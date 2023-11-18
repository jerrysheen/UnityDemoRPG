// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "STtools/WaveShader"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
        _Amplitude ("_Amplitude", Float) = 1.0
        _Wavelength ("_Wavelength", Float) = 1.0
        _Steepness ("steepness", Float) = 1.0
        [MaterialToggle(_GERSTNERWAVE_ON)] _Toggle0("Enable GerstnerWave", Float) = 0
        [MaterialToggle(_DIR_GERSTNERWAVE)] _Toggle1("Enable Dir GerstnerWave", Float) = 0
        [MaterialToggle(_Multi_GERSTNERWAVE)] _Toggle2("Multi Dir GerstnerWave", Float) = 0
        _MultiGerstnerPram ("_MultiGerstnerPram", Vector) = (0.1, 0.3, 0.3, 0.3)
        _GerstnerIterNum ("_MultiGerstnerPram", Int) = 64
        _GerstnerSpeed ("_MultiGerstnerPram", Float) = 1.0
        _GerstnerDir ("_MultiGerstnerPram", Vector) = (0.5, 0.5, 0.0, 0.0)

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
                float3 normal : NORMAL;
            };

            struct v2f {
                float3 normal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float4 _Specular;
            float4 _MultiGerstnerPram;
            float4 _GerstnerDir;
            uint _GerstnerIterNum;
            float _GerstnerSpeed;
            
            float _Shininess;

            float _Amplitude;
            float _Wavelength;
            float _Steepness;

            float3 GetSimpleSinWavePos(float3 worldPos, float amplitude, float waveLength)
            {
                float k = 2 * PI / waveLength;
                float w = sqrt(G * k);
                worldPos.y = amplitude * sin(k * worldPos.x - w * _Time.y);
                return worldPos;
            }


            void GetSimpleGerstnerWavePos(/* Inputs */  float3 positionIn, float amplitude, float wavelength,
                                    /* Outputs */ out float3 positionOut, out float3 normalOut)
            {
                positionOut = positionIn;
                
                // k: wavenumber
                // l: wavelength
                // k = 2 * PI / l
                // w = sqrt(G * k)
                
                float k = 2 * PI / wavelength;
                float w = sqrt(G * k);
                float value = k * positionOut.x - w * _Time.y;
                positionOut.x += amplitude * cos(value);
                positionOut.y = amplitude * sin(value);

                float3 bitangent = float3(1 - k * amplitude * sin(value), k * amplitude * cos(value), 0.0f);
                float3 tangent = float3(0.0f, 0.0f, 1.0f);
                normalOut = cross(tangent, bitangent);
            }

            void GetDirectionalGerstnerWavePos(/* Inputs */  float3 positionIn, float steepness, float wavelength, float2 WaveDir,
                                    /* Outputs */ out float3 positionOut, out float3 normalOut)
            {

                positionOut = positionIn;

                float2 direction = normalize(float2(WaveDir.x, WaveDir.y));
                
                float k = 2 * PI / wavelength;
                float w = sqrt(G * k);
                float amplitude = steepness / k;
                float2 wavevector = k * direction;
                float value = dot(wavevector, positionOut.xz) - w * _Time.y;
                
                positionOut.x += direction.x * amplitude * cos(value);
                positionOut.z += direction.y * amplitude * cos(value);
                positionOut.y = amplitude * sin(value);

                float3 bitangent = float3(1 - direction.x * direction.x * k * amplitude * sin(value),
                    direction.x * k * amplitude * cos(value),
                    direction.x * direction.y * k * amplitude * -sin(value));
                float3 tangent = float3(direction.x * direction.y * k * amplitude * -sin(value),
                    direction.y * k * amplitude * cos(value),
                    1 - direction.y * direction.y * k * amplitude * sin(value));
                normalOut = cross(tangent, bitangent);
            }
            
                        
            float3 RecalculateSimpleWaveNormal(float3 worldPos, float amplitude, float waveLength)
            {

                float k = 2 * PI / waveLength;
                float w = sqrt(G * k);
                // sin(kx) partial = kcos(x)
                float value = k * worldPos.x - w * _Time.y;
                float3 bitangent = normalize(float3(1.0f, k * amplitude * cos(value), 0.0f));
                float3 tangent = float3(0.0f, 0.0f, 1.0f);
                return cross(tangent, bitangent);
            }



            void GerstnerWave_float(/* Inputs */  float3 positionIn, uint waveCount, float2 direction, float speed,
                                    /* Inputs */  float wavelengthMin, float wavelengthMax,
                                    /* Inputs */  float steepnessMin, float steepnessMax,
                                    /* Outputs */ out float3 positionOut, out float3 normalOut)
            {
                float x = 0, y = 0, z = 0;
                float bx = 0, by = 0, bz = 0;
                float tx = 0, ty = 0, tz = 0;
                positionOut = positionIn;

                int randX = 0;
                int randY = 0;
                for (uint i = 0; i < waveCount; i++)
                {
                    float step = (float) i / (float) waveCount;

                    randX = (randX * 1103515245) + 12345;
                    randY = (randY * 1103515245) + 12345;
                    
                    float2 d = float2(sin((float)randX / 801571.f), cos((float)randY / 10223.f));
                    d = normalize(lerp(normalize(direction), d * 2.0f - 1.0f, 0.8f));

                    step = pow(step, 0.75f);
                    float wavelength = lerp(wavelengthMax, wavelengthMin, step);
                    float steepness = lerp(steepnessMax, steepnessMin, step);

                    float k = 2 * PI / wavelength;
                    float w = sqrt(G * k);
                    float a = steepness / k;
                    float2 wavevector = k * d;
                    float value = dot(wavevector, positionIn.xz) - w * _Time.y * (speed * 0.1f);

                    x += d.x * a * cos(value);
                    z += d.y * a * cos(value);
                    y += a * sin(value);

                    bx += d.x * d.x * k * a * -sin(value);
                    by += d.x * k * a * cos(value);
                    bz += d.x * d.y * k * a * -sin(value);

                    tx += d.x * d.y * k * a * -sin(value);
                    ty += d.y * k * a * cos(value);
                    tz += d.y * d.y * k * a * -sin(value);
                }
                
                positionOut.x = positionIn.x + x;
                positionOut.z = positionIn.z + z;
                positionOut.y = y;

                float3 bitangent = normalize(float3(1 - saturate(bx), by, bz));
                float3 tangent = normalize(float3(tx, ty, 1 - saturate(tz)));
                normalOut = cross(tangent, bitangent);
            }
            
            v2f vert (appdata v) {
                v2f o;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                #ifdef _GERSTNERWAVE_ON
                    #if _DIR_GERSTNERWAVE
                        #ifdef _Multi_GERSTNERWAVE
                            GerstnerWave_float(/* Inputs */  o.worldPos, _GerstnerIterNum, float2(_GerstnerDir.x, _GerstnerDir.y), _GerstnerSpeed,
                                    /* Inputs */  _MultiGerstnerPram.x, _MultiGerstnerPram.y,
                                    /* Inputs */  _MultiGerstnerPram.z, _MultiGerstnerPram.w,
                                    /* Outputs */ o.worldPos, o.normal);
                        #else
                                GetDirectionalGerstnerWavePos(o.worldPos, _Steepness, _Wavelength, float2(_GerstnerDir.x, _GerstnerDir.y), o.worldPos, o.normal);
                        #endif
                        o.vertex = UnityWorldToClipPos(o.worldPos);
                    #else
                        GetSimpleGerstnerWavePos(o.worldPos, _Amplitude, _Wavelength, o.worldPos, o.normal);
                        o.vertex = UnityWorldToClipPos(o.worldPos);
                    #endif
                #else
                    float3 WPos = GetSimpleSinWavePos(o.worldPos, _Amplitude,_Wavelength);
                    o.worldPos = WPos;
                    o.normal = normalize(RecalculateSimpleWaveNormal(o.worldPos, _Amplitude,_Wavelength));
                    o.vertex = UnityWorldToClipPos(WPos);
                #endif
                //o.vertex = UnityObjectToClipPos(v.vertex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
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
