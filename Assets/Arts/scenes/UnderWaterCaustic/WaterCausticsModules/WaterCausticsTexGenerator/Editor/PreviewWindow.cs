// WaterCausticsModules
// Copyright (c) 2021 Masataka Hakozaki

using System.IO;
using UnityEditor;
using UnityEngine;

namespace MH.WaterCausticsModules {
    internal class PreviewWindow : EditorWindow {
        // --------------------------------------------------------------- Static
        public static void OpenWindow (WaterCausticsTexGenerator target) {
            var win = GetWindow<PreviewWindow> (true);
            PreviewWindowStore.instance.window = win;
            win.setTarget (target);
        }

        public static void SetTargetIfShowing (WaterCausticsTexGenerator target) {
            var win = PreviewWindowStore.instance.window;
            if (win != null)
                win.setTarget (target);
        }

        public static void RemoveTarget (WaterCausticsTexGenerator target) {
            var win = PreviewWindowStore.instance.window;
            if (win != null && win._target == target)
                win.setTarget (null);
        }

        public static bool IsShowing () {
            return EditorWindow.HasOpenInstances<PreviewWindow> ();
        }

        public static void InspectorChanged (WaterCausticsTexGenerator target) {
            var win = PreviewWindowStore.instance.window;
            if (win != null && win._target == target)
                win.inspectorChanged ();
        }

        public static void CloseWindow () {
            var win = PreviewWindowStore.instance.window;
            if (win != null)
                win.Close ();
        }

        // --------------------------------------------------------------- 

        // --------------------------------------------------------------- SerializeField
        [SerializeField] private Texture m_iconUnlock;
        [SerializeField] private Texture m_iconLock;
        [SerializeField] private Texture m_iconPause;
        [SerializeField] private Texture m_iconResume;
        [SerializeField] private Texture m_iconMenu;
        [SerializeField] private Shader m_shaderIcon;

        private WaterCausticsTexGenerator _target, _subTarget;
        private RenderTexture _rt;
        private double _lastTime;

        private bool __locked;
        private bool isLocked {
            get => __locked;
            set {
                __locked = value;
                if (value == false)
                    setTarget (_subTarget);
            }
        }

        // --------------------------------------------------------------- Event
        private void OnEnable () { }

        private void OnDisable () {
            releaseTarget ();
            releaseTmpRT ();
        }

        private void OnDestroy () {
            releaseTarget ();
            releaseTmpRT ();
            destroy (ref __matIcon);
        }

        private void destroy<T> (ref T o) where T : Object {
            if (o == null) return;
            if (Application.isPlaying)
                Destroy (o);
            else
                DestroyImmediate (o);
            o = null;
        }

        // --------------------------------------------------------------- Target
        private void releaseTarget () {
            if (_target != null) _target.FinishPreview ();
            _target = null;
        }
        private void setTarget (WaterCausticsTexGenerator target) {
            if (isLocked) {
                _subTarget = target;
                return;
            }
            if (_target != target)
                releaseTarget ();
            _target = _subTarget = target;
            _lastTime = EditorApplication.timeSinceStartup;
            setTitle ();
            previewUpdate (isInspectorChanged: true);
        }

        private void setTitle () {
            string tarName = (_target != null) ? _target.name : "No Generator";
            this.titleContent = new GUIContent (tarName);
        }

        private void inspectorChanged () {
            previewUpdate (isInspectorChanged: true);
        }


        // --------------------------------------------------------------- RenderTexture
        private void releaseTmpRT () {
            if (_rt) RenderTexture.ReleaseTemporary (_rt);
            _rt = null;
        }

        private void getTmpRT (RenderTexture rt) {
            if (rt) _rt = RenderTexture.GetTemporary (rt.descriptor);
        }


        // --------------------------------------------------------------- Material
        private Material __matIcon;
        private Material matIcon () {
            if (__matIcon == null) {
                if (m_shaderIcon == null) {
                    Debug.LogError ("Shader is null. " + this);
                    Close ();
                } else {
                    __matIcon = new Material (m_shaderIcon);
                    __matIcon.hideFlags = HideFlags.HideAndDontSave;
                }
            }
            return __matIcon;
        }


        // --------------------------------------------------------------- OnGUI

        private bool isLockable => (_target != null);
        private bool isPauseable => (_target != null && (!Application.isPlaying || !_target.isActiveAndEnabled));
        private Rect getIconRect (float x, float y, float iconW = 16f) {
            var iconHalf = iconW * 0.5f;
            return new Rect (position.width - x - iconHalf, y - iconHalf, iconW, iconW);
        }

        private bool clickCheck (Vector2 mousePos, float x, float y, float r) {
            return (mousePos - new Vector2 (position.width - x, y)).sqrMagnitude < r * r;
        }

        void OnGUI () {
            // Draw Contents
            var winW = position.width;

            if (_rt != null) {
                EditorGUI.DrawPreviewTexture (new Rect (0, 0, winW, winW), _rt, null, ScaleMode.StretchToFill, 0);
            } else if (_target != null) {
                GUILayout.Space (position.size.y / 2 - 10);
                EditorGUILayout.LabelField ("No Output Render Texture", StyleConstant.alertPinkCenter);
            } else {
                isLocked = false;
                GUILayout.Space (position.size.y / 2 - 10);
                EditorGUILayout.LabelField ("No Generator Selected", StyleConstant.alertCenter);
            }
            EditorGUI.DrawPreviewTexture (getIconRect (10f, 10f), m_iconMenu, matIcon (), ScaleMode.StretchToFill, 0);
            if (isLockable)
                EditorGUI.DrawPreviewTexture (getIconRect (30f, 10f), isLocked ? m_iconLock : m_iconUnlock, matIcon (), ScaleMode.StretchToFill, 0);
            if (isPauseable)
                EditorGUI.DrawPreviewTexture (getIconRect (50f, 10f), s_isPause ? m_iconPause : m_iconResume, matIcon (), ScaleMode.StretchToFill, 0);


            // Support Click
            if (Event.current != null && Event.current.type == EventType.MouseDown && Event.current.button == 0) {
                var mousePos = Event.current.mousePosition;
                if (isLockable && clickCheck (mousePos, x : 10f, y : 10f, r : 10f))
                    openContext ();
                else if (isLockable && clickCheck (mousePos, x : 30f, y : 10f, r : 10f))
                    toggleLock ();
                else if (isPauseable && clickCheck (mousePos, x : 50f, y : 10f, r : 10f))
                    togglePause ();
            }

            // ContextMenu
            Event evt = Event.current;
            if (evt.type == EventType.ContextClick) {
                openContext ();
                evt.Use ();
            }
        }

        private void openContext () {
            GenericMenu menu = new GenericMenu ();
            var winW = position.width;
            if (isPauseable) {
                menu.AddItem (new GUIContent ("Pause", "Stop the movement of the waves."), s_isPause, (o) => togglePause (), null);
                menu.AddSeparator ("");
            }
            if (isLockable) {
                menu.AddItem (new GUIContent ("Lock", "Unlocked when entered into play mode."), isLocked, (o) => toggleLock (), null);
                menu.AddSeparator ("");
            }
            string curSize = $"Window Size ({winW.ToString ("F0")}x{winW.ToString ("F0")})/";
            if (_rt && _rt.width == _rt.height) {
                string rtW = _rt.width.ToString ("F0");
                menu.AddItem (new GUIContent ($"{curSize}Fit Texture {rtW}x{rtW}"), winW == _rt.width, specifyWindowSize, (float) _rt.width);
                menu.AddSeparator (curSize);
            }
            menu.AddItem (new GUIContent ($"{curSize}128x128"), winW == 128f, specifyWindowSize, 128f);
            menu.AddItem (new GUIContent ($"{curSize}256x256"), winW == 256f, specifyWindowSize, 256f);
            menu.AddItem (new GUIContent ($"{curSize}512x512"), winW == 512f, specifyWindowSize, 512f);
            menu.AddItem (new GUIContent ($"{curSize}1024x1024"), winW == 1024f, specifyWindowSize, 1024f);

            menu.AddItem (new GUIContent ($"FrameRate ({s_frameRate})/30"), s_frameRate == 30f, setFrameRate, 30f);
            menu.AddItem (new GUIContent ($"FrameRate ({s_frameRate})/60"), s_frameRate == 60f, setFrameRate, 60f);
            menu.AddItem (new GUIContent ($"FrameRate ({s_frameRate})/120"), s_frameRate == 120f, setFrameRate, 120f);
            menu.AddItem (new GUIContent ($"FrameRate ({s_frameRate})/240"), s_frameRate == 240f, setFrameRate, 240f);

            if (_target != null) {
                menu.AddSeparator ("");
                menu.AddItem (new GUIContent ("Select Generator :  " + _target.name), false, (o) => pingAndSelect (_target, true), null);
                if (_target.renderTexture != null) {
                    bool isLocking = isLockable && isLocked;
                    string action = isLocking ? "Select" : "Ping";
                    menu.AddItem (new GUIContent (action + " Texture :  " + _target.renderTexture.name), false, (o) => pingAndSelect (_target.renderTexture, isLocking), null);
                    if (_rt != null) {
                        menu.AddSeparator ("");
                        menu.AddItem (new GUIContent ("Save PNG"), false, savePng, null);
                    }
                }
            }
            menu.AddSeparator ("");
            menu.AddItem (new GUIContent ("Close"), false, (o) => Close (), null);

            menu.ShowAsContext ();
        }


        private string _preSavePngPath;
        private void savePng (object o) {
            if (_target == null || _target.renderTexture == null || _rt == null) return;
            string defaultPath = string.IsNullOrEmpty (_preSavePngPath) ? Application.dataPath : Path.GetDirectoryName (_preSavePngPath);
            string defaultName = string.IsNullOrEmpty (_preSavePngPath) ? "WaterCausticsTexSnapshot" : Path.GetFileNameWithoutExtension (_preSavePngPath);
            string path = EditorUtility.SaveFilePanel ("Save PNG Image", defaultPath, defaultName, "png");
            if (string.IsNullOrEmpty (path)) return;
            _preSavePngPath = path;

            Texture2D tex = new Texture2D (_rt.width, _rt.height, TextureFormat.RGB24, false);
            var tmp = RenderTexture.active;
            RenderTexture.active = _rt;
            tex.ReadPixels (new Rect (0, 0, _rt.width, _rt.height), 0, 0);
            if (PlayerSettings.colorSpace == ColorSpace.Linear) {
                var pixels = tex.GetPixels ();
                for (int i = 0; i < pixels.Length; i++) {
                    pixels [i].r = Mathf.Pow (pixels [i].r, 1f / 2.2f);
                    pixels [i].g = Mathf.Pow (pixels [i].g, 1f / 2.2f);
                    pixels [i].b = Mathf.Pow (pixels [i].b, 1f / 2.2f);
                }
                tex.SetPixels (pixels);
            }
            tex.Apply ();
            RenderTexture.active = tmp;

            byte [] bytes = tex.EncodeToPNG ();
            destroy (ref tex);
            File.WriteAllBytes (path, bytes);
            AssetDatabase.Refresh ();
        }

        private void pingAndSelect (Object obj, bool isSelect) {
            EditorGUIUtility.PingObject (obj);
            if (isSelect)
                Selection.activeObject = obj;
        }

        private void togglePause () {
            s_isPause = !s_isPause;
            Repaint ();
        }

        private void toggleLock () {
            isLocked = !isLocked;
            Repaint ();
        }

        private void specifyWindowSize (object w) {
            var pos = position;
            pos.size = new Vector2 ((float) w, (float) w);
            position = pos;
        }

        private void setFrameRate (object o) {
            s_frameRate = (float) o;
        }

        // --------------------------------------------------------------- Update

        private void setWindowSize () {
            var pos = position;
            if (pos.width != pos.height) {
                pos.size = new Vector2 (pos.width, pos.width);
                position = pos;
            }
        }

        static private bool s_isPause;
        static private float s_frameRate = 60f;

        private void Update () {
            if (!UnityEditorInternal.InternalEditorUtility.isApplicationActive) return;
            if (PreviewWindowStore.instance.window != this) Close ();
            setWindowSize ();
            previewUpdate ();
        }

        private void previewUpdate (bool isInspectorChanged = false) {
            var curTime = EditorApplication.timeSinceStartup;
            var deltaTime = curTime - _lastTime;
            bool isPause = (s_isPause && isPauseable);
            float rate = isPause ? 1f / 2f : 1f / s_frameRate;
            if (deltaTime >= rate || isInspectorChanged) {
                _lastTime = curTime;
                bool usablePreview = (_target != null && _target.renderTexture != null);
                if (usablePreview) {
                    releaseTmpRT ();
                    getTmpRT (_target.renderTexture);
                    if (deltaTime > 0.15 || isPause) deltaTime = 0;
                    _target.Preview ((float) deltaTime, _rt);
                    if (!Application.isPlaying) {
                        SceneView.RepaintAll ();
                        // repaintGameView ();
                    }
                } else {
                    releaseTmpRT ();
                }
                Repaint ();
            }
        }

        // ゲームビュー再描画 ※インスペクタで入力が出来なくなる
        // private void repaintGameView () {
        //     var assembly = typeof (EditorWindow).Assembly;
        //     var type = assembly.GetType ("UnityEditor.GameView");
        //     var gameview = EditorWindow.GetWindow (type);
        //     gameview.Repaint ();
        // }


        // --------------------------------------------------------------- Style

        private static class StyleConstant {
            public static GUIStyle alertCenter;
            public static GUIStyle alertPink;
            public static GUIStyle alertPinkCenter;
            static StyleConstant () {
                alertPink = new GUIStyle ("Label");
                alertPink.normal.textColor = new Color (1f, 0.3f, 0.6f, 1f);

                alertPinkCenter = new GUIStyle (alertPink);
                alertPinkCenter.alignment = TextAnchor.MiddleCenter;

                alertCenter = new GUIStyle ("Label");
                alertCenter.alignment = TextAnchor.MiddleCenter;
            }
        }


        // ---------------------------------------------------------------

    }


    // --------------------------------------------------------------- Singleton
    internal class PreviewWindowStore : ScriptableSingleton<PreviewWindowStore> {
        public PreviewWindow window;
    }


    // ---------------------------------------------------------------
}
