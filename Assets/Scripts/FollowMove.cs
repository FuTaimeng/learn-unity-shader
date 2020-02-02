using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FollowMove : MonoBehaviour
{

	public GameObject target = null;
	public bool cling = false;

	private Vector3 delta = new Vector3(0, 0, 0);

    // Start is called before the first frame update
    void Start()
    {
		if (target != null && !cling)
		{
			delta = transform.position - target.transform.position;
		}
    }

    // Update is called once per frame
    void Update()
    {
		if (target != null)
		{
			transform.position = target.transform.position + delta;
		}
    }
}
