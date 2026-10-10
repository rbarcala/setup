uniform float scanline_density <
    string name = "Densidad Scanlines";
    string widget_type = "slider";
    float min = 50.0;
    float max = 600.0;
    float step = 10.0;
> = 240.0;

uniform float scanline_intensity <
    string name = "Intensidad Scanlines";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.25;

uniform float aberracion_rgb <
    string name = "Aberración Cromática (RGB Split)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.05;
    float step = 0.001;
> = 0.008;

uniform float curvatura_crt <
    string name = "Curvatura Pantalla CRT";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.5;
    float step = 0.01;
> = 0.08;

uniform float vhs_glitch <
    string name = "Glitch / Desgarro de Cinta VHS";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.35;

uniform float ruido_estatica <
    string name = "Ruido Estático / Grano";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.02;
> = 0.15;

float random_noise(float2 p)
{
    return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;

    // 1. Curvatura de tubo CRT
    if (curvatura_crt > 0.001) {
        float2 cc = uv - 0.5;
        float dist = dot(cc, cc);
        uv = 0.5 + cc * (1.0 + dist * curvatura_crt * 2.0);
        // Descartar píxeles fuera de la pantalla curvada
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
            return float4(0.0, 0.0, 0.0, 0.0);
        }
    }

    // 2. Glitch / desgarro horizontal de cinta VHS
    float glitch_offset = 0.0;
    if (vhs_glitch > 0.001) {
        // Línea desfasada que baja lentamente
        float tape_roll = frac(elapsed_time * 0.25);
        float line_dist = abs(uv.y - tape_roll);
        if (line_dist < 0.03) {
            glitch_offset += sin(uv.y * 150.0 + elapsed_time * 20.0) * 0.02 * vhs_glitch;
        }

        // Saltos rápidos aperiódicos
        float fast_glitch = step(0.97, sin(elapsed_time * 5.0 + uv.y * 30.0));
        glitch_offset += fast_glitch * (random_noise(float2(floor(uv.y * 40.0), floor(elapsed_time * 10.0))) - 0.5) * 0.03 * vhs_glitch;
    }

    float2 uv_distorted = uv;
    uv_distorted.x += glitch_offset;

    // 3. Aberración Cromática (RGB split)
    float shift = aberracion_rgb;
    float r = image.Sample(textureSampler, float2(uv_distorted.x - shift, uv_distorted.y)).r;
    float g = image.Sample(textureSampler, uv_distorted).g;
    float b = image.Sample(textureSampler, float2(uv_distorted.x + shift, uv_distorted.y)).b;
    float a = image.Sample(textureSampler, uv_distorted).a;

    float3 col = float3(r, g, b);

    // 4. Scanlines CRT
    float scan = sin((uv.y * scanline_density + elapsed_time * 2.0) * 3.14159265);
    col -= col * (scan * 0.5 + 0.5) * scanline_intensity;

    // 5. Ruido estático analógico
    if (ruido_estatica > 0.001) {
        float n = (random_noise(uv * 1000.0 + frac(elapsed_time * 77.0)) - 0.5) * ruido_estatica;
        col += n;
    }

    return float4(clamp(col, 0.0, 1.0), a);
}

