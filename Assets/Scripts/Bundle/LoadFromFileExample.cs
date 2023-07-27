using System.IO;
using UnityEngine;

public class LoadFromFileExample : MonoBehaviour
{
    void Start()
    {
        var myLoadedAssetBundle
            = AssetBundle.LoadFromFile(Path.Combine(Application.streamingAssetsPath, "textures"));
        if (myLoadedAssetBundle == null)
        {
            Debug.Log("Failed to load AssetBundle!");
            Debug.Log("File Path :" + Path.Combine(Application.streamingAssetsPath, "textures"));
            return;
        }
        Texture2D prefab = myLoadedAssetBundle.LoadAsset<Texture2D>("H2U_TERRAIN_OUT_Normal0");
        //Instantiate(prefab);

        Material currMat = this.GetComponent<MeshRenderer>().material;
        currMat.SetTexture("_BaseMap", prefab);
    }
}