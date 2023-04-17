using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[System.Serializable]
[VolumeComponentMenuForRenderPipeline("Custom/VolumetricCloud", typeof(UniversalRenderPipeline))]
public class PostProcessingSettings: VolumeComponent, IPostProcessComponent{

    [Tooltip("Base Color")]
    public ColorParameter baseColor = new ColorParameter(new Color(1, 1, 1, 1));

    public bool IsActive() => true;
    public bool IsTileCompatible() => false;
    public void load(Material material, ref RenderingData data){
        /* 将所有的参数载入目标材质 */

        material.SetColor("_BaseColor", baseColor.value);
    }
}