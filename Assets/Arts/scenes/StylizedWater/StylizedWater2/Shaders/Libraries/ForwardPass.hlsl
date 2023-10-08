//Stylized Water 2
//Staggart Creations (http://staggart.xyz)
//Copyright protected under Unity Asset Store EULA

//#define DEBUG_NORMALS
//#define RESAMPLE_REFRACTION_DEPTH

//Note: Throws an error about a BLENDWEIGHTS vertex attribute on GLES when VR is enabled (fixed in URP 10+)
//Possibly related to: https://issuetracker.unity3d.com/issues/oculus-a-non-system-generated-input-signature-parameter-blendindices-cannot-appear-after-a-system-generated-value
#if SHADER_API_GLES3 && SHADER_LIBRARY_VERSION_MAJOR < 10
#define FRONT_FACE_SEMANTIC_REAL VFACE
#else
#define FRONT_FACE_SEMANTIC_REAL FRONT_FACE_SEMANTIC
#endif

#if UNDERWATER_ENABLED
half4 ForwardPassFragment(Varyings input, FRONT_FACE_TYPE vertexFace : FRONT_FACE_SEMANTIC_REAL) : SV_Target
#else
half4 ForwardPassFragment(Varyings input) : SV_Target
#endif
{
	UNITY_SETUP_INSTANCE_ID(input);
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
	
	float3 albedo = 0;
	float alpha = 1;

	float vFace = 1.0;
	//0 = back face
	#if UNDERWATER_ENABLED
	vFace = IS_FRONT_VFACE(vertexFace, true, false);
	//albedo = lerp(float3(1,0,0), float3(0,1,0), IS_FRONT_VFACE(vFace, true, false));
	//return float4(albedo.rgb, 1);
	#endif
	
	float4 vertexColor = input.color; //Mask already applied in vertex shader
	//return float4(vertexColor.aaa, 1);

	//Vertex normal in world-space
	float3 normalWS = normalize(input.normalWS.xyz);
#if _NORMALMAP
	float3 WorldTangent = input.tangent.xyz;
	float3 WorldBiTangent = input.bitangent.xyz;
	float3 wPos = float3(input.normalWS.w, input.tangent.w, input.bitangent.w);
#else
	float3 wPos = input.wPos;
#endif
	//Not normalized for depth-pos reconstruction. Normalization required for lighting (otherwise breaks on mobile)
	float3 viewDir = (_WorldSpaceCameraPos - wPos);
	float3 viewDirNorm = SafeNormalize(viewDir);
	//return float4(viewDir, 1);
	
	half VdotN = 1.0 - saturate(dot(viewDirNorm, normalWS));
	
	#if _FLAT_SHADING
	float3 dpdx = ddx(wPos.xyz);
	float3 dpdy = ddy(wPos.xyz);
	normalWS = normalize(cross(dpdy, dpdx));
	#endif

	//Returns mesh or world-space UV
	float2 uv = GetSourceUV(input.uv.xy, wPos.xz, _WorldSpaceUV);
	float2 flowMap = float2(1, 1);

	half slope = 0;
	#if _RIVER
	slope = GetSlopeInverse(normalWS);
	//return float4(slope, slope, slope, 1);
	#endif

	// Waves
	float height = 0;

	float3 waveNormal = normalWS;
#if _WAVES
	WaveInfo waves = GetWaveInfo(uv, TIME * _WaveSpeed, _WaveFadeDistance.x, _WaveFadeDistance.y);
	#if !_FLAT_SHADING
		//Flatten by blue vertex color weight
		waves.normal = lerp(waves.normal, normalWS, lerp(0, 1, vertexColor.b));
		//Blend wave/vertex normals in world-space
		waveNormal = BlendNormalWorldspaceRNM(waves.normal, normalWS, UP_VECTOR);
	#endif
	//return float4(waveNormal.xyz, 1);
	height = waves.position.y * 0.5 + 0.5;
	height *= lerp(1, 0, vertexColor.b);
	//return float4(height, height, height, 1);

	//vertices are already displaced on XZ, in this case the world-space UV needs the same treatment
	if(_WorldSpaceUV == 1) uv.xy -= waves.position.xz * HORIZONTAL_DISPLACEMENT_SCALAR * _WaveHeight;
	//return float4(frac(uv.xy), 0, 1);
#endif

	float4 shadowCoords = float4(0, 0, 0, 0);
	#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && !defined(UNLIT)
	shadowCoords = input.shadowCoord;
	#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS) && !defined(UNLIT)
	shadowCoords = TransformWorldToShadowCoord(wPos);
	#endif

	#if VERSION_GREATER_EQUAL(10,0)
	Light mainLight = GetMainLight(shadowCoords, wPos, 1.0);
	#else
	Light mainLight = GetMainLight(shadowCoords);
	#endif

	half shadowMask = mainLight.shadowAttenuation;
	//return float4(shadowMask,shadowMask,shadowMask,1);
	half backfaceShadows = 1;
	
	#if UNDERWATER_ENABLED
	//Separate so shadows applied by Unity's lighting do not appear on backfaces
	backfaceShadows = shadowMask;
	shadowMask = lerp(1.0, shadowMask, vFace);
	#endif

	//Normals
	float3 NormalsCombined = float3(0.5, 0.5, 1);
	float3 worldTangentNormal = waveNormal;
	
#if _NORMALMAP
	NormalsCombined = SampleNormals(uv * _NormalTiling, wPos, TIME, flowMap, _NormalSpeed, slope, vFace);
	//return float4((NormalsCombined.x * 0.5 + 0.5), (NormalsCombined.y * 0.5 + 0.5), 1, 1);

	worldTangentNormal = normalize(TransformTangentToWorld(NormalsCombined, half3x3(WorldTangent, WorldBiTangent, waveNormal)));

	#ifdef DEBUG_NORMALS
	return float4(SRGBToLinear(float3(NormalsCombined.x * 0.5 + 0.5, NormalsCombined.y * 0.5 + 0.5, 1)), 1.0);
	#endif
#endif

#ifdef SCREEN_POS
	float4 ScreenPos = input.screenPos;
#else
	float4 ScreenPos = 0;
#endif

	#if UNDERWATER_ENABLED
	ClipSurface(ScreenPos.xyzw, wPos, input.positionCS.xyz, vFace);
	#endif

	#if _REFRACTION || UNDERWATER_ENABLED
	float4 refractedScreenPos = ScreenPos.xyzw + (float4(worldTangentNormal.xz, 0, 0) * (_RefractionStrength * lerp(0.1, 0.01,  unity_OrthoParams.w)));
	#endif

	float3 opaqueWorldPos = wPos;
	float opaqueDist = 1;
	float surfaceDepth = opaqueDist;
	
#if !_DISABLE_DEPTH_TEX
	SceneDepth depth = SampleDepth(ScreenPos);
	opaqueWorldPos = ReconstructViewPos(ScreenPos, viewDir, depth);
	//return float4(frac(opaqueWorldPos.xyz), 1);

	//Invert normal when viewing backfaces
	float normalSign = ceil(dot(viewDirNorm, normalWS));
	normalSign = normalSign == 0 ? -1 : 1;
	
	opaqueDist = DepthDistance(wPos, opaqueWorldPos, normalWS * normalSign);
	//return float4(opaqueDist.xxx,1);
	
#if _ADVANCED_SHADING && _REFRACTION
	SceneDepth depthRefracted = SampleDepth(refractedScreenPos);
	float3 opaqueWorldPosRefracted = ReconstructViewPos(refractedScreenPos, viewDir, depthRefracted);

	//Reject any offset pixels in front of the water surface
	float refractionMask = saturate((wPos.y - opaqueWorldPosRefracted.y));

	#if UNDERWATER_ENABLED
	refractionMask = lerp(saturate((opaqueWorldPosRefracted.y - wPos.y)), refractionMask, vFace);
	#endif
	
	//return float4(refractionMask.xxx, 1.0);
	refractedScreenPos = lerp(ScreenPos, refractedScreenPos, refractionMask);
	
	//Double sample depth to avoid depth discrepancies (though this doesn't always offer the best result)
	#ifdef RESAMPLE_REFRACTION_DEPTH
	surfaceDepth = SurfaceDepth(depthRefracted, input.positionCS);
	#else
	//surfaceDepth = depth.eye - LinearEyeDepth(input.positionCS.z, _ZBufferParams);
	surfaceDepth = SurfaceDepth(depth, input.positionCS);
	#endif
	
#else
	surfaceDepth = SurfaceDepth(depth, input.positionCS);
#endif

	#if !_RIVER
	float grazingTerm = saturate(pow(VdotN, 64));
	//Resort to z-depth at surface edges. Otherwise makes intersection/edge fade visible through the water surface
	opaqueDist = lerp(opaqueDist, surfaceDepth, grazingTerm);
	#endif
#endif

	float waterDensity = 1;
#if !_DISABLE_DEPTH_TEX

	float distanceAttenuation = 1.0 - exp(-surfaceDepth * _DepthVertical * lerp(0.1, 0.01, unity_OrthoParams.w));
	float heightAttenuation = saturate(lerp(opaqueDist * _DepthHorizontal, 1.0 - exp(-opaqueDist * _DepthHorizontal), _DepthExp));
	
	waterDensity = max(distanceAttenuation, heightAttenuation);
	
	//return float4(waterDensity.xxx, 1.0);
#endif

	#if !_RIVER
	waterDensity = waterDensity * saturate(waterDensity - vertexColor.g);
	#endif

	float intersection = 0;
#if _SHARP_INERSECTION || _SMOOTH_INTERSECTION

	float interSecGradient = 0;
	
	#if !_DISABLE_DEPTH_TEX
	interSecGradient = 1-saturate(exp(opaqueDist) / _IntersectionLength);	
	#endif
	
	if (_IntersectionSource == 1) interSecGradient = vertexColor.r;
	if (_IntersectionSource == 2) interSecGradient = saturate(interSecGradient + vertexColor.r);

	intersection = SampleIntersection(uv.xy, interSecGradient, TIME * _IntersectionSpeed);
	intersection *= _IntersectionColor.a;

	#if UNDERWATER_ENABLED
	intersection *= vFace;
	#endif

	#if _WAVES
	//Prevent from peering through waves when camera is at the water level
	if(wPos.y < opaqueWorldPos.y) intersection = 0;
	#endif
	
	//Flatten normals on intersection foam
	waveNormal = lerp(waveNormal, normalWS, intersection);
#endif
	//return float4(intersection,intersection,intersection,1);

	//FOAM
	float foam = 0;
	#if _FOAM

	#if !_RIVER
	float foamMask = lerp(1, saturate(height), _FoamWaveMask);
	foamMask = pow(abs(foamMask), _FoamWaveMaskExp);
	#else
	float foamMask = 1;
	#endif

	foam = SampleFoam(uv * _FoamTiling, TIME, flowMap, _FoamSize, foamMask, slope);

	#if _RIVER
	foam *= saturate(_FoamColor.a + 1-slope + vertexColor.a);
	#else
	foam *= saturate(_FoamColor.a + vertexColor.a);
	#endif
	
	//return float4(foam, foam, foam, 1);
	#endif

	#if WAVE_SIMULATION
	SampleWaveSimulationFoam(wPos, foam);
	#endif

	//Albedo
	float4 baseColor = lerp(_ShallowColor, _BaseColor, waterDensity);
	baseColor.rgb += _WaveTint * height;
	
	albedo.rgb = baseColor.rgb;
	alpha = baseColor.a;

	float3 sparkles = 0;
#if _NORMALMAP
	float NdotL = saturate(dot(UP_VECTOR, worldTangentNormal));
	half sunAngle = saturate(dot(UP_VECTOR, mainLight.direction));
	half angleMask = saturate(sunAngle * 10); /* 1.0/0.10 = 10 */
	sparkles = saturate(step(_SparkleSize, (saturate(NormalsCombined.y) * NdotL))) * _SparkleIntensity * mainLight.color * angleMask;
	
	albedo.rgb += sparkles.rgb;
#endif
	//return float4(baseColor.rgb, alpha);

	half3 sunSpec = 0;
#ifndef _SPECULARHIGHLIGHTS_OFF
	float3 sunReflectionNormals = worldTangentNormal;

	#if _FLAT_SHADING //Use face normals
	sunReflectionNormals = waveNormal;
	#endif
	
	sunSpec = SpecularReflection(mainLight, viewDirNorm, sunReflectionNormals, _SunReflectionDistortion, _SunReflectionSize, _SunReflectionStrength);
	sunSpec.rgb *= saturate((1-foam) * (1-intersection) * shadowMask); //Hide
#endif

	//Reflection probe/planar
	float3 reflections = 0;
#ifndef _ENVIRONMENTREFLECTIONS_OFF
	float3 refWorldTangentNormal = lerp(waveNormal, normalize(waveNormal + worldTangentNormal), _ReflectionDistortion);

	#if _FLAT_SHADING //Skip, not a good fit
	refWorldTangentNormal = waveNormal;
	#endif
	
	float3 reflectionVector = reflect(-viewDirNorm , refWorldTangentNormal);
	float2 reflectionPerturbation = lerp(waveNormal.xz * 0.5, worldTangentNormal.xy, _ReflectionDistortion).xy;
	reflections = SampleReflections(reflectionVector, _ReflectionBlur, _PlanarReflectionsEnabled, ScreenPos.xyzw, wPos, refWorldTangentNormal, viewDirNorm, reflectionPerturbation);
	
	half reflectionFresnel = ReflectionFresnel(refWorldTangentNormal, viewDirNorm, _ReflectionFresnel);
	half reflectionMask = _ReflectionStrength * reflectionFresnel * vFace;
	reflectionMask = saturate(reflectionMask - foam - intersection);
	//return float4(reflectionFresnel.xxx, 1);

	//Blend reflection with albedo. Diffuse lighting will affect it
	albedo.rgb = lerp(albedo, lerp(albedo.rgb, reflections, reflectionMask), _ReflectionLighting);
	//return float4(albedo.rgb, 1);
	
	//Will be added to emission in lighting function
	reflections *= reflectionMask * (1-_ReflectionLighting);
	//return float4(reflections.rgb, 1);
#endif

	float3 caustics = 0;
#if _CAUSTICS
	caustics = SampleCaustics(opaqueWorldPos.xz + lerp(waveNormal.xz, NormalsCombined.xz, _CausticsDistortion), TIME * _CausticsSpeed, _CausticsTiling) * _CausticsBrightness;

	float causticsMask = saturate((1-waterDensity) - intersection - foam) * vFace;

	#if _RIVER
	//Reduce caustics visibility by supposed water turbulence
	causticsMask *= lerp(1, causticsMask, slope);
	#endif
	
	//Note: not masked by shadows, this occurs in the lighting function
	caustics = caustics * causticsMask;
	//return float4(caustics.rgb, 1);
#endif

	// Translucency
	TranslucencyData translucencyData = (TranslucencyData)0;
#if _TRANSLUCENCY
	
	//Note: value is subtracted
	float thickness = saturate(intersection + (foam * 0.25) + (1-shadowMask)); //Foam isn't 100% opaque; 
	//return float4(thickness, thickness, thickness, 1);

	translucencyData = PopulateTranslucencyData(_ShallowColor.rgb,mainLight.direction, mainLight.color, viewDirNorm, lerp(UP_VECTOR, waveNormal, vFace),worldTangentNormal, thickness, _TranslucencyParams);
	#if UNDERWATER_ENABLED
	//Override the strength of the effect for the backfaces, to match the underwater shading post effect
	translucencyData.strength *= lerp(_UnderwaterFogBrightness * _UnderwaterSubsurfaceStrength, 1, vFace);
	#endif
#endif

	//Foam application on top of everything up to this point
	#if _FOAM
	albedo.rgb = lerp(albedo.rgb, _FoamColor.rgb, foam);
	#endif

	#if _SHARP_INERSECTION || _SMOOTH_INTERSECTION
	//Layer intersection on top of everything
	albedo.rgb = lerp(albedo.rgb, _IntersectionColor.rgb, intersection);
	#endif

	//Sum values to compose alpha
	alpha = saturate(alpha + intersection + foam);

	#if _FLAT_SHADING
	//Moving forward, consider the tangent normal the same as the flat-shaded normals
	worldTangentNormal = waveNormal;
	#endif
	
	//Horizon color (note: not using normals, since they are perturbed by waves)
	float fresnel = saturate(pow(VdotN, _HorizonDistance));
	#if UNDERWATER_ENABLED
	fresnel *= vFace;
	#endif
	albedo.rgb = lerp(albedo.rgb, _HorizonColor.rgb, fresnel * _HorizonColor.a);

	#if UNITY_COLORSPACE_GAMMA
	//Gamma-space is likely a choice, enabling this will have the water stand out from non gamma-corrected shaders
	//albedo.rgb = LinearToSRGB(albedo.rgb);
	#endif
	
	//Final alpha
	float edgeFade = saturate(opaqueDist / (_EdgeFade * 0.01));

	#if UNDERWATER_ENABLED
	edgeFade = lerp(1.0, edgeFade, vFace);
	#endif

	alpha *= edgeFade;

	SurfaceData surfaceData = (SurfaceData)0;

	surfaceData.albedo = albedo.rgb;
	surfaceData.specular = sunSpec.rgb;
	//surfaceData.metallic = lerp(0.0, _Metallic, 1-(intersection+foam));
	surfaceData.metallic = 0;
	//surfaceData.smoothness = _Smoothness;
	surfaceData.smoothness = 0;
	surfaceData.normalTS = NormalsCombined;
	surfaceData.emission = 0; //To be populated with translucency
	surfaceData.occlusion = 1.0;
	surfaceData.alpha = alpha;

	SurfaceNormalData normalData;
	normalData.geometryNormalWS = waveNormal;
	normalData.pixelNormalWS = worldTangentNormal;
	normalData.lightingStrength = _NormalStrength;
	normalData.mask = saturate(intersection + foam);

	//https://github.com/Unity-Technologies/Graphics/blob/31106afc882d7d1d7e3c0a51835df39c6f5e3073/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl#L34
	InputData inputData = (InputData)0;
	inputData.positionWS = wPos;
	inputData.viewDirectionWS = viewDirNorm;
	inputData.shadowCoord = shadowCoords;
	#if UNDERWATER_ENABLED
	//Flatten normals for underwater lighting (distracting, peers through the fog)
	inputData.normalWS = lerp(waveNormal, worldTangentNormal, vFace);
	#else
	inputData.normalWS = worldTangentNormal;
	#endif
	inputData.fogCoord = input.fogFactorAndVertexLight.x;
	inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;

	inputData.bakedGI = 0;
	#if defined(DYNAMICLIGHTMAP_ON) && VERSION_GREATER_EQUAL(12,0)
    inputData.bakedGI = SAMPLE_GI(input.bakedLightmapUV, input.dynamicLightmapUV, input.vertexSH, inputData.normalWS);
    #else
    inputData.bakedGI = SAMPLE_GI(input.bakedLightmapUV, input.vertexSH, inputData.normalWS);
    #endif

	float4 finalColor = float4(ApplyLighting(surfaceData, inputData, translucencyData, normalData, caustics, reflections, _ShadowStrength, vFace), alpha);

	#if VERSION_GREATER_EQUAL(12,0) && defined(DEBUG_DISPLAY)
	inputData.positionCS = input.positionCS;
	#if _NORMALMAP
	inputData.tangentToWorld = half3x3(WorldTangent, WorldBiTangent, inputData.normalWS);
	#else
	inputData.tangentToWorld = 0;
	#endif
	inputData.normalizedScreenSpaceUV = ScreenPos.xy / ScreenPos.w;
	inputData.shadowMask = shadowCoords;
	#if defined(DYNAMICLIGHTMAP_ON)
	inputData.dynamicLightmapUV = input.dynamicLightmapUV;
	#endif
	#if defined(LIGHTMAP_ON)
	inputData.staticLightmapUV = input.bakedLightmapUV;
	#else
	inputData.vertexSH = input.vertexSH;
	#endif

	inputData.brdfDiffuse = surfaceData.albedo;
	inputData.brdfSpecular = surfaceData.specular;
	inputData.uv = uv;
	inputData.mipCount = 0;
	inputData.texelSize = float4(1/uv.x, 1/uv.y, uv.x, uv.y);
	inputData.mipInfo = 0;
	half4 debugColor;

	if (CanDebugOverrideOutputColor(inputData, surfaceData, debugColor))
	{
		return debugColor;
	}
	#endif

	float3 sceneColor = 0;
	#if _REFRACTION || UNDERWATER_ENABLED
	sceneColor = SampleOpaqueTexture(refractedScreenPos, vFace);
	#endif
	
	#if _REFRACTION
	finalColor.rgb = lerp(sceneColor, finalColor.rgb, alpha);
	alpha = lerp(1.0, edgeFade, vFace);
	#endif

	ApplyFog(finalColor.rgb, input.fogFactorAndVertexLight.x, ScreenPos, wPos, vFace);

	#if UNDERWATER_ENABLED
		float skyMask = 0;
		
		#if !_DISABLE_DEPTH_TEX
		#if _ADVANCED_SHADING && _REFRACTION
		//Use depth resampled with refracted screen UV
		depth.raw = depthRefracted.raw;
		#endif
			
		skyMask = (Linear01Depth(depth.raw, _ZBufferParams) > 0.99 ? 1 : 0);
		//return float4(skyMask.xxx, 1.0);
		#endif
	
	float3 underwaterColor = ShadeUnderwaterSurface(albedo.rgb, surfaceData.emission.rgb, surfaceData.specular.rgb, sceneColor, skyMask, backfaceShadows, inputData.positionWS, inputData.normalWS, worldTangentNormal, viewDirNorm,  _ShallowColor.rgb, _BaseColor.rgb, vFace);
	finalColor.rgb = lerp(underwaterColor, finalColor.rgb, vFace);
	alpha = lerp(1.0, alpha, vFace);
	#endif

	#if _RIVER
	finalColor.a = alpha * saturate(alpha - vertexColor.g);
	#endif

	return finalColor;
}