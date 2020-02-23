// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/ToonShadingShader"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _Ramp ("Ramp Tex", 2D) = "white" {}
        _Outline ("Outline", Range(0, 1)) = 0.1
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _SpecularScale ("Specular Scale", Range(0, 0.1)) = 0.01
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            NAME "OUTLINE"

            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

			float _Outline;
			fixed4 _OutlineColor;

            v2f vert (appdata v)
            {
                v2f o;
				float4 pos = float4(UnityObjectToViewPos(v.vertex), 1);
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                normal.z = -0.5;
                pos = pos + float4(normalize(normal), 0) * _Outline;
                o.pos = mul(UNITY_MATRIX_P, pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }

        Pass
        {
            Tags { "LightMood"="ForwardBase" }

            Cull Back

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityShaderVariables.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float3 tangent: TANGENT;
                float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				SHADOW_COORDS(3)
			};

			float4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _Ramp;
			float4 _Specular;
			float _SpecularScale;

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
                TRANSFER_SHADOW(o);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
				float3 worldNormal = normalize(i.worldNormal);
				float3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				float3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				float3 worldHalfDir = normalize(worldLightDir + worldViewDir);

                float4 c = tex2D(_MainTex, i.uv);
                float3 albedo = c.rgb * _Color.rgb;

                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                float diff = dot(worldNormal, worldLightDir);
                diff = (diff * 0.5 + 0.5) * atten;
                float diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp, float2(diff, diff)).rgb;

                float spec = dot(worldNormal, worldHalfDir);
                float w = fwidth(spec) * 2;
                float3 specular = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1)) * step(0.001, _SpecularScale);

                return float4(ambient + diffuse + specular, 1);
            }
            ENDCG
        }
    }

    Fallback "Diffuse"
}
