#ifndef FASTER_TERRAIN_LIT_PASSES_INCLUDED
#define FASTER_TERRAIN_LIT_PASSES_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"

#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
    #define ENABLE_TERRAIN_PERPIXEL_NORMAL
#endif

#ifdef UNITY_INSTANCING_ENABLEDs
    TEXTURE2D(_TerrainHeightmapTexture);
    TEXTURE2D(_TerrainNormalmapTexture);
    SAMPLER(sampler_TerrainNormalmapTexture);
#endif

UNITY_INSTANCING_BUFFER_START(Terrain)
    UNITY_DEFINE_INSTANCED_PROP(float4, _TerrainPatchInstanceData)  // float4(xBase, yBase, skipScale, ~)
UNITY_INSTANCING_BUFFER_END(Terrain)

// #ifdef _ALPHATEST_ON
// TEXTURE2D(_TerrainHolesTexture);
// SAMPLER(sampler_TerrainHolesTexture);
//
// void ClipHoles(float2 uv)
// {
// 	float hole = SAMPLE_TEXTURE2D(_TerrainHolesTexture, sampler_TerrainHolesTexture, uv).r;
// 	clip(hole == 0.0f ? -1 : 1);
// }
// #endif

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 texcoord : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 uvMainAndLM              : TEXCOORD0; // xy: control, zw: lightmap
#ifndef TERRAIN_SPLAT_BASEPASS
    float4 uvSplat01                : TEXCOORD1; // xy: splat0, zw: splat1
    float4 uvSplat23                : TEXCOORD2; // xy: splat2, zw: splat3
#endif

//#if defined(_NORMALMAP) && !defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
    float4 normal                   : TEXCOORD3;    // xyz: normal, w: viewDir.x
    float4 tangent                  : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    float4 bitangent                : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
// #else
//     float3 normal                   : TEXCOORD3;
//     float3 viewDir                  : TEXCOORD4;
//     half3 vertexSH                  : TEXCOORD5; // SH
// #endif

    half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light
    float3 positionWS               : TEXCOORD7;
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD8;
#endif
    float4 clipPos                  : SV_POSITION;
    float4 globleUV                 : TEXCOORD9;
    UNITY_VERTEX_OUTPUT_STEREO
};

void InitializeInputData(Varyings IN, half3 normalTS, out InputData input)
{
    input = (InputData)0;

    input.positionWS = IN.positionWS;
    half3 SH = half3(0, 0, 0);

//#if defined(_NORMALMAP) && !defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
    half3 viewDirWS = half3(IN.normal.w, IN.tangent.w, IN.bitangent.w);
    input.normalWS = TransformTangentToWorld(normalTS, half3x3(-IN.tangent.xyz, IN.bitangent.xyz, IN.normal.xyz));
    SH = SampleSH(input.normalWS.xyz);
// #elif defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
//     half3 viewDirWS = IN.viewDir;
//     float2 sampleCoords = (IN.uvMainAndLM.xy / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
//     half3 normalWS = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
//     half3 tangentWS = cross(GetObjectToWorldMatrix()._13_23_33, normalWS);
//     input.normalWS = TransformTangentToWorld(normalTS, half3x3(-tangentWS, cross(normalWS, tangentWS), normalWS));
//     SH = SampleSH(input.normalWS.xyz);
// #else
//     half3 viewDirWS = IN.viewDir;
//     input.normalWS = IN.normal;
//     SH = IN.vertexSH;
// #endif

#if SHADER_HINT_NICE_QUALITY
    viewDirWS = SafeNormalize(viewDirWS);
#endif

    input.normalWS = NormalizeNormalPerPixel(input.normalWS);

    input.viewDirectionWS = viewDirWS;

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    input.shadowCoord = IN.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    input.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
#else
    input.shadowCoord = float4(0, 0, 0, 0);
#endif

    input.fogCoord = IN.fogFactorAndVertexLight.x;
    input.vertexLighting = IN.fogFactorAndVertexLight.yzw;

    input.bakedGI = SAMPLE_GI(IN.uvMainAndLM.zw, SH, input.normalWS);
    input.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.clipPos);
    input.shadowMask = SAMPLE_SHADOWMASK(IN.uvMainAndLM.zw)
}

#ifndef TERRAIN_SPLAT_BASEPASS

void SplatmapMix(float4 uvMainAndLM, float4 uvSplat01, float4 uvSplat23, inout half4 splatControl, out half weight, out half4 mixedDiffuse, out half4 defaultSmoothness, inout half3 mixedNormal)
{
    half4 diffAlbedo[4];

    diffAlbedo[0] = SAMPLE_TEXTURE2D(_Splat0, sampler_Splat0, uvSplat01.xy);
    diffAlbedo[1] = SAMPLE_TEXTURE2D(_Splat1, sampler_Splat0, uvSplat01.zw);
    diffAlbedo[2] = SAMPLE_TEXTURE2D(_Splat2, sampler_Splat0, uvSplat23.xy);
    diffAlbedo[3] = SAMPLE_TEXTURE2D(_Splat3, sampler_Splat0, uvSplat23.zw);
    
    // This might be a bit of a gamble -- the assumption here is that if the diffuseMap has no
    // alpha channel, then diffAlbedo[n].a = 1.0 (and _DiffuseHasAlphaN = 0.0)
    // Prior to coming in, _SmoothnessN is actually set to max(_DiffuseHasAlphaN, _SmoothnessN)
    // This means that if we have an alpha channel, _SmoothnessN is locked to 1.0 and
    // otherwise, the true slider value is passed down and diffAlbedo[n].a == 1.0.
    defaultSmoothness = half4(diffAlbedo[0].a, diffAlbedo[1].a, diffAlbedo[2].a, diffAlbedo[3].a);
    defaultSmoothness *= half4(_Smoothness0, _Smoothness1, _Smoothness2, _Smoothness3);

// #ifndef _TERRAIN_BLEND_HEIGHT
//     if(_NumLayersCount <= 4)
//     {
//         // 20.0 is the number of steps in inputAlphaMask (Density mask. We decided 20 empirically)
//         half4 opacityAsDensity = saturate((half4(diffAlbedo[0].a, diffAlbedo[1].a, diffAlbedo[2].a, diffAlbedo[3].a) - (half4(1.0, 1.0, 1.0, 1.0) - splatControl)) * 20.0);
//         opacityAsDensity += 0.001h * splatControl;      // if all weights are zero, default to what the blend mask says
//         half4 useOpacityAsDensityParam = { _DiffuseRemapScale0.w, _DiffuseRemapScale1.w, _DiffuseRemapScale2.w, _DiffuseRemapScale3.w }; // 1 is off
//         splatControl = lerp(opacityAsDensity, splatControl, useOpacityAsDensityParam);
//     }
// #endif

    // Now that splatControl has changed, we can compute the final weight and normalize
    weight = dot(splatControl, 1.0h);

// #ifdef TERRAIN_SPLAT_ADDPASS
//     clip(weight <= 0.005h ? -1.0h : 1.0h);
// #endif
//
// #ifndef _TERRAIN_BASEMAP_GEN
//     // Normalize weights before lighting and restore weights in final modifier functions so that the overal
//     // lighting result can be correctly weighted.
//     splatControl /= (weight + HALF_MIN);
// #endif

    
    mixedDiffuse = 0.0h;
    mixedDiffuse += diffAlbedo[0] * half4(_DiffuseRemapScale0.rgb * splatControl.rrr, 1.0h);
    mixedDiffuse += diffAlbedo[1] * half4(_DiffuseRemapScale1.rgb * splatControl.ggg, 1.0h);
    mixedDiffuse += diffAlbedo[2] * half4(_DiffuseRemapScale2.rgb * splatControl.bbb, 1.0h);
    mixedDiffuse += diffAlbedo[3] * half4(_DiffuseRemapScale3.rgb * saturate(1.0 - splatControl.r -splatControl.g - splatControl.b) , 1.0h);

    //#ifdef _NORMALMAP
    half3 nrm = 0.0f;

    nrm += splatControl.r * UnpackNormalScale(SAMPLE_TEXTURE2D(_Normal0, sampler_Normal0, uvSplat01.xy), _NormalScale0);
    nrm += splatControl.g * UnpackNormalScale(SAMPLE_TEXTURE2D(_Normal1, sampler_Normal0, uvSplat01.zw), _NormalScale1);
    nrm += splatControl.b * UnpackNormalScale(SAMPLE_TEXTURE2D(_Normal2, sampler_Normal0, uvSplat23.xy), _NormalScale2);
    nrm += saturate(1 - splatControl.r -splatControl.g - splatControl.b) * UnpackNormalScale(SAMPLE_TEXTURE2D(_Normal3, sampler_Normal0, uvSplat23.zw), _NormalScale3);
    
    // avoid risk of NaN when normalizing.
#if HAS_HALF
    nrm.z += 0.01h;
#else
    nrm.z += 1e-5f;
#endif

    mixedNormal = normalize(nrm.xyz);
//#endif
}

#endif

// #ifdef _TERRAIN_BLEND_HEIGHT
// void HeightBasedSplatModify(inout half4 splatControl, in half4 masks[4])
// {
//     // heights are in mask blue channel, we multiply by the splat Control weights to get combined height
//     half4 splatHeight = half4(masks[0].b, masks[1].b, masks[2].b, masks[3].b) * splatControl.rgba;
//     half maxHeight = max(splatHeight.r, max(splatHeight.g, max(splatHeight.b, splatHeight.a)));
//
//     // Ensure that the transition height is not zero.
//     half transition = max(_HeightTransition, 1e-5);
//
//     // This sets the highest splat to "transition", and everything else to a lower value relative to that, clamping to zero
//     // Then we clamp this to zero and normalize everything
//     half4 weightedHeights = splatHeight + transition - maxHeight.xxxx;
//     weightedHeights = max(0, weightedHeights);
//
//     // We need to add an epsilon here for active layers (hence the blendMask again)
//     // so that at least a layer shows up if everything's too low.
//     weightedHeights = (weightedHeights + 1e-6) * splatControl;
//
//     // Normalize (and clamp to epsilon to keep from dividing by zero)
//     half sumHeight = max(dot(weightedHeights, half4(1, 1, 1, 1)), 1e-6);
//     splatControl = weightedHeights / sumHeight.xxxx;
// }
// #endif

void SplatmapFinalColor(inout half4 color, half fogCoord)
{
    color.rgb *= color.a;

    #ifndef TERRAIN_GBUFFER // Technically we don't need fogCoord, but it is still passed from the vertex shader.

    #ifdef TERRAIN_SPLAT_ADDPASS
        color.rgb = MixFogColor(color.rgb, half3(0,0,0), fogCoord);
    #else
        color.rgb = MixFog(color.rgb, fogCoord);
    #endif

    #endif
}

void TerrainInstancing(inout float4 positionOS, inout float3 normal, inout float2 uv)
{
#ifdef UNITY_INSTANCING_ENABLED
    float2 patchVertex = positionOS.xy;
    float4 instanceData = UNITY_ACCESS_INSTANCED_PROP(Terrain, _TerrainPatchInstanceData);

    float2 sampleCoords = (patchVertex.xy + instanceData.xy) * instanceData.z; // (xy + float2(xBase,yBase)) * skipScale
    float height = UnpackHeightmap(_TerrainHeightmapTexture.Load(int3(sampleCoords, 0)));

    positionOS.xz = sampleCoords * _TerrainHeightmapScale.xz;
    positionOS.y = height * _TerrainHeightmapScale.y;

    #ifdef ENABLE_TERRAIN_PERPIXEL_NORMAL
        normal = float3(0, 1, 0);
    #else
        normal = _TerrainNormalmapTexture.Load(int3(sampleCoords, 0)).rgb * 2 - 1;
    #endif
    uv = sampleCoords * _TerrainHeightmapRecipSize.zw;
#endif
}

void TerrainInstancing(inout float4 positionOS, inout float3 normal)
{
    float2 uv = { 0, 0 };
    TerrainInstancing(positionOS, normal, uv);
}

///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

// Used in Standard Terrain shader
Varyings SplatmapVert(Attributes v)
{
    Varyings o = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    TerrainInstancing(v.positionOS, v.normalOS, v.texcoord);

    VertexPositionInputs Attributes = GetVertexPositionInputs(v.positionOS.xyz);

    o.uvMainAndLM.xy = v.texcoord;
    o.uvMainAndLM.zw = v.texcoord * unity_LightmapST.xy + unity_LightmapST.zw;
//#ifndef TERRAIN_SPLAT_BASEPASS
    o.uvSplat01.xy = TRANSFORM_TEX(v.texcoord, _Splat0);
    o.uvSplat01.zw = TRANSFORM_TEX(v.texcoord, _Splat1);
    o.uvSplat23.xy = TRANSFORM_TEX(v.texcoord, _Splat2);
    o.uvSplat23.zw = TRANSFORM_TEX(v.texcoord, _Splat3);
//#endif

    half3 viewDirWS = GetWorldSpaceViewDir(Attributes.positionWS);
#if !SHADER_HINT_NICE_QUALITY
    viewDirWS = SafeNormalize(viewDirWS);
#endif

//#if defined(_NORMALMAP) && !defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
    float4 vertexTangent = float4(cross(float3(0, 0, 1), v.normalOS), 1.0);
    VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS, vertexTangent);

    o.normal = half4(normalInput.normalWS, viewDirWS.x);
    o.tangent = half4(normalInput.tangentWS, viewDirWS.y);
    o.bitangent = half4(normalInput.bitangentWS, viewDirWS.z);
// #else
//     o.normal = TransformObjectToWorldNormal(v.normalOS);
//     o.viewDir = viewDirWS;
//     o.vertexSH = SampleSH(o.normal);
// #endif
    o.fogFactorAndVertexLight.x = ComputeFogFactor(Attributes.positionCS.z);
    o.fogFactorAndVertexLight.yzw = VertexLighting(Attributes.positionWS, o.normal.xyz);
    o.positionWS = Attributes.positionWS;
    o.clipPos = Attributes.positionCS;
    o.globleUV.xy=TRANSFORM_TEX(v.texcoord,_GlobalNormalMap);
#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    o.shadowCoord = GetShadowCoord(Attributes);
#endif

    return o;
}

// void ComputeMasks(out half4 masks[4], half4 hasMask, Varyings IN)
// {
//     masks[0] = 0.5h;
//     masks[1] = 0.5h;
//     masks[2] = 0.5h;
//     masks[3] = 0.5h;
//
// #ifdef _MASKMAP
//     masks[0] = lerp(masks[0], SAMPLE_TEXTURE2D(_Mask0, sampler_Mask0, IN.uvSplat01.xy), hasMask.x);
//     masks[1] = lerp(masks[1], SAMPLE_TEXTURE2D(_Mask1, sampler_Mask0, IN.uvSplat01.zw), hasMask.y);
//     masks[2] = lerp(masks[2], SAMPLE_TEXTURE2D(_Mask2, sampler_Mask0, IN.uvSplat23.xy), hasMask.z);
//     masks[3] = lerp(masks[3], SAMPLE_TEXTURE2D(_Mask3, sampler_Mask0, IN.uvSplat23.zw), hasMask.w);
// #endif
//
//     masks[0] *= _MaskMapRemapScale0.rgba;
//     masks[0] += _MaskMapRemapOffset0.rgba;
//     masks[1] *= _MaskMapRemapScale1.rgba;
//     masks[1] += _MaskMapRemapOffset1.rgba;
//     masks[2] *= _MaskMapRemapScale2.rgba;
//     masks[2] += _MaskMapRemapOffset2.rgba;
//     masks[3] *= _MaskMapRemapScale3.rgba;
//     masks[3] += _MaskMapRemapOffset3.rgba;
// }

// Used in Standard Terrain shader
// #ifdef TERRAIN_GBUFFER
// FragmentOutput SplatmapFragment(Varyings IN)
// #else
half4 SplatmapFragment(Varyings IN) : SV_TARGET
//#endif
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);
#ifdef _ALPHATEST_ON
    ClipHoles(IN.uvMainAndLM.xy);
#endif

    half3 normalTS = half3(0.0h, 0.0h, 1.0h);
// #ifdef TERRAIN_SPLAT_BASEPASS
//     half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uvMainAndLM.xy).rgb;
//     half smoothness = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uvMainAndLM.xy).a;
//     half metallic = SAMPLE_TEXTURE2D(_MetallicTex, sampler_MetallicTex, IN.uvMainAndLM.xy).r;
//     half alpha = 1;
//     half occlusion = 1;
// #else

    //half4 hasMask = half4(_LayerHasMask0, _LayerHasMask1, _LayerHasMask2, _LayerHasMask3);
    //half4 masks[4];
    //ComputeMasks(masks, hasMask, IN);

    float2 splatUV = (IN.uvMainAndLM.xy * (_Control_TexelSize.zw - 1.0f) + 0.5f) * _Control_TexelSize.xy;
    half4 splatControl = SAMPLE_TEXTURE2D(_Control, sampler_Control, splatUV);

    splatControl.a = 1 - splatControl.r - splatControl.g - splatControl.b;
    half alpha = dot(splatControl, half4(1.0h, 1.0h, 1.0h, 1.0h));

    // half3 ctr = SAMPLE_TEXTURE2D(_Control, sampler_Control, splatUV).xyz;
    //
    // //half3 Normal_Total = UnpackScaleNormal(tex2D(_NorTex_Total , input.uv).xyz, _NorTex_Total_Scale).rgb;
    // half4 c =  SAMPLE_TEXTURE2D(_Splat0,sampler_Splat0, IN.uvSplat01.xy);
    // half4 c1 = SAMPLE_TEXTURE2D(_Splat1,sampler_Splat0, IN.uvSplat01.zw);
    // half4 c2 = SAMPLE_TEXTURE2D(_Splat2,sampler_Splat0, IN.uvSplat23.xy);
    // half4 c3 = SAMPLE_TEXTURE2D(_Splat3,sampler_Splat0, IN.uvSplat23.zw);
    //
	   //
    // half4 controlValue = half4(ctr.r, ctr.g, ctr.b, 1 - ctr.r - ctr.g - ctr.b);
    // half4 Albedo = c * controlValue.x + c1 * controlValue.y + c2 * controlValue.z + c3 *  controlValue.w;
    // return Albedo;        

    
// #ifdef _TERRAIN_BLEND_HEIGHT
//     // disable Height Based blend when there are more than 4 layers (multi-pass breaks the normalization)
//     if (_NumLayersCount <= 4)
//         HeightBasedSplatModify(splatControl, masks);
// #endif

    half weight;
    half4 mixedDiffuse;
    half4 defaultSmoothness;
    
    SplatmapMix(IN.uvMainAndLM, IN.uvSplat01, IN.uvSplat23, splatControl, weight, mixedDiffuse, defaultSmoothness, normalTS);
    half3 albedo = mixedDiffuse.rgb;
    half4 defaultMetallic = half4(_Metallic0, _Metallic1, _Metallic2, _Metallic3);
    half4 defaultOcclusion = 1.0f;

    // added 2022/8/31 for global metallic and smoothness
    //------------------------------------------------------
    half4 metallicSmothnessControl = SAMPLE_TEXTURE2D(_GlobalMetallicSmoothness, sampler_Control, splatUV);
    half3 globleNormal=UnpackNormal(SAMPLE_TEXTURE2D(_GlobalNormalMap, sampler_GlobalNormalMap, IN.globleUV.xy));
    globleNormal=normalize(globleNormal);
    globleNormal.xy*=_GlobalNormalScale;
    normalTS+=globleNormal;
    defaultMetallic *= metallicSmothnessControl.r;
    defaultSmoothness *= metallicSmothnessControl.a;
    //------------------------------------------------------

    // half4 maskSmoothness = half4(masks[0].a, masks[1].a, masks[2].a, masks[3].a);
    // defaultSmoothness = lerp(defaultSmoothness, maskSmoothness, hasMask);
    half smoothness = dot(splatControl, defaultSmoothness);

    // half4 maskMetallic = half4(masks[0].r, masks[1].r, masks[2].r, masks[3].r);
    // defaultMetallic = lerp(defaultMetallic, maskMetallic, hasMask);
    half metallic = dot(splatControl, defaultMetallic);

    // half4 maskOcclusion = half4(masks[0].g, masks[1].g, masks[2].g, masks[3].g);
    // defaultOcclusion = lerp(defaultOcclusion, maskOcclusion, hasMask);
    half occlusion = dot(splatControl, defaultOcclusion);
//#endif

    InputData inputData;
    InitializeInputData(IN, normalTS, inputData);

// #ifdef TERRAIN_GBUFFER
//
//     BRDFData brdfData;
//     InitializeBRDFData(albedo, metallic, /* specular */ half3(0.0h, 0.0h, 0.0h), smoothness, alpha, brdfData);
//
//     half4 color;
//     color.rgb = GlobalIllumination(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS);
//     color.a = alpha;
//
//     SplatmapFinalColor(color, inputData.fogCoord);
//
//     return BRDFDataToGbuffer(brdfData, inputData, smoothness, color.rgb);
//
// #else

    half4 color = UniversalFragmentPBR(inputData, albedo, metallic, /* specular */ half3(0.0h, 0.0h, 0.0h), smoothness, occlusion, /* emission */ half3(0, 0, 0), alpha);
    SplatmapFinalColor(color, inputData.fogCoord);

    return half4(color.rgb, 1.0h);
//#endif
}

#endif
