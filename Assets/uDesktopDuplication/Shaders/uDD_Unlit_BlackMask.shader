﻿Shader "uDesktopDuplication/Unlit BlackMask"
{

Properties
{
    _Color ("Color", Color) = (1, 1, 1, 1)
    _ColorScale ("ColorScale", Range(0.0, 10.0)) = 1.0
    _MainTex ("Texture", 2D) = "white" {}
    _Mask ("Mask", Range(0, 1)) = 0.1
    [KeywordEnum(Y, Z)] _Forward("Mesh Forward Direction", Int) = 0
    [Toggle(BEND_ON)] _Bend("Use Bend", Int) = 0
    [PowerSlider(10.0)] _Radius("Bend Radius", Range(1, 100)) = 30
    [PowerSlider(10.0)] _Thickness("Thickness", Range(0.01, 10)) = 1
    _Width("Width", Range(0.0, 10.0)) = 1.0
    [KeywordEnum(Off, Front, Back)] _Cull("Culling", Int) = 2
    [ToggleUI]_IsHDR("Is HDR", Float) = 0
    //_ColorSpace("Color Space", int) = 0
    _MinLuminance("Minimal Luminance", Range(0, 1)) = 0
    _MaxLuminance("Maximum Luminance", Range(0, 1)) = 0
    _MaxFullFrameLuminance("Max Full Frame Luminance", Range(0, 1)) = 0
}

SubShader
{

Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }

Cull [_Cull]
ZWrite On
Blend SrcAlpha OneMinusSrcAlpha

CGINCLUDE

#include "./uDD_Common.cginc"

fixed _Mask;

v2f vert(appdata v)
{
    v2f o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(v2f, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    uddBendVertex(v.vertex.xyz, _Radius, _Width, _Thickness);
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    return o;
}

fixed4 frag(v2f i) : SV_Target
{
    fixed4 tex = uddGetScreenTexture(i.uv);
    fixed alpha = pow((tex.r + tex.g + tex.b) / 3.0, _Mask);
    return fixed4(tex.rgb * _Color.rgb * _ColorScale, alpha * _Color.a);
}

ENDCG

Pass
{
    CGPROGRAM
    #pragma vertex vert
    #pragma fragment frag
    #pragma shader_feature ___ INVERT_X
    #pragma shader_feature ___ INVERT_Y
    #pragma shader_feature _FORWARD_Y _FORWARD_Z
    #pragma shader_feature ___ USE_GAMMA_TO_LINEAR_SPACE
    #pragma multi_compile ___ ROTATE90 ROTATE180 ROTATE270
    #pragma multi_compile ___ USE_CLIP
    #pragma multi_compile ___ BEND_ON
    ENDCG
}

}

Fallback "Unlit/Texture"

}
