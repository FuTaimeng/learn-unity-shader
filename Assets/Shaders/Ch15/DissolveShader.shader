Shader "Unlit/DissolveShader"
{
    Properties
    {
        _BurnAmount ("Burn Amount", Range(0.0, 1.0)) = 0.0
		_LineWidth("Burn Line Width", Range(0.0, 0.2)) = 0.1
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_BurnFirstColor("Burn First Color", Color) = (1, 0, 0, 1)
		_BurnSecondColor("Burn Second Color", Color) = (1, 0, 0, 1)
		_BurnMap("Burn Map", 2D) = "white"{}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }

        Pass
        {
            Tags { "LightMode"="ForwardBase" }

            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            struct a2f
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 tangent: TANGENT;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uvMainTex : TEXCOORD0;
                float2 uvBumpMap : TEXCOORD1;
                float2 uvBurnMap : TEXCOORD2;
                float3 lightDir : TEXCOORD3;
                float3 worldPos : TEXCOORD4;
                SHADOW_COORDS(5)
                float4 pos : SV_POSITION;
            };

            fixed _BurnAmount;
			fixed _LineWidth;
			sampler2D _MainTex;
			sampler2D _BumpMap;
			fixed4 _BurnFirstColor;
			fixed4 _BurnSecondColor;
			sampler2D _BurnMap;

            float4 _MainTex_ST;
			float4 _BumpMap_ST;
			float4 _BurnMap_ST;

            v2f vert(a2f v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uvMainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uvBumpMap = TRANSFORM_TEX(v.texcoord, _BumpMap);
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);

                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;

                clip(burn.r - _BurnAmount);

                float3 tangentLightDir = normalize(i.lightDir);
                float3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uvBurnMap));

                fixed3 albedo = tex2D(_MainTex, i.uvMainTex).rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentLightDir, tangentNormal));

                fixed t = 1 - smoothstep(0, _LineWidth, burn.r - _BurnAmount);
                fixed3 burnCol = lerp(_BurnFirstColor, _BurnSecondColor, t);
                burnCol = pow(burnCol, 5);

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                fixed3 finalCol = lerp(ambient + diffuse * atten, burnCol, t * step(0.001, _BurnAmount));
                return fixed4(finalCol, 1);
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

            fixed _BurnAmount;
            sampler2D _BurnMap;
            float4 _BurnMap_ST;

            struct v2f
            {
                V2F_SHADOW_CASTER;
                float2 uvBurnMap : TEXCOORD1;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 burn = tex2D(_BurnMap, i.uvBurnMap);
                clip(burn.r - _BurnAmount);

                SHADOW_CASTER_FRAGMENT(i)
            }

            ENDCG
        }
    }
    
    FallBack "Diffuse"
}
