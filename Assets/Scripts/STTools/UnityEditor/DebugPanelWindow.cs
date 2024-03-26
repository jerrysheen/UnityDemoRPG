#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEditor.SearchService;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UIElements;
using Scene = UnityEngine.SceneManagement.Scene;

public class DebugPanelWindow : EditorWindow
{
    // Tab状态的枚举
    private enum TabState
    {
        Tab1,
        Tab2,
        Tab3
    }

    // 当前选择的Tab状态
    private TabState currentTab = TabState.Tab1;

    [MenuItem("Window/UI Toolkit/DebugPanelWindow")]
    public static void ShowDebugPanel()
    {
        DebugPanelWindow wnd = GetWindow<DebugPanelWindow>();
        wnd.titleContent = new GUIContent("DebugPanelWindow");
    }
    public static void ShowWindow()
    {
        GetWindow<DebugPanelWindow>("Custom Editor Window");
    }

    private void OnGUI()
    {
        DrawTabs();
        DrawContentForCurrentTab();
    }

    private void DrawTabs()
    {
        GUILayout.BeginHorizontal("box", GUILayout.MaxWidth(100));
        if (GUILayout.Button("场景快速切换")) currentTab = TabState.Tab1;
        if (GUILayout.Button("渲染，性能相关按钮")) currentTab = TabState.Tab2;
        if (GUILayout.Button("Tab 3")) currentTab = TabState.Tab3;
        
        GUILayout.EndHorizontal();
    }

    private void DrawContentForCurrentTab()
    {
        GUILayout.BeginHorizontal();
        GUILayout.Space(110);  // 为Tab预留空间
        GUILayout.BeginVertical();

        switch (currentTab)
        {
            case TabState.Tab1:
                DrawSceneSwitchPanel();
                break;
            case TabState.Tab2:
                DrawQualityButton();
                break;
            case TabState.Tab3:
                DrawEditorToolsPanel();
                break;
            default:
                break;
        }

        GUILayout.EndVertical();
        GUILayout.EndHorizontal();
    }
    
    public void DrawSceneSwitchPanel()
    {
        if (GUILayout.Button("切换到场景对应资源文件夹"))
        {
            Scene currScene = SceneManager.GetActiveScene();
            string fullPath = "Assets/Arts/scenes/" + currScene.name;
            Debug.Log(fullPath);
            // 检查目录是否存在
            if (AssetDatabase.IsValidFolder(fullPath))
            {
                Debug.Log("目录存在: " + fullPath);

                // 在项目视图中选中文件夹
                var folder = AssetDatabase.LoadAssetAtPath<Object>(fullPath);
                Selection.activeObject = folder;
                EditorGUIUtility.PingObject(folder);
                //ProjectWindowUtil.ShowCreatedAsset(folder);
            }
            else
            {
                Debug.Log("目录不存在: " + fullPath);
            }
        }
        
        if (GUILayout.Button("切换到场景文件夹"))
        {
            Scene currScene = SceneManager.GetActiveScene();
            string fullPath = "Assets/Scenes";
            
            if (AssetDatabase.IsValidFolder(fullPath))
            {
                Debug.Log("目录存在: " + fullPath);

                // 在项目视图中选中文件夹
                var folder = AssetDatabase.LoadAssetAtPath<Object>(fullPath);
                Selection.activeObject = folder;
                EditorGUIUtility.PingObject(folder);
                //ProjectWindowUtil.ShowCreatedAsset(folder);
            }
            else
            {
                Debug.Log("目录不存在: " + fullPath);
            }
        }
        
        if (GUILayout.Button("内城地表Shader测试场景"))
        {
            EditorSceneManager.OpenScene("Assets/Scenes/" + "MainCityTerrainShderTest.unity", OpenSceneMode.Single);
        }
        if (GUILayout.Button("MipMap检视工具测试场景"))
        {
            EditorSceneManager.OpenScene("Assets/Scenes/" + "MipMapViewer.unity", OpenSceneMode.Single);
        }
        if (GUILayout.Button("骨骼动画场景"))
        {
            EditorSceneManager.OpenScene("Assets/Scenes/SkinMesh/" + "SkinMeshScene.unity", OpenSceneMode.Single);
        }

    }    
    
    public void DrawEditorToolsPanel()
    {

    }
    
    public void DrawQualityButton()
    {
        if (GUILayout.Button("切换shaderLOD到低"))
        {
            Shader.globalMaximumLOD = 200;
        }
        
        if (GUILayout.Button("切换shaderLOD到高"))
        {
            Shader.globalMaximumLOD = 65535;
        }
    }
    
}
 
    // [MenuItem("Window/UI Toolkit/MyEditorWindow")]
    // public static void ShowDebugPanel()
    // {
    //     DebugPanelWindow wnd = GetWindow<DebugPanelWindow>();
    //     wnd.titleContent = new GUIContent("MyEditorWindow");
    // }
    //
    // public void CreateGUI()
    // {
    //     //// Each editor window contains a root VisualElement object
    //     //VisualElement root = rootVisualElement;
    //
    //     //// VisualElements objects can contain other VisualElement following a tree hierarchy
    //     //Label label = new Label("Hello World!");
    //     //root.Add(label);
    //
    //     //// Create button
    //     //Button button = new Button();
    //     //button.name = "button";
    //     //button.text = "Button";
    //     //root.Add(button);
    //
    //     //// Create toggle
    //     //Toggle toggle = new Toggle();
    //     //toggle.name = "toggle";
    //     //toggle.label = "Toggle";
    //     //root.Add(toggle);
    // }
    //


#endif