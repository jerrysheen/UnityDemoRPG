#ifndef UNIVERSAL_SDF_SHADOWMASK
#define UNIVERSAL_SDF_SHADOWMASK

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/lighting.hlsl"

half SampleSdfShadowMask(half2 uv, half maxdistance, half smooth)
{
	half4 maskvalue = SAMPLE_SHADOWMASK(luv);
	half sdf = smoothstep(maxdistance - smooth, maxdistance + smooth, maskvalue);
	return sdf;
}

#endif