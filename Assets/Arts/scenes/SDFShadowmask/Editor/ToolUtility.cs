using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace Elex.SDFShadowMask.Editor
{
    public static class ToolUtility
    {
        public static Texture2D DuplicateTexture(Texture2D source)
        {
            RenderTexture renderTex = RenderTexture.GetTemporary(
                source.width,
                source.height,
                0,
                RenderTextureFormat.Default,
                RenderTextureReadWrite.Linear);

            Graphics.Blit(source, renderTex);

            RenderTexture previous = RenderTexture.active;
            RenderTexture.active = renderTex;
            Texture2D readableText = new Texture2D(renderTex.width, renderTex.height);
            readableText.ReadPixels(new Rect(0, 0, source.width, source.height), 0, 0);
            readableText.Apply();
            RenderTexture.active = previous;
            RenderTexture.ReleaseTemporary(renderTex);
            return readableText;
        }

        /// <summary>
        /// 将大图切出一小部分
        /// </summary>
        /// <param name="source"></param>
        /// <param name="size"></param>
        /// <param name="offset"></param>
        /// <param name="invertColor">颜色反相</param>
        /// <param name="binaryProcess">二值化处理</param>
        /// <returns></returns>
        public static Texture2D SliceTexture(Texture2D source, Vector2 size, Vector2 offset, bool invertColor, bool binaryProcess)
        {
            var targetHeight = source.height * size.y;
            var targetWidth = source.width * size.x;

            var targetOffsetY = (int)(source.height * offset.y);
            var targetOffsetX = (int)(source.width * offset.x);

            Texture2D newTex = new Texture2D((int)targetWidth, (int)targetHeight);

            for (int j = targetOffsetY; j < targetOffsetY + targetHeight; j++)
            {
                for (int i = targetOffsetX; i < targetOffsetX + targetWidth; i++)
                {
                    var colorValue = source.GetPixel(i, j);

                    if (binaryProcess)
                    {
                        colorValue.r = colorValue.r > 0.5 ? 1 : 0;
                        colorValue.g = colorValue.g > 0.5 ? 1 : 0;
                        colorValue.b = colorValue.b > 0.5 ? 1 : 0;
                        colorValue.a = colorValue.a > 0.5 ? 1 : 0;
                    }

                    if (invertColor)
                    {
                        var value = Color.white - colorValue;
                        newTex.SetPixel(i - targetOffsetX, j - targetOffsetY, value);
                    }
                    else
                    {
                        newTex.SetPixel(i - targetOffsetX, j - targetOffsetY, source.GetPixel(i, j));
                    }
                }
            }

            newTex.Apply();

            return newTex;
        }
        /// <summary>
        /// 小图填充到大图中
        /// </summary>
        /// <param name="source"></param>
        /// <param name="target"></param>
        /// <param name="size"></param>
        /// <param name="offset"></param>
        /// <returns></returns>
        public static Texture2D FillTexture(Texture2D source, Texture2D target, Vector2 size, Vector2 offset)
        {
            var targetHeight = target.height * size.y;
            var targetWidth = target.width * size.x;

            var targetOffsetY = (int)(target.height * offset.y);
            var targetOffsetX = (int)(target.width * offset.x);

            for (int j = 0; j < targetHeight; j++)
            {
                for (int i = 0; i < targetWidth; i++)
                {
                    var colorValue = source.GetPixel(i, j);

                    target.SetPixel(i + targetOffsetX, j + targetOffsetY, colorValue);
                }
            }

            target.Apply();

            return target;
        }

        public static void ReverseTexture(Texture2D texture)
        {
            var pixels = texture.GetPixels();

            for (int i = 0; i < pixels.Length; ++i)
            {
                pixels[i] = Color.white - pixels[i];
            }

            texture.SetPixels(pixels);

            texture.Apply();
        }

        public static void SaveTexture(Texture2D texture, string name, string path)
        {
            if (texture == null)
            {
                Debug.LogErrorFormat("texture {0} is null", name);
                return;
            }

            var bytes = texture.EncodeToPNG();
            if (!Directory.Exists(path))
            {
                Directory.CreateDirectory(path);
            }

            var file = File.Open(path + "/" + name + ".png", FileMode.OpenOrCreate);
            var binary = new BinaryWriter(file);
            binary.Write(bytes);
            file.Close();
        }
    }
}


