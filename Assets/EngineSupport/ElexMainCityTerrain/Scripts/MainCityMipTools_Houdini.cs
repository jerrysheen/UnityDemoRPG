#if UNITY_EDITOR
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

public class MainCityMipTools_Houdini : EditorWindow
{
    [SerializeField]string inputPath = "/EngineSupport/Houdini2UnityResource/OriginalResource";
    [SerializeField]string inputPrefix = "H2U_TERRAIN_IN_";
    [SerializeField]string outputPath = "/EngineSupport/Houdini2UnityResource/TransferedResource";
    [SerializeField]string outputPrefix = "H2U_TERRAIN_OUT_";

    [SerializeField]string matPath = "/EngineSupport/Houdini2UnityResource";
    [SerializeField]string matName = "MaincityTerrain";

    public List<Texture2D> inAlbedoPack;
    public List<Texture2D> inNormalPack;
    public List<Texture2D> inMaskPack;
    public List<Texture2D> inWeightPack;

    public List<Texture2D> outWeightPack;
    public List<Texture2D> outHeightPack;
    public List<Texture2D> outAlbedoPack;
    public List<Texture2D> outNormalPack;


    // Add menu named "My Window" to the Window menu
    //[MenuItem("Assets/[Engine] MainCityTerrain/ConvertTexture")]
    static void Init()
    {
        // Get existing open window or if none, make a new one:
        MainCityMipTools_Houdini window = (MainCityMipTools_Houdini)EditorWindow.GetWindow(typeof(MainCityMipTools_Houdini));

        window.Show();
    }

    void OnGUI()
    {
        GUILayout.Label("Texture Compress Format", EditorStyles.boldLabel);
        GUILayout.Label("the default android platform compress format here is : astc4x4");
        GUILayout.Space(20);
        GUILayout.Label("Input Texture Path", EditorStyles.boldLabel);
        inputPath = EditorGUILayout.TextField("input_texturePath", inputPath);
        inputPrefix = EditorGUILayout.TextField("input_prefix", inputPrefix);

        GUILayout.Label("Output Texture Path", EditorStyles.boldLabel);
        outputPath = EditorGUILayout.TextField("output_texturePath", outputPath);
        outputPrefix = EditorGUILayout.TextField("output_prefix", outputPrefix);

        GUILayout.Label("Output Mat", EditorStyles.boldLabel);
        matPath = EditorGUILayout.TextField("outputMatPath", matPath);
        matName = EditorGUILayout.TextField("outputMatName", matName);

        if (GUILayout.Button("Convert"))
        {
            Houdini2UnityTextureTransferTools(inputPath, outputPath);
//            Debug.Log(PlayerSettings.GetNormalMapEncoding(BuildTargetGroup.Android));
        }

        if (GUILayout.Button("Create a Material"))
        {
            CreateMat();
        }
    }

    private void Houdini2UnityTextureTransferTools(string inputRelativePath, string outputRelativePath)
    {
        // find texture, use importer to set read/write enable;
        CreateTextureList(inputRelativePath);
        // clean folder:
        CleanOutputFolder();
        // convert.
        TransfromTexture();
    }

    void CreateTextureList(string inputRelativePath)
    {
        inAlbedoPack = new List<Texture2D>();
        inNormalPack = new List<Texture2D>();
        inMaskPack = new List<Texture2D>();
        inWeightPack = new List<Texture2D>();

        outWeightPack = new List<Texture2D>();
        outHeightPack = new List<Texture2D>();
        outAlbedoPack = new List<Texture2D>();
        outNormalPack = new List<Texture2D>();
        // // the path gonna be look like this : Assets/Art/Houdini2UnityResource/OriginalResource
        // string test = AssetDatabase.GetAssetPath(Selection.activeObject);
        // Debug.Log(test);
        // string inputTexPath =  inputRelativePath + "/H2U_Terrain_IN_Albedo1_snow_basecolor.png";
        // Debug.Log(inputTexPath);
        // TextureImporter importer = (TextureImporter) TextureImporter.GetAtPath(inputTexPath);
        // importer.mipmapEnabled = true;
        // importer.isReadable = true;
        // importer.sRGBTexture = true;
        // importer.textureCompression = TextureImporterCompression.Uncompressed;
        // importer.SaveAndReimport();


        // string outputTexPath =  outputPath + "/H2U_Terrain_OUT_Albedo00.tga";
        // Texture2D currTexture = (Texture2D)AssetDatabase.LoadAssetAtPath(outputTexPath, typeof(Texture2D));
        // Debug.Log(currTexture.name);
        // Texture2D testTexture = new Texture2D(currTexture.width, currTexture.height);

        string absolutePath = Application.dataPath + inputPath;
        Debug.Log(absolutePath);
        DirectoryInfo dir = new DirectoryInfo(absolutePath);
        var info = dir.GetFiles("*.*").Where(s => s.Name.EndsWith(".tga") || s.Name.EndsWith(".png"));;
        foreach (FileInfo f in info)
        {
            // won't be care about index, caz it will list from 1 ~ 9
            string assetLoadPath = "Assets" + inputPath + "/" + f.Name;
            Debug.Log(f.Name);
            Texture2D currTexture = (Texture2D)AssetDatabase.LoadAssetAtPath(assetLoadPath, typeof(Texture2D));
            if (currTexture)
            {
                if (currTexture.name.Contains("Albedo"))
                {
                    inAlbedoPack.Add(currTexture);
                }
                else if (currTexture.name.Contains("Normal"))
                {
                    inNormalPack.Add(currTexture);
                }
                else if (currTexture.name.Contains("Mask"))
                {
                    inMaskPack.Add(currTexture);
                }
                else if (currTexture.name.Contains("Weight"))
                {
                    inWeightPack.Add(currTexture);
                }
            }
        }
    }

    void CleanOutputFolder()
    {
        string absoluteOutputPath = Application.dataPath + outputPath;
//        Debug.Log("OutputPath:" + absoluteOutputPath);
        if (Directory.Exists(absoluteOutputPath)) { Directory.Delete(absoluteOutputPath, true); }
        Directory.CreateDirectory(absoluteOutputPath);
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
            newcol.Clear();
            string assetLoadPath = "Assets" + outputPath + "/";
            string assetName = outputPrefix + "HeightMap" + i + ".asset";
            EditorUtility.CompressTexture(targetTex, TextureFormat.ASTC_4x4, TextureCompressionQuality.Normal);
            targetTex.Apply(true, true);
            AssetDatabase.CreateAsset(targetTex, assetLoadPath + "/" + assetName);
            outHeightPack.Add(targetTex);
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
        for (int j = 0; j < height; j++)
        {
            for (int k = 0; k < width; k++)
            {
                Color curr = Color.black;
                curr.r = inWeightPack[0].GetPixel(k, j).r;
                curr.g = inWeightPack[0].GetPixel(k, j).g;
                curr.b = inWeightPack[0].GetPixel(k, j).b;
                curr.a = inWeightPack[1].GetPixel(k, j).r;
                newcol.Add(curr);
            }
        }
        targetTex.SetPixels(newcol.ToArray());
        string assetLoadPath = "Assets" + outputPath + "/";
        string assetName = outputPrefix + "WeightMap00.asset";
        EditorUtility.CompressTexture(targetTex, TextureFormat.ASTC_4x4, TextureCompressionQuality.Normal);
        targetTex.Apply(true, true);
        AssetDatabase.CreateAsset(targetTex, assetLoadPath + "/" + assetName);
        outWeightPack.Add(targetTex);
        newcol.Clear();

        // pic01:
        targetTex = new Texture2D(height, width, textureFormat: TextureFormat.RGBA32, false, true);
        for (int j = 0; j < height; j++)
        {
            for (int k = 0; k < width; k++)
            {
                Color curr = Color.black;
                curr.r = inWeightPack[1].GetPixel(k, j).g;
                curr.g = inWeightPack[1].GetPixel(k, j).b;
                curr.b = inWeightPack[2].GetPixel(k, j).r;
                curr.a = inWeightPack[2].GetPixel(k, j).g;
                newcol.Add(curr);
            }
        }
        targetTex.SetPixels(newcol.ToArray());
        assetLoadPath = "Assets" + outputPath + "/";
        assetName = outputPrefix + "WeightMap01.asset";
        EditorUtility.CompressTexture(targetTex, TextureFormat.ASTC_4x4, TextureCompressionQuality.Normal);
        targetTex.Apply(true, true);
        AssetDatabase.CreateAsset(targetTex, assetLoadPath + "/" + assetName);
        outWeightPack.Add(targetTex);
        newcol.Clear();

        // // pic02:
        // targetTex = new Texture2D(height, width, textureFormat: TextureFormat.RGBA32, false, true);
        // for (int j = 0; j < height; j++)
        // {
        //     for (int k = 0; k < width; k++)
        //     {
        //         Color curr = Color.black;
        //         curr.r = inWeightPack[2].GetPixel(k, j).b;
        //         curr.g = 0.0f;
        //         curr.b = 0.0f;
        //         curr.a = 0.0f;
        //         newcol.Add(curr);
        //     }
        // }
        // targetTex.SetPixels(newcol.ToArray());
        // assetLoadPath = "Assets" + outputPath + "/";
        // assetName = outputPrefix + "WeightMap02.asset";
        // AssetDatabase.CreateAsset(targetTex, assetLoadPath + "/" + assetName);
        // outWeightPack.Add(targetTex);
        // newcol.Clear();
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
                newcol.Clear();

            }
            string assetLoadPath = "Assets" + outputPath + "/";
            string assetName = outputPrefix + "AlbedoMap" + count + ".asset";
            EditorUtility.CompressTexture(targetTex, TextureFormat.ASTC_4x4, TextureCompressionQuality.Normal);
            targetTex.Apply(true, true);
            AssetDatabase.CreateAsset(targetTex, assetLoadPath + "/" + assetName);
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
                newcol.Clear();
            }
            string assetLoadPath = "Assets" + outputPath + "/";
            string assetName = outputPrefix + "Normal" + count + ".asset";
            outNormalPack.Add(targetTex);
            EditorUtility.CompressTexture(targetTex, TextureFormat.ASTC_4x4, TextureCompressionQuality.Normal);
            targetTex.Apply(true, true);
            AssetDatabase.CreateAsset(targetTex, assetLoadPath + "/" + assetName);
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
    }

    protected void OnEnable ()
    {
        // Here we retrieve the data if it exists or we save the default field initialisers we set above
        var data = EditorPrefs.GetString("MainCityMipTools", JsonUtility.ToJson(this, false));
        // Then we apply them to this window
        JsonUtility.FromJsonOverwrite(data, this);
    }

    protected void OnDisable ()
    {
        // We get the Json data
        var data = JsonUtility.ToJson(this, false);
        // And we save it
        EditorPrefs.SetString("MainCityMipTools", data);

        // Et voilà !
    }

}
#endif
