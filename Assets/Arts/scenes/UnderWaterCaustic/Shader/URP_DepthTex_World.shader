Shader "Unlit/URP_DepthTex_World"
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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/GlobalSamplers.hlsl"

            struct a2v
            {
                float4 posOS : POSITION;
                float2 uv : TEXCOORD0;
                uint vertexID : SV_VertexID;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
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
                #if SHADER_API_GLES
                    float4 pos = input.positionOS;
                    float2 uv  = input.uv;
                #else
                    float4 pos = GetFullScreenTriangleVertexPosition(v.vertexID);
                    float2 uv  = GetFullScreenTriangleTexCoord(v.vertexID);
                #endif

                    o.positionCS = pos;
                    output.texcoord   = uv * _BlitScaleBias.xy + _BlitScaleBias.zw;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv) * _Color;
                half4 screenPos = ComputeScreenPos(i.posCS);
                half2 screenUV = screenPos.xy / screenPos.w;
                #if UNITY_REVERSED_Z
                    float deviceDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_PointClamp, i.uv.xy).r;
                #else
                    float deviceDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_PointClamp, input.texcoord.xy).r;
                    deviceDepth = deviceDepth * 2.0 - 1.0;
                #endif

                //Fetch shadow coordinates for cascade.
                //float3 wpos = ComputeWorldSpacePosition(i.uv.xy, deviceDepth, unity_MatrixInvVP);
                float3 wpos = ComputeWorldSpacePosition(i.uv.xy, deviceDepth, unity_MatrixInvVP);
                return half4(wpos, 1.0f);
                return 1.0f;
            }
            ENDHLSL
        }
    }

    FallBack Off
}