#ifndef FASTER_TERRAIN_LIT_PASSES_INCLUDED
#define FASTER_TERRAIN_LIT_PASSES_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"


            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS    : TANGENT;
            };

            struct Varyings
            {
                float2 uvMainAndLM                       : TEXCOORD0;

                #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                float3 positionWS               : TEXCOORD1;
                #endif

                float3 normalWS                 : TEXCOORD2;
                #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
                half4 tangentWS                : TEXCOORD3;    // xyz: tangent, w: sign
                #endif

                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                half4 fogFactorAndVertexLight   : TEXCOORD5; // x: fogFactor, yzw: vertex light
                #else
                half  fogFactor                 : TEXCOORD5;
                #endif

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                float4 shadowCoord              : TEXCOORD6;
                #endif

                #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                half3 viewDirTS                : TEXCOORD7;
                #endif

                DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 8);
                #ifdef DYNAMICLIGHTMAP_ON
                float2  dynamicLightmapUV : TEXCOORD9; // Dynamic lightmap UVs
                #endif

                float4 positionCS               : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };


            void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
            {
                    inputData = (InputData)0;

                #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                    inputData.positionWS = input.positionWS;
                #endif

                    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                #if defined(_NORMALMAP) || defined(_DETAIL)
                    float sgn = input.tangentWS.w;      // should be either +1 or -1
                    float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                    half3x3 tangentToWorld = half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz);

                    #if defined(_NORMALMAP)
                    inputData.tangentToWorld = tangentToWorld;
                    #endif
                    inputData.normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
                #else
                    inputData.normalWS = input.normalWS;
                #endif

                    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                    inputData.viewDirectionWS = viewDirWS;

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    inputData.shadowCoord = input.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                #else
                    inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif
                #ifdef _ADDITIONAL_LIGHTS_VERTEX
                    inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactorAndVertexLight.x);
                    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
                #else
                    inputData.fogCoord = InitializeInputDataFog(float4(input.positionWS, 1.0), input.fogFactor);
                #endif

                #if defined(DYNAMICLIGHTMAP_ON)
                    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.dynamicLightmapUV, input.vertexSH, inputData.normalWS);
                #else
                    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.normalWS);
                #endif

                    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                    inputData.shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);

                    #if defined(DEBUG_DISPLAY)
                    #if defined(DYNAMICLIGHTMAP_ON)
                    inputData.dynamicLightmapUV = input.dynamicLightmapUV;
                    #endif
                    #if defined(LIGHTMAP_ON)
                    inputData.staticLightmapUV = input.staticLightmapUV;
                    #else
                    inputData.vertexSH = input.vertexSH;
                    #endif
                    #endif
            }

            void SplatmapFinalColor(inout half4 color, half fogCoord)
            {
                color.rgb *= color.a;

                #ifndef TERRAIN_GBUFFER // Technically we don't need fogCoord, but it is still passed from the vertex shader.

                #ifdef TERRAIN_SPLAT_ADDPASS
                    color.rgb = MixFogColor(color.rgb, half3(0,0,0), fogCoord);
                #else
                    color.rgb = MixFog(color.rgb, fogCoord);
                #endif

                #endif
            }


            Varyings MainCityTerrainPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                // normalWS and tangentWS already normalize.
                // this is required to avoid skewing the direction during interpolation
                // also required for per-vertex lighting and SH evaluation
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);

                half fogFactor = 0;
                #if !defined(_FOG_FRAGMENT)
                    fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
                #endif

                output.uvMainAndLM = TRANSFORM_TEX(input.texcoord, _GlobalNormal);

                // already normalized from normal transform to WS.
                output.normalWS = normalInput.normalWS;
            #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR) || defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                real sign = input.tangentOS.w * GetOddNegativeScale();
                half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
            #endif
            #if defined(REQUIRES_WORLD_SPACE_TANGENT_INTERPOLATOR)
                output.tangentWS = tangentWS;
            #endif

            #if defined(REQUIRES_TANGENT_SPACE_VIEW_DIR_INTERPOLATOR)
                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
                half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
                output.viewDirTS = viewDirTS;
            #endif

                OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
            #ifdef DYNAMICLIGHTMAP_ON
                output.dynamicLightmapUV = input.dynamicLightmapUV.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
            #endif
                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
            #ifdef _ADDITIONAL_LIGHTS_VERTEX
                output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
            #else
                output.fogFactor = fogFactor;
            #endif

            #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                output.positionWS = vertexInput.positionWS;
            #endif

            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                output.shadowCoord = GetShadowCoord(vertexInput);
            #endif

                output.positionCS = vertexInput.positionCS;
                return output;
            }

            real3 UnpackNormalMainCity(real4 packedNormal, real scale = 1.0)
            {
                // v2.0 modify: Normal从0-1 转到-1~1的过程在Normal Blend中完成，所以这边我们只需要计算z通道即可。

                real3 normal;
                normal.xy = packedNormal.rg * 2.0 - 1.0;
                normal.z = max(1.0e-16, sqrt(1.0 - saturate(dot(normal.xy, normal.xy))));

                //normal.xy = packedNormal.rg;
                // must scale after reconstruction of normal.z which also
                // mirrors UnpackNormalRGB(). This does imply normal is not returned
                // as a unit length vector but doesn't need it since it will get normalized after TBN transformation.
                // If we ever need to blend contributions with built-in shaders for URP
                // then we should consider using UnpackDerivativeNormalAG() instead like
                // HDRP does since derivatives do not use renormalization and unlike tangent space
                // normals allow you to blend, accumulate and scale contributions correctly.
                normal.xy *= scale;

                // v2.0， 这个地方如果做了normal scale， 我们要将转化完的normal 从 [-1, 1] 在转化回 [0, 1]
                //normal.xy = (normal.xy + 1.0) * 0.5f;
                return normal;
            }


            half4 MainCityTerrainPassFragment(Varyings IN)  : COLOR
            {

#ifndef  LOW_QUALITY
    #define GLOBAL_NORMAL_BLEND
    #define HTIGHTMAP_BLEND
    #define PBR_LIGHT_CALCULATE
#else
                //return 1.0f;
#endif
                float _ChangeSeasonPack0 = 0.0f;

                float2 u_xlat16_1 = IN.uvMainAndLM.xy;
                float2 uvHeight = IN.uvMainAndLM.xy * _HeightPack0_ST.xy + _HeightPack0_ST.zw;
                //globalNormal = TransformTangentToWorld(globalNormal, half3x3(-IN.tangent.xyz, IN.bitangent.xyz, IN.normal.xyz));

                half4 weight00 = SAMPLE_TEXTURE2D(_WeightPack0, sampler_WeightPack0, u_xlat16_1.xy).xyzw;
                half4 weight01 = SAMPLE_TEXTURE2D(_WeightPack1, sampler_WeightPack1, u_xlat16_1.xy).xyzw;
                float3 globalNormal = UnpackNormalMainCity(SAMPLE_TEXTURE2D(_GlobalNormal, sampler_GlobalNormal, u_xlat16_1.xy));
                
                u_xlat16_1 = weight01.xy;



                float2 u_xlat16_12 = 0.0;

                // Global Normal and LOD:
                float2 u_xlat0 = IN.uvMainAndLM.xy;

#ifdef HEIGHTMAP_BLEND
                float4 HeightControl0;
                float4 HeightControl1;
                HeightControl0 = SAMPLE_TEXTURE2D(_HeightPack0, sampler_HeightPack0, uvHeight.xy);
                HeightControl1 = SAMPLE_TEXTURE2D(_HeightPack1, sampler_HeightPack1, uvHeight.xy);
#endif


                // 计算LOD
                _AlbedoPack0_TexelSize.xy *= (int)pow(2, _GLobalMipMapLimit);
                _AlbedoPack0_TexelSize.zw /= (int)pow(2, _GLobalMipMapLimit);
                float2 uv = uvHeight * _AlbedoPack0_TexelSize.zw ;
                float2  dx = ddx(uv);
                float2 dy = ddy(uv);
                float2 rho = max(sqrt(dot(dx, dx)), sqrt(dot(dy, dy)));
                //float2 lambda = 0.5 * log2(rho);
                float lambda = log2(rho - _LODScale).x;
                float LODLevel = max(int(lambda + 0.5), 0);
                
                u_xlat0.x = _AlbedoPack0_TexelSize.z * 0.5;
                //int d = max(int(lambda + 0.5), 0);
                float u_xlat16_24;
                //float LODLevel = round(lambda * 1.0);
                LODLevel = LODLevel > 0.0 ? LODLevel : 0.0;
                float final_LOD = LODLevel;

                // 得到正确的local坐标，0，0表示完全采样第一个texel的像素， 0，1则表示完全采样第三个texel的像素，
                // 这一步就在求，我正确的LOD下，需要采样的texel的间隔是多少。
                // Single_AlbedoTex_Width : 单张diffuse的大小
                // diffuseGalobalTillingAndOffset : diffuseUV的全局的tilling和offset计算结果
                // diffuseLodScale : 用来计算不同LOD Level时，每个texel的UV偏移量，比方说0层的时候是1/512，一层就是2/512
                float Single_AlbedoTex_Width = _AlbedoPack0_TexelSize.z * 0.5;
                float LOD_Scale = exp2(final_LOD);;
                float ScaleRatio = Single_AlbedoTex_Width / LOD_Scale;
                float diffuseLodScale = LOD_Scale * _AlbedoPack0_TexelSize.x;
                float2 diffuseGalobalTillingAndOffset;
                // 这一步的操作，是分离globalUV和localUV，因为我在下面会计算localUV，它是0-1的数字，计算的是在四个diffuse组成的色块中的位置
                // 比方说，一张组合图为1024，那么一个单块的diffuse为512，diffuseLocalUV.xy * diffuseLodScale.x，就能够计算在1/512里面
                // 的移动，如果diffuseLocalUV为1，则计算结果为（1/1024 , 1/1024)， 而diffuseGalobalTillingAndOffset(1/2048)的偏移量，刚好代表第一个小块中的最右上色块正中位置，一般这个数字会比1小一点，避免采样问题
                // 而diffuseGalobalTillingAndOffset，则要保证globalUV保持在
                // （0/512),（1/512),（2/512)....1 +（0/512), 1 +（1/512), 1 +（2/512) 这些位置上，这些位置以一个Block为单位
                // 最后diffuseLodScale.xx * float2(0.5, 0.5) 表示我会在像素的中心点进行采样。
                diffuseGalobalTillingAndOffset = uvHeight.xy * float2(ScaleRatio, ScaleRatio);
                diffuseGalobalTillingAndOffset = floor(diffuseGalobalTillingAndOffset);
                diffuseGalobalTillingAndOffset = diffuseGalobalTillingAndOffset / float2(ScaleRatio, ScaleRatio);
                diffuseGalobalTillingAndOffset = diffuseLodScale.xx * float2(0.5, 0.5) + diffuseGalobalTillingAndOffset;

                // 第一层的混合
                float2 diffuseLocalUV;
                half4  AlbedoPack00;
                half3  NormalPack00;
                half  Metallic00;
                half  Smoothness00;
                half4 Nomal_Metallic_Smoothness;
#ifdef HEIGHTMAP_BLEND
                float BlendUVLayer0X = weight00.x * HeightControl0.x;
                float BlendUVLayer0Y = weight00.y * HeightControl0.y;
                float BlendUVLayer0Z = weight00.z * HeightControl0.z;
#else
                float BlendUVLayer0X = weight00.x;
                float BlendUVLayer0Y = weight00.y;
                float BlendUVLayer0Z = weight00.z;
#endif

                
                diffuseLocalUV.x = BlendUVLayer0Z / (BlendUVLayer0Y + BlendUVLayer0Z + 0.00100000005);
                diffuseLocalUV.y = (BlendUVLayer0Y + BlendUVLayer0Z + 0.00100000005) / (BlendUVLayer0Z + BlendUVLayer0Y + BlendUVLayer0X + 0.00100000005);
                float2 Layer0UV  = diffuseLocalUV.xy * diffuseLodScale.xx + diffuseGalobalTillingAndOffset;
 
                

                AlbedoPack00 = SAMPLE_TEXTURE2D_LOD(_AlbedoPack0, sampler_AlbedoPack0, Layer0UV.xy , final_LOD);
                
                Nomal_Metallic_Smoothness = (SAMPLE_TEXTURE2D_LOD(_NormalPack0, sampler_NormalPack0, Layer0UV.xy , final_LOD));
                NormalPack00 = UnpackNormalMainCity(Nomal_Metallic_Smoothness, _NormalScale00);
                Metallic00 = Nomal_Metallic_Smoothness.b;
                Smoothness00 = Nomal_Metallic_Smoothness.a;

                half4 AlbedoPack01;
                half3  NormalPack01;
                half  Metallic01;
                half  Smoothness01;
 #ifdef HEIGHTMAP_BLEND
                float BlendUVLayer1X = weight00.w * HeightControl0.w;
                float BlendUVLayer1Y = weight01.y * HeightControl1.x;
                float BlendUVLayer1Z = weight01.z * HeightControl1.y;
#else
                float BlendUVLayer1X = weight00.w;
                float BlendUVLayer1Y = weight01.x;
                float BlendUVLayer1Z = weight01.y;
#endif
        

                diffuseLocalUV.x = BlendUVLayer1Z / (BlendUVLayer1Y + BlendUVLayer1Z + 0.00100000005);
                diffuseLocalUV.y = (BlendUVLayer1Y + BlendUVLayer1Z + 0.00100000005) / (BlendUVLayer1Y + BlendUVLayer1Z + BlendUVLayer1X + 0.00100000005);
                float2 Layer1UV  = diffuseLocalUV.xy * diffuseLodScale.xx + diffuseGalobalTillingAndOffset;
                AlbedoPack01 = SAMPLE_TEXTURE2D_LOD(_AlbedoPack1, sampler_AlbedoPack1,Layer1UV.xy,final_LOD);
                Nomal_Metallic_Smoothness = (SAMPLE_TEXTURE2D_LOD(_NormalPack1, sampler_NormalPack1, Layer1UV.xy , final_LOD));
                NormalPack01 = UnpackNormalMainCity(Nomal_Metallic_Smoothness, _NormalScale01);
                Metallic01 = Nomal_Metallic_Smoothness.b;
                Smoothness01 = Nomal_Metallic_Smoothness.a;


                float totalWeight;
                totalWeight = 1.0f - dot(weight00, half4(1.0, 1.0, 1.0, 1.0)) - dot(weight01, half4(1.0, 1.0, 1.0, 1.0)) ;
                //totalWeight = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uvMainAndLM.xy).r;
                totalWeight = clamp(totalWeight, 0.0, 1.0);
                totalWeight *= 0.5f;
                // total value其实这个地方就是0.0;
#ifdef HEIGHTMAP_BLEND
                float BlendUVLayer2X = weight00.w * HeightControl0.w;
                float BlendUVLayer2Y = weight01.y * HeightControl1.x;
                float BlendUVLayer2Z = weight01.z * HeightControl1.y;
                
#else
                float BlendUVLayer2X = weight01.z;
                float BlendUVLayer2Y = weight01.w;
                float BlendUVLayer2Z = totalWeight;
                
#endif

                
                diffuseLocalUV.x= BlendUVLayer2Z / (BlendUVLayer2Y + BlendUVLayer2Z + 0.00100000005);
                diffuseLocalUV.y = (BlendUVLayer2Y + BlendUVLayer2Z + 0.00100000005) /(BlendUVLayer2X + BlendUVLayer2Y + BlendUVLayer2Z + 0.00100000005);
                float2 Layer2UV = diffuseLocalUV.xy * diffuseLodScale.xx + diffuseGalobalTillingAndOffset;
                half3  NormalPack02;
                half  Metallic02;
                half  Smoothness02;
                half4 AlbedoPack02 = SAMPLE_TEXTURE2D_LOD(_AlbedoPack2 ,sampler_AlbedoPack2 ,Layer2UV.xy,final_LOD);
                Nomal_Metallic_Smoothness = (SAMPLE_TEXTURE2D_LOD(_NormalPack2, sampler_NormalPack2, Layer2UV.xy , final_LOD));
                NormalPack02 = UnpackNormalMainCity(Nomal_Metallic_Smoothness, _NormalScale02);
                Metallic02 = Nomal_Metallic_Smoothness.b;
                Smoothness02 = Nomal_Metallic_Smoothness.a;

           
                float Layer01TotalWeight = BlendUVLayer1X + BlendUVLayer1Y + BlendUVLayer1Z + 0.00100000005;

                float Layer00TotalWeight = BlendUVLayer0Y + BlendUVLayer0Z+ BlendUVLayer0X + 0.00100000005;

                float Layer02TotalWeight = (BlendUVLayer2X + BlendUVLayer2Y + BlendUVLayer2Z + 0.00100000005);

                half4 BlendAlbedoRes = AlbedoPack00 * Layer00TotalWeight + AlbedoPack01 * Layer01TotalWeight + AlbedoPack02 * Layer02TotalWeight;
                half3 BlendNormalRes = NormalPack00 * Layer00TotalWeight + NormalPack01 * Layer01TotalWeight + NormalPack02 * Layer02TotalWeight;
                half BlendMetallicRes = Metallic00 * Layer00TotalWeight + Metallic01 * Layer01TotalWeight + Metallic02 * Layer02TotalWeight;
                half BlendSmoothnessRes = Smoothness00 * Layer00TotalWeight + Smoothness01 * Layer01TotalWeight + Smoothness02 * Layer02TotalWeight;
            
                float totalValue =  Layer00TotalWeight + Layer01TotalWeight + Layer02TotalWeight;

                BlendAlbedoRes = BlendAlbedoRes / totalValue;
                BlendNormalRes = BlendNormalRes / totalValue;
                BlendMetallicRes = BlendMetallicRes / totalValue;
                BlendSmoothnessRes = BlendSmoothnessRes / totalValue;

                half4 albedo = BlendAlbedoRes;
                InputData inputData;

                // V2.0: global normal blend with local normal
                // using UE4 normal Blend method, ref: https://mp.weixin.qq.com/s/3cGThckJ3WE-SPnarjjPyA
                half3 detailNormal = BlendNormalRes;
                half3 baseNormal = lerp(normalize(half3(0.5, 0.5, 1.0)), globalNormal, _GlobalNormalBlendRate);
                float3 t = baseNormal.xyz * float3( 2.0,  2.0, 2.0) + float3(-1.0, -1.0,  0);
                float3 u = normalize(detailNormal.xyz) * float3(-2.0, -2.0, 2.0) + float3( 1.0,  1.0, -1.0);
                float3 normalTS = t * dot(t, u) / t.z - u;
                normalTS = normalTS * 0.5 + 0.5f;
                // 这个地方法线做完运算后，还是需要归一到(0.5, 0.5, 1.0)去？
                //half3 curr = UnpackNormal(SAMPLE_TEXTURE2D(_GlobalNormal, sampler_GlobalNormal, IN.uvMainAndLM.xy));
               // return half4((detailNormal.xyz* float3( 2.0,  2.0, 2.0) + float3(-1.0, -1.0,  0)), 1.0f);
                return half4(normalize(normalTS.xyz), 1.0f);
                //normal 混合貌似有一点问题。
                normalTS = BlendNormalRes;
                
                InitializeInputData(IN, normalTS, inputData);
                float sgn = IN.tangentWS.w;      // should be either +1 or -1
                float3 bitangent = sgn * cross(IN.normalWS.xyz, IN.tangentWS.xyz);
                half3x3 tangentToWorld = half3x3(IN.tangentWS.xyz, bitangent.xyz, IN.normalWS.xyz);
                inputData.normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);

                half metallic = BlendMetallicRes;
                half smoothness = BlendSmoothnessRes;
                half occlusion = BlendAlbedoRes.a;
                //smoothness = 0.0f;
               // metallic = 0.5f;
                half alpha = 1.0;

                half4 color = UniversalFragmentPBR(inputData, albedo.xyz, metallic, /* specular */ half3(0.0h, 0.0h, 0.0h), smoothness, occlusion, /* emission */ half3(0, 0, 0), alpha);
                SplatmapFinalColor(color, inputData.fogCoord);

                return half4(color.xyz, 1.0h);
                //#endif
            }


#endif
