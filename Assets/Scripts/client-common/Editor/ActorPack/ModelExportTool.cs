using UnityEngine;
using UnityEditor;
using System.Collections;
using System.IO;
using System.Collections.Generic;
using UnityEditor.Animations;
using System.Xml.Serialization;
using System;
using ELEX.Resource;
using UnityEditor.U2D;
using UnityEngine.U2D;

[Serializable]
[XmlType(@"AnimNameList")]
public class ConfAnimNameList
{
    [System.Xml.Serialization.XmlElement(@"AnimName")]
    public List<string> AnimName = new List<string>();
    [System.Xml.Serialization.XmlElement(@"LoopAnimName")]
    public List<string> LoopAnimName = new List<string>();
}

public static class ModelExportTool
{
    //static List<string> cacheFbxNameList = new List<string>();

//    [MenuItem("Assets/【模型】1.处理动作和prefab添加挂点信息&加入Game_Prefab", priority = 102)]
//    static void DealNPCExportAndAddGamePrefab()
//    {
//        DealNPCExport();
//        ActorPrefabBuild.ExportSimplePrefabNoAnim();
//    }
    
    // fbx目录;
    
    [MenuItem("Assets/【模型】处理动作和prefab添加挂点信息", priority = 100)]
    public static void DealNPCExport()
    {
        //EditorCommon.ClearConsole();
        
        InitAnimConfig();
        //cacheFbxNameList.Clear();

        UnityEngine.Object[] SelectionAsset = Selection.GetFiltered(typeof(UnityEngine.Object), SelectionMode.Assets);
        foreach(UnityEngine.Object obj in SelectionAsset)
        {
            string npcFolder = AssetDatabase.GetAssetPath(obj);
            DealNpcFolder(npcFolder);
        }
        
        EditorUtility.DisplayDialog("提示", "操作成功", "知道了");
    }
    
//    [MenuItem("Assets/【模型】处理2D序列帧动画资源", priority = 100)]
//    static void DealFrameExport()
//    {
//        EditorCommon.ClearConsole();
//        
//        InitAnimConfig();
//        
//        SpriteAtlasUtility.PackAllAtlases(PackBundleTools.platform);
//        
//        // 缓存图集;
//        List<SpriteAtlas> spriteAtlasList = new List<SpriteAtlas>();
//        List<string> allatlas = EditorCommon.GetSprites(ResourceConfig.ResCfg.AtlasPackPath);
//        foreach (string atlas in allatlas)
//        {
//            SpriteAtlas spriteAtlas = AssetDatabase.LoadAssetAtPath<SpriteAtlas>(atlas);
//            if (spriteAtlas == null) continue;
//            spriteAtlasList.Add(spriteAtlas);
//        }
//
//        UnityEngine.Object[] SelectionAsset = Selection.GetFiltered(typeof(UnityEngine.Object), SelectionMode.Assets);
//        foreach(UnityEngine.Object obj in SelectionAsset)
//        {
//            string npcFolder = AssetDatabase.GetAssetPath(obj);
//            DealFolderFrameAnimation(npcFolder, spriteAtlasList);
//        }
//        
//        EditorUtility.DisplayDialog("提示", "操作成功", "知道了");
//    }

    /// <summary>
    /// 1.生成动作及AnimatorController；2.将动作绑到prefab上；3.自动添加CharacterBoneInfo脚本;
    /// </summary>
    /// <param name="npcFolder"></param>
    static void DealNpcFolder(string npcFolder)
    {
        string prefabFolder = npcFolder + "/prefab";

        string[] prefabFiles = Directory.GetFiles(prefabFolder, "*.prefab");
        if (prefabFiles.Length == 0)
        {
            EditorUtility.DisplayDialog("提示", prefabFolder + "没有模型prefab文件", "知道了");
            return;
        }

        // anim、animcontroller生成;
        AnimatorController animController = GenerateAnimFolderInternal(npcFolder);

        GameObject focusObj = null;
        for (int i = 0; i < prefabFiles.Length; i++)
        {
            GameObject gameObj = AssetDatabase.LoadAssetAtPath<GameObject>(prefabFiles[i]);
            if(gameObj == null) continue;
            
            Animator animtor = gameObj.GetComponent<Animator>();
            if (animtor == null)
            {
                animtor = gameObj.AddComponent<Animator>();
            }
            animtor.runtimeAnimatorController = animController;
            
            CharacterBoneInfo boneInfo = gameObj.GetComponent<CharacterBoneInfo>();
            if (boneInfo == null)
            {
                boneInfo = gameObj.AddComponent<CharacterBoneInfo>();
            }
            string configFile = Application.dataPath + "/../StickBoneExprot.xml";
            CharacterBoneInfoInspector.ImportXml(configFile, boneInfo);
            
            EditorUtility.SetDirty(gameObj);
            focusObj = gameObj;
        }
        
        AssetDatabase.Refresh();
        AssetDatabase.SaveAssets();

        if (focusObj != null)
        {
//            Scene scene = EditorSceneManager.GetActiveScene();
//            if (scene != null)
//            {
//                focusObj = PrefabUtility.InstantiatePrefab(focusObj, scene) as GameObject;
//                focusObj.transform.SetAsLastSibling();
//            }
            Selection.activeObject = focusObj;
            EditorGUIUtility.PingObject(focusObj);
        }
    }

    static Material GetMaterial(string folder)
    {
        string materialFolder = folder + "/material";
        
        if (Directory.Exists(materialFolder) == false)
        {
            EditorUtility.DisplayDialog("提示", "材质目录不存在！", "知道了");
            return null;
        }

        string[] mat_files = Directory.GetFiles(materialFolder, "*.mat");
        if (mat_files.Length == 0)
        {
            return null;
        }

        return AssetDatabase.LoadAssetAtPath<Material>(mat_files[0]);
    }

    static AnimatorController GenerateAnimFolderInternal(string folder)
    {
        string fbxFolder = folder + "/fbx";
        string animFolder = folder + "/" + ResourceConst.CombineAnimFolser;

        string npcName = Path.GetFileName(folder);
        string controllerFullPath = animFolder + "/" + npcName + ".controller";

        if (Directory.Exists(fbxFolder) == false)
        {
            EditorUtility.DisplayDialog("提示", "fbx目录不存在！", "知道了");
            return null;
        }

        // anim 处理;
        if (Directory.Exists(animFolder))
        {
            Directory.Delete(animFolder, true);
        }
        Directory.CreateDirectory(animFolder);
        string[] fbx_files = Directory.GetFiles(fbxFolder, "*.fbx");
#if UNITY_EDITOR_OSX
        if (fbx_files.Length == 0)
            fbx_files = Directory.GetFiles(fbxFolder, "*.FBX");
#endif

        AnimatorController animController = null;
        List<AnimationClip> animList = new List<AnimationClip>();
        if (fbx_files.Length > 0)
        {
            foreach (string fbx_file in fbx_files)
            {
                if (!IsAnimFbx(fbx_file))
                {
                    continue;
                }

                string animName = GetAnimName(fbx_file);
                if (string.IsNullOrEmpty(animName))
                {
                    string ptStr = fbx_file + " 命名不合理";
                    EditorUtility.DisplayDialog("提示", ptStr, "知道了");
                    continue;
                }

//                if(!GetAnimNameList().Contains(animName))
//                {
//                    cacheFbxNameList.Add(Path.GetFileName(fbx_file));
//                    //continue;
//                }

                AnimationClip animClip = AssetDatabase.LoadAssetAtPath<AnimationClip>(fbx_file);
                if (animClip == null) continue;

                AnimationClip newClip = new AnimationClip();
                EditorUtility.CopySerialized(animClip, newClip);

                // 设置循环动作;
                if (IsLoopAnim(animName))
                {
                    AnimationClipSettings clipSetting = AnimationUtility.GetAnimationClipSettings(newClip);
                    clipSetting.loopTime = true;
                    AnimationUtility.SetAnimationClipSettings(newClip, clipSetting);
                }
                AssetDatabase.CreateAsset(newClip, animFolder + "/" + animName + ".anim");
                animList.Add(newClip);
            }

            // 把stand排最前面;
            animList.Sort((back, pre) =>
            {
                if (back != null && back.name.StartsWith("stand") && !pre.name.StartsWith("stand"))
                    return -1;
                return 1;
            });
            
            if (animList.Count > 0)
            {
                animController = AnimatorController.CreateAnimatorControllerAtPath(controllerFullPath);
                AnimatorControllerLayer _layer = animController.layers[0];
                AnimatorStateMachine _state = _layer.stateMachine;
                int index = 0;
                foreach (AnimationClip clip in animList)
                {
                    AnimatorState state = _state.AddState(clip.name, Vector3.zero + Vector3.one * index);
                    index -= 50;
                    state.motion = clip;
                }
            }
            else
            {
                if (Directory.Exists(animFolder))
                {
                    Directory.Delete(animFolder, true);
                }
            }
        }
        return animController;
    }

    static bool IsAnimFbx(string fbxName)
    {
        if (string.IsNullOrEmpty(fbxName))
            return false;

        fbxName = fbxName.ToLower();
        fbxName = Path.GetFileNameWithoutExtension(fbxName);
        if (fbxName.EndsWith("skin"))
        {
            return false;
        }

        return true;
    }

    static bool IsLoopAnim(string animName)
    {
        foreach (var anim in GetLoopAnimNameList())
        {
            if (animName.Contains(anim))
                return true;
        }

        return false;
    }

    static string GetAnimName(string fbxName)
    {
        fbxName = Path.GetFileNameWithoutExtension(fbxName).ToLower().Replace(" ", "");
        int _pos = fbxName.LastIndexOf("@");
        if (_pos >= 0) return fbxName.Substring(_pos + 1).ToLower();
        
        _pos = fbxName.LastIndexOf("_");
        return (_pos >= 0) ? fbxName.Substring(_pos + 1).ToLower() : fbxName.ToLower();
    }

    #region Config;
    static List<string> s_anim_list = new List<string>();
    static List<string> s_loop_anim_list = new List<string>();
    static void InitAnimConfig()
    {
        string config_path = Application.dataPath + "/../model_anim_name_list.xml";
        if (File.Exists(config_path))
        {
            XmlSerializer x = new XmlSerializer(typeof(ConfAnimNameList));
            StreamReader reader = File.OpenText(config_path);
            try
            {
                ConfAnimNameList animList = (ConfAnimNameList)x.Deserialize(reader);
                if (animList != null)
                {
                    s_anim_list = animList.AnimName;
                    s_loop_anim_list = animList.LoopAnimName;
                }
            }
            catch (Exception e)
            {
                Debug.LogException(e);
                EditorUtility.DisplayDialog("model_anim_name_list Serialize Failed", "See console for detail\n \n" + e.Message, "OK");
            }
            finally
            {
                if (reader != null)
                {
                    reader.Close();
                }
            }
        }
    }

    static List<string> GetAnimNameList()
    {
        return s_anim_list;
    }

    static List<string> GetLoopAnimNameList()
    {
        return s_loop_anim_list;
    }
    #endregion


    //[MenuItem("Assets/比较骨骼，选中两个prefab【场合主角时装导入】")]
    //[MenuItem("ModelExport/CompareBones")]
//    [MenuItem("GameObject/ModelExport/CompareBones", false, 0)]
//    public static void ComparePrefabBones()
//    {
//        List<GameObject> gameObjList = new List<GameObject>();
//        foreach (GameObject gameObj in Selection.gameObjects)
//        {
//            if (gameObj != null)
//            {
//                gameObjList.Add(gameObj);
//            }
//        }
//
//        if (gameObjList.Count < 2)
//            return;
//
//        Transform[] bones1 = gameObjList[0].GetComponentsInChildren<Transform>();
//        Transform[] bones2 = gameObjList[1].GetComponentsInChildren<Transform>();
//
//        StringBuilder sb = new StringBuilder();
//        List<string> compare_list = new List<string>();
//        for (int nIdx = 0; nIdx < bones1.Length && nIdx < bones2.Length; ++nIdx)
//        {
//            Transform bone1 = bones1[nIdx];
//            Transform bone2 = bones2[nIdx];
//            if (bone1 == null || bone2 == null)
//            {
//                continue;;
//            }
//
//            if (bone1.name != bone2.name)
//            {
//                sb.Append(bone1.name + " ------ " + bone2.name + "|");
//            }
//        }
//
//        if (sb.Length > 0)
//        {
//            EditorUtility.DisplayDialog("提示", sb.ToString(), "知道了");
//        }
//        else
//        {
//            EditorUtility.DisplayDialog("提示", "完全一样", "知道了");
//        }
//    }
}