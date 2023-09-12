// using UnityEditor;
// using UnityEngine;
// using System.Collections.Generic;
// using System.IO;
// using UnityEditor.SceneManagement;
// using ELEX.Resource;
// using ELEX.Common.Config;
// using UnityEngine.Playables;
// using YooAsset.Editor;
//
// public class ActorPrefabBuild
// {
// //    public enum EActorPrefabType
// //    {
// //        ActorPrefab_Character,
// //        ActorPrefab_SimpleCharacter,
// //        ActorPrefab_Item,
// //        ActorPrefab_Num
// //    }
//
//     // 存储临时的材质list;
//     //public static List<string> mTemData = new List<string>();
//     public static List<GameObject> mAllPackObjectList = new List<GameObject>();
//     //public static List<string> mAllExportObjPaths = new List<string>();
// //    [MenuItem("ELEX/PrefabExport/导出角色资源")]
// //    static void Execute()
// //    {
// //        if (ObjectBuild(false))
// //        {
// //            Debugger.Log(" 物件打包完成 ");
// //        }
// //
// //        mAllPackObjectList.Clear();
// //
// //        AssetDatabase.Refresh();
// //        AssetDatabase.SaveAssets();
// //    }
// //    [MenuItem("ELEX/PrefabExport/一键导出角色资源")]
// //    static void ExecuteAuto()
// //    {
// //        if (ObjectBuildAuto(false))
// //        {
// //            Debugger.Log(" 物件打包完成 ");
// //        }
// //        else
// //        {
// //            Debugger.LogError(" 物件打包失败 ");
// //        }
// //
// //        mAllPackObjectList.Clear();
// //
// //        AssetDatabase.Refresh();
// //        AssetDatabase.SaveAssets();
// //    }
//
//     [MenuItem("Assets/【模型】加入Game_Prefab【model】", priority = 101)]
//     public static void ExportSimplePrefabNoAnim()
//     {
//         if (SimpleObjectBuild(false))
//         {
//             // Debugger.Log(" 物件打包完成 ");
//         }
//
//         mAllPackObjectList.Clear();
//
//         AssetDatabase.Refresh();
//         AssetDatabase.SaveAssets();
//     }
//
//     [MenuItem("Assets/【特效】/加入Game_Prefab\\fx", priority = 101)]
//     private static void ExportParticlePrefab()
//     {
//         if (ParticleObjectBuild())
//         {
//             // Debugger.Log(" 物件打包完成 ");
//         }
//
//         mAllPackObjectList.Clear();
//
//         AssetDatabase.Refresh();
//         AssetDatabase.SaveAssets();
//     }
//     
//     [MenuItem("Assets/【特效】/加入Game_Prefab\\fx\\test", priority = 102)]
//     private static void ExportParticlePrefabTest()
//     {
//         if (ParticleObjectBuild("/test"))
//         {
//             // Debugger.Log(" 物件打包完成 ");
//         }
//
//         mAllPackObjectList.Clear();
//
//         AssetDatabase.Refresh();
//         AssetDatabase.SaveAssets();
//     }
//
//     [MenuItem("Assets/【模型】加入Game_Prefab【model\\dep】", priority = 101)]
//     public static void ExportSimplePrefabToDependency()
//     {
//         if (SimpleObjectBuild(false, "dep"))
//         {
//             // Debugger.Log(" 物件打包完成 ");
//         }
//
//         mAllPackObjectList.Clear();
//
//         AssetDatabase.Refresh();
//         AssetDatabase.SaveAssets();
//     }
//     
//     [MenuItem("Assets/【地型】加入Game_Prefab【model】会去掉block_mesh节点", priority = 101)]
//     public static void ExportMapPrefab()
//     {
//         if (SimpleObjectBuild(false, null, "block_mesh"))
//         {
//             // Debugger.Log(" 物件打包完成 ");
//         }
//
//         mAllPackObjectList.Clear();
//
//         AssetDatabase.Refresh();
//         AssetDatabase.SaveAssets();
//     }
//
//     static void FindAllPackObject()
//     {
//         // 直接查找
//         UnityEngine.Object[] SelectionAsset = Selection.GetFiltered(typeof(UnityEngine.Object), SelectionMode.Assets);
//         foreach(UnityEngine.Object obj in SelectionAsset)
//         {
//             string folder = AssetDatabase.GetAssetPath(obj);
//             if (Path.GetExtension(folder) == ".prefab")
//             {
//                 mAllPackObjectList.Add(AssetDatabase.LoadAssetAtPath<GameObject>(folder));
//                 continue;
//             }
//             
//             string[] prefabFiles = Directory.GetFiles(folder, "*.prefab", SearchOption.AllDirectories);
//             if (prefabFiles.Length == 0)
//                 continue;
//
//             for (int i = 0; i < prefabFiles.Length; i++)
//             {
//                 mAllPackObjectList.Add(AssetDatabase.LoadAssetAtPath<GameObject>(prefabFiles[i]));
//             }
//         }
//     }
//
// //    public static void BuildSceneAllObj()
// //    {
// //        // 得到场景中所有的gameobject 节点;
// //        Object[] goes = Object.FindObjectsOfType(typeof(GameObject));
// //        foreach (Object obj in goes)
// //        {
// //            GameObject gameObj = obj as GameObject;
// //            // 查找根节点;
// //            if (gameObj != null && gameObj.transform.parent == null)
// //            {
// //                BuildSelObject(gameObj);
// //            }
// //        }
// //    }
//
//     // 检查资源是否冗余;
// //    static void CheckResRedundance(string prefabName, string foldName, string typeName)
// //    {
// //        if(mAllExportObjPaths == null)
// //        {
// //            return;
// //        }
// //
// //        string prefabPath = PrefabBuildCommon.getBuildPrefabPath(prefabName, typeName, foldName);
// //        if(mAllExportObjPaths.Contains(prefabPath))
// //        {
// //            mAllExportObjPaths.Remove(prefabPath);
// //        }
// //    }
//
// //    public static void BuildSelObject(GameObject objectFBX)
// //    {
// //        if (objectFBX == null)
// //        {
// //            return;
// //        }
// //
// //        Object srcPrefab = PrefabUtility.GetPrefabParent(objectFBX);
// //        if (srcPrefab == null)
// //        {
// //            for (int i = 0; i < objectFBX.transform.childCount; i++)
// //            {
// //                GameObject subObjectFBX = objectFBX.transform.GetChild(i).gameObject;
// //                BuildSelObject(subObjectFBX);
// //            }
// //            //Debugger.LogError(objectFBX.name + "--- GetPrefabParent == null！");
// //            return;
// //        }
// //
// //        if (objectFBX.activeSelf == false)
// //        {
// //            Debugger.LogError(objectFBX.name + "--- activeSelf == false！");
// //            return;
// //        }
// //
// //        if (PrefabBuildCommon.CheckGameObjectValid(objectFBX) == false)
// //        {
// //            return;
// //        }
// //
// //        mAllPackObjectList.Add((GameObject)srcPrefab);
// //    }
//
// //    public static void PackInit()
// //    {
// //
// //    }
//
// //    public static void PackObject(bool isCheck)
// //    {
// //        if (mAllPackObjectList == null)
// //        {
// //            return;
// //        }
// //        for (int i = 0, imax = mAllPackObjectList.Count; i < imax; i++)
// //        {
// //            GameObject gameObj = mAllPackObjectList[i];
// //            if (gameObj == null)
// //            {
// //                continue;
// //            }
// //
// //            if(isCheck)
// //            {
// //                if (EditorUtility.DisplayCancelableProgressBar("CheckObject", string.Format("({0}/{1}) {2}", i + 1, imax, gameObj.name), (i + 1f) / imax))
// //                {
// //                    return;
// //                }
// //            }
// //
// //            Object obj = gameObj.GetComponentInChildren<MeshRenderer>();
// //            if (obj != null)
// //            {
// //                Debugger.LogError("实体资源中包含MeshRenderer对象 : " + gameObj.name);
// //                if (isCheck)
// //                {
// //                    // 检查静态实体资源是否冗余;
// //                    CheckResRedundance(gameObj.name + ".prefab", "mesh", ResourceConst.ResourceItem);
// //                }
// //                else
// //                {
// //                    PackStaticObject(gameObj);
// //                }
// //                continue;
// //            }
// //
// //            // 目前没什么用，可以删除;
// //            //obj = mAllPackObjectList[i].GetComponentInChildren<AnimationPack>();
// //            //if (obj != null)
// //            //{
// //            //    PackAllAnimtion(mAllPackObjectList[i]);
// //            //    continue;
// //            //}
// //
// ////            obj = gameObj.GetComponentInChildren<DynamicBone>();
// ////            if (obj != null)
// ////            {
// ////                PackDynamicBoneObj(gameObj, isCheck);
// ////                continue;
// ////            }
// //
// //            string name = gameObj.name.ToLower();
// //            if (PrefabBuildCommon.CheckFile(name))
// //            {
// //                PackBone(gameObj, isCheck);
// //                PackMesh(gameObj, isCheck);
// //            }
// //            else
// //            {
// //                int first = name.IndexOf("_");
// //                if (first > 0)
// //                {
// //                    string substring = name.Substring(first + 1);
// //                    if (substring.Contains("_"))
// //                    {
// //                        PackMesh(gameObj, isCheck);
// //                    }
// //                    else
// //                    {
// //                        PackBone(gameObj, isCheck);
// //                    }
// //                }
// //            }
// //        }
// //
// //        mAllPackObjectList.Clear();
// //    }
//
// //    public static bool ObjectBuild(bool isCheck)
// //    {
// //        mAllPackObjectList.Clear();
// //        FindAllPackObject();
// //        EditorSceneManager.SaveScene(UnityEditor.SceneManagement.EditorSceneManager.GetActiveScene());
// //
// //        PackInit();
// //        PackObject(isCheck);
// //        return true;
// //    }
//     
//     // 导出简单实体资源，将资源整个prefab导出，不进行任何拆分;
//     public static void PackSimpleObject(string folderPath, bool exportAnim = true, string removeNodeName = "")
//     {
//         if (mAllPackObjectList == null)
//         {
//             return;
//         }
//         for (int i = 0; i < mAllPackObjectList.Count; i++)
//         {
//             GameObject gameObj = mAllPackObjectList[i];
//             if (gameObj == null)
//             {
//                 continue;
//             }
//
//             // 打包材质;
//             //PackMaterial(mAllPackObjectList[i], ResourceConst.ResourceCharacter);
//             // 获取实体对应资源导出到指定目录;
//             string bundleName = gameObj.name.ToLower();
//             // GameObject instanceObj = GameObject.Instantiate(mAllPackObjectList[i]) as GameObject;
//
//             // 剥离材质;
//             //Renderer[] renderers = instanceObj.GetComponentsInChildren<Renderer>(true);
//             //if (renderers != null)
//             //{
//             //    CharacterRendererInfo rendererInfo = instanceObj.GetComponent<CharacterRendererInfo>();
//             //    if (rendererInfo != null && rendererInfo.m_RendererArray != null)
//             //    {
//             //        foreach (Renderer renderer in rendererInfo.m_RendererArray)
//             //        {
//             //            if (renderer == null)
//             //            {
//             //                Object.DestroyImmediate(instanceObj);
//             //                Debugger.LogError("实体资源CharacterRendererInfo包含有空对象 : " + bundleName);
//             //                continue;
//             //            }
//             //        }
//             //        if (renderers.Length > rendererInfo.m_RendererArray.Length)
//             //        {
//             //            Object.DestroyImmediate(instanceObj);
//             //            Debugger.LogError("实体资源包含多个材质，但有材质未放置在CharacterRendererInfo中管理 : " + bundleName);
//             //            continue;
//             //        }
//             //    }
//             //    else if (renderers.Length > 1)
//             //    {
//             //        Object.DestroyImmediate(instanceObj);
//             //        Debugger.LogError("实体资源包含多个材质，但未挂接CharacterRendererInfo管理 : " + bundleName);
//             //        continue;
//             //    }
//             //    foreach (Renderer renderer in renderers)
//             //    {
//             //        renderer.sharedMaterials = new Material[1];
//             //    }
//             //}
//             
//             // 剥离动画资源;
// //            if (exportAnim)
// //            {
// //                PackAllAnim(gameObj, false);
// //            }
//
//             gameObj = PrefabBuildCommon.PackPrefab(gameObj, bundleName, folderPath) as GameObject;
//             if (gameObj != null)
//             {
//                 bool dirty = false;
//                 Animator animator = gameObj.GetComponent<Animator>();
//                 if (animator != null)
//                 {
//                     // 无动画的没必要保留animator;
//                     if (animator.runtimeAnimatorController == null)
//                     {
//                         Object.DestroyImmediate(animator, true);
//                         dirty = true;
//                     }
//
// //                    if (animator.cullingMode != AnimatorCullingMode.CullUpdateTransforms)
// //                    {
// //                        animator.cullingMode = AnimatorCullingMode.CullUpdateTransforms;
// //                        dirty = true;
// //                    }
//                 }
//
//                 SkinnedMeshRenderer[] allRenderer = gameObj.GetComponentsInChildren<SkinnedMeshRenderer>(true);
//                 if (allRenderer != null)
//                 {
//                     
//                     for (int j = 0; j < allRenderer.Length; j++)
//                     {
//                         SkinnedMeshRenderer meshRenderer = allRenderer[j];
//                         if (meshRenderer != null && meshRenderer.receiveShadows)
//                         {
//                             meshRenderer.receiveShadows = false;
//                             dirty = true;
//                         }
//                     }
//                 }
//
//                 if (!string.IsNullOrEmpty(removeNodeName) && RemoveObj(gameObj.transform, removeNodeName))
//                 {
//                     dirty = true;
//                 }
//                 
//                 if (dirty)
//                 {
//                     EditorUtility.SetDirty(gameObj);
//                 }
//             }
//         }
//
//         mAllPackObjectList.Clear();
//     }
//
//     private static bool RemoveObj(Transform tarTran, string name)
//     {
//         int childCnt = tarTran.childCount;
//         bool ret = false;
//         
//         for (int i = childCnt - 1; i >= 0; i--)
//         {
//             Transform tran = tarTran.GetChild(i);
//             if (tran != null && tran.name == name)
//             {
//                 GameObject.DestroyImmediate(tran.gameObject, true);
//                 ret = true;
//             }
//             else
//             {
//                 ret |= RemoveObj(tran, name);
//             }
//         }
//
//         return ret;
//     }
//
//     // 检查简单实体资源是否冗余;
// //    public static void CheckSimpleObject()
// //    {
// //        if (mAllPackObjectList == null)
// //        {
// //            return;
// //        }
// //        for (int i = 0, imax = mAllPackObjectList.Count; i < imax; i++)
// //        {
// //            if (mAllPackObjectList == null || mAllPackObjectList[i] == null)
// //            {
// //                continue;
// //            }
// //
// //            // 获取实体对应资源导出到指定目录;
// //            string bundleName = mAllPackObjectList[i].name;
// //            if (EditorUtility.DisplayCancelableProgressBar("CheckSimpleObject", string.Format("({0}/{1}) {2}", i + 1, imax, bundleName), (i + 1f) / imax))
// //            {
// //                return;
// //            }
// //
// //            Animator animator = mAllPackObjectList[i].GetComponent<Animator>();
// //            if (animator != null)
// //            {
// //                if (animator.runtimeAnimatorController != null && PrefabBuildCommon.CheckNpcFile(bundleName))
// //                {
// //                    PackAllAnim(mAllPackObjectList[i], true);
// //                }
// //            }
// //
// //            // 只检查资源是否冗余;
// //            //CheckResRedundance(bundleName + ".prefab", "prefab", ResourceConst.ResourceCharacter);
// //        }
// //
// //        mAllPackObjectList.Clear();
// //    }
//
//     public static bool SimpleObjectBuild(bool exportAnim = true, string folderPath = null, string removeNodeName = "")
//     {
//         FindAllPackObject();
//         if (!string.IsNullOrEmpty(folderPath))
//             folderPath = AssetBundleCollectorSettingData.ModelPackPath();
//         else
//             folderPath = string.Format("{0}/{1}", AssetBundleCollectorSettingData.ModelPackPath(), folderPath);
//         PackSimpleObject(folderPath, exportAnim, removeNodeName);
//         return true;
//     }
//
//     public static void PackItemObject(bool isCheck)
//     {
//         if (mAllPackObjectList == null)
//         {
//             return;
//         }
//         for (int i = 0, imax = mAllPackObjectList.Count; i < imax; i++)
//         {
//             if (mAllPackObjectList == null || mAllPackObjectList[i] == null)
//             {
//                 continue;
//             }
//             if (isCheck)
//             {
//                 if (EditorUtility.DisplayCancelableProgressBar("CheckItemObject", string.Format("({0}/{1}) {2}", i + 1, imax, mAllPackObjectList[i].name), (i + 1f) / imax))
//                 {
//                     return;
//                 }
//                 // 检查静态实体资源是否冗余;
//                 // CheckResRedundance(mAllPackObjectList[i].name + ".prefab", "mesh", ResourceConst.ResourceItem);
//             }
//             else
//             {
//                 PackStaticObject(mAllPackObjectList[i]);
//             }
//         }
//     }
//
//     public static bool ItemObjectBuild(bool isCheck)
//     {
//         FindAllPackObject();
//
//         PackItemObject(isCheck);
//         return true;
//     }
//
//     /// <summary>
//     /// 如果非简单模型，动作需要单独拷贝到Game_Prefab/character/animation/xx/*.anim
//     /// </summary>
//     /// <param name="prefabObj"></param>
//     /// <param name="isCheck"></param>
//     public static void PackBone(GameObject prefabObj, bool isCheck)
//     {
//         if (prefabObj == null)
//         {
//             return;
//         }
//         string bundleName = null;
//         //string bundleName_extra = null;
//         string lowBundleName = prefabObj.name.ToLower();
//         if (PrefabBuildCommon.CheckFile(lowBundleName))
//         {
//             bundleName = prefabObj.name;
//         }
//         else
//         {
//             bundleName = prefabObj.name;
//
//             //int index = prefabObj.name.IndexOf("_");
//             //if (index == -1)
//             //{
//             //    bundleName = prefabObj.name;
//             //    Debugger.LogError(string.Format("PackBone prefabObj.name:{0} can't contain  _", prefabObj.name));
//             //}
//             //else
//             //{
//             //    bundleName = prefabObj.name.Substring(0, index);
//             //}
//             //string[] name_array = prefabObj.name.Split('_');
//             //bundleName_extra = name_array[0];
//
//             //PackAllAnim(prefabObj, isCheck);
//         }
//         string assetName = bundleName + "_characterbase";
//         // 只检查资源是否冗余;
//         if(isCheck)
//         {
//             // CheckResRedundance(assetName + ".prefab", "bone", ResourceConst.ResourceCharacter);
//             return;
//         }
//
//         GameObject instanceObj = GameObject.Instantiate(prefabObj) as GameObject;
//         //  PackAnimatorController(prefabObj);
//         foreach (SkinnedMeshRenderer smr in instanceObj.GetComponentsInChildren<SkinnedMeshRenderer>())
//         {
//             if (smr.name != instanceObj.name && smr.sharedMesh != null)
//             {
//                 Object.DestroyImmediate(smr.gameObject);
//             }
//             else if (smr.gameObject.transform.parent)
//                 Object.DestroyImmediate(smr.gameObject);
//         }
//
//         Animator animator = instanceObj.GetComponent<Animator>();
//         if (animator != null)
//         {
//             animator.runtimeAnimatorController = null;
//             animator.cullingMode = AnimatorCullingMode.AlwaysAnimate;
//         }
//
//         PrefabBuildCommon.PackPrefab(instanceObj, assetName,
//             AssetBundleCollectorSettingData.GetResTypePath(ResourceType.Character_Bone));
//         Object.DestroyImmediate(instanceObj);
//     }
//     
//     private static bool ParticleObjectBuild(string lastPath = "")
//     {
//         FindAllPackObject();
//         DealParticlePrefab(lastPath);
//         return true;
//     }
//     
//     private static void DealParticlePrefab(string lastPath = "")
//     {
//         if (mAllPackObjectList == null || mAllPackObjectList.Count == 0)
//         {
//             return;
//         }
//
//         List<string> successList = new List<string>();
//         List<string> failList = new List<string>();
//         List<string> timeWarnningList = new List<string>();
//         List<string> fxSettingWarnningList = new List<string>();
//         for (int i = 0; i < mAllPackObjectList.Count; i++)
//         {
//             GameObject gameObj = mAllPackObjectList[i];
//             if (gameObj == null)
//             {
//                 continue;
//             }
//             
//             string path = AssetDatabase.GetAssetPath(gameObj);
//
//             bool dirty = false;
//             string bundleName = gameObj.name.ToLower();
//             gameObj = PrefabBuildCommon.PackPrefab(gameObj, bundleName, AssetBundleCollectorSettingData.FxPackPath() + lastPath) as GameObject;
//             
//             if (gameObj != null)
//             {
//                 ParticleSystem rootP = gameObj.GetComponent<ParticleSystem>();
//                 if (rootP == null)
//                 {
//                     // ParticleSystem[] allParticleSystems = gameObj.GetComponentsInChildren<ParticleSystem>();
//                     // TrailRenderer[] trailRenderers = gameObj.GetComponentsInChildren<TrailRenderer>();
//                     //
//                     // // 目前纯拖尾特效允许根节点没有ParticleSystem;
//                     // if (trailRenderers.Length == 0 || allParticleSystems.Length > 0)
//                     // {
//                     //     failList.Add(path);
//                     //
//                     //     path = AssetDatabase.GetAssetPath(gameObj);
//                     //     
//                     //     File.Delete(path);
//                     //     path += ".meta";
//                     //     if (File.Exists(path))
//                     //     {
//                     //         File.Delete(path);
//                     //     }
//                     //     continue;
//                     // }
//                     
//                     if (gameObj.transform.childCount > 0)
//                     {
//                         rootP = gameObj.transform.GetChild(0).GetComponent<ParticleSystem>();
//                     }
//                 }
//                 
//                 if(rootP != null)
//                 {
//                     if (!rootP.main.loop && MathGUtils.floatEqual(rootP.main.duration, 5f))
//                     {
//                         // Debugger.LogWarning("提示：" + path + "\n非循环特效，总持续时间是5s吗？");
//                         timeWarnningList.Add(path);
//                     }
//                     
//                     // 这一改，子粒子系统会跟着全改，需求只改跟节点PlayOnAwake，暂未找到合适接口，保持原样，防止错误;
//                     // rootP.playOnAwake = false;
//                 }
//
//                 FxSetting fxSetting = gameObj.GetComponent<FxSetting>();
//                 if (fxSetting == null)
//                 {
//                     dirty = true;
//                     fxSetting = gameObj.AddComponent<FxSetting>();
//                     
//                     // Debugger.LogWarning("提示：" + path + "\n自动添加了FxSetting脚本");
//                     fxSettingWarnningList.Add(path);
//                 }
//                 
//                 EditorUtility.SetDirty(gameObj);
//                 successList.Add(path);
//             }
//         }
//
//         if (successList.Count > 0)
//         {
//             ClientCommon.tempStrBuilder.Length = 0;
//             ClientCommon.tempStrBuilder.Append("成功导入：");
//             foreach (string s in successList)
//             {
//                 ClientCommon.tempStrBuilder.Append("\n==== " + s);    
//             }
//
//             Debug.Log(ClientCommon.tempStrBuilder.ToString());
//         }
//         
//         if (timeWarnningList.Count > 0)
//         {
//             ClientCommon.tempStrBuilder.Length = 0;
//             ClientCommon.tempStrBuilder.Append("时间警告：");
//             foreach (string s in timeWarnningList)
//             {
//                 ClientCommon.tempStrBuilder.Append("\n==== " + s + " 非循环，总持续时间是5s吗？");    
//             }
//             
//             Debug.LogWarning(ClientCommon.tempStrBuilder.ToString());
//         }
//         
//         if (fxSettingWarnningList.Count > 0)
//         {
//             ClientCommon.tempStrBuilder.Length = 0;
//             ClientCommon.tempStrBuilder.Append("FxSetting脚本警告(导出添加了默认的FxSetting脚本)：");
//             foreach (string s in fxSettingWarnningList)
//             {
//                 ClientCommon.tempStrBuilder.Append("\n==== " + s);    
//             }
//             
//             Debug.LogWarning(ClientCommon.tempStrBuilder.ToString());
//         }
//         
//         if (failList.Count > 0)
//         {
//             ClientCommon.tempStrBuilder.Length = 0;
//             foreach (string s in failList)
//             {
//                 ClientCommon.tempStrBuilder.Append(s + " 根节点必须有 ParticleSystem 组件\n");    
//             }
//
//             EditorUtility.DisplayDialog("导出失败", ClientCommon.tempStrBuilder.ToString(), "确定");
//         }
//         
//         
//         mAllPackObjectList.Clear();
//     }
//
//     //public static void PackAnimatorController(GameObject prefabObj)
//     //{
//     //    string[] ass = { AssetDatabase.GetAssetPath(prefabObj) };
//     //    string[] deps = AssetDatabase.GetDependencies(ass);
//
//     //    foreach (string assetpath in deps)
//     //    {
//     //        string extension = System.IO.Path.GetExtension(assetpath).ToLower();
//     //        if (extension == ".controller")
//     //        {
//     //            string fileName = System.IO.Path.GetFileNameWithoutExtension(assetpath).ToLower();
//     //            if (extension == ".controller")
//     //            {
//     //                mTemData.Add(assetpath);
//     //                // 如果同目录下有override_cotroller文件就一并拷过来
//     //                string fileDirectory = System.IO.Path.GetDirectoryName(assetpath).ToLower();
//     //                mTemData.Add(string.Format("{0}/{1}.overrideController", fileDirectory, fileName));
//     //            }
//
//     //            if (fileName.Contains("@"))
//     //            {
//     //                mTemData.Add(assetpath);
//     //            }
//     //        }
//     //    }
//
//     //    for (int i = 0; i < mTemData.Count; i++)
//     //    {
//     //        string filePath = mTemData[i];
//
//     //        string fileName = System.IO.Path.GetFileName(filePath);
//
//     //        int index = fileName.IndexOf(".", 0, fileName.Length);
//     //        if (index > 0)
//     //        {
//     //            fileName = fileName.Substring(0, index);
//     //        }
//
//     //        string assetPath = PrefabBuildCommon.getBuildPrefabPath(filePath, ResourceConst.ResourceCharacter, "animation");
//
//     //        string metaPath = string.Format("{0}.meta", filePath);
//     //        string metaAssetPath = string.Format("{0}.meta", assetPath);
//     //        try
//     //        {
//     //            if (File.Exists(filePath) == false)
//     //            {
//     //                UnityEngine.Debugger.LogError(filePath + "--文件不存在");
//     //                continue;
//     //            }
//     //            File.Copy(filePath, assetPath, true);
//     //            File.Copy(metaPath, metaAssetPath, true);
//     //        }
//     //        catch (System.Exception exe)
//     //        {
//     //            UnityEngine.Debugger.LogError(exe.Message.ToString());
//     //        }
//
//     //    }
//
//     //    mTemData.Clear();
//     //}
//
//     // 导出所有动画文件到指定目录;
// //    public static void PackAllAnim(GameObject prefabObj, bool isCheck)
// //    {
// //        if(prefabObj == null)
// //        {
// //            return;
// //        }
// //        string prefabName = prefabObj.name;
// //
// //        string[] ass = { AssetDatabase.GetAssetPath(prefabObj) };
// //        string[] deps = AssetDatabase.GetDependencies(ass);
// //
// //        string animatorControllerName = string.Empty;
// //        foreach (string assetpath in deps)
// //        {
// //            string extension = Path.GetExtension(assetpath).ToLower();
// //            if (extension == ".anim")
// //            {
// //                mTemData.Add(assetpath);
// //            }
// //            else if (extension == ".controller" && string.IsNullOrEmpty(animatorControllerName))
// //            {
// //                animatorControllerName = Path.GetFileNameWithoutExtension(assetpath);
// //            }
// //        }
// //
// //        for (int i = 0; i < mTemData.Count; i++)
// //        {
// //            string filePath = mTemData[i];
// //            
// //            string assetPath = PrefabBuildCommon.getBuildPrefabPath(filePath, ResourceConst.ResourceCharacter, "animation/"+ animatorControllerName);
// //            // 只检查资源是否冗余;
// //            if (isCheck)
// //            {
// ////                if (mAllExportObjPaths != null && mAllExportObjPaths.Contains(assetPath))
// ////                {
// ////                    mAllExportObjPaths.Remove(assetPath);
// ////                }
// //                continue;
// //            }
// //
// //            try
// //            {
// //                if (File.Exists(filePath) == false)
// //                {
// //                    UnityEngine.Debugger.LogError(filePath + "--文件不存在");
// //                    continue;
// //                }
// //                File.Copy(filePath, assetPath, true);
// //            }
// //            catch (System.Exception exe)
// //            {
// //                UnityEngine.Debugger.LogError(exe.Message.ToString());
// //            }
// //        }
// //
// //        mTemData.Clear();
// //    }
//
//     /// <summary>
//     /// 将prefab里的SkinnedMeshRenderer单独克隆出来，骨点信息存储到BoneIndex脚本中，挂到一个父节点上，制作成一个prefab文件;
//     /// 拷贝到Game_Prefab/character/mesh/*.prefab;
//     /// </summary>
//     /// <param name="prefabObj"></param>
//     /// <param name="isCheck"></param>
//     public static void PackMesh(GameObject prefabObj, bool isCheck)
//     {
//         if (prefabObj == null)
//         {
//             return;
//         }
//
//         // 只检查资源是否冗余;
//         if (isCheck)
//         {
//             // CheckResRedundance(prefabObj.name + ".prefab", "mesh", ResourceConst.ResourceCharacter);
//             return;
//         }
//
//         //PackMaterial(prefabObj, ResourceConst.ResourceCharacter);
//
//         //GameObject fbxClone = Object.Instantiate(prefabObj) as GameObject;
//         SkinnedMeshRenderer[] skinnMeshes = prefabObj.GetComponentsInChildren<SkinnedMeshRenderer>(true);
//         Transform[] boneTrans = prefabObj.GetComponentsInChildren<Transform>();
//
//         GameObject fbxClone = new GameObject(prefabObj.name);
//         foreach (SkinnedMeshRenderer smr in skinnMeshes)
//         {
//             if (smr == null || smr.sharedMesh == null || smr.bones == null)
//                 continue;
//
//             string meshName = smr.name;
//             //string parentName = prefabObj.name;
//             //if (meshName != parentName)
//             //{
//             //    Debugger.LogError(parentName + "子节点名字和父节点不一致！！！！！");
//             //    meshName = parentName;
//             //}
//
//             GameObject rendererClone = (GameObject)Object.Instantiate(smr.gameObject);
//             if (rendererClone.transform.parent != null)
//             {
//                 GameObject rendererParent = rendererClone.transform.parent.gameObject;
//
//                 rendererClone.transform.parent = null;
//                 Object.DestroyImmediate(rendererParent);
//             }
//             rendererClone.name = meshName;
//             rendererClone.transform.parent = fbxClone.transform;
//
//             Renderer render = rendererClone.GetComponent<Renderer>();
//             if (render == null)
//             {
//                 continue;
//             }
//             // 如果不设置为null会依赖资源prefab，导致打包时资源依赖太多;
//             SkinnedMeshRenderer skinnedMeshRenderer = render as SkinnedMeshRenderer;
//             if (skinnedMeshRenderer != null)
//             {
//                 skinnedMeshRenderer.rootBone = null;
//                 skinnedMeshRenderer.bones = null;
//             }
//             //render.sharedMaterials = new Material[1];
//             BoneIndex boneIndex = rendererClone.AddComponent<BoneIndex>();
//             string boneHash = string.Empty;
//             foreach (Transform t in smr.bones)
//             {
//                 for (int i = 0; i < boneTrans.Length; i++)
//                 {
//                     if (t == null)
//                     {
//                         if (string.IsNullOrEmpty(boneHash))
//                         {
//                             boneHash = "-1";
//                         }
//                         else
//                         {
//                             boneHash += (";" + "-1");
//                         }
//                         break;
//                     }
//                     if (t.name != boneTrans[i].name) continue;
//                     if (string.IsNullOrEmpty(boneHash))
//                     {
//                         boneHash = Animator.StringToHash(t.name).ToString(); //i.ToString();
//                     }
//                     else
//                     {
//                         boneHash += (";" + Animator.StringToHash(t.name).ToString());
//                     }
//                     break;
//                 }
//             }
//
//             boneIndex.mBoneHash = boneHash;
//             //PrefabBuildCommon.PackPrefab(rendererClone, meshName, "mesh", ResourceConst.ResourceCharacter);
//             //GameObject.DestroyImmediate(rendererClone);
//             //GameObject.DestroyImmediate(fbxClone);
//         }
//         PrefabBuildCommon.PackPrefab(fbxClone, prefabObj.name, AssetBundleCollectorSettingData.GetResTypePath(ResourceType.Character_Mesh));
//         GameObject.DestroyImmediate(fbxClone);
//     }
//
//     /// <summary>
//     /// 这个的prefab只要是把prefab相关的fbx直接取得md5看是不是改变了
//     /// </summary>
//     /// <param name="prefabObj"></param>
//     static void PackStaticObject(GameObject prefabObj)
//     {
//         if (prefabObj == null)
//         {
//             return;
//         }
//
//         //PackMaterial(prefabObj, ResourceConst.ResourceItem);
//
//         GameObject rendererClone = (GameObject)Object.Instantiate(prefabObj);
//
//         //Renderer mesh = rendererClone.GetComponentInChildren<Renderer>();
//         //if (mesh != null)
//         //{
//         //    Material[] mat = new Material[1];
//         //    mesh.sharedMaterials = mat;
//         //}
//
//         Animator anim = rendererClone.GetComponent<Animator>();
//         if (anim != null && anim.runtimeAnimatorController == null)
//         {
//             Object.DestroyImmediate(anim, true);
//         }
//         PrefabBuildCommon.PackPrefab(rendererClone, prefabObj.name, AssetBundleCollectorSettingData.GetResTypePath(ResourceType.Item_Mesh));
//         GameObject.DestroyImmediate(rendererClone);
//     }
//
//     /// <summary>
//     /// 材质的输出只是单纯的把材质的mat文件和相关的贴图文件拷贝
//     /// </summary>
//     /// <param name="prefabObj"></param> 
//     /// <param name="isModifyMatValue"></param>
// //    public static void PackMaterial(GameObject prefabObj, string typeName)
// //    {
// //        string[] ass = { AssetDatabase.GetAssetPath(prefabObj) };
// //        string[] deps = AssetDatabase.GetDependencies(ass);
// //
// //        foreach (string assetpath in deps)
// //        {
// //            string extension = System.IO.Path.GetExtension(assetpath).ToLower();
// //            if (extension == ".mat")
// //            {
// //                if (extension == ".mat")
// //                {
// //                    mTemData.Add(assetpath);
// //                }
// //                else
// //                {
// //                    mTemData.Insert(0, assetpath);
// //                }
// //            }
// //        }
// //
// //        for (int i = 0; i < mTemData.Count; i++)
// //        {
// //            string filePath = mTemData[i];
// //
// //            string fileName = System.IO.Path.GetFileName(filePath);
// //
// //            int index = fileName.IndexOf(".", 0, fileName.Length);
// //            if (index > 0)
// //            {
// //                fileName = fileName.Substring(0, index);
// //            }
// //
// //            string assetPath = PrefabBuildCommon.getBuildPrefabPath(filePath, typeName, "material");
// //
// //            string metaPath = string.Format("{0}.meta", filePath);
// //            string metaAssetPath = string.Format("{0}.meta", assetPath);
// //            try
// //            {
// //                File.Copy(filePath, assetPath, true);
// //                File.Copy(metaPath, metaAssetPath, true);
// //            }
// //            catch (System.Exception exe)
// //            {
// //                UnityEngine.Debugger.LogError(exe.Message.ToString());
// //            }
// //
// //        }
// //
// //        mTemData.Clear();
// //
// //    }
// }
