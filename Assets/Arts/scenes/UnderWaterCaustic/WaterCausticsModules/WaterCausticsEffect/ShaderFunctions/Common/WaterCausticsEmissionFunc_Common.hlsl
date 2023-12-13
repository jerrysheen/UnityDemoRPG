// WaterCausticsModules
// Copyright (c) 2021 Masataka Hakozaki

#ifndef WCE_CUSTOM_FUNCTION_COMMON_INCLUDED
#define WCE_CUSTOM_FUNCTION_COMMON_INCLUDED

#include "../../Effect/Shader/WaterCausticsEffectCommon.hlsl"


CBUFFER_START(_WCECF_)
    float _WCECF_Scale;
    float _WCECF_WaterSurfaceY;
    float _WCECF_WaterSurfaceAttenWide;
    float _WCECF_WaterSurfaceAttenOffset;
    half _WCECF_IntensityMainLit;
    half _WCECF_IntensityAddLit;
    float2 _WCECF_ColorShift;
    half _WCECF_LitSaturation;
    half _WCECF_MulOpaqueIntensity;
    half _WCECF_NormalAttenIntensity;
    half _WCECF_NormalAttenPower;
    half _WCECF_TransparentBackside;
    float4x4 _WCECF_WldObjMatrixOfVolume;
    int _WCECF_ClipOutsideVolume;
    int _WCECF_UseImageMask;
CBUFFER_END

#if defined(WCE_USE_SAMPLER2D_INSTEAD_TEXTURE2D)
    sampler2D _WCECF_CausticsTex;
    sampler2D _WCECF_ImageMaskTex;
    #define WCE_TEX_PARAMS_RAW(texName) texName
    #define WCE_TEX_SAMPLE_RAW(texName, uv) tex2D(texName, uv)
#else
    TEXTURE2D(_WCECF_CausticsTex);
    TEXTURE2D(_WCECF_ImageMaskTex);
    SAMPLER(sampler_WCECF_CausticsTex);
    SAMPLER(sampler_WCECF_ImageMaskTex);
    #define WCE_TEX_PARAMS_RAW(texName) texName, sampler##texName
    #define WCE_TEX_SAMPLE_RAW(texName, uv) texName.Sample(sampler##texName, (uv))
#endif


half3 WCE_emissionSyncCore(float3 WorldPos, half3 NormalWS, half3 BaseColor, half intensity = 1) {
    half3 c = WCE_waterCausticsEmission(WorldPos, NormalWS, WCE_TEX_PARAMS_RAW(_WCECF_CausticsTex),
    _WCECF_Scale, _WCECF_WaterSurfaceY, _WCECF_WaterSurfaceY + _WCECF_WaterSurfaceAttenOffset,
    _WCECF_WaterSurfaceAttenWide, _WCECF_IntensityMainLit * intensity, _WCECF_IntensityAddLit * intensity,
    _WCECF_ColorShift, _WCECF_LitSaturation, _WCECF_NormalAttenIntensity, _WCECF_NormalAttenPower, _WCECF_TransparentBackside);

    c *= 1 - (1 - BaseColor) * _WCECF_MulOpaqueIntensity;
    return c;
}

half3 WCE_waterCausticsEmissionSync(float3 WorldPos, half3 NormalWS, half3 BaseColor) {
    
    [branch] if (_WCECF_ClipOutsideVolume != 0 || _WCECF_UseImageMask != 0) {
        float3 posO = mul(_WCECF_WldObjMatrixOfVolume, float4(WorldPos, 1)).xyz;
        [branch] if (_WCECF_ClipOutsideVolume != 0 && (abs(posO.x) > 0.5 || abs(posO.y) > 0.5 || abs(posO.z) > 0.5)) {
            return half3(0, 0, 0);
        } else {
            [branch] if (_WCECF_UseImageMask != 0) {
                half imageMask = WCE_TEX_SAMPLE_RAW(_WCECF_ImageMaskTex, posO.xz + 0.5).r;
                [branch] if (imageMask < 0.0001) {
                    return half3(0, 0, 0);
                } else {
                    return WCE_emissionSyncCore(WorldPos, NormalWS, BaseColor, imageMask);
                }
            } else {
                return WCE_emissionSyncCore(WorldPos, NormalWS, BaseColor);
            }
        }
    } else {
        return WCE_emissionSyncCore(WorldPos, NormalWS, BaseColor);
    }
}

#endif

