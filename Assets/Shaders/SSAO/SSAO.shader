﻿Shader "Unlit/SSAO"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        // _SSAOTex ("SSAO (RGB)", 2D) = "white" {}
        _AOAmount ("AOAmount", Float) = 1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        ZTest Always
        ZWrite Off
        Cull Off

        Pass
        {
            NAME "SSAO"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            
            static const int SampleNumber = 64;
            static const float PI = 3.14159;

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv_depth: TEXCOORD1;
                float4 vertex : SV_POSITION;
				float4 interpolatedRay : TEXCOORD2;
            };

            float4x4 _FrustumCornersRay;
            sampler2D _CameraDepthNormalsTexture;
            half4 _MainTex_TexelSize;
            float4 _SampleList[SampleNumber];

            inline float noise(float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453123);
            }

            v2f vert (appdata_img v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.uv_depth = v.texcoord;

                #if UNITY_UV_STARTS_AT_TOP
                if (_MainTex_TexelSize.y < 0)
                {
                    o.uv_depth.y = 1 - o.uv_depth.y;
                }
                #endif

                int index = 0;
                if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5)
                {
                    index = 0;
                }
                else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5)
                {
                    index = 1;
                }
                else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5)
                {
                    index = 2;
                }
                else
                {
                    index = 3;
                }

                #if UNITY_UV_STARTS_AT_TOP
                if (_MainTex_TexelSize.y < 0)
                {
                    index = 3 - index;
                }
                #endif

                o.interpolatedRay = _FrustumCornersRay[index];

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float3 viewNormal;
				float depth;
                DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.uv_depth), depth, viewNormal);
                depth *= _ProjectionParams.z;
                float3 viewPos = depth * i.interpolatedRay.xyz;
                viewPos.z = -viewPos.z;

                float3 up = float3(0, 1, 0);
                float3 tangent = cross(viewNormal, up);
                if (length(tangent) < 0.01)
                {
                    up = float3(1, 0, 0);
                    tangent = cross(viewNormal, up);
                }
                tangent = normalize(tangent);
                float3 bitangent = cross(viewNormal, tangent);
                bitangent = normalize(bitangent);

                float3x3 tangentSpaceToView = float3x3(tangent.x, viewNormal.x, bitangent.x,
                                                       tangent.y, viewNormal.y, bitangent.y,
                                                       tangent.z, viewNormal.z, bitangent.z);

                float theta = noise(i.uv) * PI * 2;
                float c = cos(theta);
                float s = sin(theta);
                float3x3 rotate = float3x3(c, 0, s,
                                           0, 1, 0,
                                          -s, 0, c);

                float3x3 mat = mul(tangentSpaceToView, rotate);

                float AO = 0;
                for (int ii = 0; ii < SampleNumber; ii++)
                {
                    float3 dir = mul(mat, _SampleList[ii].xyz);
                    float4 pos = float4(viewPos + dir, 1);
                    float depthAtPos = -pos.z;
                    pos = mul(UNITY_MATRIX_P, pos);
                    pos.xyz /= pos.w;
                    if (pos.x < -1 || pos.x > 1 || pos.y < -1 || pos.y > 1 || pos.z < -1 || pos.z > 1) 
                    {
                        continue;
                    }
                    
                    float2 posUV = pos.xy / 2 + float2(0.5, 0.5);
                    float depthAtPosUV = DecodeFloatRG(tex2D(_CameraDepthNormalsTexture, posUV).zw);
                    depthAtPosUV *= _ProjectionParams.z;
                    if (depthAtPos > depthAtPosUV)
                    {
                        AO += 1;
                        // AO += smoothstep(0, 1, _MaxSampleLen / (depthAtPos - depthAtPosUV));
                    }
                }

                AO = 1 - AO / SampleNumber;
                return fixed4(AO, AO, AO, 1);
            }
            ENDCG
        }

        UsePass "Unlit/GuassianBlurShader/GUASSIAN_BLUR_VERTICAL"
        UsePass "Unlit/GuassianBlurShader/GUASSIAN_BLUR_HORIZONTAL"

        Pass
        {
            NAME "BLEND_WITH_MAINTEX"

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _SSAOTex;
            float _AOAmount;

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
			};

            v2f vert(appdata_img v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
				return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 col = tex2D(_MainTex, i.uv);
                fixed3 AO = tex2D(_SSAOTex, i.uv);
                AO = AO * _AOAmount + (1 - _AOAmount) + _AOAmount * 0.2;
                return fixed4(col * pow(AO, 2.2), 1);
            }
            
            ENDCG
        }
    }
}
