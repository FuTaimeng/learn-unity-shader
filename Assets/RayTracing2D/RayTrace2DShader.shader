Shader "RayTrace2D/RayTrace2DShader"
{
	Properties
	{

	}

	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

            static const int SAMPLE_NUMBER = 40;
			static const float MAX_DIST = 2;
			static const int MAX_STEP = 50;
			static const float EPS = 1e-4;
            static const float TWO_EPS = 2e-4;
			static const float INF = 1e4;
			static const float PI = 3.1415926;
			static const float TWO_PI = 6.2831853;
			static const float BASE = 1e-3;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            struct Material
            {
                float3 emission;
                float3 reflection;
				float3 absorbtion;
                float eta;
			};

            struct SceneData
            {
                float sd;
                Material mat;
			};

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

			float circleSDF(float2 pos, float2 center, float radius)
			{
				return length(pos - center) - radius;
			}

            float boxSDF(float2 pos, float2 center, float2 halfSize, float a)
            {
                float sina = sin(a), cosa = cos(a);
                float2 d = pos - center;
                float2 t = abs(float2(d.x * cosa    + d.y * sina, 
                                      d.x * (-sina) + d.y * cosa));
                d = t - halfSize;
                if (d.x <= 0 || d.y <= 0)
                    return max(d.x, d.y);
                else
                    return sqrt(dot(d, d));
            }

            SceneData unionOp(SceneData a, SceneData b, bool useformer = false)
            {
				if (useformer)
				{
					a.sd = min(a.sd, b.sd);
					return a;
				}
				else
				{
					if (a.sd < b.sd) return a;
					else			 return b;
				}
            }

            SceneData getSceneDateAt(float2 position)
            {
                SceneData circle;
				circle.sd = circleSDF(position, float2(0.5, 0.2), 0.1);
                circle.mat.emission = float3(0, 0, 0);
				circle.mat.reflection = float3(0, 0, 0);
                circle.mat.absorbtion = float3(1, 2, 0);
				circle.mat.eta = 1.3;
                
                SceneData light;
                light.sd = circleSDF(position, float2(cos(_Time.y), sin(_Time.y)), 0.2);
                light.mat.emission = float3(3, 3, 3);
				light.mat.reflection = float3(0, 0, 0);
                light.mat.absorbtion = float3(0, 0, 0);
				light.mat.eta = 0;

                SceneData box;
                box.sd = boxSDF(position, float2(0.3, 0.5), float2 (0.2, 0.1), -0.3);
                // box.sd = circleSDF(position, float2(0.3, 0.3), 0.1);
                box.mat.emission = float3(0, 0, 0);
                box.mat.reflection = float3(0.2, 0.2, 0.2);
                box.mat.absorbtion = float3(0, 0.5, 1);
                box.mat.eta = 1.55;

                return unionOp(light, unionOp(circle, box));
                // return box;
            }

            float2 gradient(float2 pos)
            {
                return float2(
                    (getSceneDateAt(float2(pos.x + EPS, pos.y)).sd - getSceneDateAt(float2(pos.x - EPS, pos.y)).sd) / TWO_EPS,
                    (getSceneDateAt(float2(pos.x, pos.y + EPS)).sd - getSceneDateAt(float2(pos.x, pos.y - EPS)).sd) / TWO_EPS
                );
            }

            void getReflectDir(float2 i, float2 n, out float2 r)
            {
                r = i - 2 * dot(i, n) * n;
            }

            bool getRefractDir(float2 i, float2 n, float eta, out float2 r)
            {
                float idotn = dot(i, n);
                float k = 1 - eta * eta * (1 - idotn * idotn);
                if (k < 0) return false;
                float a = eta * idotn + sqrt(k);
                r = eta * i - a * n;
                return true;

                // for debug
                // r = i;
                // return true;
            }

            float3 beerLambert(float3 absorb, float dist)
            {
                return exp(-dist * absorb);
                // return float3(1, 1, 1);
            }

			float3 rayTrace3(float2 origin, float2 direction)
			{
				float dist = BASE;
                SceneData ores = getSceneDateAt(origin);
				float sign = ores.sd > 0 ? 1 : -1;
				for (int i = 0; i < MAX_STEP && dist < MAX_DIST; i++)
				{
					float2 position = origin + dist * direction;
					SceneData res = getSceneDateAt(position);
					if (abs(res.sd) < EPS)
					{
                        // no reflect and refract
						return res.mat.emission;
					}
					dist += res.sd * sign;
				}
				return float3(0, 0, 0);
			}

			float3 rayTrace2(float2 origin, float2 direction)
			{
				float dist = BASE;
				SceneData ores = getSceneDateAt(origin);
				float sign = ores.sd > 0 ? 1 : -1;
				for (int i = 0; i < MAX_STEP && dist < MAX_DIST; i++)
				{
					float2 position = origin + dist * direction;
					SceneData res = getSceneDateAt(position);
					if (abs(res.sd) < EPS)
					{
						float3 sum = float3(0, 0, 0);
						if (any(res.mat.reflection) || res.mat.eta > 0)
						{
							float3 refl = res.mat.reflection;
							float2 normal = gradient(position) * sign;
							if (res.mat.eta > 0)
							{
								float eta = res.mat.eta;
								if (sign > 0) eta = 1 / eta;
								float2 refractDir;
								if (getRefractDir(direction, normal, eta, refractDir))
								{
									sum += (1 - refl) * rayTrace3(position - normal * BASE, refractDir);
								}
								else refl = float3(1, 1, 1);
							}
							if (any(refl))
							{
								float2 reflectDir;
								getReflectDir(direction, normal, reflectDir);
								sum += refl * rayTrace3(position + normal * BASE, reflectDir);
							}
						}
						if (sign < 0) sum *= beerLambert(res.mat.absorbtion, dist);
						sum += res.mat.emission;
						return sum;
					}
					dist += res.sd * sign;
				}
				return float3(0, 0, 0);
			}

            float3 rayTrace(float2 origin, float2 direction)
            {
                float dist = BASE;
                SceneData ores = getSceneDateAt(origin);
                float sign = ores.sd > 0 ? 1 : -1;
                for (int i = 0; i < MAX_STEP && dist < MAX_DIST; i++) 
                {
                    float2 position = origin + dist * direction;
                    SceneData res = getSceneDateAt(position);
                    if (abs(res.sd) < EPS)
                    {
                        float3 sum = float3(0, 0, 0);
                        if (any(res.mat.reflection) || res.mat.eta > 0)
                        {
                            float3 refl = res.mat.reflection;
                            float2 normal = gradient(position) * sign;
                            if (res.mat.eta > 0)
                            {
                                float eta = res.mat.eta;
                                if (sign > 0) eta = 1 / eta;
                                float2 refractDir;
                                if (getRefractDir(direction, normal, eta, refractDir))
                                {
                                    sum += (1 - refl) * rayTrace2(position - normal * BASE, refractDir);
                                    
                                    // for debug
                                    // sum += rayTrace3(position - normal * BASE, refractDir);
                                }
                                else refl = float3(1, 1, 1);
                            }
                            if (any(refl))
                            {
                                float2 reflectDir;
                                getReflectDir(direction, normal, reflectDir);
                                sum += refl * rayTrace2(position + normal * BASE, reflectDir);
                            }
                        }
                        if (sign < 0) sum *= beerLambert(res.mat.absorbtion, dist);
						sum += res.mat.emission;
						return sum;
					}
                    dist += res.sd * sign;
                }
                return float3(0, 0, 0);
            }

			float random(float2 uv)
			{
				return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453123);
			}

            fixed4 frag (v2f f) : SV_Target
            {
				float3 res = float3(0, 0, 0);
				for (int i = 0; i < SAMPLE_NUMBER; i++)
				{
					float a = TWO_PI * (i + random(f.uv)) / SAMPLE_NUMBER;
                    // float a = 0;
                    res += rayTrace(f.uv, float2(cos(a), sin(a)));
				}
                // res += rayTrace(f.uv, float2(1, 0));
                res = clamp(res / SAMPLE_NUMBER, 0, 1);
                return fixed4(res, 1);

                // for debug
                // SceneData dd = getSceneDateAt(f.uv);
                // float2 normal = gradient(f.uv);
                // if (dd.sd > 0 && dd.sd < 0.01)
                // {
                //     float2 refractDir;
                //     float tp = sqrt(2) / 2;
				// 	if (getRefractDir(float2(tp, -tp), normal, 1 / 1.55, refractDir))
				// 		return fixed4((refractDir + float2(1, 1)) / 2, 0, 1);
                // }

                // return float4(0, 0, 0, 1);
                // return fixed4((gradient(f.uv) + float2(1, 1)) / 2, 0, 1);
                // float r = random(f.uv);
                // float flag = r < 0.5 ? 0 : 1;
                // return fixed4(flag, flag, flag, 1);
				// return float4((f.uv.x + f.uv.y) / 2, 0, 0, 1);
            }
            ENDCG
        }
    }
}
