Shader "sea"
{
    Properties
    {
        _BaseColor("_BaseColor", Color) = (1, 1, 1, 1)
        _ShoalColor("shoalColor", Color) = (1, 1, 1, 1)
        _DepthColor("dpethColor", Color) = (1, 1, 1, 1)
        _DepthTrans("_DepthTrans",float)=1
        _CubeMap("_CubeMap", cube) = "white" {}
        _FormMap("FormMap", 2D) = "white" {}
        _ShoreMap("_ShoreMap", 2D) = "white" {}
        _SpecMap("_SpecMap", 2D) = "white" {}
        _BumpMap("_BumpMap", 2D) = "bump" {}
        _BumpScale("_BumpScale", float) = 1
        _NoiseMap("_NoiseMap", 2D) = "white" {}
        _WaveColor("_WaveColor",color)= (1, 1, 1, 1)
        _WaveIntensity("_WaveIntensity", float) = 1
        _FormIntensity("_FormIntensity", float) = 1
        _FormRange("_FormRange", float) = 1
        _NoiseIntensity("_NoiseIntensity",float)=0





        _BumpMapST("_bumpuvscale",vector)=(0,0,0,1)
        _SpecMapST("_SpecMapST",vector)=(0,0,0,1)
        _wavescale("_wavescale",vector)=(0,0,0,1)
        _formScale("_formScale",vector)=(0,0,0,1)
        _LightDir("_LightDir",vector)=(0,0,0,1)
        _ReflectIntensity("_ReflectIntensity",float)=1

        _Blin("_blin",float)=1
        _Fade("_Fade",float)=1
        _AlphaFade("_AlphaFade",float)=1
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
            float4 _NoiseMap_ST;
            half4 _BaseColor, _DepthColor, _ShoalColor;
            half _Cutoff;
            half _Surface;
            float4 _LightDir;


            half _test;
            half _Blin;
            float4 _BumpMapST, _wavescale, _SpecMapST, _formScale;
            half _Fade, _AlphaFade;
            half _NoiseIntensity;
            half _FormRange;
            float4 _WaveColor;
            float _WaveIntensity;
            float _FormIntensity;
            float _ReflectIntensity;
            float _DepthTrans;
            float _BumpScale;
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

            TEXTURE2D(_NoiseMap);
            SAMPLER(sampler_NoiseMap);

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
                float3 uv2 : TEXCOORD7;
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

                output.uv2.xy = TRANSFORM_TEX(input.uv, _NoiseMap);
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

                float2 screenPos = pos.xy / pos.w;
                //depth
                float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r; //采样深度
                float depthValue = LinearEyeDepth(depth, _ZBufferParams); //转换深度到0-1区间灰度值
                float z = pos.w;
                depth = abs(depthValue - z);
                depth *= 1.2;
                half2 worldUV = input.positionWS.xz;
                //

                //normal noise
                float3 normalTS = UnpackNormal(
                    SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, worldUV*_BumpMapST+_Time.x));
                float3 normalTS2 = UnpackNormal(
                    SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, worldUV*_BumpMapST-_Time.x));
                normalTS += normalTS2;
                normalTS.xy *= _BumpScale;
                normalTS = normalize(normalTS);
                float sgn = input.tangentWS.w; // should be either +1 or -1
                float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                float3 normalWS = TransformTangentToWorld(
                    normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));


                //noise
                float4 noiseTex = SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, input.uv2.xy);

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


                ////////////////////////////////////////////////////////////////////////

                //wavedepth uv////////////////////////////////////////////////////////////////////////
                float2 depuv;
                depuv.x = frac((depth / 3 + (noiseTex.z * 2) * noiseTex.g) + _Time.y * 0.2);
                depuv.y = 0.5;
                float4 wavetex = SAMPLE_TEXTURE2D(_ShoreMap, sampler_ShoreMap, depuv+noiseTex.b);
                //  return float4(wavetex.rrr, 1);
                float foam = dot(wavetex.xxy, formtex.yyz) * (1 - (depth / 20) - 0.6).xxx;
                foam *= saturate(depth) * noiseTex.g;
                foam *= 5;
                float shoreform = dot(formtex.xxy, float3(1, 1, 1)) * Pow4(saturate(1 - depth / 5));

                // foam *= noiseTex.b;
                foam = max(foam, shoreform) * 0.65;


                // foam*=0.6;


                // //view
                float3 viewDir = SafeNormalize(input.viewDirWS);
                float3 lightDir = normalize(_LightDir); // normalize(_MainLightPosition);
                float3 halfview = SafeNormalize(viewDir + lightDir);


                float NoL = saturate(1 - dot(normalWS, lightDir));
                float NoH = saturate(dot(normalWS, halfview));
                float NoV = saturate(dot(viewDir, normalWS));
                // //spec
                float3 specTex = SAMPLE_TEXTURE2D(_SpecMap, sampler_SpecMap, frac(input.positionWS.xz*_SpecMapST.xy)).
                    xyz;
                float3 specTex2 = SAMPLE_TEXTURE2D(_SpecMap, sampler_SpecMap,
                                                   frac(input.positionWS.xz*_SpecMapST.zw)+float2(.2,.5)+_Time.x*_Blin).xyz;
                float spec = smoothstep(0.0,0.02,dot(specTex, specTex2)) ;
                
                float speculer = pow(max(0, dot(normalize(input.normalWS), halfview)), 36);
                spec *= smoothstep(0,1,speculer);//1-abs((1-(speculer*2))));

                float4 final = lerp(_DepthColor, _ShoalColor, clamp(0, 1, exp(depth * _DepthTrans * NoL)));
                final.rgb *= _BaseColor;
                final.rgb = final.rgb + pow(NoH, 36) * .3;

                final.rgb += (speculer*_LightDir.w)*_BaseColor+ spec*5;
                //reflect
                half3 reflectVector = reflect(-viewDir, normalWS);
                half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector,
                                                                 _ReflectIntensity) * _ReflectIntensity;
                final.rgb += encodedIrradiance.rgb;
                final.rgb += foam;
                
                final.a = saturate(1 - NoV + 0.8) * saturate(1 - exp(depth * _Fade))*_BaseColor.a;
                final.a += foam;
                final.a *= saturate(depth * _AlphaFade);
                final.a += spec;
                // //fog
                final.rgb = MixFog(final.rgb, input.fogCoord);
                return (final); //+ alpha + _BaseColor; // _BaseColor + alpha;
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