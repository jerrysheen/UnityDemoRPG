



CBUFFER_START(UnityPerMaterial)
    float4 _BaseMap_ST;
    float4 _TangentOffset1_ST;
    float4 _TangentOffset2_ST;
    half4 _BaseColor;
    half _Cutoff;
    half _Metallic;
    half _Smoothness1;
    half _Smoothness2;
    half _BumpScale;
    half _HighLightWeight1;
    half _HighLightWeight2;
CBUFFER_END
TEXTURE2D(_TangentOffset1);            //SAMPLER(sampler_BaseMap);
TEXTURE2D(_TangentOffset2);
/*
struct SurfaceData
{
    half3 albedo;
    half3 specular;
    half  metallic;
    half  smoothness;
    half3 normalTS;
    half3 emission;
    half  occlusion;
    half  alpha;
};
*/
struct InputDataWithTAndB
{
    float3  positionWS;
    half3   normalWS;
    half3   viewDirectionWS;
    float4  shadowCoord;
    half    fogCoord;
    half3   vertexLighting;
    half3   bakedGI;
    half3   tangent;
    half3   bioTangent;
};
            
inline void InitializeSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    outSurfaceData = (SurfaceData)0;
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
                

    outSurfaceData.specular = 1;
    outSurfaceData.metallic = _Metallic;
    outSurfaceData.smoothness = _Smoothness1;
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    outSurfaceData.occlusion = 1;
    outSurfaceData.emission = 0;
}









//LitForwardPass.hlsl
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    float2 texcoord     : TEXCOORD0;
    float2 lightmapUV   : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv                       : TEXCOORD0;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    float3 positionWS               : TEXCOORD2;
#endif

    float3 normalWS                 : TEXCOORD3;
#ifdef _NORMALMAP
    float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: sign
#endif
    float3 viewDirWS                : TEXCOORD5;

    half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD7;
#endif

    float4 positionCS               : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

void InitializeInputData(Varyings input, half3 normalTS, out InputDataWithTAndB inputData)
{
    inputData = (InputDataWithTAndB)0;

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    inputData.positionWS = input.positionWS;
#endif

    half3 viewDirWS = SafeNormalize(input.viewDirWS);
#ifdef _NORMALMAP
    float sgn = input.tangentWS.w;      // should be either +1 or -1
    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
    inputData.tangent = input.tangentWS.xyz;
    inputData.bioTangent = bitangent.xyz;
    inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
#else
    //inputData.normalWS = input.normalWS;
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

    inputData.fogCoord = input.fogFactorAndVertexLight.x;
    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
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
    float3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
    half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

    // already normalized from normal transform to WS.
    output.normalWS = normalInput.normalWS;
    output.viewDirWS = viewDirWS;
#ifdef _NORMALMAP
    real sign = input.tangentOS.w * GetOddNegativeScale();
    output.tangentWS = half4(normalInput.tangentWS.xyz, sign);
#endif

    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    output.positionWS = vertexInput.positionWS;
#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertexInput);
#endif

    output.positionCS = vertexInput.positionCS;

    return output;
}
half3 FixLightDir()
{
    half3 lightDir = _MainLightPosition.xyz;
    lightDir.y = smoothstep(0.9 , 1 , lightDir.y);
    return normalize(lightDir);
}
float D_GGXaniso( float RoughnessX, float RoughnessY , float NoH, float3 H, float3 X, float3 Y)
{
    float ax = RoughnessX * RoughnessX ;
    float ay = RoughnessY * RoughnessY ;
    float XoH = dot( Y, H );
    float YoH = dot( X, H );
    float d = XoH*XoH / (ax*ax) + YoH*YoH / (ay*ay) + NoH*NoH;
    return 1 / ( ax * ay * d * d );
}
/*

struct BRDFData
{
    half3 diffuse;
    half3 specular;
    half perceptualRoughness;
    half roughness;
    half roughness2;
    half grazingTerm;

    // We save some light invariant BRDF terms so we don't have to recompute
    // them in the light loop. Take a look at DirectBRDF function for detailed explaination.
    half normalizationTerm;     // roughness * 4.0 + 2.0
    half roughness2MinusOne;    // roughness^2 - 1.0
};
*/
half3 CustomDirectBDRF(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS , half3 tangent , half3 bioTangent , half2 uv , half alpha)
{
#ifndef _SPECULARHIGHLIGHTS_OFF
    float3 halfDir = SafeNormalize(float3(lightDirectionWS) + float3(viewDirectionWS));
    float NoH = saturate(dot(normalWS, halfDir));
    half LoH = saturate(dot(lightDirectionWS, halfDir));
    float2 offsetUV = uv.xy * _TangentOffset1_ST.xy +_TangentOffset1_ST.zw;
    float offset = SAMPLE_TEXTURE2D(_TangentOffset1 , sampler_BaseMap , offsetUV).r - 0.5+ _TangentOffset1_ST.zw;
    half bioTangent1  = bioTangent + offset;
    //return  offset * normalWS;
    //float d_a = D_GGXaniso(brdfData.roughness , 1 , NoH , halfDir , tangent , bioTangent);
    float d_a = D_GGXaniso(brdfData.roughness , 1 , NoH , halfDir , bioTangent1 , tangent);
    float3 specularTerm =  d_a * _HighLightWeight1;
    offset = SAMPLE_TEXTURE2D(_TangentOffset2 , sampler_BaseMap , offsetUV).r - 0.5 + _TangentOffset2_ST.zw;
    half bioTangent2  = bioTangent + offset;
    d_a = D_GGXaniso(brdfData.roughness * _Smoothness2 , 1 , NoH , halfDir , bioTangent2 , tangent);
    specularTerm += d_a * _HighLightWeight2;

    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles


    half3 color = specularTerm * brdfData.specular * alpha  + brdfData.diffuse;
    return color;
#else
    return brdfData.diffuse;
#endif
}

half3 CustomLightingPhysical(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS ,  half3 tangent , half3 bioTangent , half2 uv , half alpha)
{
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NdotL);
    return CustomDirectBDRF(brdfData, normalWS, lightDirectionWS, viewDirectionWS ,  tangent , bioTangent , uv , alpha) * radiance;
}
half3 CustomLightingPhysical(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS, half3 tangent , half3 bioTangent , half2 uv , half alpha)
{
                
    return CustomLightingPhysical(brdfData, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS , tangent , bioTangent , uv , alpha);
}

half4 PBR(InputDataWithTAndB inputData, half3 albedo, half metallic, half3 specular,
    half smoothness, half occlusion, half3 emission, half alpha ,  half3 tangent , half3 bioTangent , half2 uv)
{
    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);
    
    Light mainLight = GetMainLight(inputData.shadowCoord);
    mainLight.direction = FixLightDir();
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    half3 color = GlobalIllumination(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS);
    color += CustomLightingPhysical(brdfData, mainLight , inputData.normalWS, inputData.viewDirectionWS , tangent , bioTangent , uv , alpha);

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
        color += LightingPhysicallyBased(brdfData, light, inputData.normalWS, inputData.viewDirectionWS);
    }
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    color += inputData.vertexLighting * brdfData.diffuse;
#endif

    color += emission;
    half3 rim = 1.0 - saturate(dot(inputData.viewDirectionWS , inputData.normalWS));
    //color += rim * _RimWeight;
    return half4(color, alpha);
}

            


// Used in Standard (Physically Based) shader
half4 LitPassFragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    SurfaceData surfaceData;
    InitializeSurfaceData(input.uv, surfaceData );

    InputDataWithTAndB inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);

    half4 color = PBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.occlusion, surfaceData.emission, surfaceData.alpha , inputData.tangent , inputData.bioTangent , input.uv);
                
    color.rgb = MixFog(color.rgb, inputData.fogCoord);

    return color;
}



