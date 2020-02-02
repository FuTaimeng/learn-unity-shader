using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightMove : MonoBehaviour
{

	public Vector3 faceTo = new Vector3(0, 0, 0);
	public float circleTime = 5;
	public bool reverse = false;

	private float R;
	private Vector2 center;
	private float radian;
	private float speed;

    // Start is called before the first frame update
    void Start()
    {
		Vector2 pos = new Vector2(transform.position.x, transform.position.z);
        center = new Vector2(faceTo.x, faceTo.z);
		Vector2 pointer = pos - center;
		R = pointer.magnitude;
		speed = 2 * Mathf.PI / circleTime;
		if (reverse) speed = -speed;
		radian = Vector2.Angle(new Vector2(1, 0), pointer);
    }

    // Update is called once per frame
    void Update()
    {
        radian += Time.deltaTime * speed;
		Vector3 pos;
		pos.x = center.x + Mathf.Cos(radian) * R;
		pos.z = center.y + Mathf.Sin(radian) * R;
		pos.y = transform.position.y;
		transform.position = pos;
		transform.LookAt(faceTo);
    }
}
