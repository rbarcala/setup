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

uniform float velocidad_giro <
    string name = "Velocidad de Giro Base";
    string widget_type = "slider";
    float min = -2.0;
    float max = 2.0;
    float step = 0.05;
> = 0.6;

uniform float ondulacion_imagen <
    string name = "Ondulación Líquida de la Imagen";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.08;
    float step = 0.002;
> = 0.025;

uniform float frecuencia_ondas <
    string name = "Cantidad de Ondas en la Imagen";
    string widget_type = "slider";
    float min = 3.0;
    float max = 25.0;
    float step = 1.0;
> = 10.0;

uniform float golpe_zoom_beat <
    string name = "Golpe de Zoom en el Beat";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.35;
    float step = 0.01;
> = 0.14;

uniform float efecto_tunel <
    string name = "Torsión de Espiral / Vórtice";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.5;
    float step = 0.05;
> = 0.45;

uniform float destellos_estela <
    string name = "Estelas Fantasma de Movimiento";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.8;
    float step = 0.05;
> = 0.35;

uniform float velocidad_color <
    string name = "Velocidad de Colores Rave";
    string widget_type = "slider";
    float min = 0.2;
    float max = 4.0;
    float step = 0.1;
> = 1.2;

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

float2 mirror_uv(float2 uv) {
    return 1.0 - abs( (uv - 2.0 * floor(uv / 2.0)) - 1.0 );
}

float3 rainbow_cycle(float h)
{
    float val = frac(h);
    float3 c = clamp(abs(fmod(val * 6.0 + float3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    return c;
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;
    float aspect = uv_size.x / uv_size.y;
    float2 p = uv - 0.5;
    p.x *= aspect;

    // 1. Cálculo de BPM (música en vivo vs por defecto) y pulso del beat
    float active_bpm = musica_activa ? bpm : bpm_default;
    float bps = active_bpm / 60.0;
    float synced_time = elapsed_time + beat_offset;
    float beat_phase = frac(synced_time * bps);

    // Pulso fuerte en el golpe de bombo (kick)
    float beat_kick = usar_beat ? (exp(-beat_phase * 5.5) * amplificacion_beat) : 0.0;
    // Oscilación rítmica continua con el beat
    float beat_wave = usar_beat ? (sin(beat_phase * 6.2831853) * amplificacion_beat) : 0.0;

    float r = length(p);
    float a = atan2(p.y, p.x);

    // 2. Golpe de Zoom rítmico con el beat
    float zoom_factor = 1.0 + beat_kick * golpe_zoom_beat;
    float zoomed_r = r / max(0.2, zoom_factor);

    // 3. Giro acelerado en los golpes de beat + torsión de vórtice pulsante
    float dynamic_spin = (synced_time * velocidad_giro * 1.5) + (usar_beat ? sin(synced_time * bps * 3.14159) * 0.25 * amplificacion_beat : 0.0);
    float dynamic_vortex = efecto_tunel * (1.0 + beat_kick * 0.5);
    float tunnel_angle = a + (zoomed_r * dynamic_vortex * 2.5) + dynamic_spin;

    float2 tunnel_p = float2(cos(tunnel_angle), sin(tunnel_angle)) * zoomed_r;
    tunnel_p.x /= aspect;

    // 4. Ondulación líquida psicodélica sobre la imagen (amplificada con el beat)
    float wave_amp = ondulacion_imagen * (1.0 + beat_kick * 0.8);
    float wave_t = synced_time * (usar_beat ? bps * 2.5 : 3.0);
    float2 ripple = float2(
        sin(tunnel_p.y * frecuencia_ondas + wave_t) + cos(zoomed_r * frecuencia_ondas * 1.5 - wave_t),
        cos(tunnel_p.x * frecuencia_ondas - wave_t) + sin(zoomed_r * frecuencia_ondas * 1.5 + wave_t)
    ) * 0.5 * wave_amp;

    float2 warped_uv = mirror_uv(0.5 + tunnel_p + ripple);

    // 5. Muestreo principal + Ecos fantasma que se abren con el beat
    float4 col_main = image.Sample(textureSampler, warped_uv);

    float echo_spread = 0.06 + beat_kick * 0.05;
    float2 uv_echo1 = mirror_uv(0.5 + tunnel_p * (1.0 + echo_spread) + ripple);
    float2 uv_echo2 = mirror_uv(0.5 + tunnel_p * (1.0 - echo_spread) - ripple);

    float4 col_echo1 = image.Sample(textureSampler, uv_echo1);
    float4 col_echo2 = image.Sample(textureSampler, uv_echo2);

    float4 mixed_col = lerp(col_main, (col_main + col_echo1 + col_echo2) / 3.0, destellos_estela);

    // 6. Ondas de color arcoiris en espiral sincronizadas al compás
    float rainbow_phase = (a / 6.2831853) + (zoomed_r * 2.5) - (synced_time * velocidad_color * 0.5) - (beat_kick * 0.2);
    float3 rave_color = rainbow_cycle(rainbow_phase);

    // Fusión psicodélica con brillo extra en el golpe del beat
    float3 final_rgb = mixed_col.rgb * (rave_color * 1.25 + 0.25) + rave_color * (beat_kick * 0.15);

    return float4(clamp(final_rgb, 0.0, 1.0), col_main.a);
}
