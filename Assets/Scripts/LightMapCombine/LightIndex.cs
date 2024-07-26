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
        if (_mbp == null)
        {
            _mbp = new MaterialPropertyBlock();
            _renderer.GetPropertyBlock(_mbp);
            _mbp.SetVector("LightmapST_Array", _offset);
            _mbp.SetVector("LightmapIndex_Array", _index);
            _renderer.SetPropertyBlock(_mbp);
        }
    }
}