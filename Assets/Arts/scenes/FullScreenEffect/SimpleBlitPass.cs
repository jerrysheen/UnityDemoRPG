using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class SimpleBlitPass : ScriptableRendererFeature
{
    class CustomRenderPass : ScriptableRenderPass
    {
        
        public Material blitMaterial;
        private static string m_ProfilerTag = "Simple Blit";
        private static ProfilingSampler m_ProfilingSampler = new ProfilingSampler(m_ProfilerTag);
        private RTHandle m_RenderTarget;
        private Material m_Material;
        private Settings m_Settings;

        private RenderTargetIdentifier source { get; set; }

        public CustomRenderPass(Settings settings)
        {
            m_Settings = settings;
            m_Material = settings.blitMat;
        }

        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                var descriptor = new RenderTextureDescriptor(renderingData.cameraData.cameraTargetDescriptor.width, renderingData.cameraData.cameraTargetDescriptor.height);
                descriptor.graphicsFormat = renderingData.cameraData.cameraTargetDescriptor.graphicsFormat;
                descriptor.useMipMap = false;
                RenderingUtils.ReAllocateIfNeeded(ref m_RenderTarget, descriptor, FilterMode.Point, TextureWrapMode.Clamp,
                    name: "_UnderWaterCausticTex");
                source = renderingData.cameraData.renderer.cameraColorTargetHandle;
                cmd.Blit(source, m_RenderTarget, m_Material, 0);
                cmd.Blit(m_RenderTarget, source);
            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
        
        public void Dispose()
        {
            m_RenderTarget?.Release();
        }
    }

    CustomRenderPass m_ScriptablePass;
    [System.Serializable]
    public class Settings
    {
        public Material blitMat;
        public RenderPassEvent passEvent;
    }
    public Settings passSettings = new Settings();

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass(passSettings);
        
        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = passSettings.passEvent;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
    
    protected override void Dispose(bool disposing)
    {
        m_ScriptablePass?.Dispose();
        m_ScriptablePass = null;
    }
}


