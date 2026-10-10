uniform float bpm <
    string name = "Ritmo (BPM)";
    string widget_type = "slider";
    float min = 40.0;
    float max = 240.0;
    float step = 1.0;
> = 128.0;

uniform float velocidad_arcoiris <
    string name = "Multiplicador de Velocidad";
    string widget_type = "slider";
    float min = 0.1;
    float max = 5.0;
    float step = 0.1;
> = 1.0;

uniform int modo_onda <
    string name = "Modo de Arcoiris (0: Espiral / Giro, 1: Radial Centro, 2: Diagonal Barrido)";
    string widget_type = "slider";
    int min = 0;
    int max = 2;
    int step = 1;
> = 0;

uniform float frecuencia_espiral <
    string name = "Frecuencia / Anillos";
    string widget_type = "slider";
    float min = 0.5;
    float max = 15.0;
    float step = 0.5;
> = 3.0;

uniform float saturacion <
    string name = "Saturación del Color";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.85;

uniform float intensidad_arcoiris <
    string name = "Intensidad / Opacidad del Tinte";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.65;

uniform int modo_mezcla <
    string name = "Modo de Mezcla (0: Multiplicar/Tinte, 1: Superposición/Overlay, 2: Pantalla/Aditivo)";
    string widget_type = "slider";
    int min = 0;
    int max = 2;
    int step = 1;
uniform float beat_offset <
    string name = "Calibración de Fase (Desfase)";
    string widget_type = "slider";
    float min = -100.0;
    float max = 100.0;
    float step = 0.01;
> = 0.0;

// Función de conversión HUE a RGB continua y vibrante
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
    float4 base_col = image.Sample(textureSampler, uv);
    if (base_col.a <= 0.001) return base_col;

    // Coordenadas relativas al centro compensadas por relación de aspecto
    float aspect = uv_size.x / uv_size.y;
    float2 p = uv - 0.5;
    p.x *= aspect;

    float angle = atan2(p.y, p.x); // -PI a PI
    float dist = length(p);

    float synced_time = elapsed_time + beat_offset;
    float speed_factor = (bpm / 60.0) * velocidad_arcoiris * 0.5;
    float hue_val = 0.0;

    if (modo_onda == 0) {
        // Espiral giratoria psicodélica: ángulo + distancia + tiempo
        hue_val = (angle / 6.2831853) + (dist * frecuencia_espiral * 0.2) + (synced_time * speed_factor);
    } else if (modo_onda == 1) {
        // Ondas concéntricas que se expanden desde el centro
        hue_val = (dist * frecuencia_espiral) - (synced_time * speed_factor * 2.0);
    } else {
        // Barrido diagonal continuo
        hue_val = (uv.x + uv.y * 0.7) * (frecuencia_espiral * 0.3) + (synced_time * speed_factor);
    }

    float3 rainbow = hue_to_rgb(hue_val);

    // Ajuste de saturación hacia blanco
    float3 desat_rainbow = lerp(float3(1.0, 1.0, 1.0), rainbow, saturacion);

    float3 final_rgb;

    if (modo_mezcla == 0) {
        // Multiplicación directa (tinte puro)
        final_rgb = lerp(base_col.rgb, base_col.rgb * desat_rainbow * 1.5, intensidad_arcoiris);
    } else if (modo_mezcla == 1) {
        // Overlay canal por canal sin indexación de arrays
        float3 overlay_res = float3(
            overlay_channel(base_col.r, desat_rainbow.r),
            overlay_channel(base_col.g, desat_rainbow.g),
            overlay_channel(base_col.b, desat_rainbow.b)
        );
        final_rgb = lerp(base_col.rgb, overlay_res, intensidad_arcoiris);
    } else {
        // Aditivo / Pantalla
        float3 screen_res = 1.0 - (1.0 - base_col.rgb) * (1.0 - desat_rainbow * 0.8);
        final_rgb = lerp(base_col.rgb, screen_res, intensidad_arcoiris);
    }

    return float4(clamp(final_rgb, 0.0, 1.0), base_col.a);
}
