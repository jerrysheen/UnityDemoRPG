using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;



public enum EStickBone
{
	Head = 0,           //0头;
    Head_UI = 1,       //模型名字挂点UI;
	Chest = 2,          //1胸 ;
	LeftHand = 3,       //2左手 ;
	RightHand = 4,      //3右手;
	LeftArm = 5,        //左胳膊
	RightArm = 6,       //右胳膊
	LeftLeg = 7,        //左腿
	RightLeg = 8,       //右腿
	LeftFoot = 9,       //左脚
	RightFoot = 10,      //右脚
    
	NB_Bottom = 11,  //默认，脚底
    
    EX_0 = 12,    // 预留;
    EX_1 = 13,
    EX_2 = 14,

    MaxCount //在此之后禁止添加;
}

public class CharacterBoneInfo : MonoBehaviour
{

    [SerializeField]
    [HideInInspector]
    public Transform[] m_BoneArray;

	public Transform m_Transform
    {
        get
        {
            return this.transform;
        }
    }

    private Dictionary<int, Transform> mBoneDic = null;
    public Dictionary<int, Transform> GetBoneDic()
    {
        if(mBoneDic == null)
        {
            mBoneDic = GetBoneDic(gameObject);
        }
        return mBoneDic;
    }
    
    public static Dictionary<int, Transform> GetBoneDic(GameObject root)
    {
        Dictionary<int, Transform> boneDic = new Dictionary<int, Transform>();
        Transform[] bones = root.GetComponentsInChildren<Transform>();
        for (int i = 0; i < bones.Length; i++)
        {
            Transform bone = bones[i];
            int id = Animator.StringToHash(bone.name);
#if UNITY_EDITOR
            if (boneDic.ContainsKey(id))
            {
                //Debugger.LogError("bone id repeated!!! " + bone.name);
                Debug.LogError("bone id repeated!!! " + bone.name);
            }
#endif
            boneDic.Add(id, bone);
        }

        return boneDic;
    }

    public Transform GetBone(int index)
    {
        if (index > -1 && index < (int)EStickBone.MaxCount && m_BoneArray != null && index < m_BoneArray.Length)
            return m_BoneArray[index];
        else
            return null;
    }

    public Transform GetBone(EStickBone boneType)
    {
        if ((int)boneType > -1 && boneType < EStickBone.MaxCount)
            return m_BoneArray[(int)boneType];
        else
            return null;
    }

#if UNITY_EDITOR
    public void SetBoneInfo(EStickBone boneType, Transform boneTran)
    {
        if (m_BoneArray == null || m_BoneArray.Length < 1)
        {
            return;
        }
        Debug.Log("======== add:" + boneType.ToString() + ", name:" + (boneTran != null ? boneTran.name : "null"));
        m_BoneArray[(int)boneType] = boneTran;
    }
#endif

}
