//Stylized Water 2
//Staggart Creations (http://staggart.xyz)
//Copyright protected under Unity Asset Store EULA

//Prototyping!
//#define RECEIVE_PROJECTORS

#ifdef RECEIVE_PROJECTORS
TEXTURE2D(_WaterProjectorDiffuse);
SAMPLER(sampler_WaterProjectorDiffuse);
float4 _WaterProjectorUV;
#endif

TEXTURE2D(_FoamTex);
SAMPLER(sampler_FoamTex);

TEXTURE2D(_BumpMapLarge);
SAMPLER(sampler_BumpMapLarge);

TEXTURE2D(_SpecTex);
SAMPLER(sampler_SpecTex);


TEXTURE2D(_DepthControlTex);
SAMPLER(sampler_DepthControlTex);

float3 SampleNormals(float2 uv, float3 wPos, float2 time, float2 flowmap, float speed, float slope, int vFace) 
{
	float4 uvs = PackedUV(uv, time, flowmap, speed);
	float3 n1 = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uvs.xy));
	float3 n2 = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uvs.zw));

	float3 blendedNormals = BlendTangentNormals(n1, n2);
	
#if _DISTANCE_NORMALS
	float pixelDist = length(_WorldSpaceCameraPos.xyz - wPos.xyz);

	#if UNDERWATER_ENABLED
	//Use vertical distance only for backfaces (underwater). This ensures tiling is reduced when moving deeper into the water, vertically
	pixelDist = lerp(length(_WorldSpaceCameraPos.xz - wPos.xz), pixelDist, vFace);
	#endif
	
	float fadeFactor = saturate((_DistanceNormalParams.y - pixelDist) / (_DistanceNormalParams.y-_DistanceNormalParams.x));

	float3 largeBlendedNormals;
	
	uvs = PackedUV(uv * _DistanceNormalParams.z, time, flowmap, speed * 0.5);
	float3 n1b = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMapLarge, sampler_BumpMapLarge, uvs.xy));
	
	#if _ADVANCED_SHADING //Use 2nd texture sample
	float3 n2b = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMapLarge, sampler_BumpMapLarge, uvs.zw));
	largeBlendedNormals = BlendTangentNormals(n1b, n2b);
	#else
	largeBlendedNormals = n1b;
	#endif
	
	blendedNormals = lerp(largeBlendedNormals, blendedNormals, fadeFactor);
#endif
	
#if _RIVER
	uvs = PackedUV(uv, time, flowmap, speed * _SlopeParams.y);
	uvs.xy = uvs.xy * float2(1, 1-_SlopeParams.x);
	float3 n3 = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uvs.xy));

	blendedNormals = lerp(n3, blendedNormals, slope);
#endif

	#ifdef WAVE_SIMULATION
	BlendWaveSimulation(wPos, blendedNormals);
	#endif
	
	return blendedNormals;
}

float SampleIntersection(float2 uv, float gradient, float2 time)
{
	float inter = 0;
	float dist = 0;
	
#if _SHARP_INERSECTION
	float sine = sin(time.y * 10 - (gradient * _IntersectionRippleDist)) * _IntersectionRippleStrength;
	float2 nUV = float2(uv.x, uv.y) * _IntersectionTiling;
	float noise = SAMPLE_TEXTURE2D(_IntersectionNoise, sampler_IntersectionNoise, nUV + time.xy).r;

	dist = saturate(gradient / _IntersectionFalloff);
	noise = saturate((noise + sine) * dist + dist);
	inter = step(_IntersectionClipping, noise);
#endif

#if _SMOOTH_INTERSECTION
	float noise1 = SAMPLE_TEXTURE2D(_IntersectionNoise, sampler_IntersectionNoise, (float2(uv.x, uv.y) * _IntersectionTiling) + (time.xy )).r;
	float noise2 = SAMPLE_TEXTURE2D(_IntersectionNoise, sampler_IntersectionNoise, (float2(uv.x, uv.y) * (_IntersectionTiling * 1.5)) - (time.xy )).r;

	#if UNITY_COLORSPACE_GAMMA
	noise1 = SRGBToLinear(noise1);
	noise2 = SRGBToLinear(noise2);
	#endif
	
	dist = saturate(gradient / _IntersectionFalloff);
	inter = saturate(noise1 + noise2 + dist) * dist;
#endif

	return saturate(inter);
}

float SampleFoam(float2 uv, float2 time, float2 flowmap, float clipping, float mask, float slope)
{
#if _FOAM
	float4 uvs = PackedUV(uv, time, flowmap, _FoamSpeed);
	float f1 = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, uvs.xy).r;
	
	float f2 = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, uvs.zw).r;
	
	#if UNITY_COLORSPACE_GAMMA
	f1 = SRGBToLinear(f1);
	f2 = SRGBToLinear(f2);
	#endif

	float foam = saturate(f1 + f2) * mask;

#if _RIVER //Slopes
	uvs = PackedUV(uv, time, flowmap, _FoamSpeed * _SlopeParams.y);
	//Stretch UV vertically on slope
	uvs = uvs * float4(1.0, 1-_SlopeParams.x, 1.0, 1-_SlopeParams.x);

	//Cannot reuse the same UV, slope foam needs to be resampled and blended in
	//float f3 = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, uvs.xy).r;
	///float f4 = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, uvs.zw).r;
	float f3 = 0.0f;
	float f4 = 0.0f;
	
	#if UNITY_COLORSPACE_GAMMA
	f3 = SRGBToLinear(f3);
	f4 = SRGBToLinear(f4);
	#endif

	foam = saturate(lerp(f3 + f4, f1 + f2, slope)) * mask;
#endif
	
	foam = smoothstep(clipping, 1.0, foam);

	return foam;
#else
	return 0;
#endif
}

float SampleSpecTex(float2 uv, float2 time, float specNum)
{
	float3 specTex = SAMPLE_TEXTURE2D(_SpecTex, sampler_SpecTex, uv).xyz;
	float3 specTex2 = SAMPLE_TEXTURE2D(_SpecTex, sampler_SpecTex, uv + float2(.2,.5) + time.x * 0.01f).xyz;
	//float spec = smoothstep(0.0,0.01,dot(specTex, specTex2));
	float spec = smoothstep(0.0,specNum,dot(specTex, specTex2));
	return spec;
}

float4 SampleControlTex(float2 uv)
{
	float4 depthTex = SAMPLE_TEXTURE2D(_DepthControlTex, sampler_DepthControlTex, uv).xyzw;
	return depthTex;
}