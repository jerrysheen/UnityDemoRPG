using System.Collections;
using System.Collections.Generic;
using TMPro;
using Unity.Mathematics;
using Unity.VisualScripting;
using UnityEngine;
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

    [Header("LocalToWorld Matrix")]
    public float4x4 localToWorld_matrix;
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
        // Quaternion.Euler(0, 0 , 0) 使得物体的初始
        arrowObj_systemQuaternionToEular.transform.rotation = Quaternion.Euler(xDegree, yDegree, zDegree);
        arrowObj_pureEular.transform.rotation = arrowObj_originRotation;
        // Space.world 和 Space.self 的区别就是，Space.world 是在世界坐标系下旋转，Space.self将自身初始化位置当成0.0.0
        arrowObj_pureEular.transform.Rotate(xDegree, yDegree, zDegree,Space.World);

        //arrowObj_pureEular.transform.localToWorldMatrix = Matrix4x4.TRS(new Vector3(0,0,0), Quaternion.Euler(xDegree, yDegree, zDegree), new Vector3(1,1,1));
        localToWorld_matrix = arrowObj_pureEular.transform.localToWorldMatrix;
        arrowObj_mat.SetMatrix("_LocalToWorldMatrix", localToWorld_matrix);
        arrowObj_mat.SetMatrix("_ViewMatrix", gameCam.worldToCameraMatrix);
        arrowObj_mat.SetMatrix("_ProjectionMatrix", gameCam.projectionMatrix);

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
}
