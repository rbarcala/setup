uniform float intensidad <
    string name = "Fuerza de la Distorsión de Calor";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.04;
    float step = 0.001;
> = 0.012;

uniform float velocidad <
    string name = "Velocidad de Subida del Calor";
    string widget_type = "slider";
    float min = 0.5;
    float max = 10.0;
    float step = 0.5;
> = 4.5;

uniform float frecuencia_vertical <
    string name = "Cantidad de Ondas de Calor";
    string widget_type = "slider";
    float min = 5.0;
    float max = 45.0;
    float step = 1.0;
> = 22.0;

uniform float tinte_calido <
    string name = "Tinte Naranja de Brasa / Fuego";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.8;
    float step = 0.05;
> = 0.20;

uniform float origen_altura <
    string name = "Altura donde Empieza el Calor (0=Abajo, 1=Arriba)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.9;
    float step = 0.05;
> = 0.1;

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;

    float heat_factor = smoothstep(origen_altura - 0.1, 1.0, 1.0 - uv.y);

    float t = elapsed_time * velocidad;
    float wave_x = sin(uv.y * frecuencia_vertical - t) * 0.6 +
                   cos(uv.y * (frecuencia_vertical * 1.8) - t * 1.4 + uv.x * 10.0) * 0.4;

    float wave_y = cos(uv.x * frecuencia_vertical - t * 0.8) * 0.3;

    float2 uv_distorted = uv;
    uv_distorted.x = clamp(uv.x + wave_x * intensidad * heat_factor, 0.0, 1.0);
    uv_distorted.y = clamp(uv.y + wave_y * (intensidad * 0.5) * heat_factor, 0.0, 1.0);

    float4 col = image.Sample(textureSampler, uv_distorted);

    if (tinte_calido > 0.001) {
        float3 glow_orange = float3(1.0, 0.45, 0.1);
        col.rgb = lerp(col.rgb, col.rgb * glow_orange * 1.3, tinte_calido * heat_factor);
    }

    return col;
}
