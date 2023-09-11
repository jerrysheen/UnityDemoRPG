#ifndef UNIVERSAL_MAINCITY_LIT_INPUT_INCLUDED
#define UNIVERSAL_MAINCITY_LIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

#if defined(_DETAIL_MULX2) || defined(_DETAIL_SCALED)
#define _DETAIL
#endif


CBUFFER_START(UnityPerMaterial)
float4 _MainTex_ST;
half4 _BaseColor;
half _Cutoff;

float4 _BaseMap_ST;
float4 _HeightPack0_ST;
float4 _GlobalNormal_ST;
float4 _AlbedoPack0_ST;
float4 _AlbedoPack1_ST;
float4 _AlbedoPack2_ST;
float4 _NormalPack0_ST;
half4 _Color;
float _GlobalNormalBlendRate;
float _LODValue01;
float _LODValue00;
float _offSetY;
float _NormalScale00;
float _NormalScale01;
float _NormalScale02;
float _offSetX;
float _diffuseUVoffSetX;
float _diffuseUVoffSetY;

float4 _PosInfo;
float4 _GridVSPixel;
uniform float4 _AlbedoPack0_TexelSize;
float _LODScale;
float _LODPram;
float _LODAdd;
int _GLobalMipMapLimit;
CBUFFER_END

           // TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
TEXTURE2D(_WeightPack0);            SAMPLER(sampler_WeightPack0);
TEXTURE2D(_WeightPack1);            SAMPLER(sampler_WeightPack1);
TEXTURE2D(_HeightPack0);            SAMPLER(sampler_HeightPack0);
TEXTURE2D(_HeightPack1);            SAMPLER(sampler_HeightPack1);
TEXTURE2D(_GlobalNormal);            SAMPLER(sampler_GlobalNormal);
TEXTURE2D( _AlbedoPack0);           SAMPLER(sampler_AlbedoPack0);
TEXTURE2D( _NormalPack0);          SAMPLER(sampler_NormalPack0);
TEXTURE2D( _AlbedoPack1);           SAMPLER(sampler_AlbedoPack1);
TEXTURE2D(_NormalPack1);          SAMPLER(sampler_NormalPack1);
TEXTURE2D(_NormalPack2);          SAMPLER(sampler_NormalPack2);
TEXTURE2D( _AlbedoPack2);          SAMPLER(sampler_AlbedoPack2);


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

#define _BaseColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata_BaseColor)
#define _SpecColor              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata_SpecColor)
#define _EmissionColor          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata_EmissionColor)
#define _Cutoff                 UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_Cutoff)
#define _Smoothness             UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_Smoothness)
#define _Metallic               UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_Metallic)
#define _BumpScale              UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_BumpScale)
#define _Parallax               UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_Parallax)
#define _OcclusionStrength      UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_OcclusionStrength)
#define _ClearCoatMask          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_ClearCoatMask)
#define _ClearCoatSmoothness    UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_ClearCoatSmoothness)
#define _DetailAlbedoMapScale   UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_DetailAlbedoMapScale)
#define _DetailNormalMapScale   UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_DetailNormalMapScale)
#define _Surface                UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_Surface)
#endif

// TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
//  TEXTURE2D(_WeightPack0);            SAMPLER(sampler_WeightPack0);
// TEXTURE2D(_WeightPack1);            SAMPLER(sampler_WeightPack1);
// TEXTURE2D(_HeightPack0);            SAMPLER(sampler_HeightPack0);
// TEXTURE2D(_HeightPack1);            SAMPLER(sampler_HeightPack1);
// TEXTURE2D(_GlobalNormal);            SAMPLER(sampler_GlobalNormal);
// TEXTURE2D( _AlbedoPack0);           SAMPLER(sampler_AlbedoPack0);
// TEXTURE2D( _NormalPack0);          SAMPLER(sampler_NormalPack0);
// TEXTURE2D( _AlbedoPack1);           SAMPLER(sampler_AlbedoPack1);
// TEXTURE2D(_NormalPack1);          SAMPLER(sampler_NormalPack1);
// TEXTURE2D(_NormalPack2);          SAMPLER(sampler_NormalPack2);
// TEXTURE2D( _AlbedoPack2);          SAMPLER(sampler_AlbedoPack2);

#ifdef _SPECULAR_SETUP
    #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, uv)
#else
    #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv)
#endif

// half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
// {
//     half4 specGloss;
//
// #ifdef _METALLICSPECGLOSSMAP
//     specGloss = half4(SAMPLE_METALLICSPECULAR(uv));
//     #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
//         specGloss.a = albedoAlpha * _Smoothness;
//     #else
//         specGloss.a *= _Smoothness;
//     #endif
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
//
//     return specGloss;
// }

half SampleOcclusion(float2 uv)
{
    #ifdef _OCCLUSIONMAP
        half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
        return LerpWhiteTo(occ, _OcclusionStrength);
    #else
        return half(1.0);
    #endif
}


// // Returns clear coat parameters
// // .x/.r == mask
// // .y/.g == smoothness
// half2 SampleClearCoat(float2 uv)
// {
// #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
//     half2 clearCoatMaskSmoothness = half2(_ClearCoatMask, _ClearCoatSmoothness);
//
// #if defined(_CLEARCOATMAP)
//     clearCoatMaskSmoothness *= SAMPLE_TEXTURE2D(_ClearCoatMap, sampler_ClearCoatMap, uv).rg;
// #endif
//
//     return clearCoatMaskSmoothness;
// #else
//     return half2(0.0, 1.0);
// #endif  // _CLEARCOAT
// }
//
// void ApplyPerPixelDisplacement(half3 viewDirTS, inout float2 uv)
// {
// #if defined(_PARALLAXMAP)
//     uv += ParallaxMapping(TEXTURE2D_ARGS(_ParallaxMap, sampler_ParallaxMap), viewDirTS, _Parallax, uv);
// #endif
// }

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

half3 GetBreathingColor()
{
#ifdef _BREATHING_ON
    return (sin(6.28318530718 * _BreathingSpeed * _Time.y) + 1) / 2 * _BreathingColor.rgb
    * step(_BreathingPauseTime, fmod(_Time.y, _BreathingPauseTime + _BreathingDurationTime));
#else
    return 0;
#endif
}

// inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
// {
//     half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
//     outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
//
//     half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
//     outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
//     outSurfaceData.albedo = AlphaModulate(outSurfaceData.albedo, outSurfaceData.alpha);
//
// #if _SPECULAR_SETUP
//     outSurfaceData.metallic = half(1.0);
//     outSurfaceData.specular = specGloss.rgb;
// #else
//     outSurfaceData.metallic = specGloss.r;
//     outSurfaceData.specular = half3(0.0, 0.0, 0.0);
// #endif
//
//     outSurfaceData.smoothness = specGloss.a;
//     outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
//     outSurfaceData.occlusion = SampleOcclusion(uv);
//     outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
//     outSurfaceData.emission += GetBreathingColor();
//
// #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
//     half2 clearCoat = SampleClearCoat(uv);
//     outSurfaceData.clearCoatMask       = clearCoat.r;
//     outSurfaceData.clearCoatSmoothness = clearCoat.g;
// #else
//     outSurfaceData.clearCoatMask       = half(0.0);
//     outSurfaceData.clearCoatSmoothness = half(0.0);
// #endif
//
// #if defined(_DETAIL)
//     half detailMask = SAMPLE_TEXTURE2D(_DetailMask, sampler_DetailMask, uv).a;
//     float2 detailUv = uv * _DetailAlbedoMap_ST.xy + _DetailAlbedoMap_ST.zw;
//     outSurfaceData.albedo = ApplyDetailAlbedo(detailUv, outSurfaceData.albedo, detailMask);
//     outSurfaceData.normalTS = ApplyDetailNormal(detailUv, outSurfaceData.normalTS, detailMask);
// #endif
// }



#endif // UNIVERSAL_INPUT_SURFACE_PBR_INCLUDED
