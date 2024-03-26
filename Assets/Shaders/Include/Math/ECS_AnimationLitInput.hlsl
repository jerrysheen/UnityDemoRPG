#ifndef ECS_ANIMATION_LITINPUT
#define ECS_ANIMATION_LITINPUT

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

CBUFFER_START(UnityPerMaterial)
    float _CurFramIndex;
    float _PreFramIndex;
    float _TransProgress;
    float _Dissolve;

    
    float4 _FlagColor;
    float4 _DissolveColor;
    float4 _SkinningTexSize;

    // shadow input
    float4 _PlanarShadowColor;
    float4 _LightDir;
    float _ShadowFalloff;
    float _UpwardShift;
    float _HorizontalPlane;

    float _Edge;
    half4 _EmissionColor;

CBUFFER_END

#ifdef UNITY_DOTS_INSTANCING_ENABLED

UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
    UNITY_DOTS_INSTANCED_PROP(float, _CurFramIndex)
    UNITY_DOTS_INSTANCED_PROP(float, _PreFramIndex)
    UNITY_DOTS_INSTANCED_PROP(float, _TransProgress)
    UNITY_DOTS_INSTANCED_PROP(float, _Dissolve)
    UNITY_DOTS_INSTANCED_PROP(float, _Edge)
    UNITY_DOTS_INSTANCED_PROP(float4, _FlagColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _DissolveColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _SkinningTexSize)
    UNITY_DOTS_INSTANCED_PROP(float4, _PlanarShadowColor)
    UNITY_DOTS_INSTANCED_PROP(float4, _LightDir)
    UNITY_DOTS_INSTANCED_PROP(float, _ShadowFalloff)
    UNITY_DOTS_INSTANCED_PROP(float, _UpwardShift)
    UNITY_DOTS_INSTANCED_PROP(float, _HorizontalPlane)
    UNITY_DOTS_INSTANCED_PROP(float4, _EmissionColor)
UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
            
#define _CurFramIndex UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float, _CurFramIndex)
#define _PreFramIndex UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float, _PreFramIndex)
#define _TransProgress UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float, _TransProgress)
#define _Dissolve UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float, _Dissolve)
#define _Edge UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float, _Edge)
#define _FlagColor UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _FlagColor)
#define _DissolveColor UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _DissolveColor)
#define _SkinningTexSize UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _SkinningTexSize)
#define _PlanarShadowColor UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _PlanarShadowColor)
#define _LightDir UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _LightDir)
#define _ShadowFalloff UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float, _ShadowFalloff)
#define _UpwardShift UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float, _UpwardShift)
#define _HorizontalPlane UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float, _HorizontalPlane)
#define _EmissionColor UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _EmissionColor)

#endif

uniform sampler2D _SkinningTex;
TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);
TEXTURE2D(_MaskTex);
SAMPLER(sampler_MaskTex);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);

#endif