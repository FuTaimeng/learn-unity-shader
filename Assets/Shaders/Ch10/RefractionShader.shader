Shader "Unlit/RefractionShader"
{
    Properties
    {
		_Color ("ColorTint", Color) = (1, 1, 1, 1)
		_RefractColor ("RefractionColor", Color) = (1, 1, 1, 1)
		_RefractAmount ("RefractionAmount", Range(0, 1)) = 1
		_RefractRatio ("RefractionRatio", Range(0.1, 1)) = 0.5
		_Cubemap ("Refraction Cubemap", Cube) = "_Skybox" {}
    }
    SubShader
    {
        Pass
        {
			Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
			#pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float3 worldViewDir : TEXCOORD2;
				float3 worldRefr : TEXCOORD3;
				SHADOW_COORDS(4)
            };

			float4 _Color;
			float4 _RefractColor;
			float _RefractAmount;
			float _RefractRatio;
			samplerCUBE _Cubemap;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
                o.worldRefr = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractRatio);

				TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 viewDir = normalize(i.worldViewDir);

				fixed ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

				fixed3 refraction = texCUBE(_Cubemap, i.worldRefr).rgb * _RefractColor.rgb;

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

				fixed3 res = ambient + lerp(diffuse, refraction, _RefractAmount) * atten;
				return fixed4(res, 1.0);
            }
            ENDCG
        }
    }

	Fallback "Specular"
}
