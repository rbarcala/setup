uniform float intensidad <
    string name = "Fuerza de la Onda";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.08;
    float step = 0.002;
> = 0.015;

uniform float velocidad <
    string name = "Velocidad del Fuego / Calor";
    string widget_type = "slider";
    float min = 0.5;
    float max = 15.0;
    float step = 0.5;
> = 5.0;

uniform float frecuencia_vertical <
    string name = "Frecuencia de Ondas";
    string widget_type = "slider";
    float min = 5.0;
    float max = 60.0;
    float step = 1.0;
> = 25.0;

uniform float tinte_calido <
    string name = "Tinte Cálido / Brasa";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.2;

uniform float origen_altura <
    string name = "Punto de Inicio Inferior (0 abajo, 1 arriba)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.1;

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;

    // El calor sube: la distorsión suele ser más intensa cerca de la base o fuente
    // Invertimos uv.y para que aumente o varíe hacia arriba
    float heat_factor = smoothstep(origen_altura - 0.1, 1.0, 1.0 - uv.y);

    // Suma de dos ondas sinusoidales para turbulencia fluida realista
    float t = elapsed_time * velocidad;
    float wave_x = sin(uv.y * frecuencia_vertical - t) * 0.6 +
                   cos(uv.y * (frecuencia_vertical * 1.8) - t * 1.4 + uv.x * 10.0) * 0.4;

    float wave_y = cos(uv.x * frecuencia_vertical - t * 0.8) * 0.3;

    float2 uv_distorted = uv;
    uv_distorted.x += wave_x * intensidad * heat_factor;
    uv_distorted.y += wave_y * (intensidad * 0.5) * heat_factor;

    float4 col = image.Sample(textureSampler, uv_distorted);

    // Tinte sutil anaranjado / rojizo si está activo
    if (tinte_calido > 0.001) {
        float3 glow_orange = float3(1.0, 0.45, 0.1);
        col.rgb = lerp(col.rgb, col.rgb * glow_orange * 1.3, tinte_calido * heat_factor);
    }

    return col;
}

