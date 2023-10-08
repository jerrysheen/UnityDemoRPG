Shader "SSS/SkinBake" 
{
	Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_CurveFactor("CurveFactor",Range(0,5)) = 1
	}
	
	CGINCLUDE
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		uniform half4 _MainTex_TexelSize;
		half4 _MainTex_ST;
		
		uniform half _CurveFactor;
	
		// weight curves
		static const half weight[5][5] = {{0.0030,0.0133,0.0219,0.0133,0.0030},
										  {0.0133,0.0596,0.0983,0.0596,0.0133},
										  {0.0219,0.0983,0.1621,0.0983,0.0219},
										  {0.0133,0.0596,0.0983,0.0596,0.0133},
										  {0.0030,0.0133,0.0219,0.0133,0.0030}};
		
		struct v2f
		{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			float3 vertex : TEXCOORD1;
			float3 normal : TEXCOORD2;
		};

		struct v2f_out 
		{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
		};	

		v2f vert (appdata_full v)
		{
			v2f o;
			
			o.uv = fmod(v.texcoord.xy,1);
			o.pos = float4(o.uv * 2 - 1,0,1);
			o.pos.y = -o.pos.y;
			o.vertex = v.vertex.xyz;
			o.normal = v.normal;

			return o; 
		}	

		fixed4 frag (v2f i ) : SV_Target
		{
			float3 worldPos = i.vertex;
			float3 worldBump = normalize(i.normal);
			float cuv = length(fwidth(worldBump)) / length(fwidth(worldPos)) / 10000 * _CurveFactor;
			return fixed4(cuv,cuv,cuv,1);
		}

		v2f_out vertBlur (appdata_img v)
		{
			v2f_out o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = v.texcoord.xy;
			return o; 
		}

		fixed4 fragBlur (v2f_out In) : SV_Target
		{
			float result = 0;
			for (int i = 0;i < 5;i++)
			{
				for (int j = 0;j < 5;j++)
				{
				    half2 newUv = In.uv + float2(i - 2,j - 2) * _MainTex_TexelSize.xy * 2;
					result += tex2D(_MainTex, newUv).r * weight[i][j] ;
				}
			}
			return fixed4(result,result,result,1);
		}		
	ENDCG
	
	SubShader 
	{
		ZTest Off Cull Off ZWrite Off Blend Off
		Pass {
		CGPROGRAM 
		
		#pragma vertex vert
		#pragma fragment frag
		
		ENDCG 
		}	
		Pass {
		CGPROGRAM 
		
		#pragma vertex vertBlur
		#pragma fragment fragBlur
		
		ENDCG 
		}	
	}
	FallBack Off
}

