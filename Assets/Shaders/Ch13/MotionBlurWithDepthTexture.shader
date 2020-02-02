Shader "Unlit/MotionBlurWithDepthTexture"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
		_BlurSize ("BlurSize", Float) = 0.5
		_SampleTimes ("SampleTimes", Float) = 10
    }

    SubShader
    {
        CGINCLUDE
		#include "UnityCG.cginc"

		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _CameraDepthTexture;
		float4x4 _ViewProjectionInverse;
		float4x4 _PreviousViewProjection;
		float _BlurSize;
		float _SampleTimes;

		struct v2f
		{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uvDepth : TEXCOORD1;
		};

		v2f vert(appdata_img v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = v.texcoord;
			o.uvDepth = v.texcoord;

			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
			{
				o.uvDepth.y = 1 - o.uvDepth.y;
			}
			#endif

			return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
			float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uvDepth);
			float4 NDCPos = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depth * 2 - 1, 1);
			float4 temp = mul(_ViewProjectionInverse, NDCPos);
			float4 worldPos = temp / temp.w;

			float4 currentPos = NDCPos;
			float4 previousPos = mul(_PreviousViewProjection, worldPos);
			previousPos /= previousPos.w;

			float2 velocity = (currentPos - previousPos).xy;

			float2 uv = i.uv;
			float2 delta = velocity / _SampleTimes * _BlurSize;
			float4 color;
			int st = floor(_SampleTimes + 0.1);
			for (int p = 0; p < st; p++)
			{
				color += tex2D(_MainTex, uv);
				uv += delta;
			}
			color /= st;
			color.w = 1;

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
