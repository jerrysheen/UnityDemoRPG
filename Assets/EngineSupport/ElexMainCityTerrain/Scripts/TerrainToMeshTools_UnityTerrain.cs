#if UNITY_EDITOR
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

public class TerrainToMeshTools_UnityTerrain : MonoBehaviour
{
    [SerializeField]string outputPath = "/Plugins/3rdPlugins/ELEX_MainCityResource/Arts";
    [SerializeField]string outputPrefix = "MAINCITY_TERRAINTEX_OUT_";
    
    [SerializeField]string matPath = "/Plugins/3rdPlugins/ELEX_MainCityResource/Arts";
    [SerializeField]string matName = "MaincityTerrainMat";
    
    public Material currMat;
    
    public List<Texture2D> inAlbedoPack;
    public List<Texture2D> inNormalPack;
    public List<Texture2D> inMaskPack;
    public List<Texture2D> inWeightPack;

    public List<Texture2D> outWeightPack;
    public List<Texture2D> outHeightPack;
    public List<Texture2D> outAlbedoPack;
    public List<Texture2D> outNormalPack;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void ExtactTextureInfo()
    {
        CreateTextureList();
        // clean folder:
        CleanOutputFolder();
        // convert.
        TransfromTexture();
        CreateMat();
    }

    void CreateTextureList()
    {
        inAlbedoPack = new List<Texture2D>();
        inNormalPack = new List<Texture2D>();
        inMaskPack = new List<Texture2D>();
        inWeightPack = new List<Texture2D>();

        outWeightPack = new List<Texture2D>();
        outHeightPack = new List<Texture2D>();
        outAlbedoPack = new List<Texture2D>();
        outNormalPack = new List<Texture2D>();

        TerrainData terrainData = this.GetComponent<TerrainCollider>().terrainData;
        if (!terrainData)
        {
            Debug.LogError("Can't Find Terrain Data!");
            return;
        }

        // inWeightPack
        for (int i = 0; i < 3; i++)
        {
            inWeightPack.Add(terrainData.alphamapTextures[i]);
        }
        //inAlbedoPack
        //inNormalPack
        //inMaskPack
        for (int i = 0; i < 9; i++)
        {
            inAlbedoPack.Add(terrainData.terrainLayers[i].diffuseTexture);
            inNormalPack.Add(terrainData.terrainLayers[i].normalMapTexture);
            inMaskPack.Add(terrainData.terrainLayers[i].maskMapTexture);
        }
    }
    
    void CleanOutputFolder()
    {
        string absoluteOutputPath = Application.dataPath + outputPath;
//        Debug.Log("OutputPath:" + absoluteOutputPath);
        if (Directory.Exists(absoluteOutputPath)) { Directory.Delete(absoluteOutputPath, true); }
        Directory.CreateDirectory(absoluteOutputPath);
        AssetDatabase.Refresh();
    }

    void TransfromTexture()
    {
        TransformHeightMap();
        TransformWeightMap();
        TransformAlbedoMap();
        TransformNormalMap();
    }
    
    public void TransformHeightMap()
    {
        #region GetHeightMap
        List<int> indexArray = new List<int>() {0, 1, 2, 3, 5,6,4 ,7,8 };
        var newcol = new List<Color>();
        outHeightPack = new List<Texture2D>();
        for (int i = 0; i < 2; i++)
        {
            int indexPic0 = indexArray[4 * i];
            int indexPic1 = indexArray[4 * i + 1];
            int indexPic2 = indexArray[4 * i + 2];
            int indexPic3 = indexArray[4 * i + 3];

            Texture2D heightMap00 = inMaskPack[indexPic0];
            Texture2D heightMap01 = inMaskPack[indexPic1];
            Texture2D heightMap02 = inMaskPack[indexPic2];
            Texture2D heightMap03 = inMaskPack[indexPic3];



            var height = heightMap00.height;
            var width = heightMap00.width;
            Texture2D targetTex = new Texture2D(height, width, textureFormat: TextureFormat.RGBA32, false, true);
            Texture2D targetTexPC = new Texture2D(height, width, textureFormat: TextureFormat.RGBA32, false, true);
            Debug.Log(outputPrefix + "HeightMap" + i);
            for (int j = 0; j < height; j++)
            {
                for (int k = 0; k < width; k++)
                {
                    Color curr = Color.black;
                    curr.r = heightMap00.GetPixel(k, j).b;
                    curr.g = heightMap01.GetPixel(k, j).b;
                    curr.b = heightMap02.GetPixel(k, j).b;
                    curr.a = heightMap03.GetPixel(k, j).b;
                    newcol.Add(curr);
                }

            }
            targetTex.SetPixels(newcol.ToArray());
            targetTexPC.SetPixels(newcol.ToArray());
            newcol.Clear();
            string assetLoadPath = "Assets" + outputPath + "/";
            string assetName = outputPrefix + "HeightMap" + i + ".asset";
            EditorUtility.CompressTexture(targetTex, TextureFormat.ASTC_4x4, TextureCompressionQuality.Normal);
            targetTex.Apply(true, true);
            AssetDatabase.CreateAsset(targetTex, assetLoadPath + "/" + assetName);
            
            assetName = outputPrefix + "HeightMap" + i + "_PC.asset";
            EditorUtility.CompressTexture(targetTexPC, TextureFormat.DXT5, TextureCompressionQuality.Normal);
            targetTexPC.Apply(true, true);
            AssetDatabase.CreateAsset(targetTexPC, assetLoadPath + "/" + assetName);
            outHeightPack.Add(targetTexPC);
        }
        AssetDatabase.Refresh();
#endregion
    }

    public void TransformWeightMap()
    {
#region GetWeightMap
        Debug.Log("Deal with weight map");
        List<int> indexArray = new List<int>() {0, 1, 2, 3, 5,6,4 ,7,8 };
        var newcol = new List<Color>();
        outWeightPack = new List<Texture2D>();

        // pic00:
        var height = inWeightPack[0].height;
        var width = inWeightPack[0].width;
        Texture2D targetTex = new Texture2D(height, width, textureFormat: TextureFormat.RGBA32, false, true);
        Texture2D targetTexPC = new Texture2D(height, width, textureFormat: TextureFormat.RGBA32, false, true);
        for (int j = 0; j < height; j++)
        {
            for (int k = 0; k < width; k++)
            {
                Color curr = Color.black;
                curr.r = inWeightPack[0].GetPixel(k, j).r;
                curr.g = inWeightPack[0].GetPixel(k, j).g;
                curr.b = inWeightPack[0].GetPixel(k, j).b;
                curr.a = inWeightPack[0].GetPixel(k, j).a;
                newcol.Add(curr);
            }
        }
        targetTex.SetPixels(newcol.ToArray());
        targetTexPC.SetPixels(newcol.ToArray());
        string assetLoadPath = "Assets" + outputPath + "/";
        string assetName = outputPrefix + "WeightMap00.asset";
        EditorUtility.CompressTexture(targetTex, TextureFormat.ASTC_4x4, TextureCompressionQuality.Normal);
        targetTex.Apply(true, true);
        AssetDatabase.CreateAsset(targetTex, assetLoadPath + "/" + assetName);        
        
        assetName = outputPrefix + "WeightMap00_PC.asset";
        EditorUtility.CompressTexture(targetTexPC, TextureFormat.DXT5, TextureCompressionQuality.Normal);
        targetTexPC.Apply(true, true);
        AssetDatabase.CreateAsset(targetTexPC, assetLoadPath + "/" + assetName);
        
        outWeightPack.Add(targetTex);
        newcol.Clear();

        // pic01:
        targetTex = new Texture2D(height, width, textureFormat: TextureFormat.RGBA32, false, true);
        targetTexPC = new Texture2D(height, width, textureFormat: TextureFormat.RGBA32, false, true);
        for (int j = 0; j < height; j++)
        {
            for (int k = 0; k < width; k++)
            {
                Color curr = Color.black;
                curr.r = inWeightPack[1].GetPixel(k, j).r;
                curr.g = inWeightPack[1].GetPixel(k, j).g;
                curr.b = inWeightPack[1].GetPixel(k, j).b;
                curr.a = inWeightPack[1].GetPixel(k, j).a;
                newcol.Add(curr);
            }
        }
        targetTex.SetPixels(newcol.ToArray());
        targetTexPC.SetPixels(newcol.ToArray());
        assetLoadPath = "Assets" + outputPath + "/";
        assetName = outputPrefix + "WeightMap01.asset";
        EditorUtility.CompressTexture(targetTex, TextureFormat.ASTC_4x4, TextureCompressionQuality.Normal);
        targetTex.Apply(true, true);
        AssetDatabase.CreateAsset(targetTex, assetLoadPath + "/" + assetName);
        
        assetName = outputPrefix + "WeightMap01_PC.asset";
        EditorUtility.CompressTexture(targetTexPC, TextureFormat.DXT5, TextureCompressionQuality.Normal);
        targetTexPC.Apply(true, true);
        AssetDatabase.CreateAsset(targetTexPC, assetLoadPath + "/" + assetName);
        
        outWeightPack.Add(targetTex);
        newcol.Clear();

        // pic02:
        targetTex = new Texture2D(height, width, textureFormat: TextureFormat.RGBA32, false, true);
        targetTexPC = new Texture2D(height, width, textureFormat: TextureFormat.RGBA32, false, true);
        for (int j = 0; j < height; j++)
        {
            for (int k = 0; k < width; k++)
            {
                Color curr = Color.black;
                curr.r = inWeightPack[2].GetPixel(k, j).r;
                curr.g = 0.0f;
                curr.b = 0.0f;
                curr.a = 0.0f;
                newcol.Add(curr);
            }
        }
        targetTex.SetPixels(newcol.ToArray());
        targetTexPC.SetPixels(newcol.ToArray());
        assetLoadPath = "Assets" + outputPath + "/";
        assetName = outputPrefix + "WeightMap02.asset";
        EditorUtility.CompressTexture(targetTex, TextureFormat.ASTC_4x4, TextureCompressionQuality.Normal);
        targetTex.Apply(true, true);
        AssetDatabase.CreateAsset(targetTex, assetLoadPath + "/" + assetName);
        
        assetName = outputPrefix + "WeightMap02_PC.asset";
        EditorUtility.CompressTexture(targetTexPC, TextureFormat.DXT5, TextureCompressionQuality.Normal);
        targetTexPC.Apply(true, true);
        AssetDatabase.CreateAsset(targetTexPC, assetLoadPath + "/" + assetName);
        
        outWeightPack.Add(targetTex);
        newcol.Clear();
        AssetDatabase.Refresh();
#endregion
    }

    public void TransformAlbedoMap()
    {
#region GetAlbedoMap
        Debug.Log("Deal with albedo map");
        List<int> indexArray = new List<int>() {0, 1, 2, 3, 5,6,4 ,7,8 };
        outAlbedoPack = new List<Texture2D>();
        var newcol = new List<Color>();

        for(int i = 0; i < 3; i ++)
        {
            int count = i;
            int indexPic0 = indexArray[count * 3 + 0];
            int indexPic1 = indexArray[count * 3 + 1];
            int indexPic2 = indexArray[count * 3 + 2];

            Texture2D currDiffuseMap00 = inAlbedoPack[indexPic0];
            Texture2D currDiffuseMap01 = inAlbedoPack[indexPic1];
            Texture2D currDiffuseMap02 = inAlbedoPack[indexPic2];

            Texture2D currMaskMap00 = inMaskPack[indexPic0];
            Texture2D currMaskMap01 = inMaskPack[indexPic1];
            Texture2D currMaskMap02 = inMaskPack[indexPic2];

            int mipmapLevel = currDiffuseMap00.mipmapCount;
            var height = currDiffuseMap00.height;
            var width = currDiffuseMap00.width;
            Texture2D targetTex = new Texture2D(height * 2, width * 2, textureFormat: TextureFormat.RGBA32, true, false);
            Texture2D targetTexPC = new Texture2D(height * 2, width * 2, textureFormat: TextureFormat.RGBA32, true, false);

            for (int currLevel = 0; currLevel <= mipmapLevel; currLevel++)
            {
                if (currLevel == mipmapLevel)
                {
                    Color[] colorArray00 = currDiffuseMap00.GetPixels(currLevel - 1);
                    Color[] maskArray00 = currMaskMap00.GetPixels(currLevel - 1);
                    Color res = Color.black;
                    res = colorArray00[0];
                    res.a = maskArray00[0].g;
                    newcol.Add(res);
                }
                else
                {
                    Color[] colorArray00 = currDiffuseMap00.GetPixels(currLevel);
                    Color[] colorArray01 = currDiffuseMap01.GetPixels(currLevel);
                    Color[] colorArray02 = currDiffuseMap02.GetPixels(currLevel);


                    Color[] maskArray00 = currMaskMap00.GetPixels(currLevel);
                    Color[] maskArray01 = currMaskMap01.GetPixels(currLevel);
                    Color[] maskArray02 = currMaskMap02.GetPixels(currLevel);
                    var levelHeight = (int)(height / Mathf.Pow(2, currLevel));
                    var levelWidth = (int)(width / Mathf.Pow(2, currLevel));
                    for (int j = 0; j < levelHeight; j++)
                    {
                        for (int col = 0; col <= 1; col++)
                        {
                            for (int k = 0; k < levelWidth; k++)
                            {
                                if (col == 0)
                                {
                                    Color res = Color.black;
                                    res = colorArray00[j * levelHeight + k];
                                    res.a = maskArray00[j * levelHeight + k].g;
                                    newcol.Add(res);
                                    newcol.Add(res);
                                }
                                else
                                {
                                    Color res = Color.black;
                                    res = colorArray01[j * levelHeight + k];
                                    res.a = maskArray01[j * levelHeight + k].g;
                                    newcol.Add(res);

                                    res = Color.black;
                                    res = colorArray02[j * levelHeight + k];
                                    res.a = maskArray02[j * levelHeight + k].g;
                                    newcol.Add(res);
                                }

                            }
                        }
                    }
                }
                targetTex.SetPixels(newcol.ToArray(), currLevel);
                targetTexPC.SetPixels(newcol.ToArray(), currLevel);
                newcol.Clear();

            }
            string assetLoadPath = "Assets" + outputPath + "/";
            string assetName = outputPrefix + "AlbedoMap" + count + ".asset";
            EditorUtility.CompressTexture(targetTex, TextureFormat.ASTC_4x4, TextureCompressionQuality.Normal);
            targetTex.Apply(true, true);
            AssetDatabase.CreateAsset(targetTex, assetLoadPath + "/" + assetName);
            
            assetName = outputPrefix + "AlbedoMap" + count + "_PC.asset";
            EditorUtility.CompressTexture(targetTexPC, TextureFormat.DXT5, TextureCompressionQuality.Normal);
            targetTexPC.Apply(true, true);
            AssetDatabase.CreateAsset(targetTexPC, assetLoadPath + "/" + assetName);
            
            outAlbedoPack.Add(targetTex);
        }
        AssetDatabase.Refresh();
#endregion

    }

    public void TransformNormalMap()
    {
#region GetNormalMap
        List<int> indexArray = new List<int>() {0, 1, 2, 3, 5,6,4 ,7,8 };
        outNormalPack = new List<Texture2D>();

        for(int i = 0; i < 3; i++)
        {
            int count = i;
            int indexPic0 = indexArray[count * 3 + 0];
            int indexPic1 = indexArray[count * 3 + 1];
            int indexPic2 = indexArray[count * 3 + 2];

            Texture2D currNormalMap00 = inNormalPack[indexPic0];
            Texture2D currNormalMap01 = inNormalPack[indexPic1];
            Texture2D currNormalMap02 = inNormalPack[indexPic2];

            ///
            /// 这边应该还需要知道当前的mask图是不是srgb格式的，因为转换之后的normal是default格式，这边的mask也需要对上。
            /// 如果是srgb格式的，我getpixels时候获取的数据是正确的，但是因为错误的格式，在linear space下会导致颜色发生改变，具体来说，本来在srgb中
            /// 颜色会更加淡，但是在linear space中，颜色变亮了。
            ///
            /// v2.0： 默认学俊哥会把mask图的srgb关掉。
            ///
            Texture2D currMaskMap00 = inMaskPack[indexPic0];
            Texture2D currMaskMap01 = inMaskPack[indexPic1];
            Texture2D currMaskMap02 = inMaskPack[indexPic2];



            int mipmapLevel = currNormalMap00.mipmapCount;
//            Debug.Log(mipmapLevel);
            var height = currNormalMap00.height;
            var width = currNormalMap00.width;
            Texture2D targetTex = new Texture2D(height * 2, width * 2, textureFormat: TextureFormat.RGBA32, true, true);
            Texture2D targetTexPC = new Texture2D(height * 2, width * 2, textureFormat: TextureFormat.RGBA32, true, true);

            for (int currLevel = 0; currLevel <= mipmapLevel; currLevel++)
            {
                List<Color> newcol = new List<Color>();

                if (currLevel == mipmapLevel)
                {
                    Color[] colorArray00 = currNormalMap00.GetPixels(currLevel - 1);
                    Color[] maskArray00 = currMaskMap00.GetPixels(currLevel - 1);
                    Color DxtnmColor = colorArray00[0];
                    Color MaskColor = maskArray00[0];
                    Color DefaultColor = Color.black;

                    // we first need to make sure our build platform normal encoding is right
                    if (PlayerSettings.GetNormalMapEncoding(BuildTargetGroup.Android) == NormalMapEncoding.XYZ)
                    {
                        DefaultColor.r = DxtnmColor.r;
                        DefaultColor.g = DxtnmColor.g;
                    }
                    else
                    {
                        DefaultColor.r = DxtnmColor.a;
                        DefaultColor.g = DxtnmColor.g;
                    }
                    DefaultColor.b = MaskColor.r;
                    DefaultColor.a = MaskColor.a;



                    newcol.Add(DefaultColor);
                }
                else
                {
                    Color[] colorArray00 = currNormalMap00.GetPixels(currLevel);
                    Color[] colorArray01 = currNormalMap01.GetPixels(currLevel);
                    Color[] colorArray02 = currNormalMap02.GetPixels(currLevel);

                    Color[] maskArray00 = currMaskMap00.GetPixels(currLevel);
                    Color[] maskArray01 = currMaskMap01.GetPixels(currLevel);
                    Color[] maskArray02 = currMaskMap02.GetPixels(currLevel);
                    var levelHeight = (int)(height / Mathf.Pow(2, currLevel));
                    var levelWidth = (int)(width / Mathf.Pow(2, currLevel));
                    for (int j = 0; j < levelHeight; j++)
                    {
                        for (int col = 0; col <= 1; col++)
                        {
                            for (int k = 0; k < levelWidth; k++)
                            {
                                if (col == 0)
                                {
                                    Color DxtnmColor = colorArray00[j * levelHeight + k];
                                    Color MaskColor = maskArray00[j * levelHeight + k];
                                    Color DefaultColor = Color.black;
                                    // we first need to make sure our build platform normal encoding is right
                                    if (PlayerSettings.GetNormalMapEncoding(BuildTargetGroup.Android) == NormalMapEncoding.XYZ)
                                    {
                                        DefaultColor.r = DxtnmColor.r;
                                        DefaultColor.g = DxtnmColor.g;
                                    }
                                    else
                                    {
                                        DefaultColor.r = DxtnmColor.a;
                                        DefaultColor.g = DxtnmColor.g;
                                    }
                                    DefaultColor.b = MaskColor.r;
                                    DefaultColor.a = MaskColor.a;
                                    newcol.Add(DefaultColor);
                                    newcol.Add(DefaultColor);
                                }
                                else
                                {
                                    Color DxtnmColor = colorArray01[j * levelHeight + k];
                                    Color MaskColor = maskArray01[j * levelHeight + k];
                                    Color DefaultColor = Color.black;
                                    // we first need to make sure our build platform normal encoding is right
                                    if (PlayerSettings.GetNormalMapEncoding(BuildTargetGroup.Android) == NormalMapEncoding.XYZ)
                                    {
                                        DefaultColor.r = DxtnmColor.r;
                                        DefaultColor.g = DxtnmColor.g;
                                    }
                                    else
                                    {
                                        DefaultColor.r = DxtnmColor.a;
                                        DefaultColor.g = DxtnmColor.g;
                                    }
                                    DefaultColor.b = MaskColor.r;
                                    DefaultColor.a = MaskColor.a;

                                    newcol.Add(DefaultColor);



                                    DxtnmColor = colorArray02[j * levelHeight + k];
                                    MaskColor = maskArray02[j * levelHeight + k];
                                    DefaultColor = Color.black;
                                    // we first need to make sure our build platform normal encoding is right
                                    if (PlayerSettings.GetNormalMapEncoding(BuildTargetGroup.Android) == NormalMapEncoding.XYZ)
                                    {
                                        DefaultColor.r = DxtnmColor.r;
                                        DefaultColor.g = DxtnmColor.g;
                                    }
                                    else
                                    {
                                        DefaultColor.r = DxtnmColor.a;
                                        DefaultColor.g = DxtnmColor.g;
                                    }
                                    DefaultColor.b = MaskColor.r;
                                    DefaultColor.a = MaskColor.a;

                                    newcol.Add(DefaultColor);

                                }



                            }
                        }
                    }
                }
                targetTex.SetPixels(newcol.ToArray(), currLevel);
                targetTexPC.SetPixels(newcol.ToArray(), currLevel);
                newcol.Clear();
            }
            string assetLoadPath = "Assets" + outputPath + "/";
            string assetName = outputPrefix + "Normal" + count + ".asset";
            outNormalPack.Add(targetTex);
            EditorUtility.CompressTexture(targetTex, TextureFormat.ASTC_4x4, TextureCompressionQuality.Normal);
            targetTex.Apply(true, true);
            AssetDatabase.CreateAsset(targetTex, assetLoadPath + "/" + assetName);
            
            assetName = outputPrefix + "Normal" + count + "_PC.asset";
            EditorUtility.CompressTexture(targetTexPC, TextureFormat.DXT5, TextureCompressionQuality.Normal);
            targetTexPC.Apply(true, true);
            AssetDatabase.CreateAsset(targetTexPC, assetLoadPath + "/" + assetName);
        }
        AssetDatabase.Refresh();
#endregion
    }
    
    void CreateMat()
    {
        ClearOldMat();
        CreateNew();
    }

    private void ClearOldMat()
    {
        string absoluteMatDirPath = "Assets" + this.matPath;
        string matPath = absoluteMatDirPath + "/" + this.matName + ".mat";
        Debug.Log(matPath);
        AssetDatabase.DeleteAsset(matPath);
    }

    private void CreateNew()
    {
        Material mat = new Material(Shader.Find("Catmull/MainCityTerrain"));
        string assetLoadPath = "Assets" + matPath + "/";
        string assetName = matName + ".mat";
        AssetDatabase.CreateAsset(mat, assetLoadPath + "/" + assetName);
        mat.SetTextureScale("_HeightPack0", new Vector2(60.0f, 60.0f));
        int count = 0;
        foreach (var VARIABLE in outAlbedoPack)
        {
            Debug.Log(VARIABLE.name);
            string propertyName = "_AlbedoPack" + count;
            mat.SetTexture(propertyName, VARIABLE);
            count++;
        }

        count = 0;
        foreach (var VARIABLE in outWeightPack)
        {
            Debug.Log(VARIABLE.name);
            string propertyName = "_WeightPack" + count;
            mat.SetTexture(propertyName, VARIABLE);
            count++;
        }

        count = 0;
        foreach (var VARIABLE in outHeightPack)
        {
            Debug.Log(VARIABLE.name);
            string propertyName = "_HeightPack" + count;
            mat.SetTexture(propertyName, VARIABLE);
            count++;
        }

        count = 0;
        foreach (var VARIABLE in outNormalPack)
        {
            Debug.Log(VARIABLE.name);
            string propertyName = "_NormalPack" + count;
            mat.SetTexture(propertyName, VARIABLE);
            count++;
        }

        currMat = mat;
        AssetDatabase.Refresh();
    }

    /// <summary>
    /// 内城地表pc端材质替换
    /// </summary>
    public  void __MainCityMaterialTranslation(bool isPCPlatform)
    {
        
        string file = "Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MaincityTerrainMat.mat";
        if (!File.Exists(file))
        {
            Debug.LogError("Can't find maincity mat! please check!!!");
            return;
        }
        
        Debug.Log("Start Replace Data");
        Texture2D[] mobileTextures = new Texture2D[10];
        mobileTextures[0] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_AlbedoMap0.asset");
        mobileTextures[1] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_AlbedoMap1.asset");
        mobileTextures[2] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_AlbedoMap2.asset");
        mobileTextures[3] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_HeightMap0.asset");
        mobileTextures[4] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_HeightMap1.asset");
        mobileTextures[5] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_Normal0.asset");
        mobileTextures[6] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_Normal1.asset");
        mobileTextures[7] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_Normal2.asset");
        mobileTextures[8] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_WeightMap00.asset");
        mobileTextures[9] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_WeightMap01.asset");

        foreach (var VARIABLE in mobileTextures)
        {
            if (!VARIABLE)
            {
                Debug.LogError("Can't find maincity Mobile Textures! please check!!!");
                return; 
            }
        }
        
        Texture2D[] pcTextures = new Texture2D[10];
        pcTextures[0] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_AlbedoMap0_PC.asset");
        pcTextures[1] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_AlbedoMap1_PC.asset");
        pcTextures[2] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_AlbedoMap2_PC.asset");
        pcTextures[3] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_HeightMap0_PC.asset");
        pcTextures[4] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_HeightMap1_PC.asset");
        pcTextures[5] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_Normal0_PC.asset");
        pcTextures[6] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_Normal1_PC.asset");
        pcTextures[7] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_Normal2_PC.asset");
        pcTextures[8] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_WeightMap00_PC.asset");
        pcTextures[9] = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Plugins/3rdPlugins/ELEX_MainCityResource/Arts/MAINCITY_TERRAINTEX_OUT_WeightMap01_PC.asset");

        foreach (var VARIABLE in pcTextures)
        {
            if (!VARIABLE)
            {
                Debug.LogError("Can't find maincity PC Textures! please check!!!");
                return; 
            }
        }

        
        string mobileGuid = string.Empty;
        string pcGuid = string.Empty;
        long localId;
        for (int i = 0; i < 10; i++)
        {
            AssetDatabase.TryGetGUIDAndLocalFileIdentifier(mobileTextures[i], out mobileGuid, out localId);
            AssetDatabase.TryGetGUIDAndLocalFileIdentifier(pcTextures[i], out pcGuid, out localId);

            string materialContent = File.ReadAllText(file);
            if (isPCPlatform)
            {
                materialContent = materialContent.Replace(mobileGuid, pcGuid);
                File.WriteAllText(file, materialContent);
            }
            else
            {
                materialContent = materialContent.Replace(pcGuid, mobileGuid);
                File.WriteAllText(file, materialContent);
            }


            Debug.Log(pcGuid + " , " + mobileGuid);
            AssetDatabase.Refresh();

        }

    }
}

[CustomEditor(typeof(TerrainToMeshTools_UnityTerrain))]
public class TerrainToMeshToolsEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        TerrainToMeshTools_UnityTerrain script = target as TerrainToMeshTools_UnityTerrain; ;
        if (GUILayout.Button("Extract"))
        {
            script.ExtactTextureInfo();

        }   
        
        if (GUILayout.Button("Test Mat Replace"))
        {
            script.__MainCityMaterialTranslation(false);

        }
    }
}

#endif