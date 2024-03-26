using System;
using System.Collections;
using System.Collections.Generic;
#if UNITY_EDITOR
using UnityEditor.Rendering;
using UnityEditor;
#endif
using UnityEditor.Rendering.Universal;
using UnityEditor.Rendering.Universal.ShaderGUI;
using UnityEngine;
using static Unity.Rendering.Universal.ShaderUtils;

using UnityEngine;
using UnityEngine.Rendering;

namespace UnityEditor
{
    
    internal static class Property
    {
        public static readonly string SpecularWorkflowMode = "_WorkflowMode";
        public static readonly string SurfaceType = "_Surface";
        public static readonly string BlendMode = "_Blend";
        public static readonly string AlphaClip = "_AlphaClip";
        public static readonly string AlphaToMask = "_AlphaToMask";
        public static readonly string SrcBlend = "_SrcBlend";
        public static readonly string DstBlend = "_DstBlend";
        public static readonly string SrcBlendAlpha = "_SrcBlendAlpha";
        public static readonly string DstBlendAlpha = "_DstBlendAlpha";
        public static readonly string BlendModePreserveSpecular = "_BlendModePreserveSpecular";
        public static readonly string ZWrite = "_ZWrite";
        public static readonly string CullMode = "_Cull";
        public static readonly string CastShadows = "_CastShadows";
        public static readonly string ReceiveShadows = "_ReceiveShadows";
        public static readonly string QueueOffset = "_QueueOffset";

        // for ShaderGraph shaders only
        public static readonly string ZTest = "_ZTest";
        public static readonly string ZWriteControl = "_ZWriteControl";
        public static readonly string QueueControl = "_QueueControl";

        // Global Illumination requires some properties to be named specifically:
        public static readonly string EmissionMap = "_EmissionMap";
        public static readonly string EmissionColor = "_EmissionColor";
    }
     class LitHeroGUI : ShaderGUI
    {
        protected class Styles
        {
            /// <summary>
            /// The names for options available in the SurfaceType enum.
            /// </summary>
            public static readonly string[] materialTypeName = Enum.GetNames(typeof(MaterialType));

            public static readonly GUIContent castShadowText = EditorGUIUtility.TrTextContent("Cast Shadows",
                "When enabled, this GameObject will cast shadows onto any geometry that can receive them.");

            public static readonly GUIContent materialTypeContent = EditorGUIUtility.TrTextContent("Shader Mode",
                "选择头发渲染，皮肤渲染对应的shader");

        }

        public enum MaterialType
        {
            /// <summary>
            /// Show Original GUI
            /// </summary>
            DefaultGUI,
            
            /// <summary>
            /// Use this for Hair alpha test.
            /// </summary>
            Hair_Nei,

            /// <summary>
            /// Use this for Hair doubleSided rendering.
            /// </summary>
            Hair_Wai,

            /// <summary>
            /// Use this for Skin rendering.
            /// </summary>
            Skin,
            
            /// <summary>
            /// Use this for Eye rendering.
            /// </summary>
            Eye,
            
            /// <summary>
            /// Use this for item rendering.
            /// </summary>
            StandardPBR

        }

        static List<MaterialData> defaultGUIList = new List<MaterialData>();

        /// <summary>
        /// All of thr
        /// </summary>
        static List<MaterialData> commonPropertiesList = new List<MaterialData>();

        /// <summary>
        /// the hair nei related properties will added into this list, later be drawn in gui.
        /// </summary>
        static List<MaterialData> hairNeiPropertiesList = new List<MaterialData>();
        static List<MaterialData> hairWaiPropertiesList = new List<MaterialData>();
        static List<MaterialData> skinPropertiesList = new List<MaterialData>();
        static List<MaterialData> eyePropertiesList = new List<MaterialData>();

        public class MaterialData
        {
            public MaterialProperty prop;
            public bool indentLevel = false;
        }


        protected MaterialProperty castShadowForHeroMat { get; set; }

        protected MaterialProperty materialType { get; set; }

        static int selectedMaterialType = 0;
        private void FindProperties(MaterialProperty[] properties)
        {
            castShadowForHeroMat = FindProperty("_CastShadow", properties, false);
            materialType = FindProperty("_MATERIAL_TYPE", properties, false);
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            FindProperties(properties);
            Material currMat = materialEditor.target as Material;
            if (currMat == null)
            {
                Debug.Log("Material Error Here: can't find related material");
                return;
            }

            Shader shader = currMat.shader;

            defaultGUIList.Clear();
            hairNeiPropertiesList.Clear();
            hairWaiPropertiesList.Clear();
            skinPropertiesList.Clear();
            eyePropertiesList.Clear();
            commonPropertiesList.Clear();
            for (int i = 0; i < properties.Length; i++)
            {
                var propertity = properties[i];
                var attributes = shader.GetPropertyAttributes(i);
                defaultGUIList.Add(new MaterialData() {prop = propertity, indentLevel = false});
                foreach (var item in attributes)
                {
                    if (item.Contains("COMMON"))
                    {
                        hairNeiPropertiesList.Add(new MaterialData() {prop = propertity, indentLevel = false});
                        hairWaiPropertiesList.Add(new MaterialData() {prop = propertity, indentLevel = false});
                        skinPropertiesList.Add(new MaterialData() {prop = propertity, indentLevel = false});
                        eyePropertiesList.Add(new MaterialData() {prop = propertity, indentLevel = false});
                        commonPropertiesList.Add(new MaterialData() {prop = propertity, indentLevel = false});
                    }
                    else if (item.Contains("HAIR_NEI"))
                    {
                        hairNeiPropertiesList.Add(new MaterialData() {prop = propertity, indentLevel = false});
                    }
                    else if (item.Contains("HAIR_WAI"))
                    {
                        hairWaiPropertiesList.Add(new MaterialData() {prop = propertity, indentLevel = false});
                    }
                    else if (item.Contains("SKIN"))
                    {
                        skinPropertiesList.Add(new MaterialData() {prop = propertity, indentLevel = false});
                    }
                    else if (item.Contains("Eye"))
                    {
                        eyePropertiesList.Add(new MaterialData() {prop = propertity, indentLevel = false});
                    }
                }
            }
            
            
            EditorGUI.BeginChangeCheck();
            selectedMaterialType = materialEditor.PopupShaderProperty(materialType, Styles.materialTypeContent, Styles.materialTypeName);
            if (EditorGUI.EndChangeCheck())
            {
                SwitchShaderIfNeeded(selectedMaterialType, currMat);

                switch (selectedMaterialType)
                {
                    case (int) MaterialType.Hair_Nei:
                        SetDrawHairNeiKeyWord(currMat);
                        break;
                    case (int) MaterialType.Hair_Wai:
                        SetDrawHairWaiKeyWord(currMat);
                        break;
                    case (int) MaterialType.Skin:
                        SetDrawSkinKeyWord(currMat);
                        break;
                    case (int) MaterialType.Eye:
                        SetDrawEyeKeyWord(currMat);
                        break;
                    case (int) MaterialType.StandardPBR:
                        SetDrawStandardPBRKeyWord(currMat);
                        break;
                }
            }

            switch (selectedMaterialType)
            {
                case (int) MaterialType.Hair_Nei:
                    PropertiesDefaultGUI(materialEditor, hairNeiPropertiesList);
                    break;
                case (int) MaterialType.Hair_Wai:
                    PropertiesDefaultGUI(materialEditor, hairWaiPropertiesList);
                    break;
                case (int) MaterialType.Skin:
                    PropertiesDefaultGUI(materialEditor, skinPropertiesList);
                    break;
                case (int) MaterialType.Eye:
                    PropertiesDefaultGUI(materialEditor, eyePropertiesList);
                    break;                
                case (int) MaterialType.DefaultGUI:
                    PropertiesDefaultGUI(materialEditor, defaultGUIList);
                    break;
                case (int) MaterialType.StandardPBR:
                    PropertiesDefaultGUI(materialEditor, commonPropertiesList);
                    break;
            }

            // 绘制和Material相关的材质，比如是否开启阴影投射
            DrawAdditionalMatRelatedProperties(materialEditor);

        }

        private void SwitchShaderIfNeeded(int selectedMaterialType, Material thisMat)
        {
            switch (selectedMaterialType)
            {
                case (int)MaterialType.Hair_Nei:
                    thisMat.shader = Shader.Find("Elex/LitHeroSkinAndHair");
                    break;
                case (int)MaterialType.Hair_Wai:
                    thisMat.shader = Shader.Find("Elex/LitHeroSkinAndHair");
                    break;
                case (int)MaterialType.Skin:
                    thisMat.shader = Shader.Find("Elex/LitHeroSkinAndHair");
                    break;
                case (int)MaterialType.Eye:
                    thisMat.shader = Shader.Find("Elex/HeroEye");
                    break;
                case (int)MaterialType.StandardPBR:
                    thisMat.shader = Shader.Find("Elex/LitHeroItem");
                    break;
            }
        }
        public new static MaterialProperty FindProperty(string propertyName, MaterialProperty[] properties,
            bool propertyIsMandatory)
        {
            for (int index = 0; index < properties.Length; ++index)
            {
                if (properties[index] != null && properties[index].name == propertyName)
                    return properties[index];
            }

            if (propertyIsMandatory)
                throw new ArgumentException("Could not find MaterialProperty: '" + propertyName +
                                            "', Num properties: " + (object) properties.Length);
            return null;
        }


        public void PropertiesDefaultGUI(MaterialEditor materialEditor, List<MaterialData> props)
        {
            for (int i = 0; i < props.Count; i++)
            {
                MaterialProperty prop = props[i].prop;
                bool indentLevel = props[i].indentLevel;
                if ((prop.flags & (MaterialProperty.PropFlags.HideInInspector |
                                   MaterialProperty.PropFlags.PerRendererData)) == MaterialProperty.PropFlags.None)
                {
                    float propertyHeight = materialEditor.GetPropertyHeight(prop, prop.displayName);
                    Rect controlRect =
                        EditorGUILayout.GetControlRect(true, propertyHeight, EditorStyles.layerMaskField);
                    if (indentLevel) EditorGUI.indentLevel++;
                    materialEditor.ShaderProperty(controlRect, prop, prop.displayName);
                    if (indentLevel) EditorGUI.indentLevel--;
                }
            }
        }

        public void DrawAdditionalMatRelatedProperties(MaterialEditor materialEditor)
        {
            Material targetMat = materialEditor.target as Material;
            materialEditor.RenderQueueField();
            // 开关材质阴影：
            EditorGUI.BeginChangeCheck();
            MaterialEditor.BeginProperty(castShadowForHeroMat);
            bool newValue = EditorGUILayout.Toggle(Styles.castShadowText, castShadowForHeroMat.floatValue == 1);
            if (EditorGUI.EndChangeCheck())
            {
                castShadowForHeroMat.floatValue = newValue ? 1.0f : 0.0f;
                Debug.Log("ShadowSettings for mat: " + targetMat.name + " has been changed to " + newValue);
                targetMat.SetShaderPassEnabled("ShadowCaster", newValue);
            }

            MaterialEditor.EndProperty();
        }

        private void SetDrawHairNeiKeyWord(Material material)
        {
            SetMaterialSrcDstBlendProperties(material, UnityEngine.Rendering.BlendMode.One,
                UnityEngine.Rendering.BlendMode.Zero, UnityEngine.Rendering.BlendMode.One,
                UnityEngine.Rendering.BlendMode.Zero);
            material.EnableKeyword("_ALPHATEST_ON");
            material.EnableKeyword("Anisotropy");
            material.SetFloat("_Cull", (float)BaseShaderGUI.RenderFace.Front);
            material.SetFloat("_Zwrite", 1.0f);
            material.renderQueue = (int)RenderQueue.AlphaTest;
        }
        
        private void SetDrawSkinKeyWord(Material material)
        {
            SetMaterialSrcDstBlendProperties(material, UnityEngine.Rendering.BlendMode.One,
                UnityEngine.Rendering.BlendMode.Zero, UnityEngine.Rendering.BlendMode.One,
                UnityEngine.Rendering.BlendMode.Zero);
            material.DisableKeyword("_ALPHATEST_ON");
            material.DisableKeyword("Anisotropy");
            material.EnableKeyword("EnableBentNormal");
            material.SetFloat("_Cull", (float)BaseShaderGUI.RenderFace.Front);
            material.SetFloat("_Zwrite", 1.0f);
            material.renderQueue = (int)RenderQueue.Geometry;
        } 
        
        private void SetDrawEyeKeyWord(Material material)
        {
            SetMaterialSrcDstBlendProperties(material, UnityEngine.Rendering.BlendMode.One,
                UnityEngine.Rendering.BlendMode.Zero, UnityEngine.Rendering.BlendMode.One,
                UnityEngine.Rendering.BlendMode.Zero);
            material.DisableKeyword("_ALPHATEST_ON");
            material.DisableKeyword("Anisotropy");
            material.SetFloat("_Cull", (float)BaseShaderGUI.RenderFace.Front);
            material.SetFloat("_Zwrite", 1.0f);
            material.renderQueue = (int)RenderQueue.Geometry;
        }  
        
        private void SetDrawStandardPBRKeyWord(Material material)
        {
            SetMaterialSrcDstBlendProperties(material, UnityEngine.Rendering.BlendMode.One,
                UnityEngine.Rendering.BlendMode.Zero, UnityEngine.Rendering.BlendMode.One,
                UnityEngine.Rendering.BlendMode.Zero);
            material.DisableKeyword("_ALPHATEST_ON");
            material.DisableKeyword("Anisotropy");
            material.SetFloat("_Cull", (float)BaseShaderGUI.RenderFace.Front);
            material.SetFloat("_Zwrite", 1.0f);
            material.renderQueue = (int)RenderQueue.Geometry;
        } 
        

        
        private void SetDrawHairWaiKeyWord(Material material)
        {
            SetMaterialSrcDstBlendProperties(material, UnityEngine.Rendering.BlendMode.SrcAlpha,
                UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha, UnityEngine.Rendering.BlendMode.SrcAlpha,
                UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
            material.DisableKeyword("_ALPHATEST_ON");
            material.EnableKeyword("Anisotropy");
            material.SetFloat("_Cull", (float)BaseShaderGUI.RenderFace.Both);
            material.SetFloat("_Zwrite", 0.0f);
            material.renderQueue = (int)RenderQueue.Transparent + 50;
        }
        
        private static void SetMaterialSrcDstBlendProperties(Material material, UnityEngine.Rendering.BlendMode srcBlendRGB, UnityEngine.Rendering.BlendMode dstBlendRGB, UnityEngine.Rendering.BlendMode srcBlendAlpha, UnityEngine.Rendering.BlendMode dstBlendAlpha)
        {
            if (material.HasProperty(Property.SrcBlend))
                material.SetFloat(Property.SrcBlend, (float)srcBlendRGB);

            if (material.HasProperty(Property.DstBlend))
                material.SetFloat(Property.DstBlend, (float)dstBlendRGB);

            if (material.HasProperty(Property.SrcBlendAlpha))
                material.SetFloat(Property.SrcBlendAlpha, (float)srcBlendAlpha);

            if (material.HasProperty(Property.DstBlendAlpha))
                material.SetFloat(Property.DstBlendAlpha, (float)dstBlendAlpha);
        }

        private static void SetMaterialZWriteProperty(Material material, bool zwriteEnabled)
        {
            if (material.HasProperty(Property.ZWrite))
                material.SetFloat(Property.ZWrite, zwriteEnabled ? 1.0f : 0.0f);
        }

    }
}