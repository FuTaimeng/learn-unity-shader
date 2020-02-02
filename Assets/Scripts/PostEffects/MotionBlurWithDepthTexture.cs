using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlurWithDepthTexture : PostEffect
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

	[Range(0, 1)]
	public float blurSize = 0.1f;

	[Range(1, 100)]
	public int sampleTimes = 30;

	private Matrix4x4 previousViewProjection;

	private Camera myCamera;

	private void OnEnable()
	{
		myCamera = GetComponent<Camera>();
		myCamera.depthTextureMode |= DepthTextureMode.Depth;

		previousViewProjection = myCamera.projectionMatrix * myCamera.worldToCameraMatrix;
	}

	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if (material != null)
		{
			material.SetFloat("_BlurSize", blurSize);
			material.SetFloat("_SampleTimes", sampleTimes);
			material.SetMatrix("_PreviousViewProjection", previousViewProjection);

			Matrix4x4 viewProjection = myCamera.projectionMatrix * myCamera.worldToCameraMatrix;
			Matrix4x4 viewProjectionInvese = viewProjection.inverse;
			material.SetMatrix("_ViewProjectionInverse", viewProjectionInvese);

			previousViewProjection = viewProjection;

			Graphics.Blit(source, destination, material);
		}
		else
		{
			Graphics.Blit(source, destination);
		}
	}

}
