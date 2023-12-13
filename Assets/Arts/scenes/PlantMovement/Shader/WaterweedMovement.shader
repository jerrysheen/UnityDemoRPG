Shader "Unlit/WaterweedMovement"
{
    Properties
    {
       _MainTex ("Texture", 2D) = "white" {}
       _Color("Color", Color) = (1,1,1,1)
       _XMovementAtten("X位移", Float) = 0.3
       _XMovementSpeed("X方向运动速度", Float) = 1.0

       _YMovementAtten("Y位移", Float) = 0.1
       _YMovementSpeed("X方向运动速度", Float) = 1.0

    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" 
        }
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }
            
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct a2v
            {
                float4 posOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexColor : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 posCS : SV_POSITION;
            };
            
            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            float _YMovementAtten;
            float _XMovementAtten;
            float _YMovementSpeed;
            float _XMovementSpeed;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            v2f vert(a2v v)
            {
                v2f o;
                float posIndentity = UNITY_MATRIX_M[0][3] + UNITY_MATRIX_M[1][3] + UNITY_MATRIX_M[2][3];
                v.posOS.x += sin(_XMovementSpeed * _Time.y +  v.vertexColor.r + posIndentity) * _XMovementAtten * v.vertexColor.g;
                v.posOS.y += sin(_YMovementSpeed * _Time.y +  v.vertexColor.r + posIndentity) * _YMovementAtten * v.vertexColor.g;
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