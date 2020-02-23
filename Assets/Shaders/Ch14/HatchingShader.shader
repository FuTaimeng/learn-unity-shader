// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/HatchingShader"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
		_TileFactor ("Tile Factor", Float) = 1
		_Outline ("Outline", Range(0, 1)) = 0.1
		_Hatch0 ("Hatch 0", 2D) = "white" {}
		_Hatch1 ("Hatch 1", 2D) = "white" {}
		_Hatch2 ("Hatch 2", 2D) = "white" {}
		_Hatch3 ("Hatch 3", 2D) = "white" {}
		_Hatch4 ("Hatch 4", 2D) = "white" {}
		_Hatch5 ("Hatch 5", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

		UsePass "Unlit/ToonShadingShader/OUTLINE"

        Pass
        {
			Tags{ "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityShaderVariables.cginc"

            struct a2v {
				float4 vertex : POSITION;
				float4 tangent : TANGENT; 
				float3 normal : NORMAL; 
				float2 texcoord : TEXCOORD0; 
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed3 hatchFactor0 : TEXCOORD1;
				fixed3 hatchFactor1 : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				SHADOW_COORDS(4)
			};

            fixed4 _Color;
			float _TileFactor;
			sampler2D _Hatch0;
			sampler2D _Hatch1;
			sampler2D _Hatch2;
			sampler2D _Hatch3;
			sampler2D _Hatch4;
			sampler2D _Hatch5;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord * _TileFactor;

                float3 worldLightDir = WorldSpaceLightDir(v.vertex);
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed diff = max(0, dot(worldLightDir, worldNormal));

                o.hatchFactor0 = fixed3(0, 0, 0);
                o.hatchFactor1 = fixed3(0, 0, 0);

                float hatchFactor = diff * 7;

                if (hatchFactor > 6)
                {
                    // white
                }
                else if (hatchFactor > 5)
                {
                    o.hatchFactor0.x = 6 - hatchFactor;
                }
                else if (hatchFactor > 4)
                {
                    o.hatchFactor0.x = hatchFactor - 4;
                    o.hatchFactor0.y = 1 - o.hatchFactor0.x;
                }
                else if (hatchFactor > 3)
                {
                    o.hatchFactor0.y = hatchFactor - 3;
                    o.hatchFactor0.z = 1 - o.hatchFactor0.y;
                }
                else if (hatchFactor > 2.0) 
                {
					o.hatchFactor0.z = hatchFactor - 2.0;
					o.hatchFactor1.x = 1.0 - o.hatchFactor0.z;
				} 
                else if (hatchFactor > 1.0) 
                {
					o.hatchFactor1.x = hatchFactor - 1.0;
					o.hatchFactor1.y = 1.0 - o.hatchFactor1.x;
				} 
                else 
                {
					o.hatchFactor1.y = hatchFactor;
					o.hatchFactor1.z = 1.0 - o.hatchFactor1.y;
				}

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 hatchTex0 = tex2D(_Hatch0, i.uv) * i.hatchFactor0.x;
                fixed4 hatchTex1 = tex2D(_Hatch1, i.uv) * i.hatchFactor0.y;
                fixed4 hatchTex2 = tex2D(_Hatch2, i.uv) * i.hatchFactor0.z;
                fixed4 hatchTex3 = tex2D(_Hatch3, i.uv) * i.hatchFactor1.x;
                fixed4 hatchTex4 = tex2D(_Hatch4, i.uv) * i.hatchFactor1.y;
                fixed4 hatchTex5 = tex2D(_Hatch5, i.uv) * i.hatchFactor1.z;
                fixed4 whiteCol = fixed4(1, 1, 1, 1) * (1 - i.hatchFactor0.x - i.hatchFactor0.y - i.hatchFactor0.z
                                                          - i.hatchFactor1.x - i.hatchFactor1.y - i.hatchFactor1.z);
                fixed4 hatchCol = hatchTex0 + hatchTex1 + hatchTex2 + hatchTex3 + hatchTex4 + hatchTex5 + whiteCol;

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                return fixed4(hatchCol.rgb * _Color.rgb * atten, 1);
            }
            ENDCG
        }
    }

	Fallback "Diffuse"
}
