// WaterCausticsModules
// Copyright (c) 2021 Masataka Hakozaki

#ifndef WCE_CUSTOM_FUNCTION_FOR_SHADER_GRAPH_INCLUDED
#define WCE_CUSTOM_FUNCTION_FOR_SHADER_GRAPH_INCLUDED

#include "../Common/WaterCausticsEmissionFunc_Common.hlsl"

// Custom Function  (for ShaderGraph)
void WCE_WaterCausticsEmission_float(float3 WorldPos, half3 NormalWS, UnityTexture2D CausticsTex,
float Scale, float WaterSurfaceY, float WaterSurfaceAttenWide, float WaterSurfaceAttenOffset, half IntensityMainLit,
half IntensityAddLit, float ColorShiftU, float ColorShiftV, half LitSaturation, half NormalAttenIntensity,
half NormalAttenPower, half TransparentBack, out half3 EmissionColor) {

    EmissionColor = WCE_waterCausticsEmission(WorldPos, NormalWS, CausticsTex.tex, CausticsTex.samplerstate,
    Scale, WaterSurfaceY, WaterSurfaceY + WaterSurfaceAttenOffset, WaterSurfaceAttenWide, IntensityMainLit, IntensityAddLit,
    float2(ColorShiftU, ColorShiftV) * 0.01, LitSaturation, NormalAttenIntensity, NormalAttenPower, TransparentBack);
}

// Custom Function  Sync with effect script on the scene.  (for ShaderGraph)
void WCE_WaterCausticsEmissionSync_float(float3 WorldPos, half3 NormalWS, half3 BaseColor, out half3 EmissionColor) {
    EmissionColor = WCE_waterCausticsEmissionSync(WorldPos, NormalWS, BaseColor);
}

#endif

