uniform float bpm <
    string name = "Ritmo (BPM)";
    string widget_type = "slider";
    float min = 40.0;
    float max = 240.0;
    float step = 1.0;
> = 128.0;

uniform float velocidad_giro <
    string name = "Multiplicador de Giro";
    string widget_type = "slider";
    float min = 0.2;
    float max = 4.0;
    float step = 0.1;
> = 1.0;

uniform float efecto_tunel <
    string name = "Profundidad del Túnel (Vórtice)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 2.0;
    float step = 0.1;
> = 0.8;

uniform float destellos_estela <
    string name = "Estelas y Duplicación de Ecos";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.6;

uniform float velocidad_color <
    string name = "Velocidad Ciclo de Colores";
    string widget_type = "slider";
    float min = 0.5;
    float max = 8.0;
    float step = 0.5;
uniform float beat_offset <
    string name = "Calibración de Fase (Desfase)";
    string widget_type = "slider";
    float min = -100.0;
    float max = 100.0;
    float step = 0.01;
> = 0.0;

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

    float r = length(p);
    float a = atan2(p.y, p.x);

    // Deformación polar de túnel / vórtice al ritmo de la música en fase
    float synced_time = elapsed_time + beat_offset;
    float spin_speed = (bpm / 60.0) * velocidad_giro * 1.5;
    float tunnel_angle = a + (r * efecto_tunel * 3.0) + (synced_time * spin_speed);
    float2 tunnel_p = float2(cos(tunnel_angle), sin(tunnel_angle)) * r;
    tunnel_p.x /= aspect;
    float2 warped_uv = 0.5 + tunnel_p;

    // Muestreo central
    float4 col_main = image.Sample(textureSampler, warped_uv);

    // Efecto de estelas y ecos de movimiento (Motion Echoes)
    float4 col_echo1 = image.Sample(textureSampler, 0.5 + tunnel_p * 1.12);
    float4 col_echo2 = image.Sample(textureSampler, 0.5 + tunnel_p * 0.88);

    float4 mixed_col = col_main + (col_echo1 + col_echo2) * (destellos_estela * 0.35);

    // Ondas concéntricas de arcoiris en espiral
    float rainbow_phase = (a / 6.28318) + (r * 4.0) + (elapsed_time * velocidad_color * 0.3);
    float3 rave_color = rainbow_cycle(rainbow_phase);

    // Fusión psicodélica
    float3 final_rgb = mixed_col.rgb * (rave_color * 1.4 + 0.2);

    return float4(clamp(final_rgb, 0.0, 1.0), col_main.a);
}

