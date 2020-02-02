Shader "Unlit/SequanceAnimationShader"
{
    Properties
    {
		_Color ("ColorTint", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
		_HorizontalAmount ("HorizontalAmount", Float) = 4
		_VerticalAmount ("VerticalAmount", Float) = 4
		_Speed ("Speed", Range(1, 100)) = 30
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }

        Pass
        {
			Tags { "LightMode"="Forwardbase" }

			ZWrite Off

			Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

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

			fixed4 _Color;
			float _HorizontalAmount;
			float _VerticalAmount;
			float _Speed;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float time = floor(_Time.y * _Speed);
				float row = floor(time / _HorizontalAmount);
				float column = time - row * _HorizontalAmount;

				float2 uv = float2(column/_VerticalAmount, (_HorizontalAmount-row+1)/_HorizontalAmount)
						  + float2(i.uv.x / _VerticalAmount, i.uv.y / _HorizontalAmount);

				return tex2D(_MainTex, uv) * _Color;
            }
            ENDCG
        }
    }
}
