using System.Collections;
using System.Collections.Generic;
using NewBlood;
using Unity.VisualScripting;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif
public class LightMapDataModifier : MonoBehaviour
{
    public LightingDataAsset lightingDataAsset; 
    public LightingSettings lightingDataSettings; 
    public Texture2DArray texture2DArray; 
    public Texture2D texture2D;

    public GameObject go;

    private Texture2D[] lightmapArray;
    private Texture2D[] shadowMaskArray;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void ReplaceLightMap()
    {
        var data = ScriptableObject.CreateInstance<ScriptableLightingData>();
        data.Read(lightingDataAsset);
        Debug.Log(data.lightmaps[0].lightmap);
        data.lightmaps = new ScriptableLightingData.LightmapData[0];
        data.Write(lightingDataAsset);
        AssetDatabase.Refresh();
    }

    public void ChangePerMatLightmapData()
    {
        Transform[] trans = go.GetComponentsInChildren<Transform>();
        foreach (var VARIABLE in trans)
        {
            MeshRenderer temp = VARIABLE.GetComponent<MeshRenderer>();
            if (temp != null)
            {
                temp.lightmapIndex = 0;
            }

        }
    }   
    
    public void RecordLightmapInfo()
    {
        Transform[] trans = go.GetComponentsInChildren<Transform>();
        foreach (var VARIABLE in trans)
        {
            MeshRenderer temp = VARIABLE.GetComponent<MeshRenderer>();
            if (temp != null)
            {
                LightIndex tempScript = VARIABLE.GetComponent<LightIndex>();
                if (tempScript == null)
                {
                    tempScript = VARIABLE.AddComponent<LightIndex>();
                }
                tempScript.Record();
            }

        }
    }        
    
    public void UpdateLightmapArray()
    {
        Shader.SetGlobalTexture("unity_Lightmaps", texture2DArray);
    }    
    
    public void MergeLightMapAndShadowMask()
    {
        var maps = LightmapSettings.lightmaps;
        lightmapArray = new Texture2D[maps.Length];
        shadowMaskArray = new Texture2D[maps.Length];
        for (int i = 0; i < maps.Length; i++)
        {
            lightmapArray[i] = maps[i].lightmapColor;
            shadowMaskArray[i] = maps[i].shadowMask;
        }
        
        // 转化
        Texture2DArray texArray = new Texture2DArray(lightmapArray[0].width, lightmapArray[0].height, maps.Length, lightmapArray[0].format, true, false);

        for (int i = 0; i < maps.Length; i ++)
        {
            Texture2D temp0 = lightmapArray[i];
            
            Texture2D outputTex = new Texture2D(temp0.width, temp0.height, TextureFormat.RGBA32, true, false);
            int mipmapLevel = temp0.mipmapCount;
            int height = temp0.height;
            int width = temp0.width;
            for (int currLevel = 0; currLevel < mipmapLevel; currLevel++)
            {
                List<Color> newcol = new List<Color>();
                Color[] colorArray00 = temp0.GetPixels(currLevel);
                
                var levelHeight = (int) (height / Mathf.Pow(2, currLevel));
                var levelWidth = (int) (width / Mathf.Pow(2, currLevel));
                for (int j = 0; j < levelHeight; j++)
                {
                    for (int k = 0; k < levelWidth; k++)
                    {
                        {
                            Color color = colorArray00[j * levelHeight + k];
                            newcol.Add(color);
                        }
                    }
                }

                outputTex.SetPixels(newcol.ToArray(), currLevel);
                newcol.Clear();
            }

            EditorUtility.CompressTexture(outputTex, lightmapArray[0].format, TextureCompressionQuality.Normal);
            outputTex.Apply();
            for (int currLevel = 0; currLevel < mipmapLevel; currLevel++)
            {
                Graphics.CopyTexture(outputTex, 0, currLevel, texArray, i, currLevel);
            }
        }
        
        texArray.Apply(false, true);
        AssetDatabase.CreateAsset(texArray, string.Format("Assets/LightmapArray.asset"));
        AssetDatabase.Refresh();
    }


}

#if UNITY_EDITOR
[CustomEditor(typeof(LightMapDataModifier))]
public class LightMapDataModifierEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        LightMapDataModifier script = target as LightMapDataModifier;
        if (GUILayout.Button("Read"))
        {
            script.ReplaceLightMap();
        }
        
        if (GUILayout.Button("Clean Lightmap data"))
        {
            script.ChangePerMatLightmapData();
        }

        if (GUILayout.Button("Record lightmap INFO"))
        {
            script.RecordLightmapInfo();
        }
        
        if (GUILayout.Button("Merge Lightmap and ShadowMask"))
        {
            script.MergeLightMapAndShadowMask();
        }
        
        if (GUILayout.Button("Update lightmapArray"))
        {
            script.UpdateLightmapArray();
        }
    }
}

#endif
