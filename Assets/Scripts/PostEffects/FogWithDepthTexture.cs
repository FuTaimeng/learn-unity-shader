using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FogWithDepthTexture : PostEffect
{
	public Shader fogShader;
	private Material fogMaterial;
	public Material material
	{
		get
		{
			fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
			return fogMaterial;
		}
	}

	private Camera myCamera;

	[Range(0, 3)]
	public float fogDensity = 1;

	public Color fogColor = Color.white;

	public float fogStart = 0;
	public float fogEnd = 2;

	private void OnEnable()
	{
		myCamera = GetComponent<Camera>();
		myCamera.depthTextureMode |= DepthTextureMode.Depth;
	}

	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if (material != null)
		{
			Matrix4x4 frustumCorners = Matrix4x4.identity;
			Matrix4x4 viewProjectionInverse = (myCamera.projectionMatrix * myCamera.worldToCameraMatrix).inverse;

			float fov = myCamera.fieldOfView;
			float near = myCamera.nearClipPlane;
			float far = myCamera.farClipPlane;
			float aspect = myCamera.aspect;

			float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
			Vector3 toRight = myCamera.transform.right * halfHeight * aspect;
			Vector3 toTop = myCamera.transform.up * halfHeight;

			Vector3 TL = myCamera.transform.forward * near + toTop - toRight;
			TL /= near;
			Vector3 TR = myCamera.transform.forward * near + toTop + toRight;
			TR /= near;
			Vector3 BL = myCamera.transform.forward * near - toTop - toRight;
			BL /= near;
			Vector3 BR = myCamera.transform.forward * near - toTop + toRight;
			BR /= near;

			frustumCorners.SetRow(0, BL);
			frustumCorners.SetRow(1, BR);
			frustumCorners.SetRow(2, TR);
			frustumCorners.SetRow(3, TL);

			material.SetMatrix("_FrustumCorners", frustumCorners);

			material.SetFloat("_FogDensity", fogDensity);
			material.SetColor("_FogColor", fogColor);
			material.SetFloat("_FogStart", fogStart);
			material.SetFloat("_FogEnd", fogEnd);

			Graphics.Blit(source, destination, material);
		}
		else
		{
			Graphics.Blit(source, destination);
		}
	}
}
