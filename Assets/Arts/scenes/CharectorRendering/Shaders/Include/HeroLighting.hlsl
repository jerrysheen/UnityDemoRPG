#ifndef UNIVERSAL_LIGHTING_INCLUDED
#define UNIVERSAL_LIGHTING_INCLUDED

#include "Include/HeroBRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
#include "Include/LitHero_Input.hlsl"

#if defined(LIGHTMAP_ON)
    #define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) float2 lmName : TEXCOORD##index
    #define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT) OUT.xy = lightmapUV.xy * lightmapScaleOffset.xy + lightmapScaleOffset.zw;
    #define OUTPUT_SH(normalWS, OUT)
#else
#define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) half3 shName : TEXCOORD##index
#define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT)
#define OUTPUT_SH(normalWS, OUT) OUT.xyz = SampleSHVertex(normalWS)
#endif

///////////////////////////////////////////////////////////////////////////////
//                      Lighting Functions                                   //
///////////////////////////////////////////////////////////////////////////////
half3 LightingLambert(half3 lightColor, half3 lightDir, half3 normal)
{
    half NdotL = saturate(dot(normal, lightDir));
    return lightColor * NdotL;
}

half3 LightingSpecular(half3 lightColor, half3 lightDir, half3 normal, half3 viewDir, half4 specular, half smoothness)
{
    float3 halfVec = SafeNormalize(float3(lightDir) + float3(viewDir));
    half NdotH = half(saturate(dot(normal, halfVec)));
    half modifier = pow(NdotH, smoothness);
    half3 specularReflection = specular.rgb * modifier;
    return lightColor * specularReflection;
}

half3 GlobalIlluminationE(BRDFData brdfData, BRDFData brdfDataClearCoat, float clearCoatMask,
                          half3 bakedGI, half occlusion, float3 positionWS,
                          half3 normalWS, half3 viewDirectionWS, float2 normalizedScreenSpaceUV)
{
    half3 reflectVector = saturate(normalize(mul(UNITY_MATRIX_IT_MV, normalWS)) * 0.5 + 0.5);


    half3 indirectSpecular = SAMPLE_TEXTURE2D(_MatCapTex, sampler_MatCapTex, reflectVector.xy);
    // / SAMPLE_TEXTURE2D_LOD(_MatCapTex, sampler_MatCapTex,reflectVector.xy,brdfData.perceptualRoughness*9);
    half NoV = saturate(dot(normalWS, viewDirectionWS));
    half3 color = EnvironmentBRDF(brdfData, bakedGI, indirectSpecular, Pow4(1.0 - NoV));
    return color;
    // half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    // half NoV = saturate(dot(normalWS, viewDirectionWS));
    // half fresnelTerm = Pow4(1.0 - NoV);
    //
    // half3 indirectDiffuse = bakedGI;
    // half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, positionWS, brdfData.perceptualRoughness, 1.0h, normalizedScreenSpaceUV);
    //
    // half3 color = EnvironmentBRDF(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm);
    //
    // if (IsOnlyAOLightingFeatureEnabled())
    // {
    //     color = half3(1,1,1); // "Base white" for AO debug lighting mode
    // }
    //
    // #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
    // half3 coatIndirectSpecular = GlossyEnvironmentReflection(reflectVector, positionWS, brdfDataClearCoat.perceptualRoughness, 1.0h, normalizedScreenSpaceUV);
    // // TODO: "grazing term" causes problems on full roughness
    // half3 coatColor = EnvironmentBRDFClearCoat(brdfDataClearCoat, clearCoatMask, coatIndirectSpecular, fresnelTerm);
    //
    // // Blend with base layer using khronos glTF recommended way using NoV
    // // Smooth surface & "ambiguous" lighting
    // // NOTE: fresnelTerm (above) is pow4 instead of pow5, but should be ok as blend weight.
    // half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * fresnelTerm;
    // return (color * (1.0 - coatFresnel * clearCoatMask) + coatColor) * occlusion;
    // #else
    // return color * occlusion;
    // #endif
}


half3 HeroLightingPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat,
                                  half3 lightColor, half3 lightDirectionWS, half lightAttenuation,
                                  half3 normalWS, half3 viewDirectionWS,
                                  half clearCoatMask, bool specularHighlightsOff, HeroSurfaceData surfaceData, float3 worldTangent)
{
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NdotL);

    half3 brdf = brdfData.diffuse;
    #ifndef _SPECULARHIGHLIGHTS_OFF
    [branch] if (!specularHighlightsOff)
    {
        brdf += brdfData.specular * HeroDirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);
        #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
        // Clear coat evaluates the specular a second timw and has some common terms with the base specular.
        // We rely on the compiler to merge these and compute them only once.
        half brdfCoat = kDielectricSpec.r * DirectBRDFSpecular(brdfDataClearCoat, normalWS, lightDirectionWS, viewDirectionWS);

            // Mix clear coat and base layer using khronos glTF recommended formula
            // https://github.com/KhronosGroup/glTF/blob/master/extensions/2.0/Khronos/KHR_materials_clearcoat/README.md
            // Use NoV for direct too instead of LoH as an optimization (NoV is light invariant).
            half NoV = saturate(dot(normalWS, viewDirectionWS));
            // Use slightly simpler fresnelTerm (Pow4 vs Pow5) as a small optimization.
            // It is matching fresnel used in the GI/Env, so should produce a consistent clear coat blend (env vs. direct)
            half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * Pow4(1.0 - NoV);

        brdf = brdf * (1.0 - clearCoatMask * coatFresnel) + brdfCoat * clearCoatMask;
        #endif // _CLEARCOAT
    }
    #endif // _SPECULARHIGHLIGHTS_OFF

    // DirectLight Result : brdf * radiance;
    half3 DirectResult = brdf * radiance;


    //-------------------------VERSION 0, CALCULATE FRONT AND BACK COLOR------------------------------------------------------
    //
    //    
    // //SSS calculation:
    // float lutU = dot(normalWS, lightDirectionWS) * 0.5 + 0.5;
    // lutU *= lightAttenuation * 0.5 + 0.5;
    // float lutV = surfaceData.channel.g * surfaceData.curvatureOffset;
    // half3 skin = SAMPLE_TEXTURE2D(_ScatterLUT , sampler_ScatterLUT, float2(lutU, lutV)).rgb;
    // float3 frontcolor=float3(surfaceData.channel.z * (1.0 - surfaceData.channel.x) + (1.5 * surfaceData.channel.x),
    //     surfaceData.channel.z * (1.0 - surfaceData.channel.x) + (1.5 * surfaceData.channel.x),
    //     surfaceData.channel.z * (1.0 - surfaceData.channel.x) + (1.5 * surfaceData.channel.x)) * 2;
    //
    // //float3 bentNormalWS = TransformTangentToWorld(surfaceData.bentNormalTS, tangentToWorld);
    // half3 TransLightDir = surfaceData._cVirtualLitDir;// + bentNormalWS * 0.5;
    // half TransDot = saturate(dot(-TransLightDir, viewDirectionWS));
    //
    //
    // half WrapNoL = saturate(1 - NdotL);
    // half3 backscatter = WrapNoL * surfaceData.channel.x  * surfaceData._sssColor.rgb;//* S (pow(TransDot, _SSSPower)+backSSSMask)*WrapNoL *channel.x  *_sssColor;//* 
    //
    // // return float4(backscatter,1);
    // float nlwrap = saturate(NdotL + 0.5) / 1.5;
    // float3 frontscatter = ((lightColor+frontcolor) * surfaceData._sssColor.rgb * surfaceData.channel.r) * lightAttenuation * nlwrap;///((frontcolor+(lightColor+frontcolor)*_sssColor)*channel.r)*nlwrap*nlwrap+nl;
    //
    //
    // //  return float4(frontscatter+backscatter,1);
    // float3 first=(frontscatter + backscatter) + skin;
    // // first *=Albedo;//pow(Albedo,2.2);
    // // first*=kd;
    // // kd = oneMinusReflectivity;
    // first *= surfaceData.albedo;
    // first *= (half3(1.0,1.0,1.0) - brdfData.reflectivity);
    // //return  brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);
    // half3 finalRes = DirectResult + (first * lightColor + brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS) );
    // return finalRes;
    //-------------------------VERSION 0, CALCULATE FRONT AND BACK COLOR------------------------------------------------------
    float3 halfVector = normalize(lightDirectionWS + viewDirectionWS);
    float nh = max(0.0001, dot(normalWS, halfVector));
    float nl = max(0.0001, dot(normalWS, lightDirectionWS));
    float nv = max(0.0001, dot(normalWS, viewDirectionWS));
    float vh = max(0.0001, dot(viewDirectionWS, halfVector));
    float perceptualRoughness = 1 - surfaceData.smoothness;
    float roughness = max(perceptualRoughness * perceptualRoughness, 0.0078125);
    float squareRoughness = max(roughness * roughness, 6.103515625e-5);
    float3 kd = lerp(0.96, 0, surfaceData.metallic);
    #ifndef Anisotropy
    float lutU = dot(normalWS, lightDirectionWS) * 0.5 + 0.5;
    lutU *= lightAttenuation * 0.5 + 0.5;
    float lutV = surfaceData.channel.g * surfaceData.curvatureScale + surfaceData.curvatureOffset;
    half3 skin = SAMPLE_TEXTURE2D(_ScatterLUT, sampler_ScatterLUT, float2(lutU, lutV)).rgb;
    float wlight = ComputeWrappedDiffuseLighting2(-nl, surfaceData._cVirtualLitDir.w);
    float3 cc = wlight * surfaceData._sssColor * max(0, (1 - surfaceData.channel.r) / (surfaceData.thickness / 1000));
    skin += cc * wlight;
    //DirectLightResult += frist * lightColor + specColor;
    float D = 0;
    D = Distribution(roughness, nh);
    float3 F0 = lerp(0.04, surfaceData.albedo, surfaceData.metallic);
    float G = Geometry(squareRoughness, nl, nv);
    float3 F = Fresnelschlick4Skin(vh, F0);
    // return F;
    float3 specularResult = (D * G * F);
    float3 specColor = specularResult;
    float3 diffColor = surfaceData.albedo * kd * skin;
    float3 directLightResult = (diffColor + specColor * PI) * lightAttenuation * lightColor;
    return directLightResult;
    #else
    //float4 shifttexture = SAMPLE_TEXTURE2D(_ShiftTex, sampler_ShiftTex, i.uv.xy);
    float4 shifttexture = surfaceData.shiftTex;
    half3 aspect = sqrt(1-surfaceData._Anisotropy * 0.9f);
    half anisoXRoughness = max(0.01f, roughness / aspect.x);
    half anisoYRoughness = max(0.01f, roughness * aspect.x);

    half anisoARoughness = max(0.01f, roughness / aspect.y);
    half anisoBRoughness = max(0.01f, roughness * aspect.y);
    // float3 binormal=normalize(i.worldBinormal+normal*shifttexture.rgb*_Anisotropy.w);
    // float3 tannormal=normalize(cross(normal,binormal));
    // float3 tannormal=normalize(worldTangent + normalWS * shifttexture.rgb * surfaceData._Anisotropy.w);
    // float3 binormal=normalize(cross(normalWS,tannormal));

    
    float G = G_Geometryaniso(roughness,nl,nh);
    float D = D_GGXaniso(anisoXRoughness*2,anisoYRoughness*2,nh,halfVector,surfaceData.tannormal,surfaceData.binnormal);// D_GGXaniso(roughness,nh,halfVector,tannormal,binormal,_Anisotropy.z);

    D += D_GGXaniso(anisoARoughness,anisoBRoughness,nv,viewDirectionWS,surfaceData.tannormal,surfaceData.binnormal);
    D *= surfaceData._AnisotroySpecBoardLine * nv * nv;
    float3 SpecularResult = (D * G);
    float3 specColor = SpecularResult * PI;
    float3 diffColor = surfaceData.albedo * kd;
    float3 directLightResult = (diffColor + specColor) * lightAttenuation * lightColor * nl;
    return directLightResult;

    #endif
}


half3 LightingPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat,
                              half3 lightColor, half3 lightDirectionWS, half lightAttenuation,
                              half3 normalWS, half3 viewDirectionWS,
                              half clearCoatMask, bool specularHighlightsOff)
{
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NdotL);

    half3 brdf = brdfData.diffuse;
    #ifndef _SPECULARHIGHLIGHTS_OFF
    [branch] if (!specularHighlightsOff)
    {
        brdf += brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);

        #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
        // Clear coat evaluates the specular a second timw and has some common terms with the base specular.
        // We rely on the compiler to merge these and compute them only once.
        half brdfCoat = kDielectricSpec.r * DirectBRDFSpecular(brdfDataClearCoat, normalWS, lightDirectionWS, viewDirectionWS);

        // Mix clear coat and base layer using khronos glTF recommended formula
        // https://github.com/KhronosGroup/glTF/blob/master/extensions/2.0/Khronos/KHR_materials_clearcoat/README.md
        // Use NoV for direct too instead of LoH as an optimization (NoV is light invariant).
        half NoV = saturate(dot(normalWS, viewDirectionWS));
        // Use slightly simpler fresnelTerm (Pow4 vs Pow5) as a small optimization.
        // It is matching fresnel used in the GI/Env, so should produce a consistent clear coat blend (env vs. direct)
        half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * Pow4(1.0 - NoV);

        brdf = brdf * (1.0 - clearCoatMask * coatFresnel) + brdfCoat * clearCoatMask;
        #endif // _CLEARCOAT
    }
    #endif // _SPECULARHIGHLIGHTS_OFF

    // DirectLight Result : brdf * radiance;
    return brdf * radiance;
}

half3 HeroLightingPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat, Light light, half3 normalWS, half3 viewDirectionWS, half clearCoatMask, bool specularHighlightsOff, HeroSurfaceData surfaceData, float3 worldTangent)
{
    //#ifndef Anisotropy
    //   float atten = light.shadowAttenuation;
    float atten = lerp(1, light.shadowAttenuation, surfaceData.localShadowAtten) * light.distanceAttenuation;
    //#endif

    return HeroLightingPhysicallyBased(brdfData, brdfDataClearCoat, light.color, light.direction, atten, normalWS, viewDirectionWS, clearCoatMask, specularHighlightsOff, surfaceData, worldTangent);
}

half3 LightingPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat, Light light, half3 normalWS, half3 viewDirectionWS, half clearCoatMask, bool specularHighlightsOff)
{
    return LightingPhysicallyBased(brdfData, brdfDataClearCoat, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, clearCoatMask, specularHighlightsOff);
}


// Backwards compatibility
half3 LightingPhysicallyBased(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS)
{
    #ifdef _SPECULARHIGHLIGHTS_OFF
    bool specularHighlightsOff = true;
    #else
    bool specularHighlightsOff = false;
    #endif
    const BRDFData noClearCoat = (BRDFData)0;
    return LightingPhysicallyBased(brdfData, noClearCoat, light, normalWS, viewDirectionWS, 0.0, specularHighlightsOff);
}

half3 LightingPhysicallyBased(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS)
{
    Light light;
    light.color = lightColor;
    light.direction = lightDirectionWS;
    light.distanceAttenuation = lightAttenuation;
    light.shadowAttenuation = 1;
    return LightingPhysicallyBased(brdfData, light, normalWS, viewDirectionWS);
}

half3 LightingPhysicallyBased(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS, bool specularHighlightsOff)
{
    const BRDFData noClearCoat = (BRDFData)0;
    return LightingPhysicallyBased(brdfData, noClearCoat, light, normalWS, viewDirectionWS, 0.0, specularHighlightsOff);
}

half3 LightingPhysicallyBased(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS, bool specularHighlightsOff)
{
    Light light;
    light.color = lightColor;
    light.direction = lightDirectionWS;
    light.distanceAttenuation = lightAttenuation;
    light.shadowAttenuation = 1;
    return LightingPhysicallyBased(brdfData, light, viewDirectionWS, specularHighlightsOff, specularHighlightsOff);
}

half3 VertexLighting(float3 positionWS, half3 normalWS)
{
    half3 vertexLightColor = half3(0.0, 0.0, 0.0);

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
    uint lightsCount = GetAdditionalLightsCount();
    LIGHT_LOOP_BEGIN(lightsCount)
        Light light = GetAdditionalLight(lightIndex, positionWS);
        half3 lightColor = light.color * light.distanceAttenuation;
        vertexLightColor += LightingLambert(lightColor, light.direction, normalWS);
    LIGHT_LOOP_END
    #endif

    return vertexLightColor;
}

struct LightingData
{
    half3 giColor;
    half3 mainLightColor;
    half3 additionalLightsColor;
    half3 vertexLightingColor;
    half3 emissionColor;
};

half3 CalculateLightingColor(LightingData lightingData, half3 albedo)
{
    half3 lightingColor = 0;

    if (IsOnlyAOLightingFeatureEnabled())
    {
        return lightingData.giColor; // Contains white + AO
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_GLOBAL_ILLUMINATION))
    {
        lightingColor += lightingData.giColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_MAIN_LIGHT))
    {
        lightingColor += lightingData.mainLightColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_ADDITIONAL_LIGHTS))
    {
        lightingColor += lightingData.additionalLightsColor;
    }

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_VERTEX_LIGHTING))
    {
        lightingColor += lightingData.vertexLightingColor;
    }

    lightingColor *= albedo;

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_EMISSION))
    {
        lightingColor += lightingData.emissionColor;
    }

    return lightingColor;
}

half4 CalculateFinalColor(LightingData lightingData, half alpha)
{
    half3 finalColor = CalculateLightingColor(lightingData, 1);

    return half4(finalColor, alpha);
}

half4 CalculateFinalColor(LightingData lightingData, half3 albedo, half alpha, float fogCoord)
{
    #if defined(_FOG_FRAGMENT)
    #if (defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2))
        float viewZ = -fogCoord;
        float nearToFarZ = max(viewZ - _ProjectionParams.y, 0);
        half fogFactor = ComputeFogFactorZ0ToFar(nearToFarZ);
    #else
    half fogFactor = 0;
    #endif
    #else
    half fogFactor = fogCoord;
    #endif
    half3 lightingColor = CalculateLightingColor(lightingData, albedo);
    half3 finalColor = MixFog(lightingColor, fogFactor);

    return half4(finalColor, alpha);
}

LightingData CreateLightingData(InputData inputData, SurfaceData surfaceData)
{
    LightingData lightingData;

    lightingData.giColor = inputData.bakedGI;
    lightingData.emissionColor = surfaceData.emission;
    lightingData.vertexLightingColor = 0;
    lightingData.mainLightColor = 0;
    lightingData.additionalLightsColor = 0;

    return lightingData;
}

half3 CalculateBlinnPhong(Light light, InputData inputData, SurfaceData surfaceData)
{
    half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
    half3 lightDiffuseColor = LightingLambert(attenuatedLightColor, light.direction, inputData.normalWS);

    half3 lightSpecularColor = half3(0, 0, 0);
    #if defined(_SPECGLOSSMAP) || defined(_SPECULAR_COLOR)
    half smoothness = exp2(10 * surfaceData.smoothness + 1);

    lightSpecularColor += LightingSpecular(attenuatedLightColor, light.direction, inputData.normalWS, inputData.viewDirectionWS, half4(surfaceData.specular, 1), smoothness);
    #endif

    #if _ALPHAPREMULTIPLY_ON
    return lightDiffuseColor * surfaceData.albedo * surfaceData.alpha + lightSpecularColor;
    #else
    return lightDiffuseColor * surfaceData.albedo + lightSpecularColor;
    #endif
}

///////////////////////////////////////////////////////////////////////////////
//                      Fragment Functions                                   //
//       Used by ShaderGraph and others builtin renderers                    //
///////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
/// PBR lighting...
////////////////////////////////////////////////////////////////////////////////
half4 HeroUniversalFragmentPBRE(InputData inputData, HeroSurfaceData herosurfaceData)
{
    #if defined(_SPECULARHIGHLIGHTS_OFF)
    bool specularHighlightsOff = true;
    #else
    bool specularHighlightsOff = false;
    #endif
    BRDFData brdfData;

    SurfaceData surfaceData = CopyHeroSurfaceDataToSurfaceData(herosurfaceData);
    // NOTE: can modify "surfaceData"...
    InitializeBRDFData(surfaceData, brdfData);

    #if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, brdfData, debugColor))
    {
        return debugColor;
    }
    #endif

    // Clear-coat calculation...
    BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    uint meshRenderingLayers = GetMeshRenderingLayer();
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    // NOTE: We don't apply AO to the GI here because it's done in the lighting calculation below...
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    LightingData lightingData = CreateLightingData(inputData, surfaceData);

    half3x3 tangentToWorld;
    #if defined(_NORMALMAP) || defined(_DETAIL)
    tangentToWorld = inputData.tangentToWorld;
    #endif
    //calculate bentNormal Here:
    #ifndef Anisotropy
    float3 bentNormalWS = TransformTangentToWorld(herosurfaceData.bentNormalTS, tangentToWorld);
    #else
    float3 bentNormalWS = herosurfaceData.tannormal;
    #endif

    // lightingData.giColor = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
    //                                           inputData.bakedGI, aoFactor.indirectAmbientOcclusion, inputData.positionWS,
    //                                           inputData.normalWS, inputData.viewDirectionWS, inputData.normalizedScreenSpaceUV);


    lightingData.giColor = GlobalIlluminationE(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                                               inputData.bakedGI, aoFactor.indirectAmbientOcclusion, inputData.positionWS,
                                               inputData.normalWS, inputData.viewDirectionWS, inputData.normalizedScreenSpaceUV);
    return float4(lightingData.giColor, 1);
    #ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
    #endif
    {
        lightingData.mainLightColor = HeroLightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                                                  mainLight,
                                                                  inputData.normalWS, inputData.viewDirectionWS,
                                                                  surfaceData.clearCoatMask, specularHighlightsOff, herosurfaceData, float3(tangentToWorld[0][0], tangentToWorld[0][1], tangentToWorld[0][2]));
    }

    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    #if USE_FORWARD_PLUS
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

    #ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
    #endif
        {
            lightingData.additionalLightsColor += HeroLightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                          surfaceData.clearCoatMask, specularHighlightsOff, herosurfaceData, tangentToWorld[0]);
        }
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

    #ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
    #endif
        {
            lightingData.additionalLightsColor += HeroLightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                          surfaceData.clearCoatMask, specularHighlightsOff, herosurfaceData, tangentToWorld[0]);
        }
    LIGHT_LOOP_END
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
    #endif

    #if REAL_IS_HALF
    // Clamp any half.inf+ to HALF_MAX
    return min(CalculateFinalColor(lightingData, surfaceData.alpha), HALF_MAX);
    #else
    return CalculateFinalColor(lightingData, surfaceData.alpha);
    #endif
}

half4 HeroUniversalFragmentPBR(InputData inputData, HeroSurfaceData herosurfaceData)
{
    #if defined(_SPECULARHIGHLIGHTS_OFF)
    bool specularHighlightsOff = true;
    #else
    bool specularHighlightsOff = false;
    #endif
    BRDFData brdfData;

    SurfaceData surfaceData = CopyHeroSurfaceDataToSurfaceData(herosurfaceData);
    // NOTE: can modify "surfaceData"...
    InitializeBRDFData(surfaceData, brdfData);

    #if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, brdfData, debugColor))
    {
        return debugColor;
    }
    #endif

    // Clear-coat calculation...
    BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    uint meshRenderingLayers = GetMeshRenderingLayer();
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);
    // NOTE: We don't apply AO to the GI here because it's done in the lighting calculation below...
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    LightingData lightingData = CreateLightingData(inputData, surfaceData);

    half3x3 tangentToWorld;
    #if defined(_NORMALMAP) || defined(_DETAIL)
    tangentToWorld = inputData.tangentToWorld;
    #endif
    //calculate bentNormal Here:
    #ifndef Anisotropy
    float3 bentNormalWS = TransformTangentToWorld(herosurfaceData.bentNormalTS, tangentToWorld);
    #else
    float3 bentNormalWS = herosurfaceData.tannormal;
    #endif

    // lightingData.giColor = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
    //                                           inputData.bakedGI, aoFactor.indirectAmbientOcclusion, inputData.positionWS,
    //                                           inputData.normalWS, inputData.viewDirectionWS, inputData.normalizedScreenSpaceUV);


    lightingData.giColor = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                                              inputData.bakedGI, aoFactor.indirectAmbientOcclusion, inputData.positionWS,
                                              bentNormalWS, inputData.viewDirectionWS, inputData.normalizedScreenSpaceUV);

    #ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
    #endif
    {
        lightingData.mainLightColor = HeroLightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                                                  mainLight,
                                                                  inputData.normalWS, inputData.viewDirectionWS,
                                                                  surfaceData.clearCoatMask, specularHighlightsOff, herosurfaceData, float3(tangentToWorld[0][0], tangentToWorld[0][1], tangentToWorld[0][2]));
    }
    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    #if USE_FORWARD_PLUS
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

    #ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
    #endif
        {
            lightingData.additionalLightsColor += HeroLightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                          surfaceData.clearCoatMask, specularHighlightsOff, herosurfaceData, tangentToWorld[0]);
        }
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

    #ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
    #endif
        {
            lightingData.additionalLightsColor += HeroLightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                          surfaceData.clearCoatMask, specularHighlightsOff, herosurfaceData, tangentToWorld[0]);
        }
    LIGHT_LOOP_END
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
    #endif

    #if REAL_IS_HALF
    // Clamp any half.inf+ to HALF_MAX
    return min(CalculateFinalColor(lightingData, surfaceData.alpha), HALF_MAX);
    #else
    return CalculateFinalColor(lightingData, surfaceData.alpha);
    #endif
}


half4 UniversalFragmentPBR(InputData inputData, SurfaceData surfaceData)
{
    #if defined(_SPECULARHIGHLIGHTS_OFF)
    bool specularHighlightsOff = true;
    #else
    bool specularHighlightsOff = false;
    #endif
    BRDFData brdfData;

    // NOTE: can modify "surfaceData"...
    InitializeBRDFData(surfaceData, brdfData);

    #if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, brdfData, debugColor))
    {
        return debugColor;
    }
    #endif

    // Clear-coat calculation...
    BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    uint meshRenderingLayers = GetMeshRenderingLayer();
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    // NOTE: We don't apply AO to the GI here because it's done in the lighting calculation below...
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    LightingData lightingData = CreateLightingData(inputData, surfaceData);

    lightingData.giColor = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                                              inputData.bakedGI, aoFactor.indirectAmbientOcclusion, inputData.positionWS,
                                              inputData.normalWS, inputData.viewDirectionWS, inputData.normalizedScreenSpaceUV);
    #ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
    #endif
    {
        lightingData.mainLightColor = LightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                                              mainLight,
                                                              inputData.normalWS, inputData.viewDirectionWS,
                                                              surfaceData.clearCoatMask, specularHighlightsOff);
    }

    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    #if USE_FORWARD_PLUS
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

    #ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
    #endif
        {
            lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                          surfaceData.clearCoatMask, specularHighlightsOff);
        }
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

    #ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
    #endif
        {
            lightingData.additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                          surfaceData.clearCoatMask, specularHighlightsOff);
        }
    LIGHT_LOOP_END
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
    #endif

    #if REAL_IS_HALF
    // Clamp any half.inf+ to HALF_MAX
    return min(CalculateFinalColor(lightingData, surfaceData.alpha), HALF_MAX);
    #else
    return CalculateFinalColor(lightingData, surfaceData.alpha);
    #endif
}

// Deprecated: Use the version which takes "SurfaceData" instead of passing all of these arguments...
half4 UniversalFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular,
                           half smoothness, half occlusion, half3 emission, half alpha)
{
    SurfaceData surfaceData;

    surfaceData.albedo = albedo;
    surfaceData.specular = specular;
    surfaceData.metallic = metallic;
    surfaceData.smoothness = smoothness;
    surfaceData.normalTS = half3(0, 0, 1);
    surfaceData.emission = emission;
    surfaceData.occlusion = occlusion;
    surfaceData.alpha = alpha;
    surfaceData.clearCoatMask = 0;
    surfaceData.clearCoatSmoothness = 1;

    return UniversalFragmentPBR(inputData, surfaceData);
}

////////////////////////////////////////////////////////////////////////////////
/// Phong lighting...
////////////////////////////////////////////////////////////////////////////////
half4 UniversalFragmentBlinnPhong(InputData inputData, SurfaceData surfaceData)
{
    #if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, debugColor))
    {
        return debugColor;
    }
    #endif

    uint meshRenderingLayers = GetMeshRenderingLayer();
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, aoFactor);

    inputData.bakedGI *= surfaceData.albedo;

    LightingData lightingData = CreateLightingData(inputData, surfaceData);
    #ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
    #endif
    {
        lightingData.mainLightColor += CalculateBlinnPhong(mainLight, inputData, surfaceData);
    }

    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    #if USE_FORWARD_PLUS
    for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
    #ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
    #endif
        {
            lightingData.additionalLightsColor += CalculateBlinnPhong(light, inputData, surfaceData);
        }
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
    #ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
    #endif
        {
            lightingData.additionalLightsColor += CalculateBlinnPhong(light, inputData, surfaceData);
        }
    LIGHT_LOOP_END
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * surfaceData.albedo;
    #endif

    return CalculateFinalColor(lightingData, surfaceData.alpha);
}

// Deprecated: Use the version which takes "SurfaceData" instead of passing all of these arguments...
half4 UniversalFragmentBlinnPhong(InputData inputData, half3 diffuse, half4 specularGloss, half smoothness, half3 emission, half alpha, half3 normalTS)
{
    SurfaceData surfaceData;

    surfaceData.albedo = diffuse;
    surfaceData.alpha = alpha;
    surfaceData.emission = emission;
    surfaceData.metallic = 0;
    surfaceData.occlusion = 1;
    surfaceData.smoothness = smoothness;
    surfaceData.specular = specularGloss.rgb;
    surfaceData.clearCoatMask = 0;
    surfaceData.clearCoatSmoothness = 1;
    surfaceData.normalTS = normalTS;

    return UniversalFragmentBlinnPhong(inputData, surfaceData);
}

////////////////////////////////////////////////////////////////////////////////
/// Unlit
////////////////////////////////////////////////////////////////////////////////
half4 UniversalFragmentBakedLit(InputData inputData, SurfaceData surfaceData)
{
    #if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, debugColor))
    {
        return debugColor;
    }
    #endif

    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    LightingData lightingData = CreateLightingData(inputData, surfaceData);

    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_AMBIENT_OCCLUSION))
    {
        lightingData.giColor *= aoFactor.indirectAmbientOcclusion;
    }

    return CalculateFinalColor(lightingData, surfaceData.albedo, surfaceData.alpha, inputData.fogCoord);
}

// Deprecated: Use the version which takes "SurfaceData" instead of passing all of these arguments...
half4 UniversalFragmentBakedLit(InputData inputData, half3 color, half alpha, half3 normalTS)
{
    SurfaceData surfaceData;

    surfaceData.albedo = color;
    surfaceData.alpha = alpha;
    surfaceData.emission = half3(0, 0, 0);
    surfaceData.metallic = 0;
    surfaceData.occlusion = 1;
    surfaceData.smoothness = 1;
    surfaceData.specular = half3(0, 0, 0);
    surfaceData.clearCoatMask = 0;
    surfaceData.clearCoatSmoothness = 1;
    surfaceData.normalTS = normalTS;

    return UniversalFragmentBakedLit(inputData, surfaceData);
}

#endif
