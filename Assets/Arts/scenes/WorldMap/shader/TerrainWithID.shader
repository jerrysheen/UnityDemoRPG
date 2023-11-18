Shader "Custom/TerrainWithID"
{
    Properties
    {
        _DiffuseArr ("Diffuse Array", 2DArray) = "" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _AlbedoPow ("Albedo Pow", Range(0, 10)) = 1.0
        _MipMapFactor ("MipMap Level Factor", Range(0, 100)) = 42.0
        [KeywordEnum(None, Low, High)] _Tiling("Random Tiling Quality", Float) = 0
        [MaterialToggle(_FRAME_CACHE_ON)] _ToggleFrameCache("Enable Frame Cache", Float) = 0
        [MaterialToggle(_WORLDSPACE_UV_ON)] _ToggleWorldSpaceUV("Enable World Space UV", Float) = 0

        [Space(5)]
        [Header(Normalmap)]
        _GlobalNormal ("Global Normalmap", 2D) = "bump" {}
        _Normal0 ("Normalmap 0", 2D) = "bump" {}
        _Normal1 ("Normalmap 1", 2D) = "bump" {}
        _NormalChoiceGroup0("Normalmap Choice Group 0", Vector) = (1.0, 1.0, 1.0, 1.0)
        _NormalChoiceGroup1("Normalmap Choice Group 1", Vector) = (1.0, 1.0, 1.0, 1.0)
        _NormalChoiceGroup2("Normalmap Choice Group 2", Vector) = (1.0, 1.0, 1.0, 1.0)
        _NormalChoiceGroup3("Normalmap Choice Group 3", Vector) = (1.0, 1.0, 1.0, 1.0)

        [Space(5)]
        [Header(Blending)]
        _BlendDistanceFactor ("Lerp Distance Factor", Range( 0 , 1000)) = 200.0
        [MaterialToggle(_BIASED_UV_ON)] _ToggleBiasedUV("Enable Biased UV", Float) = 0
        _BiasedUVFactor ("Biased UV Factor", Range( 1 , 10)) = 1.0
        [KeywordEnum(R8, R8G8)] _IDFormat("ID Map Format", Float) = 0
        _IDMapTex ("ID Map Texture", 2D) = "black" {}
        _Rect ("World Rect", Vector) = (0.0, 0.0, 0.0, 0.0)

        [Space(5)]
        [Header(Macro Variation)]
        [MaterialToggle(_MACRO_VARIATION_ON)] _ToggleMacroVariation("Enable Macro Variation", Float) = 0
        _NoiseTex ("Variation Texture", 2D) = "black" {}
        _VariationUVScale("Variation UV Scale", Vector) = (2.0, 0.3, 0.02)
        _VariationStrength("Variation Strength", Range( 0 , 10)) = 1.5

        [Space(5)]
        [Header(Edge Optimization)]
        [MaterialToggle(_EDGE_OPTIMIZATION_ON)] _ToggleEdgeOptimization("Enable Edge Optimization", Float) = 1.0
        [MaterialToggle(_BLEND_WITH_NOISE_ON)] _BlendWithNoise("Blend With Noise", Float) = 1.0
        _CornerAtlas ("Corner Atlas", 2D) = "black" {}   
        _NoiseScale("Noise Scale (x for noise scale, z for noise strengnth)" , Vector) = (5000, 0.0, 5.0, 0.0)
        _NoiseClampValue("Noise Clamp Value (x for min noise, y for max noise)" , Vector) = (0.5, 2.0, 0.0, 0.0)
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "ShaderModel"="4.5"}
        LOD 300
        
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}
            
            Stencil
            {
                Ref 0
                Comp Equal
                Pass Keep
            }
            HLSLPROGRAM
            //#pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5
            #pragma multi_compile _TILING_NONE _TILING_LOW _TILING_HIGH
            #pragma multi_compile _MACRO_VARIATION_OFF _MACRO_VARIATION_ON
            #pragma multi_compile _BIASED_UV_OFF _BIASED_UV_ON
            #pragma multi_compile _FRAME_CACHE_OFF _FRAME_CACHE_ON
            #pragma multi_compile _IDFORMAT_R8 _IDFORMAT_R8G8
            #pragma multi_compile _EDGE_OPTIMIZATION_OFF _EDGE_OPTIMIZATION_ON 
            #pragma multi_compile _BLEND_WITH_NOISE_OFF _BLEND_WITH_NOISE_ON 
            #pragma multi_compile _WORLDSPACE_UV_OFF _WORLDSPACE_UV_ON
            #define _ARC_RENDERING_OFF 1

            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            #pragma vertex TerrainPassVertex
            #pragma fragment TerrainPassFragment

            #include "./TerrainInput.hlsl"
            #include "./TerrainForwardPass.hlsl"
          
            ENDHLSL
        }
        
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ColorMask R
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
