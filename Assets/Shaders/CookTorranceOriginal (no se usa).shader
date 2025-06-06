Shader "Custom/CookTorrance"
{
    Properties
    {
        _MaterialKd("Kd Material", Color) = (0, 0, 0, 0) // color difuso del material
        _Fresnel("Reflectancia de Fresnel", color) = (0,0,0)// valor base de reflectancia
        _Rugosidad("Rugosidad", Range(0,1)) = 0.0 //controla que tan rugosa es la superficie
        _MainTex("Textura Difusa", 2D) = "white" {} //para la textura 2d
    }

    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vertexShader
            #pragma fragment fragmentShader
            #include "UnityCG.cginc"

             //
            struct vertice {
                float4 position : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0; //para usar una textura 2d
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float3 normal_w : TEXCOORD0;
                float3 viewDir_w : TEXCOORD1;
                float2 uv : TEXCOORD2; // paso textura 2d al fragment

            };

            //las variables globales
            float4 _MaterialKd;
            float3 _Fresnel;
            float _Rugosidad;
            sampler2D _MainTex;



            //FUNCIONES PRINCIPALES PARA MODELO COOK TORRANCE

            //Con fresnel defino cuanto refleja un material dependiendo del angulo de vision F 
            float3 aproxFresnel_Smith(float3 V, float3 H)
            {
                float3 F0 = _Fresnel;
                return F0 + (1 - F0) * pow(1.0 - max(0, dot(V, H)), 5);
            }
            //Represento la micro superficie rugosa - micro normales  D
            float distribucionNormalesGGX(float3 N, float3 H)
            {
                const float PI = 3.14159265;
                float alpha = pow(_Rugosidad, 2);
                float dotNH2 = pow(max(0, dot(N, H)), 2);
                float denom = PI * pow(dotNH2 * (alpha * alpha - 1) + 1, 2);
                return (alpha * alpha) / denom;
            }
            // para el sombreado 
            float aproximacionSchlickGGX(float3 M, float3 N)
            {
                float alpha = pow(_Rugosidad, 2);
                float k = alpha / 2;
                float cosMN = max(0, dot(M, N));
                float denom = (cosMN * (1 - k)) + k;
                return cosMN / denom;
            }
            //combino el resultado de la apximacion ggx para la luz, la vista y la normal G
            float enmascaradoSombras_Smith(float3 L, float3 V, float3 N)
            {
                float G1L = aproximacionSchlickGGX(L, N);
                float G1V = aproximacionSchlickGGX(V, N);
                return G1L * G1V;
            }

            //
            float3 terminoEspecularCook_Torrance(float3 L, float3 N, float3 V)
            {
                float3 H = normalize(L + V);
                float3 F = aproxFresnel_Smith(V, H);
                float D = distribucionNormalesGGX(N, H);
                float G = enmascaradoSombras_Smith(L, V, N);
                return F * D * G / (4 * max(0, dot(N, L)) * max(0, dot(N, V)));
            }

            v2f vertexShader(vertice v)
            {
                v2f o;
                float4 worldPos = mul(unity_ObjectToWorld, v.position);
                o.vertex = UnityObjectToClipPos(v.position);
                o.normal_w = UnityObjectToWorldNormal(v.normal);
                o.viewDir_w = normalize(_WorldSpaceCameraPos - worldPos);
                o.uv = v.uv;
                return o;
            }

            fixed4 fragmentShader(v2f i) : SV_Target
            {
                float3 N = normalize(i.normal_w);
                float3 V = normalize(i.viewDir_w);
                float3 difusoColor;


                // Direccion de luz fija 
                float3 L = normalize(float3(0.577, 0.577, 0.577));

                //Difuso de lambert
                float3 difuso = _MaterialKd*tex2D(_MainTex, i.uv).rgb * max(0, dot(N, L));


                float3 especular = terminoEspecularCook_Torrance(L, N, V);

                float3 colorFinal = difuso + especular;
                return float4(colorFinal, 1);
            }
            ENDCG
        }
    }
    FallBack Off
}