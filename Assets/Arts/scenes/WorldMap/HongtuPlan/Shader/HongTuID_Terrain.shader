Shader "WorldMapTerrain/HongTuID_Terrain"
{
    Properties
    {
        _DiffuseArr ("Diffuse Array", 2DArray) = "" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _AlbedoPow ("Albedo Pow", Range(0, 10)) = 1.0

        [KeywordEnum(R8, R8G8)] _IDFormat("ID Map Format", Float) = 0
        [KeywordEnum(WEIGHT1, WEIGHT2, FINAL)] _LAYER("Layer", Float) = 0
        _IDMapTex ("ID Map Texture", 2D) = "black" {}
        _IDMapTex1 ("ID Map Weight2", 2D) = "black" {}
        _Rect ("World Rect", Vector) = (0.0, 0.0, 0.0, 0.0)
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
            #pragma multi_compile _LAYER_WEIGHT1 _LAYER_WEIGHT2 _LAYER_FINAL
            #pragma multi_compile _EDGE_OPTIMIZATION_OFF _EDGE_OPTIMIZATION_ON 
            #pragma multi_compile _BLEND_WITH_NOISE_OFF _BLEND_WITH_NOISE_ON 
            #pragma enable_d3d11_debug_symbols

            #pragma vertex TerrainPassVertex
            #pragma fragment TerrainPassFragment

            #include "./TerrainInput.hlsl"
            #include "./TerrainForwardPass.hlsl"
          
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
