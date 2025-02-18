using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace Elex.SDFShadowMask.Editor
{
    public class TextureSlice
    {
        public int lightMapIndex;
        public Texture2D tex;
        public Texture2D sdftex;
        public Vector2 size;
        public Vector2 offset;

        public ulong objID;
    }
    public class TextureSlicer
    {
        List<TextureSlice> slices = new List<TextureSlice>();

        int mapSizeX = 0;
        int mapSizeY = 0;

        public void Slice(Texture2D tex, Vector4[] texSTs, ulong[] objIDs)
        {
            if (tex == null)
            {
                return;
            }

            mapSizeX = tex.width;
            mapSizeY = tex.height;

            //Debug.Log(mapSizeX);
            //Debug.Log(mapSizeY);
            //Debug.Log(tex.texelSize);

            //for readable
            var readableTex = ToolUtility.DuplicateTexture(tex);

            for (int i = 0; i < texSTs.Length; ++i)
            {
                var st = texSTs[i];
                var id = objIDs[i];
                var minisize = new Vector2(st.x, st.y);

                var minioffset = new Vector2(st.z, st.w);

                var minitex = ToolUtility.SliceTexture(readableTex, minisize, minioffset, true, true);

                if (minitex != null)
                {
                    slices.Add(new TextureSlice()
                    {
                        lightMapIndex = 1,
                        tex = minitex,
                        size = minisize,
                        offset = minioffset,
                        objID = id
                    });
                }
            }
        }

        public void Combine(int scale, TextureFormat format, out Texture2D targetTex)
        {
            if (slices == null)
            {
                targetTex = null;
                return;
            }

            float scaleValue = 1 << scale;

            Debug.Log(scaleValue);

            var w = mapSizeX / scaleValue;
            var h = mapSizeY / scaleValue;

            Debug.Log(w);
            Debug.Log(h);

            targetTex = new Texture2D((int)w, (int)h, format, true);
            int num = (int)w * (int)h;
            Color[] defaultColors = new Color[num];
            for (var i = 0; i < num; ++i)
            {
                defaultColors[i] = Color.black;
            }
            targetTex.SetPixels(defaultColors);

            foreach (var s in slices)
            {
                var sourcetex = s.tex;
                if (sourcetex == null)
                {
                    continue;
                }



                ToolUtility.FillTexture(sourcetex, targetTex, s.size, s.offset);
            }
        }

        public void CombineSdf(int texScale, TextureFormat format, out Texture2D targetTex)
        {
            Debug.LogFormat("CombineSdf slices: {0}", slices);
            if (slices == null)
            {
                targetTex = null;
                return;
            }

            //float scaleValue = 1 << scale;
            float scaleValue = texScale;

            Debug.Log(scaleValue);

            var w = mapSizeX / scaleValue;
            var h = mapSizeY / scaleValue;

            Debug.Log(w);
            Debug.Log(h);

            targetTex = new Texture2D((int)w, (int)h, format, true);
            int num = (int)w * (int)h;
            Color[] defaultColors = new Color[num];
            for (var i = 0; i < num; ++i)
            {
                defaultColors[i] = Color.black;
            }
            targetTex.SetPixels(defaultColors);

            foreach (var s in slices)
            {
                var sourcetex = s.sdftex;
                if (sourcetex == null)
                {
                    continue;
                }
                Debug.Log(sourcetex.width);
                Debug.Log(sourcetex.height);


                ToolUtility.FillTexture(sourcetex, targetTex, s.size, s.offset);
            }
        }

        public void SaveTex(string path, int mapindex)
        {
            if (slices == null)
            {
                return;
            }

            for (int i = 0; i < slices.Count; ++i)
            {
                var name = string.Format("test_{0}_{1}", mapindex, i);
                ToolUtility.SaveTexture(slices[i].tex, name, path);
            }

            AssetDatabase.Refresh();
        }

        public void SaveSdfTex(string path, int mapindex)
        {
            if (slices == null)
            {
                return;
            }

            for (int i = 0; i < slices.Count; ++i)
            {
                var name = string.Format("test_{0}_{1}", mapindex, i);
                ToolUtility.SaveTexture(slices[i].sdftex, name, path);
            }

            AssetDatabase.Refresh();
        }

        public void Convert2Sdf(int scale, float insideMaxValue, float outsideMaxkValue, SdfUtility.ColorChannel channel, SdfUtility.ColorChannel outchannel, TextureFormat targetTexFormat)
        {
            if (slices == null)
            {
                return;
            }

            for (int i = 0; i < slices.Count; ++i)
            {
                SdfUtility.GenerateSDF(slices[i].tex, scale, insideMaxValue, outsideMaxkValue, channel, outchannel, targetTexFormat, out Texture2D sdttex);

                slices[i].sdftex = sdttex;


                ToolUtility.ReverseTexture(slices[i].sdftex);
            }

        }

        public TextureSlice FindSlice(ulong id)
        {
            foreach (var s in slices)
            {
                if (s.objID == id)
                {
                    return s;
                }
            }

            return null;
        }

        public List<TextureSlice> GetSlices()
        {
            return slices;
        }
    }
}

