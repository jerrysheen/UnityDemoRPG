using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class SetColorRange : MonoBehaviour
{
    public Color color = Color.white;
    public float Speed = 0;
    public Vector4 _Wind;


    private Color _curColor;
    private float _speed;
    private Vector4 _wind;
    private Renderer _render;

    private MaterialPropertyBlock _propertyBlock;

    private void Start()
    {
        _render = transform.GetComponent<Renderer>();
        SetBlock();
    }

    // Update is called once per frame
    void Update()
    {
        if (_curColor != color || _speed != Speed || _wind != _Wind)
        {
            SetBlock();
        }
    }

    void SetBlock()
    {
        if (_render == null)
        {
            return;
        }

        if (_propertyBlock == null)
        {
            _propertyBlock = new MaterialPropertyBlock();
            _propertyBlock.Clear();
        }
        _propertyBlock.SetColor("_PColored", color);
        _propertyBlock.SetFloat("_Speed", Speed);
        _propertyBlock.SetVector("_Wind", _Wind);
        _render.SetPropertyBlock(_propertyBlock);
        _curColor = color;
        _speed = Speed;
        _wind = _Wind;
    }
}