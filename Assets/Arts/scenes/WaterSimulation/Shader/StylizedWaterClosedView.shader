Shader "EngineSupport/StylizedWaterClosedView"
{
    Properties
    {
        _Waves ("Texture", 2D) = "white" {}
        [Header(WorldUV_Offset)] _WorldUV_Offset ("xy：位移，zw：缩放", Vector) = (0.0, 0.0, 0.3, 0.3)
        [Header(SinWave)]_SinWaveParam ("x：影响 y：流速, zw: Tilling", Vector) = (0.38, 4, 0.1, 0.1)
        [Header(Wave00Param)]_Wave00Param ("x：波高， zw：Tilling", Vector) = (1, 1, 0.1, 0.1)
        _displacementBigWaveScale ("sin波影响因子", Float) = 0.48
        [Header(Wave01Param)]_Wave01Param ("x：波高， zw：Tilling", Vector) = (1, 1, 0.1, 0.1)
        _displacementSmallWaveScale ("小波影响因子", Float) = 0.12
        _WaveTotalDisplacementFactor ("波高总控制", Float) = 1
    	_CameraDistance ("_CameraDistance", Float) = 1.0
        _CameraRelatedFadeRange("_CameraRelatedFadeRange", Float) = 20
        _CameraRelatedClipRange("_CameraRelatedClipRange", Vector) =  (0, 70, 0.0, 0.0)
    	
        _WaveTimeScale("波浪运动速度", Float) = 0.1
        _WaveNormalTex ("法线", 2D) = "white" {}
        _NormalFlowSpeed("法线移动速度", Vector) =  (0.07, 0.07, 0, 0)
        _NormalTilling("法线Tilling", Vector) =  (1, 1, 1, 1)
        _WaveCausticTex ("水底焦散", 2D) = "white" {}
        _Color1 ("_Color1", Color) =  (0.0, 0.0, 0.0, 0.0)
        _Color2 ("_Color2", Color) =  (0.0, 0.0, 0.0, 0.0)
        [Header(Intersection)]
    	_IntersectionNoiseTex ("交互泡沫贴图", 2D) = "white" {}
    	_IntersectionColor("_IntersectionColor", Color) = (1,1,1,1)
		_IntersectionLength("_IntersectionLength", Range(0.01 , 5)) = 2
		_IntersectionFalloff("_IntersectionFalloff", Range(0.01 , 1)) = 0.5
		_IntersectionTiling("_IntersectionTiling", float) = 0.2
		_IntersectionSpeed("_IntersectionSpeed", float) = 0.1
    	_IntersectionClipping("_IntersectionClipping", Range(0.01, 1)) = 0.5
		_IntersectionRippleDist("_IntersectionRippleDist", float) = 32
		_IntersectionRippleStrength("_IntersectionRippleStrength", Range(0 , 1)) = 0.5
    	
    	 [Header(Foam)]
    	_FoamTex("_FoamTex", 2D) = "black" {}
		_FoamColor("_FoamColor", Color) = (1,1,1,1)
		_FoamSize("_FoamSize", Range(0.01 , 0.999)) = 0.01
		_FoamSpeed("_FoamSpeed", float) = 0.1
    	_FoamWaveMask("_FoamWaveMask", Range(0, 1)) = 0.2
    	_FoamWaveMaskExp("_FoamWaveMaskExp", Range(1 , 8)) = 1
		_FoamTiling("_FoamTiling", float) = 0.1    	 
    	
    	[Header(DepthVariation)]
		[HDR]_BaseColor("Deep", Color) = (0, 0.44, 0.62, 1)
		[HDR]_DeepColor1("Deep1", Color) = (0, 0.44, 0.62, 1)    	
		[HDR]_ShallowColor("Shallow", Color) = (0.1, 0.9, 0.89, 0.02)
		[HDR]_HorizonColor("Horizon", Color) = (0.84, 1, 1, 0.15)

    	_DepthControlTex("_DepthControlTex", 2D) = "white" {}
    	_DepthControlTiling("_DepthControlTiling", float) = 1
		_DepthVertical("Vertical Depth", Range(0.01 , 8)) = 4
		_DepthHorizontal("Horizontal Depth", Range(0.01 , 8)) = 1
		_DepthExp("Exponential Blend", Range(0 , 1)) = 1
		_WaveTint("_WaveTint", Range(-0.1 , 1)) = 0

    	[Header(Sparkle)]
    	_SparkleSize("Sparkle Size", Range( 0 , 1)) = 0.318
    	_SparkleIntensity("Sparkle Intensity", Range(0 , 10)) = 0.2
		
    	[Header(World Reflection)]
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
    	

    	//_IntersectionNoiseTex ("交互泡沫贴图", 2D) = "white" {}
    	//_IntersectionColor("_IntersectionColor", Color) = (1,1,1,1)
		//_IntersectionLength("_IntersectionLength", Range(0.01 , 5)) = 2
		//_IntersectionFalloff("_IntersectionFalloff", Range(0.01 , 1)) = 0.5

        
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent" "ShaderModel"="4.5"
        }
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }
            Blend srcalpha oneminussrcalpha 
            ZWrite off
            Stencil
            {
               Ref 2
               Comp Always
               Pass Replace
            }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            
            
            struct a2v
            {
                float4 posOS : POSITION;
                float2 uv : TEXCOORD0;
            	float4 normalOS  : NORMAL;
				float4 tangentOS  : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 posCS : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            	float3 tangent 		: TANGENT;
				//wPos.z in w-component
				float3 bitangent 	: TEXCOORD4;
            };
            
            CBUFFER_START(UnityPerMaterial)

            float4 _MainTex_ST;
            float4 _Waves_ST;
            float4 _SinWaveParam;
            float4 _Wave00Param;
            float4 _Wave01Param;
            float4 _WorldUV_Offset;
            float4 _Color1;
            float4 _Color2;
            float _WaveTotalDisplacementFactor;
            float _displacementSmallWaveScale;
            float _WaveTimeScale;
            float _displacementBigWaveScale;
            float _CameraDistance;
            float _CameraRelatedFadeRange;
            float4 _CameraRelatedClipRange;
            float4 _NormalFlowSpeed;
            float4 _NormalTilling;

			//Intersection
			half _IntersectionSource;
			half _IntersectionLength;
			half _IntersectionFalloff;
			half _IntersectionTiling;
			half _IntersectionRippleDist;
			half _IntersectionRippleStrength;
			half _IntersectionClipping;
			float _IntersectionSpeed;

            //Foam
			float _FoamTiling;
			float4 _FoamColor;
			float _FoamSpeed;
			half _FoamSize;
			half _FoamWaveMask;
			half _FoamWaveMaskExp;

            // _DepthControl :
            half _DepthControlTiling;
			float _DepthVertical;
			float _DepthHorizontal;
			float _DepthExp;
            // 调整wave对水体颜色的影响
			float _WaveTint;

            // Color:
            float4 _ShallowColor;
			float4 _BaseColor;
			float4 _DeepColor1;


            // sparkles:
            float _SparkleIntensity;
			float _SparkleSize;
            
            CBUFFER_END

            TEXTURE2D(_Waves);
            SAMPLER(sampler_Waves);

            TEXTURE2D(_WaveNormalTex);
            SAMPLER(sampler_WaveNormalTex);

            TEXTURE2D(_WaveCausticTex);
            SAMPLER(sampler_WaveCausticTex);

            TEXTURE2D(_IntersectionNoiseTex);
            SAMPLER(sampler_IntersectionNoiseTex);

            TEXTURE2D(_FoamTex);
            SAMPLER(sampler_FoamTex);

			TEXTURE2D(_DepthControlTex);
            SAMPLER(sampler_DepthControlTex);
            
            TEXTURE2D_X_FLOAT(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            struct SceneDepth
			{
				float raw;
				float linear01;
				float eye;
			};
            //Reconstruct view-space position from depth.
			float3 ReconstructViewPos(float4 screenPos, float3 viewDir, SceneDepth sceneDepth)
			{
				#if UNITY_REVERSED_Z
				real rawDepth = sceneDepth.raw;
				#else
				// Adjust z to match NDC for OpenGL
				real rawDepth = lerp(UNITY_NEAR_CLIP_VALUE, 1, sceneDepth.raw);
				#endif
				
				#if defined(ORTHOGRAPHIC_SUPPORT)
				//View to world position
				float4 viewPos = float4((screenPos.xy/screenPos.w) * 2.0 - 1.0, rawDepth, 1.0);
				float4x4 viewToWorld = UNITY_MATRIX_I_VP;
				#if UNITY_REVERSED_Z //Wrecked since 7.3.1 "fix" and causes warping, invert second row https://issuetracker.unity3d.com/issues/shadergraph-inverse-view-projection-transformation-matrix-is-not-the-inverse-of-view-projection-transformation-matrix
				//Commit https://github.com/Unity-Technologies/Graphics/pull/374/files
				viewToWorld._12_22_32_42 = -viewToWorld._12_22_32_42;              
				#endif
				float4 viewWorld = mul(viewToWorld, viewPos);
				float3 viewWorldPos = viewWorld.xyz / viewWorld.w;
				#endif

				//Projection to world position
				float3 camPos = _WorldSpaceCameraPos.xyz;
				float3 worldPos = sceneDepth.eye * (viewDir/screenPos.w) - camPos;
				float3 perspWorldPos = -worldPos;

				#if defined(ORTHOGRAPHIC_SUPPORT)
				return lerp(perspWorldPos, viewWorldPos, unity_OrthoParams.w);
				#else
				return perspWorldPos;
				#endif

			}

            //Return depth based on the used technique (buffer, vertex color, baked texture)
			SceneDepth SampleDepth(float2 screenPos)
			{
				SceneDepth depth = (SceneDepth)0;
				depth.raw = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos.xy).r;
				depth.eye = LinearEyeDepth(depth.raw, _ZBufferParams);
				depth.linear01 = 0.0; //LinearDepth(screenPos.z, depth.eye);
				return depth;
			}


            
            v2f vert(a2v v)
            {
                v2f o;
                
                float3 worldPos = mul(unity_ObjectToWorld, half4(v.posOS.xyz, 1.0f)).xyz;

                float3 camDistance = (worldPos - _WorldSpaceCameraPos);
                float d = sqrt(dot(camDistance, camDistance));
                d -= _CameraRelatedFadeRange;
                d = max(d, _CameraRelatedClipRange.x);
                d = min(d, _CameraRelatedClipRange.y);
                d /= _CameraRelatedClipRange.y;
                d = 1.0 - d;

                float4 WorldUV;
                // 基本思想： 采两次b通道，每次做一个小位移和tilling，然后做相加平均
                // 在上面叠加一个sin波做扰动
                float2 scaledWorldPos= worldPos.xz + (-_WorldUV_Offset.xy);
                scaledWorldPos.xy = scaledWorldPos.xy * (-_WorldUV_Offset.zw);
                WorldUV = scaledWorldPos.xyxy * float4(_displacementSmallWaveScale, _displacementSmallWaveScale, _displacementBigWaveScale, _displacementBigWaveScale);
                float time = _Time.x * _WaveTimeScale;
                float2 timeScale;
                timeScale.y = _Time.x * _WaveTimeScale;
                timeScale.x = (-timeScale.y);
                float2 wave00UV = WorldUV.xy * float2(_Wave00Param.zw) + timeScale.xy;
                timeScale.xy = timeScale.yy * float2(1.0, -1.0);
                wave00UV = wave00UV * _Waves_ST.xy + _Waves_ST.zw;

                half waveValue00 = SAMPLE_TEXTURE2D_LOD(_Waves, sampler_Waves, float2(wave00UV), 0.0f).y    ;
                waveValue00 = d * waveValue00;
                waveValue00 *= _Wave00Param.x;

                
                float2 sinWaveUV = WorldUV.zw * float2(_SinWaveParam.zw);
                sinWaveUV = (-_SinWaveParam.yy) * time.xx + sinWaveUV;
                sinWaveUV = sinWaveUV * _Waves_ST.xy + _Waves_ST.zw;
                half sinWaveValue = SAMPLE_TEXTURE2D_LOD(_Waves, sampler_Waves, float2(sinWaveUV), 0.0f).z;
                sinWaveValue = d * sinWaveValue;
                
                float2 wave01UV = WorldUV.xy * float2(_Wave01Param.zw) + float2(0.5, 0.5);
                wave01UV = wave01UV * float2(0.75, 0.75) + timeScale.xy;
                wave01UV = wave01UV * _Waves_ST.xy + _Waves_ST.zw;
                half waveValue01 = SAMPLE_TEXTURE2D_LOD(_Waves, sampler_Waves, float2(wave01UV), 0.0f).y;
                waveValue01 = waveValue01 * d ;
                waveValue01*= _Wave01Param.x;
                
                half totalWaveVal = waveValue01 * 0.5 + waveValue00 * 0.5 ;
                half totalWaveDisplacement = sinWaveValue * _SinWaveParam.x + totalWaveVal;
				

                worldPos.y += totalWaveDisplacement * _WaveTotalDisplacementFactor;
                o.worldPos = worldPos;
                o.posCS = TransformWorldToHClip(worldPos);
                //VertexPositionInputs posInput = GetVertexPositionInputs(v.posOS.xyz);
                o.uv = v.uv;

				VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS.xyz, v.tangentOS);
				o.tangent = normalInput.tangentWS;
				o.bitangent = normalInput.bitangentWS;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float3 ddxPos = normalize(ddx(i.worldPos));
                float3 ddyPos = normalize(ddy(i.worldPos));
                float3 normal = normalize( cross(ddyPos, ddxPos));
                float2 WorldUV = i.worldPos.xz;
                float3 worldPos = i.worldPos;
                float3 viewDir = (_WorldSpaceCameraPos - i.worldPos);
				float3 viewDirNorm = SafeNormalize(viewDir);

                
                // Sample Normal: 两次：
                float2 NormalUV1 = _NormalTilling.xy * WorldUV.xy + (_Time.xx * _NormalFlowSpeed.xy);
	            float2 NormalUV2 = _NormalTilling.zw * (WorldUV.xy * 0.5) + ((1.0 - _Time.xx) * _NormalFlowSpeed.xy * 0.5f);
                float3 n1 = UnpackNormal(SAMPLE_TEXTURE2D(_WaveNormalTex, sampler_WaveNormalTex, NormalUV1));
	            float3 n2 = UnpackNormal(SAMPLE_TEXTURE2D(_WaveNormalTex, sampler_WaveNormalTex, NormalUV2));

	            float3 blendedNormals = BlendNormalRNM(n1, n2);
            	float3 worldTangentNormal = normalize(TransformTangentToWorld(blendedNormals, half3x3(i.bitangent, i.tangent, normal)));
				//return half4(blendedNormals.xyz, 1.0f);
                //todo: do normal blend here----

                
                // Sample Depth:
                float4 pos = ComputeScreenPos(TransformWorldToHClip(i.worldPos.xyz));
                float2 screenPos = pos.xy / pos.w;
                //depth
                SceneDepth depth = SampleDepth(screenPos); //采样深度
            	float3 opaqueWorldPos = ReconstructViewPos(pos, viewDir, depth);
				float opaqueDist = length((worldPos - opaqueWorldPos) * normal);
				//return float4(opaqueDist.xxx, 1);
            	//return half4(normal.xyz, 1.0f);

                // Intersection 岸边接触部分泡沫
				float interSecGradient = 0;
				float intersection = 0;
				interSecGradient = 1-saturate(exp(opaqueDist) / _IntersectionLength);	
				
				//-----------------------------------------------Intersection part
            	float inter = 0;
				float dist = 0;
            	float sine = sin(_Time.x  * 10 - (interSecGradient * _IntersectionRippleDist)) * _IntersectionRippleStrength;
            	float2 IntersectionUV = WorldUV.xy * _IntersectionTiling;
            	float noise = SAMPLE_TEXTURE2D(_IntersectionNoiseTex, sampler_IntersectionNoiseTex, IntersectionUV + _Time.xx *  _IntersectionSpeed).r;

				dist = saturate(interSecGradient / _IntersectionFalloff);
				noise = saturate((noise + sine) * dist + dist);
				inter = step(_IntersectionClipping, noise);

            	if(i.worldPos.y < opaqueWorldPos.y) intersection = 0;

				//Flatten normals on intersection foam
				//waveNormal = lerp(waveNormal, normalWS, intersection);
				//return half4(inter.xxx, 1.0f);
				//return saturate(inter);
				//-----------------------------------------------Intersection part
				
				//-----------------------------------------------Foam part
            	// 泡沫产生的地方，与波动的高度有关
            	// 这个地方，波最高是多高？
				 float foam = 0;
				 float height = i.worldPos.y * 0.5 + 0.5;;
				 float foamMask = lerp(1, saturate(height), _FoamWaveMask);
				 foamMask = pow(abs(foamMask), _FoamWaveMaskExp);
				 //foamMask *= (i.worldPos.y - 0.7f);
            	//float height = i.worldPos.y - 0.7f;
				foam = SAMPLE_TEXTURE2D(_IntersectionNoiseTex, sampler_IntersectionNoiseTex, IntersectionUV + _Time.xx *  _IntersectionSpeed).r;
            	float2 sourceUV = WorldUV * _FoamTiling;
				float2 uv1 = sourceUV.xy + (_Time.xx * _FoamSpeed);
				float2 uv2 = (sourceUV.xy * 0.5) + (_Time.xx * _FoamSpeed);
				float f1 = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, uv1.xy).r;
				float f2 = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, uv2.xy).r;
				float finalFoam = saturate(f1 + f2) * foamMask;
				foam = smoothstep(_FoamSize, 1.0, finalFoam);
				//return foam;
            	//-----------------------------------------------Foam part

				
				//-----------------------------------------------Depth part
            	float2 depthUV = WorldUV * _DepthControlTiling * 0.01f;
				float4 depthContrl = SAMPLE_TEXTURE2D(_DepthControlTex, sampler_DepthControlTex, depthUV.xy).xyzw;
				float depthContrlval =  dot(half3(1,1,1) , depthContrl);

            	float waterDensity = 1;
            	float surfaceDepth = depth.eye - pos.w;
            	float distanceAttenuation = 1.0 - exp(-surfaceDepth * _DepthVertical * lerp(0.1, 0.01, unity_OrthoParams.w));
				float heightAttenuation = saturate(lerp(opaqueDist * _DepthHorizontal, 1.0 - exp(-opaqueDist * _DepthHorizontal), _DepthExp));
				
				waterDensity = max(distanceAttenuation, heightAttenuation);
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
				
				float3 albedo;
				float alpha;
            	albedo.rgb = baseColor.rgb + foam * _FoamColor;
				alpha = baseAlpha.a;
				//return half4(albedo.rgb, alpha);
				//-----------------------------------------------Depth part

            	
            	//-----------------------------------------------sparkles part
            	float3 sparkles = 0;
				float NdotL = saturate(dot(float3(0.0f,1.0f,0.0f), worldTangentNormal));
				half sunAngle = saturate(dot(float3(0.0f,1.0f,0.0f), _MainLightPosition));
				half angleMask = saturate(sunAngle * 10); /* 1.0/0.10 = 10 */
				sparkles = saturate(step(_SparkleSize, (saturate(blendedNormals.y) * NdotL))) * _SparkleIntensity * _MainLightColor * angleMask;
				albedo.rgb += sparkles.rgb;
            	return half4(albedo.xyz,1.0f);

            	//-----------------------------------------------sparkles part
				#if WAVE_SIMULATION
				SampleWaveSimulationFoam(wPos, foam);
				#endif
            	//-----------------------------------------------Foam part


            	float3 sunReflectionNormals = worldTangentNormal;

            	half3 sunSpec = 0;
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
			// #ifndef _ENVIRONMENTREFLECTIONS_OFF
			// 	float3 refWorldTangentNormal = lerp(waveNormal, normalize(waveNormal + worldTangentNormal), _ReflectionDistortion);
   //
			// 	#if _FLAT_SHADING //Skip, not a good fit
			// 	refWorldTangentNormal = waveNormal;
			// 	#endif
			// 	
			// 	float3 reflectionVector = reflect(-viewDirNorm , refWorldTangentNormal);
			// 	float2 reflectionPerturbation = lerp(waveNormal.xz * 0.5, worldTangentNormal.xy, _ReflectionDistortion).xy;
			// 	//reflections = SampleReflections(reflectionVector, _ReflectionBlur, _PlanarReflectionsEnabled, ScreenPos.xyzw, wPos, refWorldTangentNormal, viewDirNorm, reflectionPerturbation);
   //
   //              //half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectionVector,0);
   //
			// 	reflections = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, reflectionVector,0);
			// 	//return half4(encodedIrradiance.xyz, 1.0f);
			// 	half reflectionFresnel = ReflectionFresnel(refWorldTangentNormal, viewDirNorm, _ReflectionFresnel);
			// 	half reflectionMask = _ReflectionStrength * reflectionFresnel * vFace;
			// 	reflectionMask = saturate(reflectionMask - foam - intersection);
			// 	//return float4(reflectionFresnel.xxx, 1);
   //
			// 	//Blend reflection with albedo. Diffuse lighting will affect it
			// 	albedo.rgb = lerp(albedo, lerp(albedo.rgb, reflections, reflectionMask), _ReflectionLighting);
			// 	//return float4(albedo.rgb, 1);
			// 	
			// 	//Will be added to emission in lighting function
			// 	reflections *= reflectionMask * (1-_ReflectionLighting);
			// 	return float4(reflections.rgb, 1);
			// #endif

            	
				// #if UNDERWATER_ENABLED
				// intersection *= vFace;
				// #endif
				
				// #if _WAVES
				// //Prevent from peering through waves when camera is at the water level
				// if(wPos.y < opaqueWorldPos.y) intersection = 0;
				// #endif
                
                // Normalized direction to the light source
                float3 lightDir = normalize(_MainLightPosition.xyz);
                // Calculate the Blinn-Phong reflection model
                //float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                //
                float3 halfDir = normalize(lightDir + viewDir);
                float diff = max(0.0, dot(normal, lightDir));
                //float spec = pow(max(0.0, dot(normal, halfDir)), _Shininess * 128.0);
                
                float waveHeight = saturate(i.worldPos.y/1.0f);
                //col.rgb =  ;
                // Combine the textures and light effects
                //fixed4 col = tex2D(_MainTex, i.vertex.xy) * _Color;
                half4 col =  _Color1;
                float3 _LightColor0 = float3(1.0, 1.0, 1.0);
                col.rgb *= _LightColor0.rgb * diff; // Diffuse lighting
                //col.rgb += _Specular.rgb * _LightColor0.rgb * spec; // Specular lighting
                return col;
            }
            ENDHLSL
        }
    }

    FallBack Off
}