using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Fountain : MonoBehaviour
{
    Renderer rend;
    [SerializeField] private float ScrollX, ScrollY;
    void Start()
    {
        rend = GetComponent<Renderer>();
    }

    // Update is called once per frame
    void Update()
    {
        float OffsetX = Time.time * ScrollX;
        float OffsetY = Time.time * ScrollY;
        rend.material.mainTextureOffset = new Vector2(OffsetX,OffsetY);
    }
}
