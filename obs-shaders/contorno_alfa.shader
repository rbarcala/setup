uniform float outline_size <
    string name = "Grosor del Borde (píxeles en 1080p)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 35.0;
    float step = 0.5;
> = 5.0;

uniform float4 outline_color <
    string name = "Color del Borde / Contorno";
    string widget_type = "color";
> = {1.0, 1.0, 1.0, 1.0};

uniform int samples <
    string name = "Suavidad del Borde (Calidad de Muestras)";
    string widget_type = "slider";
    int min = 16;
    int max = 96;
    int step = 8;
> = 48;

float4 mainImage(VertData v_in) : TARGET
{
    float4 col = image.Sample(textureSampler, v_in.uv);

    if (outline_size <= 0.0 || col.a >= 0.99) {
        return col;
    }

    float max_alpha = col.a;
    float golden_angle = 2.39996323;

    int safe_samples = clamp(samples, 8, 96);
    for (int i = 1; i <= 96; ++i) {
        if (i > safe_samples) {
            break;
        }

        float fi = float(i);
        float fsamples = float(safe_samples);

        float r = sqrt(fi / fsamples) * outline_size;
        float theta = fi * golden_angle;

        float2 offset = float2(cos(theta), sin(theta)) * r * uv_pixel_interval;
        float sample_alpha = image.Sample(textureSampler, v_in.uv + offset).a;

        if (sample_alpha > max_alpha) {
            max_alpha = sample_alpha;
        }
    }

    if (max_alpha > col.a) {
        float4 out_col = float4(outline_color.rgb, outline_color.a * max_alpha);

        float out_a = col.a + out_col.a * (1.0 - col.a);
        if (out_a > 0.0) {
            float3 out_rgb = (col.rgb * col.a + out_col.rgb * out_col.a * (1.0 - col.a)) / out_a;
            return float4(out_rgb, out_a);
        }
    }

    return col;
}
