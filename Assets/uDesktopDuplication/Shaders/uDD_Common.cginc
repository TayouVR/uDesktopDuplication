#ifndef UDD_COMMON_CGINC
#define UDD_COMMON_CGINC

#include "UnityCG.cginc"
#include "./uDD_Params.cginc"

struct appdata
{
    float4 vertex : POSITION;
    float2 uv     : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 vertex : SV_POSITION;
    float2 uv     : TEXCOORD0;
    UNITY_VERTEX_OUTPUT_STEREO
};

struct Input 
{
    float2 uv_MainTex;
};

inline float2 uddInvertUV(float2 uv)
{
#ifdef INVERT_X
    uv.x = 1.0 - uv.x;
#endif
#ifdef INVERT_Y
    uv.y = 1.0 - uv.y;
#endif
    return uv;
}

inline float2 uddRotateUV(float2 uv)
{
#ifdef ROTATE90
    float2 tmp = uv;
    uv.x = tmp.y;
    uv.y = 1.0 - tmp.x;
#elif ROTATE180
    uv.x = 1.0 - uv.x;
    uv.y = 1.0 - uv.y;
#elif ROTATE270
    float2 tmp = uv;
    uv.x = 1.0 - tmp.y;
    uv.y = tmp.x;
#endif
    return uv;
}

inline float2 uddClipUV(float2 uv)
{
    uv.x = _ClipX + uv.x * _ClipWidth;
    uv.y = _ClipY + uv.y * _ClipHeight;
    return uv;
}

/* --------------------------------- https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ACES.hlsl --------------------------------- */

//=================================================================================================
//
//  Baking Lab
//  by MJP and David Neubelt
//  http://mynameismjp.wordpress.com/
//
//  All code licensed under the MIT license
//
//=================================================================================================

// The code in this file was originally written by Stephen Hill (@self_shadow), who deserves all
// credit for coming up with this fit and implementing it. Buy him a beer next time you see him. :)

// sRGB => XYZ => D65_2_D60 => AP1 => RRT_SAT
static const float3x3 ACESInputMat =
{
    {0.59719, 0.35458, 0.04823},
{0.07600, 0.90834, 0.01566},
{0.02840, 0.13383, 0.83777}
};

// ODT_SAT => XYZ => D60_2_D65 => sRGB
static const float3x3 ACESOutputMat =
{
    { 1.60475, -0.53108, -0.07367},
{-0.10208,  1.10813, -0.00605},
{-0.00327, -0.07276,  1.07602}
};

float3 RRTAndODTFit(float3 v)
{
    float3 a = v * (v + 0.0245786f) - 0.000090537f;
    float3 b = v * (0.983729f * v + 0.4329510f) + 0.238081f;
    return a / b;
}

float3 ACESFitted(float3 color)
{
    color = mul(ACESInputMat, color);

    // Apply RRT and ODT
    color = RRTAndODTFit(color);

    color = mul(ACESOutputMat, color);

    // Clamp to [0, 1]
    color = saturate(color);

    return color;
}

/* ------------------------------------------------------------------ END ------------------------------------------------------------------ */

inline void uddConvertToSRGB(inout fixed3 rgb)
{
    if (_IsHDR) {
        //TODO color space correction here
        // Using these:
        // _MinLuminance
        // _MaxLuminance
        // _MaxFullFrameLuminance

        // copy pasted from here: https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ACES.hlsl
        rgb = ACESFitted(rgb);
        
        // copy pasted from here: https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
        //float a = 2.51f;
        //float b = 0.03f;
        //float c = 2.43f;
        //float d = 0.59f;
        //float e = 0.14f;
        //rgb = saturate((rgb*(a*x+b))/(rgb*(c*rgb+d)+e));
        
        ///other useful sources:
        // https://bruop.github.io/tonemapping/
    }
}

inline void uddConvertToLinearIfNeeded(inout fixed3 rgb)
{
#ifdef USE_GAMMA_TO_LINEAR_SPACE
    if (!IsGammaSpace()) {
        rgb = GammaToLinearSpace(rgb);
    }
#endif
}

inline fixed4 uddGetTexture(sampler2D tex, float2 uv)
{
    uv = uddInvertUV(uv);
#ifdef USE_CLIP
    uv = uddClipUV(uv);
#endif
    fixed4 c = tex2D(tex, uddRotateUV(uv));
    uddConvertToSRGB(c.rgb);
    uddConvertToLinearIfNeeded(c.rgb);
    return c;
}

inline fixed4 uddGetScreenTexture(float2 uv)
{
    return uddGetTexture(_MainTex, uv);
}

inline void uddBendVertex(inout float3 v, half radius, half width, half thickness)
{
#ifdef BEND_ON
    half angle = width * v.x / radius;
    #ifdef _FORWARD_Z
    v.z *= thickness;
    radius += v.z;
    v.z -= radius * (1 - cos(angle));
    #elif _FORWARD_Y
    v.y *= thickness;
    radius += v.y;
    v.y += radius * (1 - cos(angle));
    #endif
    v.x = radius * sin(angle) / width;
#else
    #ifdef _FORWARD_Z
    v.z *= thickness;
    #elif _FORWARD_Y
    v.y *= thickness;
    #endif
#endif
}

inline float3 uddRotateY(float3 n, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float3(c * n.x - s * n.z, n.y, s * n.x + c * n.z);
}

inline float3 uddRotateX(float3 n, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float3(n.x, c * n.y + s * n.z, -s * n.y + c * n.z);
}

inline void uddBendNormal(float4 x, inout float3 n, half radius, half width)
{
#ifdef BEND_ON
    half angle = width * x / radius;
    #ifdef _FORWARD_Z
    n = uddRotateY(n, -angle);
    #elif _FORWARD_Y
    n = uddRotateX(n, -angle);
    #endif
#endif
}

#endif