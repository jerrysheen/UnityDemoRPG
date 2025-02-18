// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/SDFShaderTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _InnerColor ("实心颜色", Color) = (1,1,1,1)
        _InnerGradiantSize ("实心渐变范围", Float) = 0
        _InnerRange ("实心颜色区域", Float) = 1
        _OutlineColor ("外描边颜色", Color) = (1,1,1,1)
        _OuterGradiantSize ("外描边渐变范围", Float) = 1
        _OutlineRange ("外描边宽度", Float) = 1
        _ShadowOffsetX ("阴影偏移方向X", Float) = 0
        _ShadowOffsetY ("阴影偏移方向Y", Float) = 0
        _ShadowRange ("阴影宽度", Float) = 0
        _ShadowGradiantSize ("阴影渐变范围", Float) = 0
        _ShadowColor ("阴影颜色", Color) = (1,1,1,1)

    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float2 texcoord : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainColor;
            float4 _InnerColor;
            float _InnerRange;
            float _InnerGradiantSize;
            
            float4 _OutlineColor;
            float _OuterGradiantSize;
            float _OutlineRange;

            float4 _ShadowColor;
            float _ShadowOffsetX;
            float _ShadowOffsetY;
            float _ShadowRange;
            float _ShadowGradiantSize;

            
            v2f vert(appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.texcoord);
                float distance = col.r;
                // // do some anti-aliasing
                // col.a = 1 - smoothstep(_DistanceMark - _OuterGradiantSize, _DistanceMark + _OuterGradiantSize, distance);
                // col.rgb = _MainColor.rgb;

                // 描边outline写法：
                	fixed4 outlineCol;

	                outlineCol.a = 1 - smoothstep(_OutlineRange - _OuterGradiantSize, _OutlineRange + _OuterGradiantSize, distance);
	                outlineCol.rgb = _OutlineColor.rgb;
	                col.a = 1 - smoothstep(_InnerRange - _InnerGradiantSize, _InnerRange + _InnerGradiantSize, distance);
	                col.rgb = _InnerColor.rgb;

                col = lerp(outlineCol, col, col.a);

                // 添加阴影：
                float shadowDistance = tex2D(_MainTex, i.texcoord + half2(_ShadowOffsetX, _ShadowOffsetY));
                float shadowAlpha = 1 - smoothstep(_ShadowRange - _ShadowGradiantSize, _ShadowRange + _ShadowGradiantSize, shadowDistance);
                fixed4 shadowCol = fixed4(_ShadowColor.rgb, _ShadowColor.a * shadowAlpha);

                return lerp(shadowCol, col, col.a);
                return col;
            }
            ENDCG
        }
    }
}
