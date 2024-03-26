#ifndef WIND
#define WIND


#define SIDE_TO_SIDE_FREQ1 1.975
#define SIDE_TO_SIDE_FREQ2 0.793
#define UP_AND_DOWN_FREQ1 0.375
#define UP_AND_DOWN_FREQ2 1.193
#define BranchAmplitude  0.05;

// #ifdef UNITY_DOTS_INSTANCING_ENABLED
//     UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
//         UNITY_DOTS_INSTANCED_PROP(float , _Speed)
//         UNITY_DOTS_INSTANCED_PROP(float4 , _Wind)
//     UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)
//     #define _Speed            UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_Speed)
//     #define _Wind            UNITY_ACCESS_DOTS_INSTANCED_PROP_FROM_MACRO(float  , Metadata_Wind)
// #endif
UNITY_INSTANCING_BUFFER_START(_PlantProp)
UNITY_DEFINE_INSTANCED_PROP(float, _Speed)
UNITY_DEFINE_INSTANCED_PROP(float4, _Wind)
UNITY_DEFINE_INSTANCED_PROP(float4, _PColored)
#define _Speed UNITY_ACCESS_INSTANCED_PROP(_PlantProp,_Speed)
#define _Wind UNITY_ACCESS_INSTANCED_PROP(_PlantProp,_Wind)
#define _PColored UNITY_ACCESS_INSTANCED_PROP(_PlantProp,_PColored)
UNITY_INSTANCING_BUFFER_END(_PlantProp)



// This describes how much the overall leaf/branch oscillates side-to-side.
#define DetailAmplitude  0.05;

float4 SmoothCurve(float4 x)
{
    return x * x * (3.0 - 2.0 * x);
}

float4 TriangleWave(float4 x)
{
    return abs(frac(x + 0.5) * 2.0 - 1.0);
}

float4 SmoothTriangleWave(float4 x)
{
    return SmoothCurve(TriangleWave(x));
}


void ApplyMainBending(inout float3 vPos, float2 vWind, float fBendScale)
{
    // Calculate the length from the ground, since we'll need it.
    float fLength = length(vPos);
    // Bend factor - Wind variation is done on the CPU.  
    float fBF = vPos.y * fBendScale;
    // Smooth bending factor and increase its nearby height limit.  
    fBF += 1.0;
    fBF *= fBF;
    fBF = fBF * fBF - fBF;
    // Displace position  
    float3 vNewPos = vPos;
    vNewPos.xz += vWind.xy * fBF;
    // Rescale - this keeps the plant parts from "stretching" by shortening the y (height) while
    // they move about the xz.
    vPos.xyz = normalize(vNewPos.xyz) * fLength;
}

// This provides "chaotic" motion for leaves and branches (the entire plant, really)
void ApplyDetailBending(
	inout float3 vPos,		// The final world position of the vertex being modified
	float3 vNormal,			// The world normal for this vertex
	float3 objectPosition,	        // The world position of the plant instance (same for all vertices)
	float fDetailPhase,		// Optional phase for side-to-side. This is used to vary the phase for side-to-side motion
	float fBranchPhase,		// The green vertex channel per Crytek's convention
	float fTime,			// Ever-increasing time value (e.g. seconds ellapsed)
	float fEdgeAtten,		// "Leaf stiffness", red vertex channel per Crytek's convention
	float fBranchAtten,		// "Overall stiffness", *inverse* of blue channel per Crytek's convention
	float fBranchAmp,		// Controls how much up and down
	float fSpeed,			// Controls how quickly the leaf oscillates
	float fDetailFreq,		// Same thing as fSpeed (they could really be combined, but I suspect
					// this could be used to let you additionally control the speed per vertex).
	float fDetailAmp)		// Controls how much back and forth
{
	// Phases (object, vertex, branch)
	// fObjPhase: This ensures phase is different for different plant instances, but it should be
	// the same value for all vertices of the same plant.
	float fObjPhase = dot(objectPosition.xyz, 1);  

	// In this sample fBranchPhase is always zero, but if you want you could somehow supply a
	// different phase for each branch.
	fBranchPhase += fObjPhase;

	// Detail phase is (in this sample) controlled by the GREEN vertex color. In your modelling program,
	// assign the same "random" phase color to each vertex in a single leaf/branch so that the whole leaf/branch
	// moves together.
	float fVtxPhase = dot(vPos.xyz, fDetailPhase + fBranchPhase);  

	float2 vWavesIn = fTime + float2(fVtxPhase, fBranchPhase );
	float4 vWaves = (frac( vWavesIn.xxyy * float4(SIDE_TO_SIDE_FREQ1, SIDE_TO_SIDE_FREQ2, UP_AND_DOWN_FREQ1, UP_AND_DOWN_FREQ2) ) * 2.0 - 1.0 ) * fSpeed * fDetailFreq;
	vWaves = SmoothTriangleWave( vWaves );
	float2 vWavesSum = vWaves.xz + vWaves.yw;  

	// -fBranchAtten is how restricted this vertex of the leaf/branch is. e.g. close to the stem
	//  it should be 0 (maximum stiffness). At the far outer edge it might be 1.
	//  In this sample, this is controlled by the blue vertex color.
	// -fEdgeAtten controls movement in the plane of the leaf/branch. It is controlled by the
	//  red vertex color in this sample. It is supposed to represent "leaf stiffness". Generally, it
	//  should be 0 in the middle of the leaf (maximum stiffness), and 1 on the outer edges.
	// -Note that this is different from the Crytek code, in that we use vPos.xzy instead of vPos.xyz,
	//  because I treat y as the up-and-down direction.
	// vPos.xzy += vWavesSum.xxy * float3(fEdgeAtten * fDetailAmp *
	// 						vNormal.xz, fBranchAtten * fBranchAmp

        // vPos.xyz += vWavesSum.x * float3(fEdgeAtten * fDetailAmp * vNormal.xyz);
        // vPos.y += vWavesSum.y * fBranchAtten * fBranchAmp;
        vPos.xyz += vWavesSum.x * float3(fEdgeAtten * fDetailAmp * vNormal.xyz);
        vPos.y += vWavesSum.y * fBranchAtten * fBranchAmp;
}

void TreeBlend(inout float3 positionOS, float3 vertecColor, float3 Normal, half4 WindParam)
{
	// WindParam.xy = WindSpeed;
	// WindParam.z = BendScale;
	// WindParam.w = windStrength;
	// dummy data:
	half2 WindSpeed = WindParam.xy;
	WindSpeed.x = sin(_Time.x * 13.0f) * 2.0f;
	WindSpeed.y = cos(_Time.x * 13.0f) * 2.0f;
	half BendScale = WindParam.z;
	half windStrength = WindParam.w;

    float3 objectPosition = unity_ObjectToWorld[3].xyz;
    positionOS -= objectPosition;	// Reset the vertex to base-zero
    ApplyMainBending(positionOS, WindSpeed, BendScale);
	//positionOS += objectPosition;
	//return;
	float3 vPos = positionOS;	
    ApplyDetailBending(
    vPos,
    Normal,
    objectPosition,
    0,					// Leaf phase - not used in this scenario, but would allow for variation in side-to-side motion
    vertecColor.g,		// Branch phase - should be the same for all verts in a leaf/branch.
    _Time,
    vertecColor.r,		// edge attenuation, leaf stiffness
    1 - vertecColor.b,  // branch attenuation. High values close to stem, low values furthest from stem.
                        // For some reason, Crysis uses solid blue for non-moving, and black for most movement.
                        // So we invert the blue value here.
    0.05 * windStrength, // branch amplitude. Play with this until it looks good.  // original code is : BranchAmplitude * windStrength
    2,					// Speed. Play with this until it looks good.
    1,					// Detail frequency. Keep this at 1 unless you want to have different per-leaf frequency
    0.05 * windStrength);	// Detail amplitude. Play with this until it looks good. // original code is ： DetailAmplitude * windStrength

	positionOS = vPos;
}


#endif
