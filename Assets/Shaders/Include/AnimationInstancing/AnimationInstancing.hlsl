#ifndef ANIMATION_INSTANCING_INCLUDED
#define ANIMATION_INSTANCING_INCLUDED

#if defined(CUSTOM_ANIMATION_INPUT)
    #include "Assets/Shaders/Include/Math/AnimationInput.hlsl"
#endif

#include "Assets/Shaders/Include/Math/AnimationDQ.hlsl"
#include "Assets/Shaders/Include/HSV.hlsl"

struct AnimationInput
{
    float4 vertex:POSITION;
    float4 normal:NORMAL;
    float2 uv:TEXCOORD0;
    float4 uv1:TEXCOORD3;
    float4 uv2:TEXCOORD4;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct AnimationOutPut
{
    float4 vertex:SV_POSITION;
    float3 normal:NORMAL;
    float2 uv:TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

AnimationOutPut AnimationVert(AnimationInput input)
{
    AnimationOutPut output = (AnimationOutPut)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    float4 vert = SkinDQ(input.uv1, input.uv2, input.vertex);
    float4 normal = SkinDQRotation(input.uv1, input.uv2, input.normal);

    output.vertex = TransformObjectToHClip(vert.xyz);
    output.normal = TransformObjectToWorldDir(normal.xyz);
    output.uv = input.uv;
    return output;
}

float4 AnimationFrag(AnimationOutPut input):COLOR
{
    UNITY_SETUP_INSTANCE_ID(input);
    float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
    float3 mask = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, input.uv).rgb;
    col.xyz = (_FlagColor.xyz*mask.r) * col.xyz + col.xyz * (1 - mask.r);
    
    float c1 = mask.b + _Dissolve;
    float c2 = c1 - (_Dissolve + _Edge);
    float3 color = lerp(0, _DissolveColor.xyz, max(0, c1 - (c2 - c1)));
    col.rgb += color * 10;

    // TODO： 时刻开启clip会严重影响效率。应该根据宏定义来控制是否开启clip
    if (c1 > 0.2)
    {
        discard;
    }

    float3 emmisive = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, input.uv).rgb * _EmissionColor.rgb;
    col.rgb += emmisive;
    
    return col;
}

#endif
