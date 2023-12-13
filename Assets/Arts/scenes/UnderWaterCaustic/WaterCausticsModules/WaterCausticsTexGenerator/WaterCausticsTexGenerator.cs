// WaterCausticsModules
// Copyright (c) 2021 Masataka Hakozaki

using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace MH.WaterCausticsModules {

    [ExecuteAlways]
    [AddComponentMenu ("WaterCausticsModules/WaterCausticsTexGenerator")]
    public class WaterCausticsTexGenerator : MonoBehaviour {

        // ----------------------------------------------------------- Constant
        public const int THREAD_SIZE = 16;
        public const int WAVE_MAX_CNT = 4;

        public enum LitDirTypeEnum {
            Numeric,
            Transform,
            LitSettingSun,
            Auto,
        }

        public enum CalcResEnum {
            x64 = 64,
            x96 = 96,
            x128 = 128,
            x160 = 160,
            x256 = 256,
            x320 = 320,
            x512 = 512,
        }

        public enum LitCondensStyleEnum {
            StyleA,
            StyleB,
            StyleC,
        }

        readonly string [] _lcStyleStr = {
            "STYLE_A",
            "STYLE_B",
            "STYLE_C",
        };

        readonly private float [] _lcStyleBright = { 1f, 1.3f, 1.3f };
        readonly private float [] _lcStyleGamma = { 1f, 1.25f, 1.02f };

        public enum RayStyleEnum {
            Normalized,
            Extend,
        }

        // ----------------------------------------------------------- SerializeField
        [SerializeField] private bool m_generateInEditMode = true;
        [SerializeField, Range (0.1f, 1.9f)] private float m_density = 1f;
        [SerializeField, Range (0f, 4f)] private float m_speed = 1f;
        [SerializeField] private List<Wave> m_waves;
        [SerializeField] private CalcResEnum m_calcResolution = CalcResEnum.x160;
        [SerializeField] private RenderTexture m_renderTexture;
        [SerializeField, Range (0f, 0.5f)] private float m_FillGapAmount = 0.08f;
        [SerializeField] private LitDirTypeEnum m_lightDirectionType = LitDirTypeEnum.Numeric;
        [SerializeField] private Transform m_lightTransform;
        [SerializeField] private Vector3 m_lightDir = Vector3.down;
        [SerializeField] private LitCondensStyleEnum m_lightCondensingStyle = LitCondensStyleEnum.StyleB;
        [SerializeField] private RayStyleEnum m_rayStyle = RayStyleEnum.Normalized;
        [SerializeField, Range (0f, 3f)] private float m_brightness = 0.7f;
        [SerializeField, Range (0.0001f, 2f)] private float m_gamma = 1f;
        [SerializeField, Min (0f)] private float m_clamp = 2f;
        [Range (1f, 3f), SerializeField] private float m_refractionIndex = 1.333f;
        [SerializeField] private bool m_useChromaticAberration = false;
        [Range (0f, 0.3f), SerializeField] private float m_chromaticAberration = 0.005f;

        [SerializeField] private ComputeShader m_computeShader;
        [SerializeField] private Shader m_shader;


        private bool useChromAbe => (m_useChromaticAberration && m_chromaticAberration > 0f);

        private int bufSize3or1 () {
            return useChromAbe? 3 : 1;
        }

        // ----------------------------------------------------------- Public property
        public bool isGenerateInEditMode {
            get => m_generateInEditMode;
            set => m_generateInEditMode = value;
        }
        public float density {
            get => m_density;
            set => m_density = Mathf.Clamp (value, 0.1f, 3f);
        }
        public float speed {
            get => m_speed;
            set => m_speed = Mathf.Max (value, 0f);
        }
        public CalcResEnum calculateResolution {
            get => m_calcResolution;
            set => m_calcResolution = value;
        }
        public RenderTexture renderTexture {
            get => m_renderTexture;
            set => m_renderTexture = value;
        }
        public float fillGapAmount {
            get => m_FillGapAmount;
            set => m_FillGapAmount = Mathf.Clamp (value, 0f, 0.5f);
        }
        public LitDirTypeEnum lightDirectionType {
            get => m_lightDirectionType;
            set => m_lightDirectionType = value;
        }
        public Transform lightTransform {
            get => m_lightTransform;
            set => m_lightTransform = value;
        }
        public Vector3 lightDir {
            get => m_lightDir;
            set => m_lightDir = value;
        }
        public LitCondensStyleEnum lightCondensingStyle {
            get => m_lightCondensingStyle;
            set => m_lightCondensingStyle = value;
        }
        public RayStyleEnum rayStyle {
            get => m_rayStyle;
            set => m_rayStyle = value;
        }
        public float brightness {
            get => m_brightness;
            set => m_brightness = Mathf.Max (value, 0f);
        }
        public float gamma {
            get => m_gamma;
            set => m_gamma = Mathf.Max (value, 0.0001f);
        }
        public float clamp {
            get => m_clamp;
            set => m_clamp = Mathf.Max (value, 0f);
        }
        public float refractionIndex {
            get => m_refractionIndex;
            set => m_refractionIndex = Mathf.Clamp (value, 1f, 3f);
        }
        public bool useChromaticAberration {
            get => m_useChromaticAberration;
            set => m_useChromaticAberration = value;
        }
        public float chromaticAberration {
            get => m_chromaticAberration;
            set => m_chromaticAberration = Mathf.Clamp (value, 0f, 0.5f);
        }


        // -----------------------------------------------------------
        private void Reset () {
            m_waves = m_waves = new List<Wave> () {
                new Wave (4.5f, 0.53f, 0.6f, 0.7f, 0f),
                new Wave (11.5f, 0.5f, 0.6f, -0.7f, 0f)
            };
        }


        private void OnEnable () { }

        private void OnDisable () {
            if (!Application.isPlaying)
                DestroyAllBuffers ();
        }

        void OnDestroy () {
            DestroyAllBuffers ();
        }

        public void DestroyAllBuffers () {
            releaseGraphicsBuffers ();
            destroy (ref _mesh);
            destroy (ref __mat);
            destroy (ref __computeShader);
        }

        private void destroy<T> (ref T o) where T : Object {
            if (o == null) return;
            if (Application.isPlaying)
                Destroy (o);
            else
                DestroyImmediate (o);
            o = null;
        }

        // ----------------------------------------------------------- PropertyToID

        private class pID {
            readonly public static int _WaveCnt = Shader.PropertyToID ("_WaveCnt");
            readonly public static int _WaveData = Shader.PropertyToID ("_WaveData");
            readonly public static int _WaveUVShift = Shader.PropertyToID ("_WaveUVShift");
            readonly public static int _WaveNoiseDir = Shader.PropertyToID ("_WaveNoiseDir");
            readonly public static int _CalcResUI = Shader.PropertyToID ("_CalcResUI");
            readonly public static int _CalcTexel = Shader.PropertyToID ("_CalcTexel");
            readonly public static int _CalcTexelInv = Shader.PropertyToID ("_CalcTexelInv");
            readonly public static int _LightDir = Shader.PropertyToID ("_LightDir");
            readonly public static int _Eta = Shader.PropertyToID ("_Eta");
            readonly public static int _Brightness = Shader.PropertyToID ("_Brightness");
            readonly public static int _Gamma = Shader.PropertyToID ("_Gamma");
            readonly public static int _Clamp = Shader.PropertyToID ("_Clamp");
            readonly public static int _IdxStride = Shader.PropertyToID ("_IdxStride");
            readonly public static int _DrawOffset = Shader.PropertyToID ("_DrawOffset");

            readonly public static int _BufNoiseRW = Shader.PropertyToID ("_BufNoiseRW");
            readonly public static int _BufNoise = Shader.PropertyToID ("_BufNoise");
            readonly public static int _BufRefractRW = Shader.PropertyToID ("_BufRefractRW");
            readonly public static int _BufRefract = Shader.PropertyToID ("_BufRefract");

            readonly public static int _LightDirection = Shader.PropertyToID ("_LightDirection");
        }


        // ----------------------------------------------------------- ComputeShader
        private ComputeShader __computeShader;
        private ComputeShader getComputeShader () {
            if (__computeShader != null)
                return __computeShader;

            if (m_computeShader == null) {
                Debug.LogError ("Compute Shader is null. " + this);
                return null;
            } else {
                __computeShader = (ComputeShader) Instantiate (m_computeShader);
                kID.setKernelID (__computeShader);
                return __computeShader;
            }
        }

        private class kID {
            public static int NoiseCS;
            public static int RefractCS;
            public static int ColorCS;
            public static void setKernelID (ComputeShader cs) {
                NoiseCS = cs.FindKernel ("NoiseCS");
                RefractCS = cs.FindKernel ("RefractCS");
                ColorCS = cs.FindKernel ("ColorCS");
            }
        }

        // ----------------------------------------------------------- Material
        private Material __mat;
        private Material getMaterial () {
            if (__mat != null)
                return __mat;

            if (m_shader == null) {
                Debug.LogError ("Shader is null. " + this);
                return null;
            } else {
                __mat = new Material (m_shader);
                __mat.hideFlags = HideFlags.HideAndDontSave;
                return __mat;
            }
        }

        // ----------------------------------------------------------- Mesh
        private Mesh _mesh;
        private int _meshVertsCnt;

        private int calcVerticesCnt (int res) {
            int wholeWide = (int) res + (int) ((float) res * m_FillGapAmount) * 2;
            return (wholeWide + 1) * (wholeWide + 1) * bufSize3or1 ();
        }
        private void prepMesh () {
            if (_mesh == null || _meshVertsCnt != calcVerticesCnt ((int) m_calcResolution))
                setupMesh ();
        }

        private void setupMesh () {
            int wide = (int) m_calcResolution;
            float wideF = (float) wide;
            int bufArea = wide * wide;
            float cellSz = 1f / wideF;
            int over = (int) (wideF * m_FillGapAmount);
            int wholeWide = wide + over * 2;
            int bufSz3or1 = bufSize3or1 ();
            int verticesCnt = (wholeWide + 1) * (wholeWide + 1) * bufSz3or1;
            Vector3 [] vertices = new Vector3 [verticesCnt];
            for (int vi = 0, i = 0; i < bufSz3or1; i++) {
                for (int y = 0; y <= wholeWide; y++) {
                    for (int x = 0; x <= wholeWide; x++, vi++) {
                        int pX = x - over;
                        int pY = y - over;
                        float vX = (float) pX * cellSz;
                        float vY = (float) pY * cellSz;
                        int idx = ((pY + wide * 10) % wide) * wide + ((pX + wide * 10) % wide);
                        float vZ = (float) (i * bufArea + idx) + 0.1f;
                        vertices [vi] = new Vector3 (vX, vY, vZ);
                    }
                }
            }
            int [] triangles = new int [wholeWide * wholeWide * 6 * bufSz3or1];
            for (int ti = 0, vi = 0, i = 0; i < bufSz3or1; i++, vi += wholeWide + 1) {
                for (int y = 0; y < wholeWide; y++, vi++) {
                    for (int x = 0; x < wholeWide; x++, ti += 6, vi++) {
                        triangles [ti] = vi;
                        triangles [ti + 2] = triangles [ti + 3] = vi + 1;
                        triangles [ti + 1] = triangles [ti + 4] = vi + wholeWide + 1;
                        triangles [ti + 5] = vi + wholeWide + 2;
                    }
                }
            }
            if (_mesh == null)
                _mesh = new Mesh ();
            _mesh.Clear ();
            _mesh.indexFormat = (verticesCnt >= 65536) ? IndexFormat.UInt32 : IndexFormat.UInt16;
            _mesh.vertices = vertices;
            _mesh.triangles = triangles;
            _mesh.name = "WaterCausticsTexGen";
            _meshVertsCnt = verticesCnt;
        }


        // ----------------------------------------------------------- GraphicsBuffer
        private GraphicsBuffer _bufNoise;
        private GraphicsBuffer _bufRefract;
        void prepGraphicsBuffers () {
            int res = (int) m_calcResolution;
            int resSq = res * res;
            checkAndRemakeCBuffer (ref _bufNoise, resSq, 1);
            checkAndRemakeCBuffer (ref _bufRefract, resSq * bufSize3or1 (), 5);
        }

        private void checkAndRemakeCBuffer (ref GraphicsBuffer buf, int count, int stride) {
            if (buf == null || buf.count != count) {
                if (buf != null) buf.Release ();
                buf = new GraphicsBuffer (GraphicsBuffer.Target.Structured, count, sizeof (float) * stride);
            }
        }

        private void releaseGraphicsBuffers () {
            release (ref _bufNoise);
            release (ref _bufRefract);
        }

        private void release (ref GraphicsBuffer cb) {
            if (cb == null) return;
            cb.Release ();
            cb = null;
        }


        // ----------------------------------------------------------- Update
#if UNITY_EDITOR
        public void Preview (float deltaTime, RenderTexture rt) {
            if (Application.isPlaying && isActiveAndEnabled) deltaTime = 0f;
            generate (deltaTime, rt);
            if (!Application.isPlaying && isActiveAndEnabled && m_renderTexture)
                Graphics.Blit (rt, m_renderTexture);
        }

        public void FinishPreview () {
            if (!isActiveAndEnabled || (!Application.isPlaying && !m_generateInEditMode))
                DestroyAllBuffers ();
        }
#endif


        void Update () {
#if UNITY_EDITOR
            if (!Application.isPlaying && !m_generateInEditMode) return;
            generate (Application.isPlaying ? Time.deltaTime : 0f, m_renderTexture);
#else
            generate (Time.deltaTime, m_renderTexture);
#endif          
        }


        private void generate (float deltaTime, RenderTexture rt) {
            if (rt == null) return;

            // Prepare
            checkAndMakeBuffers ();

            // Set data for compute shader 
            setConstantBuffer (deltaTime);

            // Compute shader
            calcComputeShader ();

            // Draw mesh
            drawMesh (rt);
        }


        private void checkAndMakeBuffers () {
            prepGraphicsBuffers ();
            prepMesh ();
        }


        Vector3 refract (Vector3 I, float eta) {
            float dot = -I.z;
            float k = 1f - eta * eta * (1f - dot * dot);
            return (k < 0f) ? Vector3.zero : eta * I + Vector3.forward * (eta * dot + Mathf.Sqrt (k));
        }


        private Vector4 [] _tmpDataAry = new Vector4 [WAVE_MAX_CNT];
        private Vector4 [] _tmpUVAry = new Vector4 [WAVE_MAX_CNT];
        private Vector4 [] _tmpDirAry = new Vector4 [WAVE_MAX_CNT];


        private float getDecimal (float v) {
            return v - Mathf.Floor (v);
        }

        const float NOISE_RADIUS = 100f;
        const float NOISE_CIRCUMFERENCE_INV = 1f / (NOISE_RADIUS * 2f * Mathf.PI);

        private void setConstantBuffer (float delteTime) {
            var cs = getComputeShader ();
            if (cs == null) return;

            // Waves
            int waveIdx = 0;
            float delta = delteTime * m_speed;
            foreach (var w in m_waves) {
                if (!w.Active) continue;
                if (!w.Pause) {
                    w.pos.z = getDecimal (w.pos.z + w.fluctuation * NOISE_CIRCUMFERENCE_INV * delta);
                    w.pos.x = getDecimal (w.pos.x - w.flowU * delta / w.density);
                    w.pos.y = getDecimal (w.pos.y - w.flowV * delta / w.density);
                }
                float rad = w.pos.z * Mathf.PI * 2f;
                float cos = Mathf.Cos (rad);
                float sin = Mathf.Sin (rad);
                _tmpDirAry [waveIdx] = new Vector2 (cos, sin);
                _tmpUVAry [waveIdx] = new Vector2 (w.pos.x, w.pos.y);
                _tmpDataAry [waveIdx] = w.getData (m_density);
                if (++waveIdx >= WAVE_MAX_CNT) break;
            }
            cs.SetInt (pID._WaveCnt, waveIdx);
            cs.SetVectorArray (pID._WaveData, _tmpDataAry);
            cs.SetVectorArray (pID._WaveUVShift, _tmpUVAry);
            cs.SetVectorArray (pID._WaveNoiseDir, _tmpDirAry);

            // Resolution
            int calcRes = (int) m_calcResolution;
            float texel = 1f / (float) calcRes;
            cs.SetFloat (pID._CalcTexel, texel);
            cs.SetFloat (pID._CalcTexelInv, (float) calcRes);
            cs.SetInt (pID._CalcResUI, calcRes);
            cs.SetInt (pID._IdxStride, calcRes * calcRes);

            // light Direction
            Vector3 litDir;
            switch (m_lightDirectionType) {
                case LitDirTypeEnum.Numeric:
                    litDir = (m_lightDir != Vector3.zero) ? m_lightDir.normalized : Vector3.down;
                    break;
                case LitDirTypeEnum.Transform:
                    litDir = (m_lightTransform != null) ? m_lightTransform.forward : Vector3.down;
                    break;
                case LitDirTypeEnum.LitSettingSun:
                    litDir = (RenderSettings.sun != null) ? RenderSettings.sun.transform.forward : Vector3.down;
                    break;
                case LitDirTypeEnum.Auto:
                default:
                    litDir = -Shader.GetGlobalVector (pID._LightDirection);
                    break;
            }
            if (litDir.y >= 0f) {
                litDir.y = -0.01f;
                litDir = litDir.normalized;
            }
            litDir = new Vector3 (litDir.x, litDir.z, -litDir.y);
            cs.SetVector (pID._LightDir, litDir);

            // Brightness
            cs.SetFloat (pID._Brightness, m_brightness * _lcStyleBright [(int) m_lightCondensingStyle] * 0.1f);
            cs.SetFloat (pID._Gamma, m_gamma * _lcStyleGamma [(int) m_lightCondensingStyle]);
            cs.SetFloat (pID._Clamp, m_clamp);


            // Refraction index
            float eta = 1f / m_refractionIndex;
            float chrAb = 1f + m_chromaticAberration;
            Vector3 refractIdx = new Vector3 (eta * chrAb, eta, eta / chrAb);
            cs.SetVector (pID._Eta, refractIdx);

            // Offset drawing position
            Vector3 refractG = refract (litDir, eta);
            if (m_rayStyle == RayStyleEnum.Normalized) {
                cs.DisableKeyword ("EXTEND_RAY");
                cs.SetVector (pID._DrawOffset, -(Vector2) refractG);
            } else {
                cs.EnableKeyword ("EXTEND_RAY");
                cs.SetVector (pID._DrawOffset, -(Vector2) refractG / refractG.z);
            }
        }


        private void calcComputeShader () {
            var cs = getComputeShader ();
            if (cs == null) return;

            // Keywords
            cs.EnableKeyword (_lcStyleStr [(int) m_lightCondensingStyle]);

            int kernel;
            int sc = (int) m_calcResolution / THREAD_SIZE;
            int shift = useChromAbe ? 1 : 0;

            cs.SetBuffer (kID.NoiseCS, pID._BufNoiseRW, _bufNoise);
            cs.Dispatch (kID.NoiseCS, sc, sc, 1);

            kernel = kID.RefractCS + shift;
            cs.SetBuffer (kernel, pID._BufNoise, _bufNoise);
            cs.SetBuffer (kernel, pID._BufRefractRW, _bufRefract);
            cs.Dispatch (kernel, sc, sc, 1);

            kernel = kID.ColorCS + shift;
            cs.SetBuffer (kernel, pID._BufRefractRW, _bufRefract);
            cs.Dispatch (kernel, sc, sc, 1);

            // cs.SetBuffer (kID.ColorCS + 2, pID._BufNoise, _bufNoise);
            // cs.SetBuffer (kID.ColorCS+ 2, pID._BufRefractRW, _bufRefract);
            // cs.Dispatch (kID.ColorCS+ 2, sc, sc, 1);

            // cs.SetBuffer (kID.ColorCS + 3, pID._BufRefractRW, _bufRefract);
            // cs.Dispatch (kID.ColorCS + 3, sc, sc, 1);

            // Keywords
            cs.DisableKeyword (_lcStyleStr [(int) m_lightCondensingStyle]);
        }


        readonly private Matrix4x4 ORTHO_MATRIX = Matrix4x4.Ortho (0, 1, 0, 1, 0.1f, 10);
        private void drawMesh (RenderTexture rt) {
            var mat = getMaterial ();
            if (mat == null) return;

            RenderTexture prevRT = RenderTexture.active;
            rt.DiscardContents ();
            RenderTexture.active = rt;
            GL.Clear (false, true, Color.clear);

            GL.PushMatrix ();
            GL.LoadIdentity();
            var matrix = (Camera.current == null) ? ORTHO_MATRIX : ORTHO_MATRIX * Camera.current.worldToCameraMatrix.inverse;
            GL.LoadProjectionMatrix (matrix);

            mat.SetBuffer (pID._BufRefract, _bufRefract);
            mat.SetPass (0);
            Graphics.DrawMeshNow (_mesh, Matrix4x4.identity);

            GL.PopMatrix ();
            RenderTexture.active = prevRT;
            
            rt.IncrementUpdateCount();
        }


        // ----------------------------------------------------------- Wave class
        [System.Serializable]
        public class Wave {
            public bool Active = true;
            public bool Pause = false;
            [SerializeField, Range (1f, 20f)] private float m_density = 3f;
            [SerializeField, Range (0f, 1f)] private float m_height = 0.53f;
            [Space (3)]
            [SerializeField, Range (0f, 2f)] private float m_fluctuation = 0.6f;
            [SerializeField, Range (-5f, 5f)] private float m_flowU = 0.7f;
            [SerializeField, Range (-5f, 5f)] private float m_flowV = 0f;

            public float density {
                get => m_density;
                set => m_density = Mathf.Clamp (value, 1f, 20f);
            }
            public float height {
                get => m_height;
                set => m_height = Mathf.Clamp (value, 0f, 1f);
            }
            public float fluctuation {
                get => m_fluctuation;
                set => m_fluctuation = Mathf.Clamp (value, 0f, 2f);
            }
            public float flowU {
                get => m_flowU;
                set => m_flowU = Mathf.Clamp (value, -5f, 5f);
            }
            public float flowV {
                get => m_flowV;
                set => m_flowV = Mathf.Clamp (value, -5f, 5f);
            }

            [System.NonSerialized] public Vector3 pos;

            public Wave (float density, float height, float fluct, float flowU, float flowV) {
                m_density = density;
                m_height = height;
                m_fluctuation = fluct;
                m_flowU = flowU;
                m_flowV = flowV;
            }
            public Vector2 getData (float adjustDensity) {
                float d = m_density * adjustDensity;
                return new Vector2 (d, m_height / (d * d) * 0.5f);
            }
        }


        // -----------------------------------------------------------


    }
}
