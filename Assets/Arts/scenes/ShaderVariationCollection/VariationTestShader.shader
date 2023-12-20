Shader "Custom/VariationTestShader"
{
    Properties
    {
       _MainTex ("Texture", 2D) = "white" {}
       _Color("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ MULTI_COMPILE
            //#pragma multi_compile_fragment _ MULTI_COMPILE_FRAGMENT
            #pragma multi_compile_fragment _ MULTI_COMPILE_FRAGMENT
            #pragma shader_feature_local_fragment _ SHADER_FEATURE_LOCAL_FRAGEMENT
            #pragma shader_feature_local _ SHADER_FEATURE_LOCAL
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
            half4 _Color;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            v2f vert(a2v v)
            {
                v2f o;

                VertexPositionInputs posInput = GetVertexPositionInputs(v.posOS.xyz);
                o.posCS = posInput.positionCS;
                o.uv = v.uv;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv) * _Color;
                
                return col;
            }
            ENDHLSL
        }
    }

    FallBack Off
}