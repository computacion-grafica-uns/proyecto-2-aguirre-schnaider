Shader "PhongTexturaDirecto"
{
    Properties
    {
        _LightIntensity("Light Intensity", Color) = (1,1,1,1)  //Intesidad de luz puntual
        _LightPosition_w("Light Position (world)", Vector) = (0,5,0,1)
        _AmbientLight("Ambient Light", Color) = (0.1,0.1,0.1,1)

        _CameraPosition_w("Camera Position (world)", Vector) = (5,0,0,1)

        _MaterialKa("Material Ka", Vector) = (0,0,0,0)
        _MaterialKd("Material Kd", Vector) = (0,0,0,0)
        _MaterialKs("Material Ks", Vector) = (0,0,0,0)
        _Material_n("Material n", float) = 0.5

        [NoScaleOffset] _Texture ("Textura", 2D) = "white" {}
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
                float2 uv : TEXCOORD0;
                float3 normal_w : TEXCOORD2; //world space
            };

            float4 _MaterialColor;
            float4 _LightIntensity;
            float4 _LightPosition_w;
            float4 _CameraPosition_w;
            float4 _AmbientLight;
            float4 _MaterialKa;
            float4 _MaterialKd;
            float4 _MaterialKs;
            float _Material_n;
            sampler2D _Texture;


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
            
                //parte de iluminación difusa
                float3 diffuse;
                float3 L = normalize(_LightPosition_w - i.position_w);
                float3 N = normalize(i.normal_w);
                float DiffuseReflexivity = max(0, dot(N, L));
                diffuse = _LightIntensity * DiffuseReflexivity * _MaterialKd ;

                //parte de iluminación especular
                float3 specular;
                L = normalize(_LightPosition_w - i.position_w);
                N = normalize(i.normal_w);
                float3 V = normalize(i.position_w - _CameraPosition_w);
                float3 R = reflect(-L, N);
                float SpecularReflexivity = pow(max(0, dot(R, V)), _Material_n);
                specular = _LightIntensity * SpecularReflexivity * _MaterialKs;

                fragColor.rgb = ambient+ diffuse*tex2D(_Texture, i.uv) + specular;
                return fragColor;
            }


            ENDCG
        }
    }
}
