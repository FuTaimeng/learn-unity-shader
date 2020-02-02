using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlur : PostEffect
{
	public Shader motionBlurShader;
	protected Material motionBlurMaterial;
	public Material material
	{
		get
		{
			motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
			return motionBlurMaterial;
		}
	}

	[Range(0, 0.9f)]
	public float blurAmount = 0.5f;

	private RenderTexture accumulateTexture;

	private void OnDisable()
	{
		DestroyImmediate(accumulateTexture);
	}

	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if (material != null)
		{
			if (accumulateTexture == null || accumulateTexture.width!=source.width || accumulateTexture.height != source.height)
			{
				DestroyImmediate(accumulateTexture);
				accumulateTexture = new RenderTexture(source.width, source.height, 0);
				accumulateTexture.hideFlags = HideFlags.HideAndDontSave;

				Graphics.Blit(source, accumulateTexture);
			}

			accumulateTexture.MarkRestoreExpected();

			material.SetFloat("_BlurAmount", blurAmount);

			Graphics.Blit(source, accumulateTexture, material);
			Graphics.Blit(accumulateTexture, destination);
		}
		else
		{
			Graphics.Blit(source, destination);
		}
	}
}
