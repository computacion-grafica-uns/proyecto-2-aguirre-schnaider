Shader "OrenNayarBPTexturaDirecto"
{
    Properties
    {
        _LightIntensity("Light Intensity", Color) = (1,1,1,1)  //Intesidad de luz puntual
        _LightPosition_w("Light Position (world)", Vector) = (0,5,0,1)
        _AmbientLight("Ambient Light", Color) = (0.1,0.1,0.1,1)
        
        _CameraPosition_w("Camera Position (world)", Vector) = (5,0,0,1)

        _Color ("Diffuse Color", Color) = (1,1,1,1)
        _Roughness ("Roughness", Range(0.0, 1.0)) = 0.5
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
        
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 position : POSITION; // vertex position
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 position : SV_POSITION; // clip space position
                float4 position_w : TEXCOORD1;
                float3 normal_w : TEXCOORD2; //world space
                float2 uv : TEXCOORD0;
            };

            float4 _MaterialColor;
            float4 _LightIntensity;
            float4 _LightPosition_w;
            float4 _CameraPosition_w;
            float4 _AmbientLight;
            fixed4 _Color;
            float _Roughness;
            float4 _MaterialKs;
            float _Material_n;
            sampler2D _Texture;

            v2f vert (appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.position);
                o.position_w = mul(unity_ObjectToWorld, v.position);
                o.normal_w = UnityObjectToWorldNormal(v.normal);
                o.uv = v.uv;

                return o;
            }
        
            float orenNayar(float3 N, float3 L, float3 V, float sigma)
            {
                float3 R = reflect(-L, N);

                float NL = max(0.0, dot(N, L));
                float NV = max(0.0, dot(N, V));

                float theta_i = acos(NL);
                float theta_r = acos(NV);

                float alpha = max(theta_i, theta_r);
                float beta = min(theta_i, theta_r);

                float sigma2 = sigma * sigma;
                float A = 1.0 - 0.5 * (sigma2 / (sigma2 + 0.33));
                float B = 0.45 * (sigma2 / (sigma2 + 0.09));

                float3 Lproj = normalize(L - N * dot(N, L));
                float3 Vproj = normalize(V - N * dot(N, V));
                float gamma = max(0.0, dot(Lproj, Vproj));

                return NL * (A + B * gamma * sin(alpha) * tan(beta));
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 N = normalize(i.normal_w);
                float3 L = normalize(_LightPosition_w - i.position_w);
                float3 V = normalize(i.position_w - _CameraPosition_w);

                float diff = orenNayar(N, L, V, _Roughness);

                //parte de iluminación especular de Blinn-Phong
                float3 specular;
                float3 H = normalize(L+V);
                float SpecularReflexivity = pow(max(0, dot(N, H)), _Material_n);
                specular = _LightIntensity * SpecularReflexivity * _MaterialKs;

                fixed3 finalColor =_AmbientLight * _Color + _LightIntensity.rgb * _Color.rgb * diff * tex2D(_Texture, i.uv) + specular;
                return fixed4(finalColor, 1.0);
            }

            ENDCG
        }
    }    
    FallBack "Diffuse"
}
