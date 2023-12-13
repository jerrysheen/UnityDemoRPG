// WaterCausticsModules
// Copyright (c) 2021 Masataka Hakozaki

using UnityEditor;
using UnityEngine;

namespace MH.WaterCausticsModules {

    [CanEditMultipleObjects]
    [CustomEditor (typeof (WaterCausticsTexGenerator))]
    public class WaterCausticsTexGeneratorEditor : Editor {
        private SerializedProperty m_generateInEditMode;
        private SerializedProperty m_density;
        private SerializedProperty m_speed;
        private SerializedProperty m_waves;
        private SerializedProperty m_calcResolution;
        private SerializedProperty m_renderTexture;
        private SerializedProperty m_FillGapAmount;
        private SerializedProperty m_lightDirectionType;
        private SerializedProperty m_lightTransform;
        private SerializedProperty m_lightDir;
        private SerializedProperty m_lightCondensingStyle;
        private SerializedProperty m_rayStyle;
        private SerializedProperty m_brightness;
        private SerializedProperty m_gamma;
        private SerializedProperty m_clamp;
        private SerializedProperty m_refractionIndex;
        private SerializedProperty m_useChromaticAberration;
        private SerializedProperty m_chromaticAberration;
        private SerializedProperty m_computeShader;
        private SerializedProperty m_shader;

        public void findProps () {
            m_generateInEditMode = serializedObject.FindProperty ("m_generateInEditMode");
            m_density = serializedObject.FindProperty ("m_density");
            m_speed = serializedObject.FindProperty ("m_speed");
            m_waves = serializedObject.FindProperty ("m_waves");
            m_calcResolution = serializedObject.FindProperty ("m_calcResolution");
            m_renderTexture = serializedObject.FindProperty ("m_renderTexture");
            m_FillGapAmount = serializedObject.FindProperty ("m_FillGapAmount");
            m_lightDirectionType = serializedObject.FindProperty ("m_lightDirectionType");
            m_lightTransform = serializedObject.FindProperty ("m_lightTransform");
            m_lightDir = serializedObject.FindProperty ("m_lightDir");
            m_lightCondensingStyle = serializedObject.FindProperty ("m_lightCondensingStyle");
            m_rayStyle = serializedObject.FindProperty ("m_rayStyle");
            m_brightness = serializedObject.FindProperty ("m_brightness");
            m_gamma = serializedObject.FindProperty ("m_gamma");
            m_clamp = serializedObject.FindProperty ("m_clamp");
            m_refractionIndex = serializedObject.FindProperty ("m_refractionIndex");
            m_useChromaticAberration = serializedObject.FindProperty ("m_useChromaticAberration");
            m_chromaticAberration = serializedObject.FindProperty ("m_chromaticAberration");
            m_computeShader = serializedObject.FindProperty ("m_computeShader");
            m_shader = serializedObject.FindProperty ("m_shader");
        }

        readonly string [] _condensingEnumStr = {
            "StyleA",
            "StyleB",
            "StyleC",
        };

        readonly string [] _litDirEnumStr = {
            "Numeric",
            "Transform",
            "Sun",
            "Auto",
        };

        readonly string [] _resEnumStr = {
            "64 x 64",
            "96 x 96",
            "128 x 128",
            "160 x 160",
            "256 x 256",
            "320 x 320",
            "512 x 512",
        };


        private void OnEnable () {
            findProps ();
            PreviewWindow.SetTargetIfShowing (target as WaterCausticsTexGenerator);
        }

        private void OnDisable () {
            PreviewWindow.RemoveTarget (target as WaterCausticsTexGenerator);
        }

        public override void OnInspectorGUI () {
            serializedObject.Update ();
            bool isChanged = drawProperties ();
            if (isChanged) {
                PreviewWindow.InspectorChanged (target as WaterCausticsTexGenerator);
            }
            serializedObject.ApplyModifiedProperties ();
        }

        // ----------------------------------------------------------- Draw
        static bool s_maintenanceOpen, s_maintenanceUnlock;
        readonly Color colorPinkBar = new Color (1f, 0.3f, 0.6f, 0.3f);
        readonly Color colorPinkContent = new Color (1f, 0.3f, 0.6f, 1f);
        readonly Color colorGreenButton = new Color (0.0f, 1f, 0.66f, 1f);

        private bool drawProperties () {
            bool changed = false;
            bool useTextureWarning = (m_renderTexture.objectReferenceValue == null && isGameObjectOnScene ());
            if (m_generateInEditMode.isExpanded && useTextureWarning)
                drawRect (colorPinkBar);
            else
                drawRect ();
            m_generateInEditMode.isExpanded = !EditorGUILayout.Foldout (!m_generateInEditMode.isExpanded, "Generate Texture");
            if (!m_generateInEditMode.isExpanded) {
                using (new IndentScope ()) {
                    using (var check = new EditorGUI.ChangeCheckScope ()) {

                        var desc3 = new GUIContent ("Output Render Texture", "Output destination render texture.");
                        if (useTextureWarning) {
                            drawRect2WithLabel ("Calculation", colorPinkBar);
                            using (new ColorScope (colorPinkContent))
                            EditorGUILayout.PropertyField (m_renderTexture, desc3);
                        } else {
                            drawRect2WithLabel ("Calculation");
                            EditorGUILayout.PropertyField (m_renderTexture, new GUIContent ("Output Render Texture", "Output destination render texture."));
                        }

                        var desc2 = new GUIContent ("Calculate Resolution", "Resolution used for internal calculations.");
                        m_calcResolution.enumValueIndex = EditorGUILayout.Popup (desc2, m_calcResolution.enumValueIndex, _resEnumStr);

                        EditorGUILayout.PropertyField (m_FillGapAmount, new GUIContent ("Fill Gap", "If the edges of the output image are not drawn, increase the value. Make it as small as possible to reduce the load."));

                        if (targets.Length == 1) {
                            EditorGUILayout.Space (3);
                            EditorGUILayout.BeginHorizontal ();
                            GUILayout.FlexibleSpace ();
                            if (PreviewWindow.IsShowing ()) {
                                if (GUILayout.Button ("Close Preview", EditorStyles.miniButtonLeft, GUILayout.Width (150))) {
                                    PreviewWindow.CloseWindow ();
                                }
                            } else {
                                using (new ColorScope (colorGreenButton))
                                if (GUILayout.Button ("Open Preview", EditorStyles.miniButtonLeft, GUILayout.Width (150))) {
                                    PreviewWindow.OpenWindow (target as WaterCausticsTexGenerator);
                                }
                            }
                            EditorGUILayout.EndHorizontal ();
                            EditorGUILayout.Space (3);
                        }

                        drawRect2WithLabel ("Wave");
                        EditorGUILayout.PropertyField (m_density, new GUIContent ("Density", "Adjust the overall density."));
                        EditorGUILayout.PropertyField (m_speed, new GUIContent ("Speed", "Adjust the overall speed."));
                        EditorGUILayout.Space (3);
                        EditorGUILayout.PropertyField (m_waves, new GUIContent ("Waves", $"Wave settings. Supports up to {WaterCausticsTexGenerator.WAVE_MAX_CNT}."));
                        if (m_waves.arraySize >= 5) {
                            EditorGUILayout.LabelField ($"Up to {WaterCausticsTexGenerator.WAVE_MAX_CNT} waves be supported.", new GUIStyle ("HelpBox"));
                        }
                        EditorGUILayout.Space (3);

                        drawRect2WithLabel ("Refraction");
                        var desc0 = new GUIContent ("Style", "How to calculate light focusing.");
                        m_lightCondensingStyle.enumValueIndex = EditorGUILayout.Popup (desc0, m_lightCondensingStyle.enumValueIndex, _condensingEnumStr);
                        EditorGUILayout.PropertyField (m_refractionIndex, new GUIContent ("Refraction Index", "Index of refraction."));


                        m_lightDirectionType.isExpanded = EditorGUILayout.Foldout (m_lightDirectionType.isExpanded, "Details");
                        if (m_lightDirectionType.isExpanded) {

                            EditorGUILayout.PropertyField (m_useChromaticAberration, new GUIContent ("Chromatic Aberration", "Simulate more realistic chromatic aberrations. Amount of calculation increases. For mobile devices, consider using color shift sampling at the time of drawing instead."));
                            if (m_useChromaticAberration.boolValue) {
                                using (new IndentScope (-2, 5)) {
                                    EditorGUILayout.PropertyField (m_chromaticAberration, new GUIContent ("Intensity", "Shifts the refractive index in the RGB channels."));
                                }
                            }

                            var desc1 = new GUIContent ("Light Direction", "Direction of the ray from the Light.");
                            m_lightDirectionType.enumValueIndex = EditorGUILayout.Popup (desc1, m_lightDirectionType.enumValueIndex, _litDirEnumStr);

                            using (new IndentScope (1, 5)) {
                                switch ((WaterCausticsTexGenerator.LitDirTypeEnum) m_lightDirectionType.enumValueIndex) {
                                    case WaterCausticsTexGenerator.LitDirTypeEnum.Numeric:
                                        EditorGUILayout.PropertyField (m_lightDir, new GUIContent ("Direction", "Direction of the rays from the Light. It will be normalized."));
                                        break;
                                    case WaterCausticsTexGenerator.LitDirTypeEnum.Transform:
                                        EditorGUILayout.PropertyField (m_lightTransform, new GUIContent ("Transform", "Transforms the light to be referenced."));
                                        break;
                                    case WaterCausticsTexGenerator.LitDirTypeEnum.LitSettingSun:
                                        EditorGUILayout.LabelField ("Use the sun setting in the Light Settings window.", new GUIStyle ("HelpBox"));
                                        break;
                                    case WaterCausticsTexGenerator.LitDirTypeEnum.Auto:
                                    default:
                                        EditorGUILayout.LabelField ("Use the shader's global variable \"_LightDirection\".", new GUIStyle ("HelpBox"));
                                        break;
                                }
                            }
                            EditorGUILayout.PropertyField (m_rayStyle, new GUIContent ("Ray Style", "Either normalize the rays past the surface of the water or extend them to the bottom. If the light ray is oblique, there is a noticeable difference."));
                        }
                        EditorGUILayout.Space (3);

                        drawRect2WithLabel ("Adjustment");
                        EditorGUILayout.PropertyField (m_brightness, new GUIContent ("Brightness", "Adjust the brightness."));
                        EditorGUILayout.PropertyField (m_gamma, new GUIContent ("Gamma", "Adjusts the contrast."));
                        EditorGUILayout.PropertyField (m_clamp, new GUIContent ("Clamp", "Limit the brightness to this value."));

                        EditorGUILayout.Space (4);

                        changed |= check.changed;
                    }
                }
            }
            EditorGUILayout.Space (5);

            drawRect ();
            m_computeShader.isExpanded = EditorGUILayout.Foldout (m_computeShader.isExpanded, "Advanced Settings");
            if (m_computeShader.isExpanded) {
                using (new IndentScope ()) {
                    using (var check = new EditorGUI.ChangeCheckScope ()) {

                        drawRect2WithLabel ("Editor");
                        EditorGUILayout.PropertyField (m_generateInEditMode, new GUIContent ("Generate In EditMode", "Whether to generate while in edit mode."));

                        drawRect2WithLabel ("Maintenance");
                        s_maintenanceOpen = EditorGUILayout.Foldout (s_maintenanceOpen, "");
                        if (s_maintenanceOpen) {
                            EditorGUILayout.Space (-2);
                            EditorGUILayout.LabelField ("Do not touch these values if there is no problem.", new GUIStyle ("HelpBox"));
                            EditorGUILayout.Space (2);
                            s_maintenanceUnlock = !EditorGUILayout.Toggle (new GUIContent ("Lock", "Do not touch these values if there is no problem."), !s_maintenanceUnlock);
                            using (new DisableScope (s_maintenanceUnlock)) {
                                using (new IndentScope (3, 0)) {
                                    EditorGUILayout.PropertyField (m_computeShader, new GUIContent ("Compute Shader", "Compute Shader"));
                                    EditorGUILayout.PropertyField (m_shader, new GUIContent ("Shader", "Shader"));
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
            public LabelAndIndentScope (string label, int space = 0) {
                EditorGUILayout.Space (space);
                EditorGUILayout.LabelField (label);
                EditorGUI.indentLevel++;
            }
            protected override void CloseScope () {
                EditorGUI.indentLevel--;
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
