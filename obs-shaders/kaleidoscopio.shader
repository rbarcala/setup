uniform float segments <
    string name = "Cantidad de Espejos / Segmentos";
    string widget_type = "slider";
    float min = 2.0;
    float max = 16.0;
    float step = 1.0;
> = 6.0;

uniform float rotation_speed <
    string name = "Velocidad de Giro Base (Sin Música)";
    string widget_type = "slider";
    float min = -3.0;
    float max = 3.0;
    float step = 0.05;
> = 0.6;

uniform bool usar_beat <
    string name = "Activar Sincronización con el Beat Musical";
> = true;

uniform float amplificacion_beat <
    string name = "Amplificación del Efecto con el Beat";
    string widget_type = "slider";
    float min = 0.0;
    float max = 3.0;
    float step = 0.05;
> = 1.2;

uniform float bpm_default <
    string name = "BPM por Defecto (Cuando no hay música)";
    string widget_type = "slider";
    float min = 60.0;
    float max = 180.0;
    float step = 1.0;
> = 120.0;

uniform float bpm <
    string name = "BPM en Vivo (Sincronizado con Spotify)";
    string widget_type = "slider";
    float min = 60.0;
    float max = 200.0;
    float step = 1.0;
> = 120.0;

uniform bool musica_activa <
    string name = "Música en Reproducción (Automático)";
> = false;

uniform float zoom <
    string name = "Nivel de Zoom";
    string widget_type = "slider";
    float min = 0.3;
    float max = 2.5;
    float step = 0.05;
> = 0.85;

uniform float center_x <
    string name = "Posición Centro Horizontal (X)";
    string widget_type = "slider";
    float min = 0.2;
    float max = 0.8;
    float step = 0.01;
> = 0.5;

uniform float center_y <
    string name = "Posición Centro Vertical (Y)";
    string widget_type = "slider";
    float min = 0.2;
    float max = 0.8;
    float step = 0.01;
> = 0.5;

uniform float rgb_split <
    string name = "Desfase de Color RGB (Aberración)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.03;
    float step = 0.001;
> = 0.006;

uniform float beat_offset <
    string name = "Ajuste Fino de Compás (Desfase s)";
    string widget_type = "slider";
    float min = -2.0;
    float max = 2.0;
    float step = 0.01;
> = 0.0;

float custom_mod(float x, float y) {
    return x - y * floor(x / y);
}

float2 custom_mod2(float2 x, float y) {
    return x - y * floor(x / y);
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;
    float2 center = float2(center_x, center_y);
    float2 p = uv - center;

    // Corregir la relación de aspecto 1080p (16:9)
    float aspect = uv_size.x / uv_size.y;
    p.x *= aspect;

    // Cálculo de ritmo y pulso si el beat está activo
    float active_bpm = musica_activa ? bpm : bpm_default;
    float bps = active_bpm / 60.0;
    float synced_time = elapsed_time + beat_offset;
    float beat_phase = frac(synced_time * bps);
    float beat_pulse = usar_beat ? (exp(-beat_phase * 5.0) * amplificacion_beat) : 0.0;

    // El zoom y el giro se amplifican en cada golpe del beat; si no hay música usa la velocidad estándar
    float dynamic_zoom = zoom * (1.0 - beat_pulse * 0.12);
    float radius = length(p) * max(0.1, dynamic_zoom);
    float angle = atan2(p.y, p.x);

    // Rotación: velocidad base + aceleración rítmica cuando suena música y el beat está activo
    float beat_speed_boost = (usar_beat && musica_activa) ? (bps * 0.6 * amplificacion_beat) : 0.0;
    float beat_angle_kick = usar_beat ? (sin(beat_phase * 6.2831853) * 0.15 * amplificacion_beat) : 0.0;
    angle += elapsed_time * (rotation_speed + sign(rotation_speed + 0.001) * beat_speed_boost) + beat_angle_kick;

    // Lógica del caleidoscopio
    float pi = 3.14159265359;
    float segmentAngle = pi * 2.0 / max(2.0, segments);

    angle = custom_mod(angle, segmentAngle);
    angle = abs(angle - segmentAngle * 0.5);

    // Separación RGB que también vibra ligeramente con el beat
    float current_rgb = rgb_split + beat_pulse * 0.005;
    float2 uv_r = float2(cos(angle), sin(angle)) * radius * (1.0 - current_rgb);
    float2 uv_g = float2(cos(angle), sin(angle)) * radius;
    float2 uv_b = float2(cos(angle), sin(angle)) * radius * (1.0 + current_rgb);

    // Devolver al espacio de textura normal
    uv_r.x /= aspect; uv_r += float2(0.5, 0.5);
    uv_g.x /= aspect; uv_g += float2(0.5, 0.5);
    uv_b.x /= aspect; uv_b += float2(0.5, 0.5);

    // Espejar coordenadas en los bordes para evitar cortes negros
    uv_r = 1.0 - abs(custom_mod2(uv_r, 2.0) - 1.0);
    uv_g = 1.0 - abs(custom_mod2(uv_g, 2.0) - 1.0);
    uv_b = 1.0 - abs(custom_mod2(uv_b, 2.0) - 1.0);

    float r = image.Sample(textureSampler, uv_r).r;
    float g = image.Sample(textureSampler, uv_g).g;
    float b = image.Sample(textureSampler, uv_b).b;

    return float4(r, g, b, 1.0);
}
