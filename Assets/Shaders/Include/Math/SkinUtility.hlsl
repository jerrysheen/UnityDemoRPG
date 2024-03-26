#ifndef SkinUtilt
#define SkinUtilt

  inline float4 getUV(float startIndex,float textureSize)
   {
       float y=(int)(startIndex/textureSize);
        float u=(startIndex-y*textureSize)/textureSize;
        float v=y/textureSize;
        return float4(u,v,0,0);
    }
#endif