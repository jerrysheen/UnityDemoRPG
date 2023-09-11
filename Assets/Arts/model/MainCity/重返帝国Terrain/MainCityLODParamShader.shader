Shader "STTools/MainCityLODParamShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LODScale ("_LODScale", Range(0.0, 10.0)) = 3.0
        _LODPram ("_LODPram", Range(0.0, 5.0)) = 1.0
        _LODAdd ("_LODAdd", Range(0.0, 10.0)) = 1.0
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
                float4 miplut : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
                float _LODPram;
                float _LODScale;
                float _LODAdd;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 dx = ddx(i.uv  * _MainTex_TexelSize.zw );
                float2 dy = ddy(i.uv* _MainTex_TexelSize.zw);
                float2 rho = max(sqrt(dot(dx, dx)), sqrt(dot(dy, dy)));

                float lambda = log2(_LODPram * rho - _LODScale).x;
                //lambda = lambda > 0.0 ? lambda : 0.0;
                float LODLevel = max(int(lambda + _LODAdd), 0);
                LODLevel = LODLevel > 0.0 ? LODLevel : 0.0;
                return half4(LODLevel/ 10.0f,LODLevel/ 10.0f,LODLevel/ 10.0f, 1.0f);
                // o.miplut.xy = uvx;
                // o.miplut.zw = uvy;
                // sample the texture
                return i.miplut;
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
