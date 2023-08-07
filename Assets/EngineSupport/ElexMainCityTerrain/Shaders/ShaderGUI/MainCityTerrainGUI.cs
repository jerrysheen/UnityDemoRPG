#if UNITY_EDITOR
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Linq;

public class MainCityTerrainGUI : ShaderGUI
{
    MaterialProperty[] m_properties;
    MaterialEditor m_materialEditor;
    //设置列表显示关键字
    public enum TERRAIN_SHADER_COMPLEXITY
    {
         _STANDARD_TERRAIN, _SIMPLE_TERRAIN
    }

    public TERRAIN_SHADER_COMPLEXITY terrainComplexity;

    override public void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {

        // render the shader properties using the default GUI
        // base.OnGUI(materialEditor, properties);

        m_properties = properties;
        m_materialEditor = materialEditor;
        // get the current keywords from the material
        Material targetMat = materialEditor.target as Material;
        string[] keyWords = targetMat.shaderKeywords;
        terrainComplexity = (TERRAIN_SHADER_COMPLEXITY)EditorGUILayout.EnumPopup("LayerCount", terrainComplexity);

        switch (terrainComplexity)
        {
            case TERRAIN_SHADER_COMPLEXITY._SIMPLE_TERRAIN:
                ShowSimpleTerrain();
                break;
            case TERRAIN_SHADER_COMPLEXITY._STANDARD_TERRAIN:
                ShowStandardTerrain();
                break;


        }

          
        bool redify = keyWords.Contains("_ENABLE_SIMPLE_TERRAIN_SHADER");
        EditorGUI.BeginChangeCheck();
        redify = EditorGUILayout.Toggle("Enable Simple Terrain", redify);
        if (EditorGUI.EndChangeCheck())
        {
            if (redify)
            {
                targetMat.EnableKeyword("_ENABLE_SIMPLE_TERRAIN_SHADER");
            }
            else
            {
                targetMat.DisableKeyword("_ENABLE_SIMPLE_TERRAIN_SHADER");
            }
            // if the checkbox is changed, reset the shader keywords
            EditorUtility.SetDirty(targetMat);
        }
    }


    public void ShowStandardTerrain()
    {
        EditorGUILayout.Space(2);
        EditorGUILayout.LabelField("Global Normal", EditorStyles.boldLabel);
        MaterialProperty _GlobalNormal = FindProperty("_GlobalNormal", m_properties, true);
        MaterialProperty _NormalStrength = FindProperty("_GlobalNormalBlendRate", m_properties, true);
        GUIContent content = new GUIContent(_GlobalNormal.displayName, _GlobalNormal.textureValue, "_GlobalNormal");
        m_materialEditor.TexturePropertySingleLine(content, _GlobalNormal);
        m_materialEditor.RangeProperty(_NormalStrength, "Normal Blend Rate");
        EditorGUILayout.Space(2);

        EditorGUILayout.LabelField("Weight Textures", EditorStyles.boldLabel);
        MaterialProperty _WeightPack0 = FindProperty("_WeightPack0", m_properties, true);
        content = new GUIContent(_WeightPack0.displayName, _WeightPack0.textureValue, "_WeightPack0");
        m_materialEditor.TexturePropertySingleLine(content, _WeightPack0);
        MaterialProperty _WeightPack1 = FindProperty("_WeightPack1", m_properties, true);
        content = new GUIContent(_WeightPack1.displayName, _WeightPack1.textureValue, "_WeightPack1");
        m_materialEditor.TexturePropertySingleLine(content, _WeightPack1);
        EditorGUILayout.Space(2);

        EditorGUILayout.LabelField("Detail Textures", EditorStyles.boldLabel);
        EditorGUILayout.LabelField("Detail Map Tilling And Offset");
        MaterialProperty _HeightPack0 = FindProperty("_HeightPack0", m_properties, true);
        EditorGUI.indentLevel++;
        m_materialEditor.TextureScaleOffsetProperty(_HeightPack0);
        EditorGUI.indentLevel--;
        content = new GUIContent(_HeightPack0.displayName, _HeightPack0.textureValue, "_HeightPack0");
        m_materialEditor.TexturePropertySingleLine(content, _HeightPack0);
        MaterialProperty _HeightPack1 = FindProperty("_HeightPack1", m_properties, true);
        content = new GUIContent(_HeightPack1.displayName, _HeightPack1.textureValue, "_HeightPack1");
        m_materialEditor.TexturePropertySingleLine(content, _HeightPack1);
        MaterialProperty _AlbedoPack0 = FindProperty("_AlbedoPack0", m_properties, true);
        content = new GUIContent(_AlbedoPack0.displayName, _AlbedoPack0.textureValue, "_AlbedoPack0");
        m_materialEditor.TexturePropertySingleLine(content, _AlbedoPack0);
        MaterialProperty _NormalPack0 = FindProperty("_NormalPack0", m_properties, true);
        content = new GUIContent(_NormalPack0.displayName, _NormalPack0.textureValue, "_NormalPack0");
        m_materialEditor.TexturePropertySingleLine(content, _NormalPack0);
        MaterialProperty _AlbedoPack1 = FindProperty("_AlbedoPack1", m_properties, true);
        content = new GUIContent(_AlbedoPack1.displayName, _AlbedoPack1.textureValue, "_AlbedoPack1");
        m_materialEditor.TexturePropertySingleLine(content, _AlbedoPack1);
        MaterialProperty _NormalPack1 = FindProperty("_NormalPack1", m_properties, true);
        content = new GUIContent(_NormalPack1.displayName, _NormalPack1.textureValue, "_NormalPack1");
        m_materialEditor.TexturePropertySingleLine(content, _NormalPack1);
        MaterialProperty _AlbedoPack2 = FindProperty("_AlbedoPack2", m_properties, true);
        content = new GUIContent(_AlbedoPack2.displayName, _AlbedoPack2.textureValue, "_AlbedoPack2");
        m_materialEditor.TexturePropertySingleLine(content, _AlbedoPack2);
        MaterialProperty _NormalPack2 = FindProperty("_NormalPack2", m_properties, true);
        content = new GUIContent(_NormalPack2.displayName, _NormalPack2.textureValue, "_NormalPack2");
        m_materialEditor.TexturePropertySingleLine(content, _NormalPack2);

        MaterialProperty _LODScale = FindProperty("_LODScale", m_properties, true);
        m_materialEditor.RangeProperty(_LODScale, "_LODScale");

    }

    public void ShowSimpleTerrain()
    {

    }
}
#endif
