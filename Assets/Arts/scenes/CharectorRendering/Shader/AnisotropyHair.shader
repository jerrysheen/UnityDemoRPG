Shader "Unlit/NewUnlitShader"
{
    Properties
    {
       _MainTex ("Texture", 2D) = "white" {}
       _Color("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            struct a2v
            {
                float4 posOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 posCS : SV_POSITION;
                float4 worldPos : TEXCOORD2;

                float3 worldNormal : TEXCOORD3;
                float3 worldBinormal:TEXCOORD4;
                float3 worldTangent:TEXCOORD5;
            };
            
            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            v2f vert(a2v v)
            {
                v2f o;

                VertexPositionInputs posInput = GetVertexPositionInputs(v.posOS.xyz);
                o.posCS = posInput.positionCS;
                o.uv = v.uv;
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv) * _Color;
                float4 shadowcoord = TransformWorldToShadowCoord(i.worldPos);
                Light mainLight = GetMainLight(shadowcoord);
                float3 lightDir = normalize(mainLight.direction);
                float3 viewDir = normalize(GetWorldSpaceViewDir(i.worldPos)).xyz;
                float3 lightColor = mainLight.color;
                float3 halfVector = normalize(lightDir + viewDir); //半角向量

                float3 normal;
                    normal = UnpackNormal( SAMPLE_TEXTURE2D(_NormalMap,sampler_NormalMap, i.uv.xy));
                    float3x3 TBN = float3x3(normalize(i.worldTangent), normalize(i.worldBinormal), normalize(i.worldNormal));
                    TBN = transpose(TBN);
                    normal=mul(TBN,normal);
                    normal=normalize(normal);

               float roughness = 0.5f;
                    half aspect = sqrt(_Anisotropy * 0.99f);
                    half anisoXRoughness = max(0.01f, roughness / aspect);
                    half anisoYRoughness = max(0.01f, roughness * aspect);
                    float3 binormal=normalize(cross(normal,i.worldTangent));
                    float3 tannormal=normalize(cross(normal,binormal));
                    
           
                  tannormal=normalize(tannormal+_comb.xyz);
                    half NDF0 = D_GGXaniso(anisoXRoughness, anisoYRoughness, vh, halfVector,tannormal,binormal);
                //return half4(NDF0.xxx, 1.0f);
                    half NDF1 = D_GGXaniso(anisoXRoughness, anisoYRoughness,1, halfVector, tannormal, binormal);
                    half ndfs = (NDF0*NDF1)*_specBoardLine;
                   
                    // half NDF3 = D_GGXaniso(anisoXRoughness, anisoYRoughness, nh, halfVector,tannormal,binormal);
                    // half NDF4= D_GGXaniso(anisoXRoughness, anisoYRoughness,1, halfVector, tannormal, binormal);
                    // half ndfs2 = (NDF3*NDF4)*_specBoardLine;

                
                    D=ndfs*nl;
                   // D+=ndfs2*0.5*nl;

              
              
                return col;
            }
            ENDHLSL
        }
    }

    FallBack Off
}