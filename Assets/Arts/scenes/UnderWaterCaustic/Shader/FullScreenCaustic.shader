Shader "EngineSupport/FullScreenCaustic"
{

    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        //_NormalTex("_NormalTex", 2D) = "white" {}
        _NoiseTex("_NoiseTex", 2D) = "white" {}
        _CausticTexture("_CausticTexture", 2D) = "white" {}
        _CameraRelatedFadeRange("相机衰减距离补偿", Float) = 42.94
        _CameraRelatedClipRange("x:焦散从什么距离开始衰减 y:焦散在什么距离完全消失", Vector) =  (0, 70, 0.0, 0.0)
        _NoiseAttan("x: noise对焦散1扰动影响 y：noise对焦散2扰动影响, zw：扰动速率", Vector) =  (0.04, 0.05, 1.9,1.8)
        
        [Header(Caustic1)]_FlowParam00("xy: dir，z: speed, w:tilling", Vector) =  (1, 1, 0.5,0)
        _VerticalCompensate0("用来补偿焦散1采样面垂直xz时候的采样异常", Vector) =  (1.5, 1.3, 0.5, 0.5)
        _CausticAttan0("焦散强度1", Float) =  2.0
        
        [Header(Caustic2)]_FlowParam01("xy: dir，z: speed, w:tilling", Vector) =  (1, 1, 0.5,0)
        _VerticalCompensate1("用来补偿焦散2采样面垂直xz时候的采样异常", Vector) =  (1.5, 1.3, 0.5, 0.5)
        _CausticAttan1("焦散强度2", Float) =  2.0

    }
    SubShader
    {
        Tags{ "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}

        HLSLINCLUDE

        //Keep compiler quiet about Shadows.hlsl.
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
        // Core.hlsl for XR dependencies
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

        TEXTURE2D(_CausticTexture);       SAMPLER(sampler_CausticTexture);
        //TEXTURE2D(_NormalTex);            SAMPLER(sampler_NormalTex);
        TEXTURE2D(_NoiseTex);            SAMPLER(sampler_NoiseTex);


        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST, _CausticTexture_ST;
            float4 _NoiseTex_ST;
            float _CameraRelatedFadeRange;
            float4 _CameraRelatedClipRange;
            float4 _VerticalCompensate0;
            float4 _VerticalCompensate1;
            float4 _NoiseAttan;
            float4 _FlowParam00;
            float4 _FlowParam01;
            float _CausticAttan0;
            float _CausticAttan1;
        CBUFFER_END

        TEXTURE2D(_MainTex);       SAMPLER(sampler_MainTex);
        TEXTURE2D(_MaskSecondTex);       SAMPLER(sampler_MaskSecondTex);

        struct appdata{
            float4 vertex : POSITION;
            float2 texcoord : TEXCOORD0;
        };

        struct v2f {
	        float4 pos : SV_POSITION;
	        half2 uv : TEXCOORD0;
            float3 worldPos : TEXCOORD1;

        };

		v2f vert(appdata v) {
			v2f o;
			o.pos = TransformObjectToHClip(v.vertex.xyz);

			o.uv = v.texcoord;
            o.worldPos = TransformObjectToWorld(v.vertex.xyz);
			return o;
		}

        half4 Fragment(v2f i) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

#if UNITY_REVERSED_Z
            float deviceDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_PointClamp, i.uv).r;
#else
            float deviceDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_PointClamp, input.texcoord.xy).r;
            deviceDepth = deviceDepth * 2.0 - 1.0;
#endif
            float4 blitTex = SAMPLE_TEXTURE2D(_MainTex, sampler_PointClamp, i.uv);
            //Fetch shadow coordinates for cascade.
            float3 wpos = ComputeWorldSpacePosition(i.uv, deviceDepth, unity_MatrixInvVP);

            float2 noiseUV = wpos.xz * _NoiseTex_ST.xy + _NoiseTex_ST.zw + _Time.x * _NoiseAttan.zw;
            float3 noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, noiseUV);
            noise = sin((noise - 0.5f) * 2.0f);

            //normal = 0;
            half2 worldPosWithCompensite0 = half2(wpos.x +_VerticalCompensate0.z* sin(_VerticalCompensate0.x * wpos.y), wpos.z + _VerticalCompensate0.w * cos( _VerticalCompensate0.y * wpos.y));
            float2 causticUV0 = (worldPosWithCompensite0 + _NoiseAttan.x * noise.rg)* _FlowParam00.w + _Time.y * _FlowParam00.z * normalize(_FlowParam00.xy);
            float4 caustic = SAMPLE_TEXTURE2D(_CausticTexture, sampler_CausticTexture, causticUV0) ;
            half2 worldPosWithCompensite1 = half2(wpos.x +_VerticalCompensate1.z* sin(_VerticalCompensate1.x * wpos.y), wpos.z + _VerticalCompensate1.w * cos( _VerticalCompensate1.y * wpos.y));
            float2 causticUV1 = (worldPosWithCompensite1 + _NoiseAttan.y * noise.rg)* _FlowParam01.w + _Time.y * _FlowParam01.z * normalize(_FlowParam01.xy);
            float4 caustic1 = SAMPLE_TEXTURE2D(_CausticTexture, sampler_CausticTexture, 1.0 - causticUV1);

            caustic *= _CausticAttan0;
            caustic1 *= _CausticAttan1;
            float3 camDistance = (wpos - _WorldSpaceCameraPos);

            float d = sqrt(dot(camDistance, camDistance));
            d -= _CameraRelatedFadeRange;
            d = max(d, _CameraRelatedClipRange.x);
            d = min(d, _CameraRelatedClipRange.y);
            d /= _CameraRelatedClipRange.y;
            d = 1.0 - d;
            return blitTex + (caustic1 +caustic) * 0.5f * d;
        }

        ENDHLSL

        Pass
        {
            Name "FullScreenCaustic"
            ZTest Off
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            //#pragma multi_compile _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            //#pragma multi_compile_fragment _ _SHADOWS_SOFT

            #pragma vertex   vert
            #pragma fragment Fragment
            ENDHLSL
        }
    }
}
