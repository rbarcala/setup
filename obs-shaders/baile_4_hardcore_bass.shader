uniform bool usar_beat <
    string name = "Activar Sincronización con el Beat Musical";
> = true;

uniform float amplificacion_beat <
    string name = "Amplificación del Efecto con el Beat";
    string widget_type = "slider";
    float min = 0.2;
    float max = 3.0;
    float step = 0.1;
> = 1.2;

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

uniform float velocidad_locura <
    string name = "Velocidad de Caos y Parpadeo";
    string widget_type = "slider";
    float min = 0.5;
    float max = 3.5;
    float step = 0.1;
> = 1.6;

uniform float temblor_pantalla <
    string name = "Terremoto de Cámara (Screen Shake)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.06;
    float step = 0.002;
> = 0.022;

uniform float zoom_blur_radial <
    string name = "Desenfoque de Zoom Radial (Bass Boost)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.22;
    float step = 0.01;
> = 0.10;

uniform float saturacion_quemada <
    string name = "Saturación Extrema (Efecto Deep Fried)";
    string widget_type = "slider";
    float min = 1.0;
    float max = 3.2;
    float step = 0.1;
> = 2.0;

uniform float resplandor_arcoiris <
    string name = "Intensidad de Resplandor Arcoiris";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.2;
    float step = 0.05;
> = 0.65;

uniform float beat_offset <
    string name = "Ajuste Fino de Compás (Desfase s)";
    string widget_type = "slider";
    float min = -2.0;
    float max = 2.0;
    float step = 0.01;
> = 0.0;

float hash2(float2 p)
{
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123);
}

float3 spectral_rainbow(float t)
{
    return 0.5 + 0.5 * cos(6.28318 * (t + float3(0.0, 0.33, 0.67)));
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;

    // 1. Terremoto caótico sincronizado al tempo (en vivo o por defecto)
    float active_bpm = musica_activa ? bpm : bpm_default;
    float bps = (usar_beat ? (active_bpm / 60.0) : 1.5) * velocidad_locura;
    float synced_time = elapsed_time + beat_offset;
    float beat_phase = frac(synced_time * bps);
    float beat_kick = usar_beat ? (exp(-beat_phase * 4.5) * amplificacion_beat) : 0.4;

    float time_step = floor(synced_time * bps * 2.0);
    float shake_amount = temblor_pantalla * (0.4 + beat_kick * 0.85);
    float2 shake = float2(
        hash2(float2(time_step, 1.0)) - 0.5,
        hash2(float2(time_step, 2.0)) - 0.5
    ) * shake_amount;

    uv = clamp(uv + shake, 0.001, 0.999);

    // 2. Radial Zoom Blur desenfrenado que estalla en cada golpe de bajo
    float2 center = float2(0.5, 0.5);
    float2 dir = uv - center;
    float4 accum = float4(0.0, 0.0, 0.0, 0.0);

    float dynamic_blur = zoom_blur_radial * (0.5 + beat_kick * 0.75);
    const int SAMPLES = 10;
    for (int i = 0; i < SAMPLES; i++) {
        float scale = 1.0 - dynamic_blur * (float(i) / float(SAMPLES - 1));
        float2 sample_uv = clamp(center + dir * scale, 0.0, 1.0);
        accum += image.Sample(textureSampler, sample_uv);
    }
    float4 base_col = accum / float(SAMPLES);

    // 3. Destello estroboscópico de colores espectrales al ritmo musical
    float3 hyper_color = spectral_rainbow(beat_phase + length(dir) * 2.0);

    // 4. Modo Deep-fried / sobreexposición de bajo y saturación
    float3 rgb = base_col.rgb;
    float luma = dot(rgb, float3(0.299, 0.587, 0.114));
    rgb = lerp(float3(luma, luma, luma), rgb, saturacion_quemada);

    // Contraste de impacto en el beat
    rgb = (rgb - 0.5) * (1.25 + beat_kick * 0.2) + 0.5;

    // Inyectar arcoiris en picos de luminancia y borde radial
    rgb += hyper_color * resplandor_arcoiris * (0.6 + beat_kick * 0.5) * (luma * 1.3 + 0.2);

    return float4(clamp(rgb, 0.0, 1.0), base_col.a);
}
