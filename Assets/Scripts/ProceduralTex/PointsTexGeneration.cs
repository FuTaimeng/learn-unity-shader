using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PointsTexGeneration : MonoBehaviour
{
    public Material material;

    public int texWidth = 512;
    public Color bgColor = Color.white;
    public Color circleColor = Color.red;
    public float blurFactor = 2.0f;

    private int pre_texWidth;
    private Color pre_bgColor;
    private Color pre_circleColor;
    private float pre_blurFactor;

    private Texture2D texture;

    private void Start()
    {
        if (material == null)
        {
            Renderer renderer = gameObject.GetComponent<Renderer>();
            material = renderer.sharedMaterial;
        }
    }

    private void Update()
    {
        if (pre_texWidth != texWidth || pre_bgColor != bgColor || pre_circleColor != circleColor || pre_blurFactor != blurFactor)
        {
            UpdateMaterial();
            pre_texWidth = texWidth;
            pre_bgColor = bgColor;
            pre_circleColor = circleColor;
            pre_blurFactor = blurFactor;
        }
    }

    public void UpdateMaterial()
    {
        texture = GenerateTexture();
        material.SetTexture("_MainTex", texture);
    }

    private Texture2D GenerateTexture()
    {
        Texture2D tex = new Texture2D(texWidth, texWidth);

        float interval = texWidth / 4.0f;
        float radius = texWidth / 10.0f;
        float edgeBlur = 1.0f / blurFactor;

        for (int w = 0; w < texWidth; w++)
        {
            for (int h = 0; h < texWidth; h++)
            {
                Color pixel = bgColor;
                for (int i = 0; i < 3; i++)
                {
                    for (int j = 0; j < 3; j++)
                    {
                        Vector2 center = new Vector2(interval * (i + 1), interval * (j + 1));
                        float dist = Vector2.Distance(new Vector2(w, h), center) - radius;
                        Color col = MixColor(circleColor, new Color(pixel.r, pixel.g, pixel.b, 0.0f), Mathf.SmoothStep(0.0f, 1.0f, dist * edgeBlur));
                        pixel = MixColor(pixel, col, col.a);
                    }
                }
                tex.SetPixel(w, h, pixel);
            }
        }
        tex.Apply();
        return tex;
    }

    private Color MixColor(Color color0, Color color1, float mixFactor)
    {
        Color mixColor;
        mixColor.r = Mathf.Lerp(color0.r, color1.r, mixFactor);
        mixColor.g = Mathf.Lerp(color0.g, color1.g, mixFactor);
        mixColor.b = Mathf.Lerp(color0.b, color1.b, mixFactor);
        mixColor.a = Mathf.Lerp(color0.a, color1.a, mixFactor);
        return mixColor;
    }
}
