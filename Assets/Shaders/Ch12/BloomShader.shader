Shader "Unlit/BloomShader"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
		_BlurSize ("BlurSize", Float) = 1
		_Bloom ("Bloom", 2D) = "balck" {}
		_LuminanceThreshold ("LuminanceThreshold", Float) = 0.5
    }

    SubShader
    {
        CGINCLUDE
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		float4 _MainTex_TexelSize;
		float _BlurSize;
		sampler2D _Bloom;
		float4 _Bloom_TexelSize;
		float _LuminanceThreshold;


		struct v2f
		{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
		};

		struct v2fBlur
		{
			float4 pos : SV_POSITION;
			half2 uv[5] : TEXCOORD0;
		};

		struct v2fBloom
		{
			float4 pos : SV_POSITION;
			half4 uv : TEXCOORD;
		};

		v2f vertExtractBright(appdata_img v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = v.texcoord;
			return o;
		}

		fixed lumiance(fixed4 color)
		{
			return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
		}

		fixed4 fragExtractBright(v2f i) : SV_Target
		{
			fixed4 col = tex2D(_MainTex, i.uv);
			fixed val = clamp(lumiance(col) - _LuminanceThreshold, 0, 1);
			return col * val;
		}

		v2fBlur vertBlurVertical(appdata_img v)
		{
			v2fBlur o;
			o.pos = UnityObjectToClipPos(v.vertex);

			half2 uv = v.texcoord;
			float ps_y = _MainTex_TexelSize.y;
			o.uv[0] = uv;
			o.uv[1] = uv + float2(0, ps_y) * _BlurSize;
			o.uv[2] = uv - float2(0, ps_y) * _BlurSize;
			o.uv[3] = uv + float2(0, ps_y * 2) * _BlurSize;
			o.uv[4] = uv - float2(0, ps_y * 2) * _BlurSize;

			return o;
		}

		v2fBlur vertBlurHorizontal(appdata_img v)
		{
			v2fBlur o;
			o.pos = UnityObjectToClipPos(v.vertex);

			half2 uv = v.texcoord;
			float ps_x = _MainTex_TexelSize.x;
			o.uv[0] = uv;
			o.uv[1] = uv + float2(ps_x, 0) * _BlurSize;
			o.uv[2] = uv - float2(ps_x, 0) * _BlurSize;
			o.uv[3] = uv + float2(ps_x * 2, 0) * _BlurSize;
			o.uv[4] = uv - float2(ps_x * 2, 0) * _BlurSize;

			return o;
		}

		fixed4 fragBlur(v2fBlur i) : SV_Target
		{
			float weight[3] = { 0.4026, 0.2442, 0.0545 };

			fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
			for (int p = 1; p < 3; p++)
			{
				sum += tex2D(_MainTex, i.uv[p * 2 - 1]).rgb * weight[p];
				sum += tex2D(_MainTex, i.uv[p * 2]).rgb * weight[p];
			}

			return fixed4(sum, 1.0);
		}

		v2fBloom vertBloom(appdata_img v)
		{
			v2fBloom o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv.xy = v.texcoord;
			o.uv.zw = v.texcoord;
			
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv.w = 1 - o.uv.w;
			#endif

			return o;
		}

		fixed4 fragBloom(v2fBloom i) : SV_Target
		{
			return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
		}

		ENDCG

		ZTest Always
		ZWrite Off
		Cull Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vertExtractBright
			#pragma fragment fragExtractBright
			ENDCG
		}

        Pass
        {
			NAME "GUASSIAN_BLUR_VERTICAL"

            CGPROGRAM
			#pragma vertex vertBlurVertical
			#pragma fragment fragBlur
            ENDCG
        }

		Pass
		{
			NAME "GUASSIAN_BLUR_HORIZONTAL"

            CGPROGRAM
			#pragma vertex vertBlurHorizontal
			#pragma fragment fragBlur
            ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vertBloom
			#pragma fragment fragBloom
			ENDCG
		}
    }

	Fallback Off
}
