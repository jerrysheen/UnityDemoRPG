using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;
using UnityEditor;

public class TestWorldToCamMatrix : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void TestMatrix()
    {
        Camera cam = GetComponent<Camera>();
        var viewMatrix = Matrix4x4.Inverse(Matrix4x4.TRS(
            GetComponent<Camera>().transform.position,
            GetComponent<Camera>().transform.rotation,
            new Vector3(1, 1, -1)));
        Debug.Log(Quaternion.Euler(90, 0, 0));
        Debug.Log(quaternion.Euler(0.5f * 3.14159f,0,0));
    }
}


[CustomEditor(typeof(TestWorldToCamMatrix))]
public class TestWorldToCamMatrixEditor : Editor
{
    public override void OnInspectorGUI()
    {
        if (GUILayout.Button("Test"))
        {
            TestWorldToCamMatrix test = target as TestWorldToCamMatrix;
            test.TestMatrix();
        }
    }
}