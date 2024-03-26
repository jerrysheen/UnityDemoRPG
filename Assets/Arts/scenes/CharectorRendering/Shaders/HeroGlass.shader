Shader "Elex/glass"
{
    Properties
    {

        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _MainTex ("MainTex", 2D) = "white" {}
        _MetallicTex ("_MetallicTex", 2D) = "white" {}
        _NoiseTex ("NoiseTex", 2D) = "white" {}

        _Cube ("Env Cubemap", CUBE) = "" {}

        _Glossness("_Glossness",Range(0,1)) = 1.0

        _ReflecOffset ("_ReflecOffset", Range(0,1)) = 1.0
        _Reflecfactor("_Reflecfactor",Range(0,1))=1
        _FresnelScale ("Fresnel Scale", Range(0.1, 15.0)) = 3.0
        _FresnelBias ("Fresnel Bias", Range(-5, 5.0)) = 3.0
        ratio ("ratio", Range(0, 1)) = 0.03
        _RampNoiseMin ("_RampNoiseMin", Range(-1, 0)) = 0.0
        _RampNoiseMax ("_RampNoiseMax", Range(0, 2)) = 1.0
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

            //  Blend SrcAlpha OneMinusSrcAlpha
            Zwrite Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

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
                float4 worldRef : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 worldNormal : TEXCOORD3;
                float distance : TEXCOORD4;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _NoiseTex_ST;

            float4 _Color;
            float _FresnelScale;
            float _FresnelBias;

            float _Reflecfactor, _ReflecOffset;
            float _Glossness;

            float ratio;

            CBUFFER_END


            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_MetallicTex);
            SAMPLER(sampler_MetallicTex);
            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            TEXTURECUBE(_Cube);
            SAMPLER(sampler_Cube);

            TEXTURECUBE(_AlphaCubemap);
            SAMPLER(sampler_AlphaCubemap);

            v2f vert(a2v v)
            {
                v2f o;

                VertexPositionInputs posInput = GetVertexPositionInputs(v.posOS.xyz);
                float3 worldTangent = TransformObjectToWorldDir(v.tangent.xyz);
                float3 worldNormal = TransformObjectToWorldDir(v.normal.xyz);
                float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
                o.uv.xy = TRANSFORM_TEX(v.uv, _NoiseTex);
                o.posCS = posInput.positionCS;
                o.worldPos = posInput.positionWS;
                o.worldNormal = worldNormal;
                o.distance = length(_WorldSpaceCameraPos - unity_ObjectToWorld[3].xyz);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float4 pos = ComputeScreenPos(TransformWorldToHClip((i.worldPos.xyz)));
                float2 screenPos = pos.xy / pos.w;
                float4 noiseTex = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv);
                float3 nor = UnpackNormal(noiseTex);
                nor *= ratio;
                half3 textureSample = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenPos.xy +nor.xy).rgb;;
                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                float4 metallicTex = SAMPLE_TEXTURE2D(_MetallicTex, sampler_MetallicTex, i.uv);
                _Color.a *= mainTex.a;
                _Color.rgb *= mainTex.rgb;
                float A0=metallicTex.b;
                float rougness=(1-metallicTex.a*_Glossness);
                rougness*=rougness;

                float3 normal = i.worldNormal;
                float3 viewDir = normalize(GetWorldSpaceViewDir(i.worldPos)).xyz;
                float3 reflectVec = reflect(-viewDir, normal);
                reflectVec = normalize(reflectVec + _ReflecOffset + nor);
                float3 cubeSample = SAMPLE_TEXTURECUBE_LOD(_Cube, sampler_Cube, reflectVec,rougness*9)*A0;
                //float3 alphaSample = SAMPLE_TEXTURECUBE (_AlphaCubemap, sampler_AlphaCubemap, reflectVec);
                //alphaSample = pow (alphaSample, _AlphaPower);
                float fresnel = saturate(1.0 - dot(viewDir, i.worldNormal) + 0.5);
                fresnel = (fresnel * fresnel);

                float3 finalColor = _Color.rgb * _Color.a + textureSample.rgb * (1 - _Color.a);
                finalColor += cubeSample * _Reflecfactor * fresnel;
                return half4(finalColor, 1);
            }
            ENDHLSL
        }
    }

    FallBack Off
}