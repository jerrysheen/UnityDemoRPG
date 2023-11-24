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
        _Color1 ("_Color1", Color) =  (0.0, 0.0, 0.0, 0.0)
        _Color2 ("_Color2", Color) =  (0.0, 0.0, 0.0, 0.0)
          
//        _GerstnerIterNum ("_MultiGerstnerPram", Int) = 64
        _CameraDistance ("_CameraDistance", Float) = 1.0
        _CameraRelatedFadeRange("_CameraRelatedFadeRange", Float) = 1.0
        _CameraRelatedClipRange("_CameraRelatedClipRange", Vector) =  (0.5, 0.5, 0.0, 0.0)
        //_GerstnerSpeed ("_MultiGerstnerPram", Float) = 1.0
//        _GerstnerDir ("_MultiGerstnerPram", Vector) = (0.5, 0.5, 0.0, 0.0)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Pass {
             Stencil
             {
                Ref 2
                Comp Always
                Pass Replace
             }
            
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
            float4 _Color1;
            float4 _Color2;
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

            float _CameraDistance;
            float _CameraRelatedFadeRange;
            float4 _CameraRelatedClipRange;

            
            v2f vert (appdata v) {
                v2f o;
                // float4 _Azure_WaterInfo2 = float4( 9.64001, 0.29522, 0.80493, 2.36235);
                // float4 _Azure_WaterInfo3 = float4(0.47582, 0.51156, 0.00, 0.47049);
                // float4 _Azure_WaterInfo6 = float4(0.59965, 2.51537, 0.79, 0.00);
                float4 _PG_UVOffset  = float4(0.0, 0.0, -1.0, -1.0);
                
                float3 worldPos = mul(unity_ObjectToWorld, half4(v.vertex.xyz, 1.0f)).xyz;

                float3 distance = (worldPos - _WorldSpaceCameraPos);
                float d = sqrt(dot(distance, distance));
                d -= _CameraRelatedFadeRange;
                d = max(d, _CameraRelatedClipRange.x);
                d = min(d, _CameraRelatedClipRange.y);
                d /= _CameraRelatedClipRange.y;
                d = 1.0 - d;

                float3 u_xlat6;
                float3 u_xlat1;
                float4 u_xlat2;
                float3 u_xlat3;
                float3 u_xlat11;
                float3 u_xlat16_4;
                float3 u_xlat16_9;
                u_xlat1.x = d;
                
                u_xlat6.xy = worldPos.xz + (-_PG_UVOffset.xy);
                u_xlat6.xy = u_xlat6.xy * float2(-0.300000012, -0.300000012);
                u_xlat2 = u_xlat6.xyxy * float4(_displacementSmallWaveScale, _displacementSmallWaveScale, _displacementBigWaveScale, _displacementBigWaveScale);
                float time = _Time.x * 0.1;
                u_xlat3.y = time * _Azure_WaterInfo6.z;
                u_xlat3.x = (-u_xlat3.y);
                u_xlat6.xy = u_xlat2.xy * float2(0.100000001, 0.100000001) + u_xlat3.xy;
                u_xlat3.xy = u_xlat3.yy * float2(1.0, -1.0);
                u_xlat6.xy = u_xlat6.xy * _Waves_ST.xy + _Waves_ST.zw;

                u_xlat6.x = tex2Dlod(_Waves, float4(u_xlat6.xy, 0.0, 0.0f)).y    ;
                u_xlat6.x = u_xlat1.x * u_xlat6.x;
                u_xlat11.xy = u_xlat2.xy * float2(0.100000001, 0.100000001) + float2(0.5, 0.5);
                u_xlat2.xy = u_xlat2.zw * float2(0.100000001, 0.100000001);
                u_xlat2.xy = (-_Azure_WaterInfo2.ww) * time.xx + u_xlat2.xy;
                u_xlat2.xy = u_xlat2.xy * _Waves_ST.xy + _Waves_ST.zw;
                u_xlat2.x = tex2Dlod(_Waves, float4(u_xlat2.xy, 0.0, 0.0f)).z ;
                u_xlat2.x = u_xlat1.x * u_xlat2.x;
                u_xlat16_4.x = dot(u_xlat2.xxx, float3(0.300000012, 0.589999974, 0.109999999));
                u_xlat11.xy = u_xlat11.xy * float2(0.75, 0.75) + u_xlat3.xy;
                u_xlat11.xy = u_xlat11.xy * _Waves_ST.xy + _Waves_ST.zw;
                u_xlat11.x = tex2Dlod(_Waves, float4(u_xlat11.xy, 0.0, 0.0f)).y;
                 //wave0.xy*=5;
                //wave0.xy*=abs(_SinTime.xz);
                u_xlat16_9 = u_xlat11.x * u_xlat1.x + (-u_xlat6.x);
                u_xlat16_9 = u_xlat16_9 * 0.5 + u_xlat6.x;
                u_xlat1.x = u_xlat16_4.x * _Azure_WaterInfo3.x + u_xlat16_9;
                u_xlat16_4.y = dot(float3(u_xlat16_9), float3(0.300000012, 0.589999974, 0.109999999));
                //vs_TEXCOORD0.zw = u_xlat16_4.xy;
                //u_xlat0.w = u_xlat1.x * _Azure_WaterInfo6.y + u_xlat0.y;
                worldPos.y += u_xlat1.x * _Azure_WaterInfo6.y;
                
                // worldPos.x += wave0.x;
                // worldPos.z += wave0.y;
                o.worldPos = worldPos;
                o.vertex = UnityWorldToClipPos(worldPos);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
               float3 ddxPos = normalize(ddx(i.worldPos));
               float3 ddyPos = normalize(ddy(i.worldPos));
               float3 normal = normalize( cross(ddyPos, ddxPos));
               
                //return half4(normal, 1.0f);
                // Normalized direction to the light source
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                // Calculate the Blinn-Phong reflection model
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                //
                float3 halfDir = normalize(lightDir + viewDir);
                float diff = max(0.0, dot(normal, lightDir));
                float spec = pow(max(0.0, dot(normal, halfDir)), _Shininess * 128.0);
                
                float waveHeight = saturate(i.worldPos.y/1.0f);
                //col.rgb =  ;
                // Combine the textures and light effects
                //fixed4 col = tex2D(_MainTex, i.vertex.xy) * _Color;
                fixed4 col =  _Color1;
                float3 _LightColor0 = float3(1.0, 1.0, 1.0);
                col.rgb *= _LightColor0.rgb * diff; // Diffuse lighting
                col.rgb += _Specular.rgb * _LightColor0.rgb * spec; // Specular lighting
                return col;
            }
            ENDCG
        }
    }
}
