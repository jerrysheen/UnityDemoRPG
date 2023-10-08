Shader "SSS/Skin" 
{
    Properties 
    {         
        _MainTex ("MainTexture", 2D) = "white" {}
        _MainNormalTex ("NormalTex", 2D) = "white" {}
        _SmoothTex ("SmoothTex", 2D) = "white" {}
        _CurveTex ("CurveTex", 2D) = "white" {}
        _SSSLUT ("SSSLUT", 2D) = "white" {}
        _KelemenLUT ("KelemenLUT", 2D) = "white" {}
		[KeywordEnum(OFF,ON)]SSS("SSS Mode",Float) = 1
		[KeywordEnum(Const,Calu,Tex)] Curve("Use Curve Tex",Float) = 1
		_CurveFactor("CurveFactor",Range(0,5)) = 1
		[KeywordEnum(Off,BlinPhong,Kelemen)] Spec("Specular Mode",Float) = 1
		_SpecularScale("SpecularScale", Range(0,5)) = 1
		[KeywordEnum(None, Curve, Specular)] Debug ("Debug Mode", Float) = 0
    }

    SubShader 
    {
        Tags{
        	"RenderType"="Opaque"
        	"RenderPipeline" = "UniversalPipeline"
        	}
		Pass 
		{
			Tags { "LightMode"="ForwardBase"}
			CGPROGRAM
		    #pragma target 3.0
			#pragma vertex vert_new
			#pragma fragment frag_new
            #pragma multi_compile_fwdbase
			#pragma multi_compile SSS_OFF SSS_ON SSS_BLENDNORMAL
			#pragma multi_compile CURVE_CONST CURVE_CALU CURVE_TEX
			#pragma multi_compile SPEC_OFF SPEC_BLINPHONG SPEC_KELEMEN
			#pragma multi_compile DEBUG_NONE DEBUG_CURVE DEBUG_SPECULAR

			#include "UnityCG.cginc"
            #include "AutoLight.cginc"		
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _MainNormalTex;
			float4 _MainNormalTex_ST;
			sampler2D _SmoothTex;
			sampler2D _CurveTex;
			sampler2D _SSSLUT;
			sampler2D _KelemenLUT;
			float _SpecularScale;
			float _CurveFactor;

            float4 _LightColor0;
			
			struct v2f_new
			{
                float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;	
                float4 T2W0 :TEXCOORD1;
                float4 T2W1 :TEXCOORD2;
                float4 T2W2 :TEXCOORD3;	
                LIGHTING_COORDS(4, 5)	
			};
			
			v2f_new vert_new(appdata_full v)
			{
				v2f_new o;				
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord,_MainNormalTex);

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent);
                float3 worldBitangent = cross(worldNormal ,worldTangent) * v.tangent.w;

                o.T2W0 = float4 (worldTangent.x,worldBitangent.x,worldNormal.x,worldPos .x);
                o.T2W1 = float4 (worldTangent.y,worldBitangent.y,worldNormal.y,worldPos .y);
                o.T2W2 = float4 (worldTangent.z,worldBitangent.z,worldNormal.z,worldPos .z);
				
				TRANSFER_VERTEX_TO_FRAGMENT(o);

				return o;
			}

//			inline float fresnelReflectance( float3 H, float3 V, float F0 )
//			{
//				float base = 1.0 - dot( V, H );
//				float exponential = pow( base, 5.0 );
//				return exponential + F0 * ( 1.0 - exponential );
//			}

			half4 frag_new(v2f_new i) : SV_Target
			{
				fixed4 ambient = UNITY_LIGHTMODEL_AMBIENT;//环境光
                fixed attenuation = LIGHT_ATTENUATION(i);//投影
				float3 albedo = tex2D(_MainTex,i.uv.xy).rgb;

                float3 worldPos  = float3(i.T2W0.w,i.T2W1.w,i.T2W2.w);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				
				fixed4 tangentNormal = tex2D(_MainNormalTex,i.uv.zw);
                fixed3 bump = UnpackNormal(tangentNormal);
                fixed3 worldBump = normalize(half3( dot(i.T2W0.xyz,bump),
                                                    dot(i.T2W1.xyz,bump),
                                                    dot(i.T2W2.xyz,bump)));

				#ifdef CURVE_CONST
					fixed cuv = _CurveFactor;
				#else
					#ifdef CURVE_TEX
						fixed cuv = tex2D(_CurveTex,i.uv.zw);
					#else
						fixed3 worldShapeBump = normalize(float3(i.T2W0.z,i.T2W1.z,i.T2W2.z));
						fixed cuv = saturate(_CurveFactor * 0.01 * (length(fwidth(worldShapeBump)) / length(fwidth(worldPos))));
					#endif
				#endif

				#ifdef SSS_OFF
					fixed NoL = dot(worldBump,lightDir);	
					fixed3 diffuse = max(0,NoL);
				#else
					fixed NoL = dot(worldBump,lightDir);	
					fixed3 diffuse = tex2D(_SSSLUT,float2(NoL*0.5+0.5,cuv));
				#endif

				half3 h = lightDir + viewDir;
                half3 H = normalize(h);
				fixed NoH = dot(worldBump,H);	
                fixed smooth = tex2D(_SmoothTex,i.uv.zw).r;
				#ifdef SPEC_OFF
					fixed3 specular = 0;
				#else
					#ifdef SPEC_BLINPHONG
						fixed3 specular = pow(max(0,NoH),10.0) * smooth * _SpecularScale;
					#else
						float PH = pow(2.0 * tex2D(_KelemenLUT,float2(NoH, smooth)), 10.0 );
						fixed F = 0.028;//fresnelReflectance( H, viewDir, 0.028 );
						half3 specular = max( PH * F / dot( h, h ), 0 ) * _SpecularScale;
					#endif
                #endif
                fixed3 finalColor = (ambient + (diffuse + specular) * _LightColor0.rgb * attenuation) * albedo;

				#ifdef DEBUG_CURVE
					return fixed4(cuv,cuv,cuv,1);
				#else
					#ifdef DEBUG_SPECULAR
						return fixed4(specular,1);
					#else
						return fixed4(finalColor,1);
					#endif
				#endif
			}
			ENDCG
		}
    }
    FallBack "Diffuse"    
}