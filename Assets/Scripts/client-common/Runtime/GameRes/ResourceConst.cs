
using UnityEngine;
namespace ELEX.Resource
{
	public class ResourceConst
	{
		/// ----■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 资源路径定义 Start ■■■■■■■■■■■■■■■■■■■■■■■■■■■■
		// 打包路径;
		public const string BundlesRootPath = "bundles";
		public const string BundleExtensions = ".bundle";

		public const string PackResRoot = "PackResRoot";
		public const string ConfigZipName = "config.zip";
		
		// 这种文件夹下一定有个controller依赖了该文件夹中所有动作，会都打一块;
		public const string CombineAnimFolser = "anim_combine";
		
		public const string shaderVariants = "svc.shadervariants";

		/// ----■■■■■■■■■■■■■■■■■■■■■■■■■■■■ 资源路径定义 End ■■■■■■■■■■■■■■■■■■■■■■■■■■■■
		
		public const string PkgBundleBuildFolder = "_Build";

#if UNITY_ANDROID
		public const string PkgBundleFolder = "DataAndroid";
#elif UNITY_IPHONE
		public const string PkgBundleFolder = "DataIOS";
#elif UNITY_STANDALONE_WIN
		public const string PkgBundleFolder = "DataPC";
#elif UNITY_STANDALONE_OSX
		public const string PkgBundleFolder = "DataMAC";
#else
		public const string PkgBundleFolder = "DataPC";
#endif

		public const string PreBundleFolder = "PreDownload";
		
		// public const string LuaFolder = "lua";
		public const string ConfFolder = "data_dat";
		
		public const string SceneRoot_Low = "_res";
		public const string SceneRoot_Medium = "_medium";
		public const string SceneRoot_High = "_high";
        public const string SceneInfo_Root = "SceneNodeRefData";
        public const string ScenePath = "Assets/Scenes/level_process/";

		public const string FileListName = "filelist";

		//*******************************************************************

		public static string BundleFolder
		{
			get
			{
				switch (Application.platform)
				{
					case RuntimePlatform.WindowsEditor:
					case RuntimePlatform.OSXEditor:
						return string.Format("{0}/{1}", PackResRoot, PkgBundleFolder);
					default:
						return PkgBundleFolder;
				}
			}
		}
	}

}