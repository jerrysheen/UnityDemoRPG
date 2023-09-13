using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System;
using System.Xml;
using System.Xml.Serialization;
using System.IO;

[CustomEditor(typeof(CharacterBoneInfo))]
public class CharacterBoneInfoInspector : Editor
{
    CharacterBoneInfo m_CharacterBoneInfo;

    private string m_ImportStickBoneConfigPath;
    private string m_ExportStickBoneConfigPath;

    void OnEnable()
    {
        m_CharacterBoneInfo = target as CharacterBoneInfo;
        InitBoneArray(m_CharacterBoneInfo);
    }

    static void InitBoneArray(CharacterBoneInfo boneInfo)
    {	
        if (boneInfo == null || boneInfo.m_BoneArray != null)
        {
            return;
        }
        boneInfo.m_BoneArray = new Transform[(int)EStickBone.MaxCount];

    }

	void InitBoneArray(Transform[] boneArray)
	{
		m_CharacterBoneInfo.m_BoneArray = new Transform[(int)EStickBone.MaxCount];

		if ( boneArray == null )
		{
			return;
		}

		for ( int i=0; i<boneArray.Length && i < m_CharacterBoneInfo.m_BoneArray.Length; i++ )
		{
			m_CharacterBoneInfo.m_BoneArray[i] = boneArray[i];
        }

	}

	static void ClearBoneArray(CharacterBoneInfo boneInfo)
    {
	    if(boneInfo == null) return;
	    
        for (int i = 0, imax = boneInfo.m_BoneArray.Length; i < imax; i++)
        {
	        boneInfo.SetBoneInfo((EStickBone)i, null);
        }
    }

    private void SetBoneInfo()
    {
        if (m_CharacterBoneInfo == null || m_CharacterBoneInfo.m_BoneArray == null)
        {
            return;
        }

		if (m_CharacterBoneInfo.m_BoneArray.Length < (int)EStickBone.MaxCount)
		{
			InitBoneArray(m_CharacterBoneInfo.m_BoneArray);
		}

        for (int i = 0, imax = (int)EStickBone.MaxCount; i < imax; i++)
        {
            if (i >= m_CharacterBoneInfo.m_BoneArray.Length)
            {
                continue;
            }
            EStickBone type = (EStickBone)i;
            string labelName = type.ToString() + "  (" + GetTypeName(type) + ")【" + i + "】";
            Transform showValue = m_CharacterBoneInfo.m_BoneArray[i];
            Transform actualValue = EditorGUILayout.ObjectField(labelName, showValue, typeof(Transform), true) as Transform;
            if (actualValue != showValue)
            {
                m_CharacterBoneInfo.SetBoneInfo((EStickBone)i, actualValue);
            }
        }
    }

	private string GetTypeName(EStickBone type)
	{
		switch(type)
		{
			case EStickBone.Head:
				return "头";

			case EStickBone.Chest:
				return "胸";

			case EStickBone.LeftHand:
				return "左手";

			case EStickBone.RightHand:
				return "右手";

			case EStickBone.LeftArm:
				return "左臂";

			case EStickBone.RightArm:
				return "右臂";

			case EStickBone.LeftLeg:
				return "左腿";

			case EStickBone.RightLeg:
				return "右腿";

			case EStickBone.LeftFoot:
				return "左脚";

			case EStickBone.RightFoot:
				return "右脚";

			case EStickBone.NB_Bottom:
				return "根节点";
			
			case EStickBone.Head_UI:
				return "头顶UI位置";
			
			case EStickBone.EX_0:
			case EStickBone.EX_1:
			case EStickBone.EX_2:
				return "预留【自定义】";
		}
		
		return "未定义";
	}

    public override void OnInspectorGUI()
    {
        if (m_CharacterBoneInfo == null)
        {
            return;
        }

        SetBoneInfo();

        if (GUILayout.Button("Export Xml"))
        {
            m_ExportStickBoneConfigPath = EditorUtility.SaveFilePanel("Save Xml File", string.Format("{0}/../conf/data_xml", Application.dataPath), "StickBoneExprot", "xml");
            if (string.IsNullOrEmpty(m_ExportStickBoneConfigPath))
            {
                return;
            }
            ExportXml();
            Debug.LogFormat("Export Xml Success To {0}", m_ExportStickBoneConfigPath);
        }

        if (GUILayout.Button("Import Xml"))
        {
            m_ImportStickBoneConfigPath = EditorUtility.OpenFilePanel("Select Xml File", string.Format("{0}/../conf/data_xml", Application.dataPath), "xml");
            if (string.IsNullOrEmpty(m_ImportStickBoneConfigPath))
            {
                return;
            }
            ImportXml(m_ImportStickBoneConfigPath, m_CharacterBoneInfo);
            Debug.LogFormat("Import Xml Success From {0}", m_ImportStickBoneConfigPath);
        }

        if (GUILayout.Button("Reset"))
        {
            if (EditorUtility.DisplayDialog("重置", "你确定要重置？", "是", "否"))
            {
                ClearBoneArray(m_CharacterBoneInfo);
            }
        }
        
        if (GUI.changed) EditorUtility.SetDirty(m_CharacterBoneInfo);
    }

    private void ExportXml()
    {
        XmlDocument xmlDoc = new XmlDocument();
        XmlDeclaration declaration = xmlDoc.CreateXmlDeclaration("1.0", "utf-8", "yes");
        XmlNode rootNode = xmlDoc.CreateElement("StickBones");
        xmlDoc.AppendChild(declaration);
        XmlNode elementNode;
        XmlAttribute elementNodeKeyAttr;
        XmlAttribute elementNodeValueAttr;
        for (int i = 0, imax = (int)EStickBone.MaxCount; i < imax; i++)
        {
            if (m_CharacterBoneInfo.m_BoneArray[i] == null)
            {
                continue;
            }
            elementNodeKeyAttr = xmlDoc.CreateAttribute("key");
            elementNodeKeyAttr.Value = ((EStickBone)i).ToString();
            elementNodeValueAttr = xmlDoc.CreateAttribute("transform");
            elementNodeValueAttr.Value = m_CharacterBoneInfo.m_BoneArray[i].name;
            elementNode = xmlDoc.CreateElement("StickBone");
            elementNode.Attributes.Append(elementNodeKeyAttr);
            elementNode.Attributes.Append(elementNodeValueAttr);
            rootNode.AppendChild(elementNode);
        }
        xmlDoc.AppendChild(rootNode);
        xmlDoc.Save(m_ExportStickBoneConfigPath);
    }

    public static void ImportXml(string configFile, CharacterBoneInfo boneInfo)
    {
	    InitBoneArray(boneInfo);
	    
        StickBoneImport stickBoneImport = new StickBoneImport();
        if (File.Exists(configFile))
        {
            XmlSerializer x = new XmlSerializer(typeof(StickBoneImport));
            StreamReader reader = File.OpenText(configFile);
            try
            {
                stickBoneImport = (StickBoneImport)x.Deserialize(reader);
            }
            catch (Exception e)
            {
                Debug.LogException(e);
                EditorUtility.DisplayDialog("XML Serialize Failed", "See console for detail\n \n" + e.Message, "OK");
            }
            finally
            {
                if (reader != null)
                {
                    reader.Close();
                }
            }
        }
        else
        {
	        Debug.LogError("There is no Bone Config file");
        }
        ClearBoneArray(boneInfo);
        for (int i = 0, imax = stickBoneImport.StickBoneList.Count; i < imax; i++)
        {
            StickBone stickBone = stickBoneImport.StickBoneList[i];
            EStickBone bonetype;
            try
            {
                bonetype = (EStickBone)Enum.Parse(typeof(EStickBone), stickBone.key);
            }
            catch (System.Exception ex)
            {
                Debug.LogErrorFormat("{0}\n{1}","xml节点必须与枚举名称一致，请检查xml或枚举",ex);
                continue;
            }
            boneInfo.SetBoneInfo(bonetype, FindTransform(stickBone.transform, boneInfo));
        }
    }

    static private Transform FindTransform(string transformName, CharacterBoneInfo boneInfo)
    {
        Transform targetTransform;
        Transform transform = boneInfo.m_Transform;
        if (transform == null)
            return null;
        targetTransform = GetChild(transform, transformName);
        return targetTransform;
    }


	public static Transform GetChild(Transform rootTransform, string name, bool includeSelf = false)
	{
		if (rootTransform == null || string.IsNullOrEmpty(name))
		{
			return null;
		}

		if (includeSelf && rootTransform.name == name)
		{
			return rootTransform;
		}
		
		Transform tranChild = null;
		if (name.IndexOf('/') != -1)
		{
			tranChild = rootTransform.Find(name);
			if (tranChild != null)
			{
				return tranChild.gameObject.transform;
			}
			return null;
		}

		tranChild = rootTransform.Find(name);
		if (tranChild != null)
		{
			return tranChild.gameObject.transform;
		}

		// 函数的这部分怎么还在？ 
		for (int i = 0; i < rootTransform.childCount; i++)
		{
			Transform childTran = rootTransform.GetChild(i);
			//if (goChild.name == name)
			//    return goChild;

			childTran = GetChild(childTran, name);
			if (childTran != null)
			{
				return childTran;
			}
		}
		return null;
	}

	[Serializable]
    [XmlType(@"StickBones")]
    public class StickBoneImport
    {
        [System.Xml.Serialization.XmlElement(@"StickBone")]
        public List<StickBone> StickBoneList = new List<StickBone>();
    }
    [Serializable]
    [XmlType(@"StickBone")]
    public class StickBone
    {
        [XmlAttribute(@"key")]
        public string key;
        [XmlAttribute(@"transform")]
        public string transform;
    }

}
