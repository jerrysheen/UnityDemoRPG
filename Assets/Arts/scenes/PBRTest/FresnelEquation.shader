// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/FresnelEquation"
{
    Properties
    {
        _BaseColor ("Color", Color) = (1, 1, 1, 1)
        _Metalness ("_Metalness", Float) = 1.0
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 viewDir : TEXCOORD2;
                float3 normal : TEXCOORD3;
};

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _BaseColor;
            float _Metalness;

            half3 GetFresnel(float3 baseColor, float cosTheata, float metalness)
            {
                float3 F0 = 0.04f;
                F0 = lerp(F0, baseColor, metalness);
                return F0 + (1.0 - F0) * pow(1.0 - cosTheata, 5.0);
    
            }


            v2f vert(appdata_full v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.viewDir = normalize(_WorldSpaceCameraPos - worldPos);
    
                //float3 normalWorld = mul((float3x3) unity_WorldToObject, v.normal);
                float3 normalWorld = mul(v.normal, (float3x3) unity_WorldToObject);
                //normalWorld = v.normal;
                o.normal = normalize(normalWorld);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                // sample the texture
                float3 viewDir = i.viewDir;
                float3 normal = i.normal;
                //return half4(normal, 1.0f);
                fixed4 col = tex2D(_MainTex, i.uv);
                float cosTheata = saturate(dot(viewDir, normal));
                ///return half4(cosTheata.xxx, 1.0f);
                fixed3 Fresnel = GetFresnel(_BaseColor.xyz, cosTheata, _Metalness);
                return half4(Fresnel, 1.0f);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }


            ENDCG
        }
    }
}
