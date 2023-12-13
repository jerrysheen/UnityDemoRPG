// WaterCausticsModules
// Copyright (c) 2021 Masataka Hakozaki

using UnityEngine;

namespace MH.WaterCausticsModules {
    public class DEMO_CameraDolly : MonoBehaviour {
        public float m_SpeedScroll = 2f;
        public float m_SpeedKey = 0.2f;
        public float m_SpeedPinch = 2f;

        public float m_Damping = 4f;

        private float _prePinch;
        private float _tarZ;


        private bool isMouseInsideGameView {
            get {
                var pos = Input.mousePosition;
                return 0f <= pos.x && 0f <= pos.y && Screen.width >= pos.x && Screen.height >= pos.y;
            }
        }

        private void OnEnable () {
            _tarZ = transform.localPosition.z;
        }

        void Update () {
            if (Input.touchCount == 2) {
                var tch0 = Input.GetTouch (0);
                var tch1 = Input.GetTouch (1);
                if (tch1.phase == TouchPhase.Began) {
                    _prePinch = Vector2.Distance (tch0.position, tch1.position);
                } else if (tch0.phase == TouchPhase.Moved || tch1.phase == TouchPhase.Moved) {
                    float curPinch = Vector2.Distance (tch0.position, tch1.position);
                    float pinch = (curPinch - _prePinch) / Mathf.Min (Screen.width, Screen.height);
                    _prePinch = curPinch;
                    _tarZ += pinch * m_SpeedPinch * Mathf.Abs (_tarZ);
                }
            } else if (Input.GetAxis ("Vertical") != 0) {
                _tarZ += Input.GetAxis ("Vertical") * m_SpeedKey * Mathf.Abs (_tarZ) * Time.deltaTime;
            } else {
                float scroll = Input.GetAxis ("Mouse ScrollWheel");
                if (scroll != 0f && isMouseInsideGameView) {
                    _tarZ += scroll * m_SpeedScroll * Mathf.Abs (_tarZ);
                }
            }
            float curZ = transform.localPosition.z;
            if (Mathf.Abs (curZ - _tarZ) > 0.00001f) {
                float z = Mathf.Lerp (curZ, _tarZ, Time.deltaTime * m_Damping);
                transform.localPosition = Vector3.forward * z;
            }
        }

    }
}
