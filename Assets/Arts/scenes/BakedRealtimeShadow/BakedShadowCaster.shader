Shader "Unlit/BakedShadowCaster"
{
    Properties
    {
        _BakedShadowMap ("_BakedShadowMap", 2D) = "white" {}
        _BaseColor ("ShadowColor", Color) = (0,0,0,0)
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100
        
        Pass
        {
            Tags
            {
                "LightMode" = "ScreenSpaceOcclusionCaster"
            }
            Blend srcalpha oneminussrcalpha
            Name "ScreenSpaceShadowCaster"
            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex LitPassVertexLocal
            #pragma fragment LitPassFragmentLocal

            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
            #pragma enable_d3d11_debug_symbols

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitForwardPass.hlsl"
            TEXTURE2D(_BakedShadowMap);
            SAMPLER(sampler_BakedShadowMap);

            UNITY_INSTANCING_BUFFER_START(ShadowPros)
                UNITY_DEFINE_INSTANCED_PROP(float4x4, _ShadowMatrix_Array)
                UNITY_DEFINE_INSTANCED_PROP(float4, _ShadowChanelIndex_Array)
            UNITY_INSTANCING_BUFFER_END(ShadowPros)

            #define _ShadowMatrix UNITY_ACCESS_INSTANCED_PROP(ShadowPros, _ShadowMatrix_Array)
            #define _ShadowChanelIndex UNITY_ACCESS_INSTANCED_PROP(ShadowPros, _ShadowChanelIndex_Array)
            
            Varyings LitPassVertexLocal(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                output.uv = input.texcoord;
                return output;
            }
            // Used in Standard (Physically Based) shader
            void LitPassFragmentLocal(
                Varyings input
                , out half4 outColor : SV_Target0
            #ifdef _WRITE_RENDERING_LAYERS
                , out float4 outRenderingLayers : SV_Target1
            #endif
            )
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float4 shadowCoord = mul(_ShadowMatrix, float4(input.positionWS, 1.0));
                half4 shadowmap = SAMPLE_TEXTURE2D(_BakedShadowMap, sampler_BakedShadowMap, shadowCoord.xy);
                float chanelMixed = dot(shadowmap, _ShadowChanelIndex);
                half shadowRes = step(0.0001, chanelMixed);
                shadowRes = shadowCoord.x > 1.0f || shadowCoord.x < 0.0f ? 0.0 : shadowRes;
                shadowRes = shadowCoord.y > 1.0f || shadowCoord.y < 0.0f ? 0.0 : shadowRes;
                half3 color = shadowRes * _BaseColor;
                outColor = half4(color.xyz, shadowRes);
            #ifdef _WRITE_RENDERING_LAYERS
                uint renderingLayers = GetMeshRenderingLayer();
                outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
            #endif
            }
            ENDHLSL
        }
    }
}
