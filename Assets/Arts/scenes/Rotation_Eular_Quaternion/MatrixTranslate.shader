Shader "Unlit/MatrixTranslate"
{
    Properties
    {
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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            uniform float4x4 _LocalToWorldMatrix;
            uniform float4x4 _ViewMatrix;
            uniform float4x4 _ProjectionMatrix;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                //o.vertex = mul(_ProjectionMatrix, mul(_ViewMatrix, mul(_LocalToWorldMatrix, float4(v.vertex.xyz, 1.0f))));
                //o.vertex = mul(UNITY_MATRIX_V, (mul(UNITY_MATRIX_P, mul(_LocalToWorldMatrix, float4(v.vertex.xyz, 1.0f)))));
    o.vertex = mul(UNITY_MATRIX_P, (mul(_ViewMatrix, mul(_LocalToWorldMatrix, float4(v.vertex.xyz, 1.0f)))));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
