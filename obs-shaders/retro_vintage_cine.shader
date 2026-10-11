uniform float tono_sepia <
    string name = "Tono Sepia / Calidez Vintage";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.85;

uniform float intensidad_grano <
    string name = "Grano de Película (Film Grain)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.02;
> = 0.28;

uniform float parpadeo_proyector <
    string name = "Parpadeo de Proyector (Flicker)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.5;
    float step = 0.02;
> = 0.12;

uniform float lineas_rayones <
    string name = "Rayones de Celuloide (Scratches)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.35;

uniform float motas_polvo <
    string name = "Manchas y Polvo de Película";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.30;

uniform float intensidad_vineta <
    string name = "Viñeta Oscura Clásica";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.65;

uniform float contraste_vintage <
    string name = "Contraste Antiguo";
    string widget_type = "slider";
    float min = 0.5;
    float max = 2.0;
    float step = 0.05;
> = 1.15;

// Generador pseudoaleatorio de ruido
float hash11(float p)
{
    p = frac(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return frac(p);
}

float hash21(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;
    float4 col = image.Sample(textureSampler, uv);

    // 1. Desaturación base a luminancia blanco y negro
    float luma = dot(col.rgb, float3(0.299, 0.587, 0.114));

    // Ajuste de contraste para emular emulsión fotográfica antigua
    luma = clamp((luma - 0.5) * contraste_vintage + 0.5, 0.0, 1.0);

    // 2. Tinte Sepia / Gris amarronado de película antigua
    // Matriz de sepia tradicional cálido con base marrón y sombras profundas
    float3 sepia_pure = float3(
        luma * 1.08 + 0.05,
        luma * 0.88 + 0.02,
        luma * 0.68
    );
    // Un gris-marrón desaturado más neutro
    float3 gris_marron = float3(
        luma * 1.02 + 0.02,
        luma * 0.94 + 0.01,
        luma * 0.82
    );

    // Mezclar sepia cálido con gris-marrón
    float3 vintage_color = lerp(gris_marron, sepia_pure, tono_sepia);

    // 3. Parpadeo estocástico del obturador mecánico (18-24 FPS)
    float frame_time = floor(elapsed_time * 18.0);
    float flicker = (hash11(frame_time) - 0.5) * parpadeo_proyector;
    vintage_color += flicker * vintage_color;

    // 4. Rayones verticales de celuloide que aparecen y desaparecen
    if (lineas_rayones > 0.01) {
        float scratch_seed = floor(elapsed_time * 12.0);
        for (int i = 0; i < 3; i++) {
            float scratch_x = hash11(scratch_seed + float(i) * 17.13);
            float scratch_width = 0.0012 + hash11(scratch_seed + float(i) * 5.3) * 0.0015;
            float dist = abs(uv.x - scratch_x);
            if (dist < scratch_width) {
                float intensity = (1.0 - dist / scratch_width) * lineas_rayones;
                // Rayones claros u oscuros aleatorios
                float scratch_tone = hash11(scratch_seed + float(i) * 23.7);
                if (scratch_tone > 0.4) {
                    vintage_color += intensity * 0.25;
                } else {
                    vintage_color -= intensity * 0.35;
                }
            }
        }
    }

    // 5. Motas de polvo y suciedad de película
    if (motas_polvo > 0.01) {
        float dust_seed = floor(elapsed_time * 14.0);
        float2 dust_pos = float2(hash11(dust_seed * 3.1), hash11(dust_seed * 7.7));
        float dust_dist = distance(uv, dust_pos);
        if (dust_dist < 0.006) {
            float dust_alpha = (1.0 - dust_dist / 0.006) * motas_polvo * 0.6;
            vintage_color -= dust_alpha;
        }
    }

    // 6. Grano fino de emulsión de película de plata
    if (intensidad_grano > 0.01) {
        float grain_seed = elapsed_time * 60.0;
        float grain = hash21(uv * 900.0 + float2(grain_seed, grain_seed * 1.37)) - 0.5;
        vintage_color += grain * intensidad_grano;
    }

    // 7. Viñeta oscura periférica (lentes antiguas)
    if (intensidad_vineta > 0.01) {
        float2 dist_center = uv - 0.5;
        float v = dot(dist_center, dist_center);
        float vignette = 1.0 - smoothstep(0.12, 0.65, v) * intensidad_vineta;
        vintage_color *= vignette;
    }

    return float4(clamp(vintage_color, 0.0, 1.0), col.a);
}

