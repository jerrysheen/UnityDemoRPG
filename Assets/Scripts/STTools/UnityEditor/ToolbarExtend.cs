#if UNITY_EDITOR
using System.Collections;
using System.Reflection;
using UnityEditor;
using UnityEngine;
using Object = UnityEngine.Object;
using System;
//using DEBUG_WINDOW;
using UnityEngine.SceneManagement;
#if UNITY_2019_1_OR_NEWER
using UnityEngine.UIElements;
#else
using UnityEngine.Experimental.UIElements;
#endif

namespace EditorExtend
{
    [InitializeOnLoad]
    public class ToolbarExtend
    {
        private static readonly Type containterType = typeof(IMGUIContainer);
        private static readonly Type TOOLBAR_TYPE = typeof(UnityEditor.Editor).Assembly.GetType("UnityEditor.Toolbar");
        private static readonly Type GUIVIEW_TYPE = typeof(UnityEditor.Editor).Assembly.GetType("UnityEditor.GUIView");
        private static ScriptableObject sCurrentToolbar;

#if UNITY_2020_1_OR_NEWER
        private static readonly Type backendType = typeof(UnityEditor.Editor).Assembly.GetType("UnityEditor.IWindowBackend");

        private static readonly PropertyInfo guiBackend = GUIVIEW_TYPE.GetProperty("windowBackend",
            BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
        private static readonly PropertyInfo VISUALTREE_PROPERTYINFO = backendType.GetProperty("visualTree",
            BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);

#else
        private static readonly PropertyInfo VISUALTREE_PROPERTYINFO = GUIVIEW_TYPE.GetProperty("visualTree",
           BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
#endif
        private static readonly FieldInfo ONGUI_HANDLER_FIELDINFO = containterType.GetField("m_OnGUIHandler",
            BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);


        private static ScriptableObject ms_CurrentToolbar;
        private static int ms_ToolIconCount;
        private static GUIStyle ms_CommandStyle;
        private static GUIStyle ms_CommandButtonStyle;
        private const string START_IS_GAME = "START_IS_GAME";

        /// <summary>
        /// 游戏启动时调用（仅只一次）
        /// </summary>
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        static void OnStartGame()
        {
#if UNITY_EDITOR
            Scene scene = SceneManager.GetActiveScene();
            if (!scene.name.Equals("StartGame"))
            {
                if (UnityEditor.EditorPrefs.GetBool(START_IS_GAME))
                {
                    SceneManager.LoadScene("StartGame");
                }
            }
            UnityEditor.EditorPrefs.SetBool(START_IS_GAME, false);
            //AssetDatabase.Refresh();

#endif
        }

        static ToolbarExtend()
        {
            EditorApplication.update -= OnUpdate;
            EditorApplication.update += OnUpdate;
        }

        public static GUIStyle GetCommandButtonStyle()
        {
            return ms_CommandButtonStyle;
        }

        private static void OnUpdate()
        {
#if UNITY_2021_1_OR_NEWER || UNITY_2022_1_OR_NEWER
            if (sCurrentToolbar == null)
            {
                UnityEngine.Object[] toolbars1 = Resources.FindObjectsOfTypeAll(TOOLBAR_TYPE);
                sCurrentToolbar = toolbars1.Length > 0 ? (ScriptableObject)toolbars1[0] : null;
                if (sCurrentToolbar != null)
                {
                    FieldInfo root = sCurrentToolbar.GetType().GetField("m_Root", BindingFlags.NonPublic | BindingFlags.Instance);
                    VisualElement concreteRoot = root.GetValue(sCurrentToolbar) as VisualElement;

                    VisualElement toolbarZone = concreteRoot.Q("ToolbarZoneRightAlign");
                    VisualElement parent = new VisualElement()
                    {
                        style = {
                            flexGrow = 1,
                            flexDirection = FlexDirection.Row,
                        }
                    };
                    IMGUIContainer container = new IMGUIContainer();
                    container.onGUIHandler += OnGuiBody;
                    parent.Add(container);
                    toolbarZone.Add(parent);
                }
            }
            return;
#endif
            if (ms_CurrentToolbar != null)
            {
                return;
            }

            UnityEngine.Object[] toolbars = Resources.FindObjectsOfTypeAll(TOOLBAR_TYPE);
            ms_CurrentToolbar = toolbars.Length > 0 ? (ScriptableObject)toolbars[0] : null;
            if (ms_CurrentToolbar != null)
            {


#if UNITY_2020_1_OR_NEWER
                var backend = guiBackend.GetValue(ms_CurrentToolbar);
                var elements = VISUALTREE_PROPERTYINFO.GetValue(backend, null) as VisualElement;
                var container = elements[0] as IMGUIContainer;
#else
                var elements = VISUALTREE_PROPERTYINFO.GetValue(ms_CurrentToolbar, null) as VisualElement;
                 var container = elements[0];
#endif


                var handler = ONGUI_HANDLER_FIELDINFO.GetValue(container) as Action;
                handler -= OnGUI;
                handler += OnGUI;
                ONGUI_HANDLER_FIELDINFO.SetValue(container, handler);
            }
        }
        private static void OnGUI()
        {
            var rect = new Rect(800, 3, 40, 24);
            int space = 10;
            if (GUI.Button(rect, "运行"))
            {
                EditorPrefs.SetBool(START_IS_GAME, true);
                EditorApplication.ExecuteMenuItem("Edit/Play");
            }
            rect.x += rect.width + space;
            if (GUI.Button(rect, "控制台"))
            {
                DebugPanelWindow.ShowDebugPanel();
            }
            // if (GUI.Button(rect, "更新"))
            // {
            //     GitUpdate();
            // }
        }
        private static void OnGuiBody()
        {
            //自定义按钮加在此处
            GUILayout.BeginHorizontal();
            if (GUILayout.Button(new GUIContent("运行", EditorGUIUtility.FindTexture("PlayButton"))))
            {
                //Debug.Log("运行");
                EditorPrefs.SetBool(START_IS_GAME, true);
                EditorApplication.ExecuteMenuItem("Edit/Play");
            }

            GUILayout.Space(10);
            if (GUILayout.Button(new GUIContent("控制台", EditorGUIUtility.FindTexture("Debug"))))
            {
                DebugPanelWindow.ShowDebugPanel();
            }

            GUILayout.Space(100);
            GUILayout.EndHorizontal();
        }

        // 执行命令行
        public static void ProcessCommand(string command, string argument, bool waitForExit = true)
        {
            System.Diagnostics.ProcessStartInfo info = new System.Diagnostics.ProcessStartInfo(command);
            info.Arguments = argument;
            info.CreateNoWindow = false;
            info.ErrorDialog = true;
            info.UseShellExecute = true;

            if (info.UseShellExecute)
            {
                info.RedirectStandardOutput = false;
                info.RedirectStandardError = false;
                info.RedirectStandardInput = false;
            }
            else
            {
                info.RedirectStandardOutput = true;
                info.RedirectStandardError = true;
                info.RedirectStandardInput = true;
                info.StandardOutputEncoding = System.Text.UTF8Encoding.UTF8;
                info.StandardErrorEncoding = System.Text.UTF8Encoding.UTF8;
            }

            System.Diagnostics.Process process = System.Diagnostics.Process.Start(info);

            if (!info.UseShellExecute)
            {
                Debug.Log(process.StandardOutput);
                Debug.Log(process.StandardError);
            }
            if (waitForExit)
                process.WaitForExit();
            process.Close();
        }
    }
}
#endif