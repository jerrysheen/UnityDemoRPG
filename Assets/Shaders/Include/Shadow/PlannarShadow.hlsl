#include <UnityInstancing.cginc>
#ifndef PlannarShadow
#define PlannarShadow


#include "Assets/Shaders/Include/Math/AnimationDQ.hlsl"

struct VertexInput
{
    float4 vertex:POSITION;
    float4 normal:NORMAL;
    float2 uv:TEXCOORD0;
    float4 uv1:TEXCOORD3;
    float4 uv2:TEXCOORD4;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutput
{
    float4 vertex:SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};


float3 ShadowProjectPos(float4 vertPos,float4 LightDir,float UpwardShift)
{
    float3 shadowPos;
    float3 worldPos= TransformObjectToWorld(vertPos.xyz);
    shadowPos.y = min(worldPos.y, _HorizontalPlane)+_UpwardShift;
    shadowPos.xz = worldPos.xz - LightDir.xz * max(0, worldPos.y - _HorizontalPlane) / LightDir.y;
    return shadowPos;
}

VertexOutput DefaultPlannarVert(VertexInput input)
{
    VertexOutput output = (VertexOutput)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    float _upwardShift=_UpwardShift;
    float4 _lightDir=float4(_MainLightPosition.xyz,1);
    float4 vert = SkinDQ(input.uv1, input.uv2, input.vertex);
    float3 shadowPos = ShadowProjectPos(vert,_lightDir,_upwardShift);
    output.vertex = TransformWorldToHClip(shadowPos);
    return output;
}

VertexOutput AnimationPlannarVert(VertexInput input)
{
    VertexOutput output = (VertexOutput)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
    
    float _upwardShift=_UpwardShift;
    float4 _lightDir=float4(_MainLightPosition.xyz,1);

    
    float4 vert = SkinDQ(input.uv1, input.uv2, input.vertex);
    float3 shadowPos = ShadowProjectPos(vert,_lightDir,_upwardShift);
    output.vertex = TransformWorldToHClip(shadowPos);
    return output;
}

float4 PlannarShadowFrag(VertexOutput i) :COLOR
{
    UNITY_SETUP_INSTANCE_ID(i);
    float4 _shadowColor=_PlanarShadowColor;
    return _shadowColor;
}


#endif
