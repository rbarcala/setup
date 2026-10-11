uniform float4 color_holograma <
    string name = "Color del Holograma";
    string widget_type = "color";
> = {0.15, 0.85, 1.0, 1.0};

uniform float transparencia_base <
    string name = "Opacidad General del Holograma";
    string widget_type = "slider";
    float min = 0.2;
    float max = 1.0;
    float step = 0.05;
> = 0.85;

uniform float parpadeo_flicker <
    string name = "Parpadeo de Señal Inestable";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.8;
    float step = 0.05;
> = 0.30;

uniform float velocidad_escaneo <
    string name = "Velocidad de la Barra de Escaneo";
    string widget_type = "slider";
    float min = 0.2;
    float max = 6.0;
    float step = 0.1;
> = 2.5;

uniform float lineas_holograma <
    string name = "Cantidad de Líneas Horizontales";
    string widget_type = "slider";
    float min = 60.0;
    float max = 360.0;
    float step = 10.0;
> = 180.0;

uniform float distorsion_transmision <
    string name = "Cortes de Interferencia Horizontal";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.025;
    float step = 0.001;
> = 0.004;

float hash(float n)
{
    return frac(sin(n) * 43758.5453123);
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;

    float jitter = 0.0;
    if (distorsion_transmision > 0.0001) {
        float slice = floor(uv.y * 60.0);
        float rand_slice = hash(slice + floor(elapsed_time * 15.0));
        if (rand_slice > 0.85) {
            jitter = (hash(slice * 1.7) - 0.5) * distorsion_transmision;
        }
    }
    uv.x = clamp(uv.x + jitter, 0.0, 1.0);

    float4 original = image.Sample(textureSampler, uv);
    if (original.a <= 0.001) return original;

    float bar = sin(uv.y * 3.14159 * 2.0 - elapsed_time * velocidad_escaneo);
    float glow_bar = smoothstep(0.7, 1.0, bar) * 0.4;

    float stripes = sin(uv.y * lineas_holograma + elapsed_time * 5.0) * 0.5 + 0.5;

    float flicker = 1.0;
    if (parpadeo_flicker > 0.001) {
        float f1 = sin(elapsed_time * 45.0) * 0.1;
        float f2 = hash(floor(elapsed_time * 24.0)) * 0.15;
        flicker = 1.0 - (f1 + f2) * parpadeo_flicker;
    }

    float luma = dot(original.rgb, float3(0.299, 0.587, 0.114));
    float3 holo_rgb = color_holograma.rgb * (luma * 1.2 + 0.1);

    holo_rgb += holo_rgb * stripes * 0.35;
    holo_rgb += color_holograma.rgb * glow_bar;
    holo_rgb *= flicker;

    float final_alpha = original.a * transparencia_base * flicker;

    return float4(clamp(holo_rgb, 0.0, 1.0), clamp(final_alpha, 0.0, 1.0));
}
