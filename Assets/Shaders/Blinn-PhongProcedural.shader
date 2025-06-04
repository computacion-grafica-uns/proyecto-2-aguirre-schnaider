Shader "BlinnPhongProceduralMarmol"
{
    Properties
    {
        _PointLightIntensity("Point Light Intensity", Color) = (1,1,1,1)  //Intesidad de luz puntual
        _PointLightPosition_w("Point Light Position (world)", Vector) = (0,5,0,1)
        _AmbientLight("Ambient Light", Color) = (0.1,0.1,0.1,1)
        _DirectionalLightIntensity("Directional Light Intensity", Color) = (1,1,1,1)  //Intesidad de luz puntual
        _DirectionalLightDirection_w("Directional Light Direction (world)", Vector) = (0,-1,0,0) // Direccion de la luz direccional)
        _SpotLightIntensity("Spot Light Intensity", Color) = (1,1,1,1)  //Intesidad de luz puntual
        _SpotLightPosition_w("Spot Light Position (world)", Vector) = (0,5,0,1)
        _SpotLightDirection_w("Spot Light Direction (world)", Vector) = (0,-1,0,0) // Direccion de la luz direccional)
        _SpotLightAperture("Spot Light Aperture", float) = 30 // Apertura del cono de luz spot en grados

        _CameraPosition_w("Camera Position (world)", Vector) = (5,0,0,1)

        _MaterialKa("Material Ka", Vector) = (0,0,0,0)
        _MaterialKd("Material Kd", Vector) = (0,0,0,0)
        _MaterialKs("Material Ks", Vector) = (0,0,0,0)
        _Material_n("Material n", float) = 0.5

        _MarbleColorA("Marble Base Color", Color) = (1,1,1,1)
        _MarbleColorB("Marble Vein Color", Color) = (0.8,0.8,0.85,1)
        _MarbleVeinScale("Vein Scale", Float) = 10
        _MarbleVeinIntensity("Vein Intensity", Float) = 0.8
        _MarbleNoiseScale("Noise Scale", Float) = 20

    }
    SubShader
    {
        Pass
        {

            Tags { "RenderType"="Opaque" }
            LOD 200

             CGPROGRAM
    
            // use "vert" function as the vertex shader 
            #pragma vertex vert
            // use "frag" function as the pixel (fragment) shader
            #pragma fragment frag
            #include "UnityCG.cginc"

            // vertex shader inputs
            struct appdata
            {
                float4 position : POSITION; // vertex position
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            // vertex shader outputs ("vertex to fragment")
            struct v2f
            {
                float4 position : SV_POSITION; // clip space position
                float4 position_w : TEXCOORD1;
                float3 normal_w : TEXCOORD2; //world space
                float2 uv : TEXCOORD0;
            };

            float4 _PointLightIntensity;
            float4 _PointLightPosition_w;
            float4 _CameraPosition_w;
            float4 _AmbientLight;
            float4 _DirectionalLightIntensity;
            float4 _DirectionalLightDirection_w;
            float4 _SpotLightIntensity;
            float4 _SpotLightPosition_w;
            float4 _SpotLightDirection_w;
            float _SpotLightAperture;

            float4 _MaterialKa;
            float4 _MaterialKd;
            float4 _MaterialKs;
            float _Material_n;
            
            float4 _MarbleColorA;
            float4 _MarbleColorB;
            float _MarbleVeinScale;
            float _MarbleVeinIntensity;
            float _MarbleNoiseScale;

            //procedural marble texture
            // Simple pseudo-random noise based on UV
            float noise(float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898,78.233))) * 43758.5453);
            }
            // Generates a marble pattern using sine and noise
            float3 ProceduralMarble(float2 uv)
            {
                // Add some noise to the UVs for more natural veins
                float n = noise(uv * _MarbleNoiseScale);

                // Create a wavy pattern using sine, modulated by noise
                float veins = sin((uv.x + n * _MarbleVeinIntensity) * _MarbleVeinScale + uv.y * 2.0);

                // Map veins from [-1,1] to [0,1]
                veins = veins * 0.5 + 0.5;

                // Blend between base color and vein color
                return lerp(_MarbleColorA.rgb, _MarbleColorB.rgb, veins);
            }



            float3 calculateDiffuse(v2f i, float3 L , float3 lightIntensity){
                float3 N = normalize(i.normal_w);
                float DiffuseReflexivity = max(0, dot(N, L));
                return lightIntensity * DiffuseReflexivity * _MaterialKd * ProceduralMarble(i.uv);
            }

            float3 calculateSpecular(v2f i, float3 L, float3 lightIntensity){
                float3 N = normalize(i.normal_w);
                float3 V = normalize(i.position_w - _CameraPosition_w);
                float3 H = normalize(L+V);
                float SpecularReflexivity = pow(max(0, dot(N, H)), _Material_n);
                return lightIntensity * SpecularReflexivity * _MaterialKs;
            }

            float esIluminadoSpot(float3 L)
            {
                float ret = 0;
                if (dot(-L, normalize(_SpotLightDirection_w.xyz)) >= cos(_SpotLightAperture * UNITY_PI / 180.0))
                    ret = 1;
                return ret;
            }

            // vertex shader
            v2f vert(appdata v)
            {
                v2f o;

                o.position = UnityObjectToClipPos(v.position);
                o.position_w = mul(unity_ObjectToWorld, v.position);
                o.normal_w = normalize(UnityObjectToWorldNormal(v.normal));
                o.uv = v.uv;

                return o;
            }
            

        
            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 fragColor = 0; // Initialize fragment color)
                
                //parte de iluminación ambiente
                float3 ambient = _AmbientLight * _MaterialKa;
            

                //Luz puntual
                float3 L = normalize(_PointLightPosition_w - i.position_w);
                float3 luzPuntual = calculateDiffuse(i, L, _PointLightIntensity.rgb) + calculateSpecular(i, L , _PointLightIntensity.rgb);

                //Luz direccional
                L = -normalize(_DirectionalLightDirection_w.xyz);
                float3 luzDireccional = calculateDiffuse(i, L, _DirectionalLightIntensity.rgb) + calculateSpecular(i, L, _DirectionalLightIntensity.rgb);

                float3 luzSpot = 0;
                L = normalize(_SpotLightPosition_w.xyz - i.position_w);
                if ( esIluminadoSpot(L) )
                {
                    luzSpot = calculateDiffuse(i, L, _SpotLightIntensity.rgb) + calculateSpecular(i, L, _SpotLightIntensity.rgb);
                }

                fragColor.rgb = ambient + luzPuntual + luzDireccional + luzSpot;
                
                
                return fragColor;
            }
            ENDCG
        }
    }
}
