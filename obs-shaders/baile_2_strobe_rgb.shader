uniform float bpm <
    string name = "Ritmo (BPM)";
    string widget_type = "slider";
    float min = 40.0;
    float max = 240.0;
    float step = 1.0;
> = 128.0;

uniform float velocidad_estroboscopica <
    string name = "Multiplicador de Luces / Strobe";
    string widget_type = "slider";
    float min = 0.5;
    float max = 5.0;
    float step = 0.1;
> = 2.0;

uniform float desface_rgb <
    string name = "Separación Cromática (Chromatic Shake)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.04;
    float step = 0.002;
> = 0.015;

uniform float saturacion_neon <
    string name = "Saturación Neón";
    string widget_type = "slider";
    float min = 1.0;
    float max = 2.5;
    float step = 0.1;
> = 1.6;

uniform float mezcla_luces <
    string name = "Intensidad de Luces de Fiesta";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.4;

uniform float beat_offset <
    string name = "Calibración de Fase (Desfase)";
    string widget_type = "slider";
    float min = -100.0;
    float max = 100.0;
    float step = 0.01;
> = 0.0;

float hash1(float n)
{
    return frac(sin(n) * 43758.5453123);
}

float3 get_strobe_color(int idx)
{
    if (idx == 0) return float3(1.0, 0.05, 0.6); // Magenta neón
    if (idx == 1) return float3(0.0, 0.9, 1.0);  // Cian
    if (idx == 2) return float3(1.0, 0.85, 0.0); // Amarillo eléctrico
    if (idx == 3) return float3(0.5, 0.0, 1.0);  // Violeta
    return float3(0.05, 1.0, 0.4);               // Verde flúor
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;

    // Frecuencia derivada del BPM musical calibrado en fase
    float strobe_freq = (bpm / 60.0) * velocidad_estroboscopica;
    float synced_time = elapsed_time + beat_offset;
    float step_time = floor(synced_time * strobe_freq);

    // Movimiento rápido de cámara / temblor de beat
    float shake_x = (hash1(step_time * 1.3) - 0.5) * desface_rgb * 0.5;
    float shake_y = (hash1(step_time * 2.7) - 0.5) * desface_rgb * 0.5;

    // Desfase RGB cromático dinámico
    float r = image.Sample(textureSampler, uv + float2(desface_rgb + shake_x, shake_y)).r;
    float g = image.Sample(textureSampler, uv + float2(shake_x, shake_y)).g;
    float b = image.Sample(textureSampler, uv - float2(desface_rgb - shake_x, shake_y)).b;
    float a = image.Sample(textureSampler, uv).a;

    float3 col = float3(r, g, b);

    // Aumento de saturación para aspecto neón
    float luma = dot(col, float3(0.299, 0.587, 0.114));
    col = lerp(float3(luma, luma, luma), col, saturacion_neon);

    // Color estroboscópico de fiesta
    int col_idx = int(fmod(step_time, 5.0));
    float3 active_strobe = get_strobe_color(col_idx);

    // Ráfaga estroboscópica con caída sincronizada
    float strobe_cycle = frac(synced_time * strobe_freq);
    float flash_strength = pow(1.0 - strobe_cycle, 2.0);

    // Teñir y proyectar luz de boliche
    float3 final_rgb = lerp(col, col * active_strobe * 1.8 + active_strobe * (flash_strength * 0.3), mezcla_luces);

    return float4(clamp(final_rgb, 0.0, 1.0), a);
}
