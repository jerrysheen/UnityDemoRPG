using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[ExecuteInEditMode]
public class AnimationSampler : MonoBehaviour
{

    public int frameIndex = 0;
    public bool isPlaying = false;
    public int currIndex = 0;
    public float currAnimTime = 0.0f;
    public AnimationClip clip;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (isPlaying)
        {
            currAnimTime += Time.deltaTime;
            
            // 判断有没有超过length:
            if (currAnimTime >= clip.length)
            {
                currAnimTime = 0.0f;
                isPlaying = false;
            }
            else
            {
                currIndex = (int)(currAnimTime * clip.frameRate);
                SampleAnimation(currIndex);
            }
        }
    }

    
    public void SampleAnimation(float currIndex)
    {
        if (clip == null)
        {
            Debug.LogError("Error, Please Assign animationClip");
        }
        Debug.Log("Clip Length : " + clip.length);
        Debug.Log("Clip frameRate : " + clip.frameRate);
        float timer = currIndex / clip.frameRate;
        timer = Mathf.Min(timer, clip.length);
        clip.SampleAnimation(this.gameObject, timer);
    }
    
}

[CustomEditor(typeof(AnimationSampler))]
public class AnimationSamplerEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        AnimationSampler script = target as AnimationSampler;
        if (GUILayout.Button("Sample Animation"))
        {
            script.isPlaying = true;
        }
        
        if (GUILayout.Button("Sample Frame"))
        {
            script.SampleAnimation(script.frameIndex);
        }
    }
}
