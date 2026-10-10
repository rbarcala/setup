uniform float luz_x <
    string name = "Origen de Luz X (%)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 100.0;
    float step = 1.0;
> = 50.0;

uniform float luz_y <
    string name = "Origen de Luz Y (%)";
    string widget_type = "slider";
    float min = -50.0;
    float max = 100.0;
    float step = 1.0;
> = -10.0;

uniform float densidad <
    string name = "Longitud de los Rayos";
    string widget_type = "slider";
    float min = 0.1;
    float max = 1.0;
    float step = 0.05;
> = 0.65;

uniform float peso <
    string name = "Grosor / Peso del Rayo";
    string widget_type = "slider";
    float min = 0.01;
    float max = 0.2;
    float step = 0.01;
> = 0.08;

uniform float decaimiento <
    string name = "Decaimiento (Atenuación)";
    string widget_type = "slider";
    float min = 0.8;
    float max = 0.99;
    float step = 0.01;
> = 0.95;

uniform float exposicion <
    string name = "Intensidad / Exposición";
    string widget_type = "slider";
    float min = 0.0;
    float max = 3.0;
    float step = 0.05;
> = 1.1;

uniform float4 color_rayos <
    string name = "Color de los Rayos";
    string widget_type = "color";
> = {1.0, 0.95, 0.75, 1.0};

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;
    float4 base_col = image.Sample(textureSampler, uv);

    float2 light_pos = float2(luz_x * 0.01, luz_y * 0.01);
    float2 delta_uv = (uv - light_pos);

    // Cantidad fija de pasos radiales para el scattering volumétrico
    const int NUM_SAMPLES = 24;
    delta_uv *= (1.0 / float(NUM_SAMPLES)) * densidad;

    float3 rays = float3(0.0, 0.0, 0.0);
    float illumination_decay = 1.0;
    float2 current_uv = uv;

    for (int i = 0; i < NUM_SAMPLES; i++) {
        current_uv -= delta_uv;
        float4 s = image.Sample(textureSampler, clamp(current_uv, 0.0, 1.0));

        // Solo las partes más brillantes emiten rayos de luz divina (umbral de luminancia)
        float luma = dot(s.rgb, float3(0.299, 0.587, 0.114));
        float bright_pass = smoothstep(0.4, 0.9, luma);

        float3 sample_contrib = s.rgb * bright_pass * peso * illumination_decay;
        rays += sample_contrib;
        illumination_decay *= decaimiento;
    }

    rays *= exposicion * color_rayos.rgb;

    // Fusión aditiva sobre el color original
    float3 final_rgb = base_col.rgb + rays;

    return float4(clamp(final_rgb, 0.0, 1.0), base_col.a);
}

