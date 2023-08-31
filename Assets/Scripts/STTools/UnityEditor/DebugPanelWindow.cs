#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEditor.SearchService;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UIElements;

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

    [MenuItem("Window/UI Toolkit/MyEditorWindow")]
    public static void ShowDebugPanel()
    {
        DebugPanelWindow wnd = GetWindow<DebugPanelWindow>();
        wnd.titleContent = new GUIContent("MyEditorWindow");
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
        GUILayout.BeginVertical("box", GUILayout.MaxWidth(100));
        if (GUILayout.Button("场景快速切换")) currentTab = TabState.Tab1;
        if (GUILayout.Button("渲染，性能相关按钮")) currentTab = TabState.Tab2;
        if (GUILayout.Button("Tab 3")) currentTab = TabState.Tab3;
        GUILayout.EndVertical();
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
                if (GUILayout.Button("Button C1")) Debug.Log("Pressed C1");
                break;
            default:
                break;
        }

        GUILayout.EndVertical();
        GUILayout.EndHorizontal();
    }
    
    public void DrawSceneSwitchPanel()
    {
        if (GUILayout.Button("内城地表Shader测试场景"))
        {
            EditorSceneManager.OpenScene("Assets/Scenes/" + "MainCityTerrainShderTest.unity", OpenSceneMode.Single);
        }
        if (GUILayout.Button("MipMap检视工具测试场景"))
        {
            EditorSceneManager.OpenScene("Assets/Scenes/" + "MipMapViewer.unity", OpenSceneMode.Single);
        }
        
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