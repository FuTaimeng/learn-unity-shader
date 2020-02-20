using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RTControl : MonoBehaviour
{
    public ComputeShader shader;
    public RenderTexture resTex { get; private set; }
    public RenderTexture tmpTex { get; private set; }

    public int resolution = 512;

    private int mainKernel, addupKernel;

    private void Start()
    {
        tmpTex = new RenderTexture(resolution, resolution, 0);
        tmpTex.format = RenderTextureFormat.ARGB32;
        tmpTex.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
        tmpTex.volumeDepth = 64;
        tmpTex.enableRandomWrite = true;
        tmpTex.Create();

        resTex = new RenderTexture(resolution, resolution, 0);
        resTex.format = RenderTextureFormat.ARGB32;
        resTex.enableRandomWrite = true;
        resTex.Create();

        shader.SetInt("resolution", resolution);

        mainKernel = shader.FindKernel("Main");
        addupKernel = shader.FindKernel("AddUp");
        shader.SetTexture(mainKernel, "tmpTex", tmpTex);
        shader.SetTexture(addupKernel, "tmpTex", tmpTex);
        shader.SetTexture(addupKernel, "resTex", resTex);
        //shader.SetTexture(mainKernel, "resTex", resTex);
    }

    private void Update()
    {
        shader.SetVector("time", new Vector2(Time.time, Time.deltaTime));

        shader.Dispatch(mainKernel, resolution, resolution, 1);
        shader.Dispatch(addupKernel, resolution, resolution, 1);
    }

    private void OnGUI()
    {
        GUI.DrawTexture(new Rect(0, 0, resolution, resolution), resTex);
    }

    private void OnDisable()
    {
        tmpTex.Release();
    }
}
