// WaterCausticsModules
// Copyright (c) 2021 Masataka Hakozaki

using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

#if UNITY_2020_1_OR_NEWER
namespace MH.WaterCausticsModules {
    public class CheckRenderPipeline : AssetPostprocessor {

        static void OnPostprocessAllAssets (string [] a, string [] b, string [] c, string [] d) {
            if (GraphicsSettings.currentRenderPipeline == null ||
                !GraphicsSettings.currentRenderPipeline.GetType ().ToString ().Contains ("UniversalRenderPipelineAsset")) {
                Debug.LogError ("WaterCausticsTexGenerator is compatible with all render pipelines, but WaterCausticsEffect is compatible with the Universal Render Pipeline only.\nPlease delete \"Assets/WaterCausticsModules/WaterCausticsEffect\" folder.\n");
            }
        }

    }
}
#endif
