#ifndef UNIVERSAL_FORWARD_LIT_PASS_INCLUDED
#define UNIVERSAL_FORWARD_LIT_PASS_INCLUDED

#include "Include/HeroLighting.hlsl"
#if defined(LOD_FADE_CROSSFADE)
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
#endif

// GLES2 has limited amount of interpolators
#if defined(_PARALLAXMAP) && !defined(SHADER_API_GLES)
#define REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR
#endif

#if (defined(_NORMALMAP) || (defined(_PARALLAXMAP) && !defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR))) || defined(_DETAIL)
#define REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR
#endif

// keep this file in sync with LitGBufferPass.hlsl

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    #if EnableHairVertexAO
    float4 vertexColor : COLOR;
    #endif
    float2 texcoord : TEXCOORD0;
    float2 staticLightmapUV : TEXCOORD1;
    float2 dynamicLightmapUV : TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv : TEXCOORD0;

    #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    float3 positionWS : TEXCOORD1;
    #endif

    float3 normalWS : TEXCOORD2;
    #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
    half4 tangentWS : TEXCOORD3; // xyz: tangent, w: sign
    #endif

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
    half4 fogFactorAndVertexLight   : TEXCOORD5; // x: fogFactor, yzw: vertex light
    #else
    half fogFactor : TEXCOORD5;
    #endif

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD6;
    #endif

    #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirTS : TEXCOORD7;
    #endif

    DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 8);
    #ifdef DYNAMICLIGHTMAP_ON
    float2  dynamicLightmapUV : TEXCOORD9; // Dynamic lightmap UVs
    #endif
    float2  LitBuildingStaticLightmapUV : TEXCOORD10;
    #if EnableHairVertexAO
    float4 vertexColor : COLOR;
    #endif
    float4 positionCS : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
{
    inputData = (InputData)0;

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    inputData.positionWS = input.positionWS;
#endif

    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
#if defined(_NORMALMAP) || defined(_DETAIL)
    float sgn = input.tangentWS.w;      // should be either +1 or -1
    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
    half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);

    #if defined(_NORMALMAP)
    inputData.tangentToWorld = tangentToWorld;
    #endif
    inputData.normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
#else
    inputData.normalWS = input.normalWS;
#endif

    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
    inputData.viewDirectionWS = viewDirWS;

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    inputData.shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
#else
    inputData.shadowCoord = float4(0, 0, 0, 0);
#endif
#ifdef _ADDITIONAL_LIGHTS_VERTEX
    inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactorAndVertexLight.x);
    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
#else
    inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactor);
#endif

#if defined(DYNAMICLIGHTMAP_ON)
    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, inputData.normalWS);
#else
    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.normalWS);
#endif

    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);

    #if defined(DEBUG_DISPLAY)
    #if defined(DYNAMICLIGHTMAP_ON)
    inputData.dynamicLightmapUV = input.dynamicLightmapUV;
    #endif
    #if defined(LIGHTMAP_ON)
    inputData.staticLightmapUV = input.staticLightmapUV;
    #else
    inputData.vertexSH = input.vertexSH;
    #endif
    #endif
}


void InitializeInputData(Varyings input, HeroSurfaceData herodata, out InputData inputData)
{
    inputData = (InputData)0;

    #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    inputData.positionWS = input.positionWS;
    #endif

    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    #if defined(_NORMALMAP) || defined(_DETAIL)
    float sgn = input.tangentWS.w; // should be either +1 or -1
    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
    half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);

    #if defined(_NORMALMAP)
    inputData.tangentToWorld = tangentToWorld;
    #endif
    inputData.normalWS = TransformTangentToWorld(herodata.normalTS, tangentToWorld);
    #else
    inputData.normalWS = input.normalWS;
    #endif

    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
    inputData.viewDirectionWS = viewDirWS;

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    inputData.shadowCoord = input.shadowCoord;
    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
    #else
    inputData.shadowCoord = float4(0, 0, 0, 0);
    #endif
    #ifdef _ADDITIONAL_LIGHTS_VERTEX
    inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactorAndVertexLight.x);
    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    #else
    inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactor);
    #endif

    #if defined(DYNAMICLIGHTMAP_ON)
    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, inputData.normalWS);
    #else
    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.normalWS);
    #endif

    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);

    #if defined(DEBUG_DISPLAY)
    #if defined(DYNAMICLIGHTMAP_ON)
    inputData.dynamicLightmapUV = input.dynamicLightmapUV;
    #endif
    #if defined(LIGHTMAP_ON)
    inputData.staticLightmapUV = input.staticLightmapUV;
    #else
    inputData.vertexSH = input.vertexSH;
    #endif
    #endif
}

///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

// Used in Standard (Physically Based) shader
Varyings LitPassVertex(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

    // normalWS and tangentWS already normalize.
    // this is required to avoid skewing the direction during interpolation
    // also required for per-vertex lighting and SH evaluation
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);

    half fogFactor = 0;
    #if !defined(_FOG_FRAGMENT)
        fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
    #endif

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

    // already normalized from normal transform to WS.
    output.normalWS = normalInput.normalWS;
    #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    real sign = input.tangentOS.w * GetOddNegativeScale();
    half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
    #endif
    #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
    output.tangentWS = tangentWS;
    #endif

    #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
    half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
    output.viewDirTS = viewDirTS;
    #endif

    #ifdef LIGHTMAP_ON
    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
    #else
    output.LitBuildingStaticLightmapUV = input.staticLightmapUV;
    #endif
    #ifdef DYNAMICLIGHTMAP_ON
    output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
    #endif
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
    #ifdef _ADDITIONAL_LIGHTS_VERTEX
    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
    #else
    output.fogFactor = fogFactor;
    #endif

    #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    output.positionWS = vertexInput.positionWS;
    #endif

    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertexInput);
    #endif
    
    output.positionCS = vertexInput.positionCS;

    #ifdef EnableHairVertexAO
    output.vertexColor = input.vertexColor; 
    #endif
    
    return output;
}

// Used in Standard (Physically Based) shader
void LitPassFragment(
    Varyings input
    , out half4 outColor : SV_Target0
    #ifdef _WRITE_RENDERING_LAYERS
    , out float4 outRenderingLayers : SV_Target1
    #endif
)
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    #if defined(_PARALLAXMAP)
    #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirTS = input.viewDirTS;
    #else
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    half3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, input.normalWS, viewDirWS);
    #endif
    ApplyPerPixelDisplacement(viewDirTS, input.uv);
    #endif


    HeroSurfaceData heroSurfaceData;


    InitializeStandardLitSurfaceData(input.uv, heroSurfaceData);

    #ifdef EnableHairVertexAO
    heroSurfaceData.occlusion *= input.vertexColor;
    #endif
    
    //#ifdef Anisotropy
    //half clippedAlpha = (heroSurfaceData.alpha >= _Cutoff) ? float(heroSurfaceData.alpha) : 0.0;
    //clip(clippedAlpha - 0.0001);
    //#endif

    #ifdef LOD_FADE_CROSSFADE
    LODFadeCrossFade(input.positionCS);
    #endif

    InputData inputData;
    InitializeInputData(input, heroSurfaceData, inputData);
    SETUP_DEBUG_TEXTURE_DATA(inputData, input.uv, _BaseMap);

    #ifdef _DBUFFER
    ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
    #endif

	#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
    #ifndef Anisotropy
	    heroSurfaceData.tannormal = input.tangentWS;
	    heroSurfaceData.binnormal = cross(inputData.normalWS, heroSurfaceData.tannormal);
    #else
        heroSurfaceData.tannormal = input.tangentWS+inputData.normalWS*heroSurfaceData.shiftTex.rgb*_Anisotropy.w;
        heroSurfaceData.binnormal = cross(inputData.normalWS, heroSurfaceData.tannormal);
    #endif
	#endif

    // Modified_2024_1_18: Replace Lighting.
    half4 color = HeroUniversalFragmentPBR(inputData, heroSurfaceData);
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    #ifdef Anisotropy
    color.a = OutputAlpha(color.a, true);
    #else
    color.a = OutputAlpha(color.a, IsSurfaceTypeTransparent(_Surface));
    #endif

    float4 result = color;
    #ifdef _DEBUG_TONE_TONE
    result.rgb = pow(result.rgb, 2.2);
    result.rgb += saturate(result.rgb - result.rgb * _ScatterColor.rgb * clamp((result.rgb + dot(result.rgb, _ScatterColor.rgb)), 0, 2));
    result.rgb = pow(result.rgb, 1 / 2.2);
    #endif
    #ifdef  _DEBUG_TONE_NEW
    result.a = color.a;
            
    #endif
    outColor = result;

    #ifdef _WRITE_RENDERING_LAYERS
    uint renderingLayers = GetMeshRenderingLayer();
    outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
    #endif
}


// // 计算旋转后的向量
// float3 RotateVectorRodrigues(float3 v, float3 k, float theta) {
//     // 罗德里格斯旋转公式
//     // v_rot = v*cos(theta) + cross(k, v)*sin(theta) + k*(dot(k, v))*(1 - cos(theta))
//     float cosTheta = cos(theta);
//     float sinTheta = sin(theta);
//     return v * cosTheta + cross(k, v) * sinTheta + k * dot(k, v) * (1 - cosTheta);
// }


float3x3 RotationMatrix(float xAngle, float yAngle, float zAngle)
{
    float4x4 rx = float4x4(1, 0, 0, 0,
                           0, cos(xAngle), -sin(xAngle), 0,
                           0, sin(xAngle), cos(xAngle), 0,
                           0, 0, 0, 1);

    float4x4 ry = float4x4(cos(yAngle), 0, sin(yAngle), 0,
                           0, 1, 0, 0,
                           -sin(yAngle), 0, cos(yAngle), 0,
                           0, 0, 0, 1);

    float4x4 rz = float4x4(cos(zAngle), -sin(zAngle), 0, 0,
                           sin(zAngle), cos(zAngle), 0, 0,
                           0, 0, 1, 0,
                           0, 0, 0, 1);

    return mul(mul(rz, ry), rx);
}

void LitPassFragmentEye(
    Varyings input
    , out half4 outColor : SV_Target0
    #ifdef _WRITE_RENDERING_LAYERS
    , out float4 outRenderingLayers : SV_Target1
    #endif
)
{
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

	#if defined(_PARALLAXMAP)
	#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
	half3 viewDirTS = input.viewDirTS;
	#else
	half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
	half3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, input.normalWS, viewDirWS);
	#endif
	ApplyPerPixelDisplacement(viewDirTS, input.uv);
	#endif

	SurfaceData surfaceData;

    HeroSurfaceData heroSurfaceData;
    InitializeStandardLitSurfaceData(input.uv, heroSurfaceData);


    #ifdef LOD_FADE_CROSSFADE
    LODFadeCrossFade(input.positionCS);
    #endif

    InputData inputData;
    InitializeInputData(input, heroSurfaceData, inputData);
	SETUP_DEBUG_TEXTURE_DATA(inputData, input.uv, _BaseMap);

    surfaceData = CopyHeroSurfaceDataToSurfaceData(heroSurfaceData);
	#ifdef _DBUFFER
	ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
	#endif


	float3 finalColor = 0;
	#if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
    float3 normal = input.normalWS;
    float sgn = input.tangentWS.w;      // should be either +1 or -1
    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
    half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);
    //float3 normalTS = SampleNormal(input.uv, TEXTURE2D_ARGS(_EyeWorldDirMap, sampler_EyeWorldDirMap));
    //float3 normalWS = normalize(TransformTangentToWorld(normalTS, tangentToWorld));


    float3 viewDir = normalize(GetWorldSpaceViewDir(input.positionWS)).xyz;
    float3 reflectVec = reflect(-viewDir, normal);
    //float3 newDir = RotateVectorRodrigues(reflectVec, normalize(_BaseVec), _Rotate);
    float3x3 rotMatrix = RotationMatrix(_BaseVec.x, _BaseVec.y, _BaseVec.z);
    float3 newDir = mul(rotMatrix, reflectVec);
    //reflectVec = normalize(reflectVec + _ReflecOffset + nor);
    //float3 cubeSample = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, reflectVec,0);
    //float depth = SAMPLE_TEXTURE2D(_EyeDepthTex,sampler_EyeDepthTex,input.uv).x;
    //float depth_pow = pow(depth, _DepthPow);
    //half3 eye_depth = depth;
    
	#endif

    // Modified_2024_1_18: Replace Lighting.
    half4 color = UniversalFragmentPBR(inputData, surfaceData);
	half4 Irradiance = half4(SAMPLE_TEXTURECUBE_LOD(_EyeCubeMap, sampler_EyeCubeMap, newDir, _EyeCubeLODOffSet));
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
	outColor = half4(color.xyz + Irradiance * _EyeCubeAtten, 1.0f);

    #ifdef _WRITE_RENDERING_LAYERS
    uint renderingLayers = GetMeshRenderingLayer();
    outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
    #endif
}

void LitPassFragmentStandardPBR(
    Varyings input
    , out half4 outColor : SV_Target0
    #ifdef _WRITE_RENDERING_LAYERS
    , out float4 outRenderingLayers : SV_Target1
    #endif
)
{
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

	#if defined(_PARALLAXMAP)
	#if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
	half3 viewDirTS = input.viewDirTS;
	#else
	half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
	half3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, input.normalWS, viewDirWS);
	#endif
	ApplyPerPixelDisplacement(viewDirTS, input.uv);
	#endif

	SurfaceData surfaceData;

    HeroSurfaceData heroSurfaceData;
    InitializeStandardLitSurfaceData(input.uv, heroSurfaceData);

    #ifdef LOD_FADE_CROSSFADE
    LODFadeCrossFade(input.positionCS);
    #endif

    InputData inputData;
    InitializeInputData(input, heroSurfaceData, inputData);
	SETUP_DEBUG_TEXTURE_DATA(inputData, input.uv, _BaseMap);

    surfaceData = CopyHeroSurfaceDataToSurfaceData(heroSurfaceData);
	#ifdef _DBUFFER
	ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
	#endif

    half4 color = UniversalFragmentPBR(inputData, surfaceData);
    outColor = color;
    color.rgb = MixFog(color.rgb, inputData.fogCoord);

    color.a = OutputAlpha(color.a, IsSurfaceTypeTransparent(_Surface));
    outColor = color;
    
    #ifdef _WRITE_RENDERING_LAYERS
    uint renderingLayers = GetMeshRenderingLayer();
    outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
    #endif
}


void LitPassFragmentBuilding(
    Varyings input
    , out half4 outColor : SV_Target0
    #ifdef _WRITE_RENDERING_LAYERS
    , out float4 outRenderingLayers : SV_Target1
    #endif
)
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    #if defined(_PARALLAXMAP)
    #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
    half3 viewDirTS = input.viewDirTS;
    #else
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    half3 viewDirTS = GetViewDirectionTangentSpace(input.tangentWS, input.normalWS, viewDirWS);
    #endif
    ApplyPerPixelDisplacement(viewDirTS, input.uv);
    #endif

    SurfaceData surfaceData;

    HeroSurfaceData heroSurfaceData;
    InitializeStandardLitSurfaceData(input.uv, heroSurfaceData);

    #ifdef LOD_FADE_CROSSFADE
    LODFadeCrossFade(input.positionCS);
    #endif

    InputData inputData;
    InitializeInputData(input, heroSurfaceData, inputData);
    SETUP_DEBUG_TEXTURE_DATA(inputData, input.uv, _BaseMap);

    surfaceData = CopyHeroSurfaceDataToSurfaceData(heroSurfaceData);
    #ifdef _DBUFFER
    ApplyDecalToSurfaceData(input.positionCS, surfaceData, inputData);
    #endif

    half4 color = UniversalFragmentPBR(inputData, surfaceData);
    outColor = color;
    half3 inputLightMapValue = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, input.LitBuildingStaticLightmapUV.xy).xyz;
    color.rgb *= (inputLightMapValue * _LightMapAtten);
    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    color.a = OutputAlpha(color.a, IsSurfaceTypeTransparent(_Surface));
    outColor = color;
    
    #ifdef _WRITE_RENDERING_LAYERS
    uint renderingLayers = GetMeshRenderingLayer();
    outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
    #endif
}

#endif
