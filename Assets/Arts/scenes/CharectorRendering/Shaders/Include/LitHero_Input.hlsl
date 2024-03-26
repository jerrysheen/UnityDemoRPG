#ifndef UNIVERSAL_LIT_INPUT_INCLUDED
#define UNIVERSAL_LIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"

#if defined(_DETAIL_MULX2) || defined(_DETAIL_SCALED)
#define _DETAIL
#endif

// NOTE: Do not ifdef the properties here as SRP batcher can not handle different layouts.
CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
float4 _DetailAlbedoMap_ST;
half4 _BaseColor;
half4 _SpecColor;
half4 _EmissionColor;
half _Cutoff;
half _Smoothness;
half _Metallic;
half _BumpScale;
half _Parallax;
half _OcclusionStrength;
half _ClearCoatMask;
half _ClearCoatSmoothness;
half _DetailAlbedoMapScale;
half _DetailNormalMapScale;
half _Surface;

// PBR Hero...
float _DetailNormalAttenuation;
float _BentNormalWeight;
half4 _cVirtualLitDir;
half4 _Tint;
half4 _sssColor;
float _CurvatureOffset;
float _CuvratureScale;
float _Gray;
float _Hue;
float _Saturation;
float _Luminance;
float _Thickness;
float _LocalShadowAtten;
float4 _ScatterColor;

half4 _Anisotropy;
float _AnisotroySpecBoardLine;

// eye:
half4 _Color;
//half _Rotate;
half _EyeCubeLODOffSet;
half _EyeCubeAtten;
half4 _BaseVec;
half _LightMapAtten;

CBUFFER_END




// NOTE: Do not ifdef the properties for dots instancing, but ifdef the actual usage.
// Otherwise you might break CPU-side as property constant-buffer offsets change per variant.
// NOTE: Dots instancing is orthogonal to the constant buffer above.
#ifdef UNITY_DOTS_INSTANCING_ENABLED

UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
    UNITY_DOTS_INSTANCED_PROP(float4, _BaseColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _SpecColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _EmissionColor)
    UNITY_DOTS_INSTANCED_PROP(float , _Cutoff)
    UNITY_DOTS_INSTANCED_PROP(float , _Smoothness)
    UNITY_DOTS_INSTANCED_PROP(float , _Metallic)
    UNITY_DOTS_INSTANCED_PROP(float , _BumpScale)
    UNITY_DOTS_INSTANCED_PROP(float , _Parallax)
    UNITY_DOTS_INSTANCED_PROP(float , _OcclusionStrength)
    UNITY_DOTS_INSTANCED_PROP(float , _ClearCoatMask)
    UNITY_DOTS_INSTANCED_PROP(float , _ClearCoatSmoothness)
    UNITY_DOTS_INSTANCED_PROP(float , _DetailAlbedoMapScale)
    UNITY_DOTS_INSTANCED_PROP(float , _DetailNormalMapScale)
    UNITY_DOTS_INSTANCED_PROP(float , _Surface)
UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

#define _BaseColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4 , _BaseColor)
#define _SpecColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4 , _SpecColor)
#define _EmissionColor          UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4 , _EmissionColor)
#define _Cutoff                 UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _Cutoff)
#define _Smoothness             UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _Smoothness)
#define _Metallic               UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _Metallic)
#define _BumpScale              UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _BumpScale)
#define _Parallax               UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _Parallax)
#define _OcclusionStrength      UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _OcclusionStrength)
#define _ClearCoatMask          UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _ClearCoatMask)
#define _ClearCoatSmoothness    UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _ClearCoatSmoothness)
#define _DetailAlbedoMapScale   UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _DetailAlbedoMapScale)
#define _DetailNormalMapScale   UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _DetailNormalMapScale)
#define _Surface                UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _Surface)
#endif

TEXTURE2D(_ParallaxMap);        SAMPLER(sampler_ParallaxMap);
TEXTURE2D(_OcclusionMap);       SAMPLER(sampler_OcclusionMap);
TEXTURE2D(_DetailMask);         SAMPLER(sampler_DetailMask);
TEXTURE2D(_DetailAlbedoMap);    SAMPLER(sampler_DetailAlbedoMap);
TEXTURE2D(_DetailNormalMap);    SAMPLER(sampler_DetailNormalMap);
TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_SpecGlossMap);       SAMPLER(sampler_SpecGlossMap);
TEXTURE2D(_ClearCoatMap);       SAMPLER(sampler_ClearCoatMap);
TEXTURE2D(_DetailNormal);       SAMPLER(sampler_DetailNormal);
TEXTURE2D(_Channel);            SAMPLER(sampler_Channel);
TEXTURE2D(_ScatterLUT);         SAMPLER(sampler_ScatterLUT);
TEXTURE2D(_ShiftTex);         SAMPLER(sampler_ShiftTex);
TEXTURE2D(_MatCapTex);         SAMPLER(sampler_MatCapTex);

TEXTURE2D(_MainTex);            SAMPLER(sampler_MainTex);
//TEXTURE2D(_EyeDepthTex);        SAMPLER(sampler_EyeDepthTex);
//TEXTURE2D(_IrisTex);            SAMPLER(sampler_IrisTex);
//TEXTURE2D(_ScleraTex);          SAMPLER(sampler_ScleraTex);
TEXTURECUBE(_EyeCubeMap);          SAMPLER(sampler_EyeCubeMap);
TEXTURE2D(_LightMap);          SAMPLER(sampler_LightMap);
//TEXTURE2D(_EyeWorldDirMap);          SAMPLER(sampler_EyeWorldDirMap);








            
struct HeroSurfaceData
{
    half3 albedo;
    half3 specular;
    half  metallic;
    half  smoothness;
    half3 normalTS;
    half3 emission;
    half  occlusion;
    half  alpha;
    half  clearCoatMask;
    half  clearCoatSmoothness;
    half3 channel;
    half3 bentNormalTS;
    half4 _cVirtualLitDir;
    half4 _Anisotropy;
    half4 shiftTex;
    float _AnisotroySpecBoardLine;
    half3 _sssColor;
    float curvatureOffset;
    float curvatureScale;
    float thickness;
    half3 tannormal;
    half3 binnormal;
    float localShadowAtten;
};


SurfaceData CopyHeroSurfaceDataToSurfaceData(HeroSurfaceData herosurfaceData)
{
    SurfaceData surfaceData;
    surfaceData.albedo              = herosurfaceData.albedo;             
    surfaceData.specular            = herosurfaceData.specular;           
    surfaceData.metallic            = herosurfaceData.metallic;           
    surfaceData.smoothness          = herosurfaceData.smoothness;         
    surfaceData.normalTS            = herosurfaceData.normalTS;           
    surfaceData.emission            = herosurfaceData.emission;           
    surfaceData.occlusion           = herosurfaceData.occlusion;          
    surfaceData.alpha               = herosurfaceData.alpha;              
    surfaceData.clearCoatMask       = herosurfaceData.clearCoatMask;      
    surfaceData.clearCoatSmoothness = herosurfaceData.clearCoatSmoothness;
    return surfaceData;
}

#ifdef _SPECULAR_SETUP
    #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, uv)
#else
    #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv)
#endif

half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
{
    half4 specGloss;

//#ifdef _METALLICSPECGLOSSMAP
    specGloss = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv);
    // #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
    //     specGloss.a = albedoAlpha * _Smoothness;
    // #else
        specGloss.g *= _Smoothness;
        specGloss.r *= _Metallic;
    //#endif
// #else // _METALLICSPECGLOSSMAP
//     #if _SPECULAR_SETUP
//         specGloss.rgb = _SpecColor.rgb;
//     #else
//         specGloss.rgb = _Metallic.rrr;
//     #endif
//
//     #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
//         specGloss.a = albedoAlpha * _Smoothness;
//     #else
//         specGloss.a = _Smoothness;
//     #endif
// #endif

    return specGloss;
}

half SampleOcclusion(float2 uv)
{
    #ifdef _OCCLUSIONMAP
        half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
        return LerpWhiteTo(occ, _OcclusionStrength);
    #else
        return half(1.0);
    #endif
}


// Returns clear coat parameters
// .x/.r == mask
// .y/.g == smoothness
half2 SampleClearCoat(float2 uv)
{
#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
    half2 clearCoatMaskSmoothness = half2(_ClearCoatMask, _ClearCoatSmoothness);

#if defined(_CLEARCOATMAP)
    clearCoatMaskSmoothness *= SAMPLE_TEXTURE2D(_ClearCoatMap, sampler_ClearCoatMap, uv).rg;
#endif

    return clearCoatMaskSmoothness;
#else
    return half2(0.0, 1.0);
#endif  // _CLEARCOAT
}

void ApplyPerPixelDisplacement(half3 viewDirTS, inout float2 uv)
{
#if defined(_PARALLAXMAP)
    uv += ParallaxMapping(TEXTURE2D_ARGS(_ParallaxMap, sampler_ParallaxMap), viewDirTS, _Parallax, uv);
#endif
}

// Used for scaling detail albedo. Main features:
// - Depending if detailAlbedo brightens or darkens, scale magnifies effect.
// - No effect is applied if detailAlbedo is 0.5.
half3 ScaleDetailAlbedo(half3 detailAlbedo, half scale)
{
    // detailAlbedo = detailAlbedo * 2.0h - 1.0h;
    // detailAlbedo *= _DetailAlbedoMapScale;
    // detailAlbedo = detailAlbedo * 0.5h + 0.5h;
    // return detailAlbedo * 2.0f;

    // A bit more optimized
    return half(2.0) * detailAlbedo * scale - scale + half(1.0);
}

half3 ApplyDetailAlbedo(float2 detailUv, half3 albedo, half detailMask)
{
#if defined(_DETAIL)
    half3 detailAlbedo = SAMPLE_TEXTURE2D(_DetailAlbedoMap, sampler_DetailAlbedoMap, detailUv).rgb;

    // In order to have same performance as builtin, we do scaling only if scale is not 1.0 (Scaled version has 6 additional instructions)
#if defined(_DETAIL_SCALED)
    detailAlbedo = ScaleDetailAlbedo(detailAlbedo, _DetailAlbedoMapScale);
#else
    detailAlbedo = half(2.0) * detailAlbedo;
#endif

    return albedo * LerpWhiteTo(detailAlbedo, detailMask);
#else
    return albedo;
#endif
}

half3 ApplyDetailNormal(float2 detailUv, half3 normalTS, half detailMask)
{
#if defined(_DETAIL)
#if BUMP_SCALE_NOT_SUPPORTED
    half3 detailNormalTS = UnpackNormal(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUv));
#else
    half3 detailNormalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailNormalMap, detailUv), _DetailNormalMapScale);
#endif

    // With UNITY_NO_DXT5nm unpacked vector is not normalized for BlendNormalRNM
    // For visual consistancy we going to do in all cases
    detailNormalTS = normalize(detailNormalTS);

    return lerp(normalTS, BlendNormalRNM(normalTS, detailNormalTS), detailMask); // todo: detailMask should lerp the angle of the quaternion rotation, not the normals
#else
    return normalTS;
#endif
}

inline void InitializeStandardLitSurfaceData(float2 uv, out HeroSurfaceData outSurfaceData)
{
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

    half4 specGloss = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv).xyzw;
    outSurfaceData.albedo = albedoAlpha.rgb * _Tint.rgb;
    outSurfaceData.albedo = AlphaModulate(outSurfaceData.albedo, outSurfaceData.alpha);

// #if _SPECULAR_SETUP
//     outSurfaceData.metallic = half(1.0);
//     outSurfaceData.specular = specGloss.rgb;
// #else
    outSurfaceData.metallic = specGloss.r * _Metallic;
    outSurfaceData.specular = half3(0.0, 0.0, 0.0);
//#endif

    outSurfaceData.smoothness = specGloss.a * _Smoothness;
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    outSurfaceData.occlusion = specGloss.g * _OcclusionStrength;
    //outSurfaceData.occlusion = SampleOcclusion(uv);
    //outSurfaceData.occlusion = specGloss.b;
    //outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
    //outSurfaceData.emission = specGloss.b;
    outSurfaceData.emission = 0.0;

// #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
//     half2 clearCoat = SampleClearCoat(uv);
//     outSurfaceData.clearCoatMask       = clearCoat.r;
//     outSurfaceData.clearCoatSmoothness = clearCoat.g;
// #else
    outSurfaceData.clearCoatMask       = half(0.0);
    outSurfaceData.clearCoatSmoothness = half(0.0);
//#endif

// #if defined(_DETAIL)
//     half detailMask = SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, uv).a;
//     float2 detailUv = uv * _DetailAlbedoMap_ST.xy + _DetailAlbedoMap_ST.zw;
//     outSurfaceData.albedo = ApplyDetailAlbedo(detailUv, outSurfaceData.albedo, detailMask);
//     outSurfaceData.normalTS = ApplyDetailNormal(detailUv, outSurfaceData.normalTS, detailMask);
// #endif

    outSurfaceData.channel = SAMPLE_TEXTURE2D(_Channel, sampler_Channel, uv).xyz;
    #ifdef EnableBentNormal
    outSurfaceData.bentNormalTS = SampleNormal(uv, TEXTURE2D_ARGS(_DetailNormal, sampler_DetailNormal), 1.0f);
    #else
    outSurfaceData.bentNormalTS = outSurfaceData.normalTS;
    #endif

    outSurfaceData._cVirtualLitDir = _cVirtualLitDir;
    outSurfaceData._sssColor = _sssColor;
    outSurfaceData.curvatureOffset = _CurvatureOffset;
    outSurfaceData.curvatureScale = _CuvratureScale;
    outSurfaceData.thickness = _Thickness;
    outSurfaceData.localShadowAtten = _LocalShadowAtten;
    
    outSurfaceData._Anisotropy = _Anisotropy;
    outSurfaceData._AnisotroySpecBoardLine = _AnisotroySpecBoardLine;
    outSurfaceData.shiftTex = SAMPLE_TEXTURE2D(_ShiftTex, sampler_ShiftTex, uv);
    outSurfaceData.tannormal=float3(1,1,1);
    outSurfaceData.binnormal=float3(1,1,1);
}


inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

    half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
    outSurfaceData.albedo = albedoAlpha.rgb * _Tint.rgb;
    outSurfaceData.albedo = AlphaModulate(outSurfaceData.albedo, outSurfaceData.alpha);

    #if _SPECULAR_SETUP
    outSurfaceData.metallic = half(1.0);
    outSurfaceData.specular = specGloss.rgb;
    #else
    outSurfaceData.metallic = specGloss.r;
    outSurfaceData.specular = half3(0.0, 0.0, 0.0);
    #endif

    outSurfaceData.smoothness = specGloss.a;
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    outSurfaceData.occlusion = SampleOcclusion(uv);
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));

    #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
    half2 clearCoat = SampleClearCoat(uv);
    outSurfaceData.clearCoatMask       = clearCoat.r;
    outSurfaceData.clearCoatSmoothness = clearCoat.g;
    #else
    outSurfaceData.clearCoatMask       = half(0.0);
    outSurfaceData.clearCoatSmoothness = half(0.0);
    #endif

    #if defined(_DETAIL)
    half detailMask = SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, uv).a;
    float2 detailUv = uv * _DetailAlbedoMap_ST.xy + _DetailAlbedoMap_ST.zw;
    outSurfaceData.albedo = ApplyDetailAlbedo(detailUv, outSurfaceData.albedo, detailMask);
    outSurfaceData.normalTS = ApplyDetailNormal(detailUv, outSurfaceData.normalTS, detailMask);
    #endif
}
#endif // UNIVERSAL_INPUT_SURFACE_PBR_INCLUDED
