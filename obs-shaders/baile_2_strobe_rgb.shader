uniform bool usar_beat <
    string name = "Activar Sincronización con el Beat Musical";
> = true;

uniform float amplificacion_beat <
    string name = "Amplificación del Efecto con el Beat";
    string widget_type = "slider";
    float min = 0.2;
    float max = 3.0;
    float step = 0.1;
> = 1.0;

uniform float bpm_default <
    string name = "BPM por Defecto (Cuando no hay música)";
    string widget_type = "slider";
    float min = 60.0;
    float max = 180.0;
    float step = 1.0;
> = 128.0;

uniform float bpm <
    string name = "BPM en Vivo (Sincronizado con Spotify)";
    string widget_type = "slider";
    float min = 60.0;
    float max = 200.0;
    float step = 1.0;
> = 128.0;

uniform bool musica_activa <
    string name = "Música en Reproducción (Automático)";
> = false;

uniform float velocidad_estroboscopica <
    string name = "Velocidad de Cambio de Luces";
    string widget_type = "slider";
    float min = 0.5;
    float max = 4.0;
    float step = 0.1;
> = 1.5;

uniform float desface_rgb <
    string name = "Separación de Color RGB y Vibración";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.025;
    float step = 0.001;
> = 0.010;

uniform float saturacion_neon <
    string name = "Saturación de Colores Neón";
    string widget_type = "slider";
    float min = 1.0;
    float max = 2.2;
    float step = 0.05;
> = 1.45;

uniform float mezcla_luces <
    string name = "Intensidad de Luces de Boliche";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.9;
    float step = 0.05;
> = 0.4;

uniform float beat_offset <
    string name = "Ajuste Fino de Compás (Desfase s)";
    string widget_type = "slider";
    float min = -2.0;
    float max = 2.0;
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

    // Seleccionar BPM activo según si suena música o usar el valor por defecto
    float active_bpm = musica_activa ? bpm : bpm_default;
    float bps = active_bpm / 60.0;
    float strobe_freq = (usar_beat ? bps : 1.5) * velocidad_estroboscopica;
    float synced_time = elapsed_time + beat_offset;
    float step_time = floor(synced_time * strobe_freq);
    float strobe_cycle = frac(synced_time * strobe_freq);

    float beat_amp = usar_beat ? amplificacion_beat : 0.4;
    float beat_pulse = exp(-strobe_cycle * 5.0) * beat_amp;

    // Movimiento rápido de cámara y separación cromática amplificados por el beat
    float current_rgb = desface_rgb * (0.6 + beat_pulse * 0.8);
    float shake_x = (hash1(step_time * 1.3) - 0.5) * current_rgb * 0.6;
    float shake_y = (hash1(step_time * 2.7) - 0.5) * current_rgb * 0.6;

    // Desfase RGB cromático dinámico
    float r = image.Sample(textureSampler, clamp(uv + float2(current_rgb + shake_x, shake_y), 0.0, 1.0)).r;
    float g = image.Sample(textureSampler, clamp(uv + float2(shake_x, shake_y), 0.0, 1.0)).g;
    float b = image.Sample(textureSampler, clamp(uv - float2(current_rgb - shake_x, shake_y), 0.0, 1.0)).b;
    float a = image.Sample(textureSampler, uv).a;

    float3 col = float3(r, g, b);

    // Aumento de saturación para aspecto neón
    float luma = dot(col, float3(0.299, 0.587, 0.114));
    col = lerp(float3(luma, luma, luma), col, saturacion_neon);

    // Color estroboscópico de fiesta
    int col_idx = int(fmod(abs(step_time), 5.0));
    float3 active_strobe = get_strobe_color(col_idx);

    // Ráfaga estroboscópica con caída sincronizada
    float flash_strength = usar_beat ? (pow(1.0 - strobe_cycle, 2.5) * amplificacion_beat) : 0.35;

    // Teñir y proyectar luz de boliche
    float3 final_rgb = lerp(col, col * active_strobe * 1.6 + active_strobe * (flash_strength * 0.28), mezcla_luces);

    return float4(clamp(final_rgb, 0.0, 1.0), a);
}
