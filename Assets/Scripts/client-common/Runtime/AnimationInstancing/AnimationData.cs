using UnityEngine;

[System.Serializable]
public class AnimationData : ScriptableObject{
	public int boneCount;
	public string[] exportBoneName;
	public Texture2D[] animaTexture;
	public TextureAnimationClip[] clips;
}
