Shader "FullScreen/FullScreenJitter"
{

    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
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
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"


        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST, _CausticTexture_ST;
        CBUFFER_END
        uniform half4 _MainTex_TexelSize;
        TEXTURE2D(_MainTex);       SAMPLER(sampler_MainTex);

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

            float4 jet1 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + _MainTex_TexelSize.xy * float2(-0.25, 0.111));
            float4 jet2 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + _MainTex_TexelSize.xy * float2(0.25, -0.388));
            float4 jet3 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + _MainTex_TexelSize.xy * float2(0.125, 0.222));
            float4 jet4 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv + _MainTex_TexelSize.xy * float2(0.125, -0.277));
            return (jet1 + jet2 + jet3 + jet4) * 0.25;
            return SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, i.uv);
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
