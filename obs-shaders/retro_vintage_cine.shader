uniform float tono_sepia <
    string name = "Tono Marrón / Sepia de Película";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.80;

uniform float contraste_vintage <
    string name = "Contraste de Imagen Antigua";
    string widget_type = "slider";
    float min = 0.7;
    float max = 1.7;
    float step = 0.05;
> = 1.15;

uniform float intensidad_grano <
    string name = "Grano Analógico de Película";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.55;
    float step = 0.02;
> = 0.22;

uniform float parpadeo_proyector <
    string name = "Parpadeo de Luz del Proyector";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.35;
    float step = 0.02;
> = 0.10;

uniform float lineas_rayones <
    string name = "Rayones Verticales de Celuloide";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.8;
    float step = 0.05;
> = 0.30;

uniform float motas_polvo <
    string name = "Manchas y Polvo en el Lente";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.8;
    float step = 0.05;
> = 0.25;

uniform float intensidad_vineta <
    string name = "Oscurecimiento de Bordes (Viñeta)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.9;
    float step = 0.05;
> = 0.60;

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

    float luma = dot(col.rgb, float3(0.299, 0.587, 0.114));
    luma = clamp((luma - 0.5) * contraste_vintage + 0.5, 0.0, 1.0);

    float3 sepia_pure = float3(
        luma * 1.08 + 0.05,
        luma * 0.88 + 0.02,
        luma * 0.68
    );
    float3 gris_marron = float3(
        luma * 1.02 + 0.02,
        luma * 0.94 + 0.01,
        luma * 0.82
    );

    float3 vintage_color = lerp(gris_marron, sepia_pure, tono_sepia);

    float frame_time = floor(elapsed_time * 18.0);
    float flicker = (hash11(frame_time) - 0.5) * parpadeo_proyector;
    vintage_color += flicker * vintage_color;

    if (lineas_rayones > 0.01) {
        float scratch_seed = floor(elapsed_time * 12.0);
        for (int i = 0; i < 3; i++) {
            float scratch_x = hash11(scratch_seed + float(i) * 17.13);
            float scratch_width = 0.0012 + hash11(scratch_seed + float(i) * 5.3) * 0.0015;
            float dist = abs(uv.x - scratch_x);
            if (dist < scratch_width) {
                float intensity = (1.0 - dist / scratch_width) * lineas_rayones;
                float scratch_tone = hash11(scratch_seed + float(i) * 23.7);
                if (scratch_tone > 0.4) {
                    vintage_color += intensity * 0.25;
                } else {
                    vintage_color -= intensity * 0.35;
                }
            }
        }
    }

    if (motas_polvo > 0.01) {
        float dust_seed = floor(elapsed_time * 14.0);
        float2 dust_pos = float2(hash11(dust_seed * 3.1), hash11(dust_seed * 7.7));
        float dust_dist = distance(uv, dust_pos);
        if (dust_dist < 0.006) {
            float dust_alpha = (1.0 - dust_dist / 0.006) * motas_polvo * 0.6;
            vintage_color -= dust_alpha;
        }
    }

    if (intensidad_grano > 0.01) {
        float grain_seed = elapsed_time * 60.0;
        float grain = hash21(uv * 900.0 + float2(grain_seed, grain_seed * 1.37)) - 0.5;
        vintage_color += grain * intensidad_grano;
    }

    if (intensidad_vineta > 0.01) {
        float2 dist_center = uv - 0.5;
        float v = dot(dist_center, dist_center);
        float vignette = 1.0 - smoothstep(0.12, 0.65, v) * intensidad_vineta;
        vintage_color *= vignette;
    }

    return float4(clamp(vintage_color, 0.0, 1.0), col.a);
}
