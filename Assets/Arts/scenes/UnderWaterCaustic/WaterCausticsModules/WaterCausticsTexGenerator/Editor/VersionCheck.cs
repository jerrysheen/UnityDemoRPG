// WaterCausticsModules
// Copyright (c) 2021 Masataka Hakozaki

using UnityEditor;
using UnityEngine;

#if !UNITY_2020_1_OR_NEWER
namespace MH.WaterCausticsModules {
    public class VersionCheck {

        [InitializeOnLoadMethod]
        static void Warning () {
            string str = "WaterCausticsModules assets are not compatible with this version of Unity. This asset is compatible with 2020.3 and later.";
            Debug.LogError (str);
        }

    }
}
#endif
