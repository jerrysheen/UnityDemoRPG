using UnityEngine;

[System.Serializable]
public class TextureAnimationClip
{
	public string name;
	public int pixelStartIndex;
	
	// 目前这个字段用于判断是否循环，0循环，非0不循环;
	// public int loopStartFrame;
	
	public int frameCount;
	public int frameRate;
	// public float length;
	public bool isLoop;
	public Bone[] bones;
	[System.Serializable]
	public class Bone
	{
		public string boneName;
		public Matrix4x4[] frames;
	}
}
