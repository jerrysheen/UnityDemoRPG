using System.Collections;
using System.Collections.Generic;
using TMPro;
using Unity.Mathematics;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.UI;

public class Rotation_Eular_Quaternion_Scene_EularScript : MonoBehaviour
{
    public GameObject XtoolbarObj;
    public GameObject YtoolbarObj;
    public GameObject ZtoolbarObj;

    public Scrollbar Xbar;
    public Scrollbar Ybar;
    public Scrollbar Zbar;

    public float xDegree;
    public float yDegree;
    public float zDegree;


    public TextMeshProUGUI Xtext;
    public TextMeshProUGUI Ytext;
    public TextMeshProUGUI Ztext;
    // Start is called before the first frame update

    public GameObject arrowObj_systemQuaternionToEular;
    public GameObject arrowObj_pureEular;
    public Material arrowObj_mat;
    public Quaternion arrowObj_originRotation;

    public Camera gameCam;

    [Header("Transform Parameter")] 
    public Vector3 pos;
    public Vector3 angle;
    public Vector3 scale;
    
    [Header("Matrix")]
    public float4x4 localToWorld_matrix;
    public float4x4 worldToCamera_matrix;
    public float4x4 projection_matrix;
    void Start()
    {
        XtoolbarObj = this.transform.Find("Xvalue").gameObject;
        YtoolbarObj = this.transform.Find("Yvalue").gameObject;
        ZtoolbarObj = this.transform.Find("Zvalue").gameObject;
        if (!XtoolbarObj || !YtoolbarObj || !ZtoolbarObj) 
        {
            Debug.Assert(false, "XtoolbarObj or YtoolbarObj or ZtoolbarObj is null");
        }

        Xbar = XtoolbarObj.GetComponent<Scrollbar>();
        Ybar = YtoolbarObj.GetComponent<Scrollbar>();
        Zbar = ZtoolbarObj.GetComponent<Scrollbar>();

        if (!Xbar || !Ybar || !Zbar)
        {
            Debug.Assert(false, "XtoolbarObj or YtoolbarObj or ZtoolbarObj is null");
        }



        Xtext = XtoolbarObj.transform.Find("x_value").GetComponent<TextMeshProUGUI>();
        Ytext = YtoolbarObj.transform.Find("y_value").GetComponent<TextMeshProUGUI>();
        Ztext = ZtoolbarObj.transform.Find("z_value").GetComponent<TextMeshProUGUI>();

        Xbar.value = 0.5f;
        Ybar.value = 0.0f;
        Zbar.value = 0.0f;

        arrowObj_originRotation = arrowObj_pureEular.transform.rotation;
    }

    // Update is called once per frame
    void Update()
    {
        // Quaternion.Euler(0, 0 , 0) ʹ������ĳ�ʼ
        arrowObj_systemQuaternionToEular.transform.rotation = Quaternion.Euler(xDegree, yDegree, zDegree);
        // arrowObj_pureEular.transform.rotation = arrowObj_originRotation;
        // // Space.world �� Space.self ��������ǣ�Space.world ������������ϵ����ת��Space.self�������ʼ��λ�õ���0.0.0
        // arrowObj_pureEular.transform.Rotate(xDegree, yDegree, zDegree,Space.World);

        //arrowObj_pureEular.transform.localToWorldMatrix = Matrix4x4.TRS(new Vector3(0,0,0), Quaternion.Euler(xDegree, yDegree, zDegree), new Vector3(1,1,1));
        //localToWorld_matrix = arrowObj_pureEular.transform.localToWorldMatrix;
        localToWorld_matrix = GetLocalToWorldMatrix();
        worldToCamera_matrix = GetWorldToCameraMatrix();
        //projection_matrix = GL.GetGPUProjectionMatrix(gameCam.projectionMatrix, true);
        projection_matrix = GetProjectionMatrix();
        arrowObj_mat.SetMatrix("_LocalToWorldMatrix", localToWorld_matrix);
        arrowObj_mat.SetMatrix("_ViewMatrix", worldToCamera_matrix);
        arrowObj_mat.SetMatrix("_ProjectionMatrix", projection_matrix);

    }

    public void OnXvalueChange(float value) 
    {
        Debug.Log("X Value change : " + Xbar.value);
        xDegree = (Xbar.value - 0.5f) * 2.0f * 90.0f;
        Xtext.text = xDegree.ToString();
    }
    
    public void OnYvalueChange(float value) 
    {
        Debug.Log("Y Value change : " + Ybar.value);
        yDegree = Ybar.value * 360.0f;
        Ytext.text = yDegree.ToString();
    }
    public void OnZvalueChange(float value) 
    {
        Debug.Log("Z Value change : " + Zbar.value);
        zDegree = Zbar.value * 360.0f;
        Ztext.text = zDegree.ToString();
    }
    
    // Matrix4x4 使用Vector4 做为参数的构造方法
    // 每一个Vector4参数都代表矩阵的一列
    // 如 new Matrix4x4(
    //            new Vector4(1,2,3,4),
    //            new Vector4(5,6,7,8),
    //            new Vector4(9,10,11,12),
    //            new Vector4(13,14,15,16)
    //        );
    // 将会得到这样一个矩阵:
    //         1 5  9 13
    //         2 6 10 14
    //         3 7 11 15
    //         4 8 12 16

    public Matrix4x4 GetLocalToWorldMatrix()
    {
        pos = arrowObj_pureEular.transform.position;
        angle = arrowObj_pureEular.transform.rotation.eulerAngles;
        scale = arrowObj_pureEular.transform.localScale;

        Matrix4x4 transformMat = Matrix4x4.identity;
        #region By Matrix:
        // Object To World Matrix:   
        
        //---------------- Rotate:
        // 旋转的部分，分为三个轴，x轴 y 轴 z轴的旋转。
        Matrix4x4 rotateZMatrix = Matrix4x4.identity;
        rotateZMatrix[0, 0] =  Mathf.Cos(angle.z * Mathf.Deg2Rad); rotateZMatrix[0, 1] = -Mathf.Sin(angle.z * Mathf.Deg2Rad); rotateZMatrix[0, 2] = 0.0f; rotateZMatrix[0, 3] = 0.0f;
        rotateZMatrix[1, 0] =  Mathf.Sin(angle.z * Mathf.Deg2Rad); rotateZMatrix[1, 1] =  Mathf.Cos(angle.z * Mathf.Deg2Rad); rotateZMatrix[1, 2] = 0.0f; rotateZMatrix[1, 3] = 0.0f;
        rotateZMatrix[2, 0] = 0.0f; rotateZMatrix[2, 1] = 0.0f; rotateZMatrix[2, 2] = 1.0f; rotateZMatrix[2, 3] = 0.0f;
        rotateZMatrix[3, 0] = 0.0f; rotateZMatrix[3, 1] = 0.0f; rotateZMatrix[3, 2] = 0.0f; rotateZMatrix[3, 3] = 1.0f;
        
        Matrix4x4 rotateXMatrix = Matrix4x4.identity;
        rotateXMatrix[0, 0] = 1.0f; rotateXMatrix[0, 1] = 0.0f; rotateXMatrix[0, 2] = 0.0f; rotateXMatrix[0, 3] = 0.0f;
        rotateXMatrix[1, 0] = 0.0f; rotateXMatrix[1, 1] = Mathf.Cos(angle.x * Mathf.Deg2Rad);   rotateXMatrix[1, 2] = -Mathf.Sin(angle.x * Mathf.Deg2Rad); rotateXMatrix[1, 3] = 0.0f;
        rotateXMatrix[2, 0] = 0.0f; rotateXMatrix[2, 1] = Mathf.Sin(angle.x * Mathf.Deg2Rad);   rotateXMatrix[2, 2] = Mathf.Cos(angle.x * Mathf.Deg2Rad); rotateXMatrix[2, 3] = 0.0f;
        rotateXMatrix[3, 0] = 0.0f; rotateXMatrix[3, 1] = 0.0f; rotateXMatrix[3, 2] = 0.0f; rotateXMatrix[3, 3] = 1.0f;

        Matrix4x4 rotateYMatrix = Matrix4x4.identity;
        rotateYMatrix[0, 0] = Mathf.Cos(angle.y * Mathf.Deg2Rad); rotateYMatrix[0, 1] = 0.0f;  rotateYMatrix[0, 2] = Mathf.Sin(angle.y * Mathf.Deg2Rad); rotateYMatrix[0, 3] = 0.0f;
        rotateYMatrix[1, 0] = 0.0f; rotateYMatrix[1, 1] = 1.0f; rotateYMatrix[1, 2] = 0.0f; rotateYMatrix[1, 3] = 0.0f;
        rotateYMatrix[2, 0] = -Mathf.Sin(angle.y * Mathf.Deg2Rad); rotateYMatrix[2, 1] = 0.0f; rotateYMatrix[2, 2] = Mathf.Cos(angle.y * Mathf.Deg2Rad); rotateYMatrix[2, 3] = 0.0f;
        rotateYMatrix[3, 0] = 0.0f; rotateYMatrix[3, 1] = 0.0f; rotateYMatrix[3, 2] = 0.0f; rotateYMatrix[3, 3] = 1.0f;
        
        //---------------- Scale:
        Matrix4x4 scaleMatrix = Matrix4x4.identity;
        scaleMatrix[0, 0] = scale.x; scaleMatrix[0, 1] = 0.0f;    scaleMatrix[0, 2] = 0.0f;    scaleMatrix[0, 3] = 0.0f;
        scaleMatrix[1, 0] = 0.0f;    scaleMatrix[1, 1] = scale.y; scaleMatrix[1, 2] = 0.0f;    scaleMatrix[1, 3] = 0.0f;
        scaleMatrix[2, 0] = 0.0f;    scaleMatrix[2, 1] = 0.0f;    scaleMatrix[2, 2] = scale.z; scaleMatrix[2, 3] = 0.0f;
        scaleMatrix[3, 0] = 0.0f;    scaleMatrix[3, 1] = 0.0f;    scaleMatrix[3, 2] = 0.0f;    scaleMatrix[3, 3] = 1.0f;
        
        //---------------- Translate:
        Matrix4x4 translateMatrix = Matrix4x4.identity;
        translateMatrix[0, 0] = 1.0f;    translateMatrix[0, 1] = 0.0f;    translateMatrix[0, 2] = 0.0f;    translateMatrix[0, 3] = pos.x;
        translateMatrix[1, 0] = 0.0f;    translateMatrix[1, 1] = 1.0f;    translateMatrix[1, 2] = 0.0f;    translateMatrix[1, 3] = pos.y;
        translateMatrix[2, 0] = 0.0f;    translateMatrix[2, 1] = 0.0f;    translateMatrix[2, 2] = 1.0f;    translateMatrix[2, 3] = pos.z;
        translateMatrix[3, 0] = 0.0f;    translateMatrix[3, 1] = 0.0f;    translateMatrix[3, 2] = 0.0f;    translateMatrix[3, 3] = 1.0f;
        #endregion

        transformMat = translateMatrix * scaleMatrix * rotateYMatrix * rotateXMatrix * rotateZMatrix;
        return transformMat;
    }


    public Matrix4x4 GetWorldToCameraMatrix()
    {
        // Z
        Vector3 forward = -Vector3.Normalize(gameCam.transform.forward);
        // Y
        Vector3 up = Vector3.Normalize(gameCam.transform.up);
        // X
        // Left hand rules.
        Vector3 right = -Vector3.Normalize(Vector3.Cross(up, forward));
        // Debug.Log(right + ","  + up  + ","  + forward);
        // Debug.Log(gameCam.worldToCameraMatrix);
        Matrix4x4 viewMatrix = Matrix4x4.identity;
        viewMatrix[0, 0] = right.x;     viewMatrix[0, 1] = right.y;     viewMatrix[0, 2] = right.z;     viewMatrix[0, 3] = -Vector3.Dot(right ,gameCam.transform.position);
        viewMatrix[1, 0] = up.x;        viewMatrix[1, 1] = up.y;        viewMatrix[1, 2] = up.z;        viewMatrix[1, 3] = -Vector3.Dot(up ,gameCam.transform.position);
        viewMatrix[2, 0] = forward.x;   viewMatrix[2, 1] = forward.y;   viewMatrix[2, 2] = forward.z;   viewMatrix[2, 3] = -Vector3.Dot(forward ,gameCam.transform.position);
        viewMatrix[3, 0] = 0.0f;        viewMatrix[3, 1] = 0.0f;        viewMatrix[3, 2] = 0.0f;        viewMatrix[3, 3] = 1.0f;
        Debug.Log("viewMatrix: " + viewMatrix);
        return viewMatrix;
    }
    
    
    public Matrix4x4 GetProjectionMatrix()
    {

        float ar = gameCam.aspect;
        float zNear = gameCam.nearClipPlane;
        float zFar = gameCam.farClipPlane;
        float zRange = zNear - zFar;
        float tanHalfFOV = Mathf.Tan(gameCam.fieldOfView / 2.0f * Mathf.Deg2Rad);
        Debug.Log("Aspect Ratio: " + ar);
        Debug.Log("fieldOfView: " + gameCam.fieldOfView);
        
        Matrix4x4 viewMatrix = Matrix4x4.identity;
        viewMatrix[0, 0] = 1.0f / (tanHalfFOV * ar);    viewMatrix[0, 1] = 0.0f;    viewMatrix[0, 2] = 0.0f;    viewMatrix[0, 3] = 0.0f;
        viewMatrix[1, 0] = 0.0f;    viewMatrix[1, 1] = 1.0f / (tanHalfFOV);    viewMatrix[1, 2] = 0.0f;    viewMatrix[1, 3] = 0.0f;
        viewMatrix[2, 0] = 0.0f;    viewMatrix[2, 1] = 0.0f;    viewMatrix[2, 2] = -(zNear + zFar)/(zFar - zNear);    viewMatrix[2, 3] = -2 * zNear * zFar / (zFar - zNear);
        viewMatrix[3, 0] = 0.0f;    viewMatrix[3, 1] = 0.0f;    viewMatrix[3, 2] = -1.0f;    viewMatrix[3, 3] = 0.0f;
        //Debug.Log(viewMatrix);
        
        #region OpenGL platform

        if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.OpenGLES3)
        {
            Debug.Log("Render Platform is: " + SystemInfo.graphicsDeviceType + " , matrix is : "  + gameCam.projectionMatrix);
            return GPUGetGPUProjectionMatrix(viewMatrix, true);
        }

        #endregion
        
        //GL.GetGPUProjectionMatrix()
        
        #region Dx platform
        if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D11 || SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D12)
        {
            Debug.Log("Render Platform is: " + SystemInfo.graphicsDeviceType + " , matrix is : "  + gameCam.projectionMatrix);
            return GPUGetGPUProjectionMatrix(viewMatrix, true);
            
        }
        #endregion
        
        return Matrix4x4.identity;
    }

    public Matrix4x4 GPUGetGPUProjectionMatrix(Matrix4x4 m, bool renderToTexture)
    {
        bool revertZ = SystemInfo.usesReversedZBuffer;
        if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.OpenGLES3)
        {
            if (revertZ)
            {
                m[2, 0] = -m[2, 0];
                m[2, 1] = -m[2, 1];
                m[2, 2] = -m[2, 2];
                m[2, 3] = -m[2, 3];
            }
			
            return m; // nothing else to do on OpenGL-like devices
        }
			
        // Otherwise, the matrix is OpenGL style, and we have to convert it to
        // D3D-like projection matrix
        bool invertY = true;
        if (invertY)
        {
            m[1, 0] = -m[1, 0];
            m[1, 1] = -m[1, 1];
            m[1, 2] = -m[1, 2];
            m[1, 3] = -m[1, 3];
        }
			
        // Now scale&bias to get Z range from -1..1 to 0..1 or 1..0
        // matrix = scaleBias * matrix
        //  1   0   0   0
        //  0   1   0   0
        //  0   0 0.5 0.5
        //  0   0   0   1
        m[2, 0] = m[2, 0] * (revertZ ? -0.5f : 0.5f) + m[3, 0] * 0.5f;
        m[2, 1] = m[2, 1] * (revertZ ? -0.5f : 0.5f) + m[3, 1] * 0.5f;
        m[2, 2] = m[2, 2] * (revertZ ? -0.5f : 0.5f) + m[3, 2] * 0.5f;
        m[2, 3] = m[2, 3] * (revertZ ? -0.5f : 0.5f) + m[3, 3] * 0.5f;
        return m;
    }
}
