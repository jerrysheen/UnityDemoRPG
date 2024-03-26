#ifndef ANIMATION_DQ_HLSL_INCLUDED
#define ANIMATION_DQ_HLSL_INCLUDED

#if defined(CUSTOM_ANIMATION_INPUT)
	#include "Assets/Shaders/Include/Math/AnimationInput.hlsl"
#endif

	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "DualQuaternion.hlsl"

	inline float4 getUV(float startIndex)
	{
		const float4 skinTexSize = _SkinningTexSize;
		float y = (int)(startIndex / skinTexSize.x);
		float u = (startIndex - y * skinTexSize.x) / skinTexSize.x;
		float v = y / skinTexSize.y;
		return float4(u, v, 0, 0);
	}

	inline DQ GetSkinDualQuat(float index)
	{
		float4 r = tex2Dlod(_SkinningTex, getUV(index));
		float4 d = tex2Dlod(_SkinningTex, getUV(index + 1));
		DQ dq;
		dq.realy = r;
		dq.dual = d;
		return dq;
	}

	DQ DualQuaternionShortestPath(DQ dq1, DQ dq2)
	{
		bool BadPath = dot(dq1.realy, dq2.realy) < 0;
		dq1.realy= BadPath ? -dq1.realy	: dq1.realy;
		dq1.dual= BadPath ? -dq1.dual: dq1.dual;
		return dq1;
	}
	inline DQ BlendWeight4(float4 bone,float4 weight)
	{
		DQ  dq0 = GetSkinDualQuat(_CurFramIndex+bone.x*2);
		DQ  dq1 = GetSkinDualQuat(_CurFramIndex+bone.y*2);
		DQ  dq2 = GetSkinDualQuat(_CurFramIndex+bone.z*2);
		DQ  dq3 = GetSkinDualQuat(_CurFramIndex+bone.w*2);

		dq1 = DualQuaternionShortestPath(dq1, dq0);
		dq2 = DualQuaternionShortestPath(dq2, dq0);
		dq3 = DualQuaternionShortestPath(dq3, dq0);
	
		DQ skind;
		skind.realy=dq0.realy*weight.x;
		skind.realy+=dq1.realy*weight.y;
		skind.realy+=dq2.realy*weight.z;
		skind.realy+=dq3.realy*weight.w;

		skind.dual=dq0.dual*weight.x;
		skind.dual+=dq1.dual*weight.y;
		skind.dual+=dq2.dual*weight.z;
		skind.realy+=dq3.dual*weight.w;



		float mag = length(skind.realy);
		skind.realy/=mag;
		skind.dual/=mag;
		return skind;
	}

	inline float4 SkinDQ(float4 bone, float4 weight, float4 vn)
	{
		// float _curFramIndex = UNITY_ACCESS_INSTANCED_PROP(__CurFramIndex_arr, _CurFramIndex);
		// float _preFramIndex = UNITY_ACCESS_INSTANCED_PROP(_PreFramIndex_arr, _PreFramIndex);
		// float _progess = UNITY_ACCESS_INSTANCED_PROP(_TransProgress_arr, _TransProgress);
		DQ	curPoseDQ;
		//#ifdef ANIMTION_SKIN_WEIGHT_4
				curPoseDQ=BlendWeight4(bone,weight);
		// #else
		// 		curPoseDQ=GetSkinDualQuat(_CurFramIndex+bone.x*2);
		// #endif
		vn.xyz=curPoseDQ.transformPositionDQ(vn.xyz);
		return  vn;
	}
	
	inline float4 SkinDQRotation(float4 bone, float4 weight, float4 dir)
	{
		DQ	curPoseDQ=BlendWeight4(bone,weight);
		dir.xyz=curPoseDQ.transformRotationByDQ(dir).xyz;
		return  dir;
	}
#endif