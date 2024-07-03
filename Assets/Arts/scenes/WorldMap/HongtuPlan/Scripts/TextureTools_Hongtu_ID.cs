using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEditor;

public class TextureTools_Hongtu_ID : EditorWindow
{
    private static TextureTools_Hongtu_ID s_TextureToolEditor;
    public enum IDMapFormat
    {
        R8G8 = 0,
        R8 = 1,
        R8G8SecondWeight = 2,
    };

    public Texture2D[] m_Weightmaps;
    public bool m_EnableTextureArraySRGB = false;
    public Texture2D[] m_TextureArray;
    public string m_OutputFolder = "Arts/scenes/WorldMap/Output/HongtuPlan";
    public Texture2D m_IDMapR8;
    public Texture2D m_IDMapR8G8;
    public IDMapFormat m_FormatChoice;

    SerializedObject m_SeObj;

    [MenuItem("ELEXTerrain/Hongtu_TextureTool")]
    public static void ShowEditorWindow()
    {
        s_TextureToolEditor = GetWindow<TextureTools_Hongtu_ID>(false, "Texture Tool", true);
    }

    private void OnEnable()
    {
        ScriptableObject target = this;
        m_SeObj = new SerializedObject(target);

        var data = EditorPrefs.GetString("TextureTools_Hongtu_IDWindow", EditorJsonUtility.ToJson(this, false));
        EditorJsonUtility.FromJsonOverwrite(data, this);
    }

    private void OnDisable()
    {
        var data = EditorJsonUtility.ToJson(this, false);
        EditorPrefs.SetString("TextureTools_Hongtu_IDWindow", data);
    }

    public void OnGUI()
    {
        m_SeObj.Update();

        SerializedProperty TexArrayProperty = m_SeObj.FindProperty("m_TextureArray");
        SerializedProperty WeightMapProperty = m_SeObj.FindProperty("m_Weightmaps");
        SerializedProperty OutputFolderProperty = m_SeObj.FindProperty("m_OutputFolder");
        SerializedProperty sRGBProperty = m_SeObj.FindProperty("m_EnableTextureArraySRGB");
        SerializedProperty FormatProperty = m_SeObj.FindProperty("m_FormatChoice");
        SerializedProperty R8MapProperty = m_SeObj.FindProperty("m_IDMapR8");
        SerializedProperty R8G8MapProperty = m_SeObj.FindProperty("m_IDMapR8G8");

        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Output Folder:", EditorStyles.boldLabel);
        m_OutputFolder = EditorGUILayout.TextArea(OutputFolderProperty.stringValue);
        EditorGUILayout.EndHorizontal();

        GUILayout.Space(30);

        EditorGUILayout.PropertyField(TexArrayProperty, true);

        m_EnableTextureArraySRGB = EditorGUILayout.Toggle("sRGB", sRGBProperty.boolValue);

        if (GUILayout.Button("Create Texture2D Array", GUILayout.Height(50)))
        {
            CreateTexture2DArray();
        }

        GUILayout.Space(30);

        EditorGUILayout.PropertyField(WeightMapProperty, true);

        m_FormatChoice = (IDMapFormat)GUILayout.SelectionGrid(FormatProperty.intValue, new string[] { "R8G8", "R8"}, 2, GUILayout.Height(50));

        if (GUILayout.Button("Generate Texel ID Map", GUILayout.Height(50)))
        {
            GenerateTexelIDMap(m_FormatChoice);
        }

        GUILayout.Space(30);

        EditorGUILayout.PropertyField(R8MapProperty, false, GUILayout.Height(50));
        EditorGUILayout.BeginHorizontal();
        if (GUILayout.Button(new GUIContent("R8G8->R8"), GUILayout.Height(50)))
        {
            ConvertIDMap(IDMapFormat.R8G8, IDMapFormat.R8);
        }
        if (GUILayout.Button(new GUIContent("R8->R8G8"), GUILayout.Height(50)))
        {
            ConvertIDMap(IDMapFormat.R8, IDMapFormat.R8G8);
        }

        EditorGUILayout.EndHorizontal();
        EditorGUILayout.PropertyField(R8G8MapProperty, false, GUILayout.Height(50));

        m_SeObj.ApplyModifiedProperties();
    }

    class TexelData
    {
        public static int m_ChannelNum = 16;
        public float[] m_RawColors;
        public int[] m_Texels;
        public Color32 m_EncodedColor;

        public TexelData()
        {
            m_RawColors = new float[m_ChannelNum];
            /* | 3 | 2 |
                ������
                | 1 | 0 | */
            m_Texels = new int[4] { -1, -1, -1, -1 };
            m_EncodedColor = new Color32();
        }

        public void Encode(IDMapFormat format)
        {
            int idxOfMax = -1;
            float valOfMax = .0f;
            int idxOfSecond = -1;
            float valOfSecond = .0f;
            for (int i = 0; i < m_RawColors.Length; ++i)
            {
                if (m_RawColors[i] > valOfMax)
                {
                    valOfSecond = valOfMax;
                    idxOfSecond = idxOfMax;
                    valOfMax = m_RawColors[i];
                    idxOfMax = i;
                }
            }
            //针对于weight2的图，我只需要在有第二个weight的时候记录它， 如果是单权重的图，继续保持原先的权重。
            if (format == IDMapFormat.R8G8SecondWeight)
            {
                if (idxOfSecond == -1)
                {
                    m_Texels[0] = idxOfMax;
                }
                else
                {
                    m_Texels[0] = idxOfSecond;
                }
            }
            else
            {
                m_Texels[0] = idxOfMax;
            }

            for (int i = 1; i < m_Texels.Length; ++i)
            {
                if (m_Texels[i] == -1)
                {
                    m_Texels[i] = m_Texels[0];
                }
            }

            if (format == IDMapFormat.R8G8)
            {
               
                m_EncodedColor.r = (byte)((m_Texels[0] << 4) | m_Texels[1]);
                m_EncodedColor.g = (byte)((m_Texels[2] << 4) | m_Texels[3]);
            }
            else if (format == IDMapFormat.R8)
            {
                m_EncodedColor.r = (byte)(m_Texels[0]);
                m_EncodedColor.g = 0;
            }
            else if(format == IDMapFormat.R8G8SecondWeight)
            {
                m_EncodedColor.r = (byte)(m_Texels[0]);
                m_EncodedColor.g = 0;
            }

            m_EncodedColor.b = 0;
            m_EncodedColor.a = 0;
        }
    }

        public void GenerateTexelIDMap(IDMapFormat format)
    {
#if UNITY_EDITOR
        if (m_Weightmaps.Length == 0)
        {
            return;
        }

        Texture2D texelIDMap = new Texture2D(m_Weightmaps[0].width, m_Weightmaps[0].height, TextureFormat.RGBA32, false, true);
        texelIDMap.filterMode = FilterMode.Point;
        
        Texture2D texelIDMapSecondWeight = new Texture2D(m_Weightmaps[0].width, m_Weightmaps[0].height, TextureFormat.RGBA32, false, true);
        texelIDMapSecondWeight.filterMode = FilterMode.Point;

        List<TexelData> texelList = new List<TexelData>();
        List<TexelData> texelListWeight = new List<TexelData>();

        for (int i = 0; i < m_Weightmaps.Length; ++i)
        {
            Color[] colors = m_Weightmaps[i].GetPixels();
            for (int j = 0; j < colors.Length; ++j)
            {
                if (i == 0)
                {
                    TexelData data = new TexelData();
                    TexelData data1 = new TexelData();
                    data.m_RawColors[0] = colors[j].r;
                    data.m_RawColors[1] = colors[j].g;
                    data.m_RawColors[2] = colors[j].b;
                    data.m_RawColors[3] = colors[j].a;
                    texelList.Add(data);
                    
                    data1.m_RawColors[0] = colors[j].r;
                    data1.m_RawColors[1] = colors[j].g;
                    data1.m_RawColors[2] = colors[j].b;
                    data1.m_RawColors[3] = colors[j].a;
                    texelListWeight.Add(data1);
                }
                else
                {
                    texelList[j].m_RawColors[4 * i] = colors[j].r;
                    texelList[j].m_RawColors[4 * i + 1] = colors[j].g;
                    texelList[j].m_RawColors[4 * i + 2] = colors[j].b;
                    texelList[j].m_RawColors[4 * i + 3] = colors[j].a;
                    
                    texelListWeight[j].m_RawColors[4 * i] = colors[j].r;
                    texelListWeight[j].m_RawColors[4 * i + 1] = colors[j].g;
                    texelListWeight[j].m_RawColors[4 * i + 2] = colors[j].b;
                    texelListWeight[j].m_RawColors[4 * i + 3] = colors[j].a;
                }
            }
        }

        Color32[] encodedColors = new Color32[texelList.Count];
        Color32[] encodedColorsWeight = new Color32[texelListWeight.Count];
        Debug.Log(format == IDMapFormat.R8G8SecondWeight);
        for (int i = 0; i < texelList.Count; ++i)
        {
            if (i % m_Weightmaps[0].width > 0)
            {
                texelList[i].m_Texels[1] = texelList[i - 1].m_Texels[0];
                texelListWeight[i].m_Texels[1] = texelListWeight[i - 1].m_Texels[0];
            }

            if (i / m_Weightmaps[0].width > 0)
            {
                texelList[i].m_Texels[2] = texelList[i - m_Weightmaps[0].width].m_Texels[0];
                texelListWeight[i].m_Texels[2] = texelListWeight[i - m_Weightmaps[0].width].m_Texels[0];
            }

            if (i % m_Weightmaps[0].width > 0 && i / m_Weightmaps[0].width > 0)
            {
                texelList[i].m_Texels[3] = texelList[i - m_Weightmaps[0].width - 1].m_Texels[0];
                texelListWeight[i].m_Texels[3] = texelListWeight[i - m_Weightmaps[0].width - 1].m_Texels[0];
            }

            texelList[i].Encode(format);
            texelListWeight[i].Encode(IDMapFormat.R8G8SecondWeight);
            encodedColors[i] = texelList[i].m_EncodedColor;
            encodedColorsWeight[i] = texelListWeight[i].m_EncodedColor;
        }

        texelIDMap.SetPixels32(encodedColors);
        texelIDMapSecondWeight.SetPixels32(encodedColorsWeight);
        byte[] bytes = texelIDMap.EncodeToTGA();
        byte[] bytesWeight = texelIDMapSecondWeight.EncodeToTGA();

        string suffix = "UnknownFormat";
        if (format == IDMapFormat.R8)
        {
            suffix = "R8";
        }
        else if (format == IDMapFormat.R8G8)
        {
            suffix = "R8G8";
        }

        File.WriteAllBytes(string.Format("Assets/{0}/{1}_TexelIDMap_{2}.tga", m_OutputFolder, m_Weightmaps[0].name, suffix), bytes);
        File.WriteAllBytes(string.Format("Assets/{0}/{1}_TexelIDMap_{2}_SecondWeight.tga", m_OutputFolder, m_Weightmaps[0].name, suffix), bytesWeight);
        AssetDatabase.Refresh();
#endif
    }

    public void CreateTexture2DArray()
    {
#if UNITY_EDITOR
        if (m_TextureArray.Length == 0)
        {
            return;
        }

        Texture2DArray texArray = new Texture2DArray(m_TextureArray[0].width, m_TextureArray[0].height, m_TextureArray.Length, m_TextureArray[0].format, true, !m_EnableTextureArraySRGB);

        for (int i = 0; i < m_TextureArray.Length; ++i)
        {
            //texArray.SetPixels(m_TextureArray[i].GetPixels(), i);
            for (int m = 0; m < m_TextureArray[i].mipmapCount; m++)
            {
                Graphics.CopyTexture(m_TextureArray[i], 0, m, texArray, i, m);
            }
        }

        AssetDatabase.CreateAsset(texArray, string.Format("Assets/{0}/{1}_2dArray.asset", m_OutputFolder, m_TextureArray[0].name));
        AssetDatabase.Refresh();
        Debug.Log("Successfully generated text2d array");
#endif
    }

    public void ConvertIDMap(IDMapFormat src, IDMapFormat dst)
    {
#if UNITY_EDITOR
        Texture2D srcIDMap = null;
        if (src == IDMapFormat.R8)
        {
            srcIDMap = m_IDMapR8;
        }
        else if (src == IDMapFormat.R8G8)
        {
            srcIDMap = m_IDMapR8G8;
        }

        if (srcIDMap == null)
        {
            Debug.LogError("[ConvertIDMap] Wrong Src ID Map!");
            return;
        }

        Texture2D dstIDMap = new Texture2D(srcIDMap.width, srcIDMap.height, TextureFormat.RGBA32, false, true);
        srcIDMap.filterMode = FilterMode.Point;

        Color32[] srcPixels = srcIDMap.GetPixels32();
        Color32[] dstPixels = new Color32[srcPixels.Length];

        if (dst == IDMapFormat.R8G8)
        {
            for (int i = 0; i < srcPixels.Length; ++i)
            {
                int pix = srcPixels[i].r;
                int left = i % srcIDMap.width > 0 ? srcPixels[i - 1].r : 0;
                int up = i / srcIDMap.width > 0 ? srcPixels[i - srcIDMap.width].r : 0;
                int leftUp = i % srcIDMap.width > 0 && i / srcIDMap.width > 0 ? srcPixels[i - srcIDMap.width - 1].r : 0;

                dstPixels[i].r = (byte)((pix << 4) | (left & 15));
                dstPixels[i].g = (byte)((up << 4) | (leftUp & 15));
                dstPixels[i].b = 0;
                dstPixels[i].a = 0;
            }
        }
        else if (dst == IDMapFormat.R8)
        {
            for (int i = 0; i < srcPixels.Length; ++i)
            {
                dstPixels[i].r = (byte)(srcPixels[i].r >> 4);
                dstPixels[i].g = 0;
                dstPixels[i].b = 0;
                dstPixels[i].a = 0;
            }
        }

        dstIDMap.SetPixels32(dstPixels);
        byte[] bytes = dstIDMap.EncodeToTGA();

        string suffix = "UnknownFormat";
        if (dst == IDMapFormat.R8)
        {
            suffix = "R8";
        }
        else if (dst == IDMapFormat.R8G8)
        {
            suffix = "R8G8";
        }

        string dstName = srcIDMap.name;
        if (dstName.EndsWith("_R8", true, System.Globalization.CultureInfo.CurrentCulture))
        {
            dstName = dstName.Substring(0, dstName.Length - 3);
        }
        else if (dstName.EndsWith("_R8G8", true, System.Globalization.CultureInfo.CurrentCulture))
        {
            dstName = dstName.Substring(0, dstName.Length - 5);
        }

        File.WriteAllBytes(string.Format("Assets/Resources/{0}/{1}_{2}.tga", m_OutputFolder, dstName, suffix), bytes);
        AssetDatabase.Refresh();
#endif
    }
}
