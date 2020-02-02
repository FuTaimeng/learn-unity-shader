using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bloom : PostEffect
{
	public Shader bloomShader;
	protected Material bloomMaterial;
	public Material material
	{
		get
		{
			bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
			return bloomMaterial;
		}
	}

	[Range(0, 4)]
	public int inerations = 3;

	[Range(0.2f, 3)]
	public float blurSpread = 0.6f;

	[Range(1, 8)]
	public int downSample = 2;

	[Range(0, 4)]
	public float luminanceThreshold = 0.6f;

	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if (material != null)
		{
			int w = source.width / downSample;
			int h = source.height / downSample;
			RenderTexture buffer = RenderTexture.GetTemporary(w, h, 0);
			buffer.filterMode = FilterMode.Bilinear;
			RenderTexture buffer_tp = RenderTexture.GetTemporary(w, h, 0);

			material.SetFloat("_LuminanceThreshold", luminanceThreshold);

			Graphics.Blit(source, buffer, material, 0);

			for (int i = 0; i < inerations; i++)
			{
				material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

				Graphics.Blit(buffer, buffer_tp, material, 1);
				Graphics.Blit(buffer_tp, buffer, material, 2);
			}

			material.SetTexture("_Bloom", buffer);

			Graphics.Blit(source, destination, material, 3);

			RenderTexture.ReleaseTemporary(buffer);
			RenderTexture.ReleaseTemporary(buffer_tp);
		}
		else
		{
			Graphics.Blit(source, destination);
		}
	}
}
