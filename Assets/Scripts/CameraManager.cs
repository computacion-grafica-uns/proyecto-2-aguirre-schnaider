using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraManager : MonoBehaviour
{
    //atributes


    public Camera mainCamera;
    public Transform obj;
    public Material material;

    public float distance = 5f;
    public float horizontalSpeed = 50f;
    public float verticalSpeed = 50f;
    public float zoomSpeed = 2f;

    private float verticalAngle = 0f;
    private float minVerticalAngle = -89f;
    private float maxVerticalAngle = 89f;

    // Start is called before the first frame update
    void Start()
    {
        if (mainCamera != null && obj != null)
        {
            // Colocar la cámara a una distancia y orientarla hacia el objeto
            Vector3 direction = (mainCamera.transform.position - obj.position).normalized;
            mainCamera.transform.position = obj.position + direction * distance;
            mainCamera.transform.LookAt(obj.position);
            // Actualizo la posición de la cámara en el shader
            material.SetVector("_CameraPosition_w", mainCamera.transform.position);
        }
    }

    void Update()
    {
        if (mainCamera == null || obj == null || material == null) return;

        // Movimiento horizontal (eje Y)
        if (Input.GetKey(KeyCode.LeftArrow))
            mainCamera.transform.RotateAround(obj.position, Vector3.up, horizontalSpeed * Time.deltaTime);
        if (Input.GetKey(KeyCode.RightArrow))
            mainCamera.transform.RotateAround(obj.position, Vector3.up, -horizontalSpeed * Time.deltaTime);

        // Movimiento vertical (eje Right)
        float angleDelta = 0;
        if (Input.GetKey(KeyCode.UpArrow))
            angleDelta = verticalSpeed * Time.deltaTime;
        if (Input.GetKey(KeyCode.DownArrow))
            angleDelta = -verticalSpeed * Time.deltaTime;


        // Roto horizontalmente solo si no estoy en el limite vertical
        float newVerticalAngle = Mathf.Clamp(verticalAngle + angleDelta, minVerticalAngle, maxVerticalAngle);
        angleDelta = newVerticalAngle - verticalAngle;
        verticalAngle = newVerticalAngle;
        mainCamera.transform.RotateAround(obj.position, mainCamera.transform.right, angleDelta);

        // Zoom
        if (Input.GetKey(KeyCode.W))
            mainCamera.transform.position += mainCamera.transform.forward * zoomSpeed * Time.deltaTime;
        if (Input.GetKey(KeyCode.S))
            mainCamera.transform.position -= mainCamera.transform.forward * zoomSpeed * Time.deltaTime;

        // Actualizar propiedad en shader
        material.SetVector("_CameraPosition_w", mainCamera.transform.position);
    }
}
