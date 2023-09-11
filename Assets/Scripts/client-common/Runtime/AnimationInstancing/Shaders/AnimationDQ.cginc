#ifndef Animation_Insancing_DQ
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
#define Animation_Insancing_DQ

#include "SkinUtility.cginc"
#include "DualQuaternion.cginc"
uniform sampler2D _SkinningTex;
uniform float _SkinningTexW;
uniform float _SkinningTexH;


UNITY_INSTANCING_BUFFER_START(Props)
UNITY_DEFINE_INSTANCED_PROP(float, _CurFramIndex)
#define __CurFramIndex_arr Props
UNITY_DEFINE_INSTANCED_PROP(float, _PreFramIndex)
#define _PreFramIndex_arr Props
UNITY_DEFINE_INSTANCED_PROP(float, _TransProgress)
#define _TransProgress_arr Props
UNITY_INSTANCING_BUFFER_END(Props)

inline float4 getUV(float startIndex)
{
	float y = (int)(startIndex / _SkinningTexW);
	float u = (startIndex - y * _SkinningTexW) / _SkinningTexW;
	float v = y / _SkinningTexH;
	return float4(u, v, 0, 0);
}

inline DQ GetSkinDualQuat(float index)
{
	float4 r = tex2Dlod(_SkinningTex, getUV(index));
	float4 d = tex2Dlod(_SkinningTex, getUV(index + 1));
	DQ dq;
	dq.real = r;
	dq.dual = d;
	return dq;
}

float3 transformPositionDQ(float3 position, float4 realDQ, float4 dualDQ)
{
	return position +2 * cross(realDQ.xyz, cross(realDQ.xyz, position) + realDQ.w * position) +2 * (realDQ.w * dualDQ.xyz - dualDQ.w * realDQ.xyz +cross(realDQ.xyz, dualDQ.xyz));
}

inline float4 SkinDQ(float4 bone, float4 weight, float4 vn)
{
	float _curFramIndex = UNITY_ACCESS_INSTANCED_PROP(__CurFramIndex_arr, _CurFramIndex);
	//float _preFramIndex = UNITY_ACCESS_INSTANCED_PROP(_PreFramIndex_arr, _PreFramIndex);
	//float _progess = UNITY_ACCESS_INSTANCED_PROP(_TransProgress_arr, _TransProgress);
	DQ  curPoseDQ = GetSkinDualQuat(_curFramIndex+bone.x*2);
	float4x4 m = DQToMatrix(curPoseDQ);
	return mul(m,vn);
}
#endif