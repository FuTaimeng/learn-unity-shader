Shader "ChinesePaint/ChinesePaint"
{
    Properties
    {
        [Header(OutLine)]
		// Stroke Color
		_StrokeColor ("Stroke Color", Color) = (0,0,0,1)
		// Noise Map
		_OutlineNoise ("Outline Noise Map", 2D) = "white" {}
		// First Outline Width
		_OutlineWidth ("Outline Width", Range(0, 1)) = 0.1
		// Second Outline Width
		_OutsideNoiseWidth ("Outside Noise Width", Range(1, 2)) = 1.3

        [Header(Interior)]
		_Ramp ("Ramp Texture", 2D) = "white" {}
		// Stroke Map
		_StrokeTex ("Stroke Tex", 2D) = "white" {}
		_InteriorNoise ("Interior Noise Map", 2D) = "white" {}
		// Interior Noise Level
		_InteriorNoiseLevel ("Interior Noise Level", Range(0, 1)) = 0.15
		// Guassian Blur
		radius ("Guassian Blur Radius", Range(0,60)) = 30
        resolution ("Resolution", float) = 800  
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}

        // outline
        Pass
        {
            NAME "ChinesePaintOutline"

            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            fixed3 _StrokeColor;
            sampler2D _OutlineNoise;
            float4 _OutlineNoise_ST;
            float _OutlineWidth;

            v2f vert (a2v v) 
			{
                v2f o;

				// fetch Perlin noise map here to map the vertex
				// add some bias by the normal direction
                float2 noise_uv = normalize(v.vertex.xy + v.vertex.yz) * _OutlineNoise_ST.xy + _OutlineNoise_ST.zw;
				fixed4 burn = tex2Dlod(_OutlineNoise, float4(noise_uv, 0, 0));

				// camera space
				float3 pos = UnityObjectToViewPos(v.vertex);
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                normal.z -= 0.5;
                normal = normalize(normal);

                // make the line width independent with distance
				// unity_CameraProjection[1].y = cos(fov/2)
				float widthScaler = -pos.z / (unity_CameraProjection[1].y);
				widthScaler = sqrt(widthScaler);

                pos = pos + normal * (burn.r * widthScaler * _OutlineWidth);
				o.pos = mul(UNITY_MATRIX_P, float4(pos, 1));

				return o;
			}

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(_StrokeColor, 1);
            }

            ENDCG
        }

        // outline add
        Pass
        {
            NAME "ChinesePaintOutlineAdd"

            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            fixed3 _StrokeColor;
            sampler2D _OutlineNoise;
            float4 _OutlineNoise_ST;
            float _OutlineWidth;
            float _OutsideNoiseWidth;

            v2f vert (a2v v) 
			{
                v2f o;

				// fetch Perlin noise map here to map the vertex
				// add some bias by the normal direction
                float2 noise_uv = normalize(v.vertex.xy + v.vertex.yz) * _OutlineNoise_ST.xy + _OutlineNoise_ST.zw;
				fixed4 burn = tex2Dlod(_OutlineNoise, float4(noise_uv, 0, 0));

				// camera space
				float3 pos = UnityObjectToViewPos(v.vertex);
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
                normal.z -= 0.5;
                normal = normalize(normal);

                // make the line width independent with distance
				// unity_CameraProjection[1].y = cos(fov/2)
				float widthScaler = -pos.z / (unity_CameraProjection[1].y);
				widthScaler = sqrt(widthScaler);

                pos = pos + normal * (burn.r * widthScaler * _OutlineWidth * _OutsideNoiseWidth);
				o.pos = mul(UNITY_MATRIX_P, float4(pos, 1));

                o.uv = v.texcoord;

				return o;
			}

            fixed4 frag (v2f i) : SV_Target
            {   
                float burn = tex2D(_OutlineNoise, i.uv).r;
                if (burn < 0.5) discard;
                return fixed4(_StrokeColor, 1);
            }

            ENDCG
        }

        // interior
        Pass
        {
            NAME "ChinesePaintInterior"

            Cull Back
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _Ramp;
            sampler2D _StrokeTex;
            sampler2D _InteriorNoise;
            float _InteriorNoiseLevel;
            float radius;
            float resolution;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD2;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target 
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				// Noise
				// For the bias of the coordiante
				float2 burn = tex2D(_InteriorNoise, i.uv).xy;
				// a little bit disturbance
				fixed diff =  dot(worldNormal, worldLightDir);
				diff = (diff * 0.5 + 0.5);
				float2 stroke = tex2D(_StrokeTex, i.uv).xy;
				float2 ramp_uv = float2(diff, diff) + stroke * burn.xy * _InteriorNoiseLevel;
				ramp_uv = clamp(ramp_uv, 0, 1);

				// Guassian Blur
				fixed3 sum = fixed3(0.0, 0.0, 0.0);
                float2 tc = ramp_uv;
                // blur radius in pixels
                float blur = radius/resolution/4;
                sum += tex2D(_Ramp, float2(tc.x - 4.0*blur, tc.y)) * 0.0162162162;
                sum += tex2D(_Ramp, float2(tc.x - 3.0*blur, tc.y)) * 0.0540540541;
                sum += tex2D(_Ramp, float2(tc.x - 2.0*blur, tc.y)) * 0.1216216216;
                sum += tex2D(_Ramp, float2(tc.x - 1.0*blur, tc.y)) * 0.1945945946;
                sum += tex2D(_Ramp, float2(tc.x,            tc.y)) * 0.2270270270;
                sum += tex2D(_Ramp, float2(tc.x + 1.0*blur, tc.y)) * 0.1945945946;
                sum += tex2D(_Ramp, float2(tc.x + 2.0*blur, tc.y)) * 0.1216216216;
                sum += tex2D(_Ramp, float2(tc.x + 3.0*blur, tc.y)) * 0.0540540541;
                sum += tex2D(_Ramp, float2(tc.x + 4.0*blur, tc.y)) * 0.0162162162;

				return fixed4(sum, 1.0);
			}

            ENDCG
        }
    }

    Fallback "Diffuse"
}
