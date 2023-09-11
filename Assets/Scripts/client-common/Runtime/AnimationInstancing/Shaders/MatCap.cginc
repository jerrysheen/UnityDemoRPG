#ifndef MatCap_CG
#define MatCap_CG

#include "UnityCG.cginc"
float3 MatCapUV(float3 normal)
{
 return normalize(mul(UNITY_MATRIX_IT_MV, normal)) * 0.5 + 0.5;
}


float3 SamplerMatCap(sampler2D map, float2 uv)
{
	return tex2D(map, uv);
}



#endif