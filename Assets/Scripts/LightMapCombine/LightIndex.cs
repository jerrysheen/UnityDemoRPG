using System;
using UnityEngine;


//记录光照贴图索引偏移
[ExecuteInEditMode]
public class LightIndex : MonoBehaviour
{
    private Renderer _renderer = null;
    [SerializeField] private Vector4 _index = Vector4.zero;
    [SerializeField] private Vector4 _offset = Vector4.zero;

    public Vector4 Index => _index;
    public Vector4 ScaleOffset => _offset;
    public MaterialPropertyBlock _mbp;

    //private String lightmapST = "LightmapST_Array";
    //private String lightmapIndex = "LightmapIndex_Array";
    
    private String lightmapST = "unity_LightmapSTArray";
    private String lightmapIndex = "unity_LightmapIndexArray";
    private void Awake()
    {
    }

    private void Start()
    {
        _renderer = GetComponent<Renderer>();
        Record();
    }

    public void Record()
    {
        _renderer = GetComponent<Renderer>();
        if (null != _renderer)
        {
            _index = new Vector4(_renderer.lightmapIndex, 0.0f, 0.0f, 0.0f);
            _offset = _renderer.lightmapScaleOffset;
            Debug.Log(_index+" , " +  _offset);
        }
        
        Apply();
    }
    
    // public void ForceModify(int index, Vector4 offset)
    // {
    //     _index = index;
    //     _offset = offset;
    //     Apply();
    // }

    public void Apply()
    {
        // if (null != _renderer && _index >= 0)
        // {
        //     _renderer.lightmapIndex = _index;
        //     _renderer.lightmapScaleOffset = _offset;
        // }
        if (_renderer == null)
        {
            _renderer = GetComponent<Renderer>();
            if(_renderer) Debug.LogError("这个GO没有挂renderer!");
        }

        if (_mbp == null)
        {
            _mbp = new MaterialPropertyBlock();
            _renderer.GetPropertyBlock(_mbp);
            _mbp.SetVector(lightmapST, _offset);
            _mbp.SetVector(lightmapIndex, _index);
            _renderer.SetPropertyBlock(_mbp);
        }
    }
}