uniform bool usar_beat <
    string name = "Activar Sincronización con el Beat Musical";
> = true;

uniform float amplificacion_beat <
    string name = "Amplificación del Efecto con el Beat";
    string widget_type = "slider";
    float min = 0.0;
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

uniform float velocidad_arcoiris <
    string name = "Velocidad de Giro del Arcoiris";
    string widget_type = "slider";
    float min = 0.2;
    float max = 3.5;
    float step = 0.1;
> = 1.0;

uniform int modo_onda <
    string name = "Patrón (0: Espiral Giratoria, 1: Anillos Radiales, 2: Barrido Diagonal)";
    string widget_type = "slider";
    int min = 0;
    int max = 2;
    int step = 1;
> = 0;

uniform float frecuencia_espiral <
    string name = "Cantidad de Anillos / Bandas de Color";
    string widget_type = "slider";
    float min = 0.5;
    float max = 8.0;
    float step = 0.25;
> = 2.5;

uniform float saturacion <
    string name = "Saturación de los Colores";
    string widget_type = "slider";
    float min = 0.2;
    float max = 1.0;
    float step = 0.05;
> = 0.85;

uniform float intensidad_arcoiris <
    string name = "Opacidad del Efecto Arcoiris";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.65;

uniform int modo_mezcla <
    string name = "Fusión de Color (0: Tinte Directo, 1: Superposición Suave, 2: Brillo Aditivo)";
    string widget_type = "slider";
    int min = 0;
    int max = 2;
    int step = 1;
> = 1;

uniform float beat_offset <
    string name = "Ajuste Fino de Compás (Desfase s)";
    string widget_type = "slider";
    float min = -2.0;
    float max = 2.0;
    float step = 0.01;
> = 0.0;

float3 hue_to_rgb(float hue)
{
    float h = frac(hue);
    float r = abs(h * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(h * 6.0 - 2.0);
    float b = 2.0 - abs(h * 6.0 - 4.0);
    return clamp(float3(r, g, b), 0.0, 1.0);
}

float overlay_channel(float base, float blend)
{
    return (base < 0.5) ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend));
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;

    // Seleccionar BPM en vivo si hay música, sino BPM por defecto
    float active_bpm = musica_activa ? bpm : bpm_default;
    float bps = active_bpm / 60.0;
    float synced_time = elapsed_time + beat_offset;
    float beat_phase = frac(synced_time * bps);
    float beat_kick = usar_beat ? (exp(-beat_phase * 5.5) * amplificacion_beat) : 0.0;

    // Ligero pulso de zoom con el beat si la amplificación está activa
    float zoom_pulse = 1.0 + beat_kick * 0.05;
    float2 centered_uv = 0.5 + (uv - 0.5) / max(0.2, zoom_pulse);

    float4 base_col = image.Sample(textureSampler, centered_uv);
    if (base_col.a <= 0.001) return base_col;

    float aspect = uv_size.x / uv_size.y;
    float2 p = centered_uv - 0.5;
    p.x *= aspect;

    float angle = atan2(p.y, p.x);
    float dist = length(p);

    float speed_factor = (usar_beat ? bps * 0.45 : 0.8) * velocidad_arcoiris;
    float hue_val = 0.0;

    if (modo_onda == 0) {
        hue_val = (angle / 6.2831853) + (dist * frecuencia_espiral * 0.25) + (synced_time * speed_factor) + beat_kick * 0.12;
    } else if (modo_onda == 1) {
        hue_val = (dist * frecuencia_espiral) - (synced_time * speed_factor * 1.8) - beat_kick * 0.15;
    } else {
        hue_val = (centered_uv.x + centered_uv.y * 0.7) * (frecuencia_espiral * 0.35) + (synced_time * speed_factor) + beat_kick * 0.1;
    }

    float3 rainbow = hue_to_rgb(hue_val);
    float3 desat_rainbow = lerp(float3(1.0, 1.0, 1.0), rainbow, saturacion);

    float dynamic_intensity = clamp(intensidad_arcoiris + beat_kick * 0.12, 0.0, 1.0);
    float3 final_rgb;

    if (modo_mezcla == 0) {
        final_rgb = lerp(base_col.rgb, base_col.rgb * desat_rainbow * 1.4, dynamic_intensity);
    } else if (modo_mezcla == 1) {
        float3 overlay_res = float3(
            overlay_channel(base_col.r, desat_rainbow.r),
            overlay_channel(base_col.g, desat_rainbow.g),
            overlay_channel(base_col.b, desat_rainbow.b)
        );
        final_rgb = lerp(base_col.rgb, overlay_res, dynamic_intensity);
    } else {
        float3 screen_res = 1.0 - (1.0 - base_col.rgb) * (1.0 - desat_rainbow * 0.8);
        final_rgb = lerp(base_col.rgb, screen_res, dynamic_intensity);
    }

    return float4(clamp(final_rgb, 0.0, 1.0), base_col.a);
}
