using System.Collections.Generic;
using System.IO;
//using ELEX.Resource;
using UnityEngine;
using UnityEditor;
//using YooAsset.Editor;

public class TextureAnimationExporter:Editor
{

	private static string s_materialsFolderPath;
	private static string s_shaderName = "Faster/Character/AnimationInstance";
	private static Dictionary<string, int> s_indexMap;
	private static Matrix4x4[] s_bonePos;
	private static AnimationData s_animationData;
#if ENABLE_ELEX_ECS
	private static bool s_isEcs;
	private static string s_extNameEcs = "_ecs";
	private static string s_materialsFolderPathEcs;
	private static string s_shaderNameEcs = "Faster/Character/ECS_AnimationInstanceLit";
#endif
	
	[MenuItem("Assets/【GPU Animation】烘焙动作骨点到贴图，并加入Game_Prefab", priority = 101)]
	public static void Export()
	{
#if ENABLE_ELEX_ECS
		s_isEcs = false;
#endif
		//EditorCommon.ClearConsole();
		Object[] SelectionAsset = Selection.GetFiltered(typeof(Object), SelectionMode.Assets);

		foreach(Object obj in SelectionAsset)
		{
			string folder = AssetDatabase.GetAssetPath(obj);
			DealAnimationFolder(folder);
		}
        
		EditorUtility.DisplayDialog("提示", "操作成功", "知道了");
		//
		// var objs = Selection.objects;
		// if (objs==null||objs.Length<=0)
  //       {
		// 	return;
  //       }
		//
		// Debug.Log(objs[0].name);
		// foreach(GameObject obj in objs)
  //       {
	 //        
  //
		// 	Animation anim = obj.GetComponent<Animation>();
		//
		// 	if (anim==null)
  //           {
		// 		continue;
  //           }
		// 	ExportAnimation(obj);
		// }

        #region
        // foreach(Object selection in Selection.objects){
        // 	if(selection is DefaultAsset){
        // 		string path=AssetDatabase.GetAssetPath(selection);
        // 		GameObject prefab=LoadPrefabOrFBX(path+"/"+selection.name);
        // 		if(prefab.transform.childCount>0){
        // 			ExportAnimation(prefab);
        // 		}
        // 	}
        // }
        #endregion
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }
	
#if ENABLE_ELEX_ECS
	[MenuItem("Assets/【模型】烘焙动作骨点到贴图，并加入Game_Prefab【ECS】", priority = 101)]
	public static void ExportEcs()
	{
		s_isEcs = true;
		EditorCommon.ClearConsole();
		Object[] SelectionAsset = Selection.GetFiltered(typeof(Object), SelectionMode.Assets);
		foreach(Object obj in SelectionAsset)
		{
			string folder = AssetDatabase.GetAssetPath(obj);
			DealAnimationFolder(folder);
		}
        
		EditorUtility.DisplayDialog("提示", "操作成功", "知道了");
		AssetDatabase.SaveAssets();
		AssetDatabase.Refresh();
	}
#endif
	
	static void DealAnimationFolder(string folder)
	{
		string[] anim_files = Directory.GetFiles(folder + "/anim_combine", "*.anim");
		string[] prefab_files = Directory.GetFiles(folder + "/prefab", "*.prefab");
		if (anim_files.Length <= 0 || prefab_files.Length <= 0)
		{
			EditorUtility.DisplayDialog("错误", "未找到动作文件或模型预制体", "知道了");
			return; 
		}

		// 加载所有动画资源
		Debug.Log("加载所有动画资源");
		List<AnimationClip> animationClips = new List<AnimationClip>();
		foreach (string anim_file in anim_files)
		{
			AnimationClip animClip = AssetDatabase.LoadAssetAtPath<AnimationClip>(anim_file);
			if (animClip == null) continue;
			animationClips.Add(animClip);
		}

		// 先烘焙一次动画，规范上同一共用动画的模型骨点也一样，只用烘焙一次
		Debug.Log("先烘焙一次动画，规范上同一共用动画的模型骨点也一样，只用烘焙一次");
		GameObject gameObj = AssetDatabase.LoadAssetAtPath<GameObject>(prefab_files[0]);
		Texture2D tex = ExportAnimation(gameObj, animationClips);
		if (tex == null)
		{
			Debug.LogError("ExportAnimation fail");
			return;
		}
		// 同骨骼不同模型分别处理网格和材质
		foreach (var prefab_file in prefab_files)
		{
			gameObj = AssetDatabase.LoadAssetAtPath<GameObject>(prefab_file);
			ExportMaterial(gameObj, tex);
		}
	}

	private static Texture2D ExportAnimation(GameObject prefab, List<AnimationClip> animationClips = null)
	{
		string prefabPath = AssetDatabase.GetAssetPath(prefab);
		string rawFolderPath = Path.GetDirectoryName(prefabPath);
		//string outFolderPath = rawFolderPath.Replace("Res","Resources");
		// 创建材质文件夹
		s_materialsFolderPath = rawFolderPath + "/materials";
		if(!Directory.Exists(s_materialsFolderPath))
		{
			Directory.CreateDirectory(s_materialsFolderPath);
		}
		
#if ENABLE_ELEX_ECS
		// 创建ecs专用的材质文件夹
		if (s_isEcs)
		{
			s_materialsFolderPathEcs = rawFolderPath + "/materials/ecs";
			if(!Directory.Exists(s_materialsFolderPathEcs))
			{
				Directory.CreateDirectory(s_materialsFolderPathEcs);
			}
		}
#endif

		AnimationData animationData = CreateInstance<AnimationData>();
		/// 获取要导出的逻辑骨骼;
		List<string> exportBoneNameList = new List<string>();
		CharacterBoneInfo boneInfo = prefab.GetComponent<CharacterBoneInfo>();
		if (boneInfo != null && boneInfo.m_BoneArray != null)
		{
			animationData.exportBoneName = new string[boneInfo.m_BoneArray.Length];
			for (int i = 0; i < boneInfo.m_BoneArray.Length; i++)
			{
				Transform tran = boneInfo.m_BoneArray[i];
				if (tran != null)
				{
					animationData.exportBoneName[i] = tran.name;
					exportBoneNameList.Add(tran.name);
				}
			}
		}
		
		//todo 修改获得骨骼父节点的方法不用chinld_0
		GameObject gameObject = Instantiate(prefab);
		Transform[] children = gameObject.transform.GetChild(0).GetComponentsInChildren<Transform>();
		Dictionary<string,int> indexMap = new Dictionary<string,int>();
		int boneCount = children.Length;
		Matrix4x4[] bonePoses=new Matrix4x4[boneCount];
		Matrix4x4[] bindPoses=new Matrix4x4[boneCount];
        DualQuaternion[] bindDQ = new DualQuaternion[boneCount];

        // 记录有多少骨骼数;
        animationData.boneCount = boneCount;

        for (int i = 0; i < boneCount; i++)
        {
            Transform child = children[i];
            indexMap.Add(child.name, i);
            bonePoses[i] = child.transform.localToWorldMatrix;
            bindPoses[i] = child.transform.worldToLocalMatrix * prefab.transform.localToWorldMatrix;
            bindDQ[i] = new DualQuaternion(bindPoses[i].ExtractRotation(), bindPoses[i].ExtractPosition());
        }
		
		s_indexMap = indexMap;
		s_bonePos = bonePoses;
		s_animationData = animationData;
		
		// 获取依赖的 AnimationClip;
		if (animationClips == null)
		{
			animationClips = new List<AnimationClip>();
			var component = prefab.GetComponent<Animation>();
			if(component == null && component.GetClipCount() <= 0)
			{
				Debug.LogError("not find animation componet at" + prefab.name);
				return null;
			}
			foreach(AnimationState state in component)
			{
				var clip = component.GetClip(state.name);
				if (clip!=null)
				{
					animationClips.Add(clip);
				}
			}
		}

		int pixelStartIndex = boneCount * 2;
		int clipCount = animationClips.Count;
		
		TextureAnimationClip[] clips = new TextureAnimationClip[clipCount];
		animationData.clips = clips;
        
		int pixelIndex = 0;
		for(int i=0; i < clipCount; i++)
		{
			AnimationClip animationClip = animationClips[i];
			TextureAnimationClip clip = new TextureAnimationClip();
			clips[i] = clip;
			clip.name = animationClip.name;
			clip.frameRate = Mathf.RoundToInt(animationClip.frameRate);//帧率
			clip.frameCount = Mathf.RoundToInt(animationClip.length * clip.frameRate);//总帧数量=时间*速率
			// clip.loopStartFrame = animationClip.isLooping ? 0:1;
			clip.isLoop = animationClip.isLooping;
			// clip.length = animationClip.length; //(float)clip.frameCount/clip.frameRate;
			clip.pixelStartIndex = pixelStartIndex;
			pixelStartIndex += clip.frameCount*boneCount*2;
			
			/// 只导出我们想要的骨骼数据;
			TextureAnimationClip.Bone[] clipBones = new TextureAnimationClip.Bone[exportBoneNameList.Count];
			clip.bones = clipBones;
			//创建GpuAnimationClip bone[]
			for (int b= 0; b < clipBones.Length; b++)
			{
				TextureAnimationClip.Bone boneData = new TextureAnimationClip.Bone();
				boneData.boneName = exportBoneNameList[b];
				boneData.frames = new Matrix4x4[clip.frameCount];
				clipBones[b] = boneData;
			}
		}

		// 算需要的最小像素, 128 / 256 ?
		int textureW = 2;
		int textureH = 2;
		while( textureW *textureH <pixelStartIndex)
		{
			if (textureW <= textureH)
			{
				textureW *= 2;
			}
			else
			{
				textureH *= 2;
			}
		}
        Texture2D texture = new Texture2D(textureW , textureH, TextureFormat.RGBAHalf, false, true);
		texture.filterMode = FilterMode.Point;

        Color[] pixels = texture.GetPixels();

        for (int b = 0; b < boneCount; b++)
        {
            var coc = children[b].transform.GetLocalToWorldDQ();
            var dq = bindDQ[b] * coc;// DualQuaternionFromMatrix4x4(m);
            pixels[pixelIndex++] = new Color(dq.real.x, dq.real.y, dq.real.z, dq.real.w);
            pixels[pixelIndex++] = new Color(dq.dual.x, dq.dual.y, dq.dual.z, dq.real.w);
        }

		for(int c=0; c < clipCount; c++)
		{
			TextureAnimationClip clip = clips[c];
			AnimationClip animationClip = animationClips[c];
			EditorCurveBinding[] curveBindings = AnimationUtility.GetCurveBindings(animationClip);

			HashSet<string> positionPathHash = new HashSet<string>();
			HashSet<string> rotationPathHash = new HashSet<string>();
			HashSet<string> scalePathHash = new HashSet<string>();
			foreach(EditorCurveBinding curveBinding in curveBindings)
			{
				string path=curveBinding.path;
				string propertyName=curveBinding.propertyName;
				if(propertyName.Length==17)
				{
					string propertyPrefix=propertyName.Substring(0,15);
					if(propertyPrefix=="m_LocalPosition")
					{
						if(!positionPathHash.Contains(path))
						{
							positionPathHash.Add(path);
						}
					}
					else if(propertyPrefix=="m_LocalRotation")
					{
						if(!rotationPathHash.Contains(path))
						{
							rotationPathHash.Add(path);
						}
					}
					else if(propertyPrefix=="m_LocalScale")
					{
						if(!scalePathHash.Contains(path))
						{
							scalePathHash.Add(path);
						}
					}
				}
			}

			for(int f=0; f < clip.frameCount; f++)
			{
				float time = (float) f / clip.frameRate;
				//获取动画local位置曲线
				foreach (string path in positionPathHash)
				{
					string boneName=path.Substring(path.LastIndexOf('/')+1);
					if(indexMap.ContainsKey(boneName))
					{
						Transform child=children[indexMap[boneName]];
						float positionX=GetCurveValue(animationClip,path,"m_LocalPosition.x",time);
						float positionY=GetCurveValue(animationClip,path,"m_LocalPosition.y",time);
						float positionZ=GetCurveValue(animationClip,path,"m_LocalPosition.z",time);
						child.localPosition=new Vector3(positionX,positionY,positionZ);
					}
				}
				//获取动画local旋转曲线
				foreach(string path in rotationPathHash)
				{
					string boneName=path.Substring(path.LastIndexOf('/')+1);
					if(indexMap.ContainsKey(boneName))
					{
						Transform child=children[indexMap[boneName]];
						float rotationX=GetCurveValue(animationClip,path,"m_LocalRotation.x",time);
						float rotationY=GetCurveValue(animationClip,path,"m_LocalRotation.y",time);
						float rotationZ=GetCurveValue(animationClip,path,"m_LocalRotation.z",time);
						float rotationW=GetCurveValue(animationClip,path,"m_LocalRotation.w",time);
						Quaternion rotation=new Quaternion(rotationX,rotationY,rotationZ,rotationW);
						child.localRotation=rotation;
					}
				}
				//获取动画local位置曲线
				foreach (string path in scalePathHash)
				{
					string boneName=path.Substring(path.LastIndexOf('/')+1);
					if(indexMap.ContainsKey(boneName))
					{
						Transform child=children[indexMap[boneName]];
						float positionX=GetCurveValue(animationClip,path,"m_LocalScale.x",time);
						float positionY=GetCurveValue(animationClip,path,"m_LocalScale.y",time);
						float positionZ=GetCurveValue(animationClip,path,"m_LocalScale.z",time);
						child.localScale = new Vector3(positionX,positionY,positionZ);
					}
				}
				
				//设置贴图为骨骼transform的worldmatrix*bindpos(bone.worldToLocalMatrix)
                for (int b = 0; b < boneCount; b++)
                {
	                Transform childTran = children[b];

	                var parDQ = prefab.transform.GetWorldToLocalDQ();
	                var coc = childTran.GetLocalToWorldDQ();
	                var c2 = parDQ * coc * bindDQ[b];
	                
	                for (int index = 0; index < clip.bones.Length; index++)
	                {
		                TextureAnimationClip.Bone boneData = clip.bones[index];
		                if (boneData.boneName == childTran.name)
		                {
			                boneData.frames[f] = Matrix4x4.TRS(childTran.position, childTran.rotation, childTran.lossyScale);
		                }
	                }

	                pixels[pixelIndex++] = new Color(c2.real.x, c2.real.y, c2.real.z, c2.real.w);
                    pixels[pixelIndex++] = new Color(c2.dual.x, c2.dual.y, c2.dual.z, c2.dual.w);
                }
			}
		}
		
		texture.SetPixels(pixels); // 保存贴图
		texture.Apply();
		AssetDatabase.CreateAsset(texture, s_materialsFolderPath + "/" + "tex_skinning.asset");
		string assetDataPath = s_materialsFolderPath + "/animation_data.asset";
		AssetDatabase.CreateAsset(animationData, assetDataPath);
//		AssetDatabase.AddObjectToAsset(texture, assetDataPath);
		DestroyImmediate(gameObject);
		return texture;
	}
	
	private static Transform GetRootBone(GameObject gameObject)
	{
		var skinmeshRenderer = gameObject.GetComponentInChildren<SkinnedMeshRenderer>();
		if (skinmeshRenderer == null)
			return null;
		return skinmeshRenderer.rootBone;
	}

	
	public static void ExportMaterial(GameObject prefab, Texture2D texture)
	{
		Debug.Log("ExportMaterial");
		var shaderName = s_shaderName;
		var prfabName = prefab.name.ToLower();
#if ENABLE_ELEX_ECS // ECS相关的额外处理
		if (s_isEcs)
		{
			prfabName += s_extNameEcs; // 导出ecs的预制体防止重名
			shaderName = s_shaderNameEcs; // ecs专用shader
		}
#endif
//		var commonMask = AssetDatabase.LoadAssetAtPath<Texture>(ResourceConfig.ResCfg.ArtsPath + "character/soldier/common_mask.png");
		var indexMap = s_indexMap;
		var bonePoses = s_bonePos;
		var animationData = s_animationData;
		GameObject gameObject = Instantiate(prefab);
		Transform[] children = gameObject.transform.GetChild(0).GetComponentsInChildren<Transform>();
		
		//设置newmesh  boneindex/weight
		
		AnimationInstancing animation = new GameObject().AddComponent<AnimationInstancing>();
		animation.data = animationData;
		animation._curclipName = "stand";

		Dictionary<Mesh,Mesh> meshMap = new Dictionary<Mesh,Mesh>();
		Dictionary<Material,Material> materialMap = new Dictionary<Material,Material>();
		SkinnedMeshRenderer[] skinnedMeshRenderers = gameObject.GetComponentsInChildren<SkinnedMeshRenderer>();
		for(int p=0;p<skinnedMeshRenderers.Length;p++){
			SkinnedMeshRenderer skinnedMeshRenderer = skinnedMeshRenderers[p];
			Mesh sharedMesh = skinnedMeshRenderer.sharedMesh;
			Mesh newMesh;
			if (sharedMesh == null){
				EditorUtility.DisplayDialog("提示", "sharedMesh 不存在！ " + gameObject.name, "知道了");
				continue;
			}
			if(meshMap.ContainsKey(sharedMesh)){
				newMesh = meshMap[sharedMesh];
			}
			else{
				Transform[] transforms = skinnedMeshRenderer.bones;
				int vertexCount = sharedMesh.vertexCount;
				List<Vector4> indices = new List<Vector4>();
				List<Vector4> weights = new List<Vector4>();
				Vector3[] vertices = new Vector3[sharedMesh.vertices.Length];
				Vector3[] normals = new Vector3[sharedMesh.normals.Length];
				Vector4[] tangents = new Vector4[sharedMesh.tangents.Length];
				
				// 乘上这个矩阵是为了摆正模型在世界空间里面的姿态。
				Matrix4x4 meshMatrix = bonePoses[indexMap[transforms[0].name]]*sharedMesh.bindposes[0];
				BoneWeight[] boneWeights = sharedMesh.boneWeights;
				for(int v=0; v<vertexCount; v++)
				{
					//设置顶点的骨骼权重
					BoneWeight weight = boneWeights[v];
					float totalWeight = weight.weight0 + weight.weight1;
					float weight0 = weight.weight0 / totalWeight;
					float weight1 = weight.weight1 / totalWeight;
					float weight2 = weight.weight2;
					float weight3 = weight.weight3;
					//设置顶点的骨骼的index
					int boneIndex0 = indexMap[transforms[weight.boneIndex0].name];
					int boneIndex1 = indexMap[transforms[weight.boneIndex1].name];
					int boneIndex2 = indexMap[transforms[weight.boneIndex2].name];
					int boneIndex3 = indexMap[transforms[weight.boneIndex3].name];
					indices.Add(new Vector4(boneIndex0,boneIndex1,boneIndex2,boneIndex3));
					weights.Add(new Vector4(weight0,weight1,weight2,weight3));
					if(v < vertices.Length)
						vertices[v] = meshMatrix * sharedMesh.vertices[v];
					if(v < normals.Length)
						normals[v] = meshMatrix * sharedMesh.normals[v];
					if(v < tangents.Length)
						tangents[v]=meshMatrix * sharedMesh.tangents[v];
					weight.boneIndex0 = boneIndex0;
					weight.boneIndex1 = boneIndex1;
					weight.boneIndex2 = boneIndex2;
					weight.boneIndex3 = boneIndex3;
					boneWeights[v] = weight;
				}
				newMesh = new Mesh();
				newMesh.vertices = vertices;
				newMesh.normals = normals;
				newMesh.tangents = tangents;
				newMesh.triangles = sharedMesh.triangles;
				newMesh.uv = sharedMesh.uv;
				newMesh.SetUVs(3,indices);
				newMesh.SetUVs(4,weights);
				skinnedMeshRenderer.bones = children;
				skinnedMeshRenderer.sharedMesh = newMesh;
				AssetDatabase.CreateAsset(newMesh,s_materialsFolderPath + "/" + prefab.name + ".asset");
				Debug.Log("new mesh place : " + s_materialsFolderPath + "/" + prefab.name + ".asset");
				meshMap.Add(sharedMesh, newMesh);
			}

			//export new material for animationtexture
			Material sharedMaterial=skinnedMeshRenderer.sharedMaterial;
			Material newMaterial;
			if(materialMap.ContainsKey(sharedMaterial)){
				newMaterial = materialMap[sharedMaterial];
			}else {
				// 先加载现有的材质资源，防止覆盖掉已经调整好参数的材质；ecs材质和传统材质需要区分开，因为使用的shader不一样
				string materialPath = s_materialsFolderPath; // 传统材质路径
#if ENABLE_ELEX_ECS
				if (s_isEcs)
				{
					materialPath = s_materialsFolderPathEcs; // ecs版本材质路径
				}
#endif
				materialPath += "/" + sharedMaterial.name + ".mat";
				newMaterial = AssetDatabase.LoadAssetAtPath<Material>(materialPath);
				if (newMaterial == null)
				{
					newMaterial = new Material(Shader.Find(shaderName));
					AssetDatabase.CreateAsset(newMaterial, materialPath);
				}

				if (newMaterial.shader == null || newMaterial.shader.name != shaderName)
				{
					newMaterial.shader = Shader.Find(shaderName);
				}

				animationData.animaTexture = new Texture2D[] {texture};
				// 材质信息处理
				newMaterial.mainTexture = sharedMaterial.mainTexture; // 主贴图复制
				newMaterial.SetTexture("_SkinningTex", texture); // 烘焙动作的贴图复制
//#if ENABLE_ELEX_ECS
//				if (s_isEcs)
//				{
					if (newMaterial.HasProperty("_SkinningTexSize"))
					{
						newMaterial.SetVector("_SkinningTexSize", new Vector4(texture.width, texture.height, 1, 1));
						
					}
//				}
//#endif
//				newMaterial.SetFloat("_SkinningTexW", texture.width);
//				newMaterial.SetFloat("_SkinningTexH", texture.height);
//				animationData.animaTexInfo.Add(texture,new Vector2(texture.width,texture.h));
				// 检查染色遮罩是否正常
				string maskTexName = "_MaskTex";
				if (newMaterial.HasProperty(maskTexName))
				{
					Texture tex = newMaterial.GetTexture(maskTexName);
					if (tex == null)
					{
						newMaterial.SetTexture(maskTexName, Texture2D.blackTexture); // commonMask
					}
				}
				newMaterial.enableInstancing = true;
				materialMap.Add(sharedMaterial,newMaterial);
			}
			
			GameObject partGameObject = new GameObject(skinnedMeshRenderer.name);
			MeshFilter meshFilter = partGameObject.AddComponent<MeshFilter>();
			meshFilter.sharedMesh = newMesh;
			MeshRenderer meshRenderer = partGameObject.AddComponent<MeshRenderer>();
			meshRenderer.sharedMaterial = newMaterial;
			meshRenderer.lightProbeUsage = skinnedMeshRenderer.lightProbeUsage;
			meshRenderer.reflectionProbeUsage = skinnedMeshRenderer.reflectionProbeUsage;
			meshRenderer.shadowCastingMode = skinnedMeshRenderer.shadowCastingMode;
			meshRenderer.receiveShadows = skinnedMeshRenderer.receiveShadows;
//			PrefabUtility.CreatePrefab(materialsFolderPath + "/" + skinnedMeshRenderer.name + ".prefab", partGameObject);
#if ENABLE_ELEX_ECS // ECS相关的额外处理
			if (s_isEcs)
			{
				// 拷贝阴影材质保存脚本
				var comp = skinnedMeshRenderer.GetComponent<Elex.ECS.SoldierRenderAuthoring>();
				if (comp != null)
				{
					var newComp = partGameObject.AddComponent<Elex.ECS.SoldierRenderAuthoring>();
					newComp.ShadowMaterial = comp.ShadowMaterial;
				}
			}
#endif
			partGameObject.transform.SetParent(animation.transform,false);
		}
		
		//PrefabUtility.CreatePrefab(AssetBundleCollectorSettingData.ModelPackPath() + "/" + prfabName + ".prefab", animation.gameObject);
				
		string prefabPath = AssetDatabase.GetAssetPath(prefab);
		string rawFolderPath = Path.GetDirectoryName(prefabPath);
		string AnimationPath = rawFolderPath + "/" + "GPUAnimation_" + prfabName ; // 设置你的目录路径

		// 检查目录是否存在
		if (Directory.Exists(AnimationPath))
		{
			// 清除目录中的所有内容
			DirectoryInfo directory = new DirectoryInfo(AnimationPath);
			foreach (FileInfo file in directory.GetFiles()) file.Delete();
			foreach (DirectoryInfo subDirectory in directory.GetDirectories()) subDirectory.Delete(true);
		}
		else
		{
			// 如果目录不存在，创建它
			Directory.CreateDirectory(AnimationPath);
		}

		// 刷新Unity编辑器
		AssetDatabase.Refresh();

		PrefabUtility.CreatePrefab(AnimationPath + "/" + prfabName + "@gpuAnim.prefab", animation.gameObject);
		DestroyImmediate(animation.gameObject);
		DestroyImmediate(gameObject);
	}

	private static float GetCurveValue(AnimationClip clip,string path,string prop,float time){
		EditorCurveBinding binding=EditorCurveBinding.FloatCurve(path,typeof(Transform),prop);
		return AnimationUtility.GetEditorCurve(clip,binding).Evaluate(time);
	}
	
	public static GameObject LoadPrefabOrFBX(string path){
		GameObject prefab=AssetDatabase.LoadAssetAtPath<GameObject>(string.Format("{0}.prefab",path));
		if(prefab==null){
			prefab=AssetDatabase.LoadAssetAtPath<GameObject>(string.Format("{0}.FBX",path));
		}
		return prefab;
	}

	public static void Print(params object[] messages){
		string[] strings=new string[messages.Length];
		for(int i=0;i<strings.Length;i++){
			strings[i]=messages[i]==null?"null":messages[i].ToString();
		}
		Debug.Log(string.Join("|",strings));
	}
}
