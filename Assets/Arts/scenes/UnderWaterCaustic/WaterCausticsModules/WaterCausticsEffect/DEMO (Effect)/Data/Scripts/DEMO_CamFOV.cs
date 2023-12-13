// WaterCausticsModules
// Copyright (c) 2021 Masataka Hakozaki

using UnityEngine;

namespace MH.WaterCausticsModules {

    [ExecuteAlways ()]
    [RequireComponent (typeof (Camera))]
    public class DEMO_CamFOV : MonoBehaviour {
        public float m_Fov = 35.0f;
        private Camera _cam;
        private Camera cam => _cam ? _cam : _cam = GetComponent<Camera> ();

        int scW, scH;
        private void Update () {
            if (Screen.width != scW || Screen.height != scH) {
                scW = Screen.width;
                scH = Screen.height;
                ResetFov ();
            }
        }

        private void ResetFov () {
            if (scW > scH) {
                float aspectHW = (float) scH / (float) scW;
                cam.fieldOfView = m_Fov * ((aspectHW - 1.0f) * 0.2f + 1.0f);
            } else {
                float aspectWH = (float) scW / (float) scH;
                cam.fieldOfView = getHorizontalAngle (aspectWH) * ((aspectWH - 1.0f) * 0.2f + 1.0f);
            }
        }

        private float getHorizontalAngle (float aspectWH) {
            float radFov = m_Fov * Mathf.Deg2Rad;
            float camH = Mathf.Tan (radFov * 0.5f);
            return Mathf.Atan (camH / aspectWH) * 2.0f * Mathf.Rad2Deg;
        }

    }
}
