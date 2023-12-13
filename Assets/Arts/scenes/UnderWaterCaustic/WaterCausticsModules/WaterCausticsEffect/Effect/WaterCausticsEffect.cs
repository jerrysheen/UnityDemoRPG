// WaterCausticsModules
// Copyright (c) 2021 Masataka Hakozaki

using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.XR;

#if UNITY_EDITOR
using UnityEditor;
#endif


namespace MH.WaterCausticsModules {
    [ExecuteAlways]
    [DisallowMultipleComponent]
    [AddComponentMenu ("WaterCausticsModules/WaterCausticsEffect")]
    public class WaterCausticsEffect : MonoBehaviour {
        // ----------------------------------------------------------- SerializeField
        [SerializeField] private LayerMask m_layerMask = ~0;
        [SerializeField] private bool m_clipOutsideVolume = true;
        [SerializeField] private bool m_useImageMask = false;
        [SerializeField] private Texture m_imageMaskTexture;

        [SerializeField] private Texture m_texture;

        [SerializeField, Min (0.0001f)] private float m_scale = 1f;
        [SerializeField] private float m_waterSurfaceY = 2f;
        [SerializeField] private float m_waterSurfaceAttenOffset = 0f;
        [SerializeField, Min (0f)] private float m_waterSurfaceAttenWide = 0.5f;

        [SerializeField, Range (0f, 6f)] private float m_intensity = 1f;
        [SerializeField, Range (0f, 6f)] private float m_adjustMainLit = 1f;
        [SerializeField, Range (0f, 6f)] private float m_adjustAddLit = 1f;
        [SerializeField, Range (-3f, 3f)] float m_colorShiftU = 0.4f;
        [SerializeField, Range (-3f, 3f)] float m_colorShiftV = -0.1f;
        [SerializeField, Range (0f, 2f)] private float m_litSaturation = 0.2f;
        [SerializeField] private bool m_multiplyOpaqueColor = true;
        [SerializeField, Range (0f, 1f)] private float m_multiplyOpaqueIntensity = 0.75f;
        [SerializeField, Range (1f, 8f)] private float m_normalAttenPower = 2f;
        [SerializeField, Range (0f, 1f)] private float m_normalAttenIntensity = 1f;
        [SerializeField, Range (0f, 1f)] private float m_transparentBackside = 0f;


        [SerializeField] private bool m_receiveShadows = true;
        [SerializeField] private bool m_useMainLight = true;
        [SerializeField] private bool m_useAdditionalLights = true;

        [SerializeField] private bool m_syncWithShaderFunctions = true;

        [SerializeField, Range (0, 255)] private int m_stencilRef = 0;
        [SerializeField, Range (0, 255)] private int m_stencilReadMask = 255;
        [SerializeField, Range (0, 255)] private int m_stencilWriteMask = 255;
        [SerializeField] private CompareFunction m_stencilComp = CompareFunction.Always;
        [SerializeField] private StencilOp m_stencilPass = StencilOp.Keep;
        [SerializeField] private StencilOp m_stencilFail = StencilOp.Keep;
        [SerializeField] private StencilOp m_stencilZFail = StencilOp.Keep;
        [SerializeField] private CullMode m_cullMode = CullMode.Back;
        [SerializeField] private bool m_zWriteMode = false;
        [SerializeField] private CompareFunction m_zTestMode = CompareFunction.Equal;
        [SerializeField] private float m_depthOffsetFactor = 0;
        [SerializeField] private float m_depthOffsetUnits = 0;


        [SerializeField] private Shader m_shader;
        [SerializeField] private Texture m_noTexture;


        // ----------------------------------------------------------- Public property


        public LayerMask layerMask {
            get => m_layerMask;
            set {
                m_layerMask = value;
                isDirty = true;
            }
        }
        public bool clipOutsideVolume {
            get => m_clipOutsideVolume;
            set {
                m_clipOutsideVolume = value;
                isDirty = true;
            }
        }

        public Texture texture {
            get => m_texture;
            set {
                m_texture = value;
                isDirty = true;
            }
        }
        public float intensity {
            get => m_intensity;
            set {
                m_intensity = Mathf.Max (0f, value);
                isDirty = true;
            }
        }
        public float adjustMainLight {
            get => m_adjustMainLit;
            set {
                m_adjustMainLit = Mathf.Max (0f, value);
                isDirty = true;
            }
        }
        public float adjustAdditionalLights {
            get => m_adjustAddLit;
            set {
                m_adjustAddLit = Mathf.Max (0f, value);
                isDirty = true;
            }
        }

        public float scale {
            get => m_scale;
            set {
                m_scale = Mathf.Max (0.0001f, value);
                isDirty = true;
            }
        }
        public float colorShiftU {
            get => m_colorShiftU;
            set {
                m_colorShiftU = value;
                isDirty = true;
            }
        }
        public float colorShiftV {
            get => m_colorShiftV;
            set {
                m_colorShiftV = value;
                isDirty = true;
            }
        }
        public float waterSurfaceY {
            get => m_waterSurfaceY;
            set {
                m_waterSurfaceY = value;
                isDirty = true;
            }
        }
        public float waterSurfaceAttenOffset {
            get => m_waterSurfaceAttenOffset;
            set {
                m_waterSurfaceAttenOffset = value;
                isDirty = true;
            }
        }
        public float waterSurfaceAttenWide {
            get => m_waterSurfaceAttenWide;
            set {
                m_waterSurfaceAttenWide = Mathf.Max (0f, value);
                isDirty = true;
            }
        }
        public float lightSaturation {
            get => m_litSaturation;
            set {
                m_litSaturation = Mathf.Max (0f, value);
                isDirty = true;
            }
        }

        public bool receiveShadows {
            get => m_receiveShadows;
            set {
                m_receiveShadows = value;
                isDirty = true;
            }
        }
        public bool useMainLight {
            get => m_useMainLight;
            set {
                m_useMainLight = value;
                isDirty = true;
            }
        }
        public bool useAdditionalLights {
            get => m_useAdditionalLights;
            set {
                m_useAdditionalLights = value;
                isDirty = true;
            }
        }
        public bool multiplyOpaqueColor {
            get => m_multiplyOpaqueColor;
            set {
                m_multiplyOpaqueColor = value;
                isDirty = true;
            }
        }
        public float multiplyOpaqueColorIntensity {
            get => m_multiplyOpaqueIntensity;
            set {
                m_multiplyOpaqueIntensity = Mathf.Clamp (value, 0f, 1f);
                isDirty = true;
            }
        }
        public float normalAttenPower {
            get => m_normalAttenPower;
            set {
                m_normalAttenPower = Mathf.Clamp (value, 1f, 8f);
                isDirty = true;
            }
        }
        public float normalAttenIntensity {
            get => m_normalAttenIntensity;
            set {
                m_normalAttenIntensity = Mathf.Clamp (value, 0f, 1f);
                isDirty = true;
            }
        }
        public float transparentBackside {
            get => m_transparentBackside;
            set {
                m_transparentBackside = Mathf.Clamp (value, 0f, 1f);
                isDirty = true;
            }
        }
        public int stencilRef {
            get => m_stencilRef;
            set {
                m_stencilRef = Mathf.Clamp (value, 0, 255);
                isDirty = true;
            }
        }
        public int stencilReadMask {
            get => m_stencilReadMask;
            set {
                m_stencilReadMask = Mathf.Clamp (value, 0, 255);
                isDirty = true;
            }
        }
        public int stencilWriteMask {
            get => m_stencilWriteMask;
            set {
                m_stencilWriteMask = Mathf.Clamp (value, 0, 255);
                isDirty = true;
            }
        }
        public CompareFunction stencilComp {
            get => m_stencilComp;
            set {
                m_stencilComp = value;
                isDirty = true;
            }
        }

        public StencilOp stencilPass {
            get => m_stencilPass;
            set {
                m_stencilPass = value;
                isDirty = true;
            }
        }
        public StencilOp stencilFail {
            get => m_stencilFail;
            set {
                m_stencilFail = value;
                isDirty = true;
            }
        }
        public StencilOp stencilZFail {
            get => m_stencilZFail;
            set {
                m_stencilZFail = value;
                isDirty = true;
            }
        }
        public CullMode cullMode {
            get => m_cullMode;
            set {
                m_cullMode = value;
                isDirty = true;
            }
        }
        public bool zWriteMode {
            get => m_zWriteMode;
            set {
                m_zWriteMode = value;
                isDirty = true;
            }
        }
        public CompareFunction zTestMode {
            get => m_zTestMode;
            set {
                m_zTestMode = value;
                isDirty = true;
            }
        }
        public float depthOffsetFactor {
            get => m_depthOffsetFactor;
            set {
                m_depthOffsetFactor = value;
                isDirty = true;
            }
        }
        public float depthOffsetUnits {
            get => m_depthOffsetUnits;
            set {
                m_depthOffsetUnits = value;
                isDirty = true;
            }
        }
        public bool useImageMask {
            get => m_useImageMask;
            set {
                m_useImageMask = value;
                isDirty = true;
            }
        }
        public Texture imageMaskTexture {
            get => m_imageMaskTexture;
            set {
                m_imageMaskTexture = value;
                isDirty = true;
            }
        }

        public bool syncWithShaderFunctions {
            get => m_syncWithShaderFunctions;
            set => m_syncWithShaderFunctions = value;
        }

        public void ForceApplyChanges () {
#if UNITY_EDITOR
            if (!isActiveAndEnabled) return;
#endif
            isDirty = false;
            updateValues ();
        }


        // ----------------------------------------------------------- Editor

#if UNITY_EDITOR
        public void OnInspectorChanged () {
            if (isActiveAndEnabled)
                updateValues ();
        }

        private void onUndoCallback () {
            if (isActiveAndEnabled)
                updateValues ();
        }
#endif


        // ----------------------------------------------------------- Resset
        protected void reorderComponentBefore<T> () {
#if UNITY_EDITOR
            var components = GetComponents<Component> ().ToList ();
            int thisIdx = components.IndexOf (this);
            int targetIdx = components.FindIndex (a => a is T);
            if (targetIdx != -1 && thisIdx > targetIdx)
                for (int i = 0; i < thisIdx - targetIdx; i++)
                    UnityEditorInternal.ComponentUtility.MoveComponentUp (this);
#endif
        }

        private void Reset () {
            m_scale = Mathf.Max (transform.lossyScale.x, transform.lossyScale.z);
            isDirty = true;
        }


        // ----------------------------------------------------------- 

        private void OnEnable () {
#if UNITY_EDITOR
            Undo.undoRedoPerformed += onUndoCallback;
#endif
            onEnable_EnqueuePass ();
            matUniquenessCheck ();
            isDirty = true;
        }

        private void OnDisable () {
#if UNITY_EDITOR
            Undo.undoRedoPerformed -= onUndoCallback;
#endif
            onDisable_EnqueuePass ();
        }

        private void OnDestroy () {
            removeFromMatDic ();
            destroy (ref m__material);
        }

        private void destroy<T> (ref T o) where T : Object {
            if (o == null) return;
            if (Application.isPlaying)
                Destroy (o);
            else
                DestroyImmediate (o);
            o = null;
        }


        // ----------------------------------------------------------- Update
        private bool isDirty;

        private void Update () {
            if (isDirty || (_pass != null && _pass.layerMask != m_layerMask)) {
                // Inspector拡張でLayerMaskの変更が検知出来ないため↑のチェックが必要
                if (Application.isPlaying)
                    isDirty = false;
                updateValues ();
            }
        }

        private void updateValues () {
            prepRenderPass ();
            prepMaterials ();
        }

        private void LateUpdate () {
            if (m_syncWithShaderFunctions)
                setShaderGlobalValue ();
        }


        // ----------------------------------------------------------- Property ID
        private class pID {
            readonly public static int _WCE_CausticsTex = Shader.PropertyToID ("_WCE_CausticsTex");
            readonly public static int _WCE_IntensityMainLit = Shader.PropertyToID ("_WCE_IntensityMainLit");
            readonly public static int _WCE_IntensityAddLit = Shader.PropertyToID ("_WCE_IntensityAddLit");
            readonly public static int _WCE_Scale = Shader.PropertyToID ("_WCE_Scale");
            readonly public static int _WCE_ColorShift = Shader.PropertyToID ("_WCE_ColorShift");
            readonly public static int _WCE_WaterSurfaceY = Shader.PropertyToID ("_WCE_WaterSurfaceY");
            readonly public static int _WCE_WaterSurfaceAttenOffset = Shader.PropertyToID ("_WCE_WaterSurfaceAttenOffset");
            readonly public static int _WCE_WaterSurfaceAttenWide = Shader.PropertyToID ("_WCE_WaterSurfaceAttenWide");
            readonly public static int _WCE_LitSaturation = Shader.PropertyToID ("_WCE_LitSaturation");
            readonly public static int _WCE_MulOpaqueIntensity = Shader.PropertyToID ("_WCE_MulOpaqueIntensity");
            readonly public static int _WCE_NormalAttenPower = Shader.PropertyToID ("_WCE_NormalAttenPower");
            readonly public static int _WCE_NormalAttenIntensity = Shader.PropertyToID ("_WCE_NormalAttenIntensity");
            readonly public static int _WCE_TransparentBackside = Shader.PropertyToID ("_WCE_TransparentBackside");
            readonly public static int _WCE_ImageMaskTex = Shader.PropertyToID ("_WCE_ImageMaskTex");
            readonly public static int _WCE_WldObjMatrixOfVolume = Shader.PropertyToID ("_WCE_WldObjMatrixOfVolume");
            readonly public static int _WCE_ClipOutsideVolume = Shader.PropertyToID ("_WCE_ClipOutsideVolume");
            readonly public static int _WCE_UseImageMask = Shader.PropertyToID ("_WCE_UseImageMask");

            readonly public static int _StencilRef = Shader.PropertyToID ("_StencilRef");
            readonly public static int _StencilReadMask = Shader.PropertyToID ("_StencilReadMask");
            readonly public static int _StencilWriteMask = Shader.PropertyToID ("_StencilWriteMask");
            readonly public static int _StencilComp = Shader.PropertyToID ("_StencilComp");
            readonly public static int _StencilPass = Shader.PropertyToID ("_StencilPass");
            readonly public static int _StencilFail = Shader.PropertyToID ("_StencilFail");
            readonly public static int _StencilZFail = Shader.PropertyToID ("_StencilZFail");
            readonly public static int _CullMode = Shader.PropertyToID ("_CullMode");
            readonly public static int _ZWrite = Shader.PropertyToID ("_ZWrite");
            readonly public static int _ZTest = Shader.PropertyToID ("_ZTest");
            readonly public static int _OffsetFactor = Shader.PropertyToID ("_OffsetFactor");
            readonly public static int _OffsetUnits = Shader.PropertyToID ("_OffsetUnits");

            readonly public static int _WCECF_IntensityMainLit = Shader.PropertyToID ("_WCECF_IntensityMainLit");
            readonly public static int _WCECF_Scale = Shader.PropertyToID ("_WCECF_Scale");
            readonly public static int _WCECF_ColorShift = Shader.PropertyToID ("_WCECF_ColorShift");
            readonly public static int _WCECF_WaterSurfaceY = Shader.PropertyToID ("_WCECF_WaterSurfaceY");
            readonly public static int _WCECF_WaterSurfaceAttenOffset = Shader.PropertyToID ("_WCECF_WaterSurfaceAttenOffset");
            readonly public static int _WCECF_WaterSurfaceAttenWide = Shader.PropertyToID ("_WCECF_WaterSurfaceAttenWide");
            readonly public static int _WCECF_LitSaturation = Shader.PropertyToID ("_WCECF_LitSaturation");
            readonly public static int _WCECF_IntensityAddLit = Shader.PropertyToID ("_WCECF_IntensityAddLit");
            readonly public static int _WCECF_MulOpaqueIntensity = Shader.PropertyToID ("_WCECF_MulOpaqueIntensity");
            readonly public static int _WCECF_NormalAttenPower = Shader.PropertyToID ("_WCECF_NormalAttenPower");
            readonly public static int _WCECF_NormalAttenIntensity = Shader.PropertyToID ("_WCECF_NormalAttenIntensity");
            readonly public static int _WCECF_TransparentBackside = Shader.PropertyToID ("_WCECF_TransparentBackside");
            readonly public static int _WCECF_WldObjMatrixOfVolume = Shader.PropertyToID ("_WCECF_WldObjMatrixOfVolume");
            readonly public static int _WCECF_ClipOutsideVolume = Shader.PropertyToID ("_WCECF_ClipOutsideVolume");
            readonly public static int _WCECF_UseImageMask = Shader.PropertyToID ("_WCECF_UseImageMask");
            readonly public static int _WCECF_CausticsTex = Shader.PropertyToID ("_WCECF_CausticsTex");
            readonly public static int _WCECF_ImageMaskTex = Shader.PropertyToID ("_WCECF_ImageMaskTex");
        }


        // ----------------------------------------------------------- Material Uniqueness
        static private Dictionary<Material, WaterCausticsEffect> s_matDic = new Dictionary<Material, WaterCausticsEffect> ();
        private void matUniquenessCheck () {
            if (m__material == null) return;
            if (s_matDic.ContainsKey (m__material)) {
                if (s_matDic [m__material] == null) {
                    s_matDic [m__material] = this;
                } else if (s_matDic [m__material] != this) {
                    m__material = null;
                }
            } else {
                s_matDic.Add (m__material, this);
            }
        }

        private void removeFromMatDic () {
            var removeTargetList = s_matDic.Where (x => x.Value == this).ToList ();
            foreach (var item in removeTargetList)
                s_matDic.Remove (item.Key);
            if (m__material != null)
                s_matDic.Remove (m__material);
        }


        // ----------------------------------------------------------- Material
        [SerializeField] private Material m__material;

        private Material getMat () {
            if (m__material == null) {
                m__material = makeMat (m_shader, "WCausticsEffect");
                matUniquenessCheck ();
            }
            return m__material;
        }

        private Material makeMat (Shader shader, string name) {
            if (shader == null) {
                Debug.LogError ("Shader is null. " + this);
                return null;
            } else {
                Material mat = new Material (shader);
                mat.name = name;
                mat.hideFlags = HideFlags.NotEditable;
                return mat;
            }
        }


        private void prepMaterials () {
            setMaterialValue (getMat ());
        }

        void setMaterialValue (Material mat) {
            if (mat != null) {
                bool isNoTex = (m_texture == null);
                mat.SetFloat (pID._WCE_Scale, isNoTex ? m_scale * 0.333f : m_scale);
                mat.SetTexture (pID._WCE_CausticsTex, isNoTex ? m_noTexture : m_texture);
                mat.SetFloat (pID._WCE_IntensityMainLit, m_intensity * m_adjustMainLit * (m_useMainLight ? 1f : 0f));
                mat.SetFloat (pID._WCE_IntensityAddLit, m_intensity * m_adjustAddLit * (m_useAdditionalLights ? 1f : 0f));
                mat.SetVector (pID._WCE_ColorShift, new Vector2 (m_colorShiftU, m_colorShiftV) * 0.01f);
                mat.SetFloat (pID._WCE_WaterSurfaceY, m_waterSurfaceY);
                mat.SetFloat (pID._WCE_WaterSurfaceAttenOffset, m_waterSurfaceAttenOffset);
                mat.SetFloat (pID._WCE_WaterSurfaceAttenWide, m_waterSurfaceAttenWide);
                mat.SetFloat (pID._WCE_LitSaturation, m_litSaturation);
                setMatKeyword (mat, !m_receiveShadows, "_RECEIVE_SHADOWS_OFF");
                float mulOpaque = m_multiplyOpaqueColor ? m_multiplyOpaqueIntensity : 0f;
                mat.SetFloat (pID._WCE_MulOpaqueIntensity, mulOpaque);
                mat.SetFloat (pID._WCE_NormalAttenPower, m_normalAttenPower);
                mat.SetFloat (pID._WCE_NormalAttenIntensity, m_normalAttenIntensity);
                mat.SetFloat (pID._WCE_TransparentBackside, m_transparentBackside);
                mat.SetInt (pID._WCE_ClipOutsideVolume, System.Convert.ToInt32 (m_clipOutsideVolume));
                bool useImgMask = (m_useImageMask && m_imageMaskTexture);
                mat.SetInt (pID._WCE_UseImageMask, System.Convert.ToInt32 (useImgMask));
                mat.SetTexture (pID._WCE_ImageMaskTex, useImgMask ? m_imageMaskTexture : null);

                mat.SetInt (pID._StencilRef, m_stencilRef);
                mat.SetInt (pID._StencilReadMask, m_stencilReadMask);
                mat.SetInt (pID._StencilWriteMask, m_stencilWriteMask);
                mat.SetInt (pID._StencilComp, (int) m_stencilComp);
                mat.SetInt (pID._StencilPass, (int) m_stencilPass);
                mat.SetInt (pID._StencilFail, (int) m_stencilFail);
                mat.SetInt (pID._StencilZFail, (int) m_stencilZFail);

                mat.SetInt (pID._CullMode, (int) m_cullMode);
                mat.SetInt (pID._ZWrite, System.Convert.ToInt32 (m_zWriteMode));
                mat.SetInt (pID._ZTest, (int) m_zTestMode);
                mat.SetFloat (pID._OffsetFactor, m_depthOffsetFactor);
                mat.SetFloat (pID._OffsetUnits, m_depthOffsetUnits);
            }
        }


        private void setMatKeyword (Material mat, bool isEnable, string keyword) {
            if (isEnable)
                mat.EnableKeyword (keyword);
            else
                mat.DisableKeyword (keyword);
        }


        // ----------------------------------------------------------- Sync with Custom Functions

        private void setShaderGlobalValue () {
            bool isNoTex = (m_texture == null);
            Shader.SetGlobalFloat (pID._WCECF_Scale, isNoTex ? m_scale * 0.333f : m_scale);
            Shader.SetGlobalFloat (pID._WCECF_WaterSurfaceY, m_waterSurfaceY);
            Shader.SetGlobalFloat (pID._WCECF_WaterSurfaceAttenOffset, m_waterSurfaceAttenOffset);
            Shader.SetGlobalFloat (pID._WCECF_WaterSurfaceAttenWide, m_waterSurfaceAttenWide);
            Shader.SetGlobalFloat (pID._WCECF_IntensityMainLit, m_intensity * m_adjustMainLit * (m_useMainLight ? 1f : 0f));
            Shader.SetGlobalFloat (pID._WCECF_IntensityAddLit, m_intensity * m_adjustAddLit * (m_useAdditionalLights ? 1f : 0f));
            Shader.SetGlobalVector (pID._WCECF_ColorShift, new Vector2 (m_colorShiftU, m_colorShiftV) * 0.01f);
            Shader.SetGlobalFloat (pID._WCECF_LitSaturation, m_litSaturation);
            float mulOpaque = m_multiplyOpaqueColor ? m_multiplyOpaqueIntensity : 0f;
            Shader.SetGlobalFloat (pID._WCECF_MulOpaqueIntensity, mulOpaque);
            Shader.SetGlobalFloat (pID._WCECF_NormalAttenPower, m_normalAttenPower);
            Shader.SetGlobalFloat (pID._WCECF_NormalAttenIntensity, m_normalAttenIntensity);
            Shader.SetGlobalFloat (pID._WCECF_TransparentBackside, m_transparentBackside);
            Shader.SetGlobalMatrix (pID._WCECF_WldObjMatrixOfVolume, transform.worldToLocalMatrix);
            Shader.SetGlobalInt (pID._WCECF_ClipOutsideVolume, System.Convert.ToInt32 (m_clipOutsideVolume));
            Shader.SetGlobalTexture (pID._WCECF_CausticsTex, isNoTex ? m_noTexture : m_texture);
            bool useImgMask = (m_useImageMask && m_imageMaskTexture);
            Shader.SetGlobalInt (pID._WCECF_UseImageMask, System.Convert.ToInt32 (useImgMask));
            Shader.SetGlobalTexture (pID._WCECF_ImageMaskTex, useImgMask ? m_imageMaskTexture : null);
        }

        // ----------------------------------------------------------- RenderPass

        private WCERenderPass _pass;

        private void prepRenderPass () {
            if (_pass == null) {
                _pass = new WCERenderPass (this, m_layerMask, getMat ());
            } else if (_pass.layerMask != m_layerMask) {
                _pass.layerMask = m_layerMask;
            }
            _pass.material = getMat ();
        }


        // ----------------------------------------------------------- Enqueue RenderPass
        // ※ MultiPass StereoRendering のとき 
        // ※ Lカメラでしか beginCameraRendering が呼ばれない問題への対策
        // ※ endCameraRendering はLRカメラで呼ばれるのでこちらでEnqueueする
        private bool isXRMultiPass => (XRSettings.enabled && XRSettings.stereoRenderingMode == XRSettings.StereoRenderingMode.MultiPass);
        private ScriptableRenderer _renderer;

        private void onEnable_EnqueuePass () {
            _renderer = null;
            RenderPipelineManager.beginCameraRendering -= beginCameraRendering;
            RenderPipelineManager.beginCameraRendering += beginCameraRendering;
            RenderPipelineManager.endCameraRendering -= endCameraRendering;
            RenderPipelineManager.endCameraRendering += endCameraRendering;
        }

        private void onDisable_EnqueuePass () {
            RenderPipelineManager.beginCameraRendering -= beginCameraRendering;
            RenderPipelineManager.endCameraRendering -= endCameraRendering;
        }

        void beginCameraRendering (ScriptableRenderContext context, Camera camera) {
            var asset = GraphicsSettings.currentRenderPipeline as UniversalRenderPipelineAsset;
            if (asset != null && (!isXRMultiPass || _renderer != asset.scriptableRenderer)) {
                _renderer = asset.scriptableRenderer;
                enqueuePass (camera);
            }
        }

        void endCameraRendering (ScriptableRenderContext context, Camera camera) {
            if (isXRMultiPass)
                enqueuePass (camera);
        }

        private void enqueuePass (Camera camera) {
#if UNITY_EDITOR
            if (camera.cameraType == CameraType.Preview) return;
#endif
            if (m_intensity > 0f && _renderer != null && _pass != null)
                _renderer.EnqueuePass (_pass);
        }


        // ----------------------------------------------------------- Gizmo
        private void OnDrawGizmosSelected () {
            Gizmos.color = new Color (0.7f, 0.3f, 0.0f, 1f);
            var tmp = Gizmos.matrix;
            Gizmos.matrix = transform.localToWorldMatrix;
            Gizmos.DrawWireCube (Vector3.zero, Vector3.one);
            Gizmos.matrix = tmp;
        }

        // ----------------------------------------------------------- 
    }


    internal class WCERenderPass : ScriptableRenderPass {
        private WaterCausticsEffect _summoner;
        private FilteringSettings _filteringSettings;
        private ProfilingSampler _profilingSampler;
        public Material material { get; set; }

        private LayerMask __layerMask = -2;
        public LayerMask layerMask {
            get => __layerMask;
            set {
                if (__layerMask != value) {
                    __layerMask = value;
                    _filteringSettings = new FilteringSettings (RenderQueueRange.opaque, value);
                }
            }
        }

        private List<ShaderTagId> _shaderTagIdList = new List<ShaderTagId> ();


        public WCERenderPass (WaterCausticsEffect summoner, int layerMask, Material mat) {
            _summoner = summoner;
            base.profilingSampler = new ProfilingSampler (nameof (WCERenderPass));
            _profilingSampler = new ProfilingSampler (nameof (WCERenderPass));
            this.renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
            this.material = mat;
            this.layerMask = layerMask;
            _shaderTagIdList.Add (new ShaderTagId ("SRPDefaultUnlit"));
            _shaderTagIdList.Add (new ShaderTagId ("UniversalForward"));
            _shaderTagIdList.Add (new ShaderTagId ("UniversalForwardOnly"));
        }

        readonly Vector3 [] points = new Vector3 [] {
            new Vector3 (-0.5f, -0.5f, -0.5f),
            new Vector3 (0.5f, -0.5f, -0.5f),
            new Vector3 (-0.5f, 0.5f, -0.5f),
            new Vector3 (0.5f, 0.5f, -0.5f),
            new Vector3 (-0.5f, -0.5f, 0.5f),
            new Vector3 (0.5f, -0.5f, 0.5f),
            new Vector3 (-0.5f, 0.5f, 0.5f),
            new Vector3 (0.5f, 0.5f, 0.5f),
        };

        readonly public static int _WCE_WldObjMatrixOfVolume = Shader.PropertyToID ("_WCE_WldObjMatrixOfVolume");
        private Plane [] planes = new Plane [6];
        public override void Execute (ScriptableRenderContext context, ref RenderingData renderingData) {
            if (material == null) return;
            if (_summoner.clipOutsideVolume || (_summoner.useImageMask && _summoner.imageMaskTexture)) {
                if (_summoner.clipOutsideVolume) {
                    Bounds bounds = GeometryUtility.CalculateBounds (points, _summoner.transform.localToWorldMatrix);
                    GeometryUtility.CalculateFrustumPlanes (renderingData.cameraData.camera, planes);
                    bool isInsideView = GeometryUtility.TestPlanesAABB (planes, bounds);
                    if (!isInsideView) return;
                }
                material.SetMatrix (_WCE_WldObjMatrixOfVolume, _summoner.transform.worldToLocalMatrix);
            }

            SortingCriteria sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;
            DrawingSettings drawingSettings = CreateDrawingSettings (_shaderTagIdList, ref renderingData, sortingCriteria);
            drawingSettings.overrideMaterial = material;
            drawingSettings.overrideMaterialPassIndex = 0;

            CommandBuffer cmd = CommandBufferPool.Get ();
            using (new ProfilingScope (cmd, _profilingSampler)) {
                context.ExecuteCommandBuffer (cmd);
                cmd.Clear ();
                context.DrawRenderers (renderingData.cullResults, ref drawingSettings, ref _filteringSettings);
            }
            context.ExecuteCommandBuffer (cmd);
            CommandBufferPool.Release (cmd);
        }

    }
}
