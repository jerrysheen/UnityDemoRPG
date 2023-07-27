Shader "Catmull/MainCityTerrain"
{

    Properties
    {
        //_BaseMap ("Texture", 2D) = "white" {}
        _GlobalNormal ("_GlobalNormal", 2D) = "white" {}
        _GlobalNormalBlendRate ("_GlobalNormalBlendRate", Range(0.0, 1.0)) = 0.0
        _WeightPack0 ("_WeightPack0", 2D) = "white" {}
        _WeightPack1 ("_WeightPack1", 2D) = "white" {}
        
        _HeightPack0 ("_HeightPack0", 2D) = "white" {}
        _HeightPack1 ("_HeightPack1", 2D) = "white" {}
        _AlbedoPack0 ("_AlbedoPack0", 2D) = "white" {}
        _AlbedoPack1 ("_AlbedoPack1", 2D) = "white" {}
        _AlbedoPack2 ("_AlbedoPack2", 2D) = "white" {}
        _NormalPack0 ("_NormalPack0", 2D) = "white" {}
        _NormalScale00 ("_NormalScale00", Range(0.0, 2.0)) = 1.0
        _NormalPack1 ("_NormalPack1", 2D) = "white" {}
        _NormalScale01 ("_NormalScale01", Range(0.0, 2.0)) = 1.0
        _NormalPack2 ("_NormalPack2", 2D) = "white" {}
        _NormalScale02 ("_NormalScale02", Range(0.0, 2.0)) = 1.0
        
        
        _LODScale ("_LODScale", Range(0.0, 3.0)) = 3.0

        [Toggle] _ENABLE_SIMPLE_TERRAIN_SHADER ("Enable Simple Terrain Shader", Float) = 0

       // _LODValue00 ("金属度", Range(0.0, 3.0)) = 1.0
       // _LODValue01 ("光滑度", Range(0.0, 1.15)) = 1.0
       // _offSetY ("_offSetY", Range(0.0, 0.1)) = 1.0
       // _offSetX ("_offSetX", Range(0.95, 1.05)) = 1.0
        
       // _diffuseUVoffSetX ("_diffuseUVoffSetX", Range(0.0, 1.0)) = 1.0
       // _diffuseUVoffSetY ("_diffuseUVoffSetY", Range(0.0, 1.0)) = 1.0
      //  _ChangeSeasonPack0 ("_ChangeSeasonPack0", Range(0.0, 1.0)) = 1.0
       // _Color ("Color", Color) = (1,1,1,1)
       // _PosInfo ("Pos: Center(x, y) . ratio(z) grid num: (w)", Vector) = (0.5,0.5,0.9,10.0)
       // _GridVSPixel("Grid num(x), Pixel num(y)", Vector) = (10.0,16.0, 0.0, 0.0)
    }
    SubShader
    {
            
        Stencil
        {
            Ref 0
            Comp Equal
            Pass Keep
        }
      
        LOD 300
        Tags
		{
	        "LightMode" = "UniversalForward" 
	        "Queue" = "Geometry"
	        "RenderPipeline" = "UniversalPipeline"
		}
        
        
        // ------------------------------------------------------------------
        //  Forward pass. Shades all light in a single pass. GI + emission + Fog
        Pass
        {
            // Lightmode matches the ShaderPassName set in UniversalRenderPipeline.cs. SRPDefaultUnlit and passes with
            // no LightMode tag are also rendered by Universal Render Pipeline

            HLSLPROGRAM
            #define _NORMALMAP
            #pragma vertex MainCityTerrainPassVertex
            #pragma fragment MainCityTerrainPassFragment

            #define _METALLICSPECGLOSSMAP 1
            #define _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A 1

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_LAYERS
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _CLUSTERED_RENDERING

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ DEBUG_DISPLAY
            #pragma multi_compile_instancing
            #pragma instancing_options norenderinglayer assumeuniformscaling nomatrices nolightprobe nolightmap

            #pragma shader_feature_local_fragment _TERRAIN_BLEND_HEIGHT
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _MASKMAP
            // Sample normal in pixel shader when doing instancing
            #pragma shader_feature_local _TERRAIN_INSTANCED_PERPIXEL_NORMAL

            #pragma multi_compile  _ _ENABLE_SIMPLE_TERRAIN_SHADER

            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

            #include "MainCityTerrainLitInput.hlsl"
            #include "MainCityTerrainLitForward.hlsl"

          
            
            ENDHLSL
        }
        
        
        Pass
        {
//                Name "ShadowCaster"
//                Tags{"LightMode" = "ShadowCaster"}
//
//                ZWrite On
//                ColorMask 0
//
//                HLSLPROGRAM
//                #pragma target 2.0
//
//                #pragma vertex ShadowPassVertex
//                #pragma fragment ShadowPassFragment
//
//                #pragma multi_compile_instancing
//                #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap
//
//                // -------------------------------------
//                // Universal Pipeline keywords
//
//                // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
//                #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
//
//                #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
//                #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitPasses.hlsl"
//                ENDHLSL
        }

        Pass
        {
            Name "GBuffer"
            Tags{"LightMode" = "UniversalGBuffer"}

            HLSLPROGRAM
            #pragma exclude_renderers gles
            #pragma target 3.0
            #pragma vertex SplatmapVert
            #pragma fragment SplatmapFragment

            #define _METALLICSPECGLOSSMAP 1
            #define _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A 1

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            //#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            //#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_LAYERS

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #pragma multi_compile_fragment _ _RENDER_PASS_ENABLED

            //#pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma instancing_options norenderinglayer assumeuniformscaling nomatrices nolightprobe nolightmap

            #pragma shader_feature_local _TERRAIN_BLEND_HEIGHT
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _MASKMAP
            // Sample normal in pixel shader when doing instancing
            #pragma shader_feature_local _TERRAIN_INSTANCED_PERPIXEL_NORMAL
            #define TERRAIN_GBUFFER 1

            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitPasses.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitPasses.hlsl"
            ENDHLSL
        }

        // This pass is used when drawing to a _CameraNormalsTexture texture
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex DepthNormalOnlyVertex
            #pragma fragment DepthNormalOnlyFragment

            #pragma shader_feature_local _NORMALMAP
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitDepthNormalsPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "SceneSelectionPass"
            Tags { "LightMode" = "SceneSelectionPass" }

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #define SCENESELECTIONPASS
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitPasses.hlsl"
            ENDHLSL
        }

        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            #pragma vertex TerrainVertexMeta
            #pragma fragment TerrainFragmentMeta

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap
            #pragma shader_feature EDITOR_VISUALIZATION
            #define _METALLICSPECGLOSSMAP 1
            #define _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A 1

            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitMetaPass.hlsl"

            ENDHLSL
        }
    }
    FallBack"Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor"MainCityTerrainGUI"
}
