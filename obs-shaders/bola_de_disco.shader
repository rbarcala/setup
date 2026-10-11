uniform float speed <
    string name = "Velocidad de Giro Base (Sin Música)";
    string widget_type = "slider";
    float min = -2.5;
    float max = 2.5;
    float step = 0.05;
> = 0.8;

uniform float scale <
    string name = "Densidad de Espejos (Menor = Más Grandes)";
    string widget_type = "slider";
    float min = 8.0;
    float max = 45.0;
    float step = 1.0;
> = 22.0;

uniform bool usar_beat <
    string name = "Activar Sincronización con el Beat Musical";
> = true;

uniform float amplificacion_beat <
    string name = "Amplificación de Destello y Giro con el Beat";
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

uniform float4 tint <
    string name = "Color del Reflejo de Luz";
    string widget_type = "color";
> = {0.9, 0.92, 1.0, 1.0};

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

    // Convertir coordenadas centradas -1..1 con relación de aspecto 1080p
    float2 p = (uv - 0.5) * 2.0;
    p.x *= (uv_size.x / uv_size.y);

    // Ritmo y pulso del beat
    float active_bpm = musica_activa ? bpm : bpm_default;
    float bps = active_bpm / 60.0;
    float synced_time = elapsed_time + beat_offset;
    float beat_phase = frac(synced_time * bps);
    float beat_kick = usar_beat ? (exp(-beat_phase * 5.0) * amplificacion_beat) : 0.0;

    // Pequeño latido de tamaño en la esfera con el beat
    p /= (1.0 + beat_kick * 0.04);

    float r = dot(p, p);
    if (r > 1.0) {
        return float4(0.0, 0.0, 0.0, 0.0);
    }

    // Mapeo 3D de esfera
    float z = sqrt(1.0 - r);
    float lon = atan2(p.x, z);
    float lat = asin(p.y);

    // Animación de rotación (acelera con la música si el beat está activo)
    float beat_spin = (usar_beat && musica_activa) ? (bps * 0.35 * amplificacion_beat) : 0.0;
    lon += elapsed_time * (speed + sign(speed + 0.001) * beat_spin);

    // Cuadrícula esférica de espejos calibrada
    float2 sp = float2(lon, lat) * scale;
    float2 grid = frac(sp);
    float2 local_uv = (grid - 0.5) * 2.0;

    // Borde biselado de cada espejito
    float dist = max(abs(local_uv.x), abs(local_uv.y));
    float edge = smoothstep(0.72, 0.98, dist);

    // Identificador único de espejo para destellos aleatorios
    float2 id = floor(sp);
    float random_val = frac(sin(dot(id, float2(12.9898, 78.233))) * 43758.5453);

    // Destello de espejos sincronizado al compás
    float flash_freq = usar_beat ? (bps * 3.14159) : 2.5;
    float flash = pow(sin(synced_time * flash_freq + random_val * 6.28318) * 0.5 + 0.5, 4.0) * (1.0 + beat_kick * 0.8);

    // Reflejo de la fuente de video en los espejos
    float2 mirror_uv = frac(id / scale);
    float4 mirror_tex = image.Sample(textureSampler, mirror_uv);

    float3 mirror_col = mirror_tex.rgb + tint.rgb * (random_val * 0.25 + flash * 0.65);

    // Oscurecer ranuras entre espejos
    mirror_col *= (1.0 - edge * 0.82);

    // Sombreado esférico 3D en bordes
    float sphere_shading = smoothstep(1.0, 0.35, sqrt(r));
    mirror_col *= sphere_shading;

    // Brillo especular global
    float specular = pow(max(0.0, p.x * 0.5 - p.y * 0.5 + z * 0.7), 10.0) * (0.8 + beat_kick * 0.4);
    mirror_col += float3(specular, specular, specular);

    return float4(clamp(mirror_col, 0.0, 1.0), 1.0);
}
