Shader "Custom/EdgeGlowShader"
{
    Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {}
        _RimColor ("Edge Color", Color) = (1, 0, 0, 1)
        // _EdgeThickness 控制边缘光粗细，推荐范围1~10，值越大边缘光越细
        _RimWidth ("_RimWidth", Range(0,1)) = 0.5
        _RimSmoothness ("_RimSmoothness", Range(0,1)) = 0.3
        _RimIntensity ("_RimIntensity", Range(0,50)) = 3
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _RimColor;
            float _EdgeThickness;
            float _RimWidth; 
            float _RimSmoothness;
            float _RimIntensity;
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv     : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv         : TEXCOORD0;
                float4 pos        : SV_POSITION;
                float3 worldNormal: TEXCOORD1;
                float3 worldPos   : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                // 转换为裁剪空间坐标
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                // 获取世界空间法线
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                // 获取世界空间顶点坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 采样基础纹理颜色
                fixed4 baseCol = tex2D(_MainTex, i.uv);
                float4 Rim = float4(0,0,0,0);
                float3 viewDirWS = _WorldSpaceCameraPos;
                float rim = 1.0 - saturate(dot(viewDirWS, i.worldNormal));//法线与视线垂直的地方边缘光强度最强 
                rim = smoothstep(1-_RimWidth, 1, rim); 
                rim = smoothstep(0, _RimSmoothness, rim);
                float4 finalCol = rim;
                Rim = rim * _RimColor * _RimIntensity;
                finalCol = lerp(baseCol, _RimColor, rim);
                //float4 RimBrush = tex2D(_RimBrushPatterns, input.uv * _RimBrushPatterns_ST.xy + _RimBrushPatterns_ST.zw); 
                //Rim = lerp(Rim, RimBrush * Rim, _RimBrushStrengh); 
                //Rim *= Mask.g;
                
                // 将基础颜色和边缘光颜色按 Fresnel 值进行混合
                //fixed4 finalCol = baseCol * Rim;

                return finalCol;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
