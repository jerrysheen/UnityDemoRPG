// WaterCausticsModules
// Copyright (c) 2021 Masataka Hakozaki

#ifndef WCE_COMMON_INCLUDED
#define WCE_COMMON_INCLUDED

#define WCE_LIT_DIR_MIN_Y 0.05

// ShadowMask
half4 WCE_getShadowMask() {
    #if defined(SHADERGRAPH_PREVIEW) || defined(_RECEIVE_SHADOWS_OFF)
        return half4(1, 1, 1, 1);
    #else
        return SAMPLE_SHADOWMASK(input.lightmapUV);
    #endif
}

// Main Light Data
void WCE_getMainLitData(float3 WorldPos, half4 ShadowMask, out half3 litDir, out half3 litColor, out half litAtten, out half litShadow) {
    #if defined(SHADERGRAPH_PREVIEW)
        litDir = normalize(half3(0, 1, -0.4));
        litColor = half3(1, 1, 1);
        litAtten = litShadow = 1;
    #else
        #if (defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) || defined(_MAIN_LIGHT_SHADOWS_SCREEN)) && !defined(_RECEIVE_SHADOWS_OFF)
            #if defined(_MAIN_LIGHT_SHADOWS_SCREEN)
                float4 clipPos = TransformWorldToHClip(WorldPos);
                float4 shadowCoord = ComputeScreenPos(clipPos);
            #else
                float4 shadowCoord = TransformWorldToShadowCoord(WorldPos);
            #endif
            Light lit = GetMainLight(shadowCoord, WorldPos, ShadowMask);
        #else
            Light lit = GetMainLight();
        #endif
        litDir = lit.direction;
        litColor = lit.color;
        litAtten = lit.distanceAttenuation;
        litShadow = lit.shadowAttenuation;
    #endif
}

// Additional Light Data
void WCE_getAdditionalLitData(uint idx, float3 WorldPos, half4 ShadowMask, out half3 litDir, out half3 litColor, out half litAtten, out half litShadow) {
    #if defined(SHADERGRAPH_PREVIEW)
        litDir = litColor = half3(0, -1, 0);
        litAtten = litShadow = 0;
    #else
        #if defined(_ADDITIONAL_LIGHT_SHADOWS) && !defined(_RECEIVE_SHADOWS_OFF)
            Light lit = GetAdditionalLight(idx, WorldPos, ShadowMask);
        #else
            Light lit = GetAdditionalLight(idx, WorldPos);
        #endif
        litDir = lit.direction;
        litColor = lit.color;
        litAtten = lit.distanceAttenuation;
        litShadow = lit.shadowAttenuation;
    #endif
}


// ライトが水面より下にあるか判別  ( below:1, Above:-1 )
float WCE_signUnderWaterMainLit(half3 litDir) {
    return step(0, litDir.y) * 2 - 1;
}
float WCE_signUnderWaterAddLit(uint idx, float WaterSurfaceY) {
    #if defined(SHADERGRAPH_PREVIEW)
        return -1;
    #else
        int perObjectLightIndex = GetPerObjectLightIndex(idx);
        #if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
            float4 litPos = _AdditionalLightsBuffer[perObjectLightIndex].position;
        #else
            float4 litPos = _AdditionalLightsPosition[perObjectLightIndex];
        #endif
        // litPos.w : 0  DirectionalLight
        return step(WaterSurfaceY * litPos.w, litPos.y) * 2 - 1;
    #endif
}


// 水面付近 Y軸減衰グラデーション
half WCE_axisYAttenMainLit(float3 WorldPos, half3 litDir, float AxisYAttenBase, float AxisYAttenWideSafe) {
    float signLitUnderWater = WCE_signUnderWaterMainLit(litDir);
    return saturate((AxisYAttenBase - WorldPos.y) / AxisYAttenWideSafe * signLitUnderWater);
}
half WCE_axisYAttenAddLit(uint idx, float3 WorldPos, float WaterSurfaceY, float AxisYAttenBase, float AxisYAttenWideSafe) {
    float signLitUnderWater = WCE_signUnderWaterAddLit(idx, WaterSurfaceY);
    return saturate((AxisYAttenBase - WorldPos.y) / AxisYAttenWideSafe * signLitUnderWater);
}


// ライト角度での減衰
inline half WCE_litDirAtten(half3 litDir) {
    return saturate((abs(litDir.y) - WCE_LIT_DIR_MIN_Y) / (0.3 - WCE_LIT_DIR_MIN_Y));
}


// 減衰をまとめる
half WCE_atten(half litAtten, half litShadow, half3 litDir, half dotLN, half axisYAtten, half NormalAttenIntensity, half NormalAttenPowSafe, half TransparentBack) {
    half dotLNp = max(dotLN, 0);
    dotLNp = pow(dotLNp, NormalAttenPowSafe);
    dotLNp = 1 - (1 - dotLNp) * NormalAttenIntensity;
    half atten = litShadow * dotLNp;
    [branch] if (TransparentBack > 0 && dotLN < 0) {
        half dotLNm = max(-dotLN, 0);
        dotLNm = pow(dotLNm, NormalAttenPowSafe);
        dotLNm = 1 - (1 - dotLNm) * NormalAttenIntensity;
        atten = max(atten, dotLNm * TransparentBack);
    }
    half litDirAtten = WCE_litDirAtten(litDir);
    return atten * litAtten * litDirAtten * axisYAtten;
}


// 彩度調整
inline half3 WCE_adjustSaturation(half3 color, half saturation) {
    half3 gray = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b;
    return lerp(gray, color, saturation);
}


#if defined(WCE_USE_SAMPLER2D_INSTEAD_TEXTURE2D)
    #define WCE_TEX_ARGS(texName) sampler2D texName
    #define WCE_TEX_PARAMS(texName) texName
    #define WCE_TEX_SAMPLE(texName, uv) tex2D(texName, uv)
#else
    #define WCE_TEX_ARGS(texName) Texture2D texName, SamplerState texName##SS
    #define WCE_TEX_PARAMS(texName) texName, texName##SS
    #define WCE_TEX_SAMPLE(texName, uv) texName.Sample(texName##SS, uv)
#endif


// テクスチャサンプリング
half3 WCE_sampleCausticsTex(float3 WorldPos, WCE_TEX_ARGS(CausticsTex), half3 litDir, float ScaleSafe, float2 ColorShift, float WaterSurfaceY) {
    // ※ litDir.yの絶対値はWCE_LIT_DIR_MIN_Y以上、ScaleSafeは0.0001以上のはずなので0除算チェック不要
    float2 uvG = (((WaterSurfaceY - WorldPos.y) * (litDir.xz / litDir.y)) + WorldPos.xz) / ScaleSafe;
    float2 uvR = uvG - ColorShift;
    float2 uvB = uvG + ColorShift;
    half3 c;
    c.r = WCE_TEX_SAMPLE(CausticsTex, uvR).r;
    c.g = WCE_TEX_SAMPLE(CausticsTex, uvG).g;
    c.b = WCE_TEX_SAMPLE(CausticsTex, uvB).b;
    return c;
}


// Main
half3 WCE_waterCausticsEmission(float3 WorldPos, half3 NormalWS, WCE_TEX_ARGS(CausticsTex), float Scale,
float WaterSurfaceY, float AxisYAttenBase, float AxisYAttenWide, half IntensityMainLit, half IntensityAddLit,
float2 ColorShift, half LitSaturation, half NormalAttenIntensity, half NormalAttenPow, half TransparentBack) {

    half3 litDir, litColor;
    half litAtten, litShadow;
    half4 shadowMask = WCE_getShadowMask();
    half3 color = half3(0, 0, 0);
    float ScaleSafe = max(Scale, 0.0001);
    float AxisYAttenWideSafe = max(AxisYAttenWide, 0.00001);
    half NormalAttenPowSafe = max(NormalAttenPow, 1);

    [branch] if (IntensityMainLit > 0) {
        WCE_getMainLitData(WorldPos, shadowMask, litDir, litColor, litAtten, litShadow);
        half dotLN = dot(litDir, NormalWS);
        [branch] if (dotLN < 0 && (TransparentBack > 0 || NormalAttenIntensity < 1)) litShadow = 1;
        [branch] if (litAtten * litShadow > 0) {
            half axisYAtten = WCE_axisYAttenMainLit(WorldPos, litDir, AxisYAttenBase, AxisYAttenWideSafe);
            half atten = WCE_atten(litAtten, litShadow, litDir, dotLN, axisYAtten, NormalAttenIntensity, NormalAttenPowSafe, TransparentBack);
            [branch] if (atten > 0) {
                half3 texColor = WCE_sampleCausticsTex(WorldPos, WCE_TEX_PARAMS(CausticsTex), litDir, ScaleSafe, ColorShift, WaterSurfaceY);
                litColor = WCE_adjustSaturation(litColor, LitSaturation);
                color = texColor * litColor * atten * IntensityMainLit;
            }
        }
    }
    #if defined(_ADDITIONAL_LIGHTS) && !defined(SHADERGRAPH_PREVIEW)
        [branch] if (IntensityAddLit > 0) {
            uint pixelLitCnt = GetAdditionalLightsCount();
            [unroll(8)] for (uint i = 0u; i < pixelLitCnt; i++) {
                WCE_getAdditionalLitData(i, WorldPos, shadowMask, litDir, litColor, litAtten, litShadow);
                half dotLN = dot(litDir, NormalWS);
                [branch] if (dotLN < 0 && (TransparentBack > 0 || NormalAttenIntensity < 1)) litShadow = 1;
                [branch] if (litAtten * litShadow > 0) {
                    half axisYAtten = WCE_axisYAttenAddLit(i, WorldPos, WaterSurfaceY, AxisYAttenBase, AxisYAttenWideSafe);
                    half atten = WCE_atten(litAtten, litShadow, litDir, dotLN, axisYAtten, NormalAttenIntensity, NormalAttenPowSafe, TransparentBack);
                    [branch] if (atten > 0) {
                        half3 texColor = WCE_sampleCausticsTex(WorldPos, WCE_TEX_PARAMS(CausticsTex), litDir, ScaleSafe, ColorShift, WaterSurfaceY);
                        litColor = WCE_adjustSaturation(litColor, LitSaturation);
                        color += texColor * litColor * atten * IntensityAddLit;
                    }
                }
            }
        }
    #endif

    return color;
}


#endif
