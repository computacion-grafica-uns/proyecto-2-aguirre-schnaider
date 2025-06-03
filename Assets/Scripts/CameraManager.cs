using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraManager : MonoBehaviour
{
    //atributes

    //Camera atributes
    public Camera orbitalCamera;
    public Camera firstPersonCamera;
    private int cameraMode = 0; // 0 for orbital, 1 for first person

    public Transform[] objects;
    public Material[] materials;
    private int indexObject = 0;

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

    public float firstPersonWalkingSpeed = 1.25f;
    public float firstPersonRotatingSpeed;



    // Start is called before the first frame update
    void Start()
    {
        if (orbitalCamera != null && firstPersonCamera != null && objects != null && objects[0] != null)
        {
            // Colocar la cámara a una distancia y orientarla hacia el objeto
            Vector3 direction = (orbitalCamera.transform.position - objects[0].position).normalized;
            orbitalCamera.transform.position = objects[0].position + direction * distance;
            orbitalCamera.transform.LookAt(objects[0].position);

            // Inicializo la posición de la cámara de primera persona
            firstPersonCamera.transform.position = new Vector3(0,1.6f,0);
            firstPersonCamera.transform.rotation = Quaternion.LookRotation(Vector3.right, Vector3.up);
            firstPersonRotatingSpeed = 150f;

            // Desactivo la camara de primera persona y los dos audio listeners (no hay audio)
            firstPersonCamera.enabled = false;
            orbitalCamera.GetComponent<AudioListener>().enabled = false;
            firstPersonCamera.GetComponent<AudioListener>().enabled = false;

            // Coordinar propiedades de los shaders
            UpdateShaderProperties();
        }
    }

    void Update()
    {
        if (orbitalCamera == null || firstPersonCamera == null || objects == null || objects[0] == null) return;

        if (cameraMode == 0) // Orbital camera mode
        {
            HandleOrbitalCameraMovement();
        }
        else if (cameraMode == 1) // First person camera mode
        {
            HandleFirstPersonCameraMovement();
        }
        
        if( Input.GetKeyDown(KeyCode.Tab))
        {
            cameraMode = (cameraMode + 1) % 2; // Alternar entre 0 y 1
            if (cameraMode == 0)
            {
                firstPersonCamera.enabled = false;
                orbitalCamera.enabled = true;
            }
            else
            {
                orbitalCamera.enabled = false;
                firstPersonCamera.enabled = true;
            }
        }

        // Comportamiento de luces
        
        if (Input.GetKeyDown(KeyCode.U))
        {
            if (AmbientLight.r == 0f && AmbientLight.g == 0f && AmbientLight.b == 0f)
                AmbientLight = new Color(0.2f, 0.2f, 0.2f, 1f);
            else
                AmbientLight = new Color(0f, 0f, 0f, 1f);
        }
        if (Input.GetKeyDown(KeyCode.I))
        {
            if (PointLightIntensity.r == 0f && PointLightIntensity.g == 0f && PointLightIntensity.b == 0f)
                PointLightIntensity = new Color(0.8f, 0.8f, 0.8f, 1f);
            else
                PointLightIntensity = new Color(0f, 0f, 0f, 1f);
        }
        if (Input.GetKeyDown(KeyCode.O))
        {
            if (DirectionalLightIntensity.r == 0f && DirectionalLightIntensity.g == 0f && DirectionalLightIntensity.b == 0f)
                DirectionalLightIntensity = new Color(0.8f, 0.8f, 0.8f, 1f);
            else
                DirectionalLightIntensity = new Color(0f, 0f, 0f, 1f);
        }
        if (Input.GetKeyDown(KeyCode.P))
        {
            if (SpotLightIntensity.r == 0f && SpotLightIntensity.g == 0f && SpotLightIntensity.b == 0f)
                SpotLightIntensity = new Color(0.8f, 0.8f, 0.8f, 1f);
            else
                SpotLightIntensity = new Color(0f, 0f, 0f, 1f);
        }

        // Actualizar propiedad en shader
        UpdateShaderProperties();

    }
    
    private void AlternarLuz(Color IntensidadLuz)
    {
        if (IntensidadLuz.r == 0f && IntensidadLuz.g == 0f && IntensidadLuz.b == 0f)
            IntensidadLuz = new Color(0.8f, 0.8f, 0.8f, 1f);
        else
            IntensidadLuz = new Color(0f, 0f, 0f, 1f);
    }

    private void HandleOrbitalCameraMovement()
    {
        // Movimiento horizontal (eje Y)
        if (Input.GetKey(KeyCode.LeftArrow))
        {
            orbitalCamera.transform.RotateAround(objects[indexObject].position, Vector3.up, horizontalSpeed * Time.deltaTime);
        }
        if (Input.GetKey(KeyCode.RightArrow))
            orbitalCamera.transform.RotateAround(objects[indexObject].position, Vector3.up, -horizontalSpeed * Time.deltaTime);

        // Movimiento vertical (eje Right)
        float angleDelta = 0;
        if (Input.GetKey(KeyCode.UpArrow))
            angleDelta = verticalSpeed * Time.deltaTime;
        if (Input.GetKey(KeyCode.DownArrow))
            angleDelta = -verticalSpeed * Time.deltaTime;


        // Roto verticalmente 
        orbitalCamera.transform.RotateAround(objects[indexObject].position, orbitalCamera.transform.right, angleDelta);

        // Zoom
        if (Input.GetKey(KeyCode.W))
            orbitalCamera.transform.position += orbitalCamera.transform.forward * zoomSpeed * Time.deltaTime;
        if (Input.GetKey(KeyCode.S))
            orbitalCamera.transform.position -= orbitalCamera.transform.forward * zoomSpeed * Time.deltaTime;

        // Cambiar objeto objetivo
        if (Input.GetKeyDown(KeyCode.Space))
        {
            indexObject = (indexObject + 1) % objects.Length;
            while (objects[indexObject] == null)
                indexObject = (indexObject + 1) % objects.Length;

            Vector3 objectPosition = objects[indexObject].position;
            orbitalCamera.transform.rotation = Quaternion.LookRotation((new Vector3(0, -1, 1)).normalized, new Vector3(0, 1, 0));
            orbitalCamera.transform.position = objectPosition - orbitalCamera.transform.forward * distance;

        }
    }

    private void HandleFirstPersonCameraMovement()
    {
        // Movimiento de WASD
        if ( Input.GetKey(KeyCode.W) )
        {
            firstPersonCamera.transform.position += new Vector3(firstPersonCamera.transform.forward.x,0 , firstPersonCamera.transform.forward.z).normalized * firstPersonWalkingSpeed * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.S))
        {
            firstPersonCamera.transform.position -= new Vector3(firstPersonCamera.transform.forward.x, 0, firstPersonCamera.transform.forward.z).normalized * firstPersonWalkingSpeed * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.A))
        {
            firstPersonCamera.transform.position -= firstPersonCamera.transform.right * firstPersonWalkingSpeed * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.D))
        {
            firstPersonCamera.transform.position += firstPersonCamera.transform.right * firstPersonWalkingSpeed * Time.deltaTime;
        }

        // Rotación de la cámara
        float inputY = Input.GetAxis("Mouse Y");
        float inputX = Input.GetAxis("Mouse X");
        // Rotación vertical
        if ( inputY != 0)
        {
            float angleY = -firstPersonRotatingSpeed * Time.deltaTime * inputY;
            firstPersonCamera.transform.Rotate(firstPersonCamera.transform.right, angleY, Space.World);
        }
        // Rotación horizontal
        if (inputX != 0)
        {
            float angleX = firstPersonRotatingSpeed * Time.deltaTime * inputX;
            firstPersonCamera.transform.Rotate(Vector3.up, angleX, Space.World);
        }
        
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
                if ( cameraMode == 0 )
                    materials[i].SetVector("_CameraPosition_w", orbitalCamera.transform.position);
                else
                    materials[i].SetVector("_CameraPosition_w", firstPersonCamera.transform.position);
            }
        }
    }
}
