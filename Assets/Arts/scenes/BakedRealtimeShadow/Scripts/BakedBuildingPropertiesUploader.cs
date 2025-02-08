using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BakedBuildingPropertiesUploader : MonoBehaviour
{
    public Matrix4x4 shadowMatrix;
    public Vector4 channelIndex;
    private MaterialPropertyBlock m_Block;
    private int shadowMatrixID = Shader.PropertyToID("_ShadowMatrix_Array");
    private int shadowChanelID = Shader.PropertyToID("_ShadowChanelIndex_Array");
    // Start is called before the first frame update
    void Start()
    {
        if (m_Block == null)
        {
            m_Block = new MaterialPropertyBlock();
        }

        Renderer renderer = this.GetComponent<Renderer>();
        if (renderer == null)
        {
            Debug.LogError("Please assign a material to GO : " + this.gameObject.name);
            return;
        }
        renderer.GetPropertyBlock(m_Block);
        m_Block.SetMatrix(shadowMatrixID, shadowMatrix);
        m_Block.SetVector(shadowChanelID, channelIndex);
        renderer.SetPropertyBlock(m_Block);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
