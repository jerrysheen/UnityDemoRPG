using System;
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.Drawing.Drawing2D;
using System.IO;

public class BakedShadowEditorWindow : EditorWindow
{
    // 记录每个投影对应的单图，以及Instancing脚本，方便合图以及调整贴图Offset位置。
    public struct PerMatInfo
    {
        public Texture2D currShadowMap;
    }

    public Transform lightTransform;
    public Camera shadowCamera;
    public string folderPath = "Assets/Arts/scenes/BakedRealtimeShadow/BakedShadowFile";
    public Vector2 shadowBias = Vector2.one;
    public int defaultSingleShadowMapSize = 256;
    
    // 阴影贴片的材质
    public Material planeMat;

    // 自定义字段的宽度
    private const float fieldWidth = 500;
    private Vector3[] points;
    private RenderTexture depthTexture;
    

    public Material buildingMat;
    public Material globalShadowGenerateMat;
    private UnityEngine.Matrix4x4 mainLightShadowMatrices;
    
    // 用于拖拽多个预制体的列表
    private List<GameObject> prefabList = new List<GameObject>();

    // 示例向量参数
    private Vector2 vector2Param = Vector2.zero;
    private Vector3 vector3Param = Vector3.zero;

    private List<PerMatInfo> perMatInfoList = new List<PerMatInfo>();
    
    // 在 Unity 菜单栏创建一个入口
    [MenuItem("Tools/BakedShadowEditorWindow")]
    private static void ShowWindow()
    {
        // 获取或者创建一个新的编辑器窗口
        var window = GetWindow<BakedShadowEditorWindow>("My Custom Editor");
        window.Show();
    }

    // 绘制窗口
    private void OnGUI()
    {
        // 标题
        GUILayout.Label("自定义编辑器窗口示例", EditorStyles.boldLabel);
        DrawShadowConfigure();
        // 绘制拖拽区（拖多个预制体）
        DrawPrefabsSection();

        // 绘制向量参数输入
        DrawVectorParameters();

        // 绘制功能按钮
        DrawFunctionButtons();
    }

    private void DrawShadowConfigure()
    {
        GUILayout.Label("Scene Settings", EditorStyles.boldLabel);

        // 使用 GUILayout.Width 来设置统一宽度
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Light Direction", GUILayout.Width(150));
        lightTransform = (Transform)EditorGUILayout.ObjectField(lightTransform, typeof(Transform), true, GUILayout.Width(fieldWidth));
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Camera", GUILayout.Width(150));
        shadowCamera = (Camera)EditorGUILayout.ObjectField(shadowCamera, typeof(Camera), true, GUILayout.Width(fieldWidth));
        EditorGUILayout.EndHorizontal();
        
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("DepthTexture", GUILayout.Width(150));
        depthTexture = (RenderTexture)EditorGUILayout.ObjectField(depthTexture, typeof(RenderTexture), true, GUILayout.Width(fieldWidth));
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Folder Path", GUILayout.Width(150));
        folderPath = EditorGUILayout.TextField(folderPath, GUILayout.Width(fieldWidth));
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Shadow Bias", GUILayout.Width(150));
        shadowBias = EditorGUILayout.Vector2Field("", shadowBias, GUILayout.Width(fieldWidth));
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("Default Shadow Map Size", GUILayout.Width(150));
        defaultSingleShadowMapSize = EditorGUILayout.IntField(defaultSingleShadowMapSize, GUILayout.Width(fieldWidth));
        EditorGUILayout.EndHorizontal();
        
        EditorGUILayout.BeginHorizontal();
        GUILayout.Label("阴影贴片材质", GUILayout.Width(150));
        planeMat = (Material)EditorGUILayout.ObjectField(planeMat, typeof(Material), true, GUILayout.Width(fieldWidth));
        EditorGUILayout.EndHorizontal();
    }

    /// <summary>
    /// 绘制可拖拽多个预制体的区域
    /// </summary>
    private void DrawPrefabsSection()
    {
        EditorGUILayout.LabelField("拖拽多个预制体到下方：", EditorStyles.boldLabel);

        // 如果要让用户动态增加，需要这样做
        int removeIndex = -1;
        for (int i = 0; i < prefabList.Count; i++)
        {
            EditorGUILayout.BeginHorizontal();

            // 显示已经拖进来的预制体引用
            prefabList[i] = (GameObject)EditorGUILayout.ObjectField(
                $"Prefab {i + 1}",
                prefabList[i],
                typeof(GameObject),
                false
            );

            // 如果有需要可以提供一个移除按钮
            if (GUILayout.Button("移除", GUILayout.Width(50)))
            {
                removeIndex = i;
            }

            EditorGUILayout.EndHorizontal();
        }

        if (removeIndex >= 0 && removeIndex < prefabList.Count)
        {
            prefabList.RemoveAt(removeIndex);
        }

        // 添加一个新的空位用以拖入新的预制体
        EditorGUILayout.Space(5);
        EditorGUILayout.LabelField("添加新预制体：", EditorStyles.miniBoldLabel);
        GameObject newPrefab = null;
        newPrefab = (GameObject)EditorGUILayout.ObjectField(
            "New Prefab",
            newPrefab,
            typeof(GameObject),
            true
        );

        // 如果检测到非空输入，且尚未在列表中，就添加进去
        if (newPrefab != null && !prefabList.Contains(newPrefab))
        {
            prefabList.Add(newPrefab);
        }

        EditorGUILayout.Space(10);
        EditorGUILayout.LabelField("————————————————————————", EditorStyles.centeredGreyMiniLabel);
    }

    /// <summary>
    /// 绘制向量参数
    /// </summary>
    private void DrawVectorParameters()
    {
        EditorGUILayout.LabelField("向量参数设置：", EditorStyles.boldLabel);

        vector2Param = EditorGUILayout.Vector2Field("Vector2 参数：", vector2Param);
        vector3Param = EditorGUILayout.Vector3Field("Vector3 参数：", vector3Param);

        EditorGUILayout.Space(10);
        EditorGUILayout.LabelField("————————————————————————", EditorStyles.centeredGreyMiniLabel);
    }

    /// <summary>
    /// 绘制功能按钮区域
    /// </summary>
    private void DrawFunctionButtons()
    {
        EditorGUILayout.LabelField("功能按钮：", EditorStyles.boldLabel);

        // 扫描场景记录需要拍摄的预制体【只有Layer为BakedShadow的才会记录】
        if (GUILayout.Button("加入预制体"))
        {
            ScanSceneAndGetGameObject();
        }

        // Button 2
        if (GUILayout.Button("拍摄并生成阴影图集"))
        {
            GenerateScreenSpaceOcclusionShadow();
        }

        // Button 3
        if (GUILayout.Button("测试功能"))
        {
            // 这里你可以做更多其他操作，举例：
            Debug.Log("点击了按钮 3，执行更多的功能。");
            int numR8Images = defaultSingleShadowMapSize;
            int numRGBAImages = (int)Math.Ceiling(numR8Images / 4.0);
            var bestSize = FindBestAtlasSize(numRGBAImages);
            Debug.Log(bestSize.rows + ","  + bestSize.cols);
        }

        EditorGUILayout.Space(10);
        EditorGUILayout.LabelField("————————————————————————", EditorStyles.centeredGreyMiniLabel);
    }

    public void ScanSceneAndGetGameObject()
    {
        prefabList.Clear();
        // 找到场景中所有的 GameObject（包括激活和未激活对象需要用不同的API；
        GameObject[] allObjects = GameObject.FindObjectsOfType<GameObject>();

        // 如果在 Layers 里有定义名为 "BakedShadow" 的图层，则可以拿到它的层号
        int bakedShadowLayer = LayerMask.NameToLayer("BakedShadow");
        if (bakedShadowLayer < 0)
        {
            Debug.LogError("未找到名为 'BakedShadow' 的图层，请先在 Project Settings > Tags and Layers 中添加。");
            return;
        }

        foreach (GameObject go in allObjects)
        {
            // 判断该对象是否在指定 Layer
            if (go.layer != bakedShadowLayer)
            {
                continue;
            }
            else if(go.GetComponent<Renderer>() != null)
            {
                // 如果检测到非空输入，且尚未在列表中，就添加进去
                if (!prefabList.Contains(go))
                {
                    prefabList.Add(go);
                }
            }
        }
    }

    public void GenerateScreenSpaceOcclusionShadow()
    {
        if (shadowCamera == null)
        {
            Debug.LogError("请创建一个正交相机！Renderer设置为BakedRenderer！");
        }
        
        if (lightTransform == null)
        {
            Debug.LogError("灯光方向还未设置！");
        }
        
        if (depthTexture == null)
        {
            Debug.LogError("请创建一张256x256，r8单通道的贴图！");
        }  
        
        if (planeMat == null)
        {
            Debug.LogError("请为GraoundShadowMat 设置一个材质");
        }

        // 先预先生成我要合图的尺寸大小，生成规则为，
        // rgba 塞满
        // 左上 -> 右上 -> 左下 -> 右下
        int numR8Images = (int)prefabList.Count;
        int numRGBAImages = (int)Math.Ceiling(numR8Images / 4.0);
        var bestSize = FindBestAtlasSize(numRGBAImages);
        Debug.Log(bestSize.rows + ","  + bestSize.cols);
        
        
        for (int goIndex = 0; goIndex < prefabList.Count; goIndex++)
        {
            
            var go = prefabList[goIndex];
            var currPosInAtlas = CalculateImagePosition(goIndex, bestSize.rows, bestSize.cols);
            AlignCamera(go);
            // 产生单张shadowmap图，
            GenerateSingleShadowInfo(go, currPosInAtlas.channel, currPosInAtlas.row, currPosInAtlas.col, bestSize.rows, bestSize.cols);
        }
        CombineAtlas(bestSize.rows, bestSize.cols);
    }

    private void GenerateSingleShadowInfo(GameObject gameObject, Vector4 channel, int row, int col, int maxRow, int maxCol)
    {
        var currMatInfo = new PerMatInfo();
        
        // 获取当前shadowmap图
        currMatInfo.currShadowMap = new Texture2D(depthTexture.width, depthTexture.height, TextureFormat.R8, false);
        RenderTexture.active = depthTexture;
        RenderTexture currentActiveRT = RenderTexture.active;
        RenderTexture.active = depthTexture;
        currMatInfo.currShadowMap.ReadPixels(new Rect(0, 0, depthTexture.width, depthTexture.height), 0, 0);
        currMatInfo.currShadowMap.Apply();
        perMatInfoList.Add(currMatInfo);
        // 手动生成阴影片。
        Bounds originalBounds = gameObject.GetComponent<Renderer>().bounds;
        Vector3 planeCenter = new Vector3(originalBounds.center.x, originalBounds.center.y -originalBounds.extents.y, originalBounds.center.z);
        GameObject plane = gameObject.transform.Find("BakedPlane")?.gameObject;
        if (plane == null)
        {
            plane = GameObject.CreatePrimitive(PrimitiveType.Plane);
            plane.transform.position = planeCenter;
            plane.transform.localScale = new Vector3(2, 2, 2); // 设置宽度和高度
            plane.transform.parent = gameObject.transform;
            plane.gameObject.name = "BakedPlane";
        }
        plane.GetComponent<MeshRenderer>().sharedMaterial = planeMat;
        
        // 记录当前阴影矩阵， 并且加上atlas偏移，这两个内容
        // 塞脚本到两个位置下：
        BakedBuildingPropertiesUploader goUploadScript;
        BakedBuildingPropertiesUploader planeUploaderScript;
        goUploadScript = gameObject.GetComponent<BakedBuildingPropertiesUploader>();
        planeUploaderScript = plane.GetComponent<BakedBuildingPropertiesUploader>();
        if(goUploadScript == null)
        {
            goUploadScript = gameObject.AddComponent<BakedBuildingPropertiesUploader>();
        }
        if (planeUploaderScript == null)
        {
            planeUploaderScript = plane.AddComponent<BakedBuildingPropertiesUploader>();
        }
        UnityEngine.Matrix4x4 worldToShadow  = GetShadowTransform(shadowCamera.projectionMatrix,shadowCamera.worldToCameraMatrix);
        UnityEngine.Matrix4x4 finalWorldToShadow = CalculateShadowMatrixOffsetForAtlas(worldToShadow, row, col, maxRow, maxCol);

        goUploadScript.shadowMatrix = finalWorldToShadow;
        planeUploaderScript.shadowMatrix = finalWorldToShadow;
        goUploadScript.channelIndex = channel;
        planeUploaderScript.channelIndex = channel;
    }

    private void CombineAtlas(int maxRows, int maxCols)
    {
        // 创建大纹理
        Texture2D shadowMapAtlas = new Texture2D(maxCols * defaultSingleShadowMapSize, maxRows * defaultSingleShadowMapSize, TextureFormat.RGBA32, false);
        int currentRow = 0;
        int currentCol = 0;
        int channelIndex = 0;  // 当前通道索引，0 = R, 1 = G, 2 = B, 3 = A

        for (int i = 0; i < perMatInfoList.Count; i++)
        {
            var currInfo = perMatInfoList[i]; // 假设currInfo是你想插入的小纹理
        
            // 从currInfo获取小纹理
            Texture2D smallTexture = currInfo.currShadowMap; // 确保这里是如何从你的currInfo中获取纹理
        
            // 将小纹理的像素复制到大纹理中
            for (int y = 0; y < smallTexture.height; y++)
            {
                for (int x = 0; x < smallTexture.width; x++)
                {
                    float rValue = smallTexture.GetPixel(x, y).r;  // 取得R通道值，因为是单通道

                    Color oldColor = shadowMapAtlas.GetPixel(x + currentCol * defaultSingleShadowMapSize, y + currentRow * defaultSingleShadowMapSize);
                    Color newColor = oldColor;

                    // 根据当前的通道索引设置对应的颜色通道
                    switch (channelIndex)
                    {
                        case 0: newColor.r = rValue; break;
                        case 1: newColor.g = rValue; break;
                        case 2: newColor.b = rValue; break;
                        case 3: newColor.a = rValue; break;
                    }

                    shadowMapAtlas.SetPixel(x + currentCol * defaultSingleShadowMapSize, y + currentRow * defaultSingleShadowMapSize, newColor);
                }
            }
            
            // 更新通道索引，移动到下一个通道
            channelIndex++;
            if (channelIndex > 3)  // 如果超过了A通道，重置通道索引，移动到下一个列
            {
                channelIndex = 0;
                currentCol++;
                if (currentCol >= maxCols)  // 如果列也填满了，移动到下一行
                {
                    currentCol = 0;
                    currentRow++;
                }
            }
        }

        // 应用更改到大纹理
        shadowMapAtlas.Apply();

        byte[] imageBytes = shadowMapAtlas.EncodeToPNG();
        UnityEngine.Object.DestroyImmediate(shadowMapAtlas);
        // foreach (var matInfo in perMatInfoList)
        // {
        //     UnityEngine.Object.DestroyImmediate(matInfo.currShadowMap);
        // }

        // 获取当前 GameObject 的名称
        string objectName = "shadowmapAtlas";
        // 如果文件夹不存在，创建它
        if (!Directory.Exists(folderPath))
        {
            Directory.CreateDirectory(folderPath);
        }
        // 拼接图片文件的完整路径
        string filePath = Path.Combine(folderPath, objectName + ".png");
        // 保存图片
        File.WriteAllBytes(filePath, imageBytes);
        // 刷新资源数据库，确保Unity识别到新添加的文件
        UnityEditor.AssetDatabase.Refresh();
        Debug.Log("Image saved to: " + filePath);
    }


    public void AlignCamera(GameObject gameObject)
    {
        if (shadowCamera == null)
        {
            Debug.LogError("No Cam assigned!");
        }
        
        if (lightTransform != null && gameObject.GetComponent<Renderer>() != null)
        {
            Bounds originalBounds = gameObject.GetComponent<Renderer>().bounds;
            points = GetRotatedPoints(originalBounds, lightTransform.rotation);
        }
        else
        {
            Debug.LogError("No Renderer!!");
        }

        Vector3 center = (points[0] + points[7]) / 2.0f;
        float viewportX = Mathf.Abs(Vector3.Magnitude(points[1] - points[0]) / 2.0f);;
        float viewportY = Mathf.Abs(Vector3.Magnitude(points[2] - points[0]) / 2.0f);;
        float nearClipPlane = -Mathf.Abs(Vector3.Distance((points[0] + points[3]) / 2.0f , center));
        float farClipPlane = Mathf.Abs(Vector3.Distance((points[0] + points[3]) / 2.0f , center));
        float size = Mathf.Abs(Vector3.Distance((points[0] + points[3]) / 2.0f , center));
        shadowCamera.transform.position = center;
        
        Vector3 forwardDirection = (points[4] - points[0]).normalized; // 摄像机朝向目标点的方向
        Vector3 upDirection = (points[2] - points[0]).normalized; // 摄像机朝向目标点的方向
        shadowCamera.transform.rotation = Quaternion.LookRotation(forwardDirection, upDirection); // 设置摄像机的朝向和上方向

        shadowCamera.nearClipPlane = nearClipPlane; 
        shadowCamera.farClipPlane = farClipPlane;

        shadowCamera.orthographicSize = Mathf.Max(viewportX, viewportY);

        shadowCamera.depthTextureMode = DepthTextureMode.Depth;
        shadowCamera.targetTexture = depthTexture;
        shadowCamera.Render();
    }

    private Vector3[] GetRotatedPoints(Bounds bounds, Quaternion rotation)
    {
        // 和transform quaternion方向相反的，
        rotation = Quaternion.Inverse(rotation);
        Vector3 center = bounds.center;
        Vector3 extents = bounds.extents;
        Vector3[] points = new Vector3[8];
        points[0] = center + rotation * new Vector3(extents.x, extents.y, extents.z);
        points[1] = center + rotation * new Vector3(-extents.x, extents.y, extents.z);
        points[2] = center + rotation * new Vector3(extents.x, -extents.y, extents.z);
        points[3] = center + rotation * new Vector3(-extents.x, -extents.y, extents.z);
        points[4] = center + rotation * new Vector3(extents.x, extents.y, -extents.z);
        points[5] = center + rotation * new Vector3(-extents.x, extents.y, -extents.z);
        points[6] = center + rotation * new Vector3(extents.x, -extents.y, -extents.z);
        points[7] = center + rotation * new Vector3(-extents.x, -extents.y, -extents.z);
        // 计算新的min和max
        Vector3 min = points[0];
        Vector3 max = points[0];
        foreach (Vector3 point in points)
        {
            min = Vector3.Min(min, point);
            max = Vector3.Max(max, point);
        }

        // 使用新的min和max来计算旋转后的8个角点
        Vector3[] rotatedPoints = new Vector3[8];
        rotatedPoints[0] = new Vector3(min.x, min.y, min.z);
        rotatedPoints[1] = new Vector3(max.x, min.y, min.z);
        rotatedPoints[2] = new Vector3(min.x, max.y, min.z);
        rotatedPoints[3] = new Vector3(max.x, max.y, min.z);
        rotatedPoints[4] = new Vector3(min.x, min.y, max.z);
        rotatedPoints[5] = new Vector3(max.x, min.y, max.z);
        rotatedPoints[6] = new Vector3(min.x, max.y, max.z);
        rotatedPoints[7] = new Vector3(max.x, max.y, max.z);

        // 假设已经有了旋转后的点和旋转四元数
        Quaternion inverseRotation = Quaternion.Inverse(rotation);

        // 逆旋转后的点
        Vector3[] originalPoints = new Vector3[8];
        for (int i = 0; i < 8; i++)
        {
            // 将每个旋转后的点逆向旋转，恢复到原始空间
            originalPoints[i] = inverseRotation * (rotatedPoints[i] - center) + center;
        }

        return originalPoints;
    }



    Matrix4x4 GetShadowTransform(Matrix4x4 proj, Matrix4x4 view)
    {
        // Currently CullResults ComputeDirectionalShadowMatricesAndCullingPrimitives doesn't
        // apply z reversal to projection matrix. We need to do it manually here.
        if (SystemInfo.usesReversedZBuffer)
        {
            proj.m20 = -proj.m20;
            proj.m21 = -proj.m21;
            proj.m22 = -proj.m22;
            proj.m23 = -proj.m23;
        }

        Matrix4x4 worldToShadow = proj * view;

        var textureScaleAndBias = Matrix4x4.identity;
        textureScaleAndBias.m00 = 0.5f;
        textureScaleAndBias.m11 = 0.5f;
        textureScaleAndBias.m22 = 0.5f;
        textureScaleAndBias.m03 = 0.5f;
        textureScaleAndBias.m23 = 0.5f;
        textureScaleAndBias.m13 = 0.5f;
        // textureScaleAndBias maps texture space coordinates from [-1,1] to [0,1]

        // Apply texture scale and offset to save a MAD in shader.
        return textureScaleAndBias * worldToShadow;
    }
    
    public static (int rows, int cols) FindBestAtlasSize(int numImages, int baseDim = 256, int maxDim = 1024)
    {
        (int rows, int cols) bestLayout = (0, 0);
        int minArea = int.MaxValue;

        // 只考虑2的幂次方的倍数
        for (int rows = 1; rows * baseDim <= maxDim; rows *= 2)
        {
            for (int cols = 1; cols * baseDim <= maxDim; cols *= 2)
            {
                if (rows * cols >= numImages)
                {
                    int area = (rows * baseDim) * (cols * baseDim);
                    if (area < minArea)
                    {
                        minArea = area;
                        bestLayout = (rows, cols);
                    }
                }
            }
        }

        return bestLayout;
    }
    
    public static (Vector4 channel, int row, int col) CalculateImagePosition(int imageIndex, int rows, int cols)
    {
        // 计算当前图像在其RGBA图中的通道位置（0=R, 1=G, 2=B, 3=A）
        int index = imageIndex % 4;
        Vector4 channel = Vector4.zero;
        switch (index)
        {
            case 0: 
                channel.x = 1;
                break;
            case 1: 
                channel.y = 1;
                break;
            case 2: 
                channel.z = 1;
                break;
            case 3: 
                channel.w = 1;
                break;
        }

        // 计算这是第几个RGBA图像
        int rgbaImageIndex = imageIndex / 4;

        // 计算在图集中的行和列
        int row = rgbaImageIndex / cols;  // 整除得到行位置
        int col = rgbaImageIndex % cols;  // 模运算得到列位置

        return (channel, row, col);
    }
    
    private static UnityEngine.Matrix4x4 CalculateShadowMatrixOffsetForAtlas(Matrix4x4 worldToShadow, int rows, int col, int maxRows, int maxCols)
    {
        // 计算缩放因子和偏移量
        float scaleX = 1.0f / maxCols;
        float scaleY = 1.0f / maxRows;
        float offsetX = col * scaleX;
        float offsetY = rows * scaleY;  // 注意Unity的Y轴是从下向上的，如果需要从上向下需要1.0 - offsetY

        // 创建缩放和偏移矩阵
        Matrix4x4 offsetMatrix = Matrix4x4.identity;
        offsetMatrix.m00 = scaleX; // 缩放x
        offsetMatrix.m11 = scaleY; // 缩放y
        offsetMatrix.m03 = offsetX; // 偏移x，包含通道偏移
        offsetMatrix.m13 = offsetY; // 偏移y

        // 将偏移和缩放矩阵与原始阴影矩阵相乘
        Matrix4x4 shadowMatrix = offsetMatrix * worldToShadow;

        return shadowMatrix;
    }
}
