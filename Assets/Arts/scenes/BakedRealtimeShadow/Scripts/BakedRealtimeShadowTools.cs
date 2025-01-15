using System.IO;
using UnityEngine;
using System.Linq;
using UnityEditor;
using UnityEngine.UIElements;

public class BoundsVisualizer : MonoBehaviour
{
    public Transform targetTransform;
    public Camera shadowCamera;

    public Vector3[] points;
    public RenderTexture depthTexture;
    
    public string folderPath = "Assets/Arts/scenes/BakedRealtimeShadow/BakedShadowFile";
    private void OnDrawGizmos()
    {
        if (targetTransform != null && GetComponent<Renderer>() != null)
        {
            Bounds originalBounds = GetComponent<Renderer>().bounds;
            Vector3[] points = GetRotatedPoints(originalBounds, targetTransform.rotation);
            // 这个地方反向无所谓了， 我只需要筛选出来四个点就ok
            DrawPoints(points);
        }
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

    private void DrawPoints(Vector3[] points)
    {
        Gizmos.color = Color.red;
    
        // 底面
        Gizmos.DrawLine(points[0], points[1]);
        Gizmos.DrawLine(points[1], points[3]);
        Gizmos.DrawLine(points[3], points[2]);
        Gizmos.DrawLine(points[2], points[0]);
    
        // 顶面
        Gizmos.DrawLine(points[4], points[5]);
        Gizmos.DrawLine(points[5], points[7]);
        Gizmos.DrawLine(points[7], points[6]);
        Gizmos.DrawLine(points[6], points[4]);
        
        // 立体连接线
        Gizmos.DrawLine(points[0], points[4]);
        Gizmos.DrawLine(points[1], points[5]);
        Gizmos.DrawLine(points[2], points[6]);
        Gizmos.DrawLine(points[3], points[7]);
    }

    public void AlignCamera()
    {
        if (shadowCamera == null)
        {
            Debug.LogError("No Cam assigned!");
        }
        
        if (targetTransform != null && GetComponent<Renderer>() != null)
        {
            Bounds originalBounds = GetComponent<Renderer>().bounds;
            points = GetRotatedPoints(originalBounds, targetTransform.rotation);
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
    }

    public void GenerateShadowMap()
    {

        RenderTexture.active = depthTexture;
        RenderTexture currentActiveRT = RenderTexture.active;
        RenderTexture.active = depthTexture;

        Texture2D tex = new Texture2D(depthTexture.width, depthTexture.height, TextureFormat.R8, false);
        tex.ReadPixels(new Rect(0, 0, depthTexture.width, depthTexture.height), 0, 0);
        tex.Apply();

        RenderTexture.active = currentActiveRT;

        byte[] imageBytes = tex.EncodeToPNG();
        Object.DestroyImmediate(tex);
        
        // 获取当前 GameObject 的名称
        string objectName = gameObject.name;
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

    public void UploadShaderConstant()
    {
        var proj_reversez = shadowCamera.projectionMatrix;
        var proj = shadowCamera.projectionMatrix;
        //if (SystemInfo.usesReversedZBuffer && m_ShadowmapFormat == RenderTextureFormat.Shadowmap)
        if (SystemInfo.usesReversedZBuffer)
        {
            proj_reversez.m20 = -proj.m20;
            proj_reversez.m21 = -proj.m21;
            proj_reversez.m22 = -proj.m22;
            proj_reversez.m23 = -proj.m23;
        }
        Matrix4x4 m_MainLightShadowMatrices = proj_reversez * shadowCamera.worldToCameraMatrix;
        Material mat = this.GetComponent<MeshRenderer>().sharedMaterial;
        if (mat == null)
        {
            Debug.Log("No mat got!");
            return;
        }
        mat.SetMatrix("_ShadowMatrix",m_MainLightShadowMatrices);
    }
}

[CustomEditor(typeof(BoundsVisualizer))]
public class BoundsVisualizerEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        BoundsVisualizer script = target as BoundsVisualizer;
        if (GUILayout.Button("Align Camera"))
        {
            if (script == null) return;
            script.AlignCamera();
        }

        if (GUILayout.Button("Save shadowmap as png"))
        {
            script.GenerateShadowMap();
        }
        
        if (GUILayout.Button("Upload Shader Constant"))
        {
            script.UploadShaderConstant();
        }
    }
}