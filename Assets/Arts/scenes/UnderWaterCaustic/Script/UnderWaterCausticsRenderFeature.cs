using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Experimental.Rendering;

namespace UnityEngine.Rendering.Universal
{
    
    public class UnderWaterCausticsRenderFeature : ScriptableRendererFeature
    {
        [System.Serializable]
        public class Settings
        {
            public Material causticMat;
        }
        
        UnderWaterCausticsRenderPass m_ScriptablePass;
        public Settings passSettings = new Settings();
        /// <inheritdoc/>
        public override void Create()
        {
            m_ScriptablePass = new UnderWaterCausticsRenderPass(passSettings);
            // Configures where the render pass should be injected.
            m_ScriptablePass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        }

        // Here you can inject one or multiple render passes in the renderer.
        // This method is called when setting up the renderer once per-camera.
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            renderer.EnqueuePass(m_ScriptablePass);
        }

        /// <inheritdoc/>
        protected override void Dispose(bool disposing)
        {
            m_ScriptablePass?.Dispose();
            m_ScriptablePass = null;
        }
        
        
        class UnderWaterCausticsRenderPass : ScriptableRenderPass
        {
            private RenderTargetIdentifier source { get; set; }
            // Profiling tag
            private static string m_ProfilerTag = "UnderWaterCaustic";
            private static ProfilingSampler m_ProfilingSampler = new ProfilingSampler(m_ProfilerTag);

            // Private Variables
            private Material m_Material;
            //private ScreenSpaceShadowsSettings m_CurrentSettings;
            private RTHandle m_RenderTarget;
            private Settings m_Settings;
            public UnderWaterCausticsRenderPass(Settings settings)
            {
                m_Settings = settings;
                m_Material = settings.causticMat;
            }

            public void Dispose()
            {
                m_RenderTarget?.Release();
            }

            // This method is called before executing the render pass.
            // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
            // When empty this render pass will render to the active camera render target.
            // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
            // The render pipeline will ensure target setup and clearing happens in a performant manner.
            public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
            {
                
                // var descriptor = new RenderTextureDescriptor(renderingData.cameraData.cameraTargetDescriptor.width, renderingData.cameraData.cameraTargetDescriptor.height);
                // descriptor.graphicsFormat = renderingData.cameraData.cameraTargetDescriptor.graphicsFormat;
                // descriptor.useMipMap = false;
                // RenderingUtils.ReAllocateIfNeeded(ref m_RenderTarget, descriptor, FilterMode.Point, TextureWrapMode.Clamp,
                //     name: "_UnderWaterCausticTex");
                // //cmd.SetGlobalTexture(m_RenderTarget.name, m_RenderTarget.nameID);
                //
                // //ConfigureTarget(renderingData.cameraData.renderer.cameraColorTargetHandle);
                // ConfigureTarget(m_RenderTarget);
                // ConfigureClear(ClearFlag.None, Color.white);
            }

            // Here you can implement the rendering logic.
            // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
            // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
            // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                var stack = VolumeManager.instance.stack;
                if (m_Material == null)
                {
                    Debug.LogErrorFormat(
                        "{0}.Execute(): Missing material. CausticRenderPass will not execute. Check for missing reference in the renderer resources.",
                        GetType().Name);
                    return;
                }


                Camera camera = renderingData.cameraData.camera;
                
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
        }
    }
}


