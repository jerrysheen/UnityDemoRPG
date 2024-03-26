inline half GetDistance(half3 v31 ,half3 v32)
{
	half2 vvv =  -(v31.xz - v32.xz) * (v31.xz - v32.xz);
	half vvvv = dot(vvv , half2(1,1)) * 0.01;
    return(vvvv);
}

void InkColor (half4 _Ink , half3 normalWS , half3 viewDirectionWS , inout half4 color , half4 noise , half3 albedo , half distance)
{
	viewDirectionWS.y -=noise;
	half diffuse = dot(albedo.rgb , 0.3);
	half3 newViewDir = half3(viewDirectionWS.x , -viewDirectionWS.y , viewDirectionWS.z);
	half rim = smoothstep (_Ink.y * 0.01 , 1 , saturate(1 - ((dot(normalWS , newViewDir) - 0.25) * 1.5 - diffuse * 0.3)));
	half4 rimColor = 1;
	
    //rimColor.rgb = smoothstep(0.7 , 1 , rim) * 0 + smoothstep(0.2 , 0.7 , 1 - rim) * _Ink.z;
	rimColor.rgb = smoothstep(0.1 , 0.9 , 1 - rim) * _Ink.z;
	rimColor.rgb += min(color.b , min(color.r ,color.g)) * _Ink.z;
	half lerpValue = smoothstep(0.9 , 1 , saturate( _Ink.x - distance));
    color = lerp(color , rimColor , lerpValue);
}
