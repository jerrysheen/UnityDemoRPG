using UnityEngine;
using System.Collections.Generic;
using System;

/// <summary>
/// 暂时不支持cross;
/// </summary>
public partial class AnimationInstancing : MonoBehaviour
{
    private static int CUR_FRAME_IDX_ID = Shader.PropertyToID("_CurFramIndex_Array");
    private static int PRE_FRAME_IDX_ID = Shader.PropertyToID("_PreFramIndex_Array");
    // private static int PROGRESS_ID = Shader.PropertyToID("_TransProgress");
    
    private static int SKIN_TEX_W_ID = Shader.PropertyToID("_SkinningTexW");
    private static int SKIN_TEX_H_ID = Shader.PropertyToID("_SkinningTexH");
    private static int HORIZONAL_PLANE = Shader.PropertyToID("_HorizontalPlane_Array");
    
    public AnimationData data;
    private int boneCount;
    [NonSerialized]
    public float _time;
    public string _curclipName;
    private int _curFrameIndex = -1;
    private TextureAnimationClip _curClip;
    private bool _curFrameDirty = true;
    
    private float _preTime;
    private int _preFramIndex;
    private float _transitionProgess;
    private bool _isTransition;
    private float _progessTimer;
    
    private TextureAnimationClip _preClip;
    
    private MaterialPropertyBlock propertyBlock;
    private Dictionary<string, TextureAnimationClip> _clipMap;
    private float _speed = 1f;
    private float _curClipLength = 0;
    private bool _crossFadeDirty = false;

    private List<MeshRenderer> meshList = new List<MeshRenderer>();
    
    /// <summary>
    /// 当有骨骼绑定时才设置，boneUseRefMap用于优化计算;
    /// </summary>
    private List<Transform> boneList = null;
    private Dictionary<Transform, int> boneUseRefMap = null;

    /// <summary>
    /// 默认动作名;
    /// </summary>
    private string _default_anim = null;

    public bool playDefaultAnim = false;
    
    /// <summary>
    /// Animation is playing
    /// </summary>
    public bool IsPlaying(int loopTimes)
    {
        return _time < loopTimes * _curClipLength;
    }

    public float speed
    {
        get { return _speed; }
        set { _speed = value; }
    }
    
    public TextureAnimationClip GetClip(string clipName)
    {
        return _clipMap.ContainsKey(clipName) ? _clipMap[clipName] : null;
    }

    /// <summary>
    /// get all clip names;
    /// </summary>
//    public string[] GetClips()
//    {
//        string[] names;
//        if (_clipMap == null || _clipMap.Count <= 0)
//        {
//            return null;
//        }
//        names = new string[_clipMap.Count];
//        _clipMap.Keys.CopyTo(names, 0);
//        return names;
//    }
    public string GetBoneNameByIdx(int index)
    {
        if (data == null || data.exportBoneName == null)
            return null;

        if (index < 0 || index >= data.exportBoneName.Length)
            return null;

        return data.exportBoneName[index];
    }
    
    public Transform BindBone(string boneName)
    {
        if (string.IsNullOrEmpty(boneName))
            return null;
        
        if (boneList == null)
        {
            boneList = new List<Transform>();
            boneUseRefMap = new Dictionary<Transform, int>();
        }
        else
        {
            foreach (Transform tran in boneList)
            {
                if (tran.name == boneName)
                {
                    int curRef = boneUseRefMap[tran];
                    boneUseRefMap[tran] = curRef + 1;
                    if (curRef == 0)
                    {
                        UpdateBoneTran(tran);
                    }
                    return tran;
                }
            }
        }
        
        Transform boneTran = new GameObject(boneName).transform;
        boneTran.SetParent(transform, false);
        boneList.Add(boneTran);
        boneUseRefMap[boneTran] = 1;
        UpdateBoneTran(boneTran);
        return boneTran;
    }

    public void UnBindBone(string boneName)
    {
        if (boneList == null || string.IsNullOrEmpty(boneName))
            return;

        foreach (Transform tran in boneList)
        {
            if (tran.name == boneName)
            {
                boneUseRefMap[tran] = boneUseRefMap[tran] - 1;
                return;
            }
        }
    }

    private void UpdateBoneTran(Transform tran)
    {
        if(tran == null)
            return;
        
        TextureAnimationClip.Bone boneData = GetBoneData(tran.name);
        if (boneData == null)
        {
            return;
        }
        
        Matrix4x4 matrix = boneData.frames[_curFrameIndex];
            
        tran.localPosition = matrix.GetColumn(3);
        tran.localRotation = matrix.rotation;
        tran.localScale = matrix.lossyScale;
    }

    //public Matrix4x4 GetMatrix(string boneName)
    //{
    //	if (clip != null && _boneMap.ContainsKey(boneName))
    //	{
    //		return transform.localToWorldMatrix * clip.bones[_boneMap[boneName]].frames[frame];
    //	}
    //	return Matrix4x4.identity;
    //}

    void Awake()
    {
        propertyBlock = new MaterialPropertyBlock();
        
        _clipMap = new Dictionary<string, TextureAnimationClip>();
        if (data != null)
        {
            boneCount = data.boneCount;
            foreach (TextureAnimationClip clip in data.clips)
            {
                _clipMap.Add(clip.name, clip);
            }
        }
        
        InitMeshes();

        SetTextureWH();

        _default_anim = _curclipName;
        
        EcsAwake();

        if (playDefaultAnim)
        {
            PlayDefaultAnim(); 
        }
    }
    
    partial void EcsAwake();
    
    private void SetTextureWH()
    {
        if (data == null || data.animaTexture == null || data.animaTexture.Length == 0)
            return;
        
        var tex = data.animaTexture[0];
        if (tex != null)
        {
            foreach (MeshRenderer meshRenderer in meshList)
            {
                meshRenderer.sharedMaterial.SetFloat(SKIN_TEX_W_ID, tex.width);
                meshRenderer.sharedMaterial.SetFloat(SKIN_TEX_H_ID, tex.height);
            }
        }
    }

    private void InitMeshes()
    {
        int childCount = transform.childCount;
        for (int i = 0; i < childCount; i++)
        {
            Transform child = transform.GetChild(i);
            MeshRenderer meshRenderer = child.GetComponent<MeshRenderer>();
            if (meshRenderer != null)
            {
                meshList.Add(meshRenderer);
            }
        }
    }

    public void PlayDefaultAnim()
    {
        if(string.IsNullOrEmpty(_default_anim))
            return;
        
        Play(_default_anim);
    }
    
    /// <summary>
    ///  Animation mix
    /// </summary>
    public void CrossFade(string name, float fadeLength, float normalizedTime)
    {
//        if (fadeLength > 0 && _curclipName != name)
//        {
//            _isTransition = true;
//            _transitionProgess = fadeLength;
//            _progessTimer = _transitionProgess;
//            _preTime = _time;
//            _preClip = _curClip;
//        }
        PlayInternal(name, normalizedTime);
    }
    
    public void Play(string name, float normalizedTime = 0)
    {
        // ResetTransition();
        PlayInternal(name, normalizedTime);
    }

    private void PlayInternal(string name, float normalizedTime)
    {
        bool isDirty = _curFrameDirty;
        if (_curclipName != name)
        {
            _curclipName = name;
            _curFrameDirty = true;
        }

        _curClip = GetClip(name);
        _curClipLength = (_curClip != null) ? 1.0f * _curClip.frameCount / _curClip.frameRate : 0;
        _time = normalizedTime * _curClipLength;

        if (isDirty || _curFrameDirty)
        {
            UpdateAnimation(0);
        }
    }
    
    private void ResetTransition()
    {
        if (_isTransition)
        {
            _crossFadeDirty = true;
            
            _preFramIndex = 0;
            _preClip = null;
            _preTime = 0;
            _isTransition = false;   
        }
    }
    
    private void UpdateAnimation(float changeTime)
    {
        if (_curClip == null)
        {
            return;
        }

        ComputeCurFrameIdx(changeTime);
        // float lerp = ComputeCrossFade(changeTime);

        if (!_curFrameDirty)
            return;
        
        _curFrameDirty = false;
        
        // 动画绘制;
        UpdateAnim(/*lerp*/);

        // 更新挂件;    
        UpdateBones();
    }

    private void ComputeCurFrameIdx(float changeTime)
    {
        _time += changeTime;
        int curFrameIndex = (int)(_time * _curClip.frameRate);
        if (curFrameIndex >= _curClip.frameCount)
        {
            // 不循环;
            if (!_curClip.isLoop)
            {
                curFrameIndex = _curClip.frameCount - 1;
            }
            else
            {
                curFrameIndex = (curFrameIndex - _curClip.frameCount) % _curClip.frameCount;
            }
        }

        if (_curFrameIndex != curFrameIndex)
        {
            _curFrameDirty = true;
            _curFrameIndex = curFrameIndex;
        }
    }

    private float ComputeCrossFade(float changeTime)
    {
        float t_lerp = 0;
        
        if (_isTransition)
        {
            if (_transitionProgess > 0)
            {
                _preTime += changeTime;
                _transitionProgess -= changeTime;

                if (_transitionProgess < 0)
                {
                    _transitionProgess = 0;
                }
                
                if (_preClip != _curClip && _preClip != null)
                {
                    _preFramIndex = (int)(_preTime * _preClip.frameRate);
                    if (_preFramIndex >= _preClip.frameCount)
                    {
                        if (!_preClip.isLoop)
                        {
                            _preFramIndex = _preClip.frameCount - 1;
                        }
                        else
                        {
                            _preFramIndex = (_preFramIndex - _preClip.frameCount) % _preClip.frameCount;
                        }
                    }
                    _preFramIndex = _preClip.pixelStartIndex + boneCount * 2 * _preFramIndex;
                }

                t_lerp = _transitionProgess / _progessTimer;
            }
            else
            {
                ResetTransition();
            }
        }

        return t_lerp;
    }
    
#if UNITY_EDITOR
    private void OnApplicationFocus(bool hasFocus)
    {
        if (hasFocus)
        {
            SetTextureWH();
        }
    }
#endif

    private void UpdateAnim(float t_lerp = 0)
    {
        /// <summary>
        /// 偏移修正;
        /// </summary>    
        int shaderCurFrameIndex = _curClip.pixelStartIndex + boneCount * 2 * _curFrameIndex;
        
        foreach (MeshRenderer meshRenderer in meshList)
        {
            meshRenderer.GetPropertyBlock(propertyBlock);
            
            propertyBlock.SetFloat(CUR_FRAME_IDX_ID, shaderCurFrameIndex);
            
            propertyBlock.SetFloat(HORIZONAL_PLANE, meshRenderer.gameObject.transform.position.y - 0.005f);
//            if (_isTransition)
//            {
//                propertyBlock.SetFloat(PRE_FRAME_IDX_ID, _preFramIndex);
//                propertyBlock.SetFloat(PROGRESS_ID, t_lerp);
//            }
//            else if (_crossFadeDirty)
//            {
//                propertyBlock.SetFloat(PROGRESS_ID, 0);
//                _crossFadeDirty = false;
//            }
            meshRenderer.SetPropertyBlock(propertyBlock);
        }
    }

    private void UpdateBones()
    {
        if(boneList == null)
            return;
        
        foreach (Transform bone in boneList)
        {
            if(boneUseRefMap[bone] <= 0)
                continue;

            TextureAnimationClip.Bone boneData = GetBoneData(bone.name);
            if (boneData == null)
            {
                return;
            }

            Matrix4x4 matrix = boneData.frames[_curFrameIndex];
            
            bone.localPosition = matrix.GetColumn(3);
            bone.localRotation = matrix.rotation;
            bone.localScale = matrix.lossyScale;
            
//            int boneNameID = Animator.StringToHash(bone.name);
//            int widgetCount = bone.childCount;
//            if (widgetCount > 0 && _boneMap.ContainsKey(boneNameID))
//            {
//                Matrix4x4 matrix = _curClip.bones[_boneMap[boneNameID]].frames[_curFramIndex];
//                Vector3 forward = new Vector3(matrix.m02, matrix.m12, matrix.m22);
//                Vector3 upwards = new Vector3(matrix.m01, matrix.m11, matrix.m21);
//                bone.localRotation = Quaternion.LookRotation(forward, upwards);
//                bone.localPosition = matrix.GetColumn(3);
//                bone.localScale = matrix.lossyScale;
//
//                bone.localRotation = matrix.rotation;
//                //update matrix lerp;
//            }
        }
    }

    private TextureAnimationClip.Bone GetBoneData(string name)
    {
        for (int i = 0; i < _curClip.bones.Length; i++)
        {
            TextureAnimationClip.Bone data = _curClip.bones[i];
            if (data.boneName.Equals(name))
                return data;
        }

#if UNITY_EDITOR
        Debug.LogError(string.Format("{0} GPUInstance 挂点【{1}】信息未导出", transform.name, name));
#endif
        return null;
    }
    
    void Update()
    {
        float changeTime = _speed * Time.deltaTime;
        UpdateAnimation(changeTime);
    }
}
