uniform float4 color_holograma <
    string name = "Color del Holograma";
    string widget_type = "color";
> = {0.15, 0.85, 1.0, 1.0};

uniform float transparencia_base <
    string name = "Transparencia Base";
    string widget_type = "slider";
    float min = 0.1;
    float max = 1.0;
    float step = 0.05;
> = 0.85;

uniform float parpadeo_flicker <
    string name = "Parpadeo / Inestabilidad de Señal";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.35;

uniform float velocidad_escaneo <
    string name = "Velocidad de Barras de Escaneo";
    string widget_type = "slider";
    float min = 0.1;
    float max = 10.0;
    float step = 0.1;
> = 3.0;

uniform float lineas_holograma <
    string name = "Frecuencia de Rayas";
    string widget_type = "slider";
    float min = 50.0;
    float max = 500.0;
    float step = 10.0;
> = 200.0;

uniform float distorsion_transmision <
    string name = "Jitter / Desfase Horizontal";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.05;
    float step = 0.001;
> = 0.004;

float hash(float n)
{
    return frac(sin(n) * 43758.5453123);
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;

    // Desfase horizontal tipo micro-glitch de transmisión holográfica
    float jitter = 0.0;
    if (distorsion_transmision > 0.0001) {
        float slice = floor(uv.y * 60.0);
        float rand_slice = hash(slice + floor(elapsed_time * 15.0));
        if (rand_slice > 0.85) {
            jitter = (hash(slice * 1.7) - 0.5) * distorsion_transmision;
        }
    }
    uv.x += jitter;

    float4 original = image.Sample(textureSampler, uv);
    if (original.a <= 0.001) return original;

    // Barra de luz gruesa que recorre verticalmente el holograma
    float bar = sin(uv.y * 3.14159 * 2.0 - elapsed_time * velocidad_escaneo);
    float glow_bar = smoothstep(0.7, 1.0, bar) * 0.4;

    // Rayas horizontales de proyección holográfica
    float stripes = sin(uv.y * lineas_holograma + elapsed_time * 5.0) * 0.5 + 0.5;

    // Inestabilidad / flicker rápido de transmisión de datos
    float flicker = 1.0;
    if (parpadeo_flicker > 0.001) {
        float f1 = sin(elapsed_time * 45.0) * 0.1;
        float f2 = hash(floor(elapsed_time * 24.0)) * 0.15;
        flicker = 1.0 - (f1 + f2) * parpadeo_flicker;
    }

    // Convertir imagen original a luminancia y teñir con el color holográfico
    float luma = dot(original.rgb, float3(0.299, 0.587, 0.114));
    float3 holo_rgb = color_holograma.rgb * (luma * 1.2 + 0.1);

    // Añadir líneas, barra de barrido y efecto de borde
    holo_rgb += holo_rgb * stripes * 0.35;
    holo_rgb += color_holograma.rgb * glow_bar;
    holo_rgb *= flicker;

    // Control de transparencia
    float final_alpha = original.a * transparencia_base * flicker;

    return float4(clamp(holo_rgb, 0.0, 1.0), clamp(final_alpha, 0.0, 1.0));
}

