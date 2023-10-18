//Stylized Water 2
//Staggart Creations (http://staggart.xyz)
//Copyright protected under Unity Asset Store EULA

// 岸边接触部分泡沫
// 岸边采样修改后减少为两次。
Shader "Universal Render Pipeline/FX/Stylized Water_clean"
{
	Properties
	{
		//[Header(Rendering)]
		[MaterialEnum(Off,0,On,1)]_ZWrite("Depth writing", Float) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _Cull("Render faces", Float) = 2
		[MaterialEnum(Simple,0,Advanced,1)] _ShadingMode("Shading mode", Float) = 1

		//[Header(Feature switches)]
		_DisableDepthTexture("Disable depth texture", Float) = 0
		_AnimationParams("XY=Direction, Z=Speed", Vector) = (1,1,1,0)
		_SlopeParams("Slope (X=Stretch) (Y=Speed)", Vector) = (0.5, 4, 0, 0)
		[MaterialEnum(Mesh UV,0,World XZ projected ,1)]_WorldSpaceUV("UV Source", Float) = 1

		//[Header(Color)]
		[HDR]_BaseColor("Deep", Color) = (0, 0.44, 0.62, 1)
		[HDR]_DeepColor1("Deep1", Color) = (0, 0.44, 0.62, 1)
		[HDR]_ShallowColor("Shallow", Color) = (0.1, 0.9, 0.89, 0.02)
		[HDR]_HorizonColor("Horizon", Color) = (0.84, 1, 1, 0.15)

		//TODO: Split up component into separate properties. This way multi-material selection works
		_VertexColorMask ("Vertex color mask", vector) = (0,0,0,0)
		
		//_Smoothness("Smoothness", Range(0.0, 1.0)) = 0.9
		//_Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		
		_HorizonDistance("Horizon Distance", Range(0.01 , 32)) = 8
		_DepthVertical("Vertical Depth", Range(0.01 , 8)) = 4
		_DepthHorizontal("Horizontal Depth", Range(0.01 , 8)) = 1
		_DepthExp("Exponential Blend", Range(0 , 1)) = 1
		_WaveTint("Wave tint", Range( -0.1 , 0.1)) = 0
		_TranslucencyParams("Translucency", Vector) = (1,8,1,0)
		//X: Strength
		//Y: Exponent
		//Z: Curvature mask
		_EdgeFade("Edge Fade", Float) = 0.1
		_ShadowStrength("Shadow Strength", Range(0 , 1)) = 1

		//[Header(Underwater)]
		[Toggle(_CAUSTICS)] _CausticsOn("Caustics ON", Float) = 1
		_CausticsBrightness("Brightness", Float) = 2
		_CausticsTiling("Tiling", Float) = 0.5
		_CausticsSpeed("Speed multiplier", Float) = 0.1
		_CausticsDistortion("Distortion", Range(0, 1)) = 0.15
		[NoScaleOffset][SingleLineTexture]_CausticsTex("Caustics Mask", 2D) = "black" {}
		
		_UnderwaterSurfaceSmoothness("Underwater Surface Smoothness", Range(0, 1)) = 0.8
		_UnderwaterRefractionOffset("Underwater Refraction Offset", Range(0, 1)) = 0.2
		
		[Toggle(_REFRACTION)] _RefractionOn("_REFRACTION", Float) = 1
		_RefractionStrength("_RefractionStrength", Range(0 , 3)) = 0.1

		//[Header(Intersection)]
		[MaterialEnum(Camera Depth,0,Vertex Color (R),1,Both combined,2)] _IntersectionSource("Intersection source", Float) = 0
		[MaterialEnum(None,0,Sharp,1,Smooth,2)] _IntersectionStyle("Intersection style", Float) = 1

		[NoScaleOffset][SingleLineTexture]_IntersectionNoise("Intersection noise", 2D) = "white" {}
		_IntersectionColor("Color", Color) = (1,1,1,1)
		_IntersectionLength("Distance", Range(0.01 , 5)) = 2
		_IntersectionClipping("Cutoff", Range(0.01, 1)) = 0.5
		_IntersectionFalloff("Falloff", Range(0.01 , 1)) = 0.5
		_IntersectionTiling("Noise Tiling", float) = 0.2
		_IntersectionSpeed("Speed multiplier", float) = 0.1
		_IntersectionRippleDist("Ripple distance", float) = 32
		_IntersectionRippleStrength("Ripple Strength", Range(0 , 1)) = 0.5

		//[Header(Foam)]
		[NoScaleOffset][SingleLineTexture]_FoamTex("Foam Mask", 2D) = "black" {}
		_FoamColor("Color", Color) = (1,1,1,1)
		_FoamSize("Cutoff", Range(0.01 , 0.999)) = 0.01
		_FoamSpeed("Speed multiplier", float) = 0.1
		_FoamWaveMask("Wave mask", Range(0 , 1)) = 0
		_FoamWaveMaskExp("Wave mask exponent", Range(1 , 8)) = 1
		_FoamTiling("Tiling", float) = 0.1

		//[Header(Normals)]
		[Toggle(_NORMALMAP)] _NormalMapOn("_NORMALMAP", Float) = 1
		[NoScaleOffset][Normal][SingleLineTexture]_BumpMap("Normals", 2D) = "bump" {}
		_NormalTiling("Tiling", Float) = 1
		_NormalStrength("Strength", Range(0 , 1)) = 0.5
		_NormalSpeed("Speed multiplier", Float) = 0.2
		//X: Start
		//Y: End
		//Z: Tiling multiplier
		_DistanceNormalParams("Distance normals", vector) = (100, 300, 0.25, 0)
		[NoScaleOffset][Normal][SingleLineTexture]_BumpMapLarge("Normals (Distance)", 2D) = "bump" {}

		_SparkleIntensity("Sparkle Intensity", Range(0 , 10)) = 00
		_SparkleSize("Sparkle Size", Range( 0 , 1)) = 0.280

		//[Header(Sun Reflection)]
		_SunReflectionSize("Sun Size", Range(0 , 1)) = 0.5
		_SunReflectionStrength("Sun Strength", Float) = 10
		_SunReflectionDistortion("Sun Distortion", Range( 0 , 1)) = 0.49
		_PointSpotLightReflectionExp("Point/spot light exponent", Range(0.01 , 128)) = 64

		//[Header(World Reflection)]
		[NoScaleOffset][SingleLineTexture]_SpecTex("_SpecTex", 2D) = "black" {}
		_SpecLightDir("Specular Dir", vector) = (9.97, 1.29, 12.44, 0.1)
		_SpecTexTilling("_SpecTexTilling", Range(0.001, 1)) = 0.05
		_SpecStrength("_SpecStrength", Range(1, 50)) = 10
		_SpecNum("_SpecNum", Range(0.0, 0.03)) = 0.01
		_ReflectionStrength("Strength", Range( 0 , 1)) = 0
		_ReflectionDistortion("Distortion", Range( 0 , 1)) = 0.05
		_ReflectionBlur("Blur", Range( 0 , 1)) = 0	
		_ReflectionFresnel("Curvature mask", Range( 0.01 , 20)) = 5	
		_ReflectionLighting("Lighting influence", Range( 0 , 1)) = 1	
		_PlanarReflectionLeft("Planar Reflections", 2D) = "" {} //Instanced
		_PlanarReflectionsEnabled("Planar Enabled", float) = 0 //Instanced
		
		//[Header(Waves)]
		[Toggle(_WAVES)] _WavesOn("_WAVES", Float) = 0

		_WaveSpeed("Speed", Float) = 2
		_WaveHeight("Height", Range(0 , 10)) = 0.25
		_WaveNormalStr("Normal Strength", Range(0 , 6)) = 0.5
		_WaveDistance("Distance", Range(0 , 1)) = 0.8
		_WaveFadeDistance("Fade Distance", vector) = (150, 300, 0, 0)


		_WaveSteepness("Steepness", Range(0 , 5)) = 0.1
		_WaveCount("Count", Range(1 , 5)) = 1
		_WaveDirection("Direction", vector) = (1,1,1,1)

		[NoScaleOffset][SingleLineTexture]_DepthControlTex("DepthControlTex", 2D) = "black" {}
		_DepthControlTexTilling("_DepthControlTexTilling", Float) = 2
		/* start Tessellation */
		//_TessValue("Max subdivisions", Range(1, 32)) = 16
		//_TessMin("Start Distance", Float) = 0
		//_TessMax("End Distance", Float) = 15
 		/* end Tessellation */
		[NoScaleOffset][SingleLineTexture]_CubeMap("_CubeMap", cube) = "white" {}
		//[CurvedWorldBendSettings] _CurvedWorldBendSettings("0|1|1", Vector) = (0, 0, 0, 0)
	}

	SubShader
	{		
		Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" }
				
		Pass
		{	
			Name "ForwardLit"
			Tags { "LightMode"="UniversalForward" }
			
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite [_ZWrite]
			Cull [_Cull]
			ZTest LEqual
			
			HLSLPROGRAM



			#pragma multi_compile_instancing
			/* start UnityFog */
			#pragma multi_compile_fog
			/* end UnityFog */

			#pragma target 3.0
			
			// Material Keywords
			//Note: _fragment suffix fails to work on GLES. Keywords would always be stripped
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local _DISTANCE_NORMALS
			#pragma shader_feature_local _WAVES
			#pragma shader_feature_local _FOAM
			#pragma shader_feature_local _UNLIT
			#pragma shader_feature_local _TRANSLUCENCY
			#pragma shader_feature_local _CAUSTICS
			#pragma shader_feature_local _REFRACTION
			#pragma shader_feature_local _ADVANCED_SHADING
			#pragma shader_feature_local _FLAT_SHADING
			#pragma shader_feature_local _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local _ENVIRONMENTREFLECTIONS_OFF
			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			#pragma shader_feature_local _DISABLE_DEPTH_TEX
			#pragma shader_feature_local _ _SHARP_INERSECTION _SMOOTH_INTERSECTION
			#pragma shader_feature_local _RIVER

			//Will be stripped, if extension is not installed
			#pragma multi_compile _ UNDERWATER_ENABLED
			//#pragma multi_compile _ WAVE_SIMULATION

			#if !_ADVANCED_SHADING
			#define _SIMPLE_SHADING
			#endif

			#if _RIVER
			#undef _WAVES
			#undef UNDERWATER_ENABLED
			#endif

			//Required to differentiate between skybox and scene geometry
			#if UNDERWATER_ENABLED
			#undef _DISABLE_DEPTH_TEX 
			#endif
			
			 //Caustics require depth texture
			#if _DISABLE_DEPTH_TEX
			#undef _CAUSTICS
			#endif
			
			//Requires some form of per-pixel offset
			#if !_NORMALMAP && !_WAVES
			#undef _REFRACTION
			#endif
			
			//Unity global keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _SHADOWS_SOFT
			
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS //URP 11+
			//Tiny use-case, disabled to reduce variants (each adds about 200-500)
			//#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE			

			//Stripped during building on older versions
			//URP 12+ only
			#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY

			#include "Libraries/URP.hlsl"

			/* start AtmosphericHeightFog */
//			#pragma multi_compile AHF_NOISEMODE_OFF AHF_NOISEMODE_PROCEDURAL3D
			/* end AtmosphericHeightFog */

			//Defines
			#define SHADERPASS_FORWARD
			#if !defined(_DISABLE_DEPTH_TEX) || defined(_REFRACTION) || defined(_CAUSTICS) || UNDERWATER_ENABLED
			//Required to read depth/opaque texture or other screen-space buffers
			#define SCREEN_POS
			#endif
			
			/* start Tessellation */
//			#define TESSELLATION_ON
//			#pragma require tessellation tessHW
//			#pragma hull Hull
//			#pragma domain Domain
			/* end Tessellation */
			


			#include "Libraries/Input.hlsl"

			//Uncommenting and rewriting is handled by the Curved World 2020 asset
			//#define CURVEDWORLD_BEND_TYPE_CLASSICRUNNER_X_POSITIVE
			//#define CURVEDWORLD_BEND_ID_1
			//#pragma shader_feature_local CURVEDWORLD_DISABLED_ON
			//#pragma shader_feature_local CURVEDWORLD_NORMAL_TRANSFORMATION_ON
			//#include "Assets/Amazing Assets/Curved World/Shaders/Core/CurvedWorldTransform.cginc"
			
			#include "Libraries/Common.hlsl"
			#include "Libraries/Fog.hlsl"
			#include "Libraries/Waves.hlsl"
			#include "Libraries/Lighting.hlsl"
			
			// #ifdef UNDERWATER_ENABLED
			// #include "Underwater/UnderwaterFog.hlsl"
			// #include "Underwater/UnderwaterShading.hlsl"
			// #endif

			#ifdef WAVE_SIMULATION
			#include "Libraries/Simulation/Simulation.hlsl"
			#endif

			#include "Libraries/Features.hlsl"
			#include "Libraries/Caustics.hlsl"

			#define VERTEX_PASS
			#include "Libraries/Vertex.hlsl"
			#undef VERTEX_PASS
			#include "Libraries/ForwardPass.hlsl"
			/* start Tessellation */
//			#include "Libraries/Tesselation.hlsl"
			/* end Tessellation */

			#pragma vertex Vertex
			#pragma fragment ForwardPass

			TEXTURECUBE(_CubeMap);
            SAMPLER(sampler_CubeMap);
			
			//#pragma fragment ForwardPassFragment
			Varyings Vertex(Attributes v)
			{
				return LitPassVertex(v);
			}

			half4 ForwardPass(Varyings input) : SV_Target
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
				
				// #if _FLAT_SHADING
				// float3 dpdx = ddx(wPos.xyz);
				// float3 dpdy = ddy(wPos.xyz);
				// normalWS = normalize(cross(dpdy, dpdx));
				// #endif

				//Returns mesh or world-space UV
				float2 uv = GetSourceUV(input.uv.xy, wPos.xz, _WorldSpaceUV);
				float2 flowMap = float2(1, 1);

				half slope = 0;
				// #if _RIVER
				// slope = GetSlopeInverse(normalWS);
				// //return float4(slope, slope, slope, 1);
				// #endif

				// Waves
				float height = 0;

				float3 waveNormal = normalWS;
			// #if _WAVES
			// 	WaveInfo waves = GetWaveInfo(uv, TIME * _WaveSpeed, _WaveFadeDistance.x, _WaveFadeDistance.y);
			// 	#if !_FLAT_SHADING
			// 		//Flatten by blue vertex color weight
			// 		waves.normal = lerp(waves.normal, normalWS, lerp(0, 1, vertexColor.b));
			// 		//Blend wave/vertex normals in world-space
			// 		waveNormal = BlendNormalWorldspaceRNM(waves.normal, normalWS, UP_VECTOR);
			// 	#endif
			// 	//return float4(waveNormal.xyz, 1);
			// 	height = waves.position.y * 0.5 + 0.5;
			// 	height *= lerp(1, 0, vertexColor.b);
			// 	//return float4(height, height, height, 1);
			//
			// 	//vertices are already displaced on XZ, in this case the world-space UV needs the same treatment
			// 	if(_WorldSpaceUV == 1) uv.xy -= waves.position.xz * HORIZONTAL_DISPLACEMENT_SCALAR * _WaveHeight;
			// 	//return float4(frac(uv.xy), 0, 1);
			// #endif

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

				// 岸边接触部分泡沫
				intersection = SampleIntersection(uv.xy, interSecGradient, TIME * _IntersectionSpeed);
				intersection *= _IntersectionColor.a;
				//return half4(intersection.xxx, 1.0f);

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

				// 岸上泡沫
				// 岸边采样修改后减少为两次。
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
				float4 depthContrl = SampleControlTex(input.uv.xy * _DepthControlTexTilling);
				float depthContrlval =  dot(half3(1,1,1) , depthContrl);
				//return half4(depthContrlval.xxx, 1.0f);
				//waterDensity *= depthContrlval;
				//baseColor = lerp(_ShallowColor, _BaseColor, dot(half3(1,1,1) , depthContrl));
				//float4 baseColor = lerp(_ShallowColor, _BaseColor, saturate(waterDensity * depthContrlval));
				float4 baseColor = lerp(_ShallowColor, _BaseColor, waterDensity);
				float pureArea = 1.0f - pow(saturate(waterDensity), 15.0f);
				//return half4(pureArea.xxx, 1.0f);
				baseColor = pureArea * baseColor + (1.0 - pureArea) * lerp(_DeepColor1, _BaseColor, depthContrlval);
				//baseColor = baseColor * 
				float4 baseAlpha = lerp(_ShallowColor, _BaseColor, waterDensity);
				//return half4(waterDensity.xxx, 1.0f);
				baseColor.rgb += _WaveTint * height;
				
				albedo.rgb = baseColor.rgb;
				alpha = baseAlpha.a;

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

				//Specular
                //float3 lightDir = normalize(half4(9.97f, 1.29f, 12.44f, 0.1f)); // normalize(_MainLightPosition);
                float3 lightDir = normalize(_SpecLightDir); // normalize(_MainLightPosition);
                float3 halfview = SafeNormalize(viewDirNorm + lightDir);
				//sunSpec = SpecularReflection(mainLight, viewDirNorm, sunReflectionNormals, _SunReflectionDistortion, _SunReflectionSize, _SunReflectionStrength);
				sunSpec = pow(max(0, dot(normalize(normalWS), halfview)), 36);
				sunSpec.rgb *= saturate((1-foam) * (1-intersection) * shadowMask); //Hide
				
				float specularRes = SampleSpecTex(uv *  _SpecTexTilling, TIME, _SpecNum);
                sunSpec *= smoothstep(0,1,specularRes) * _SpecStrength;
				//return half4(specularRes.xxx * 100.0f, 1.0f);
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
				//reflections = SampleReflections(reflectionVector, _ReflectionBlur, _PlanarReflectionsEnabled, ScreenPos.xyzw, wPos, refWorldTangentNormal, viewDirNorm, reflectionPerturbation);

                //half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectionVector,0);

				reflections = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, reflectionVector,0);
				//return half4(encodedIrradiance.xyz, 1.0f);
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

				// finalColor.a = max(0.8f, waterDensity);
				// finalColor.a += intersection;
				// finalColor.a += foam;
				//return half4(waterDensity.xxx, 1.0f);
				return finalColor;

				// SceneDepth depth00 = SampleDepth(ScreenPos);
				// return depth00.eye;
				// // // alpha 生成的这个部分，需要做修改，根据
				// // float3 NdotV = dot(viewDirNorm, normalWS);
				// // finalColor.a = saturate(1 - NdotV + 0.8) * saturate(1 - exp(depth * _Fade))*_BaseColor.a;
    // //             finalColor.a += foam;
    // //             finalColor.a *= saturate(depth * _AlphaFade);
    // //             finalColor.a += spec;
				// // return finalColor;

			}
			ENDHLSL
		}
		
		//Currently unused, except for prototypes (such as depth texture injection)
		Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }
            
            ZWrite On
			//ColorMask RG
            Cull Off

            HLSLPROGRAM
            #pragma target 3.0
            #pragma multi_compile_instancing

            #pragma shader_feature_local _WAVES

            /* start Tessellation */
//			#define TESSELLATION_ON
//			#pragma require tessellation tessHW
//			#pragma hull Hull
//			#pragma domain Domain
			/* end Tessellation */
            
            #pragma vertex Vertex
            #pragma fragment DepthOnlyFragment

            #define SHADERPASS_DEPTHONLY

            #include "Libraries/URP.hlsl"
            #include "Libraries/Input.hlsl"

			//#define CURVEDWORLD_BEND_TYPE_CLASSICRUNNER_X_POSITIVE
			//#define CURVEDWORLD_BEND_ID_1
			//#pragma shader_feature_local CURVEDWORLD_DISABLED_ON
			//#pragma shader_feature_local CURVEDWORLD_NORMAL_TRANSFORMATION_ON
			//#include "Assets/Amazing Assets/Curved World/Shaders/Core/CurvedWorldTransform.cginc"

            #include "Libraries/Common.hlsl"
            #include "Libraries/Fog.hlsl"
            #include "Libraries/Waves.hlsl"

            #define VERTEX_PASS
            #include "Libraries/Vertex.hlsl"
            #undef VERTEX_PASS

            /* start Tessellation */
//          #include "Libraries/Tesselation.hlsl"
            /* end Tessellation */

            Varyings Vertex(Attributes v)
            {
                return LitPassVertex(v);
            }

            half4 DepthOnlyFragment(Varyings input, FRONT_FACE_TYPE facing : FRONT_FACE_SEMANTIC) : SV_TARGET
            {
				UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            	float depth = input.positionCS.z;

                return float4(depth, facing, 0, 0);
            }

            ENDHLSL

        }
	}

	CustomEditor "StylizedWater2.MaterialUIClean"
	Fallback "Hidden/InternalErrorShader"	
}
