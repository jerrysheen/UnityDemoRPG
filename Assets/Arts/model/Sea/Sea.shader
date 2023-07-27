//Shader "MainCity/Sea"
//{
//    Properties
//    {
//        _BaseColor("Color", Color) = (1, 1, 1, 1)
//        _DepthColor("Color2", Color) = (1, 1, 1, 1)
//        _FormMap("FormMap", 2D) = "white" {}
//        _WaveColor("_WaveColor",color)= (1, 1, 1, 1)
//        _WaveIntensity("_WaveIntensity", float) = 1
//        _FormIntensity("_FormIntensity", float) = 1
//        _FormRange("_FormRange", float) = 1
//        _NoiseIntensity("_NoiseIntensity",float)=0
//        
//        _NoiseIntensity("_NoiseIntensity",float)=0
//        [Space(10)] 
//        [Header(Wave related)]
//        [Space(10)] 
//        _WPO_MasterSpeed("_WPO_MasterSpeed", float) = 1
//        _WPO_WaveScale("_WPO_WaveScale",vector) = (1, 1, 1, 1)
//        _WPO_WaveIntensity("_WPO_WaveIntensity",vector) = (1, 1, 1, 1)
//        _WPO_WaveSpeed("_WPO_WaveSpeed",vector) = (1, 1, 1, 1)
//        
//        
//        _NoiseMap("_NoiseMap", 2D) = "white" {}
//        _WaveScale("_WaveScale",vector) = (1, 1, 1, 1)
//        _WaveSpeed("_WaveSpeed",vector) = (1, 1, 1, 1)
//        _Intensity("_Intensity",vector) = (1, 1, 1, 1)
//        
//        
//        
//        _ShoreWaveSpeed("_ShoreWaveSpeed",float)=0
//        _ShoreWaveRampSize("_ShoreWaveRampSize",float)=0
//        _ShoreMask("_ShoreMask", 2D) = "white" {}
//        _ShoreWaveRamp("_ShoreWaveRamap", 2D) = "white" {}
//        _ShoreWaveRamp2("_ShoreWaveRamap2", 2D) = "white" {}
//        _ShoreWaveNoiseClip("_ShoreWaveNoiseClip",float)= 0.3
//        [Space(10)] 
//        [Header(Close Shore)]
//        [Space(10)] 
//        _ShoreAreaOffset("_ShoreAreaOffset",float)= 0.3
//        _ShoreDepthRange("_ShoreDepthRange",float)= 0.3
//        _EdgeOpacity("_EdgeOpacity",float)= 0.3
//
//        _Blin("_blin",float)=0
//        _SpecMap("_SpecMap", 2D) = "white" {}
//
//        _BumpMap("_BumpMap", 2D) = "bump" {}
//        _BumpMapST("_bumpuvscale",vector)=(0,0,0,1)
//        _SpecMapST("_SpecMapST",vector)=(0,0,0,1)
//        _wavescale("_wavescale",vector)=(0,0,0,1)
//        _formScale("_formScale",vector)=(0,0,0,1)
//        _LightDir("_LightDir",vector)=(0,0,0,1)
//        _ReflectIntensity("_ReflectIntensity",float)=1
//
//
//        _Fade("_Fade",float)=1
//        _test("_test",float)=1
//    }
//
//    SubShader
//    {
//        Tags
//        {
//            "Queue"="Transparent" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" "ShaderModel"="2.0"
//        }
//        LOD 100
//
//        Blend srcalpha oneminussrcalpha
//        ZWrite off
//        cull off
//
//        Pass
//        {
//            Name "Unlit"
//            HLSLPROGRAM
//            #pragma only_renderers gles gles3 glcore d3d11
//            #pragma target 2.0
//
//            #pragma vertex vert
//            #pragma fragment frag
//            #pragma shader_feature_local_fragment _ALPHATEST_ON
//            #pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
//
//            // -------------------------------------
//            // Unity defined keywords
//            #pragma multi_compile_fog
//            #pragma multi_compile_instancing
//
//            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//            CBUFFER_START(UnityPerMaterial)
//
//            float _WPO_MasterSpeed;
//            float4 _WPO_WaveScale;
//            float4 _WPO_WaveIntensity;
//            float4 _WPO_WaveSpeed;
//            
//            float4 _FormMap_ST;
//            float4 _BumpMap_ST;
//            float4 _NoiseMap_ST;
//            half4 _BaseColor, _DepthColor;
//            half _Cutoff;
//            half _Surface;
//            float3 _LightDir;
//            float3 _WaveScale;
//            float3 _WaveSpeed;
//            float3 _Intensity;
//            half _test;
//            half _Blin;
//            float4 _BumpMapST, _wavescale, _SpecMapST, _formScale;
//            half _Fade;
//            half _NoiseIntensity;
//            half _FormRange;
//            float4 _WaveColor;
//            float _WaveIntensity;
//            float _ShoreAreaOffset;
//            float _ShoreWaveNoiseClip;
//            float _ShoreDepthRange;
//            float _EdgeOpacity;
//            float _FormIntensity;
//            float _ReflectIntensity;
//            float _ShoreWaveSpeed;
//            float _ShoreWaveRampSize;
//            CBUFFER_END
//
//            #ifdef UNITY_DOTS_INSTANCING_ENABLED
//                UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
//                    UNITY_DOTS_INSTANCED_PROP(float4, _BaseColor)
//                    UNITY_DOTS_INSTANCED_PROP(float , _Cutoff)
//                    UNITY_DOTS_INSTANCED_PROP(float , _Surface)
//                UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
//
//                #define _BaseColor          UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float4 , Metadata__BaseColor)
//                #define _Cutoff             UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Cutoff)
//                #define _Surface            UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata__Surface)
//            #endif
//
//
//            TEXTURE2D(_FormMap);
//            SAMPLER(sampler_FormMap);
//            TEXTURE2D(_BumpMap);
//            SAMPLER(sampler_BumpMap);
//
//            TEXTURE2D(_NoiseMap);
//            SAMPLER(sampler_NoiseMap);
//            
//            TEXTURE2D(_ShoreMask);
//            SAMPLER(sampler_ShoreMask);
//
//            TEXTURE2D(_SpecMap);
//            SAMPLER(sampler_SpecMap);
//            
//            TEXTURE2D(_ShoreWaveRamp);
//            SAMPLER(sampler_ShoreWaveRamp);
//            
//            TEXTURE2D(_ShoreWaveRamp2);
//            SAMPLER(sampler_ShoreWaveRamp2);
//
//            TEXTURE2D_X_FLOAT(_CameraDepthTexture);
//            SAMPLER(sampler_CameraDepthTexture);
//
//            struct Attributes
//            {
//                float4 positionOS : POSITION;
//                float2 uv : TEXCOORD0;
//                float3 normalOS : NORMAL;
//                float4 tangentOS : TANGENT;
//                UNITY_VERTEX_INPUT_INSTANCE_ID
//            };
//
//            struct Varyings
//            {
//                float4 uv : TEXCOORD0;
//                float fogCoord : TEXCOORD1;
//                float4 vertex : SV_POSITION;
//                float3 normalWS : TEXCOORD3;
//                float4 tangentWS : TEXCOORD4; // xyz: tangent, w: sign
//                float3 viewDirWS : TEXCOORD5;
//                float3 positionWS : TEXCOORD6;
//                float3 uvNoise : TEXCOORD7;
//                float4 WaveWorld : TEXCOORD8;
//                UNITY_VERTEX_INPUT_INSTANCE_ID
//                UNITY_VERTEX_OUTPUT_STEREO
//            };
//
//            Varyings vert(Attributes input)
//            {
//                Varyings output = (Varyings)0;
//
//                UNITY_SETUP_INSTANCE_ID(input);
//                UNITY_TRANSFER_INSTANCE_ID(input, output);
//                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
//
//                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
//                output.vertex = vertexInput.positionCS;
//                output.uv.xy = TRANSFORM_TEX(input.uv, _FormMap);
//                output.uv.zw = TRANSFORM_TEX(input.uv, _BumpMap);
//                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
//                float3 tangent = TransformObjectToWorldDir(input.tangentOS.xyz);
//                real sign = input.tangentOS.w * GetOddNegativeScale();
//                output.tangentWS = float4(tangent, sign);
//                output.viewDirWS = GetWorldSpaceViewDir(vertexInput.positionWS);
//
//                output.fogCoord = ComputeFogFactor(vertexInput.positionCS.z);
//                output.positionWS = vertexInput.positionWS;
//                float3 waveoffset;
//                waveoffset.xyz = output.positionWS.xyz/_WaveScale.xyz;
//                waveoffset.xyz = -_Time.y * _WaveSpeed.xyz + waveoffset.xyz;
//                waveoffset.xyz *= 2 * 3.1415926;
//                waveoffset.xyz = sin(waveoffset.xyz);
//                waveoffset.xyz *= _Intensity.xyz;
//                output.positionWS += waveoffset.xyz;
//                output.vertex = TransformWorldToHClip(output.positionWS);
//                output.uvNoise.xy = TRANSFORM_TEX(input.uv, _NoiseMap);
//
//                float3 u_xlat0 = 0.0f;
//                float3 waveIntensity;
//                //u_xlat1.xyz = _WPO_WaveIntensity.www * _WPO_WaveIntensity.xyz;
//                waveIntensity.xyz = _WPO_WaveIntensity.www * _WPO_WaveIntensity.xyz;
//                //u_xlat27 = _Time.y * _WPO_MasterSpeed;
//                float masterSpeed = _Time.y * _WPO_MasterSpeed;
//
//                float posCombine = output.positionWS.x + output.positionWS.y + output.positionWS.z + 1.0;
//                //u_xlat2 = in_POSITION0.yyyy * unity_Builtins0Array[u_xlati28 / 8].hlslcc_mtx4x4unity_ObjectToWorldArray[1];
//                // u_xlat2 = unity_Builtins0Array[u_xlati28 / 8].hlslcc_mtx4x4unity_ObjectToWorldArray[0] * in_POSITION0.xxxx + u_xlat2;
//                // u_xlat2 = unity_Builtins0Array[u_xlati28 / 8].hlslcc_mtx4x4unity_ObjectToWorldArray[2] * in_POSITION0.zzzz + u_xlat2;
//                // u_xlat2 = unity_Builtins0Array[u_xlati28 / 8].hlslcc_mtx4x4unity_ObjectToWorldArray[3] * in_POSITION0.wwww + u_xlat2;
//                // u_xlat3.xyz = u_xlat2.xxz / _WPO_WaveScale.xyz;
//                
//                //u_xlat3.xyz = output.positionWS.xxz / _WPO_WaveScale.xyz - masterSpeed * _WPO_WaveSpeed.xyz ;
//                float3 waveSpeed = 2 *  PI * posCombine.xxx / _WPO_WaveScale.xyz - masterSpeed * _WPO_WaveSpeed.xyz ;
//                //u_xlat3.xyz = sin(u_xlat3.xyz);
//                waveSpeed = sin(waveSpeed);
//
//                u_xlat0.y = 2 * dot(waveIntensity.xyz, waveSpeed.xyz);
//
//                u_xlat0.xyz = u_xlat0.xyz + output.positionWS.xyz;
//
//                output.WaveWorld.w = 0.0;
//                output.WaveWorld.xyz = u_xlat0.xyz;
//
//
//                    //u_xlat0.xyz = u_xlat2.xzx / vec3(_VertexWaveTiling, _VertexShoreTiling, _VertexShoreTiling);
//                u_xlat0.xyz = posCombine.xzx / float3(_VertexWaveTiling, _VertexShoreTiling, _VertexShoreTiling);
//    u_xlat9.x = dot(u_xlat0.yz, _WaveDirection.zw);
//    u_xlat0.x = u_xlat0.x + _Time.y;
//    u_xlat0.x = u_xlat0.x * _VertexWaveSpeed;
//    u_xlat9.x = u_xlat9.x + (-_Time.y);
//    u_xlat0.y = u_xlat9.x * _VertexShoreSpeed;
//    u_xlat0.xy = u_xlat0.xy * vec2(63.0, 63.0);
//    // u_xlat18 = floor(u_xlat0.y);
//    // u_xlat9.x = fract(u_xlat0.y);
//    // u_xlat27 = u_xlat18 + 1.0;
//    // u_xlat3.w = u_xlat18 * 0.015625 + 0.0078125;
//    // u_xlat3.y = u_xlat27 * 0.015625 + 0.0078125;
//    // u_xlat3.xz = in_TEXCOORD1.xx;
//    // u_xlat5.xyz = textureLod(_ShoreNormal, u_xlat3.xy, 0.0).xyz;
//    // u_xlat3.xyz = textureLod(_ShoreNormal, u_xlat3.zw, 0.0).xyz;
//    // u_xlat16_7.xyz = (-u_xlat3.xyz) + u_xlat5.xyz;
//    // u_xlat16_7.xyz = u_xlat9.xxx * u_xlat16_7.xyz + u_xlat3.xyz;
//    // u_xlat16_7.xyz = u_xlat16_7.xyz * vec3(2.0, 2.0, 2.0) + vec3(-1.0, -1.0, -1.0);
//    // u_xlat9.xyz = u_xlat1.yyy * u_xlat16_7.xyz;
//    // u_xlat9.xyz = u_xlat9.xyz * vec3(vec3(_VertexShoreIntensity, _VertexShoreIntensity, _VertexShoreIntensity));
//    float u_xlat10 = floor(u_xlat0.x);
//    u_xlat0.x = frac(u_xlat0.x);
//    float u_xlat19 = u_xlat10.x + 1.0;
//    u_xlat3.w = u_xlat10.x * 0.015625 + 0.0078125;
//    u_xlat3.y = u_xlat19 * 0.015625 + 0.0078125;
//    u_xlat3.xz = in_TEXCOORD1.xx;
//    u_xlat10.xyz = textureLod(_WaveNormal, u_xlat3.xy, 0.0).xyz;
//    u_xlat3.xyz = textureLod(_WaveNormal, u_xlat3.zw, 0.0).xyz;
//    u_xlat16_7.xyz = u_xlat10.xyz + (-u_xlat3.xyz);
//    u_xlat16_7.xyz = u_xlat0.xxx * u_xlat16_7.xyz + u_xlat3.xyz;
//    u_xlat16_7.xyz = u_xlat16_7.xyz * vec3(2.0, 2.0, 2.0) + vec3(-1.0, -1.0, -1.0);
//    u_xlat1.xyz = u_xlat1.xxx * u_xlat16_7.xyz;
//    vs_TEXCOORD10.xyz = u_xlat1.xyz * vec3(vec3(_VertexWaveIntensity, _VertexWaveIntensity, _VertexWaveIntensity)) + u_xlat9.xyz;
//    u_xlat0.x = u_xlat2.x / t5_control.z;
//    u_xlat9.xy = u_xlat2.zx * vec2(1.0, -1.0);
//    u_xlat9.xy = u_xlat9.xy / vec2(vec2(_SpecularTiling, _SpecularTiling));
//    u_xlat0.x = _Time.y * t5_control.y + u_xlat0.x;
//    u_xlat0.x = u_xlat0.x * t5_control.w;
//    u_xlat0.x = sin(u_xlat0.x);
//    vs_TEXCOORD10.w = u_xlat0.x * t5_control.x;
//                return output;
//            }
//
//            half4 frag(Varyings input) : SV_Target
//            {
//                UNITY_SETUP_INSTANCE_ID(input);
//                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
//
//                float2 u_xlat20 = (-input.WaveWorld.zx) / 20.0;
//                u_xlat1.x = _Time.y;
//                u_xlat1.y = vs_TEXCOORD10.w;
//                u_xlat20.xy = t5_uv1.xy * u_xlat1.xy + u_xlat20.xy;
//                u_xlat16_2.xyz = texture(t5, u_xlat20.xy).xyz;
//                float timey = _Time.y * 0.100000001;
//                timey = frac(timey);
//                timey= input.WaveWorld.x * 0.0166666675 + timey;
//                    return half4(input.WaveWorld.xyz, 1.0f);
//                float2 uv = input.uv;
//                float2 FlowUV = input.uv.zw;
//                half2 worldUV = input.positionWS.xz;
//                //
//                // float form = waterTex.g;
//                // float wave = waterTex.r;
//                float sinx = sin(_Time.y);
//
//                float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, (FlowUV + 0.0005*_Time.y)));
//                float3 normalTS2 = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap,(FlowUV - 0.0005*_Time.y)));
//                //normalTS *= normalTS2;
//                normalTS = normalTS;
//                float sgn = input.tangentWS.w; // should be either +1 or -1
//                float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
//                float3 normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
//                //view
//                float3 viewDir = SafeNormalize(input.viewDirWS);
//                float3 lightDir = normalize(_LightDir); //normalize(_MainLightPosition);
//                float3 halfview = SafeNormalize(viewDir + lightDir);
//               
//                //spec
//                float3 specTex = SAMPLE_TEXTURE2D(_SpecMap, sampler_SpecMap, FlowUV).xyz;
//                float3 specTex2 = SAMPLE_TEXTURE2D(_SpecMap, sampler_SpecMap, FlowUV).xyz;
//                float spec = dot(specTex, specTex2) * 100;
//
//                spec *= pow(max(0, dot(normalize(normalWS), halfview)), 300.0);
//                //float4 final = lerp(_BaseColor, _DepthColor, clamp(0, 1, z));
//                //final.rgb += (wava * _WaveIntensity + form * _FormIntensity) * _WaveColor;
//                //final += spec;
//                return half4(spec.xxx, 1.0f);
//                //float edge = smoothstep(0, z, _FormRange);
//         
//                // foam
//                float4 shoremask= SAMPLE_TEXTURE2D(_ShoreMask, sampler_ShoreMask, input.uv.xy);
//                float depthmask = 1 - shoremask.z;
//                float2 wave1UV;
//                wave1UV.x = depthmask +_Time.y * 0.0500000007;
//                wave1UV.x /= _ShoreWaveRampSize;
//                if(wave1UV.x >= 0)
//                {
//                    wave1UV.x = frac(abs(wave1UV.x));
//                }
//                else
//                {
//                    wave1UV.x = -frac(abs(wave1UV.x));
//                }
//                wave1UV.y = 0.5;
//                float3 wave1 = SAMPLE_TEXTURE2D(_ShoreWaveRamp,sampler_ShoreWaveRamp,wave1UV).xyw;
//                //wave1 = SAMPLE_TEXTURE2D(_ShoreWaveRamp,sampler_ShoreWaveRamp, half2(0.7,0.0f));
//                float3 foamtex = SAMPLE_TEXTURE2D(_FormMap,sampler_FormMap,input.uv.xy * 90.0f);
//                
//                float wave1foam = dot(wave1.xxy,foamtex.yyz);
//                // foam step
//               // return half4(wave1UV.xxx, 1.0);
//
//                
//                float4 col = float4(wave1foam ,wave1foam ,wave1foam ,1.0);
//                //return col;
//
//                float4 Noise= SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, input.uvNoise.yx);
//
//                float u_xlat20 = saturate(Noise.z + exp2(log2(shoremask.z) * 20.0) + (-_ShoreWaveNoiseClip));
//                
//
//                 float  u_xlat30 = (-_ShoreWaveNoiseClip) + 1.0;
//                    u_xlat20 = u_xlat20 / u_xlat30;
//                    u_xlat30 = saturate(u_xlat20.x);
//               // return half4(wave1foam.xxx, 1.0f);
//
//                    u_xlat30 = u_xlat30 * wave1foam;
//                u_xlat30 *= shoremask.w;
//                 //    SV_Target0.x = u_xlat30;
//	                // SV_Target0.w = 1.0;
//                 //    return;                
//                //return half4(u_xlat30.xxx, 1.0f);
//
//                // close shore foam:
//
//                // float4 pos = ComputeScreenPos(TransformWorldToHClip(input.positionWS.xyz));
//                //
//                // float2 screenPos = pos.xy / pos.w;
//                // //depth
//                // float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r; //采样深度
//                // float depthValue = LinearEyeDepth(depth, _ZBufferParams); //转换深度到0-1区间灰度值
//                // float z = pos.w;
//                // z = abs(depthValue - z);
//
//                
//                float u_xlat31;
//                float4 u_xlat24;
//                    u_xlat31 = (-_ShoreAreaOffset) + 1.0;
//                    u_xlat24.x = shoremask.z + (-_ShoreAreaOffset);
//                    u_xlat24.x = saturate(u_xlat24.x);
//                    u_xlat31 = u_xlat24.x / u_xlat31;
//                    u_xlat30 = u_xlat30 * u_xlat31;
//                    u_xlat31 = u_xlat31;
//
//                    u_xlat31 = saturate(u_xlat31);
//                
//                u_xlat31 = (-u_xlat31) + 1.0;
//                    // u_xlat24.xy = vs_TEXCOORD9.xy / vs_TEXCOORD9.ww;
//                    // u_xlat5.x = texture(SceneDepthCopyTex, u_xlat24.xy).x;
//                    // u_xlat5.x = _ZBufferParams.z * u_xlat5.x + _ZBufferParams.w;
//                    // u_xlat5.x = float(1.0) / u_xlat5.x;
//                float4 pos = ComputeScreenPos(TransformWorldToHClip(input.positionWS.xyz));
//                float2 screenPos = pos.xy / pos.w;
//                //depth
//                float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r; //采样深度
//                float depthValue = LinearEyeDepth(depth, _ZBufferParams);
//                float z = pos.w;
//                z = depthValue - z;
//                float  u_xlat5 = z;
//                float2  u_xlat4 = saturate(u_xlat5.x / _ShoreDepthRange);
//
//                    u_xlat5.x = saturate(u_xlat5.x / _EdgeOpacity);
//               u_xlat4.y = 0.5f;
//                float4    resWaveRamp = SAMPLE_TEXTURE2D(_ShoreWaveRamp2,sampler_ShoreWaveRamp2, u_xlat4.xy);
//float2 u_xlat16_4 = resWaveRamp.xy;
//                float   u_xlat16_13 = dot(u_xlat16_4.xy, foamtex.xy);
//                float   u_xlat0 = max(u_xlat30, u_xlat16_13.x);
//
//                return half4(u_xlat0.xxx, 1.0);
//
//                
//                //form
//                float3 formtex = SAMPLE_TEXTURE2D(_FormMap, sampler_FormMap, input.positionWS.xz*_formScale.xy+_Time.x+normalWS.xy).rgb;
//                float3 formtex2 = SAMPLE_TEXTURE2D(_FormMap, sampler_FormMap, input.positionWS.xz*_formScale.zw-_Time.x+normalWS.xz).bgr;
//                formtex += formtex2;
//                //.... 
//                float edge = 0.0;
//                float form = dot(formtex, float3(1, 1, 1)) * (saturate(edge));
//                // form += form;
//
//
//                float3 waveTex = SAMPLE_TEXTURE2D(_FormMap, sampler_FormMap, uv*_wavescale.xy+normalWS.xy*_NoiseIntensity+float2(0,_Time.x)).rgb;
//                float3 waveTex2 = SAMPLE_TEXTURE2D(_FormMap, sampler_FormMap, uv*_wavescale.zw+normalWS.xy*_NoiseIntensity+float2(0,_Time.x)).rgb;
//                waveTex += waveTex2;
//                float3 wava = dot(waveTex, float3(.5, .5, .5));
//                wava *= wava;
//                //spec
//                 specTex = SAMPLE_TEXTURE2D(_SpecMap, sampler_SpecMap, input.positionWS.xz*_SpecMapST.xy).xyz;
//                 specTex2 = SAMPLE_TEXTURE2D(_SpecMap, sampler_SpecMap, input.positionWS.xz*_SpecMapST.zw+.2+_Time.x*_Blin).xyz;
//                spec = dot(specTex, specTex2) * 100;
//
//                spec *= pow(max(0, dot(normalize(input.normalWS), halfview)), 500);
//                float4 final = lerp(_BaseColor, _DepthColor, clamp(0, 1, z));
//                final.rgb += (wava * _WaveIntensity + form * _FormIntensity) * _WaveColor;
//                final += spec;
//
//                
//                //reflect
//                half3 reflectVector = reflect(-viewDir, normalWS);
//                half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector,_ReflectIntensity)*_ReflectIntensity;
//                final.rgb*=encodedIrradiance.rgb;
//                //fog
//                final.rgb=MixFog(final.rgb,input.fogCoord);
//                return saturate(final); //+ alpha + _BaseColor; // _BaseColor + alpha;
//            }
//            ENDHLSL
//        }
//        Pass
//        {
//            Name "DepthOnly"
//            Tags
//            {
//                "LightMode" = "DepthOnly"
//            }
//
//            ZWrite On
//            ColorMask 0
//
//            HLSLPROGRAM
//            #pragma only_renderers gles gles3 glcore d3d11
//            #pragma target 2.0
//
//            #pragma vertex DepthOnlyVertex
//            #pragma fragment DepthOnlyFragment
//
//            // -------------------------------------
//            // Material Keywords
//            #pragma shader_feature_local_fragment _ALPHATEST_ON
//
//            //--------------------------------------
//            // GPU Instancing
//            #pragma multi_compile_instancing
//
//            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
//            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
//            ENDHLSL
//        }
//
//        // This pass it not used during regular rendering, only for lightmap baking.
//        Pass
//        {
//            Name "Meta"
//            Tags
//            {
//                "LightMode" = "Meta"
//            }
//
//            Cull Off
//
//            HLSLPROGRAM
//            #pragma only_renderers gles gles3 glcore d3d11
//            #pragma target 2.0
//
//            #pragma vertex UniversalVertexMeta
//            #pragma fragment UniversalFragmentMetaUnlit
//
//            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
//            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitMetaPass.hlsl"
//            ENDHLSL
//        }
//    }
//    FallBack "Hidden/Universal Render Pipeline/FallbackError"
//
//}