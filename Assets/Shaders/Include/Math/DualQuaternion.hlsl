#ifndef DUALQUATERNION_ARTHIMETIC
	#define DUALQUATERNION_ARTHIMETIC

	#include "Quaternion.hlsl"

	struct DQ
	{
		float4 realy;
		float4 dual;

		inline DQ multiplyscalar(float scalar)
	{
		realy *= scalar;
		dual *= scalar;
		DQ dq;
			dq.realy=realy;
			dq.dual=dual;
		return dq;
	}

	inline DQ inverse(DQ dq)
	{
		float4 rinv = dq.realy;
		rinv.xyz*=-1;
		
		dq.realy=rinv;
		dq.dual=-rinv * dq.dual * rinv;
		//return DualQuaternion(q_r_inv, -q_r_inv * dq.dual * q_r_inv);
		return dq;
	}

	


	inline DQ add(DQ dq2)
	{
		DQ dq;

		dq.realy = realy + dq2.realy;
		dq.dual = dual + dq2.dual;

		return dq;
	}


	inline DQ Nlerp(DQ s,DQ e,float t)
	{
		s=s.multiplyscalar(1-t);
		e=e.multiplyscalar(t);
			DQ dq;
			dq.realy = s.realy + e.realy;
			dq.dual = s.dual + e.dual;
			
		return  dq;
	}
	
	inline DQ minus(DQ dq2)
	{
		DQ dq;

		dq.realy = realy - dq2.realy;
		dq.dual = dual - dq2.dual;

		return dq;
	}

	DQ normalizeDQ()
	{
		float len = length(realy);
			DQ dq;
		dq.realy = realy / len;
		dq.dual = dual / len;
		return dq;
	}

	DQ mulDQ(DQ dq1, DQ dq2)
	{
		DQ dq;
		dq.realy = mulQxQ(dq1.realy, dq2.realy);
		dq.dual = mulQxQ(dq1.dual, dq2.realy) + mulQxQ(dq1.realy, dq2.dual);
		return dq;
	}

	float3 translateFromDQ()
	{
		return
		mulQxQ(
		dual * 2,
		conjugateQuaternion(realy)
		).xyz;
	}
		//四元數旋轉
		float4 QuaternionMultiply(float4 q1, float4 q2)
		{
			float w = q1.w * q2.w - dot(q1.xyz, q2.xyz);
			q1.xyz = q2.xyz * q1.w + q1.xyz * q2.w + cross(q1.xyz, q2.xyz);
			q1.w = w;
			return q1;
		}
		//旋轉
		float4 transformRotationByDQ(float4 v)
		{
			v = QuaternionMultiply(realy, v);
			return QuaternionMultiply(v, conjugateQuaternion(realy));
		}
		//位置
		// float3 transformPositionByDQ(float3 pos)
		// {
		// 	return translateFromDQ() + transformPositionByQ(realy, pos);
		// }
		//也是位置
		 float3 transformPositionDQ(float3 position)
		{
			float4 realDQ=realy;
			float4 dualDQ=dual;
			return position + 2 * cross(realDQ.xyz, cross(realDQ.xyz, position) + realDQ.w * position) + 2 * (realDQ.w * dualDQ.xyz - dualDQ.w * realDQ.xyz +cross(realDQ.xyz, dualDQ.xyz));
		}


		
	float4x4 DQToMatrix()
	{
		float4x4 convetedMatrix;
		float len2 = dot(realy, realy);
		float xx = realy.x * realy.x, xy = realy.x * realy.y, xz = realy.x * realy.z, xw = realy.x * realy.w,
		yy = realy.y * realy.y, yz = realy.y * realy.z, yw = realy.y * realy.w,
		zz = realy.z * realy.z, zw = realy.z * realy.w;

		convetedMatrix[0][0] = 1.0 - 2.0 * yy - 2.0 * zz;
		convetedMatrix[0][1] = 2.0 * xy - 2.0 * zw;
		convetedMatrix[0][2] = 2.0 * xz + 2.0 * yw;

		convetedMatrix[1][0] = 2.0 * xy + 2 * zw;
		convetedMatrix[1][1] = 1.0 - 2.0 * xx - 2.0 * zz;
		convetedMatrix[1][2] = 2.0 * yz - 2.0 * xw;

		convetedMatrix[2][0] = 2.0 * xz - 2.0 * yw;
		convetedMatrix[2][1] = 2.0 * yz + 2.0 * xw;
		convetedMatrix[2][2] = 1.0 - 2.0 * xx - 2.0 * yy;

		float3 trans = translateFromDQ();

		convetedMatrix[0][3] = trans.x;
		convetedMatrix[1][3] = trans.y;
		convetedMatrix[2][3] = trans.z;

		convetedMatrix[3][0] = 0;
		convetedMatrix[3][1] = 0;
		convetedMatrix[3][2] = 0;

		convetedMatrix /= len2;

		convetedMatrix[3][3] = 1.0;

		return convetedMatrix;
	}
	};

	
#endif
