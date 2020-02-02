Shader "Unlit/FogWithDepthTexture"
{
    Properties
    {
        _MainTex ("Bace (RGB)", 2D) = "white" {}
		_FogDensity ("_FogDensity", Float) = 1
		_FogColor ("FogColor", Color) = (1, 1, 1, 1)
		_FogStart ("FogStart", Float) = 0
		_FogEnd ("FogEnd", Float) = 1
    }

    SubShader
    {
        CGINCLUDE
		#include "UnityCG.cginc"

		float4x4 _FrustumCorners;
		sampler2D _MainTex;
		half4 _MainTex_PexelSize;
		sampler2D _CameraDepthTexture;
		float _FogDensity;
		fixed4 _FogColor;
		float _FogStart;
		float _FogEnd;

		struct v2f
		{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uvDepth : TEXCOORD1;
			float4 interpolatedRay : TEXCOORD2;
		};

		v2f vert(appdata_img v) 
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);

			o.uv = v.texcoord;
			o.uvDepth = v.texcoord;

			#if UNITY_UV_STARTS_AT_TOP
			if(_MainTex_PexelSize.y < 0)
			{
				o.uvDepth.y = 1 - o.uvDepth.y;
			}
			#endif

			int index;
			if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) index = 0;
			if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) index = 1;
			if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) index = 2;
			if (v.texcoord.x < 0.5 && v.texcoord.y > 0.5) index = 3;

			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_PexelSize.y < 0)
			{
				index = 3 - index;
			}
			#endif

			o.interpolatedRay = _FrustumCorners[index];

			return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
			float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uvDepth));
			float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;

			float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart);
			fogDensity = saturate(fogDensity * _FogDensity);

			fixed4 color = tex2D(_MainTex, i.uv);
			color.rgb = lerp(color.rgb, _FogColor.rgb, fogDensity);

			return color;
		}

		ENDCG


        Pass
		{
			ZTest Always
			Cull Off
			ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
    }

	Fallback Off
}
