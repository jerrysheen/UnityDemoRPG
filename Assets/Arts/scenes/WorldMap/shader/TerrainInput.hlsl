#ifndef UNIVERSAL_TERRAIN_INPUT_INCLUDED
#define UNIVERSAL_TERRAIN_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"

#if defined(_DETAIL_MULX2) || defined(_DETAIL_SCALED)
#define _DETAIL
#endif

// NOTE: Do not ifdef the properties here as SRP batcher can not handle different layouts.
CBUFFER_START(UnityPerMaterial)
half _Glossiness;
half _Metallic;
half _VariationStrength;
half _AlbedoPow;
half _BlendDistanceFactor;
half _BiasedUVFactor;
half _SphereRadius;
half _MipMapFactor;
half3 _SphereCenter;
half3 _VariationUVScale;
float4x4 _PrevViewProj;
uint _FrameNum;
float4 _NormalChoiceGroup0;
float4 _NormalChoiceGroup1;
float4 _NormalChoiceGroup2;
float4 _NormalChoiceGroup3;
float4 _Rect;
float4 _DiffuseArr_ST;
float4 _IDMapTex_ST;
float4 _IDMapTex_TexelSize;
float4 _NoiseScale;
float4 _NoiseClampValue;
CBUFFER_END

TEXTURE2D(_IDMapTex);               SAMPLER(sampler_IDMapTex);
TEXTURE2D(_NoiseTex);               SAMPLER(sampler_NoiseTex);
TEXTURE2D(_GlobalNormal);           SAMPLER(sampler_GlobalNormal);
TEXTURE2D(_Normal0);                SAMPLER(sampler_Normal0);
TEXTURE2D(_Normal1);                SAMPLER(sampler_Normal1);
TEXTURE2D(_PrevFrame);             SAMPLER(sampler_PrevFrame);
TEXTURE2D(_CornerAtlas);             SAMPLER(sampler_CornerAtlas);

TEXTURE2D_ARRAY(_DiffuseArr);       SAMPLER(sampler_DiffuseArr);

static float4 _NormalChoiceArray[4] = {_NormalChoiceGroup0, _NormalChoiceGroup1, _NormalChoiceGroup2, _NormalChoiceGroup3};
            
float4 hash4( float2 p ) { return frac(sin(float4( 1.0+dot(p,float2(37.0,17.0)),
                                                   2.0+dot(p,float2(11.0,47.0)),
                                                   3.0+dot(p,float2(41.0,29.0)),
                                                   4.0+dot(p,float2(23.0,31.0))))*103.0); }


#endif // UNIVERSAL_TERRAIN_INPUT_INCLUDED
