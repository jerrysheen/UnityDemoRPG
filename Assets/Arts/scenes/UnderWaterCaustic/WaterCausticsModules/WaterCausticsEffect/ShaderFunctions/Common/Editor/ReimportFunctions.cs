// WaterCausticsModules
// Copyright (c) 2021 Masataka Hakozaki

using System.IO;
using System.Linq;
using UnityEditor;

namespace MH.WaterCausticsModules {
    public class ReimportFunctions : AssetPostprocessor {
        static void OnPostprocessAllAssets (string [] importedAssets, string [] deletedAssets, string [] movedAssets, string [] movedFromAssetPaths) {
            string thisScriptName = typeof (ReimportFunctions).Name + ".cs";
            if (movedAssets.Any (a => a.EndsWith (thisScriptName)) && !importedAssets.Any (a => a.EndsWith (thisScriptName))) {
                string path = movedAssets.FirstOrDefault (a => a.EndsWith (thisScriptName));
                path = getUpperFolder (path, 3);
                AssetDatabase.ImportAsset (path, ImportAssetOptions.ImportRecursive);
                // Debug.Log ("Re-imported the ShaderFunctions folder because it detected that it had been moved by the user. This is to solve the problem of missing SubGraph references in ShaderGraph when the folder location changes.");
            }

        }

        static private string getUpperFolder (string path, int cnt = 1) {
            string p = path;
            for (int i = 0; i < cnt; i++) {
                string tmp = Path.GetDirectoryName (p);
                if (tmp == "Assets") break;
                else p = tmp;
            }
            return p.Replace ("\\", "/");
        }
    }
}
