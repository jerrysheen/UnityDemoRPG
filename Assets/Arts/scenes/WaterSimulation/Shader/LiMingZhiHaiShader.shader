// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "STtools/Wave_VSTexture"
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
                float4 _Azure_WaterInfo2 = float4( 9.64001, 0.29522, 0.80493, 2.36235);
                float4 _Azure_WaterInfo3 = float4(0.47582, 0.51156, 0.00, 0.47049);
                float4 _Azure_WaterInfo6 = float4(0.59965, 2.51537, 0.79, 0.00);
                float4 _PG_UVOffset  = float4(0.0, 0.0, -1.0, -1.0);
                float4 u_xlat6 = 1.0f;
                float4 u_xlat0 = 1.0f;
                float4 u_xlat1 = 1.0f;
                float4 u_xlat3 = 1.0f;
                float4 u_xlat2 = 1.0f;
                float2 u_xlat5 = 1.0f;
                float4 u_xlat11 = 1.0f;
                float4 u_xlat16_4 = 1.0f;
                float3 u_xlat16_9 = 1.0f;
                float u_xlatb15 = 0.0f;

                
                // 这个地方是不是当成了一个屏幕空间的mesh？
                float3 WorldPos = v.vertex.xzy;
                hlslcc_mtx4x4_PG_MatrixVPInverse = mul(unity_MatrixInvV, unity_CameraInvProjection);
                // float4 Local = mul(mul(unity_CameraInvProjection ,unity_MatrixInvV),float4(WorldPos,1.0));
                // Local/= Local.w;
                // u_xlat0 = Local;
                // u_xlat1 = Local;
                hlslcc_mtx4x4_PG_MatrixVPInverse = transpose(hlslcc_mtx4x4_PG_MatrixVPInverse);
                u_xlat0 = v.vertex.zzzz * hlslcc_mtx4x4_PG_MatrixVPInverse[1];
                u_xlat0 = hlslcc_mtx4x4_PG_MatrixVPInverse[0] * v.vertex.xxxx + u_xlat0;
                //u_xlat1 = u_xlat0 + hlslcc_mtx4x4_PG_MatrixVPInverse[2];
                u_xlat0 = u_xlat0 + hlslcc_mtx4x4_PG_MatrixVPInverse[3];
                u_xlat0.xyz = u_xlat0.xyz / u_xlat0.www;
                //u_xlat1 = u_xlat1 + hlslcc_mtx4x4_PG_MatrixVPInverse[3];
                //u_xlat1.xyz = u_xlat1.xyz / u_xlat1.www;
                //u_xlat1.xyz = (-u_xlat0.xyz) + u_xlat1.xyz;

                // insert -----
                //
                hlslcc_mtx4x4unity_MatrixVP = UNITY_MATRIX_VP;
                 hlslcc_mtx4x4unity_MatrixVP = transpose(hlslcc_mtx4x4unity_MatrixVP);
                //hlslcc_mtx4x4unity_MatrixVP[2][2] = - hlslcc_mtx4x4unity_MatrixVP[2][2];
                u_xlat1 = u_xlat0.yyyy * hlslcc_mtx4x4unity_MatrixVP[1];
                u_xlat1 = hlslcc_mtx4x4unity_MatrixVP[0] * u_xlat0.xxxx + u_xlat1;
                u_xlat1 = hlslcc_mtx4x4unity_MatrixVP[2] * u_xlat0.zzzz + u_xlat1;
                u_xlat1 = u_xlat1 + hlslcc_mtx4x4unity_MatrixVP[3];
                o.vertex = u_xlat1;
                return o;
                // insert -----
                //
                
                u_xlat5 = (-u_xlat0.y) + _PG_WaterRendererHeight;
                u_xlat5 = u_xlat5 / u_xlat1.y;
                u_xlat0.xz = u_xlat1.xz * float2(u_xlat5) + u_xlat0.xz;
            #ifdef UNITY_ADRENO_ES3
                u_xlatb15 = !!(u_xlat1.y<0.0);
            #else
                u_xlatb15 = u_xlat1.y<0.0;
            #endif
                u_xlat0.y = _PG_WaterRendererHeight;
                u_xlat0.xyz = bool(u_xlatb15) ? u_xlat0.xyz : float3(0.0, 0.0, 0.0);
                u_xlat1.xy = u_xlat0.xz + (-_WorldSpaceCameraPos.xz);
                u_xlat1.x = dot(u_xlat1.xy, u_xlat1.xy);
                u_xlat1.x = sqrt(u_xlat1.x);
                u_xlat1.x = u_xlat1.x + -40.0;
                u_xlat1.x = max(u_xlat1.x, 0.0);
                u_xlat1.x = min(u_xlat1.x, 80.0);
                u_xlat1.x = (-u_xlat1.x) * 0.0125000002 + 1.0;
                u_xlat6.xy = u_xlat0.xz + (-_PG_UVOffset.xy);
                u_xlat6.xy = u_xlat6.xy * float2(-0.300000012, -0.300000012);
                u_xlat2 = u_xlat6.xyxy * float4(_displacementSmallWaveScale, _displacementSmallWaveScale, _displacementBigWaveScale, _displacementBigWaveScale);
                //vs_TEXCOORD0.xy = u_xlat6.xy;
                u_xlat3.y = _Time.x * _Azure_WaterInfo6.z;
                u_xlat3.x = (-u_xlat3.y);
                u_xlat6.xy = u_xlat2.xy * float2(0.100000001, 0.100000001) + u_xlat3.xy;
                u_xlat3.xy = u_xlat3.yy * float2(1.0, -1.0);

                
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;



                u_xlat6.xy = v.uv.xy;
                o.uv = v.uv;
                //u_xlat6.xy = u_xlat6.xy * _Waves_ST.xy + _Waves_ST.zw;
                u_xlat6.xy = u_xlat6.xy * _Waves_ST.xy + float2(0.0f, _Time.x);

                u_xlat6.x = tex2Dlod(_Waves, float4(u_xlat6.xy, 0.0, 0.0f)).y * 0.5f;
                //u_xlat6.x = tex2Dlod(_Waves, float4(u_xlat6.xy, 0.0, 0.0f)).y;
                u_xlat6.x = u_xlat1.x * u_xlat6.x;
                u_xlat11.xy = u_xlat2.xy * float2(0.100000001, 0.100000001) + float2(0.5, 0.5);
                u_xlat2.xy = u_xlat2.zw * float2(0.100000001, 0.100000001);
                u_xlat2.xy = (-_Azure_WaterInfo2.ww) * _Time.xx + u_xlat2.xy;
                u_xlat2.xy = u_xlat2.xy * _Waves_ST.xy + _Waves_ST.zw;
                u_xlat2.x = tex2Dlod(_Waves, float4(u_xlat2.xy, 0.0, 0.0)).z;
                u_xlat2.x = u_xlat1.x * u_xlat2.x;
                u_xlat16_4.x = dot(u_xlat2.xxx, float3(0.300000012, 0.589999974, 0.109999999));
                u_xlat11.xy = u_xlat11.xy * float2(0.75, 0.75) + u_xlat3.xy;
                u_xlat11.xy = u_xlat11.xy * _Waves_ST.xy + _Waves_ST.zw;
                u_xlat11.x = tex2Dlod(_Waves, float4(u_xlat11.xy, 0.0, 0.0)).y;
                u_xlat16_9 = u_xlat11.x * u_xlat1.x + (-u_xlat6.x);
                u_xlat16_9 = u_xlat16_9 * 0.5 + u_xlat6.x;
                u_xlat1.x = u_xlat16_4.x * _Azure_WaterInfo3.x + u_xlat16_9;
                u_xlat16_4.y = dot(float3(u_xlat16_9), float3(0.300000012, 0.589999974, 0.109999999));
                u_xlat0.w = u_xlat1.x * _Azure_WaterInfo6.y + u_xlat0.y;
                //o.vertex = UnityWorldToClipPos(o.worldPos);
                float4x4 hlslcc_mtx4x4unity_MatrixVP = UNITY_MATRIX_VP;
                hlslcc_mtx4x4unity_MatrixVP = transpose(hlslcc_mtx4x4unity_MatrixVP);
                u_xlat1 = u_xlat0.wwww * hlslcc_mtx4x4unity_MatrixVP[1];
                u_xlat1 = hlslcc_mtx4x4unity_MatrixVP[0] * u_xlat0.xxxx + u_xlat1;
                u_xlat1 = hlslcc_mtx4x4unity_MatrixVP[2] * u_xlat0.zzzz + u_xlat1;
                u_xlat1 = u_xlat1 + hlslcc_mtx4x4unity_MatrixVP[3];
                o.vertex = u_xlat1;
                // 
                // u_xlat1 = u_xlat0.wwww * hlslcc_mtx4x4unity_MatrixVP[1];
                // u_xlat1 = hlslcc_mtx4x4unity_MatrixVP[0] * u_xlat0.xxxx + u_xlat1;
                // u_xlat1 = hlslcc_mtx4x4unity_MatrixVP[2] * u_xlat0.zzzz + u_xlat1;
                // u_xlat1 = u_xlat1 + hlslcc_mtx4x4unity_MatrixVP[3];
                // gl_Position = u_xlat1;
                
                // #ifdef _GERSTNERWAVE_ON
                //     #if _DIR_GERSTNERWAVE
                //         #ifdef _Multi_GERSTNERWAVE
                //             GerstnerWave_float(/* Inputs */  o.worldPos, _GerstnerIterNum, float2(_GerstnerDir.x, _GerstnerDir.y), _GerstnerSpeed,
                //                     /* Inputs */  _MultiGerstnerPram.x, _MultiGerstnerPram.y,
                //                     /* Inputs */  _MultiGerstnerPram.z, _MultiGerstnerPram.w,
                //                     /* Outputs */ o.worldPos, o.normal);
                //         #else
                //                 GetDirectionalGerstnerWavePos(o.worldPos, _Steepness, _Wavelength, float2(_GerstnerDir.x, _GerstnerDir.y), o.worldPos, o.normal);
                //         #endif
                //         o.vertex = UnityWorldToClipPos(o.worldPos);
                //     #else
                //         GetSimpleGerstnerWavePos(o.worldPos, _Amplitude, _Wavelength, o.worldPos, o.normal);
                //         o.vertex = UnityWorldToClipPos(o.worldPos);
                //     #endif
                // #else
                //     float3 WPos = GetSimpleSinWavePos(o.worldPos, _Amplitude,_Wavelength);
                //     o.worldPos = WPos;
                //     o.normal = normalize(RecalculateSimpleWaveNormal(o.worldPos, _Amplitude,_Wavelength));
                //     o.vertex = UnityWorldToClipPos(WPos);
                // #endif
                //o.vertex = UnityObjectToClipPos(v.vertex);
                
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
