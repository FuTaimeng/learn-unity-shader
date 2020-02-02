Shader "Unlit/BillboardShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Color ("ColorTint", Color) = (1, 1, 1, 1)
		_VerticalBillboarding ("VerticalRestraints", Range(0 ,1)) = 1
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True" "DisableBatching"="True" }

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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			fixed4 _Color;
			float _VerticalBillboarding;

            v2f vert (a2v v)
            {
                v2f o;

				float3 center = float3(0, 0, 0);
				float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0));
				float3 normalDir = viewer - center;
				normalDir.y *= _VerticalBillboarding;
				normalDir = normalize(normalDir);
				float3 upDir = abs(normalDir.y) > 0.99999 ? float3(0, 0, 1) : float3(0, 1, 0);
				float3 rightDir = normalize(cross(upDir, normalDir));
				upDir = normalize(cross(normalDir, rightDir));

				float3 offset = v.vertex.xyz - center;
				float3 localPos = center + rightDir * offset.x + upDir * offset.y - normalDir * offset.z;
				o.vertex = UnityObjectToClipPos(float4(localPos, 1.0));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return tex2D(_MainTex, i.uv) * _Color;
            }
            ENDCG
        }
    }
}
