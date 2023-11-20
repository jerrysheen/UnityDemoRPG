// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "STtools/Wave_VSTexture02"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Waves ("Texture", 2D) = "white" {}
//        _Wavelength ("_Wavelength", Float) = 1.0
//        _Steepness ("steepness", Float) = 1.0
//        [MaterialToggle(_GERSTNERWAVE_ON)] _Toggle0("Enable GerstnerWave", Float) = 0
//        [MaterialToggle(_DIR_GERSTNERWAVE)] _Toggle1("Enable Dir GerstnerWave", Float) = 0
//        [MaterialToggle(_Multi_GERSTNERWAVE)] _Toggle2("Multi Dir GerstnerWave", Float) = 0
        _Azure_WaterInfo2 ("_Azure_WaterInfo2", Vector) = ( 9.64001, 0.29522, 0.80493, 2.36235)
        _Azure_WaterInfo3 ("_Azure_WaterInfo3", Vector) = (0.47582, 0.51156, 0.00, 0.47049)
        _Azure_WaterInfo6 ("_Azure_WaterInfo6", Vector) = (0.59965, 2.51537, 0.79, 0.00)
        _PG_UVOffset ("_PG_UVOffset", Vector) = (0.0, 0.0, -1.0, -1.0)
        _displacementSmallWaveScale ("_displacementSmallWaveScale", Float) = 0.162
        _displacementBigWaveScale ("_displacementBigWaveScale", Float) = 0.7
        _PG_WaterRendererHeight ("_PG_WaterRendererHeight", Float) =  83.0
          
//        _GerstnerIterNum ("_MultiGerstnerPram", Int) = 64
//        _GerstnerSpeed ("_MultiGerstnerPram", Float) = 1.0
//        _GerstnerDir ("_MultiGerstnerPram", Vector) = (0.5, 0.5, 0.0, 0.0)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _  _GERSTNERWAVE_ON
            #pragma multi_compile _  _DIR_GERSTNERWAVE
            #pragma multi_compile _  _Multi_GERSTNERWAVE


            #define PI 3.1415926
            #define G 0.98
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float3 normal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float4 uv : TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _Waves;
            float4 _MainTex_ST;
            float4 _Waves_ST;
            float4 _Color;
            float4 _Specular;
            float4 _MultiGerstnerPram;
            float4 _GerstnerDir;
            float4 _Azure_WaterInfo2;
            float4 _Azure_WaterInfo3;
            float4 _Azure_WaterInfo6;
            float4 _PG_UVOffset;
            float4x4 hlslcc_mtx4x4_PG_MatrixVPInverse;
            float4x4 hlslcc_mtx4x4unity_MatrixVP;
            float _displacementSmallWaveScale;
            float _displacementBigWaveScale;
            float _PG_WaterRendererHeight;
            
            uint _GerstnerIterNum;
            float _GerstnerSpeed;
            
            float _Shininess;

            float _Amplitude;
            float _Wavelength;
            float _Steepness;

            
            v2f vert (appdata v) {
                v2f o;

                float4 wave0 = 0.0f;
                float2 wave0UV = v.uv.xy * _Azure_WaterInfo2.xy + float2(_Time.x * _Azure_WaterInfo2.zw);
                wave0.x = tex2Dlod(_Waves, float4(wave0UV, 0.0, 0.0f)).y * _PG_UVOffset.x;

                float2 wave1UV = v.uv.xy * _Azure_WaterInfo3.xy + float2(_Time.x * _Azure_WaterInfo3.zw);
                wave0.y = tex2Dlod(_Waves, float4(wave1UV, 0.0, 0.0f)).y * _PG_UVOffset.y;

                float2 wave2UV = v.uv.xy * _Azure_WaterInfo6.xy + float2(_Time.x * _Azure_WaterInfo6.zw);
                wave0.z = 2.0f * (1.0 - tex2Dlod(_Waves, float4(wave2UV, 0.0, 0.0f)).z) * _PG_UVOffset.z;
                
                float3 worldPos = mul(unity_ObjectToWorld, half4(v.vertex.xyz, 1.0f)).xyz;
                worldPos.y += wave0.z +  wave0.x + wave0.y;
                o.vertex = UnityWorldToClipPos(worldPos);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                return half4(0.9f, 0.9f, 0.9f, 1.0f);
                //return half4(i.normal, 1.0f);
                // Normalized direction to the light source
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                // Calculate the Blinn-Phong reflection model
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

                float3 halfDir = normalize(lightDir + viewDir);
                float diff = max(0.0, dot(i.normal, lightDir));
                float spec = pow(max(0.0, dot(i.normal, halfDir)), _Shininess * 128.0);

                // Combine the textures and light effects
                //fixed4 col = tex2D(_MainTex, i.vertex.xy) * _Color;
                fixed4 col = 1.0f;
                float3 _LightColor0 = float3(1.0, 1.0, 1.0);
                col.rgb *= _LightColor0.rgb * diff; // Diffuse lighting
                col.rgb += _Specular.rgb * _LightColor0.rgb * spec; // Specular lighting
                return col;
            }
            ENDCG
        }
    }
}
