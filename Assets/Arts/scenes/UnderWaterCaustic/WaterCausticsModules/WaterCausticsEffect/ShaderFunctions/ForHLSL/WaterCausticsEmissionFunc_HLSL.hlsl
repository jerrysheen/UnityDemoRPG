// WaterCausticsModules
// Copyright (c) 2021 Masataka Hakozaki

#ifndef WCE_CUSTOM_FUNCTION_FOR_HLSL_INCLUDED
#define WCE_CUSTOM_FUNCTION_FOR_HLSL_INCLUDED

#define REQUIRE_OPAQUE_TEXTURE 1
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
#include "../Common/WaterCausticsEmissionFunc_Common.hlsl"

// Custom Function  (for HLSL Scripting)
half3 WCE_WaterCausticsEmission(float3 WorldPos, half3 NormalWS, Texture2D CausticsTex, SamplerState CausticsTexSS, 
float Scale = 3, float WaterSurfaceY = 2, float WaterSurfaceAttenWide = 0.5, float WaterSurfaceAttenOffset = 0, 
half IntensityMainLit = 1, half IntensityAddLit = 1, float ColorShiftU = 0.4, float ColorShiftV = -0.1, half LitSaturation = 0.2, 
half NormalAttenIntensity = 1, half NormalAttenPower = 2, half TransparentBack = 0) {

    return WCE_waterCausticsEmission(WorldPos, NormalWS, CausticsTex, CausticsTexSS,
    Scale, WaterSurfaceY, WaterSurfaceY + WaterSurfaceAttenOffset, WaterSurfaceAttenWide, IntensityMainLit, IntensityAddLit,
    float2(ColorShiftU, ColorShiftV) * 0.01, LitSaturation, NormalAttenIntensity, NormalAttenPower, TransparentBack);
}

// Custom Function  Sync with effect script on the scene.  (for HLSL Scripting)
half3 WCE_WaterCausticsEmissionSync(float3 WorldPos, half3 NormalWS, half3 BaseColor = half3(1, 1, 1)) {
    return WCE_waterCausticsEmissionSync(WorldPos, NormalWS, BaseColor);
}

#endif

