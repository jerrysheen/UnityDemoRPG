using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class RandomInit : MonoBehaviour
{
    // Start is called before the first frame update

    private void Awake()
    {
        Debug.Log("Test");
        var script = this.GetComponent<TreeParam>();
        if (script && !script.isInit)
        {
            script.isInit = true;
            script.color = Color.blue;
            script.isInit = true;
        }
    }

    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        
    }
    

}
