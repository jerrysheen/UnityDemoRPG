Shader "ELEX/OutLine"
{
    Properties
    {
        [MainColor]_BaseColor("Color", Color) = (0, 0, 0, 0)
        _EdgeWidth("EdgeWidth", Range(0,1)) = 0.003
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        Cull Front
        Pass
        {
            Name "Unlit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            //#pragma exclude_renderers d3d11_9x

            #pragma vertex vert
            #pragma fragment frag

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            //#pragma enable_d3d11_debug_symbols
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                float _EdgeWidth;
            CBUFFER_END

            #ifdef UNITY_DOTS_INSTANCING_ENABLED
            UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
                UNITY_DOTS_INSTANCED_PROP(float4, _BaseColor)
                UNITY_DOTS_INSTANCED_PROP(float , _EdgeWidth)
            UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

            #define _BaseColor          UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4 , _BaseColor)
            #define _EdgeWidth             UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float  , _EdgeWidth)
            #endif

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                float3 normalOS = input.normal;
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);// + normalize (input.normal) * _BaseColor.a*0.1 * (vv.z+0.5)); 
                output.vertex = TransformObjectToHClip(input.positionOS);

                // remove ununiform scaling affect
                half3 viewNormal = mul((half3x3) UNITY_MATRIX_IT_MV, normalOS);
                half3 clipNormal = normalize(mul((half3x3) UNITY_MATRIX_P, viewNormal));

                // remove aspect ration affect
                float4 screenParam = GetScaledScreenParams();
                half aspect = screenParam.y / screenParam.x;
                clipNormal.x *= aspect;
                output.vertex.xy += clipNormal.xy * _EdgeWidth * output.vertex.w;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                half3 color = _BaseColor.rgb;
                return half4(color, 1.0);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
