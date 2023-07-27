#ifndef FASTER_TERRAIN_LIT_PASSES_INCLUDED
#define FASTER_TERRAIN_LIT_PASSES_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"


            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS    : TANGENT;
            };

            struct Varyings
            {
                float4 uvMainAndLM              : TEXCOORD0; // xy: control, zw: lightmap
            // #ifndef TERRAIN_SPLAT_BASEPASS
            //     float4 uvSplat01                : TEXCOORD1; // xy: splat0, zw: splat1
            //     float4 uvSplat23                : TEXCOORD2; // xy: splat2, zw: splat3
            // #endif
                float2 uvHeight : TEXCOORD1;
                float3 viewDirWS                : TEXCOORD2;
            //#if defined(_NORMALMAP) && !defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
                float3 normal                   : TEXCOORD3;    // xyz: normal, w: viewDir.x
                float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: viewDir.y
                float4 bitangent                : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
            // #else
            //     float3 normal                   : TEXCOORD3;
            //     float3 viewDir                  : TEXCOORD4;
            //     half3 vertexSH                  : TEXCOORD5; // SH
            // #endif

                half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light
                float3 positionWS               : TEXCOORD7;
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                float4 shadowCoord              : TEXCOORD8;
            #endif
                float4 clipPos                  : SV_POSITION;
                float4 globleUV                 : TEXCOORD9;
                UNITY_VERTEX_OUTPUT_STEREO
            };


            void InitializeInputData(Varyings IN, half3 normalTS, out InputData input)
            {
                input = (InputData)0;

                input.positionWS = IN.positionWS;
                half3 SH = half3(0, 0, 0);

                float sgn = IN.tangentWS.w;      // should be either +1 or -1
                float3 bitangent = sgn * cross(IN.normal.xyz, IN.tangentWS.xyz);
                half3x3 tangentToWorld = half3x3(IN.tangentWS.xyz, bitangent.xyz, IN.normal.xyz);

                input.tangentToWorld = tangentToWorld;
                input.normalWS = TransformTangentToWorld(normalTS, tangentToWorld);

            #if SHADER_HINT_NICE_QUALITY
                viewDirWS = SafeNormalize(viewDirWS);
            #endif

                input.normalWS = NormalizeNormalPerPixel(input.normalWS);
                input.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.positionWS);


            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                input.shadowCoord = IN.shadowCoord;
            #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                input.shadowCoord = TransformWorldToShadowCoord(input.positionWS);
            #else
                input.shadowCoord = float4(0, 0, 0, 0);
            #endif

                input.fogCoord = IN.fogFactorAndVertexLight.x;
                input.vertexLighting = IN.fogFactorAndVertexLight.yzw;

                input.bakedGI = SAMPLE_GI(IN.uvMainAndLM.zw, SH, input.normalWS);
                input.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.clipPos);
                input.shadowMask = SAMPLE_SHADOWMASK(IN.uvMainAndLM.zw)
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


            Varyings MainCityTerrainPassVertex(Attributes v)
            {
                Varyings o = (Varyings)0;

                //UNITY_SETUP_INSTANCE_ID(v);
                //UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                //TerrainInstancing(v.positionOS, v.normalOS, v.texcoord);

                VertexPositionInputs Attributes = GetVertexPositionInputs(v.positionOS.xyz);

                o.uvMainAndLM.xy = v.texcoord;
                o.uvMainAndLM.zw = v.texcoord * unity_LightmapST.xy + unity_LightmapST.zw;

                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(Attributes.positionWS);
                o.viewDirWS = viewDirWS;

                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                o.normal = normalInput.normalWS;
                real sign = v.tangentOS.w * GetOddNegativeScale();
                half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
                o.tangentWS = tangentWS;

                o.fogFactorAndVertexLight.x = ComputeFogFactor(Attributes.positionCS.z);
                o.fogFactorAndVertexLight.yzw = VertexLighting(Attributes.positionWS, o.normal.xyz);
                o.positionWS = Attributes.positionWS;
                o.clipPos = Attributes.positionCS;
                //o.globleUV.xy=TRANSFORM_TEX(v.texcoord,_GlobalNormalMap);
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                o.shadowCoord = GetShadowCoord(Attributes);
            #endif

                o.uvHeight.xy = TRANSFORM_TEX(v.texcoord, _HeightPack0);
                return o;


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
                normal.xy = (normal.xy + 1.0) * 0.5f;
                return normal;
            }


            half4 MainCityTerrainPassFragment(Varyings IN)  : COLOR
            {
                 float2 weightUV;

                float2 u_xlat16_1 = IN.uvMainAndLM.xy;
                //globalNormal = TransformTangentToWorld(globalNormal, half3x3(-IN.tangent.xyz, IN.bitangent.xyz, IN.normal.xyz));

                half4 weight00 = SAMPLE_TEXTURE2D(_WeightPack0, sampler_WeightPack0, u_xlat16_1.xy).xyzw;
                half4 weight01 = SAMPLE_TEXTURE2D(_WeightPack1, sampler_WeightPack1, u_xlat16_1.xy).xyzw;
                float3 globalNormal = UnpackNormalMainCity(SAMPLE_TEXTURE2D(_GlobalNormal, sampler_GlobalNormal, u_xlat16_1.xy));

                u_xlat16_1 = weight01.xy;

                float totalWeight;
                totalWeight = 1.0f - dot(weight00, half4(1.0, 1.0, 1.0, 1.0)) - dot(weight01, half4(1.0, 1.0, 1.0, 1.0)) ;
                //totalWeight = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uvMainAndLM.xy).r;
                totalWeight = clamp(totalWeight, 0.0, 1.0);
                totalWeight *= 0.5f;

                float2 u_xlat16_12 = 0.0;

                // Global Normal and LOD:
                float2 u_xlat0 = IN.uvMainAndLM.xy;


                float2 u_xlat16_0;
                float4 u_xlat16_5;
                float4 u_xlat16_6 = 0.0;
                float4 u_xlat16_15 = 0.0;
                float4 u_xlat16_7 = 0.0;
                float3 u_xlat9;

                //u_xlat16_0.xy = SAMPLE_TEXTURE2D(_GlobalNormal, sampler_GlobalNormal, IN.uvMainAndLM.xy).xy;

                //u_xlat16_12.xy = u_xlat16_0.xy * float2(2.0, 2.0) + float2(-1.0, -1.0);

                float4 HeightControl0;
                float4 HeightControl1;
                HeightControl0 = SAMPLE_TEXTURE2D(_HeightPack0, sampler_HeightPack0, IN.uvHeight.xy);
                HeightControl1 = SAMPLE_TEXTURE2D(_HeightPack1, sampler_HeightPack1, IN.uvHeight.xy);
                float4 localHeightValue = (1 - _ChangeSeasonPack0) * HeightControl0;

                float localHeightBlendWithWeightXYZ;
                float localHeightBlendWithWeightYZ;
                float2 diffuseLocalUV;
                float4 localHeightBlendWithWeight00 = weight00 * localHeightValue;

                localHeightBlendWithWeightYZ = localHeightBlendWithWeight00.y + localHeightBlendWithWeight00.z + 0.00100000005;
                localHeightBlendWithWeightXYZ = localHeightBlendWithWeight00.x + localHeightBlendWithWeight00.y + localHeightBlendWithWeight00.z + 0.00100000005;
                diffuseLocalUV.x = localHeightBlendWithWeight00.z / localHeightBlendWithWeightYZ;
                diffuseLocalUV.y = localHeightBlendWithWeightYZ / localHeightBlendWithWeightXYZ;

                // 计算LOD
                _AlbedoPack0_TexelSize.xy *= (int)pow(2, _GLobalMipMapLimit);
                _AlbedoPack0_TexelSize.zw /= (int)pow(2, _GLobalMipMapLimit);

                float2 uv = IN.uvHeight * _AlbedoPack0_TexelSize.zw ;
                float2  dx = ddx(uv);
                float2 dy = ddy(uv);
                float2 rho = max(sqrt(dot(dx, dx)), sqrt(dot(dy, dy)));
                //float2 lambda = 0.5 * log2(rho);
                float lambda = log2(rho - _LODScale).x;
                float LODLevel = max(int(lambda + 0.5), 0);
                float2 u_xlat11;
                u_xlat0.x = _AlbedoPack0_TexelSize.z * 0.5;
                //int d = max(int(lambda + 0.5), 0);
                float u_xlat16_24;
                //float LODLevel = round(lambda * 1.0);
                LODLevel = LODLevel > 0.0 ? LODLevel : 0.0;
                float u_xlat16_30 = LODLevel;

                // 得到正确的local坐标，0，0表示完全采样第一个texel的像素， 0，1则表示完全采样第三个texel的像素，
                // 这一步就在求，我正确的LOD下，需要采样的texel的间隔是多少。
                u_xlat16_15.x = exp2(u_xlat16_30);
                u_xlat16_24 = u_xlat0.x / u_xlat16_15.x;
                u_xlat0.x = u_xlat16_15.x * _AlbedoPack0_TexelSize.x;
                //u_xlat9.xz = u_xlat4.xy * float2(u_xlat16_24, u_xlat16_24);
                u_xlat9.xz = IN.uvHeight.xy * float2(u_xlat16_24, u_xlat16_24);
                u_xlat9.xz = floor(u_xlat9.xz);
                u_xlat9.xz = u_xlat9.xz / float2(u_xlat16_24, u_xlat16_24);
                u_xlat9.xz = u_xlat0.xx * float2(0.5, 0.5) + u_xlat9.xz;
                float TexelSizeWithLOD = 1 / (_AlbedoPack0_TexelSize.z * u_xlat16_15.x);
                u_xlat11.xy = diffuseLocalUV.xy * u_xlat0.xx + u_xlat9.xz;
                half4  AlbedoPack00;
                half3  NormalPack00;
                half  Metallic00;
                half  Smoothness00;
                half4 Nomal_Metallic_Smoothness;

                AlbedoPack00 = SAMPLE_TEXTURE2D_LOD(_AlbedoPack0, sampler_AlbedoPack0, u_xlat11.xy , u_xlat16_30);

                Nomal_Metallic_Smoothness = (SAMPLE_TEXTURE2D_LOD(_NormalPack0, sampler_NormalPack0, u_xlat11.xy , u_xlat16_30));
                NormalPack00 = UnpackNormalMainCity(Nomal_Metallic_Smoothness, _NormalScale00);
                Metallic00 = Nomal_Metallic_Smoothness.b;
                Smoothness00 = Nomal_Metallic_Smoothness.a;

                half4 AlbedoPack01;
                half3  NormalPack01;
                half  Metallic01;
                half  Smoothness01;
                float Weight01YControl = weight01.y * HeightControl1.x;
                float Weight01ZControl = weight01.z * HeightControl1.y;
                float Weight00WControl = weight00.w * HeightControl0.w;
                diffuseLocalUV.x = Weight01ZControl / (Weight01YControl + Weight01ZControl + 0.00100000005);
                diffuseLocalUV.y = (Weight01YControl + Weight01ZControl + 0.00100000005) / (Weight01YControl + Weight01ZControl + Weight00WControl + 0.00100000005);
                diffuseLocalUV.x = (diffuseLocalUV.x * u_xlat0.xx + u_xlat9.x).x;
                diffuseLocalUV.y = (diffuseLocalUV.y * u_xlat0.xx + u_xlat9.z).x;
                AlbedoPack01 = SAMPLE_TEXTURE2D_LOD(_AlbedoPack1, sampler_AlbedoPack1,diffuseLocalUV.xy,u_xlat16_30);
                //AlbedoPack01 = SAMPLE_TEXTURE2D(_AlbedoPack1, sampler_AlbedoPack1,diffuseLocalUV.xy);
                Nomal_Metallic_Smoothness = (SAMPLE_TEXTURE2D_LOD(_NormalPack1, sampler_NormalPack1, diffuseLocalUV.xy , u_xlat16_30));
                NormalPack01 = UnpackNormalMainCity(Nomal_Metallic_Smoothness, _NormalScale01);
                Metallic01 = Nomal_Metallic_Smoothness.b;
                Smoothness01 = Nomal_Metallic_Smoothness.a;

#ifndef _ENABLE_SIMPLE_TERRAIN_SHADER
                float blendValue02 = weight01.w * HeightControl1.w + totalWeight + 0.00100000005;
                float blendValue03 = weight01.x * HeightControl1.z + blendValue02;

                diffuseLocalUV.x= totalWeight / blendValue02;
                diffuseLocalUV.y = blendValue02 /blendValue03;
                diffuseLocalUV.x = (diffuseLocalUV.x * u_xlat0.xx + u_xlat9.x).x;
                diffuseLocalUV.y = (diffuseLocalUV.y * u_xlat0.xx + u_xlat9.z).x;
                half3  NormalPack02;
                half  Metallic02;
                half  Smoothness02;
                half4 AlbedoPack02 = SAMPLE_TEXTURE2D_LOD(_AlbedoPack2 ,sampler_AlbedoPack2 ,diffuseLocalUV.xy,u_xlat16_30);
                Nomal_Metallic_Smoothness = (SAMPLE_TEXTURE2D_LOD(_NormalPack2, sampler_NormalPack2, diffuseLocalUV.xy , u_xlat16_30));
                NormalPack02 = UnpackNormalMainCity(Nomal_Metallic_Smoothness, _NormalScale02);
                Metallic02 = Nomal_Metallic_Smoothness.b;
                Smoothness02 = Nomal_Metallic_Smoothness.a;
#endif
                float BlendValue00 = weight00.w * HeightControl0.w + Weight01YControl + Weight01ZControl + 0.00100000005;;
                half4 BlendAlbedoRes01 = BlendValue00 * AlbedoPack01;
                half3 BlendNormalRes01 = BlendValue00 * NormalPack01;
                half BlendMetallicRes01 = BlendValue00 * Metallic01;
                half BlendSmoothnessRes01 = BlendValue00 * Smoothness01;

                half4 BlendAlbedoRes02 = AlbedoPack00 * localHeightBlendWithWeightXYZ + BlendAlbedoRes01;
                half3 BlendNormalRes02 = NormalPack00 * localHeightBlendWithWeightXYZ + BlendNormalRes01;
                half BlendMetallicRes02 = Metallic00 * localHeightBlendWithWeightXYZ + BlendMetallicRes01;
                half BlendSmoothnessRes02 = Smoothness00 * localHeightBlendWithWeightXYZ + BlendSmoothnessRes01;





                // blend stage::
                InputData inputData;
                half weight;
                half4 mixedDiffuse;
                half4 defaultSmoothness;
                half4 albedo;
                half metallic;
                half smoothness;
                half occlusion;
    
    
#ifndef _ENABLE_SIMPLE_TERRAIN_SHADER
                half4 BlendAlbedoRes03 = AlbedoPack02 * blendValue03 + BlendAlbedoRes02;
                half3 BlendNormalRes03 = NormalPack02 * blendValue03 + BlendNormalRes02;
                half BlendMetallicRes03 = Metallic02 * blendValue03 + BlendMetallicRes02;
                half BlendSmoothnessRes03 = Smoothness02 * blendValue03 + BlendSmoothnessRes02;

                float totalValue = blendValue03 + weight00.w * HeightControl0.w + Weight01YControl + Weight01ZControl + 0.00100000005 + localHeightBlendWithWeightXYZ;
                BlendAlbedoRes03 = BlendAlbedoRes03 / totalValue;
                BlendNormalRes03 = BlendNormalRes03 / totalValue;
                //BlendNormalRes03 = normalize(BlendNormalRes03);

                albedo = BlendAlbedoRes03;
                metallic = BlendMetallicRes03;
                smoothness = BlendSmoothnessRes03;
                occlusion = BlendAlbedoRes03.a;
#else

                float totalValue = BlendValue00 + localHeightBlendWithWeightXYZ + 0.00100000005;
                BlendAlbedoRes02 = BlendAlbedoRes02 / totalValue;
                BlendNormalRes02 = BlendNormalRes02 / totalValue;
                albedo = BlendAlbedoRes02;
                metallic = BlendMetallicRes02;
                smoothness = BlendSmoothnessRes02;
                occlusion = BlendAlbedoRes02.a;
#endif




                // V2.0: global normal blend with local normal
                // using UE4 normal Blend method, ref: https://mp.weixin.qq.com/s/3cGThckJ3WE-SPnarjjPyA
                half3 detailNormal;
                half3 baseNormal = lerp(normalize(half3(0.5, 0.5, 1.0)), globalNormal, _GlobalNormalBlendRate);
#ifndef _ENABLE_SIMPLE_TERRAIN_SHADER
                detailNormal = BlendNormalRes03;
#else
                detailNormal = BlendNormalRes02;
#endif
                float3 t = baseNormal.xyz * float3( 2.0,  2.0, 2.0) + float3(-1.0, -1.0,  0);
                float3 u = detailNormal.xyz * float3(-2.0, -2.0, 2.0) + float3( 1.0,  1.0, -1.0);
                half3 normalTS = t * dot(t, u) / t.z - u;

                //normalTS = BlendNormalRes03;
                //return half4(normalTS, 1.0);
                InitializeInputData(IN, normalTS, inputData);
                float sgn = IN.tangentWS.w;      // should be either +1 or -1
                float3 bitangent = sgn * cross(IN.normal.xyz, IN.tangentWS.xyz);
                half3x3 tangentToWorld = half3x3(IN.tangentWS.xyz, bitangent.xyz, IN.normal.xyz);
                inputData.normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);


                //smoothness = 0.0f;
               // metallic = 0.5f;
                half alpha = 1.0;

                half4 color = UniversalFragmentPBR(inputData, albedo.xyz, metallic, /* specular */ half3(0.0h, 0.0h, 0.0h), smoothness, occlusion, /* emission */ half3(0, 0, 0), alpha);
                SplatmapFinalColor(color, inputData.fogCoord);

                return half4(color.xyz, 1.0h);
                //#endif
            }


#endif
