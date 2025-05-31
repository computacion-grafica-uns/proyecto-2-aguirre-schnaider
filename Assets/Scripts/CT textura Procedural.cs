using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CTtexturaProcedural : MonoBehaviour
{
    // Campo público para asignar el material desde el inspector
    public Material cookMaterial;

    void Start()
    {
        // Crear la textura procedural
        Texture2D tex = new Texture2D(256, 256);

        for (int y = 0; y < tex.height; y++)
        {
            for (int x = 0; x < tex.width; x++)
            {
                // Patrón de tablero de ajedrez
                Color c = ((x / 32 + y / 32) % 2 == 0) ? Color.red : Color.yellow;
                tex.SetPixel(x, y, c);
            }
        }

        tex.Apply();

        // Clonar el material y aplicar la textura procedural
        Renderer rend = GetComponent<Renderer>();
        Material mat = new Material(cookMaterial); // clon del material base
        mat.SetTexture("_MainTex", tex);

        rend.material = mat; // aplicar material solo a este objeto
    }

    void Update()
    {
        // No es necesario actualizar nada por ahora
    }
}
