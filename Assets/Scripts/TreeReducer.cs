using System;
using System.IO;
using UnityEngine;

public class ObjBallRemover : MonoBehaviour
{
    void Start()
    {
        // Example usage
        string inputPath = "Assets/Models/Christmas_Tree_V2_L2.123cadbfe049-8aa0-4108-819e-a5524a9b8e49/ArbolConBolas.obj";
        string outputPath = "Assets/Models/nuevoArbol.obj";
        RemoveBallsFromObj(inputPath, outputPath);
    }


    public void RemoveBallsFromObj(string inputPath, string outputPath)
    {
        using (var reader = new StreamReader(inputPath))
        using (var writer = new StreamWriter(outputPath))
        {
            string line;
            bool skip = false;
            while ((line = reader.ReadLine()) != null)
            {
                // Check for object line
                if (line.StartsWith("object ", StringComparison.OrdinalIgnoreCase))
                {
                    // If this is a ball object, start skipping
                    if (line.ToLower().Contains("object ball"))
                    {
                        skip = true;
                        continue; // Don't write this line
                    }
                    else
                    {
                        skip = false;
                    }
                }

                if (!skip)
                {
                    writer.WriteLine(line);
                }
            }
        }
    }
}
