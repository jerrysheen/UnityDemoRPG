using System;
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
    public Transform rootBoneTransform;

    private SkinnedMeshRenderer currSkinMeshRenderer;
    private Mesh sharedMesh;
    private Transform[] bones;
    private Matrix4x4[] bindPose;
    private BoneWeight[] boneWeights;
    private Matrix4x4[] tposeWorldToLocalMatrixSet;
    private Dictionary<string, AnimationCurveStruct[]> animationCurveDataDic;
    private Dictionary<string, int> bonesIndexMap;
    private Dictionary<string, Matrix4x4> currLocalToWorldDic;
    private Dictionary<int, int> transformNameToBone;
    private Vector3[] originalVertices;
    private float currFrame = 0;

    private Vector3[] verticesLocalPosition;
    public GameObject targetMeshAnimGO;
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
        originalVertices = targetMeshAnimGO.GetComponent<MeshFilter>().sharedMesh.vertices; 
        bones = currSkinMeshRenderer.bones;
        bindPose = sharedMesh.bindposes;
        boneWeights = sharedMesh.boneWeights;
        //currentTransform 在开始的时候等于bones初始姿态
        transformNameToBone = new Dictionary<int, int>();
        animationCurveDataDic = new Dictionary<string, AnimationCurveStruct[]>();
        
        ConstructOffsetMatrix();
        CalculateBoneIndex();
        
        //CalculateBindPoseSkin();
        
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
        
        currFrame += Time.deltaTime * animationClip.frameRate;
        if (timer > animationClip.length) timer = 0;
    }

    private void OnApplicationQuit()
    {
        Debug.Log("Game End");
        targetMeshAnimGO.GetComponent<MeshFilter>().sharedMesh.vertices = originalVertices; 
    }

    public void PlayAnimationUsingCpuSkinAnimation(float frame)
    {
        // 首先移动骨骼到位置
        CalculateCurrentBonePose(frame);
        
        // 接下来取到sharedmesh,并且重新生成
        // 第一步，取到，让蒙皮不动起来
        //
        CalculateSkinMesh();


    }

    public void CalculateCurrentBonePose(float frame)
    {
        currLocalToWorldDic = new Dictionary<string, Matrix4x4>();
        
        int frameCount = (int)(animationClip.frameRate * animationClip.length);
        frame %= frameCount;
        frame = (int) frame;
        // 当前的frame，根据主从关系遍历所有骨骼
        Transform[] trans = rootBoneTransform.GetComponentsInChildren<Transform>();
        int index = 0;

        // 后来发现，动画数据记录的其实就是每一帧的骨骼的localTransformation，每一帧计算骨点的位置，只要直接取这个数据，还原到
        // localpositon,rotation里面就好了
        foreach (var currTransform in trans)
        {
            AnimationCurveStruct currStruct;
            if (!animationCurveDataDic.ContainsKey(currTransform.name))
            {
                currStruct.position = Vector3.zero;
                currStruct.rotation = Quaternion.identity;
                currStruct.scale = Vector3.one;
            }
            else
            {
                currStruct = animationCurveDataDic[currTransform.name][(int)frame];
            }
            
            currTransform.localPosition = currStruct.position;
            currTransform.localRotation = currStruct.rotation;
            currTransform.localScale = currStruct.scale;
        
            currLocalToWorldDic[currTransform.name] = currTransform.localToWorldMatrix;
        }
    }

    // 这个地方，实际上基本的算法很简单，每个顶点的位置都是相对于绑定空间的。
    // 利用bindPose matrix，把位置从模型空间转到boneLocal空间。
    // 然后这个时候顶点相对于骨骼有一个相对位置，之后不管我的骨骼怎么运动，顶点都会在这个固定的相对位置下跟随骨骼运动。
    // 运动完之后，需要把这个顶点乘回世界空间，就是乘上做了动画之后的骨骼矩阵的localToWorld。
    // 混合就相当于，对于同一个vertices，它受好几个 
    public void CalculateSkinMesh()
    {
        MeshFilter meshFilter = targetMeshAnimGO.GetComponent<MeshFilter>();
        Mesh originMesh = meshFilter.sharedMesh;
        Mesh tempMesh = new Mesh();
        Vector3[] NewVecticesGroup = new Vector3[originalVertices.Length];
        List<Vector4> weightList = new List<Vector4>();
        originMesh.GetUVs(4, weightList);
        List<Vector4> indexList = new List<Vector4>();
        originMesh.GetUVs(3, indexList);
        Transform[] transforms = currSkinMeshRenderer.bones;
        for (int i = 0; i < originalVertices.Length; i++)
        {
            float weight0 = weightList[i].x;
            float weight1 = weightList[i].y;
            float weight2 = weightList[i].z;
            float weight3 = weightList[i].w;
            // 获得顶点的对应的骨骼，我们需要完成的转化为: 原先的顶点，从BonePose转换到世界位置，再转换到local
            int boneIndex0 = (int)indexList[i].x;
            int boneIndex1 = (int)indexList[i].y;
            int boneIndex2 = (int)indexList[i].z;
            int boneIndex3 = (int)indexList[i].w;
            // 针对这个顶点，我需要先将他还原到BoneLocal，然后成乘上现在的位移矩阵，然后再混合权重。
            
            // 注意这个地方，一定要是vector4 的计算
            Vector4 currVertex =new Vector4(originalVertices[i].x, originalVertices[i].y, originalVertices[i].z, 1.0f);
            Vector3 resultVertex = Vector3.zero;
            try
            {
                // 这种做法哪里不对？ 改进一下
                // Vector3 blendA = currLocalToWorldDic[transforms[transformNameToBone[boneIndex0]].name] *
                //                  bindPose[transformNameToBone[boneIndex0]] * currVertex;
                // resultVertex += blendA * weight0;
                // Vector3 blendB = currLocalToWorldDic[transforms[transformNameToBone[boneIndex1]].name] *
                //                  bindPose[transformNameToBone[boneIndex1]] * currVertex;
                // resultVertex += blendB * weight1;
                // Vector3 blendC = currLocalToWorldDic[transforms[transformNameToBone[boneIndex2]].name] *
                //                  bindPose[transformNameToBone[boneIndex2]] * currVertex;
                // resultVertex += blendC * weight2;
                // Vector3 blendD = currLocalToWorldDic[transforms[transformNameToBone[boneIndex3]].name] *
                //                  bindPose[transformNameToBone[boneIndex3]] * currVertex;
                // resultVertex += blendD * weight3;
                
                // 这种做法是对的，这样不需要去考虑空间的问题，动画和bone都被还原到worldSpace底下做了。
                Vector3 blendA = currLocalToWorldDic[transforms[transformNameToBone[boneIndex0]].name] *
                                 tposeWorldToLocalMatrixSet[boneIndex0] * currVertex;
                resultVertex += blendA * weight0;
                Vector3 blendB = currLocalToWorldDic[transforms[transformNameToBone[boneIndex1]].name] *
                                 tposeWorldToLocalMatrixSet[boneIndex1] * currVertex;
                resultVertex += blendB * weight1;
                Vector3 blendC = currLocalToWorldDic[transforms[transformNameToBone[boneIndex2]].name] *
                                 tposeWorldToLocalMatrixSet[boneIndex2] * currVertex;
                resultVertex += blendC * weight2;
                Vector3 blendD = currLocalToWorldDic[transforms[transformNameToBone[boneIndex3]].name] *
                                 tposeWorldToLocalMatrixSet[boneIndex3] * currVertex;
                resultVertex += blendD * weight3;
                
                // Vector3 blendA =  bindPose[transformNameToBone[boneIndex0]].inverse *
                //                   tposeWorldToLocalMatrixSet[boneIndex0] * currVertex;
                // resultVertex += blendA * weight0;
                // Vector3 blendB = bindPose[transformNameToBone[boneIndex1]].inverse *
                //                  tposeWorldToLocalMatrixSet[boneIndex1] * currVertex;
                // resultVertex += blendB * weight1;
                // Vector3 blendC = bindPose[transformNameToBone[boneIndex2]].inverse *
                //                  tposeWorldToLocalMatrixSet[boneIndex2] * currVertex;
                // resultVertex += blendC * weight2;
                // Vector3 blendD = bindPose[transformNameToBone[boneIndex3]].inverse *
                //                  tposeWorldToLocalMatrixSet[boneIndex3]* currVertex;
                // resultVertex += blendD * weight3;
            }
            catch (IndexOutOfRangeException exp)
            {
                Debug.LogError("Error！ ： " + boneIndex0 + "Error！ ： " + boneIndex1 + "Error！ ： " + boneIndex2 +
                               "Error！ ： " + boneIndex3);
            }
            catch (KeyNotFoundException exp)
            {
                Debug.LogError("Error！ ： " + boneIndex0 + "Error！ ： " + boneIndex1 + "Error！ ： " + boneIndex2 +
                               "Error！ ： " + boneIndex3);
            }


            // Vector3 blendA = bindPose[boneIndex0].inverse * bindPose[boneIndex0] * currVertex;
            // resultVertex += blendA * weight0;
            // Vector3 blendB  = bindPose[boneIndex1].inverse * bindPose[boneIndex1] *currVertex;
            // resultVertex += blendB * weight1;
            // Vector3 blendC  =  bindPose[boneIndex2].inverse * bindPose[boneIndex2] *currVertex;
            // resultVertex += blendC * weight2;
            // Vector3 blendD  =  bindPose[boneIndex3].inverse * bindPose[boneIndex3] *currVertex;
            // resultVertex += blendD * weight3;
            NewVecticesGroup[i] = resultVertex;
            //NewVecticesGroup[i] = currVertex;

        }

        
        //currSkinMeshRenderer.sharedMesh = tempMesh;
        originMesh.vertices = NewVecticesGroup;
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

        Transform[] transformAll = rootBoneTransform.GetComponentsInChildren<Transform>();
        for (int i = 0; i < transformAll.Length; i++)
        {
            if (bonesIndexMap.ContainsKey(transformAll[i].name))
            {
                transformNameToBone[i] = bonesIndexMap[transformAll[i].name];
            }
        }

        tposeWorldToLocalMatrixSet = new Matrix4x4[transformAll.Length];
        for (int i = 0; i < tposeWorldToLocalMatrixSet.Length; i++)
        {
            tposeWorldToLocalMatrixSet[i] = transformAll[i].worldToLocalMatrix;
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