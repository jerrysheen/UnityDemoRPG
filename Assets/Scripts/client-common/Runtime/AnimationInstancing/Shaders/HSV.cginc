#ifndef HSV
#define HSV

float3 RGBConvertToHSV(float3 rgb)
{
    float R = rgb.x, G = rgb.y, B = rgb.z;
    float3 hsv;
    float max1 = max(R, max(G, B));
    float min1 = min(R, min(G, B));
    if (R == max1)
    {
        hsv.x = (G - B) / (max1 - min1);
    }
    if (G == max1)
    {
        hsv.x = 2 + (B - R) / (max1 - min1);
    }
    if (B == max1)
    {
        hsv.x = 4 + (R - G) / (max1 - min1);
    }
    hsv.x = hsv.x * 60.0;
    if (hsv.x < 0)
        hsv.x = hsv.x + 360;
    hsv.z = max1;
    hsv.y = (max1 - min1) / max1;
    return hsv;
}

float3 HSVConvertToRGB(float3 hsv)
{
    float R, G, B;
    if (hsv.y == 0)
    {
        R = G = B = hsv.z;
    }
    else
    {
        hsv.x = hsv.x / 60.0;
        int i = (int)hsv.x;
        float f = hsv.x - (float)i;
        float a = hsv.z * (1 - hsv.y);
        float b = hsv.z * (1 - hsv.y * f);
        float c = hsv.z * (1 - hsv.y * (1 - f));
        switch (i)
        {
        case 0: R = hsv.z; G = c; B = a;
            break;
        case 1: R = b; G = hsv.z; B = a;
            break;
        case 2: R = a; G = hsv.z; B = c;
            break;
        case 3: R = a; G = b; B = hsv.z;
            break;
        case 4: R = c; G = a; B = hsv.z;
            break;
        default: R = hsv.z; G = a; B = b;
            break;
        }
    }
    return float3(R, G, B);
}
#endif