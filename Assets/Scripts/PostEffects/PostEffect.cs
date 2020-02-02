using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class PostEffect : MonoBehaviour
{
    protected void CheckResources()
	{
		if (!CheckSupport())
		{
			enabled = false;
		}
	}

	protected bool CheckSupport()
	{
		if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false)
		{
			Debug.LogWarning("This platform does not support image effects or render textures!");
			return false;
		}
		else return true;
	}

	protected Material CheckShaderAndCreateMaterial(Shader shader, Material material)
	{
		if (shader == null || !shader.isSupported)
		{
			return null;
		}
		if (shader.isSupported && material && material.shader == shader)
		{
			return material;
		}
		material = new Material(shader);
		material.hideFlags = HideFlags.DontSave;

		if (material) return material;
		else return null;
	}

	protected void Start()
	{
		CheckResources();
	}
}
