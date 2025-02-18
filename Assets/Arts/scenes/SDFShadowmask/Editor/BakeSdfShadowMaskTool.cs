using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace Elex.SDFShadowMask.Editor
{
    public class SelfLightmapSettings
    {
        public MixedLightingMode mixedBakeMode;

        public float lightmapResolution;

        public int lightmapMaxSize;

        public int padding;
    }

    public class BakeSdfShadowMaskTool : EditorWindow
    {
        public enum OutPutType
        {
            SingleChannel_Alpha,
            SingleChannel_R16,
            RGBA32_AChannel,
            RGBA32_RChannel,
        }

        [MenuItem("Window/Bake SDF ShadowMask")]
        static void Init()
        {
            var window = (BakeSdfShadowMaskTool)EditorWindow.GetWindow(typeof(BakeSdfShadowMaskTool), false, "BakeSdfShadowMaskTool", true);
            window.Show();
        }

        SelfLightmapSettings hightQualitySetting;
        SelfLightmapSettings outputQualitySetting;

        int high2LowScale = 4;

        float insideValue = 10;
        float outsideValue = 10;
        SdfUtility.ColorChannel inputChannel = SdfUtility.ColorChannel.R;

        SdfUtility.ColorChannel outputChannel = SdfUtility.ColorChannel.R;
        TextureFormat outputFormat = TextureFormat.RGBA32;
        OutPutType outType = OutPutType.RGBA32_RChannel;

        string outputPath = "";
        //---------------------------------------------
        LightingData lightingDataPass1;
        LightingData lightingDataPass2;
        Dictionary<int, TextureSlicer> slicersPass1 = new Dictionary<int, TextureSlicer>();
        Dictionary<int, TextureSlicer> slicersPass2 = new Dictionary<int, TextureSlicer>();
        //---------------------------------------------
        bool useDefaultScenePath = true;

        bool useDefaultSetting = true;
        //---------------------------------------------

        bool isDebug = true;
        //---------------------------------------------
        const string titleStr = "距离场ShadowMask烘焙工具";
        const string defaultSettingStr = "默认设置";

        //const string maxShadowmapStr = "Max Shadowmap(Lightmap) Size";
        //const string shadowmapResulotionStr = "Shadowmap(Lightmap) Resolution";
        //const string shadowmapPaddingStr = "Shadowmap(Lightmap) padding";
        //const string hight2LowScaleStr = "High Low Scale";
        //const string sdfInsideMaxValueStr = "inside max value";
        //const string sdfOutsideMaxValueStr = "outside max value";
        //const string inputTextureChannelStr = "select input channel";
        //const string outputTextureTypeStr = "select out put type";
        //const string useScenePathStr = "use scene path";

        const string maxShadowmapStr = "Mask图片最大尺寸";
        const string shadowmapResulotionStr = "烘焙分辨率(pixel/unit)";
        const string shadowmapPaddingStr = "烘焙图形间隔";
        const string hight2LowScaleStr = "精细程度";
        const string sdfInsideMaxValueStr = "距离场内圈最大距离";
        const string sdfOutsideMaxValueStr = "距离场外圈最大距离";
        const string inputTextureChannelStr = "输入图片的颜色通道";
        const string outputTextureTypeStr = "输出图片格式";

        const string useScenePathStr = "使用场景默认路径输出";

        const string startStr = "开始烘焙";
        const string cancleStr = "取消烘焙";
        //---------------------------------------------
        private void OnGUI()
        {
            EditorGUILayout.BeginVertical();
            EditorGUILayout.LabelField(titleStr);
            EditorGUILayout.EndVertical();
            EditorGUILayout.Space(4);

            if (Lightmapping.isRunning)
            {
                EditorGUILayout.BeginVertical();

                if (GUILayout.Button(cancleStr))
                {
                    Lightmapping.Cancel();
                }
                EditorGUILayout.EndVertical();

                return;
            }

            EditorGUILayout.BeginVertical();

            if (hightQualitySetting == null)
            {
                hightQualitySetting = new SelfLightmapSettings();
                hightQualitySetting.lightmapMaxSize = Lightmapping.lightingSettings.lightmapMaxSize;
                hightQualitySetting.lightmapResolution = Lightmapping.lightingSettings.lightmapResolution;
                hightQualitySetting.mixedBakeMode = Lightmapping.lightingSettings.mixedBakeMode;
                hightQualitySetting.padding = Lightmapping.lightingSettings.lightmapPadding;
            }
            if (outputQualitySetting == null)
            {
                outputQualitySetting = new SelfLightmapSettings();
                outputQualitySetting.lightmapMaxSize = Lightmapping.lightingSettings.lightmapMaxSize;
                outputQualitySetting.lightmapResolution = Lightmapping.lightingSettings.lightmapResolution;
                outputQualitySetting.mixedBakeMode = Lightmapping.lightingSettings.mixedBakeMode;
                outputQualitySetting.padding = Lightmapping.lightingSettings.lightmapPadding;
            }

            useDefaultSetting = EditorGUILayout.Toggle(defaultSettingStr, useDefaultSetting);
            if (!useDefaultSetting)
            {
                outputQualitySetting.lightmapMaxSize = EditorGUILayout.IntField(maxShadowmapStr, outputQualitySetting.lightmapMaxSize);

                outputQualitySetting.lightmapResolution = EditorGUILayout.FloatField(shadowmapResulotionStr, outputQualitySetting.lightmapResolution);

                outputQualitySetting.padding = EditorGUILayout.IntField(shadowmapPaddingStr, outputQualitySetting.padding);

                var resolutionScale = hightQualitySetting.lightmapResolution / outputQualitySetting.lightmapResolution;
                if (high2LowScale != (int)resolutionScale)
                {
                    resolutionScale = high2LowScale;
                    hightQualitySetting.lightmapResolution = resolutionScale * outputQualitySetting.lightmapResolution;
                }
                var oriscale = high2LowScale;
                high2LowScale = EditorGUILayout.IntField(hight2LowScaleStr, high2LowScale);
                if (oriscale != high2LowScale)
                {
                    if (high2LowScale < 1)
                    {
                        high2LowScale = 1;
                    }

                    var targetResolution = outputQualitySetting.lightmapResolution * high2LowScale;
                    var maxSize = outputQualitySetting.lightmapMaxSize * high2LowScale;

                    maxSize = Mathf.NextPowerOfTwo(maxSize);

                    if (maxSize > 4096)
                    {
                        maxSize = 4096;
                    }

                    hightQualitySetting.lightmapMaxSize = maxSize;
                    hightQualitySetting.lightmapResolution = targetResolution;
                    hightQualitySetting.padding = outputQualitySetting.padding;
                    hightQualitySetting.mixedBakeMode = outputQualitySetting.mixedBakeMode;
                }

                insideValue = EditorGUILayout.FloatField(sdfInsideMaxValueStr, insideValue);
                outsideValue = EditorGUILayout.FloatField(sdfOutsideMaxValueStr, outsideValue);
                inputChannel = (SdfUtility.ColorChannel)EditorGUILayout.EnumPopup(inputTextureChannelStr, inputChannel);
                var oritype = outType;
                outType = (OutPutType)EditorGUILayout.EnumPopup(outputTextureTypeStr, outType);
                if (outType != oritype)
                {
                    switch (oritype)
                    {
                        case OutPutType.SingleChannel_Alpha:
                            {
                                outputChannel = SdfUtility.ColorChannel.A;
                                outputFormat = TextureFormat.Alpha8;
                            }
                            break;
                        case OutPutType.SingleChannel_R16:
                            {
                                outputChannel = SdfUtility.ColorChannel.R;
                                outputFormat = TextureFormat.R16;
                            }
                            break;
                        case OutPutType.RGBA32_RChannel:
                            {
                                outputChannel = SdfUtility.ColorChannel.R;
                                outputFormat = TextureFormat.RGBA32;
                            }
                            break;
                        case OutPutType.RGBA32_AChannel:
                            {
                                outputChannel = SdfUtility.ColorChannel.A;
                                outputFormat = TextureFormat.RGBA32;
                            }
                            break;
                    }
                }

                if (isDebug)
                {
                    EditorGUILayout.LabelField("hight lightmapResolution", hightQualitySetting.lightmapResolution.ToString());
                    EditorGUILayout.LabelField("hight padding", hightQualitySetting.padding.ToString());
                    EditorGUILayout.LabelField("hight lightmapMaxSize", hightQualitySetting.lightmapMaxSize.ToString());

                    EditorGUILayout.LabelField("outputChannel", outputChannel.ToString());
                    EditorGUILayout.LabelField("outputFormat", outputFormat.ToString());
                }
            }
            else
            {
                var resolutionScale = hightQualitySetting.lightmapResolution / outputQualitySetting.lightmapResolution;
                if (high2LowScale != (int)resolutionScale)
                {
                    resolutionScale = high2LowScale;
                    hightQualitySetting.lightmapResolution = resolutionScale * outputQualitySetting.lightmapResolution;
                }
            }

            useDefaultScenePath = EditorGUILayout.Toggle(useScenePathStr, useDefaultScenePath);

            if (GUILayout.Button(startStr))
            {
                if (useDefaultScenePath)
                {
                    var scene = EditorSceneManager.GetActiveScene();
                    outputPath = scene.path.Replace(".unity", "");
                }
                else
                {
                    if (outputPath == null)
                    {
                        outputPath = Application.dataPath;
                    }

                    outputPath = EditorUtility.OpenFolderPanel("", outputPath, "");
                }

                if (string.IsNullOrEmpty(outputPath))
                {
                    Debug.LogError("Output Path null");
                    return;
                }

                //pass1
                Lightmapping.lightingSettings.mixedBakeMode = MixedLightingMode.Shadowmask;
                Lightmapping.lightingSettings.lightmapResolution = hightQualitySetting.lightmapResolution;
                Lightmapping.lightingSettings.lightmapMaxSize = hightQualitySetting.lightmapMaxSize;
                Lightmapping.lightingSettings.lightmapPadding = hightQualitySetting.padding;

                if (Lightmapping.BakeAsync())
                {
                    Lightmapping.bakeCompleted += ProcessPass1;
                }
            }



            EditorGUILayout.EndVertical();
        }

        void SliceShadowMask(LightingData lData, Dictionary<int, TextureSlicer> slicers)
        {
            slicers.Clear();

            var renderdataIDs = lData.lightmappedRendererDataIDs;

            var renderdata = lData.lightmappedRendererData;

            var maps = lData.lightmaps;

            for (int mapindex = 0; mapindex < maps.Length; ++mapindex)
            {
                List<Vector4> stList = new List<Vector4>();
                List<ulong> sceneObjIDList = new List<ulong>();

                if (!slicers.ContainsKey(mapindex))
                {
                    slicers.Add(mapindex, new TextureSlicer());
                }

                for (var i = 0; i < renderdata.Length; ++i)
                {
                    if (renderdata[i].lightmapIndex == mapindex)
                    {
                        //Debug.LogFormat("<color=red>lightmap ST {0}</color>", renderdata[i].lightmapST);
                        //Debug.LogFormat("<color=green>lightmapSTDynamic {0}</color>", renderdata[i].lightmapSTDynamic);
                        stList.Add(renderdata[i].lightmapST);

                        sceneObjIDList.Add(renderdataIDs[i].targetObject);
                    }
                }

                slicers[mapindex].Slice(maps[mapindex].shadowMask, stList.ToArray(), sceneObjIDList.ToArray());
            }
        }

        void CopySdfTextures(Dictionary<int, TextureSlicer> slicersSource, Dictionary<int, TextureSlicer> slicersTarget)
        {
            foreach (var slicerMap in slicersTarget)
            {
                var slicer = slicerMap.Value;
                var slices = slicer.GetSlices();
                foreach (var s in slices)
                {
                    foreach (var slicerMap1 in slicersSource)
                    {
                        var result = slicerMap1.Value.FindSlice(s.objID);
                        if (result != null)
                        {
                            s.sdftex = result.sdftex;

                            continue;
                        }
                    }
                }
            }
        }

        void SaveShadowMask(string selectpath, Dictionary<int, TextureSlicer> slicers, TextureFormat outputformat)
        {
            Debug.LogFormat("SaveShadowMask Path: {0}", selectpath);
            if (!string.IsNullOrEmpty(selectpath))
            {
                foreach (var slicer in slicers)
                {
                    slicer.Value.CombineSdf(1, outputformat, out Texture2D targettex);
                    if (targettex != null)
                    {
                        string texname = string.Format("Lightmap-{0}_comp_shadowmask", slicer.Key);
                        //string texname = string.Format("TestFinalShadowMask_{0}", slicer.Key);

                        ToolUtility.SaveTexture(targettex, texname, selectpath);
                    }
                }

                foreach (var slicer in slicers)
                {
                    string texname = string.Format("Lightmap-{0}_comp_shadowmask.png", slicer.Key);
                    var pathbase = selectpath.Replace(Application.dataPath, "Assets");
                    Debug.Log(pathbase);
                    //var tex = AssetDatabase.LoadAssetAtPath<Texture2D>(path);

                    string path = string.Format("{0}/{1}", pathbase, texname);
                    Debug.Log(path);

                    var textureImport = AssetImporter.GetAtPath(path) as TextureImporter;

                    if (textureImport != null)
                    {
                        textureImport.sRGBTexture = false;
                        textureImport.textureType = TextureImporterType.Shadowmask;
                    }
                }

                AssetDatabase.Refresh();
            }



        }

        void ProcessPass1()
        {
            Debug.Log("finish pass1");

            Lightmapping.bakeCompleted -= ProcessPass1;

            EditorCoroutineRunner.StartEditorCoroutine(WaitToPass1());

            //var lightingDataAsset = Lightmapping.lightingDataAsset;
            //if (lightingDataAsset == null)
            //{
            //    Debug.LogError("lightingDataAsset null");
            //    return;
            //}
            //slicersPass1.Clear();
            //lightingDataPass1 = LightingData.CreateFromAsset(lightingDataAsset);
            //SliceShadowMask(lightingDataPass1, slicersPass1);

            //foreach (var slicer in slicersPass1)
            //{
            //    slicer.Value.Convert2Sdf(high2LowScale, insideValue, outsideValue, inputChannel, outputChannel, outputFormat);
            //}
            //////test debug
            ////foreach (var slicer in slicersPass1)
            ////{
            ////    slicer.Value.SaveSdfTex(outputPath, slicer.Key);
            ////}
            ////foreach (var slicer in slicersPass1)
            ////{
            ////    slicer.Value.Combine(0, outputFormat, out Texture2D targettex);
            ////    if (targettex != null)
            ////    {
            ////        string texname = string.Format("TestShadowMask_Slice_Pass1_{0}", slicer.Key);
            ////        ToolUtility.SaveTexture(targettex, texname, outputPath);
            ////    }
            ////}
            ////end
            //Lightmapping.bakeCompleted -= ProcessPass1;

            //Lightmapping.lightingSettings.mixedBakeMode = MixedLightingMode.Shadowmask;
            //Lightmapping.lightingSettings.lightmapResolution = outputQualitySetting.lightmapResolution;
            //Lightmapping.lightingSettings.lightmapMaxSize = outputQualitySetting.lightmapMaxSize;
            //Lightmapping.lightingSettings.lightmapPadding = outputQualitySetting.padding;

            //if (Lightmapping.BakeAsync())
            //{
            //    Lightmapping.bakeCompleted += ProcessPass2;
            //}
        }

        void ProcessPass2()
        {
            Debug.Log("finish pass2");
            Lightmapping.bakeCompleted -= ProcessPass2;

            EditorCoroutineRunner.StartEditorCoroutine(WaitToPass2());
            //var lightingDataAsset2 = Lightmapping.lightingDataAsset;
            //if (lightingDataAsset2 == null)
            //{
            //    Debug.LogError("Pass2 lightingDataAsset null");
            //    return;
            //}
            //slicersPass2.Clear();
            //lightingDataPass2 = LightingData.CreateFromAsset(lightingDataAsset2);
            //SliceShadowMask(lightingDataPass2, slicersPass2);

            //CopySdfTextures(slicersPass1, slicersPass2);

            ////test debug
            //foreach (var slicer in slicersPass1)
            //{
            //    slicer.Value.SaveSdfTex(outputPath, 2);
            //}
            ////foreach (var slicer in slicersPass2)
            ////{
            ////    slicer.Value.Combine(0, outputFormat, out Texture2D targettex);
            ////    if (targettex != null)
            ////    {
            ////        string texname = string.Format("TestShadowMask_Slice_Pass2_{0}", slicer.Key);
            ////        ToolUtility.SaveTexture(targettex, texname, outputPath);
            ////    }
            ////}
            ////end

            //SaveShadowMask(outputPath, slicersPass2, outputFormat);

            //Debug.Log("finish bake");
        }

        IEnumerator WaitToPass1()
        {
            yield return new WaitForSeconds(120);

            var lightingDataAsset = Lightmapping.lightingDataAsset;
            if (lightingDataAsset == null)
            {
                Debug.LogError("lightingDataAsset null");
                //return;
            }
            slicersPass1.Clear();
            lightingDataPass1 = LightingData.CreateFromAsset(lightingDataAsset);
            SliceShadowMask(lightingDataPass1, slicersPass1);

            foreach (var slicer in slicersPass1)
            {
                slicer.Value.Convert2Sdf(high2LowScale, insideValue, outsideValue, inputChannel, outputChannel, outputFormat);
            }
            //test debug
            foreach (var slicer in slicersPass1)
            {
                slicer.Value.SaveSdfTex(outputPath, slicer.Key);
            }
            //foreach (var slicer in slicersPass1)
            //{
            //    slicer.Value.Combine(0, outputFormat, out Texture2D targettex);
            //    if (targettex != null)
            //    {
            //        string texname = string.Format("TestShadowMask_Slice_Pass1_{0}", slicer.Key);
            //        ToolUtility.SaveTexture(targettex, texname, outputPath);
            //    }
            //}
            //end


            Lightmapping.lightingSettings.mixedBakeMode = MixedLightingMode.Shadowmask;
            Lightmapping.lightingSettings.lightmapResolution = outputQualitySetting.lightmapResolution;
            Lightmapping.lightingSettings.lightmapMaxSize = outputQualitySetting.lightmapMaxSize;
            Lightmapping.lightingSettings.lightmapPadding = outputQualitySetting.padding;

            if (Lightmapping.BakeAsync())
            {
                Lightmapping.bakeCompleted += ProcessPass2;
            }
        }

        IEnumerator WaitToPass2()
        {
            yield return new WaitForSeconds(120);

            var lightingDataAsset2 = Lightmapping.lightingDataAsset;
            if (lightingDataAsset2 == null)
            {
                Debug.LogError("Pass2 lightingDataAsset null");
                //return;
            }
            slicersPass2.Clear();
            lightingDataPass2 = LightingData.CreateFromAsset(lightingDataAsset2);
            SliceShadowMask(lightingDataPass2, slicersPass2);

            CopySdfTextures(slicersPass1, slicersPass2);

            //test debug
            foreach (var slicer in slicersPass1)
            {
                slicer.Value.SaveSdfTex(outputPath, 2);
            }
            //foreach (var slicer in slicersPass2)
            //{
            //    slicer.Value.Combine(0, outputFormat, out Texture2D targettex);
            //    if (targettex != null)
            //    {
            //        string texname = string.Format("TestShadowMask_Slice_Pass2_{0}", slicer.Key);
            //        ToolUtility.SaveTexture(targettex, texname, outputPath);
            //    }
            //}
            //end

            SaveShadowMask(outputPath, slicersPass2, outputFormat);

            Debug.Log("finish bake");
        }
    }
}


