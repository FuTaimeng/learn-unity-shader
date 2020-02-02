Shader "Unlit/FresneShader"
{
    Properties
    {
        _Color ("ColorTint", Color) = (1, 1, 1, 1)
		_FresnelScale ("FresnelScale", Range(0, 1)) = 0.5
		_Cubemap ("ReflectionCubemap", Cube) = "_Skybox" {}
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
				float3 worldNormal :TEXCOOED1;
				float3 worldPos : TEXCOOED2;
				float3 worldRefl : TEXCOOED3;
				float3 worldViewDir : TEXCOORD4;
				SHADOW_COORDS(0)
            };

			fixed4 _Color;
			float _FresnelScale;
			samplerCUBE _Cubemap;

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_WorldToObject, v.vertex).xyz;
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);

				TRANSFER_SHADOW(o);

				return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 viewDir = normalize(i.worldViewDir);

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

				fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb;

				fixed fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(viewDir, worldNormal), 5);

				fixed3 res = ambient + lerp(diffuse, reflection, saturate(fresnel)) * atten;
				return fixed4(res, 1.0);
            }
            ENDCG
        }
    }

	Fallback "Reflective/VertexLit"
}
