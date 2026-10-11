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

uniform float intensidad_zoom <
    string name = "Golpe de Zoom en el Beat";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.20;
    float step = 0.005;
> = 0.07;

uniform float intensidad_flash <
    string name = "Destello de Luz en el Beat";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.35;
    float step = 0.01;
> = 0.12;

uniform float vineta_disco <
    string name = "Viñeta Oscura en los Bordes";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.85;
    float step = 0.05;
> = 0.35;

uniform float beat_offset <
    string name = "Ajuste Fino de Compás (Desfase s)";
    string widget_type = "slider";
    float min = -2.0;
    float max = 2.0;
    float step = 0.01;
> = 0.0;

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;

    // Seleccionar BPM en vivo si hay música reproduciéndose, sino el BPM por defecto
    float active_bpm = musica_activa ? bpm : bpm_default;
    float bps = active_bpm / 60.0;
    float synced_time = elapsed_time + beat_offset;
    float beat_phase = frac(synced_time * bps);

    // Curva de golpe de bombo (kick) modulada por el interruptor y la amplificación
    float beat_kick = usar_beat ? (exp(-beat_phase * 6.0) * amplificacion_beat) : 0.0;

    // Zoom pulsante centrado en la imagen
    float current_zoom = 1.0 + beat_kick * intensidad_zoom;
    float2 center_offset = uv - 0.5;
    float2 zoomed_uv = 0.5 + center_offset / max(0.2, current_zoom);

    float4 col = image.Sample(textureSampler, zoomed_uv);

    // Destello rítmico en cada golpe
    col.rgb += beat_kick * intensidad_flash;

    // Viñeta oscura periférica que también late suavemente con el beat
    if (vineta_disco > 0.001) {
        float d = length(center_offset * float2(uv_size.x / uv_size.y, 1.0));
        float vignette = smoothstep(0.35, 0.95, d);
        col.rgb *= (1.0 - vignette * clamp(vineta_disco + beat_kick * 0.1, 0.0, 0.95));
    }

    return float4(clamp(col.rgb, 0.0, 1.0), col.a);
}
