// WaterCausticsModules
// Copyright (c) 2021 Masataka Hakozaki

using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace MH.WaterCausticsModules {
    [CanEditMultipleObjects]
    [CustomEditor (typeof (WaterCausticsEffect))]
    public class WaterCausticsEffectEditor : Editor {
        private SerializedProperty m_layerMask;
        private SerializedProperty m_clipOutsideVolume;
        private SerializedProperty m_texture;
        private SerializedProperty m_intensity;
        private SerializedProperty m_adjustMainLit;
        private SerializedProperty m_adjustAddLit;
        private SerializedProperty m_scale;
        private SerializedProperty m_colorShiftU;
        private SerializedProperty m_colorShiftV;
        private SerializedProperty m_waterSurfaceY;
        private SerializedProperty m_waterSurfaceAttenOffset;
        private SerializedProperty m_waterSurfaceAttenWide;
        private SerializedProperty m_litSaturation;
        private SerializedProperty m_multiplyOpaqueColor;
        private SerializedProperty m_multiplyOpaqueIntensity;
        private SerializedProperty m_normalAttenPower;
        private SerializedProperty m_normalAttenIntensity;
        private SerializedProperty m_transparentBackside;
        private SerializedProperty m_receiveShadows;
        private SerializedProperty m_useMainLight;
        private SerializedProperty m_useAdditionalLights;
        private SerializedProperty m_useImageMask;
        private SerializedProperty m_imageMaskTexture;
        private SerializedProperty m_stencilRef;
        private SerializedProperty m_stencilReadMask;
        private SerializedProperty m_stencilWriteMask;
        private SerializedProperty m_stencilComp;
        private SerializedProperty m_stencilPass;
        private SerializedProperty m_stencilFail;
        private SerializedProperty m_stencilZFail;
        private SerializedProperty m_cullMode;
        private SerializedProperty m_zWriteMode;
        private SerializedProperty m_zTestMode;
        private SerializedProperty m_depthOffsetFactor;
        private SerializedProperty m_depthOffsetUnits;
        private SerializedProperty m_shader;
        private SerializedProperty m_noTexture;
        private SerializedProperty m_syncWithShaderFunctions;

        public void findProps () {
            m_layerMask = serializedObject.FindProperty ("m_layerMask");
            m_clipOutsideVolume = serializedObject.FindProperty ("m_clipOutsideVolume");
            m_texture = serializedObject.FindProperty ("m_texture");
            m_intensity = serializedObject.FindProperty ("m_intensity");
            m_adjustMainLit = serializedObject.FindProperty ("m_adjustMainLit");
            m_adjustAddLit = serializedObject.FindProperty ("m_adjustAddLit");
            m_scale = serializedObject.FindProperty ("m_scale");
            m_colorShiftU = serializedObject.FindProperty ("m_colorShiftU");
            m_colorShiftV = serializedObject.FindProperty ("m_colorShiftV");
            m_waterSurfaceY = serializedObject.FindProperty ("m_waterSurfaceY");
            m_waterSurfaceAttenOffset = serializedObject.FindProperty ("m_waterSurfaceAttenOffset");
            m_waterSurfaceAttenWide = serializedObject.FindProperty ("m_waterSurfaceAttenWide");
            m_litSaturation = serializedObject.FindProperty ("m_litSaturation");
            m_multiplyOpaqueColor = serializedObject.FindProperty ("m_multiplyOpaqueColor");
            m_multiplyOpaqueIntensity = serializedObject.FindProperty ("m_multiplyOpaqueIntensity");
            m_normalAttenPower = serializedObject.FindProperty ("m_normalAttenPower");
            m_normalAttenIntensity = serializedObject.FindProperty ("m_normalAttenIntensity");
            m_transparentBackside = serializedObject.FindProperty ("m_transparentBackside");
            m_receiveShadows = serializedObject.FindProperty ("m_receiveShadows");
            m_useMainLight = serializedObject.FindProperty ("m_useMainLight");
            m_useAdditionalLights = serializedObject.FindProperty ("m_useAdditionalLights");
            m_useImageMask = serializedObject.FindProperty ("m_useImageMask");
            m_imageMaskTexture = serializedObject.FindProperty ("m_imageMaskTexture");
            m_stencilRef = serializedObject.FindProperty ("m_stencilRef");
            m_stencilReadMask = serializedObject.FindProperty ("m_stencilReadMask");
            m_stencilWriteMask = serializedObject.FindProperty ("m_stencilWriteMask");
            m_stencilComp = serializedObject.FindProperty ("m_stencilComp");
            m_stencilPass = serializedObject.FindProperty ("m_stencilPass");
            m_stencilFail = serializedObject.FindProperty ("m_stencilFail");
            m_stencilZFail = serializedObject.FindProperty ("m_stencilZFail");
            m_cullMode = serializedObject.FindProperty ("m_cullMode");
            m_zWriteMode = serializedObject.FindProperty ("m_zWriteMode");
            m_zTestMode = serializedObject.FindProperty ("m_zTestMode");
            m_depthOffsetFactor = serializedObject.FindProperty ("m_depthOffsetFactor");
            m_depthOffsetUnits = serializedObject.FindProperty ("m_depthOffsetUnits");
            m_shader = serializedObject.FindProperty ("m_shader");
            m_noTexture = serializedObject.FindProperty ("m_noTexture");
            m_syncWithShaderFunctions = serializedObject.FindProperty ("m_syncWithShaderFunctions");
        }


        readonly string [] _cullingEnumStr = {
            "Both",
            "Back",
            "Front",
        };


        protected virtual void OnEnable () {
            findProps ();
            _cam = (Camera.main != null && Camera.main.isActiveAndEnabled) ? Camera.main : GameObject.FindObjectOfType<Camera> (false);
        }


        public override void OnInspectorGUI () {
            serializedObject.Update ();
            bool isChanged = drawProperties ();
            serializedObject.ApplyModifiedProperties ();
            if (isChanged) {
                foreach (var tar in targets.OfType<WaterCausticsEffect> ())
                    tar.OnInspectorChanged ();
            }
        }


        private Camera _cam;
        private bool checkOpaqueTexAvailable () {
            bool? available = _cam?.GetComponent<UniversalAdditionalCameraData> ()?.requiresColorTexture;
            if (available == true) return true;
            var asset = GraphicsSettings.currentRenderPipeline as UniversalRenderPipelineAsset;
            return (asset == null) ? false : asset.supportsCameraOpaqueTexture;
        }


        private void openPipelineAssetButton () {
            var asset = GraphicsSettings.currentRenderPipeline as UniversalRenderPipelineAsset;
            EditorGUILayout.BeginHorizontal ();
            GUILayout.FlexibleSpace ();
            using (new ColorScope (colorPinkContent))
            if (GUILayout.Button ("Open Current Pipeline Asset Settings", EditorStyles.miniButtonLeft, GUILayout.Width (250))) {
                Selection.activeObject = asset;
            }
            EditorGUILayout.EndHorizontal ();
        }


        // -----------------------------------------------------------
        static bool s_maintenanceOpen, s_maintenanceUnlock;
        readonly Color colorPinkBar = new Color (1f, 0.3f, 0.6f, 0.3f);
        readonly Color colorPinkBar2 = new Color (1f, 0.3f, 0.6f, 0.25f);
        readonly Color colorPinkContent = new Color (1f, 0.3f, 0.6f, 1f);


        private bool drawProperties () {
            bool changed = false;

            // Shape Group
            drawRect ();
            m_clipOutsideVolume.isExpanded = !EditorGUILayout.Foldout (!m_clipOutsideVolume.isExpanded, "Influence Scope");
            if (!m_clipOutsideVolume.isExpanded) {
                using (var check = new EditorGUI.ChangeCheckScope ()) {
                    EditorGUILayout.Space (8);

                    using (new IndentScope (5, 0)) {
                        EditorGUI.BeginChangeCheck ();
                        EditorGUILayout.PropertyField (m_layerMask, new GUIContent ("Layer Mask", "Specify the layers to draw the effect."));
                        EditorGUILayout.Space (1);
                        EditorGUILayout.PropertyField (m_clipOutsideVolume, new GUIContent ("Clip Outside Volume", "Not draw the outside of the volume."));
                        EditorGUILayout.Space (0.5f);
                        EditorGUILayout.PropertyField (m_useImageMask, new GUIContent ("Image Mask", "Masking with an image."));
                        if (m_useImageMask.boolValue) {
                            using (new IndentScope (-2f, 0f))
                            EditorGUILayout.PropertyField (m_imageMaskTexture, new GUIContent ("Texture", "Texture to use for masking."));
                        }
                        EditorGUILayout.Space (1);
                        m_cullMode.enumValueIndex = EditorGUILayout.Popup (new GUIContent ("Render Face", "Which face to draw."), m_cullMode.enumValueIndex, _cullingEnumStr);
                    }
                    EditorGUILayout.Space (8);

                    changed |= check.changed;
                }
            }

            // Effect Group
            EditorGUILayout.Space (5);
            bool useTextureWarning = (m_texture.objectReferenceValue == null && isGameObjectOnScene ());
            if (m_texture.isExpanded && useTextureWarning)
                drawRect (colorPinkBar);
            else
                drawRect ();
            m_texture.isExpanded = !EditorGUILayout.Foldout (!m_texture.isExpanded, "Caustics Effect");
            if (!m_texture.isExpanded) {
                using (new IndentScope ()) {
                    using (var check = new EditorGUI.ChangeCheckScope ()) {
                        var discTex = new GUIContent ("Caustics Texture", "Set the Render Texture specified as the output destination in the Texture Generator.");
                        if (useTextureWarning) {
                            drawRect2WithLabel ("Texture", colorPinkBar);
                            using (new ColorScope (colorPinkContent)) {
                                EditorGUILayout.PropertyField (m_texture, discTex);
                                EditorGUILayout.Space (3);
                                EditorGUILayout.BeginHorizontal ();
                                GUILayout.FlexibleSpace ();
                                if (GUILayout.Button ("Search from this Scene", EditorStyles.miniButtonLeft, GUILayout.Width (150))) {
                                    var generator = FindObjectOfType<WaterCausticsTexGenerator> ();
                                    if (generator != null)
                                        m_texture.objectReferenceValue = generator.renderTexture;
                                    else
                                        Debug.LogWarning ("There is no WaterCausticsTexGenerator in this scene.\n");
                                }
                                EditorGUILayout.EndHorizontal ();
                            }
                        } else {
                            drawRect2WithLabel ("Texture");
                            EditorGUILayout.PropertyField (m_texture, discTex);
                        }
                        drawRect2WithLabel ("Dimensions");
                        EditorGUILayout.PropertyField (m_scale, new GUIContent ("Scale", "Texture size at the height of the water surface."));
                        EditorGUILayout.PropertyField (m_waterSurfaceY, new GUIContent ("Water Surface Y", "Height of the water surface. Y-axis. The projected position of the light is calculated with respect to this plane."));
                        using (new LabelAndIndentScope ("Near Surface Attenuation", 2f, -2f, 2f)) {
                            EditorGUILayout.PropertyField (m_waterSurfaceAttenWide, new GUIContent ("Width", "Attenuation width near the water surface."));
                            EditorGUILayout.PropertyField (m_waterSurfaceAttenOffset, new GUIContent ("Offset", "Adjustment of height where attenuation starts."));
                        }
                        drawRect2WithLabel ("Effect");
                        EditorGUILayout.PropertyField (m_intensity, new GUIContent ("Intensity", "Intensity of effect."));
                        using (new IndentScope (-2f, 2f)) {
                            using (new DisableScope (m_useMainLight.boolValue)) {
                                EditorGUILayout.PropertyField (m_adjustMainLit, new GUIContent ("Main Light", "Adjust the intensity of the main light."));
                            }
                            using (new DisableScope (m_useAdditionalLights.boolValue)) {
                                EditorGUILayout.PropertyField (m_adjustAddLit, new GUIContent ("Additional Lights", "Adjust the intensity of the additional lights."));
                            }
                        }
                        EditorGUILayout.PropertyField (m_colorShiftU, new GUIContent ("Color Shift X", "Shifts the RGB channels. X-axis."));
                        EditorGUILayout.PropertyField (m_colorShiftV, new GUIContent ("Color Shift Z", "Shifts the RGB channels. Z-axis."));
                        litleSpace ();
                        EditorGUILayout.PropertyField (m_litSaturation, new GUIContent ("Light Color Saturation", "Color intensity of the light."));
                        using (new LabelAndIndentScope ("Normal Attenuation", 2f, -2f, 2f)) {
                            EditorGUILayout.PropertyField (m_normalAttenIntensity, new GUIContent ("Intensity", "Attenuation due to the angle between the normal and the light ray."));
                            using (new DisableScope (m_normalAttenIntensity.floatValue > 0f)) {
                                EditorGUILayout.PropertyField (m_normalAttenPower, new GUIContent ("Power", "Power the attenuation value."));
                                EditorGUILayout.PropertyField (m_transparentBackside, new GUIContent ("Transparent Backside", "The intensity of light transmitted to the back side"));
                            }
                        }
                        EditorGUILayout.PropertyField (m_multiplyOpaqueColor, new GUIContent ("Multiply Opaque Color", "Multiply opaque texture color. * Opaque Texture is required. Turn it on in the pipeline asset settings or in the camera settings."));
                        if (m_multiplyOpaqueColor.boolValue) {
                            bool opaqueTexAvailable = checkOpaqueTexAvailable ();
                            if (!opaqueTexAvailable)
                                drawRectPrevious (colorPinkBar2, 15f);
                            using (new IndentScope (-2f, 0f)) {
                                EditorGUILayout.PropertyField (m_multiplyOpaqueIntensity, new GUIContent ("Intensity", "The intensity of multiplying opaque texture colors."));
                                if (!opaqueTexAvailable) {
                                    EditorGUILayout.Space (1);
                                    EditorGUILayout.HelpBox ("Opaque Texture is required to use this setting.\nTurn it on in the pipeline asset settings or in the camera settings.", MessageType.Warning);
                                    drawRectPrevious (colorPinkBar, 30f);
                                    openPipelineAssetButton ();
                                    EditorGUILayout.Space (5);
                                }
                            }
                        }

                        drawRect2WithLabel ("Light");
                        EditorGUILayout.PropertyField (m_useMainLight, new GUIContent ("Use Main Light", "Calculate the main light."));
                        EditorGUILayout.PropertyField (m_useAdditionalLights, new GUIContent ("Use Additional Lights", "Calculate the additional lights."));
                        EditorGUILayout.PropertyField (m_receiveShadows, new GUIContent ("Receive Shadows", "Calculate the shadows."));

                        changed |= check.changed;
                    }
                }
            }

            // Advanced Setting Group
            EditorGUILayout.Space (5);
            drawRect ();
            m_zTestMode.isExpanded = EditorGUILayout.Foldout (m_zTestMode.isExpanded, "Advanced Settings");
            if (m_zTestMode.isExpanded) {
                using (new IndentScope ()) {
                    using (var check = new EditorGUI.ChangeCheckScope ()) {

                        drawRect2WithLabel ("Sync");
                        EditorGUILayout.PropertyField (m_syncWithShaderFunctions, new GUIContent ("Sync With Custom Functions", "Transmits the settings to the WaterCausticsEmissionSync function embedded in the shader. Turning this On will copy the settings to a global shader variable. If there is more than one of this effect at the same time, only one should be On."));

                        drawRect2WithLabel ("Material");
                        m_zWriteMode.isExpanded = EditorGUILayout.Foldout (m_zWriteMode.isExpanded, (m_zWriteMode.isExpanded ? "Culling" : "Culling / Depth"));
                        if (m_zWriteMode.isExpanded) {
                            using (new IndentScope (2f, 0f)) {
                                EditorGUILayout.PropertyField (m_cullMode, new GUIContent ("Cull", "Controls which sides of polygons should be culled (not drawn)"));
                            }
                            using (new LabelAndIndentScope ("Depth", 2f, 1f, 4f)) {
                                EditorGUILayout.PropertyField (m_zWriteMode, new GUIContent ("ZWrite", "Whether to write depth values to the depth buffer."));
                                EditorGUILayout.PropertyField (m_zTestMode, new GUIContent ("ZTest", "Comparison method with already existing depth values."));
                                litleSpace ();
                                EditorGUILayout.PropertyField (m_depthOffsetFactor, new GUIContent ("Offset Factor", "Offset Factor"));
                                EditorGUILayout.PropertyField (m_depthOffsetUnits, new GUIContent ("Offset Units", "Offset Units"));
                            }
                        }
                        EditorGUILayout.Space (2);
                        m_stencilRef.isExpanded = EditorGUILayout.Foldout (m_stencilRef.isExpanded, "Stencil");
                        if (m_stencilRef.isExpanded) {
                            using (new IndentScope ()) {
                                EditorGUILayout.PropertyField (m_stencilRef, new GUIContent ("Ref", "Stencil Reference Value"));
                                EditorGUILayout.PropertyField (m_stencilReadMask, new GUIContent ("ReadMask", "Stencil Read Mask"));
                                EditorGUILayout.PropertyField (m_stencilWriteMask, new GUIContent ("WriteMask", "Stencil Write Mask"));
                                EditorGUILayout.PropertyField (m_stencilComp, new GUIContent ("Comp", "Stencil Compare Operation"));
                                EditorGUILayout.PropertyField (m_stencilPass, new GUIContent ("Pass", "Stencil Pass Operation"));
                                EditorGUILayout.PropertyField (m_stencilFail, new GUIContent ("Fail", "Stencil Fail Operation"));
                                EditorGUILayout.PropertyField (m_stencilZFail, new GUIContent ("ZFail", "Stencil Z Fail Operation"));
                            }
                        }

                        drawRect2WithLabel ("Maintenance");
                        s_maintenanceOpen = EditorGUILayout.Foldout (s_maintenanceOpen, "");
                        if (s_maintenanceOpen) {
                            EditorGUILayout.Space (-2);
                            EditorGUILayout.LabelField ("Do not touch these values if there is no problem.", new GUIStyle ("HelpBox"));
                            EditorGUILayout.Space (2);
                            s_maintenanceUnlock = !EditorGUILayout.Toggle (new GUIContent ("Lock", "Do not touch these values if there is no problem."), !s_maintenanceUnlock);
                            using (new DisableScope (s_maintenanceUnlock)) {
                                using (new IndentScope (3, 0)) {
                                    EditorGUILayout.PropertyField (m_noTexture, new GUIContent ("No Texture Image", "Image to be displayed when no texture is found."));
                                    EditorGUILayout.Space (3);
                                    EditorGUILayout.PropertyField (m_shader, new GUIContent ("Shader", "Shader for rendering effects."));
                                }
                            }
                        }

                        changed |= check.changed;
                    }
                }
            }

            EditorGUILayout.Space (20);
            return changed;
        }


        // ----------------------------------------------------------- Parts


        private void litleSpace () {
            EditorGUILayout.Space (2);
        }

        bool isGameObjectOnScene () {
            return (target as Component).gameObject.scene.IsValid ();
        }

        private void drawRect () {
            drawRect (new Color (0f, 0f, 0f, 0.2f));
        }

        private void drawRect (Color color) {
            Rect rect = GUILayoutUtility.GetRect (0, 0);
            rect.height = EditorGUIUtility.singleLineHeight + 2;
            rect.x -= 15;
            rect.width += 15;
            EditorGUI.DrawRect (rect, color);
        }

        private void drawRect (float height, Color color) {
            Rect rect = GUILayoutUtility.GetRect (0, 0);
            rect.height = height;
            rect.x -= 15;
            rect.width += 15;
            EditorGUI.DrawRect (rect, color);
        }

        private void drawRectPrevious (Color color, float indent = 0f) {
            Rect rect = GUILayoutUtility.GetLastRect ();
            rect.x += indent;
            rect.width -= indent;
            EditorGUI.DrawRect (rect, color);
        }

        private void drawRect2WithLabel (string label) {
            drawRect2WithLabel (label, new Color (1f, 1f, 1f, 0.05f));
        }

        private void drawRect2WithLabel (string label, Color color) {
            EditorGUILayout.Space (10);
            Rect rect = GUILayoutUtility.GetRect (0, 0);
            rect.height = EditorGUIUtility.singleLineHeight - 2;
            rect.y += 3;
            EditorGUI.DrawRect (rect, color);
            GUILayout.Label (label);
            EditorGUILayout.Space (3);
        }


        // ----------------------------------------------------------- Scope

        private class LabelAndIndentScope : GUI.Scope {
            private float _spaceBtm;
            public LabelAndIndentScope (string label, float spaceTop = 0f, float spaceMid = 2f, float spaceBtm = 0f) {
                _spaceBtm = spaceBtm;
                EditorGUILayout.Space (spaceTop);
                EditorGUILayout.LabelField (label);
                EditorGUILayout.Space (spaceMid);
                EditorGUI.indentLevel++;
            }
            protected override void CloseScope () {
                EditorGUI.indentLevel--;
                EditorGUILayout.Space (_spaceBtm);
            }
        }


        private class IndentScope : GUI.Scope {
            private float _spaceBtm;
            public IndentScope (float spaceTop = 3f, float spaceBtm = 10f) {
                _spaceBtm = spaceBtm;
                EditorGUILayout.Space (spaceTop);
                EditorGUI.indentLevel++;
            }
            protected override void CloseScope () {
                EditorGUI.indentLevel--;
                EditorGUILayout.Space (_spaceBtm);
            }
        }


        private class DisableScope : GUI.Scope {
            private readonly bool _tmp;
            public DisableScope (bool isActive = false) {
                _tmp = isActive;
                if (!_tmp) EditorGUI.BeginDisabledGroup (true);
            }
            protected override void CloseScope () {
                if (!_tmp) EditorGUI.EndDisabledGroup ();
            }
        }

        private class ColorScope : GUI.Scope {
            private readonly Color _tmp;
            public ColorScope (Color color) {
                _tmp = GUI.color;
                GUI.color = color;
            }
            protected override void CloseScope () {
                GUI.color = _tmp;
            }
        }

        // ----------------------------------------------------------- 
    }


}
