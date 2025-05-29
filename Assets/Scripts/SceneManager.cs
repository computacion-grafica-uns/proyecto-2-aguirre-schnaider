using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SceneManager : MonoBehaviour
{
    public GameObject objetoMedir;
    // Start is called before the first frame update
    void Start()
    {
        Debug.Log("Tamaño del objeto: " + objetoMedir.GetComponent<Renderer>().bounds.size);
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
