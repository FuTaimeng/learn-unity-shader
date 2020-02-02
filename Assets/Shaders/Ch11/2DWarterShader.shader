Shader "Unlit/2DWarterMat"
{
    Properties
    {
		_Color ("ColorTint", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
		_Magnitude ("Distortion Magnitude", Float) = 1
		_Frequency ("Distortion Frequency", Float) = 1
		_InvWaveLength ("Distortion Inverse Wave Length", Float) = 10
		_Speed ("Speed", Float) = 0.5
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "IgnorePorjector"="True" "RenderType"="Transparent" "DisableBatching"="True" }

        Pass
        {
			Tags { "LightMode"="ForwardBase" }

			ZWrite Off

			Blend SrcAlpha OneMinusSrcAlpha

			Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

			float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
			float _Magnitude;
			float _Frequency;
			float _InvWaveLength;
			float _Speed;

            v2f vert (a2v v)
            {
                v2f o;

                float4 offset;
				offset.yzw = float3(0, 0, 0);
				offset.x = sin(_Frequency * _Time.y + v.vertex.z * _InvWaveLength) * _Magnitude;
				o.pos = UnityObjectToClipPos(v.vertex + offset);

				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv += float2(0.0, _Time.y * _Speed);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return tex2D(_MainTex, i.uv) * _Color;
            }
            ENDCG
        }

		Pass
		{
			Tags { "LightMode"="ShadowCaster" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster

			#include "UnityCG.cginc"

			float _Magnitude;
			float _Frequency;
			float _InvWaveLength;
			float _Speed;

			struct a2v
			{
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
				float4 normal : NORMAL;
			};

			struct v2f
			{
				V2F_SHADOW_CASTER;
			};

			v2f vert(a2v v)
			{
				v2f o;
				
				float4 offset;
				offset.yzw = float3(0, 0, 0);
				offset.x = sin(_Frequency * _Time.y + v.vertex.z * _InvWaveLength) * _Magnitude;
				v.vertex = v.vertex + offset;

				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
    }

	Fallback "Diffuse"
}
