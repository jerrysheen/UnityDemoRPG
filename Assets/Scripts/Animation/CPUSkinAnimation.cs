using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEditor;
using UnityEngine;

public class CPUSkinAnimation : MonoBehaviour
{
    // 这里不用enum切换，enum切换貌似会暂停播放。。
    [SerializeField]
    public enum PlayAnimationType
    {
        USING_SAMPLEANIMTION,
        USING_CPUSKINMESH
    }

    public AnimationClip animationClip;
    public bool UsingSampleAnimation;
    public bool UsingCpuSkinAnimation = false;
    private float timer;

    public SkinnedMeshRenderer currSkinMeshRenderer;
    public Mesh sharedMesh;
    public Transform[] bones;
    public Matrix4x4[] bindPose;
    public BoneWeight[] boneWeights;
    public Transform[] currentTransform;
    public Dictionary<string, AnimationCurveStruct[]> animationCurveDataDic;
    public Dictionary<string, int> bonesIndexMap;

    private int currFrame = 0;
        public struct AnimationCurveStruct
    {
        public Vector3 position;
        public Quaternion rotation;
        public Vector3 scale;
        
    }
    private static void ClipSample(GameObject go, TextureAnimationClip textureAnimationClip, AnimationClip animationClip, int frame)
    {
        float timer = frame * (animationClip.length / textureAnimationClip.frameCount);
        timer = Mathf.Min(timer, animationClip.length);
        animationClip.SampleAnimation(go, timer);
    }

    
    // Start is called before the first frame update
    void Start()
    {
        //animationClip.SampleAnimation(this.gameObject, 0.0f);
        //StartCoroutine(PlayAttachAnimation());
        timer = 0;

        currSkinMeshRenderer = this.GetComponentInChildren<SkinnedMeshRenderer>();
        sharedMesh = currSkinMeshRenderer.sharedMesh;
        bones = currSkinMeshRenderer.bones;
        bindPose = sharedMesh.bindposes;
        sharedMesh.boneWeights = sharedMesh.boneWeights;
        //currentTransform 在开始的时候等于bones初始姿态
        currentTransform = bones;

        animationCurveDataDic = new Dictionary<string, AnimationCurveStruct[]>();
        ConstructOffsetMatrix();
        CalculateBoneIndex();
    }

    // Update is called once per frame
    void Update()
    {
        
        timer += Time.deltaTime;
        if (UsingSampleAnimation)
        {
            PlayAnimationUsingAnimationClip();
        }
        else if (UsingCpuSkinAnimation)
        {
            PlayAnimationUsingCpuSkinAnimation( currFrame);
        }

        currFrame++;
        if (timer > animationClip.length) timer = 0;
    }

    public void PlayAnimationUsingCpuSkinAnimation(int frame)
    {
        // 首先移动骨骼到位置
        CalculateCurrentPose(frame);
        // //首先简单的从获取Vertices, Normal, Tangent三个参数来做吧
        // for (int i = 0; i < sharedMesh.vertices.Length; i++)
        // {
        //     // 针对每个vertices，我需要先计算权重，然后混合
        //     //设置顶点的骨骼权重
        //     BoneWeight weight = boneWeights[i];
        //     float weight0 = weight.weight0;
        //     float weight1 = weight.weight1;
        //     float weight2 = weight.weight2;
        //     float weight3 = weight.weight3;
        //     //设置顶点的骨骼的index
        //     int boneIndex0 = indexMap[transforms[weight.boneIndex0].name];
        //     int boneIndex1 = indexMap[transforms[weight.boneIndex1].name];
        //     int boneIndex2 = indexMap[transforms[weight.boneIndex2].name];
        //     int boneIndex3 = indexMap[transforms[weight.boneIndex3].name];
        //     indices.Add(new Vector4(boneIndex0,boneIndex1,boneIndex2,boneIndex3));
        //     weights.Add(new Vector4(weight0,weight1,weight2,weight3));
        //     if(v < vertices.Length)
        //         vertices[v] = meshMatrix * sharedMesh.vertices[v];
        //     if(v < normals.Length)
        //         normals[v] = meshMatrix * sharedMesh.normals[v];
        //     if(v < tangents.Length)
        //         tangents[v]=meshMatrix * sharedMesh.tangents[v];
        //     weight.boneIndex0 = boneIndex0;
        //     weight.boneIndex1 = boneIndex1;
        //     weight.boneIndex2 = boneIndex2;
        //     weight.boneIndex3 = boneIndex3;
        //     boneWeights[v] = weight;
        //     
        // }
        // 获取当前的动画数据：

    }

    public void CalculateCurrentPose(int frame)
    {
        Vector3 OldPosition = new Vector3(this.transform.position.x, this.transform.position.y, this.transform.position.z);
        Vector3 OldScale = new Vector3(this.transform.localScale.x, this.transform.localScale.y, this.transform.localScale.z);
        Quaternion OldRotation = new Quaternion(this.transform.rotation.x, this.transform.rotation.y, this.transform.rotation.z, this.transform.rotation.w);
        Transform currPrefabTransform = this.transform;
        int frameCount = (int)(animationClip.frameRate * animationClip.length);
        frame %= frameCount;
        // 当前的frame，根据主从关系遍历所有骨骼
        Transform[] trans = this.GetComponentsInChildren<Transform>();
        
        foreach (var currTransform in trans)
        {
            Matrix4x4 matrix;
            if (!bonesIndexMap.ContainsKey(currTransform.name)||!animationCurveDataDic.ContainsKey(currTransform.name))
            {
//                Debug.Log("Unused Bone" + currTransform.name);
                matrix = Matrix4x4.identity.inverse;
            }
            else
            {
                AnimationCurveStruct currStruct = animationCurveDataDic[currTransform.name][frame];
                Matrix4x4 boneOffsetMatrix = Matrix4x4.TRS(currStruct.position, currStruct.rotation, currStruct.scale);
                
                Matrix4x4 bindPoseWorldToLocalmatrix = bindPose[bonesIndexMap[currTransform.name]];
                Quaternion worldToModelQuaternion = Quaternion.LookRotation(Vector3.up, Vector3.back);
                Matrix4x4 worldToModel = Matrix4x4.TRS(Vector3.zero, worldToModelQuaternion, Vector3.one);
                matrix = worldToModel * bindPoseWorldToLocalmatrix.inverse * boneOffsetMatrix;
            }

            currTransform.position = matrix.GetColumn(3);
            currTransform.rotation = Quaternion.LookRotation(matrix.GetColumn(2), matrix.GetColumn(1));
            currTransform.localScale = new Vector3(
                matrix.GetColumn(0).magnitude,
                matrix.GetColumn(1).magnitude,
                matrix.GetColumn(2).magnitude
            );
            
            
        }

        this.transform.position = OldPosition;
        this.transform.localScale = OldScale;
        this.transform.rotation = OldRotation;
    }



    public void CalculateBoneIndex()
    {
        Matrix4x4[] bindposesSet = sharedMesh.bindposes;
        Transform[] bonesSet = currSkinMeshRenderer.bones;
        Debug.Log("Bone Count: " + bonesSet.Length);
        //提取bonesSet的名字以及默认的序号
        bonesIndexMap = new Dictionary<string, int>();
        for (int i = 0; i < bonesSet.Length; i++)
        {
            if (!bonesIndexMap.ContainsKey(bonesSet[i].name))
            {
                bonesIndexMap[bonesSet[i].name] = i;
            }
        }
    }

    public void ConstructOffsetMatrix()
    {
        if (animationClip == null)
        {
            Debug.LogError("Doesn't have animation clip");
            return;
        }

        foreach (var binding in AnimationUtility.GetCurveBindings(animationClip))
        {
            AnimationCurve curve = AnimationUtility.GetEditorCurve(animationClip, binding);
            //if(binding.propertyName == "m_LocalPosition.x")
            //if(binding.propertyName == "m_LocalRotation.x")
            // if(binding.propertyName == "m_LocalScale.x")
            //     EditorGUILayout.LabelField(binding.path + "||| PropertyName: " + binding.propertyName + "|||  Keys: " + curve.keys[0].value);
            string realBoneName;
            int lastIndex = binding.path.LastIndexOf('/');

            if (lastIndex != -1)
            {
                realBoneName = binding.path.Substring(lastIndex + 1);
            }
            else
            {
                realBoneName = binding.path;
            }
            string result = binding.path.Substring(lastIndex + 1);
            if (!animationCurveDataDic.ContainsKey(realBoneName))
            {
                animationCurveDataDic[realBoneName] = new AnimationCurveStruct[curve.keys.Length];
            }
            
            {
                //值已经有了，那么就只要将当前的数据塞进去即可
                for (int i = 0; i < curve.keys.Length; i++)
                {
                    switch (binding.propertyName)
                    {
                        case "m_LocalPosition.x":
                            animationCurveDataDic[realBoneName][i].position.x = curve.keys[i].value;
                            break;
                        case "m_LocalPosition.y":
                            animationCurveDataDic[realBoneName][i].position.y = curve.keys[i].value;
                            break;
                        case "m_LocalPosition.z":
                            animationCurveDataDic[realBoneName][i].position.z = curve.keys[i].value;
                            break;
                        case "m_LocalRotation.x":
                            animationCurveDataDic[realBoneName][i].rotation.x = curve.keys[i].value;
                            break;
                        case "m_LocalRotation.y":
                            animationCurveDataDic[realBoneName][i].rotation.y = curve.keys[i].value;
                            break;
                        case "m_LocalRotation.z":
                            animationCurveDataDic[realBoneName][i].rotation.z = curve.keys[i].value;
                            break;
                        case "m_LocalRotation.w":
                            animationCurveDataDic[realBoneName][i].rotation.w = curve.keys[i].value;
                            break;
                        case "m_LocalScale.x":
                            animationCurveDataDic[realBoneName][i].scale.x = curve.keys[i].value;
                            break;
                        case "m_LocalScale.y":
                            animationCurveDataDic[realBoneName][i].scale.y = curve.keys[i].value;
                            break;
                        case "m_LocalScale.z":
                            animationCurveDataDic[realBoneName][i].scale.z = curve.keys[i].value;
                            break;
                    }
                }    
            }
        }
    }
    

    public void PlayAnimationUsingAnimationClip()
    {
        animationClip.SampleAnimation(gameObject, timer);
    }

    public void PlayAnimationUsingSampleClip()
    {
        animationClip.SampleAnimation(gameObject, animationClip.length / 2.0f);
        Debug.Log("clip length " + animationClip.length); 
        Debug.Log("frame rate " + animationClip.frameRate);
        //animationClip.SampleAnimation(this.gameObject, animationClip.length);
    }
    
    public void ResetToBindPose()
    {
        Vector3 OldPosition = new Vector3(this.transform.position.x, this.transform.position.y, this.transform.position.z);
        Vector3 OldScale = new Vector3(this.transform.localScale.x, this.transform.localScale.y, this.transform.localScale.z);
        Quaternion OldRotation = new Quaternion(this.transform.rotation.x, this.transform.rotation.y, this.transform.rotation.z, this.transform.rotation.w);
        Transform currPrefabTransform = this.transform;
        SkinnedMeshRenderer currSkinnedMeshRenderer = this.gameObject.GetComponentInChildren<SkinnedMeshRenderer>();
        if (currSkinnedMeshRenderer == null)
        {
            Debug.LogError("Doesn't find SkinMesh Renderer");
        }
        
        Matrix4x4[] bindposesSet = currSkinnedMeshRenderer.sharedMesh.bindposes;
        Transform[] bonesSet = currSkinnedMeshRenderer.bones;
        Debug.Log("Bone Count: " + bonesSet.Length);
        //提取bonesSet的名字以及默认的序号
        Dictionary<string, int> bonesSetMap = new Dictionary<string, int>();
        for (int i = 0; i < bonesSet.Length; i++)
        {
            if (!bonesSetMap.ContainsKey(bonesSet[i].name))
            {
                bonesSetMap[bonesSet[i].name] = i;
            }
        }
        
        // 得到的是一个乱序的， 我们直接按照transform 设置就可以了,transform中的骨骼有主从顺序。
        // 我的bindPose记录的相当于是我当前骨骼的 worldToLocal * prefab.localToWorld;
        // 但是这个记录似乎是非传递性的，就是只是记录的这一个节点，针对于上一个节点的位置变化关系.
        // 在更新的时候，BindPose中的matrix代表当前骨骼节点的Tpose变换，是基于上一个父节点的。
        // 所以需要先将父节点还原，再还原子节点。。
        Transform[] trans = this.GetComponentsInChildren<Transform>();
        foreach (var currTransform in trans)
        {
            Matrix4x4 matrix;
            if (!bonesSetMap.ContainsKey(currTransform.name))
            {
                Debug.Log("Unused Bone" + currTransform.name);
                matrix = Matrix4x4.identity.inverse;
            }
            else
            {
                Matrix4x4 bindPoseWorldToLocalmatrix = bindposesSet[bonesSetMap[currTransform.name]];
                Quaternion worldToModelQuaternion = Quaternion.LookRotation(Vector3.up, Vector3.back);
                Matrix4x4 worldToModel = Matrix4x4.TRS(Vector3.zero, worldToModelQuaternion, Vector3.one);
                matrix = worldToModel * bindPoseWorldToLocalmatrix.inverse;;
            }

            currTransform.position = matrix.GetColumn(3);
            currTransform.rotation = Quaternion.LookRotation(matrix.GetColumn(2), matrix.GetColumn(1));
            currTransform.localScale = new Vector3(
                matrix.GetColumn(0).magnitude,
                matrix.GetColumn(1).magnitude,
                matrix.GetColumn(2).magnitude
            );
        }

        this.transform.position = OldPosition;
        this.transform.localScale = OldScale;
        this.transform.rotation = OldRotation;
    }

    IEnumerator PlayAttachAnimation()
    {
        float currTimer = 0.0f;
        while (true)
        {
            animationClip.SampleAnimation(gameObject, currTimer);
            currTimer += Time.deltaTime;
            yield return null;
            if (currTimer > animationClip.length) currTimer = 0;
        }
    }
}

[CustomEditor(typeof(CPUSkinAnimation))]
public class CPUSkinAnimationEditor : Editor
{
    public override void OnInspectorGUI()
    {
        CPUSkinAnimation script = target as CPUSkinAnimation;
        base.OnInspectorGUI();
        if (GUILayout.Button("Play Animation using SampleClip"))
        {
            script.PlayAnimationUsingSampleClip();
        } 
        if (GUILayout.Button("Reset To Bind Pose"))
        {
            script.ResetToBindPose();
        }
    }
}