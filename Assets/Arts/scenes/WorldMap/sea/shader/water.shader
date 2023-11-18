Shader "water"
{
    Properties
    {
        _BaseColor("Color", Color) = (1, 1, 1, 1)
        _DepthColor("Color2", Color) = (1, 1, 1, 1)
        _FormMap("FormMap", 2D) = "white" {}
        _WaveColor("_WaveColor",color)= (1, 1, 1, 1)
        _WaveIntensity("_WaveIntensity", float) = 1
        _FormIntensity("_FormIntensity", float) = 1
        _FormRange("_FormRange", float) = 1
        _NoiseIntensity("_NoiseIntensity",float)=0
        _ShoreMap("_ShoreMap", 2D) = "white" {}
        _CubeMap("_CubeMap", cube) = "white" {}
        _Blin("_blin",float)=0
        _SpecMap("_SpecMap", 2D) = "white" {}

        _BumpMap("_BumpMap", 2D) = "bump" {}

        _BumpMapST("_BumpMapST X normal Tilling",vector)=(0,0,0,1)
        _SpecMapST("_SpecMapST",vector)=(0,0,0,1)
        _wavescale("_wavescale",vector)=(0,0,0,1)
        _formScale("_formScale",vector)=(0,0,0,1)
        _LightDir("_LightDir",vector)=(0,0,0,1)
        _ReflectIntensity("_ReflectIntensity",float)=1


        _Fade("_Fade",float)=1
        _test("_test",float)=1
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" "ShaderModel"="2.0"
        }
        LOD 100

        Blend srcalpha oneminussrcalpha
        ZWrite off
        cull off

        Pass
        {
            Name "Unlit"
            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            CBUFFER_START(UnityPerMaterial)
            float4 _FormMap_ST;
            float4 _BumpMap_ST;
            half4 _BaseColor, _DepthColor;
            half _Cutoff;
            half _Surface;
            float3 _LightDir;


            half _test;
            half _Blin;
            float4 _BumpMapST, _wavescale, _SpecMapST, _formScale;
            half _Fade;
            half _NoiseIntensity;
            half _FormRange;
            float4 _WaveColor;
            float _WaveIntensity;
            float _FormIntensity;
            float _ReflectIntensity;
            CBUFFER_END

            #ifdef UNITY_DOTS_INSTANCING_ENABLED
                UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
                    UNITY_DOTS_INSTANCED_PROP(float4, _BaseColor)
                    UNITY_DOTS_INSTANCED_PROP(float , _Cutoff)
                    UNITY_DOTS_INSTANCED_PROP(float , _Surface)
                UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

                #define _BaseColor          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata__BaseColor)
                #define _Cutoff             UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Cutoff)
                #define _Surface            UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Surface)
            #endif

            TEXTURE2D(_FormMap);
            SAMPLER(sampler_FormMap);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);

            TEXTURE2D(_ShoreMap);
            SAMPLER(sampler_ShoreMap);

            TEXTURE2D(_SpecMap);
            SAMPLER(sampler_SpecMap);

            TEXTURE2D_X_FLOAT(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            TEXTURECUBE(_CubeMap);
            SAMPLER(sampler_CubeMap);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 uv : TEXCOORD0;
                float fogCoord : TEXCOORD1;
                float4 vertex : SV_POSITION;
                float3 normalWS : TEXCOORD3;
                float4 tangentWS : TEXCOORD4; // xyz: tangent, w: sign
                float3 viewDirWS : TEXCOORD5;
                float3 positionWS : TEXCOORD6;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertexInput.positionCS;
                output.uv.xy = TRANSFORM_TEX(input.uv, _FormMap);
                output.uv.zw = TRANSFORM_TEX(input.uv, _BumpMap);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                float3 tangent = TransformObjectToWorldDir(input.tangentOS.xyz);
                real sign = input.tangentOS.w * GetOddNegativeScale();
                output.tangentWS = float4(tangent, sign);
                output.viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);

                output.fogCoord = ComputeFogFactor(vertexInput.positionCS.z);
                output.positionWS = vertexInput.positionWS;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float4 pos = ComputeScreenPos(TransformWorldToHClip(input.positionWS.xyz));

                //return half4(input.uv.xy, 0.0, 1.0f);
                float2 screenPos = pos.xy / pos.w;
                //depth
                float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r; //采样深度
                float depthValue = LinearEyeDepth(depth, _ZBufferParams); //转换深度到0-1区间灰度值
                float z = pos.w;
                z = abs(depthValue - z);
                z *= _Fade;

                half2 uv = input.uv;
                half2 worldUV = input.positionWS.xz;
                //
                // float form = waterTex.g;
                // float wave = waterTex.r;


                float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, worldUV*_BumpMapST.x+_Time.x));
                float3 normalTS2 = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, worldUV*_BumpMapST.x-_Time.x));
                //return half4(normalTS.xyz, 1.0f);
                normalTS *= normalTS2;
                float sgn = input.tangentWS.w; // should be either +1 or -1
                float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                float3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
                //view
                float3 viewDir = SafeNormalize(input.viewDirWS);
                float3 lightDir = normalize(_LightDir); //normalize(_MainLightPosition);
                float3 halfview = SafeNormalize(viewDir + lightDir);
                // float3 color.rgb = MixFog(color.rgb, input.fogCoord);
                // alpha = OutputAlpha(alpha, _Surface);
                //
                //

                float edge = smoothstep(0, z, _FormRange);

//                //form
//                // float3 shore= SAMPLE_TEXTURE2D(_ShoreMap, sampler_ShoreMap, input.positionWS*_formScale.xy+normalWS.xy).rgb;
//                float3 formtex = SAMPLE_TEXTURE2D(_FormMap, sampler_FormMap, input.positionWS.xz*_formScale.xy+_Time.x+normalWS.xy).rgb;
//                float3 formtex2 = SAMPLE_TEXTURE2D(_FormMap, sampler_FormMap, input.positionWS.xz*_formScale.zw-_Time.x+normalWS.xz).bgr;
//                formtex += formtex2;

                //foam uv////////////////////////////////////////////////////////////////////////
                float2 foamworlduv = frac(input.positionWS.xz * _formScale.z) + normalWS.xz * 0.03;
                float2 foamuv;
                foamuv.x = _Time.y * 0.1;
                foamuv.x = frac(foamuv.x);
                foamuv.x += foamworlduv;
                foamuv.x *= PI * 2;
                foamuv.x = sin(foamuv.x) * 2;;
                foamuv.y = foamworlduv.y;
                foamuv = float2(foamuv) * 0.1 + foamworlduv * _formScale.w;
                float3 formtex = SAMPLE_TEXTURE2D(_FormMap, sampler_FormMap, foamuv).rgb;
                
                float form = dot(formtex, float3(1, 1, 1)) * (saturate(edge));
                //return half4(form.xxx, 1.0f);
                // form += form;


                float3 waveTex = SAMPLE_TEXTURE2D(_FormMap, sampler_FormMap, uv*_wavescale.xy+normalWS.xy*_NoiseIntensity+float2(0,_Time.x)).rgb;
                float3 waveTex2 = SAMPLE_TEXTURE2D(_FormMap, sampler_FormMap, uv*_wavescale.zw+normalWS.xy*_NoiseIntensity+float2(0,_Time.x)).rgb;
                waveTex += waveTex2;
                float3 wava = dot(waveTex, float3(.5, .5, .5));
                wava *= wava;
                //spec
                float3 specTex = SAMPLE_TEXTURE2D(_SpecMap, sampler_SpecMap, input.positionWS.xz*_SpecMapST.xy).xyz;
                float3 specTex2 = SAMPLE_TEXTURE2D(_SpecMap, sampler_SpecMap, input.positionWS.xz*_SpecMapST.zw+.2+_Time.x*_Blin).xyz;
                float spec = dot(specTex, specTex2) * 100;

                spec *= pow(max(0, dot(normalize(input.normalWS), halfview)), 500);
                float shallow_depth = saturate(z *_test);
                float4 final = lerp(_BaseColor, _DepthColor, clamp(0, 1, shallow_depth));
                final.rgb += (wava * _WaveIntensity + form * _FormIntensity) * _WaveColor;
                final += spec;

                
                //reflect
                half3 reflectVector = reflect(-viewDir, normalWS);
                half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, reflectVector,_ReflectIntensity)*_ReflectIntensity;
                final.rgb+=encodedIrradiance.rgb;   
                //fog
                final.rgb=MixFog(final.rgb,input.fogCoord);
                final.a = z;
                final.a = pow(final.aaa, _test);
                return saturate(final); //+ alpha + _BaseColor; // _BaseColor + alpha;
            }
            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            Cull Off

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaUnlit

            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitMetaPass.hlsl"
            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"

}