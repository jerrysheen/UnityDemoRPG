Shader "Unlit/TownScaper"
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

            void TownScaper_ConvertUV_ToTileUVs(in float2 UV0, out float2 TileUVs)
            {
                TileUVs = frac(UV0) * 128.0f + 0.6f;
            }

void TownScaperEvenOddUV(in float2 SpecialUV, out float2 SpecialEvenOdd)
{
    float GapDistance = 0.1f;
    SpecialEvenOdd = floor(min(0.0f, frac(SpecialUV / 2.0f) - GapDistance));
}


void TownScaperTileLookUp(in float2 SpecialUV, in float2 SpecialEvenOdd, in sampler2D Texture2D_TownColor, out half4 LookUpColor)
{
    float2 UVScaled;
    UVScaled = floor(SpecialUV / 2.0f) * 2.0f + SpecialEvenOdd + 0.5f;
    UVScaled /= 128.0f;
    LookUpColor = tex2D(Texture2D_TownColor, UVScaled);
}


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
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
    half4 result;
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
    float2 SpecialUV;
                float2 SpecialEvenOdd;
    TownScaper_ConvertUV_ToTileUVs(i.uv, SpecialUV);
    TownScaperEvenOddUV(SpecialUV, SpecialEvenOdd);
    TownScaperTileLookUp(SpecialUV, SpecialEvenOdd, _MainTex, result);
    return result;
}

            ENDCG
        }
    }
}
