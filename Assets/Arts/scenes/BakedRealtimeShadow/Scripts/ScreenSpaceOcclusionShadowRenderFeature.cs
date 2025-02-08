using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ScreenSpaceOcclusionShadowRenderFeature : ScriptableRendererFeature
{
    class ScreenSpaceOcclusionShadowRenderPass : ScriptableRenderPass
    {
        private static string m_ProfilerTag = "ScreenSpaceOcclusionShadowRenderFeature";
        private static int m_ScreenSpaceOcclusionShadowMapID = Shader.PropertyToID("_ScreenSpaceOcclusionShadowMap");
        private static ShaderTagId m_ShaderTag = new ShaderTagId("ScreenSpaceOcclusionCaster");
        private static ProfilingSampler m_ProfilingSampler = new ProfilingSampler(m_ProfilerTag);
        private RTHandle m_ScreenSpaceOcclusionShadowMap;
        private FilteringSettings m_FilteringSettings;
        
        private int shadowmapBufferBits = 0;
        private int renderTargetWidth;
        private int renderTargetHeight;
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            renderTargetWidth = (int)(renderingData.cameraData.cameraTargetDescriptor.width * m_PassSettings.renderScale);
            renderTargetHeight = (int)(renderingData.cameraData.cameraTargetDescriptor.height * m_PassSettings.renderScale);
            
            
            ShadowRTReAllocateIfNeeded(ref m_ScreenSpaceOcclusionShadowMap, renderTargetWidth, renderTargetHeight, shadowmapBufferBits, name: "_ScreenSpaceOcclusionShadowMap");
            ConfigureTarget(m_ScreenSpaceOcclusionShadowMap);
            ConfigureClear(ClearFlag.All, Color.white);
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
                var cam = renderingData.cameraData.camera;
                cmd.SetViewport(new Rect(0.0f, 0.0f, renderTargetWidth, renderTargetHeight));
                cmd.SetViewProjectionMatrices(cam.worldToCameraMatrix, cam.projectionMatrix);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                // todo： 这个地方看起来不太对。。
                var drawingSettings = CreateDrawingSettings(m_ShaderTag, ref renderingData,
                    renderingData.cameraData.defaultOpaqueSortFlags);
                m_FilteringSettings.layerMask = -1;
                m_FilteringSettings.renderQueueRange = RenderQueueRange.opaque;
                var cullResults = renderingData.cullResults;
                context.DrawRenderers(cullResults, ref drawingSettings, ref m_FilteringSettings);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                
                // upload
                cmd.SetGlobalTexture(m_ScreenSpaceOcclusionShadowMapID, m_ScreenSpaceOcclusionShadowMap.nameID);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
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
            m_ScreenSpaceOcclusionShadowMap?.Release();
        }
        
        
        public bool ShadowRTReAllocateIfNeeded(ref RTHandle handle, int width, int height, int bits, int anisoLevel = 1, float mipMapBias = 0, string name = "")
        {
            if (ShadowUtils.ShadowRTNeedsReAlloc(handle, width, height, bits, anisoLevel, mipMapBias, name))
            {
                handle?.Release();
                RenderTextureDescriptor rtd = new RenderTextureDescriptor(width, height, RenderTextureFormat.R8, 0);
                handle = RTHandles.Alloc(rtd, FilterMode.Bilinear, TextureWrapMode.Clamp, isShadowMap: false, name: name);
                return true;
            }
            return false;
        }

        private ScreenSpaceOcclusionShadowRenderFeature.Settings m_PassSettings;

        public ScreenSpaceOcclusionShadowRenderPass(ScreenSpaceOcclusionShadowRenderFeature.Settings passSettings)
        {
            RenderQueueRange desiredRenderQueueRange = RenderQueueRange.transparent;
            m_FilteringSettings = new FilteringSettings(desiredRenderQueueRange);
            m_PassSettings = passSettings;
        }
    }

    private ScreenSpaceOcclusionShadowRenderPass m_ScriptablePass;

    public Settings passSettings = new Settings();

    [System.Serializable]
    public class Settings
    {
        public float renderScale = 0.5f;
    }

    
    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new ScreenSpaceOcclusionShadowRenderPass(passSettings);

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        m_ScriptablePass.Dispose();
    }
}


