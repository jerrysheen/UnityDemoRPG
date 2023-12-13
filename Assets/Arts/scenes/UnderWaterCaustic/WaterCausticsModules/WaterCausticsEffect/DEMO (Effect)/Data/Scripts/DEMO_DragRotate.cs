// WaterCausticsModules
// Copyright (c) 2021 Masataka Hakozaki

using UnityEngine;

namespace MH.WaterCausticsModules {
    public class DEMO_DragRotate : MonoBehaviour {
        public float m_Speed = 3f;
        public float m_Damping = 6f;

        [Range (0f, 89f)] public float m_LookDownMaxAngle = 88f;
        [Range (0f, 89f)] public float m_LookUpMaxAngle = 88f;

        private Quaternion _tarQ;
        private Vector2 _prePos;

        private void Start () {
            _tarQ = transform.rotation;
        }

        private bool _valid;

        void Update () {
            if (Input.touchCount <= 1 && Input.GetMouseButton (0)) {
                if (!_valid) {
                    _valid = true;
                    _prePos = Input.mousePosition;
                } else {
                    var curPos = Input.mousePosition;
                    float deltaX = (curPos.x - _prePos.x) / Screen.width;
                    float deltaY = (curPos.y - _prePos.y) / Screen.height;
                    _prePos = curPos;
                    var vec = new Vector3 (-deltaY * 90f * m_Speed, deltaX * 90f * m_Speed, 0);
                    var euler = _tarQ.eulerAngles + vec;
                    euler.z = 0f;
                    euler.x = (euler.x <= 180f) ? Mathf.Min (euler.x, m_LookDownMaxAngle) : Mathf.Max (euler.x, 360f - m_LookUpMaxAngle);
                    _tarQ = Quaternion.Euler (euler);
                }
            } else {
                _valid = false;
            }
            var curRot = transform.rotation;
            if (Quaternion.Angle (_tarQ, curRot) > 0.00001f) {
                var rot = Quaternion.Slerp (curRot, _tarQ, m_Damping * Time.deltaTime).eulerAngles;
                rot.z = 0f;
                transform.rotation = Quaternion.Euler (rot);
            }
        }

    }
}
