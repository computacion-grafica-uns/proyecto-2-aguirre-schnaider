using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraManager : MonoBehaviour
{
    //atributes

    //Camera atributes
    public Camera mainCamera;
    public Transform[] objects;
    public Material[] materials;
    private int index=0;

    //Light atributtes
    // Shader color properties
    public Color PointLightIntensity;
    public Color AmbientLight;
    public Color DirectionalLightIntensity;
    public Color SpotLightIntensity;
    // Shader vector properties
    public Vector4 PointLightPosition_w;
    public Vector4 DirectionalLightDirection_w;
    public Vector4 SpotLightPosition_w;
    public Vector4 SpotLightDirection_w;
    // Shader float property
    public float SpotLightAperture;

    // Camera movement attributes
    public float distance = 1f;
    public float horizontalSpeed = 50f;
    public float verticalSpeed = 50f;
    public float zoomSpeed = 2f;


    

    // Start is called before the first frame update
    void Start()
    {
        if (mainCamera != null && objects != null && objects[0]!=null)
        {
            // Colocar la cámara a una distancia y orientarla hacia el objeto
            Vector3 direction = (mainCamera.transform.position - objects[0].position).normalized;
            mainCamera.transform.position = objects[0].position + direction * distance;
            mainCamera.transform.LookAt(objects[0].position);

            // Coordinar propiedades de los shaders
            UpdateShaderProperties();
        }
    }

    void Update()
    {
        if (mainCamera == null || objects == null || objects[0] == null) return;

        // Movimiento horizontal (eje Y)
        if (Input.GetKey(KeyCode.LeftArrow))
        {
            Debug.Log("Left Arrow Pressed");
            mainCamera.transform.RotateAround(objects[index].position, Vector3.up, horizontalSpeed * Time.deltaTime); 
        }
        if (Input.GetKey(KeyCode.RightArrow))
            mainCamera.transform.RotateAround(objects[index].position, Vector3.up, -horizontalSpeed * Time.deltaTime);

        // Movimiento vertical (eje Right)
        float angleDelta = 0;
        if (Input.GetKey(KeyCode.UpArrow))
            angleDelta = verticalSpeed * Time.deltaTime;
        if (Input.GetKey(KeyCode.DownArrow))
            angleDelta = -verticalSpeed * Time.deltaTime;


        // Roto verticalmente solo si no estoy en el limite vertical
        mainCamera.transform.RotateAround(objects[index].position, mainCamera.transform.right, angleDelta);

        // Zoom
        if (Input.GetKey(KeyCode.W))
            mainCamera.transform.position += mainCamera.transform.forward * zoomSpeed * Time.deltaTime;
        if (Input.GetKey(KeyCode.S))
            mainCamera.transform.position -= mainCamera.transform.forward * zoomSpeed * Time.deltaTime;

        // Cambiar objeto objetivo
        if (Input.GetKeyDown(KeyCode.Space))
        {
            index = (index + 1) % objects.Length;
            while (objects[index]==null)
                index = (index + 1) % objects.Length;

            Vector3 objectPosition = objects[index].position;
            mainCamera.transform.rotation = Quaternion.LookRotation( (new Vector3(0,-1,1)).normalized, new Vector3(0,1,0));
            mainCamera.transform.position = objectPosition - mainCamera.transform.forward * distance;

        }

        // Actualizar propiedad en shader
        UpdateShaderProperties();
    }

    // Método para actualizar las propiedades en los materiales
    private void UpdateShaderProperties()
    {
        for (int i = 0; i < materials.Length; i++)
        {
            if (materials[i] != null)
            {
                materials[i].SetColor("_PointLightIntensity", PointLightIntensity);
                materials[i].SetColor("_AmbientLight", AmbientLight);
                materials[i].SetColor("_DirectionalLightIntensity", DirectionalLightIntensity);
                materials[i].SetColor("_SpotLightIntensity", SpotLightIntensity);
                materials[i].SetVector("_PointLightPosition_w", PointLightPosition_w);
                materials[i].SetVector("_DirectionalLightDirection_w", DirectionalLightDirection_w);
                materials[i].SetVector("_SpotLightPosition_w", SpotLightPosition_w);
                materials[i].SetVector("_SpotLightDirection_w", SpotLightDirection_w);
                materials[i].SetFloat("_SpotLightAperture", SpotLightAperture);
                materials[i].SetVector("_CameraPosition_w", mainCamera.transform.position);
            }
        }
    }
}
