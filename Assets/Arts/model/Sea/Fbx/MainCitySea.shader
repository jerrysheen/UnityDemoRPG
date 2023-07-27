Shader "MainCity/SeaTest"
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
        
        _WorldUVScale("_WorldUVScale",vector) = (0.0, 0.0, 500.0, 1)
        [Space(10)] 
        [Header(Wave related)]
        [Space(10)] 
        _VertexWaveTiling("_VertexWaveTiling",float) = 1
        _VertexShoreTiling("_VertexShoreTiling",float) = 1
        _WaveDirection("_WaveDirection",vector) = (1, 1, 1, 1)
        _VertexWaveSpeed("_VertexWaveSpeed",float) = 1
        _VertexShoreSpeed("_VertexShoreSpeed",float) = 1
        _WaveNormal("_WaveNormal", 2D) = "white" {}
        _VertexWaveIntensity("_VertexWaveIntensity",float)=0
        _SpecularTiling("_SpecularTiling",float) = 1.0
        t5_control("t5_control",vector) = (1, 1, 1, 1)
        t5_uv1("t5_uv1",vector) = (1, 1, 1, 1)
        t5_uv2("t5_uv2",vector) = (1, 1, 1, 1)
        t5_intensity("t5_intensity",float) = 1

        
        [Space(10)] 
        [Header(Wave related)]
        [Space(10)] 
        _WPO_MasterSpeed("_WPO_MasterSpeed", float) = 1
        _WPO_WaveScale("_WPO_WaveScale",vector) = (1, 1, 1, 1)
        _WPO_WaveIntensity("_WPO_WaveIntensity",vector) = (1, 1, 1, 1)
        _WPO_WaveSpeed("_WPO_WaveSpeed",vector) = (1, 1, 1, 1)
        
        
        _NoiseMap("_NoiseMap", 2D) = "white" {}
        _WaveScale("_WaveScale",vector) = (1, 1, 1, 1)
        _WaveSpeed("_WaveSpeed",vector) = (1, 1, 1, 1)
        _Intensity("_Intensity",vector) = (1, 1, 1, 1)
        
        
        
        _ShoreWaveSpeed("_ShoreWaveSpeed",float)=0
        _ShoreWaveRampSize("_ShoreWaveRampSize",float)=0
        _ShoreMask("_ShoreMask", 2D) = "white" {}
        _ShoreWaveRamp("_ShoreWaveRamap", 2D) = "white" {}
        _ShoreWaveRamp2("_ShoreWaveRamap2", 2D) = "white" {}
        _ShoreWaveNoiseClip("_ShoreWaveNoiseClip",float)= 0.3
        _ShoreWaveFoamTiling("_ShoreWaveFoamTiling",float)= 0.3
        [Space(10)] 
        [Header(Close Shore)]
        [Space(10)] 
        _ShoreAreaOffset("_ShoreAreaOffset",float)= 0.3
        _ShoreDepthRange("_ShoreDepthRange",float)= 0.3
        _EdgeOpacity("_EdgeOpacity",float)= 0.3

        _Blin("_blin",float)=0
        _SpecMap("_SpecMap", 2D) = "white" {}

        _BumpMap("_BumpMap", 2D) = "bump" {}
        _BumpMapST("_bumpuvscale",vector)=(0,0,0,1)
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

            float _WPO_MasterSpeed;
            float4 _WPO_WaveScale;
            float4 _WPO_WaveIntensity;
            float4 _WPO_WaveSpeed;
            
            float4 _WorldUVScale;
            float4 _FormMap_ST;
            float4 _BumpMap_ST;
            float4 _NoiseMap_ST;
            float4 t5_control;
            float4 t5_uv1;
            float4 t5_uv2;
            float t5_intensity;
            half4 _BaseColor, _DepthColor;
            half _Cutoff;
            half _Surface;
            float3 _LightDir;
            float3 _WaveScale;
            float3 _WaveSpeed;
            float3 _Intensity;

            float _VertexWaveTiling;
            float _SpecularTiling;
            float _VertexShoreTiling;
            float4 _WaveDirection;
            float _VertexWaveSpeed;
            float _VertexShoreSpeed;
            float _VertexWaveIntensity;
            float _ShoreWaveFoamTiling;
            
            half _test;
            half _Blin;
            float4 _BumpMapST, _wavescale, _SpecMapST, _formScale;
            half _Fade;
            half _NoiseIntensity;
            half _FormRange;
            float4 _WaveColor;
            float _WaveIntensity;
            float _ShoreAreaOffset;
            float _ShoreWaveNoiseClip;
            float _ShoreDepthRange;
            float _EdgeOpacity;
            float _FormIntensity;
            float _ReflectIntensity;
            float _ShoreWaveSpeed;
            float _ShoreWaveRampSize;
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
            
            TEXTURE2D(_WaveNormal);
            SAMPLER(sampler_WaveNormal);

            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);

            TEXTURE2D(_NoiseMap);
            SAMPLER(sampler_NoiseMap);
            
            TEXTURE2D(_ShoreMask);
            SAMPLER(sampler_ShoreMask);

            TEXTURE2D(_SpecMap);
            SAMPLER(sampler_SpecMap);
            
            TEXTURE2D(_ShoreWaveRamp);
            SAMPLER(sampler_ShoreWaveRamp);
            
            TEXTURE2D(_ShoreWaveRamp2);
            SAMPLER(sampler_ShoreWaveRamp2);

            TEXTURE2D_X_FLOAT(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
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
                float3 uvNoise : TEXCOORD7;
                float4 WaveWorld : TEXCOORD8;
                float4 texcoord0 : TEXCOORD9;
                float4 texcoord1 : TEXCOORD10;
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
                float3 waveoffset;


                float3 u_xlat0 = 0.0f;
                float3 waveIntensity;
                //u_xlat1.xyz = _WPO_WaveIntensity.www * _WPO_WaveIntensity.xyz;
                waveIntensity.xyz = _WPO_WaveIntensity.www * _WPO_WaveIntensity.xyz;
                //u_xlat27 = _Time.y * _WPO_MasterSpeed;
                float masterSpeed = _Time.y * _WPO_MasterSpeed;

               // float posCombine = output.positionWS.x + output.positionWS.y + output.positionWS.z + 1.0;
                //u_xlat2 = in_POSITION0.yyyy * unity_Builtins0Array[u_xlati28 / 8].hlslcc_mtx4x4unity_ObjectToWorldArray[1];
                // u_xlat2 = unity_Builtins0Array[u_xlati28 / 8].hlslcc_mtx4x4unity_ObjectToWorldArray[0] * in_POSITION0.xxxx + u_xlat2;
                // u_xlat2 = unity_Builtins0Array[u_xlati28 / 8].hlslcc_mtx4x4unity_ObjectToWorldArray[2] * in_POSITION0.zzzz + u_xlat2;
                // u_xlat2 = unity_Builtins0Array[u_xlati28 / 8].hlslcc_mtx4x4unity_ObjectToWorldArray[3] * in_POSITION0.wwww + u_xlat2;
                // u_xlat3.xyz = u_xlat2.xxz / _WPO_WaveScale.xyz;
                
                //u_xlat3.xyz = output.positionWS.xxz / _WPO_WaveScale.xyz - masterSpeed * _WPO_WaveSpeed.xyz ;
                float3 waveSpeed = 2 *  PI * vertexInput.positionWS.xxz / _WPO_WaveScale.xyz - masterSpeed * _WPO_WaveSpeed.xyz ;
                //u_xlat3.xyz = sin(u_xlat3.xyz);
                waveSpeed = sin(waveSpeed);
                float3 u_xlat3 = waveSpeed;
                float3 u_xlat1 = waveIntensity;
                float u_xlat27;
                float3 u_xlat2 = output.positionWS;
                u_xlat1.xy = u_xlat1.xy * u_xlat3.xy;
                u_xlat27 = u_xlat1.y + u_xlat1.x;
                u_xlat27 = u_xlat1.z * u_xlat3.z + u_xlat27;
                u_xlat0.y = u_xlat27 + u_xlat27;
                u_xlat27 = u_xlat27 * 0.100000001;
                u_xlat1.xy = u_xlat2.zx * float2(-0.00999999978, -0.00999999978) + float2(u_xlat27, u_xlat27);
                u_xlat1.xy = SAMPLE_TEXTURE2D_LOD(_NoiseMap,sampler_NoiseMap, u_xlat1.xy, 0.0).xy;
                u_xlat0.y = 2 * dot(waveIntensity.xyz, waveSpeed.xyz);

                u_xlat0.xyz = u_xlat0.xyz + output.positionWS.xyz;
                float4 worldPos;
                worldPos.xyz = u_xlat0;
                worldPos.w = 0.0f;
                output.vertex = TransformWorldToHClip(worldPos);

                output.texcoord0.w = input.uv.x;
                output.texcoord0.xyz = u_xlat0.xyz;
                output.texcoord1.w = input.uv.y;
                output.texcoord1.xyz = u_xlat2.xyz;
                // output.WaveWorld.w = 0.0;
                // output.WaveWorld.xyz = u_xlat0.xyz;
    
    
                //u_xlat0.xyz = u_xlat2.xzx / vec3(_VertexWaveTiling, _VertexShoreTiling, _VertexShoreTiling);
                u_xlat0.xyz = u_xlat2.xzx / float3(_VertexWaveTiling, _VertexShoreTiling, _VertexShoreTiling);
                float waveDirection = dot(u_xlat0.yz, _WaveDirection.zw);
                u_xlat0.x = u_xlat0.x + _Time.y;
                u_xlat0.x = u_xlat0.x * _VertexWaveSpeed;
                waveDirection = waveDirection + (-_Time.y);
                u_xlat0.y = waveDirection * _VertexShoreSpeed;
                u_xlat0.xy = u_xlat0.xy * float2(63.0, 63.0);
                // u_xlat18 = floor(u_xlat0.y);
                // u_xlat9.x = fract(u_xlat0.y);
                // u_xlat27 = u_xlat18 + 1.0;
                // u_xlat3.w = u_xlat18 * 0.015625 + 0.0078125;
                // u_xlat3.y = u_xlat27 * 0.015625 + 0.0078125;
                // u_xlat3.xz = in_TEXCOORD1.xx;
                // u_xlat5.xyz = textureLod(_ShoreNormal, u_xlat3.xy, 0.0).xyz;
                // u_xlat3.xyz = textureLod(_ShoreNormal, u_xlat3.zw, 0.0).xyz;
                // u_xlat16_7.xyz = (-u_xlat3.xyz) + u_xlat5.xyz;
                // u_xlat16_7.xyz = u_xlat9.xxx * u_xlat16_7.xyz + u_xlat3.xyz;
                // u_xlat16_7.xyz = u_xlat16_7.xyz * vec3(2.0, 2.0, 2.0) + vec3(-1.0, -1.0, -1.0);
                // u_xlat9.xyz = u_xlat1.yyy * u_xlat16_7.xyz;
                // u_xlat9.xyz = u_xlat9.xyz * vec3(vec3(_VertexShoreIntensity, _VertexShoreIntensity, _VertexShoreIntensity));
                float3 u_xlat10 = floor(u_xlat0.x);
                u_xlat0.x = frac(u_xlat0.x);
                float u_xlat19 = u_xlat10.x + 1.0;
                //float4 _WaveNormal;
               //  u_xlat3.w = u_xlat10.x * 0.015625 + 0.0078125;
               //  u_xlat3.y = u_xlat19 * 0.015625 + 0.0078125;
               //
               // //  vs_TEXCOORD1.xyz = u_xlat2.xyz;
               //  u_xlat3.xz = input.uv1.xx;
               //  //u_xlat3 = float4(.5, .5, .5, .5);
               //  u_xlat10 = SAMPLE_TEXTURE2D_LOD(_WaveNormal, sampler_WaveNormal, u_xlat3.xy, 0.0).xyz;
               //  u_xlat3 = SAMPLE_TEXTURE2D_LOD(_WaveNormal, sampler_WaveNormal, u_xlat3.zw, 0.0);
                float4 waveNormalUV;
                waveNormalUV.w = u_xlat10.x * 0.015625 + 0.0078125;
                waveNormalUV.y = u_xlat19 * 0.015625 + 0.0078125;

               //  vs_TEXCOORD1.xyz = u_xlat2.xyz;
                waveNormalUV.xz = input.uv1.xx;
                // output.WaveWorld.xy = waveNormalUV.xz;
                // return output;
                //u_xlat3 = float4(.5, .5, .5, .5);
                u_xlat10 = UnpackNormal(SAMPLE_TEXTURE2D_LOD(_WaveNormal, sampler_WaveNormal, waveNormalUV.xy, 0.0)).xyz;
                u_xlat3 = UnpackNormal(SAMPLE_TEXTURE2D_LOD(_WaveNormal, sampler_WaveNormal, waveNormalUV.zw, 0.0));
                // output.WaveWorld.xy = waveNormalUV.xz;
                // return output;
                float4 u_xlat16_7;
                float4 u_xlat1_1 = 0.0f;
                u_xlat16_7.xyz = u_xlat10.xyz + (-u_xlat3.xyz);

                u_xlat16_7.xyz = u_xlat0.xxx * u_xlat16_7.xyz + u_xlat3.xyz;
                output.WaveWorld.xyz = u_xlat16_7.xyz;
                //return output;
                //u_xlat16_7.xyz = u_xlat16_7.xyz * float3(2.0, 2.0, 2.0) + float3(-1.0, -1.0, -1.0);
                u_xlat1_1.xyz = u_xlat1.xxx * u_xlat16_7.xyz;

                //vs_TEXCOORD10.xyz = u_xlat1.xyz * vec3(vec3(_VertexWaveIntensity, _VertexWaveIntensity, _VertexWaveIntensity)) + u_xlat9.xyz;
                output.WaveWorld.xyz = u_xlat1_1.xyz * _VertexWaveIntensity;
                u_xlat0.x = u_xlat2.x / t5_control.z;
                float2 u_xlat9;
                u_xlat9.xy = u_xlat2.zx * float2(1.0, -1.0);
                u_xlat9.xy = u_xlat9.xy / float2(_SpecularTiling, _SpecularTiling);
                u_xlat0.x = _Time.y * t5_control.y + u_xlat0.x;
                u_xlat0.x = u_xlat0.x * t5_control.w;
                u_xlat0.x = sin(u_xlat0.x);
                output.WaveWorld.w = u_xlat0.x * t5_control.x;

                waveoffset.xyz = output.positionWS.xxz/_WaveScale.xyz;
                waveoffset.xyz = -_Time.y * _WPO_MasterSpeed * _WaveSpeed.xyz + waveoffset.xyz;
                waveoffset.xyz *= 2 * 3.1415926;
                waveoffset.xyz = sin(waveoffset.xyz);
                waveoffset.xyz *= _Intensity.xyz;
                output.positionWS += waveoffset.xyz;
                output.vertex = TransformWorldToHClip(output.positionWS);
                output.uvNoise.xy = TRANSFORM_TEX(input.uv, _NoiseMap);

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                //return half4(input.WaveWorld.xy, 0.0, 1.0);
                // 水面normal采样：
                //return half4(input.texcoord0.x, input.texcoord0.y, 0.0, 1.0);
                 float2 u_xlat0;            
                 u_xlat0.x = _Time.y * 0.100000001;
                 u_xlat0.x = frac(u_xlat0.x);
                 u_xlat0.x = input.texcoord0.x * 0.0166666675 + u_xlat0.x;
                 float2 u_xlat1;
                 u_xlat0.x = u_xlat0.x * 6.28318977;
                 u_xlat0.x = sin(u_xlat0.x);
                 u_xlat0.xy = u_xlat0.xx * float2(0.0, 0.400000006);
                 u_xlat1.x = input.texcoord0.w;

                 float2 u_xlat20;
                 float3 u_xlat16_2;
                 u_xlat1.y = input.texcoord1.w;
                 u_xlat0.xy = u_xlat1.xy * float2(_ShoreWaveFoamTiling, _ShoreWaveFoamTiling) + u_xlat0.xy;
                 u_xlat20.xy = (-input.texcoord0.zx) / t5_uv1.zz;
                 u_xlat1.x = _Time.y;
                 u_xlat1.y = input.WaveWorld.w;
                 u_xlat20.xy = t5_uv1.xy * u_xlat1.xy + u_xlat20.xy;
               
                 //u_xlat16_2.xyz = SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, u_xlat20.xy).xyz;
                 float3 waterNormal00 = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, u_xlat20.xy));
                 //u_xlat16_3.xyz = u_xlat16_2.xyz * vec3(2.0, 2.0, 2.0) + vec3(-1.0, -1.0, -1.0);
                  float3 specTex = SAMPLE_TEXTURE2D(_SpecMap, sampler_SpecMap, u_xlat20.xy).xyz;
                u_xlat20.xy = (-input.texcoord0.zx) / t5_uv2.zz;
                  u_xlat20.xy = t5_uv2.xy * u_xlat1.xy + u_xlat20.xy;
                float3 specTex2 = SAMPLE_TEXTURE2D(_SpecMap, sampler_SpecMap, u_xlat20.xy).xyz;
                
                  float3 waterNormal01 =UnpackNormal( SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, u_xlat20.xy));
                  float3 waterNormalTotal = t5_intensity * (waterNormal00 + waterNormal01) + float3(0.0, 0.0, 1.0);
                  waterNormalTotal = t5_intensity * normalize(waterNormal00 + waterNormal01) ;
                //return half4(waterNormalTotal, 1.0f);
 
                // foam
                float4 _ShoreMask_UV =_WorldUVScale;
                float2    WorldUV = input.positionWS.xz + (-_ShoreMask_UV.xy);
                WorldUV.xy = WorldUV.xy / _ShoreMask_UV.zz;
                float4 shoremask= SAMPLE_TEXTURE2D(_ShoreMask, sampler_ShoreMask, float2(-WorldUV.y, WorldUV.x));
                float depthmask = 1 - shoremask.z;
                float3 u_xlat1_1;
                u_xlat1_1.xyz = input.WaveWorld.xyz * depthmask.xxx + waterNormalTotal.xyz;
                u_xlat0.xy = u_xlat1_1.xy * float2(0.0299999993, 0.0299999993) + u_xlat0.xy;
                
                float2 wave1UV;
                wave1UV.x = depthmask +_Time.y * 0.0500000007;
                wave1UV.x /= _ShoreWaveRampSize;
                if(wave1UV.x >= 0)
                {
                    wave1UV.x = frac(abs(wave1UV.x));
                }
                else
                {
                    wave1UV.x = -frac(abs(wave1UV.x));
                }
                wave1UV.x /= _ShoreWaveRampSize;
                wave1UV.y = 0.5;
                float3 wave1 = SAMPLE_TEXTURE2D(_ShoreWaveRamp,sampler_ShoreWaveRamp,wave1UV).xyw;
              
                //wave1 = SAMPLE_TEXTURE2D(_ShoreWaveRamp,sampler_ShoreWaveRamp, half2(0.7,0.0f));
                // float3 u_xlat1_1;
                // u_xlat1_1.xyz = input.WaveWorld.xyz * depthmask.xxx + waterNormalTotal.xyz;
                // u_xlat0.xy = u_xlat1_1.xy * float2(0.0299999993, 0.0299999993) + u_xlat0.xy;

                float3 foamtex = SAMPLE_TEXTURE2D(_FormMap,sampler_FormMap,u_xlat0.xy );
                float wave1foam = dot(wave1.xxy,foamtex.yyz);
               // return float4(wave1foam.xxx, 1.0f);
                float4 col = float4(wave1foam ,wave1foam ,wave1foam ,1.0);
               // return col;

                float4 Noise= SAMPLE_TEXTURE2D(_NoiseMap, sampler_NoiseMap, input.uvNoise.yx);

                //float u_xlat20 = saturate(Noise.z + exp2(log2(shoremask.z) * 20.0) + (-_ShoreWaveNoiseClip));
                u_xlat20 = saturate(Noise.z + exp2(log2(shoremask.z) * 20.0) + (-_ShoreWaveNoiseClip));

                 float  u_xlat30 = (-_ShoreWaveNoiseClip) + 1.0;
                    u_xlat20 = u_xlat20 / u_xlat30;
                    u_xlat30 = saturate(u_xlat20.x);
               // return half4(wave1foam.xxx, 1.0f);

                u_xlat30 = u_xlat30 * wave1foam;
              
                u_xlat30 *= shoremask.w;


                
                float u_xlat31;
                float4 u_xlat24;
                    u_xlat31 = (-_ShoreAreaOffset) + 1.0;
                    u_xlat24.x = shoremask.z + (-_ShoreAreaOffset);
                    u_xlat24.x = saturate(u_xlat24.x);
                    u_xlat31 = u_xlat24.x / u_xlat31;
                    u_xlat30 = u_xlat30 * u_xlat31;
                    u_xlat31 = u_xlat31;

                    u_xlat31 = saturate(u_xlat31);
               
                u_xlat31 = (-u_xlat31) + 1.0;
                    // u_xlat24.xy = vs_TEXCOORD9.xy / vs_TEXCOORD9.ww;
                    // u_xlat5.x = texture(SceneDepthCopyTex, u_xlat24.xy).x;
                    // u_xlat5.x = _ZBufferParams.z * u_xlat5.x + _ZBufferParams.w;
                    // u_xlat5.x = float(1.0) / u_xlat5.x;
                float4 pos = ComputeScreenPos(TransformWorldToHClip(input.positionWS.xyz));
                float2 screenPos = pos.xy / pos.w;
                //depth
                float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r; //采样深度
                float depthValue = LinearEyeDepth(depth, _ZBufferParams);
                float z = pos.w;
                z = depthValue - z;
                float  u_xlat5 = z;
                float2  u_xlat4 = saturate(u_xlat5.x / _ShoreDepthRange);

                u_xlat5.x = saturate(u_xlat5.x / _EdgeOpacity);
               u_xlat4.y = 0.5f;
                float4    resWaveRamp = SAMPLE_TEXTURE2D(_ShoreWaveRamp2,sampler_ShoreWaveRamp2, u_xlat4.xy);
                float2 u_xlat16_4 = resWaveRamp.xy;
                float   u_xlat16_13 = dot(u_xlat16_4.xy, foamtex.xy);

                float totalFoam= max(u_xlat30, u_xlat16_13.x);

                
                float sgn = input.tangentWS.w; // should be either +1 or -1
                float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                //float3 normalWS = TransformTangentToWorld(waterNormalTotal, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
                float3 normalWS = waterNormalTotal;
                
                //float3 specTex = SAMPLE_TEXTURE2D(_SpecMap, sampler_SpecMap, WorldUV).xyz;
                //float3 specTex2 = SAMPLE_TEXTURE2D(_SpecMap, sampler_SpecMap, WorldUV).xyz;
                //return half4(specTex2, 1.0f);
                float spec = dot(specTex, specTex2) * 100;
                
                float3 viewDir = SafeNormalize(input.viewDirWS);
                float3 lightDir = normalize(_LightDir); //normalize(_MainLightPosition);
                float3 halfview = SafeNormalize(viewDir + lightDir);
                spec *= pow(max(0, dot(normalize(input.normalWS), halfview)), 250.0);
               // float4 final = lerp(_BaseColor, _DepthColor, clamp(0, 1, z));
                float4 _WaterColor2 = _DepthColor;
                float4 _WaterColor1 = _BaseColor;
                float4 u_xlat16_5;
                
                u_xlat16_5.xyz = _WaterColor2.xyz * float3(0.100000001, 0.100000001, 0.100000001) + (-_WaterColor1.xyz);
                 u_xlat16_5.xyz = depthmask * u_xlat16_5.xyz + _WaterColor1.xyz;
                u_xlat16_5.a = 1.0f;
                float4 final = u_xlat16_5;
                final.rgb += (totalFoam) * _WaveColor;
                final.rgb += spec;
               return half4(final.rgb, 1.0f);


                return half4(final.rgb, 1.0f);

                //vec3 diffuse = diff * lightColor;
                //reflect
                half3 reflectVector = reflect(-viewDir, normalWS);
                half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector,_ReflectIntensity)*_ReflectIntensity;
                final.rgb*=encodedIrradiance.rgb;
                //fog
                final.rgb=MixFog(final.rgb,input.fogCoord);
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