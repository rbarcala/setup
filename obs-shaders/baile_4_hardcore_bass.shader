uniform float bpm <
    string name = "Ritmo (BPM)";
    string widget_type = "slider";
    float min = 40.0;
    float max = 240.0;
    float step = 1.0;
> = 128.0;

uniform float velocidad_locura <
    string name = "Multiplicador de Caos";
    string widget_type = "slider";
    float min = 0.5;
    float max = 5.0;
    float step = 0.1;
> = 2.0;

uniform float temblor_pantalla <
    string name = "Terremoto / Screen Shake";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.1;
    float step = 0.005;
> = 0.035;

uniform float zoom_blur_radial <
    string name = "Fuerza del Radial Zoom Blur";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.3;
    float step = 0.01;
> = 0.12;

uniform float saturacion_quemada <
    string name = "Saturación Quemada (Deep Fried)";
    string widget_type = "slider";
    float min = 1.0;
    float max = 4.0;
    float step = 0.2;
> = 2.4;

uniform float resplandor_arcoiris <
    string name = "Resplandor Arcoiris Ultrasónico";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.5;
    float step = 0.1;
uniform float beat_offset <
    string name = "Calibración de Fase (Desfase)";
    string widget_type = "slider";
    float min = -100.0;
    float max = 100.0;
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

    // 1. Terremoto caótico sincronizado al tempo en fase
    float bps = (bpm / 60.0) * velocidad_locura;
    float synced_time = elapsed_time + beat_offset;
    float time_step = floor(synced_time * bps * 2.0);
    float2 shake = float2(
        hash2(float2(time_step, 1.0)) - 0.5,
        hash2(float2(time_step, 2.0)) - 0.5
    ) * temblor_pantalla;

    uv += shake;

    // 2. Radial Zoom Blur desenfrenado
    float2 center = float2(0.5, 0.5);
    float2 dir = uv - center;
    float4 accum = float4(0.0, 0.0, 0.0, 0.0);

    const int SAMPLES = 10;
    for (int i = 0; i < SAMPLES; i++) {
        float scale = 1.0 - zoom_blur_radial * (float(i) / float(SAMPLES - 1));
        float2 sample_uv = center + dir * scale;
        accum += image.Sample(textureSampler, sample_uv);
    }
    float4 base_col = accum / float(SAMPLES);

    // 3. Destello estroboscópico de colores espectrales al ritmo musical en fase
    float cycle = frac(synced_time * bps);
    float3 hyper_color = spectral_rainbow(cycle + length(dir) * 2.0);

    // 4. Modo Deep-fried / sobreexposición de bajo y saturación
    float3 rgb = base_col.rgb;
    float luma = dot(rgb, float3(0.299, 0.587, 0.114));
    rgb = lerp(float3(luma, luma, luma), rgb, saturacion_quemada);

    // Contraste extremo
    rgb = (rgb - 0.5) * 1.4 + 0.5;

    // Inyectar arcoiris en picos de luminancia y borde radial
    rgb += hyper_color * resplandor_arcoiris * (luma * 1.5 + 0.2);

    return float4(clamp(rgb, 0.0, 1.0), base_col.a);
}

