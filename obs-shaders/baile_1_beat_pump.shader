uniform float bpm <
    string name = "Ritmo (BPM / Pulsos por minuto)";
    string widget_type = "slider";
    float min = 60.0;
    float max = 200.0;
    float step = 1.0;
> = 128.0;

uniform float intensidad_zoom <
    string name = "Intensidad del Golpe de Zoom";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.25;
    float step = 0.01;
> = 0.08;

uniform float intensidad_flash <
    string name = "Flash Blanco en el Beat";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.5;
    float step = 0.02;
> = 0.15;

uniform float vineta_disco <
    string name = "Viñeta Club / Oscurecer Bordes";
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

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;

    // Frecuencia del compás según BPM calibrado en fase con Spotify
    float bps = bpm / 60.0;
    float synced_time = elapsed_time + beat_offset;
    float beat_phase = frac(synced_time * bps);

    // Curva de decaimiento exponencial estilo kick de bombo (golpe fuerte y cae)
    float beat_kick = exp(-beat_phase * 6.0);

    // Zoom pulsante centrado en el medio
    float current_zoom = 1.0 + beat_kick * intensidad_zoom;
    float2 center_offset = uv - 0.5;
    float2 zoomed_uv = 0.5 + center_offset / current_zoom;

    float4 col = image.Sample(textureSampler, zoomed_uv);

    // Flash rítmico en cada golpe de beat
    col.rgb += beat_kick * intensidad_flash;

    // Viñeta oscura periférica
    if (vineta_disco > 0.001) {
        float d = length(center_offset * float2(uv_size.x / uv_size.y, 1.0));
        float vignette = smoothstep(0.4, 0.9, d);
        col.rgb *= (1.0 - vignette * vineta_disco);
    }

    return float4(clamp(col.rgb, 0.0, 1.0), col.a);
}

