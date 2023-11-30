Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1,1,1,1)
        _Waves ("_Waves", 2D) = "white" {}
        _MainTex ("_MainTex", 2D) = "white" {}
        [Header(WorldUV_Offset)] _WorldUV_Offset ("xy：位移，zw：缩放", Vector) = (0.0, 0.0, 0.3, 0.3)
        [Header(SinWave)]_SinWaveParam ("x：影响 y：流速, zw: Tilling", Vector) = (0.36, 3.95, 0.1, 0.1)
        [Header(Wave00Param)]_Wave00Param ("x：波高， zw：Tilling", Vector) = (1.37, 1, 0.1, 0.1)
        _displacementBigWaveScale ("sin波影响因子", Float) = 0.48
        [Header(Wave01Param)]_Wave01Param ("x：波高， zw：Tilling", Vector) = (1, 1, 0.1, 0.1)
        _displacementSmallWaveScale ("小波影响因子", Float) = 0.12
        _WaveTotalDisplacementFactor ("波高总控制", Float) = 1
    	_CameraDistance ("_CameraDistance", Float) = 1.0
        _CameraRelatedFadeRange("_CameraRelatedFadeRange", Float) = 42.94
        _CameraRelatedClipRange("_CameraRelatedClipRange", Vector) =  (0, 70, 0.0, 0.0)
       _WaveTimeScale("波浪运动速度", Float) = 0.31

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
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct a2v
            {
                float4 posOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 posCS : SV_POSITION;
            };
            
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _Waves_ST;
            float4 _MainTex_ST;
            float4 _SinWaveParam;
            float4 _Wave00Param;
            float4 _Wave01Param;
            float4 _WorldUV_Offset;
            float _WaveTotalDisplacementFactor;
            float _displacementSmallWaveScale;
            float _WaveTimeScale;
            float _displacementBigWaveScale;
            float _CameraDistance;
            float _CameraRelatedFadeRange;
            float4 _CameraRelatedClipRange;
            CBUFFER_END

            TEXTURE2D(_Waves);
            SAMPLER(sampler_Waves);
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
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
				
				//"bakedLightmapUV" resolves to "staticLightmapUV" in URP12+
	
                worldPos.y += totalWaveDisplacement * _WaveTotalDisplacementFactor + 0.1f;
                //o.worldPos = worldPos;
                o.posCS = TransformWorldToHClip(worldPos);
                o.uv = v.uv;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv) * _BaseColor;
                // uv.x 
                return half4(col.rgb, col.a);
            }
            ENDHLSL
        }
    }

    FallBack Off
}