using UnityEngine;
using UnityEditor;
using System.IO;
using System.Security.Cryptography;
using ELEX.Resource;

public class PrefabBuildCommon
{
//    public static string getBuildPrefabPath(string szAssetPath,string typeName, string foldName)
//    {
//        string filePath = szAssetPath;
//        string fileName = System.IO.Path.GetFileName(filePath);
//        string folderPath = null;
//
//        if (string.IsNullOrEmpty(foldName))
//        {
//            folderPath = string.Format("Assets/{1}/{0}", typeName, ResourceConfig.ResCfg.PackPath);
//        }
//        else
//        {
//            folderPath = string.Format("Assets/{2}/{0}{1}/", typeName, foldName, ResourceConfig.ResCfg.PackPath);
//        }
//
//        if (!Directory.Exists(folderPath))
//        {
//            Directory.CreateDirectory(folderPath);
//        }
//
//        filePath = folderPath + fileName;
//        return filePath;
//    }

    public static Object PackPrefab(GameObject gameobj, string prefabName, string folderPath)
    {
        if (gameobj == null)
        {
            return null;
        }

        if (!Directory.Exists(folderPath))
            Directory.CreateDirectory(folderPath);

        string localPath = prefabName + ".prefab";
        string fileName = Path.GetFileName(localPath);
        string prefabPath = Path.Combine(folderPath, fileName);

        // 因为打包的时候会对生成的prefab直接进行打包,所以需要判断打包的对象是不是进行了修改
        if(File.Exists(prefabPath))
        {
            File.Delete(prefabPath);
        }

        UnityEngine.Object newPrefab = PrefabUtility.CreateEmptyPrefab(prefabPath);
        newPrefab = PrefabUtility.ReplacePrefab(gameobj, newPrefab);
        AssetDatabase.ImportAsset(prefabPath);
        return newPrefab;
    }

    /// <summary>
    /// 得到文件的md5值
    /// </summary>
    /// <param name="filePath">绝对路径</param>
    /// <returns></returns>
    public static string getFileMD5(string filePath)
    {
        try
        {
            FileStream fs = new FileStream(filePath, FileMode.Open);
            int len = (int)fs.Length;
            byte[] data = new byte[len];
            fs.Read(data, 0, len);
            fs.Close();
            MD5 md5 = new MD5CryptoServiceProvider();
            byte[] result = md5.ComputeHash(data);
            string fileMD5 = "";
            foreach (byte b in result)
            {
                fileMD5 += System.Convert.ToString(b, 16);
            }
            return fileMD5;
        }
        catch (FileNotFoundException e)
        {
			Debug.LogError(e.ToString());
            return "";
        }
    }

    public static bool CheckFile(string fileName)
    {
        if(string.IsNullOrEmpty(fileName))
        {
            return false;
        }

        string name = fileName.ToLower();
        // 武器 NPC 宠物 怪物 坐骑 法宝 采集物 触发器;
        if (name.Contains("_wp_") || name.Contains("npc_") || name.Contains("pet_") ||
            name.Contains("mon_") || name.Contains("boss_") || name.Contains("mount_") || name.Contains("magic_") || 
            name.Contains("collect_") || name.Contains("wing_") || name.Contains("other_"))
        {
            return true;
        }
        return false;
    }

    // 检测是否是Npc，Npc需要剥离所有动画然后采取动态加载的资源;
    public static bool CheckNpcFile(string fileName)
    {
        if (string.IsNullOrEmpty(fileName))
        {
            return false;
        }

        string name = fileName.ToLower();
        // NPC 宠物 怪物 坐骑 采集物;
        if ( name.Contains("npc_") || name.Contains("pet_") || name.Contains("mon_") || name.Contains("monster_") ||
            name.Contains("boss_") || name.Contains("mount_") || name.Contains("collect_") || name.Contains("wing_"))
        {
            return true;
        }
        return false;
    }

    public static bool CheckGameObjectValid(GameObject objectFBX)
    {
        if (objectFBX == null)
        {
            return false;
        }

        PrefabType prefabType = UnityEditor.PrefabUtility.GetPrefabType(objectFBX);
        if (prefabType == PrefabType.DisconnectedPrefabInstance || prefabType == PrefabType.MissingPrefabInstance)
        {
            Debug.LogError(objectFBX.name + "--- prefab错误！");
            return false;
        }

        if (objectFBX.name.Contains("@"))
        {
            Debug.LogError(objectFBX.name + "--- 存在错误的对象!!!");
            return false;
        }

        for (int i = 0; i < objectFBX.transform.childCount; i++)
        {
            GameObject obj = objectFBX.transform.GetChild(i).gameObject;
            if (obj.name.Contains("@"))
            {
                Debug.LogError(objectFBX.name + "--- 存在错误的子节点!!!");
                return false;
            }
        }

        return true;
    }
}
