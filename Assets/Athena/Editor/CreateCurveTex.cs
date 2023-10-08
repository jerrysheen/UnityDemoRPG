using UnityEngine;
using UnityEditor;

public class CreateCurveTex
{
    [MenuItem("Tools/SSS/CreateCurveTex")]
    static void DoIt()
    {
        Mesh mesh;
        Material mat;
        try
        {
            mesh = Selection.activeGameObject.GetComponent<MeshFilter>().sharedMesh;
            mat = Object.Instantiate(Selection.activeGameObject.GetComponent<MeshRenderer>().sharedMaterial);
        }
        catch (System.Exception e)
        {
            Debug.Log(e.ToString());
            return;
        }

        Texture tex = mat.mainTexture;
        RenderTexture rt = new RenderTexture(tex.width, tex.height, 0, RenderTextureFormat.ARGB32);
        Graphics.SetRenderTarget(rt);
        mat.shader = Shader.Find("SSS/SkinBake");
        mat.SetPass(0);
        Graphics.DrawMeshNow(mesh,Matrix4x4.identity);
        RenderTexture rt2 = new RenderTexture(tex.width, tex.height, 0, RenderTextureFormat.ARGB32);
        Graphics.SetRenderTarget(rt2);
        Graphics.Blit(rt, mat, 1);

        Texture2D result = new Texture2D(tex.width, tex.height, TextureFormat.ARGB32,false);
        result.ReadPixels(new Rect(0, 0, tex.width, tex.height), 0, 0);
        result.Apply();
        System.IO.File.WriteAllBytes("Assets/Athena/curve.png", result.EncodeToPNG());
        Graphics.SetRenderTarget(null);
        rt.Release();
        rt2.Release();
        AssetDatabase.Refresh();
    }
}