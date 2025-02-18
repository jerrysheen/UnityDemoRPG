using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Elex.SDFShadowMask.Editor
{
    public class SdfUtility
    {
        public enum ColorChannel
        {
            R,
            G,
            B,
            A,
        }

        class SdfData
        {
            public int dx, dy;
            public float distance;
            public float alpha;
            public Vector2 gradient;

            public void CopyData(SdfData source)
            {
                distance = source.distance;
                gradient = source.gradient;
                alpha = source.alpha;
            }

            public SdfData()
            {

            }
        }

        public static void GenerateSDF(Texture2D source, int scale,
            float maxInsideDisValue,
            float maxOutsideDisValue,
            ColorChannel useOriChannel,
            ColorChannel outChannel,
            TextureFormat targetTexFormat,
            out Texture2D destination)
        {
            int sourceWidth = source.width;
            int sourceHeight = source.height;

            //不使用幂次了 使用倍数
            //int targetWidth = source.width >> scale;
            //int targetHeight = source.height >> scale;
            int targetWidth = source.width / scale;
            int targetHeight = source.height / scale;

            var height = sourceHeight;
            var width = sourceWidth;

            destination = new Texture2D(targetWidth, targetHeight, targetTexFormat, true);

            var sdfDatas = new SdfData[width, height];

            var targetSdfDatas = new SdfData[targetWidth, targetHeight];

            int x, y;
            float outscale = 1;
            //1 init
            for (y = 0; y < height; y++)
            {
                for (x = 0; x < width; x++)
                {
                    sdfDatas[x, y] = new SdfData();
                }
            }
            for (y = 0; y < targetHeight; y++)
            {
                for (x = 0; x < targetWidth; x++)
                {
                    targetSdfDatas[x, y] = new SdfData();
                }
            }
            //2 fill inside
            if (maxInsideDisValue > 0)
            {
                for (y = 0; y < height; y++)
                {
                    for (x = 0; x < width; x++)
                    {
                        var pixel = source.GetPixel(x, y);

                        float value = 0;
                        switch (useOriChannel)
                        {
                            case ColorChannel.A:
                                value = pixel.a;
                                break;
                            case ColorChannel.R:
                                value = pixel.r;
                                break;
                            case ColorChannel.G:
                                value = pixel.g;
                                break;
                            case ColorChannel.B:
                                value = pixel.b;
                                break;
                        }

                        sdfDatas[x, y].alpha = 1 - value;
                    }
                }

                //原图进行边缘查找
                ComputeEdgeGradients(sdfDatas, sourceHeight, sourceWidth);
                //原图生成距离场
                GenerateDistanceTransform(sdfDatas, sourceHeight, sourceWidth);

                //原图距离场数据缩放为小图数据
                BigToSmallAlpha(sdfDatas, targetSdfDatas, scale);

                Color outColor = Color.black;

                outscale = 1f / maxInsideDisValue;
                for (y = 0; y < targetHeight; y++)
                {
                    for (x = 0; x < targetWidth; x++)
                    {
                        switch (outChannel)
                        {
                            case ColorChannel.A:
                                {
                                    outColor.a = Mathf.Clamp01(targetSdfDatas[x, y].distance * outscale);
                                }
                                break;
                            case ColorChannel.R:
                                {
                                    outColor.r = Mathf.Clamp01(targetSdfDatas[x, y].distance * outscale);
                                }
                                break;
                            case ColorChannel.G:
                                {
                                    outColor.g = Mathf.Clamp01(targetSdfDatas[x, y].distance * outscale);
                                }
                                break;
                            case ColorChannel.B:
                                {
                                    outColor.b = Mathf.Clamp01(targetSdfDatas[x, y].distance * outscale);
                                }
                                break;
                        }
                        //outColor.a = Mathf.Clamp01(targetSdfDatas[x, y].distance * outscale);
                        destination.SetPixel(x, y, outColor);

                    }
                }
            }
            //3 fill outside
            if (maxOutsideDisValue > 0)
            {
                for (y = 0; y < height; y++)
                {
                    for (x = 0; x < width; x++)
                    {
                        var pixel = source.GetPixel(x, y);

                        float value = 0;
                        switch (useOriChannel)
                        {
                            case ColorChannel.A:
                                value = pixel.a;
                                break;
                            case ColorChannel.R:
                                value = pixel.r;
                                break;
                            case ColorChannel.G:
                                value = pixel.g;
                                break;
                            case ColorChannel.B:
                                value = pixel.b;
                                break;
                        }

                        sdfDatas[x, y].alpha = value;
                    }
                }

                ComputeEdgeGradients(sdfDatas, sourceHeight, sourceWidth);
                GenerateDistanceTransform(sdfDatas, sourceHeight, sourceWidth);

                // BigToSmallAlpha(sdfDatas, targetSdfDatas, scale);
                // BigToSmallAlpha_Bicubic(sdfDatas, targetSdfDatas, scale);
                BigToSmallAlpha(sdfDatas, targetSdfDatas, scale);
                //
                Color outColor = Color.black;

                outscale = 1f / maxOutsideDisValue;
                if (maxInsideDisValue > 0)
                {
                    for (y = 0; y < targetHeight; y++)
                    {
                        for (x = 0; x < targetWidth; x++)
                        {
                            switch (outChannel)
                            {
                                case ColorChannel.A:
                                    {
                                        outColor.a = 0.5f + (destination.GetPixel(x, y).a -
                                                  Mathf.Clamp01(targetSdfDatas[x, y].distance * outscale)) * 0.5f;
                                    }
                                    break;
                                case ColorChannel.R:
                                    {
                                        outColor.r = 0.5f + (destination.GetPixel(x, y).r -
                                                  Mathf.Clamp01(targetSdfDatas[x, y].distance * outscale)) * 0.5f;
                                    }
                                    break;
                                case ColorChannel.G:
                                    {
                                        outColor.g = 0.5f + (destination.GetPixel(x, y).g -
                                                  Mathf.Clamp01(targetSdfDatas[x, y].distance * outscale)) * 0.5f;
                                    }
                                    break;
                                case ColorChannel.B:
                                    {
                                        outColor.b = 0.5f + (destination.GetPixel(x, y).b -
                                                  Mathf.Clamp01(targetSdfDatas[x, y].distance * outscale)) * 0.5f;
                                    }
                                    break;
                            }

                            //outColor.a = 0.5f + (destination.GetPixel(x, y).a -
                            //                      Mathf.Clamp01(targetSdfDatas[x, y].distance * outscale)) * 0.5f;
                            destination.SetPixel(x, y, outColor);
                        }
                    }
                }
                else
                {
                    for (y = 0; y < targetHeight; y++)
                    {
                        for (x = 0; x < targetWidth; x++)
                        {
                            //outColor.a = Mathf.Clamp01(1f - targetSdfDatas[x, y].distance * outscale);
                            switch (outChannel)
                            {
                                case ColorChannel.A:
                                    {
                                        outColor.a = Mathf.Clamp01(1f - targetSdfDatas[x, y].distance * outscale);
                                    }
                                    break;
                                case ColorChannel.R:
                                    {
                                        outColor.r = Mathf.Clamp01(1f - targetSdfDatas[x, y].distance * outscale);
                                    }
                                    break;
                                case ColorChannel.G:
                                    {
                                        outColor.g = Mathf.Clamp01(1f - targetSdfDatas[x, y].distance * outscale);
                                    }
                                    break;
                                case ColorChannel.B:
                                    {
                                        outColor.b = Mathf.Clamp01(1f - targetSdfDatas[x, y].distance * outscale);
                                    }
                                    break;
                            }
                            destination.SetPixel(x, y, outColor);
                        }
                    }
                }

            }

        }

        static void ComputeEdgeGradients(SdfData[,] pixels, int height, int width)
        {
            float sqrt2 = Mathf.Sqrt(2f);
            for (int y = 1; y < height - 1; y++)
            {
                for (int x = 1; x < width - 1; x++)
                {
                    SdfData p = pixels[x, y];
                    if (p.alpha > 0f && p.alpha < 1f)
                    {
                        // estimate gradient of edge pixel using surrounding pixels
                        float g =
                            -pixels[x - 1, y - 1].alpha
                            - pixels[x - 1, y + 1].alpha
                            + pixels[x + 1, y - 1].alpha
                            + pixels[x + 1, y + 1].alpha;
                        p.gradient.x = g + (pixels[x + 1, y].alpha - pixels[x - 1, y].alpha) * sqrt2;
                        p.gradient.y = g + (pixels[x, y + 1].alpha - pixels[x, y - 1].alpha) * sqrt2;
                        p.gradient.Normalize();
                    }
                }
            }
        }

        private static float ApproximateEdgeDelta(float gx, float gy, float a)
        {
            // (gx, gy) can be either the local pixel gradient or the direction to the pixel

            if (gx == 0f || gy == 0f)
            {
                // linear function is correct if both gx and gy are zero
                // and still fair if only one of them is zero
                return 0.5f - a;
            }

            // normalize (gx, gy)
            float length = Mathf.Sqrt(gx * gx + gy * gy);
            gx = gx / length;
            gy = gy / length;

            // reduce symmetrical equation to first octant only
            // gx >= 0, gy >= 0, gx >= gy
            gx = Mathf.Abs(gx);
            gy = Mathf.Abs(gy);
            if (gx < gy)
            {
                float temp = gx;
                gx = gy;
                gy = temp;
            }

            // compute delta
            float a1 = 0.5f * gy / gx;
            if (a < a1)
            {
                // 0 <= a < a1
                return 0.5f * (gx + gy) - Mathf.Sqrt(2f * gx * gy * a);
            }
            if (a < (1f - a1))
            {
                // a1 <= a <= 1 - a1
                return (0.5f - a) * gx;
            }
            // 1-a1 < a <= 1
            return -0.5f * (gx + gy) + Mathf.Sqrt(2f * gx * gy * (1f - a));
        }

        private static void UpdateDistance(SdfData[,] pixels, SdfData p, int x, int y, int oX, int oY)
        {
            SdfData neighbor = pixels[x + oX, y + oY];
            SdfData closest = pixels[x + oX - neighbor.dx, y + oY - neighbor.dy];

            if (closest.alpha == 0f || closest == p)
            {
                // neighbor has no closest yet
                // or neighbor's closest is p itself
                return;
            }

            int dX = neighbor.dx - oX;
            int dY = neighbor.dy - oY;
            float distance = Mathf.Sqrt(dX * dX + dY * dY) + ApproximateEdgeDelta(dX, dY, closest.alpha);
            if (distance < p.distance)
            {
                p.distance = distance;
                p.dx = dX;
                p.dy = dY;
            }
        }

        private static void GenerateDistanceTransform(SdfData[,] pixels, int height, int width)
        {
            // perform anti-aliased Euclidean distance transform
            int x, y;
            SdfData p;

            // initialize distances
            for (y = 0; y < height; y++)
            {
                for (x = 0; x < width; x++)
                {
                    p = pixels[x, y];
                    p.dx = 0;
                    p.dy = 0;
                    if (p.alpha <= 0f)
                    {
                        // outside
                        p.distance = 1000000f;
                    }
                    else if (p.alpha < 1f)
                    {
                        // on the edge
                        p.distance = ApproximateEdgeDelta(p.gradient.x, p.gradient.y, p.alpha);
                    }
                    else
                    {
                        // inside
                        p.distance = 0f;
                    }
                }
            }
            // perform 8SSED (eight-points signed sequential Euclidean distance transform)
            // scan up
            for (y = 1; y < height; y++)
            {
                // |P.
                // |XX
                p = pixels[0, y];
                if (p.distance > 0f)
                {
                    UpdateDistance(pixels, p, 0, y, 0, -1);
                    UpdateDistance(pixels, p, 0, y, 1, -1);
                }
                // -->
                // XP.
                // XXX
                for (x = 1; x < width - 1; x++)
                {
                    p = pixels[x, y];
                    if (p.distance > 0f)
                    {
                        UpdateDistance(pixels, p, x, y, -1, 0);
                        UpdateDistance(pixels, p, x, y, -1, -1);
                        UpdateDistance(pixels, p, x, y, 0, -1);
                        UpdateDistance(pixels, p, x, y, 1, -1);
                    }
                }
                // XP|
                // XX|
                p = pixels[width - 1, y];
                if (p.distance > 0f)
                {
                    UpdateDistance(pixels, p, width - 1, y, -1, 0);
                    UpdateDistance(pixels, p, width - 1, y, -1, -1);
                    UpdateDistance(pixels, p, width - 1, y, 0, -1);
                }
                // <--
                // .PX
                for (x = width - 2; x >= 0; x--)
                {
                    p = pixels[x, y];
                    if (p.distance > 0f)
                    {
                        UpdateDistance(pixels, p, x, y, 1, 0);
                    }
                }
            }
            // scan down
            for (y = height - 2; y >= 0; y--)
            {
                // XX|
                // .P|
                p = pixels[width - 1, y];
                if (p.distance > 0f)
                {
                    UpdateDistance(pixels, p, width - 1, y, 0, 1);
                    UpdateDistance(pixels, p, width - 1, y, -1, 1);
                }
                // <--
                // XXX
                // .PX
                for (x = width - 2; x > 0; x--)
                {
                    p = pixels[x, y];
                    if (p.distance > 0f)
                    {
                        UpdateDistance(pixels, p, x, y, 1, 0);
                        UpdateDistance(pixels, p, x, y, 1, 1);
                        UpdateDistance(pixels, p, x, y, 0, 1);
                        UpdateDistance(pixels, p, x, y, -1, 1);
                    }
                }
                // |XX
                // |PX
                p = pixels[0, y];
                if (p.distance > 0f)
                {
                    UpdateDistance(pixels, p, 0, y, 1, 0);
                    UpdateDistance(pixels, p, 0, y, 1, 1);
                    UpdateDistance(pixels, p, 0, y, 0, 1);
                }
                // -->
                // XP.
                for (x = 1; x < width; x++)
                {
                    p = pixels[x, y];
                    if (p.distance > 0f)
                    {
                        UpdateDistance(pixels, p, x, y, -1, 0);
                    }
                }
            }
        }

        private static void BigToSmallAlpha(SdfData[,] sourcePixels, SdfData[,] targetPixels, int scale)
        {
            //int scaleNum = 1 << scale;
            int scaleNum = scale;
            Debug.Log(scaleNum);

            for (int i = 0; i < targetPixels.GetLength(0); ++i)
            {
                for (int j = 0; j < targetPixels.GetLength(1); ++j)
                {
                    var startindexX = i * scaleNum;
                    var startindexY = j * scaleNum;

                    float alpha = 0;
                    float dt = 0;

                    float mindis = 10000;
                    float cachedis = 0;

                    for (int x = 0; x < scaleNum; ++x)
                    {
                        for (int y = 0; y < scaleNum; ++y)
                        {
                            var currentPixelIndexX = startindexX + x;
                            var currentPixelIndexY = startindexY + y;

                            var currentPixel = sourcePixels[currentPixelIndexX, currentPixelIndexY];

                            alpha += currentPixel.alpha;

                            dt += currentPixel.distance;

                            if (Mathf.Abs(currentPixel.distance) < mindis)
                            {
                                mindis = Mathf.Abs(currentPixel.distance);
                                cachedis = currentPixel.distance;
                            }
                        }
                    }
                    alpha = alpha / (scaleNum * scaleNum);
                    dt = dt / (scaleNum * scaleNum);
                    targetPixels[i, j].alpha = alpha;
                    targetPixels[i, j].distance = dt;
                    //targetPixels[i, j].distance = cachedis;
                }
            }
        }

        private static void BigToSmall(SdfData[,] sourcePixels, SdfData[,] targetPixels, int w, int h)
        {
            var oriW = sourcePixels.GetLength(0);
            var oriH = sourcePixels.GetLength(1);

            var scaleNumW = w / oriW;
            var scaleNumH = w / oriH;

            for (int i = 0; i < targetPixels.GetLength(0); ++i)
            {
                for (int j = 0; j < targetPixels.GetLength(1); ++j)
                {
                    var startindexX = i * scaleNumW;
                    var startindexY = j * scaleNumH;

                    float alpha = 0;
                    float dt = 0;

                    float mindis = 10000;
                    float cachedis = 0;

                    for (int x = 0; x < scaleNumW; ++x)
                    {
                        for (int y = 0; y < scaleNumH; ++y)
                        {
                            var currentPixelIndexX = startindexX + x;
                            var currentPixelIndexY = startindexY + y;

                            var currentPixel = sourcePixels[currentPixelIndexX, currentPixelIndexY];

                            alpha += currentPixel.alpha;

                            dt += currentPixel.distance;

                            if (Mathf.Abs(currentPixel.distance) < mindis)
                            {
                                mindis = Mathf.Abs(currentPixel.distance);
                                cachedis = currentPixel.distance;
                            }
                        }
                    }
                    alpha = alpha / (scaleNumW * scaleNumH);
                    dt = dt / (scaleNumW * scaleNumH);
                    targetPixels[i, j].alpha = alpha;
                    //targetPixels[i, j].distance = dt;
                    targetPixels[i, j].distance = cachedis;
                }
            }
        }
    }
}

