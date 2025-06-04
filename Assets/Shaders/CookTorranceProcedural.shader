Shader "CookTorranceProcedural"
{
    Properties
    {
        _AmbientLight("Ambient Light", Color) = (0.3,0.3,0.3,1)
        _PointLightIntensity("Point Light Intensity", Color) = (1,1,1,1)
        _PointLightPosition_w("Point Light Position (world)", Vector) = (0,5,0,1)
        _DirectionalLightIntensity("Directional Light Intensity", Color) = (1,1,1,1)
        _DirectionalLightDirection_w("Directional Light Direction (world)", Vector) = (0,-1,0,0)
        _SpotLightIntensity("Spot Light Intensity", Color) = (1,1,1,1)
        _SpotLightPosition_w("Spot Light Position (world)", Vector) = (0,5,0,1)
        _SpotLightDirection_w("Spot Light Direction (world)", Vector) = (0,-1,0,0)
        _SpotLightAperture("Spot Light Aperture", float) = 30
        _CameraPosition_w("Camera Position (world)", Vector) = (5,0,0,1)
        _MaterialKd("Kd Material", Color) = (1, 1, 1, 1)
        _Fresnel("Reflectancia de Fresnel", color) = (0.004,0.004,0.004)
        _Rugosidad("Rugosidad", Range(0,1)) = 0.0   


        //PARA TEXTURA PROCEDURAL
        _MarbleColorA("Marble Base Color", Color) = (1,1,1,1)
        _MarbleColorB("Marble Vein Color", Color) = (0.8,0.8,0.85,1)
        _MarbleVeinScale("Vein Scale", Float) = 10
        _MarbleVeinIntensity("Vein Intensity", Float) = 0.8
        _MarbleNoiseScale("Noise Scale", Float) = 20


        _MaterialKa("Ka Material", Color) = (0.1, 0.1, 0.1, 1)

    }

    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vertexShader
            #pragma fragment fragmentShader
            #include "UnityCG.cginc"

            struct vertice {
                float4 position : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float3 normal_w : TEXCOORD0;
                float3 viewDir_w : TEXCOORD1;
                float4 position_w : TEXCOORD2;
                float2 uv : TEXCOORD3;
            };

            float4 _PointLightIntensity;
            float4 _PointLightPosition_w;
            float4 _AmbientLight;
            float4 _DirectionalLightIntensity;
            float4 _DirectionalLightDirection_w;
            float4 _SpotLightIntensity;
            float4 _SpotLightPosition_w;
            float4 _SpotLightDirection_w;
            float _SpotLightAperture;

            float4 _CameraPosition_w;

            float4 _MaterialKd;
            float4 _MaterialKa;
            float3 _Fresnel;
            float _Rugosidad;


            //para textura procedural
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


            float3 aproxFresnel_Smith(float3 V, float3 H) {
                float3 F0 = _Fresnel;
                return F0 + (1 - F0) * pow(1.0 - max(0, dot(V, H)), 5);
            }

            float distribucionNormalesGGX(float3 N, float3 H) {
                const float PI = 3.14159265;
                float alpha = pow(_Rugosidad, 2);
                float dotNH2 = pow(max(0.001, dot(N, H)), 2);
                float denom = PI * pow(dotNH2 * (alpha * alpha - 1) + 1, 2);
                return (alpha * alpha) / denom;
            }

            float aproximacionSchlickGGX(float3 M, float3 N) {
                float alpha = pow(_Rugosidad, 2);
                float k = alpha / 2;
                float cosMN = max(0.001, dot(M, N));
                float denom = (cosMN * (1 - k)) + k;
                return cosMN / denom;
            }

            float enmascaradoSombras_Smith(float3 L, float3 V, float3 N) {
                float G1L = aproximacionSchlickGGX(L, N);
                float G1V = aproximacionSchlickGGX(V, N);
                return G1L * G1V;
            }

            float3 terminoEspecularCook_Torrance(float3 L, float3 N, float3 V) {
                float3 H = normalize(L + V);
                float3 F = aproxFresnel_Smith(V, H);
                float D = distribucionNormalesGGX(N, H);
                float G = enmascaradoSombras_Smith(L, V, N);
                return F * D * G / (4 * max(0.001, dot(N, L)) * max(0.001, dot(N, V)));
            }

            float3 terminoDifusoBlinn_Phong(float3 intensidadLuz, float3 L, float3 N, v2f f) {
                float3 luzDifusa = intensidadLuz;
                float3 reflexionDifusa = _MaterialKd.rgb * max(0.001, dot(N, L));
                return luzDifusa * reflexionDifusa;
            }

            float esIluminadoSpot(float3 L) {
                return dot(-L, normalize(_SpotLightDirection_w.xyz)) >= cos(_SpotLightAperture * UNITY_PI / 180.0) ? 1.0 : 0.0;
            }

            v2f vertexShader(vertice v) {
                v2f o;
                float4 worldPos = mul(unity_ObjectToWorld, v.position);
                o.vertex = UnityObjectToClipPos(v.position);
                o.normal_w = UnityObjectToWorldNormal(v.normal);
                o.viewDir_w = normalize(_WorldSpaceCameraPos - worldPos);
                o.uv = v.uv;
                o.position_w = worldPos;
                return o;
            }

            fixed4 fragmentShader(v2f i) : SV_Target {
                float3 N = normalize(i.normal_w);
                float3 V = normalize(i.viewDir_w);

                //agrego las texturas
                float3 blendedTex = ProceduralMarble(i.uv);
               


                
                float3 LPuntual = normalize(_PointLightPosition_w.xyz - i.position_w.xyz);
                float3 LDireccional = -normalize(_DirectionalLightDirection_w.xyz);
                float3 LSpot = normalize(_SpotLightPosition_w.xyz - i.position_w.xyz);

                float3 ambiente = _AmbientLight.rgb * _MaterialKa.rgb;

                //luz puntual
                float3 difusoPuntual = blendedTex * terminoDifusoBlinn_Phong(_PointLightIntensity.rgb, LPuntual, N, i) / 3.14159265;
                //luz direccional
                float3 difusoDireccional = blendedTex * terminoDifusoBlinn_Phong(_DirectionalLightIntensity.rgb, LDireccional, N, i) / 3.14159265;
                float3 difusoSpot = float3(0, 0, 0);

                float3 especularPuntual = _PointLightIntensity.rgb * terminoEspecularCook_Torrance(LPuntual, N, V);
                float3 especularDireccional = _DirectionalLightIntensity.rgb * terminoEspecularCook_Torrance(LDireccional, N, V);
                float3 especularSpot = float3(0, 0, 0);

                if (esIluminadoSpot(LSpot)) {
                    difusoSpot = blendedTex * terminoDifusoBlinn_Phong(_SpotLightIntensity.rgb, LSpot, N, i) / 3.14159265;
                    especularSpot =  _SpotLightIntensity.rgb * terminoEspecularCook_Torrance(LSpot, N, V);
                }

                float3 cookTorranceTotal = ambiente +
                                           (difusoPuntual + especularPuntual) +
                                           (difusoDireccional + especularDireccional) +
                                           (difusoSpot + especularSpot);

                return float4(cookTorranceTotal, 1);
            }
            ENDCG
        }
    }
    FallBack Off
}
