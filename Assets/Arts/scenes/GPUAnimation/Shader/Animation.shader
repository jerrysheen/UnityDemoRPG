Shader "Faster/Character/AnimationInstance"
{
    Properties
    {
        [Header(Color)]
        [Space(10)]
        _MainColor("MainColor",color) = (1,1,1,1)
        _FlagColor("FlagColor",color) = (1,1,1,1)
        _DissolveColor("DissolveColor",color) = (1,1,1,1)
        //        _Hue("Hue", Range(0,359)) = 0
        //        _Saturation("Saturation", Range(0,3.0)) = 1.0
        //        _Luminance("Luminance", Range(0,3.0)) = 1.0

        _Edge("EdgeWide",range(0,1)) = 0.5
        _Dissolve("Dissolve",range(-1,1)) = -1
        [Space(10)]
        [Header(Map)]
        [Space(10)]
        [HDR] _EmissionColor("Color", Color) = (0,0,0)
        _EmissionMap("Emission", 2D) = "white" {}
        _MaskTex("ColorMask",2D) = "white"{}
        _MainTex("MainTex",2D) = "white"{}
        _SkinningTex("SkinningTex",2D) = "black"{}
        [HideInInspector]_CurFramIndex("_CurFramIndex", float) = 0
        [HideInInspector]_PreFramIndex("_PreFramIndex", float) = 0
        [HideInInspector]_TransProgress("_TransProgress", float) = 0
        [HideInInspector]_SkinningTexSize("_SkinningTexSize", Vector) = (128.0, 128.0, 0.0078125, 0.0078125)
        [HideInInspector]_UpwardShift("_UpwardShift", float) = 0
        [HideInInspector] _HorizontalPlane("_HorizontalPlane", float) = 0.01
    }
    
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100

        Pass
        {
            Name "ForwardBase"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            Cull Off

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex AnimationVert
            #pragma fragment AnimationFrag
            #pragma multi_compile_instancing
            #define CUSTOM_ANIMATION_INPUT
            #pragma enable_d3d11_debug_symbols
            #include "Assets/Shaders/Include/Math/AnimationInput.hlsl"
            // #include "Assets/Shaders/Include/Math/AnimationDQ.hlsl"
            // #include "Assets/Shaders/Include/HSV.hlsl"
            #include "Assets/Shaders/Include/AnimationInstancing/AnimationInstancing.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "PlannarShadow"
            Tags
            {
                "LightMode"="PlannarShadow"
            }
            Stencil
            {
                Ref 0
                Comp equal
                Pass incrWrap
                Fail keep
                ZFail keep
            }
            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite off
            Offset -1 , 0
            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex AnimationPlannarVert
            #pragma fragment PlannarShadowFrag
            #pragma multi_compile_instancing
            #define CUSTOM_ANIMATION_INPUT

            #include "Assets/Shaders/Include/Math/AnimationInput.hlsl"
            #include "Assets/Shaders/Include/Shadow/PlannarShadow.hlsl"
            ENDHLSL
        }
        //        Pass
        //        {
        //            Name "ShadowCaster"
        //            Tags
        //            {
        //                "LightMode" = "ShadowCaster"
        //            }
        //        
        //            ZWrite On
        //            ZTest LEqual
        //            ColorMask 0
        //            Cull[_Cull]
        //        
        //            HLSLPROGRAM
        //            #pragma only_renderers gles gles3 glcore d3d11
        //           #pragma target 3.0
        //        
        //            //--------------------------------------
        //            // GPU Instancing
        //            #pragma multi_compile_instancing
        //        
        //            // -------------------------------------
        //            // Material Keywords
        //            #pragma shader_feature_local_fragment _ALPHATEST_ON
        //            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        //        
        //            #pragma vertex AShadowPassVertex
        //            #pragma fragment ShadowPassFragment
        //        
        //            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
        //            #include "Assets/Shaders/Include/AnimationInstancing/AnimationShadow.hlsl"
        //            ENDHLSL
        //        }

    }

}