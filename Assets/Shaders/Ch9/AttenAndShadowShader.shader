// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Unlit/AttenAndShadowShader"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1.0, 1.0, 1.0, 1.0)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
        _SelfIuminescent ("SelfLuminescent", Color) = (0, 0, 0, 0)
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

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
				SHADOW_COORDS(2)
            };

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            fixed4 _SelfIuminescent;

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                fixed3 res = ambient + (diffuse + specular) * atten + _SelfIuminescent;
                return fixed4(res, 1.0);
            }
            ENDCG
        }

		Pass
		{
			Tags { "LightMode"="ForwardAdd" }

			Blend One One

			CGPROGRAM
			#pragma multi_compile_fwdadd_fullshadows
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
				SHADOW_COORDS(2)
            };

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            fixed4 _SelfIuminescent;

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
			#ifdef USING_DIRECTIONAL_LIGHT
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
			#else
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
			#endif
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

			// #ifdef using_directional_light
			// 	fixed atten = 1.0;
			// #else
			// 	float3 lightcoord = mul(unity_worldtolight, float4(i.worldpos, 1)).xyz;
			//	fixed atten = tex2d(_lighttexture0, dot(lightcoord, lightcoord).rr).unity_atten_channel;
			// #endif

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                fixed3 res = (diffuse + specular) * atten + _SelfIuminescent;
                return fixed4(res, 1.0);
            }
			ENDCG
		}
    }

	Fallback "Specular"
}
