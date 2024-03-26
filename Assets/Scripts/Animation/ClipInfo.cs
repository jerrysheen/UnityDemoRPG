using UnityEditor;
using UnityEngine;

// Editor window for listing all float curves in an animation clip
public class ClipInfo : EditorWindow
{
    private AnimationClip clip;

    [MenuItem("Test/Clip Info")]
    static void Init()
    {
        GetWindow(typeof(ClipInfo));
    }

    public void OnGUI()
    {
        clip = EditorGUILayout.ObjectField("Clip", clip, typeof(AnimationClip), false) as AnimationClip;

        EditorGUILayout.LabelField("Curves:");
        if (clip != null)
        {
            foreach (var binding in AnimationUtility.GetCurveBindings(clip))
            {
                AnimationCurve curve = AnimationUtility.GetEditorCurve(clip, binding);
                //if(binding.propertyName == "m_LocalPosition.x")
                if(binding.propertyName == "m_LocalScale.x")
                EditorGUILayout.LabelField(binding.path + "||| PropertyName: " + binding.propertyName + "|||  Keys: " + curve.keys[0].value);
                
            }
        }
    }
}