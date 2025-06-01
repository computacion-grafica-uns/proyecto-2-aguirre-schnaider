Shader "ToonTexturaDirecto"
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
        
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _Shininess("Shininess", float) = 0.5
        _ShadeLevels ("Shade Levels", Range(1,5)) = 3

        [NoScaleOffset] _Texture ("Textura", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

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


            float4 _BaseColor;
            float4 _SpecularColor;
            float _Shininess;
            int _ShadeLevels;
            sampler2D _Texture;


            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD2;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD0;
            };

            float esIluminadoSpot(float3 L){
                 return dot(-L, normalize(_SpotLightDirection_w.xyz)) >= cos(_SpotLightAperture * UNITY_PI / 180.0);
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = v.uv;
                return o;
            }

            float3 Posterize(float3 color, float levels)
            {
                return floor(color * levels) / (levels - 1.0);
            }


            fixed4 frag(v2f i) : SV_Target
            {
                float3 texColor = Posterize(tex2D(_Texture, i.uv).rgb, _ShadeLevels*2);
                // Luz puntual
                float3 N = normalize(i.worldNormal);
                float3 L = normalize(_PointLightPosition_w.xyz - i.worldPos);
                //termino difuso
                float NdotL = max(0.0, dot(N, L));
                float level = floor(NdotL * _ShadeLevels) / (_ShadeLevels - 1.0); // Toon step based on number of shade levels
                float3 luzPuntual = _BaseColor.rgb * level * _PointLightIntensity * texColor; 
                //termino especular
                float3 V = normalize(i.worldPos - _CameraPosition_w);
                float3 H = normalize(L+V);
                float SpecularReflexivity = pow(max(0.0, dot(N, H)), _Shininess);
                // Apply toon step to specular
                float specularLevel = floor(SpecularReflexivity * _ShadeLevels) / (_ShadeLevels - 1.0);
                luzPuntual += _SpecularColor.rgb * specularLevel * _PointLightIntensity.rgb;



                // Luz direccional
                L = -normalize(_DirectionalLightDirection_w.xyz);
                //termino difuso
                NdotL = max(0.0, dot(N, L));
                level = floor(NdotL * _ShadeLevels) / (_ShadeLevels - 1.0);
                float3 luzDireccional = _DirectionalLightIntensity.rgb * _BaseColor* level * texColor;
                //termino especular
                H = normalize(L+ V);
                SpecularReflexivity = pow(max(0.0, dot(N, H)), _Shininess);
                // Apply toon step to specular
                specularLevel = floor(SpecularReflexivity * _ShadeLevels) / (_ShadeLevels - 1.0);
                luzDireccional += _SpecularColor.rgb * specularLevel * _DirectionalLightIntensity.rgb;

                // Luz spot
                float3 luzSpot = 0;
                L = normalize(_SpotLightPosition_w.xyz - i.worldPos);
                if ( esIluminadoSpot(L)){
                    //termino difuso
                    NdotL = max(0.0, dot(N, L));
                    level = floor(NdotL * _ShadeLevels) / (_ShadeLevels - 1.0);
                    luzSpot = _BaseColor.rgb *level * _SpotLightIntensity.rgb * texColor;
                    //termino especular
                    H = normalize(L + V);
                    SpecularReflexivity = pow(max(0.0, dot(N, H)), _Shininess);
                    // Apply toon step to specular
                    specularLevel = floor(SpecularReflexivity * _ShadeLevels) / (_ShadeLevels - 1.0);   
                    luzSpot += _SpecularColor.rgb * specularLevel * _SpotLightIntensity.rgb;
                }

                return fixed4(_AmbientLight * _BaseColor.rgb *texColor  +  luzPuntual  + luzDireccional + luzSpot, 1.0);

                // Detalle de sombra 
                
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}