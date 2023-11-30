using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CPUBuoyancy : MonoBehaviour
{
    public Material SeaMat;

    public Texture2D HeightMap;
    public Vector4 _WorldUV_Offset;
    public float _DisplacementSmallWaveScale;
    public float _DisplacementBigWaveScale;
    public float _WaveTimeScale;
    public float _WaveTotalDisplacementFactor;
    public Vector4 _Wave00Param;
    public Vector4 _Waves_ST;
    public Vector4 _SinWaveParam;
    public Vector4 _Wave01Param;
    public Vector3 OriginalPos;
    // Start is called before the first frame update
    void Start()
    {
        int heightMapID = Shader.PropertyToID("_Waves");
        int worldUVOffsetID = Shader.PropertyToID("_WorldUV_Offset");
        int displacementSmallWaveScaleID = Shader.PropertyToID("_displacementSmallWaveScale");
        int displacementBigWaveScaleID = Shader.PropertyToID("_displacementBigWaveScale");
        int waveTimeScaleID = Shader.PropertyToID("_WaveTimeScale");
        int wave00ParamID = Shader.PropertyToID("_Wave00Param");
        int wavesSTID = Shader.PropertyToID("_Waves_ST");
        int sinWaveParamID = Shader.PropertyToID("_SinWaveParam");
        int wave01ParamID = Shader.PropertyToID("_Wave01Param");
        int waveTotalDisplacementFactorID = Shader.PropertyToID("_WaveTotalDisplacementFactor");
        HeightMap = SeaMat.GetTexture(heightMapID) as Texture2D;
        _WorldUV_Offset = SeaMat.GetVector(worldUVOffsetID);
        _DisplacementSmallWaveScale = SeaMat.GetFloat(displacementSmallWaveScaleID);
        _WaveTotalDisplacementFactor = SeaMat.GetFloat(waveTotalDisplacementFactorID);
        _DisplacementBigWaveScale = SeaMat.GetFloat(displacementBigWaveScaleID);
        _WaveTimeScale = SeaMat.GetFloat(waveTimeScaleID);
        _Wave00Param = SeaMat.GetVector(wave00ParamID);
        _Waves_ST = SeaMat.GetVector(wavesSTID);
        _SinWaveParam = SeaMat.GetVector(sinWaveParamID);
        _Wave01Param = SeaMat.GetVector(wave01ParamID);
        OriginalPos = this.transform.position;
    }

    // Update is called once per frame
    void Update()
    {
                Vector4 WorldUV;
                Vector3 worldPos = this.transform.position;
                // 基本思想： 采两次b通道，每次做一个小位移和tilling，然后做相加平均
                // 在上面叠加一个sin波做扰动
                Vector2 scaledWorldPos;
                scaledWorldPos.x = worldPos.x + (-_WorldUV_Offset.x);
                scaledWorldPos.y = worldPos.z + (-_WorldUV_Offset.y);
                scaledWorldPos.x = scaledWorldPos.x * (-_WorldUV_Offset.z);
                scaledWorldPos.y = scaledWorldPos.y * (-_WorldUV_Offset.w);
                
                //WorldUV = scaledWorldPos.xyxy * new Vector4(_displacementSmallWaveScale, _displacementSmallWaveScale, _displacementBigWaveScale, _displacementBigWaveScale);
                WorldUV.x = scaledWorldPos.x * _DisplacementSmallWaveScale;
                WorldUV.y = scaledWorldPos.y * _DisplacementSmallWaveScale;
                WorldUV.z = scaledWorldPos.x * _DisplacementBigWaveScale;
                WorldUV.w = scaledWorldPos.y * _DisplacementBigWaveScale;
                float time = (Time.timeSinceLevelLoad / 20.0f) * _WaveTimeScale;
                Vector2 timeScale;
                timeScale.y = (Time.timeSinceLevelLoad / 20.0f) * _WaveTimeScale;
                timeScale.x = (-timeScale.y);
                Vector2 wave00UV;
                wave00UV.x = WorldUV.x * _Wave00Param.z + timeScale.x;
                wave00UV.y = WorldUV.y * _Wave00Param.w + timeScale.y;
                timeScale.x = timeScale.y * 1.0f;
                timeScale.y = timeScale.y * -1.0f;
                wave00UV.x = wave00UV.x * _Waves_ST.x + _Waves_ST.z;
                wave00UV.y = wave00UV.y * _Waves_ST.y + _Waves_ST.w;
                
                float waveValue00 = HeightMap.GetPixelBilinear(wave00UV.x, wave00UV.y, 0).g;
                //waveValue00 = d * waveValue00;
                waveValue00 *= _Wave00Param.x;

               
                Vector2 sinWaveUV;
                sinWaveUV.x    = WorldUV.z * _SinWaveParam.z;
                sinWaveUV.y    = WorldUV.w * _SinWaveParam.w;
                sinWaveUV.x = (-_SinWaveParam.y) * time + sinWaveUV.x;
                sinWaveUV.y = (-_SinWaveParam.y) * time + sinWaveUV.y;
                sinWaveUV.x = sinWaveUV.x * _Waves_ST.x + _Waves_ST.z;
                sinWaveUV.y = sinWaveUV.y * _Waves_ST.y + _Waves_ST.w;
                float sinWaveValue = HeightMap.GetPixelBilinear(sinWaveUV.x, sinWaveUV.y, 0).b;
                //sinWaveValue = d * sinWaveValue;
                
                Vector2 wave01UV;
                wave01UV.x    = WorldUV.x * _Wave01Param.z + 0.5f;
                wave01UV.y    = WorldUV.y * _Wave01Param.w + 0.5f;
                wave01UV.x = wave01UV.x * 0.75f + timeScale.x;
                wave01UV.y = wave01UV.y * 0.75f + timeScale.y;
                wave01UV.x = wave01UV.x * _Waves_ST.x + _Waves_ST.z;
                wave01UV.y = wave01UV.y * _Waves_ST.y + _Waves_ST.w;
                float waveValue01 = HeightMap.GetPixelBilinear(wave01UV.x, wave01UV.y, 0).g;
                //waveValue01 = waveValue01 * d ;
                waveValue01*= _Wave01Param.x;
                
                float totalWaveVal = waveValue01 * 0.5f + waveValue00 * 0.5f ;
                float totalWaveDisplacement = sinWaveValue * _SinWaveParam.x + totalWaveVal;
                this.transform.position = new (OriginalPos.x,OriginalPos.y + totalWaveDisplacement * _WaveTotalDisplacementFactor, OriginalPos.z);
    }
}
