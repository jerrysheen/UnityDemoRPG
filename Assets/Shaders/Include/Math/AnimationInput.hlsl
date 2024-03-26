#ifndef ANIMATION_INPUT
#define ANIMATION_INPUT

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

CBUFFER_START(UnityPerMaterial)
    float4 _FlagColor;
    float4 _SkinningTexSize;
    half4 _EmissionColor;
    float _UpwardShift;
    float _Dissolve;
    float _Edge;
CBUFFER_END

float _ShadowFalloff;
float4 _PlanarShadowColor;

UNITY_INSTANCING_BUFFER_START(Props)
    UNITY_DEFINE_INSTANCED_PROP(float, _CurFramIndex_Array)
    UNITY_DEFINE_INSTANCED_PROP(float, _PreFramIndex_Array)
    UNITY_DEFINE_INSTANCED_PROP(float, _TransProgress_Array)
    UNITY_DEFINE_INSTANCED_PROP(float, _HorizontalPlane_Array)
    UNITY_DEFINE_INSTANCED_PROP(float4, _DissolveColor_Array)
UNITY_INSTANCING_BUFFER_END(Props)

#define _CurFramIndex UNITY_ACCESS_INSTANCED_PROP(Props, _CurFramIndex_Array)
#define _PreFramIndex UNITY_ACCESS_INSTANCED_PROP(Props, _PreFramIndex_Array)
#define _TransProgress UNITY_ACCESS_INSTANCED_PROP(Props, _TransProgress_Array)
#define _HorizontalPlane UNITY_ACCESS_INSTANCED_PROP(Props, _HorizontalPlane_Array)
#define _DissolveColor UNITY_ACCESS_INSTANCED_PROP(Props, _DissolveColor_Array)

uniform sampler2D _SkinningTex;

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);
TEXTURE2D(_MaskTex);
SAMPLER(sampler_MaskTex);

#endif