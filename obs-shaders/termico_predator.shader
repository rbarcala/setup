uniform int paleta_termica <
    string name = "Paleta (0: Predator Clásico, 1: Ironbow / Infrarrojo, 2: Blanco Caliente)";
    string widget_type = "slider";
    int min = 0;
    int max = 2;
    int step = 1;
> = 0;

uniform float contraste_termico <
    string name = "Contraste Térmico";
    string widget_type = "slider";
    float min = 0.5;
    float max = 3.0;
    float step = 0.1;
> = 1.3;

uniform float brillo_base <
    string name = "Ajuste de Temperatura Base";
    string widget_type = "slider";
    float min = -0.5;
    float max = 0.5;
    float step = 0.02;
> = 0.0;

uniform float intensidad_scanline <
    string name = "HUD Scanline Sutil";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.5;
    float step = 0.05;
> = 0.15;

float3 ramp_predator(float t)
{
    // Escala Predator: Azul -> Cyan -> Verde -> Amarillo -> Rojo -> Blanco
    float3 c0 = float3(0.0, 0.0, 0.5);  // Azul profundo (frío)
    float3 c1 = float3(0.0, 0.8, 1.0);  // Cyan
    float3 c2 = float3(0.0, 0.9, 0.1);  // Verde
    float3 c3 = float3(1.0, 0.9, 0.0);  // Amarillo
    float3 c4 = float3(1.0, 0.1, 0.0);  // Rojo (cálido)
    float3 c5 = float3(1.0, 1.0, 1.0);  // Blanco (muy caliente)

    if (t < 0.2) return lerp(c0, c1, t / 0.2);
    if (t < 0.4) return lerp(c1, c2, (t - 0.2) / 0.2);
    if (t < 0.6) return lerp(c2, c3, (t - 0.4) / 0.2);
    if (t < 0.8) return lerp(c3, c4, (t - 0.6) / 0.2);
    return lerp(c4, c5, (t - 0.8) / 0.2);
}

float3 ramp_ironbow(float t)
{
    // Escala FLIR / Ironbow clásica (Negro -> Púrpura -> Naranja -> Amarillo -> Blanco)
    float3 c0 = float3(0.05, 0.0, 0.1);
    float3 c1 = float3(0.5, 0.0, 0.6);
    float3 c2 = float3(0.9, 0.2, 0.1);
    float3 c3 = float3(1.0, 0.8, 0.1);
    float3 c4 = float3(1.0, 1.0, 1.0);

    if (t < 0.25) return lerp(c0, c1, t / 0.25);
    if (t < 0.5) return lerp(c1, c2, (t - 0.25) / 0.25);
    if (t < 0.75) return lerp(c2, c3, (t - 0.5) / 0.25);
    return lerp(c3, c4, (t - 0.75) / 0.25);
}

float4 mainImage(VertData v_in) : TARGET
{
    float4 original = image.Sample(textureSampler, v_in.uv);
    if (original.a <= 0.001) return original;

    // Calcular temperatura aparente a partir de luminancia y calidez (canales rojo y verde)
    float luma = dot(original.rgb, float3(0.299, 0.587, 0.114));
    float warmth = (original.r * 0.6 + original.g * 0.4) - original.b * 0.3;
    float temp = (luma * 0.7 + warmth * 0.3);

    // Ajustes de contraste y brillo
    temp = clamp((temp - 0.5) * contraste_termico + 0.5 + brillo_base, 0.0, 1.0);

    float3 final_rgb;
    if (paleta_termica == 0) {
        final_rgb = ramp_predator(temp);
    } else if (paleta_termica == 1) {
        final_rgb = ramp_ironbow(temp);
    } else {
        final_rgb = float3(temp, temp, temp);
    }

    // Líneas sutiles de display de mira térmica
    if (intensidad_scanline > 0.001) {
        float grid = sin(v_in.uv.y * uv_size.y * 0.5) * 0.5 + 0.5;
        final_rgb *= (1.0 - grid * intensidad_scanline);
    }

    return float4(final_rgb, original.a);
}

