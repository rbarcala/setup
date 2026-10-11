uniform float water_level <
    string name = "Altura de la Superficie del Agua (0=Arriba, 1=Abajo)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.01;
> = 0.35;

uniform float wave_speed <
    string name = "Velocidad de las Olas";
    string widget_type = "slider";
    float min = 0.2;
    float max = 6.0;
    float step = 0.1;
> = 2.0;

uniform float wave_intensity <
    string name = "Distorsión Bajo el Agua (Refracción)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.04;
    float step = 0.001;
> = 0.012;

uniform float4 water_color <
    string name = "Color del Agua";
    string widget_type = "color";
> = {0.1, 0.5, 0.85, 1.0};

uniform float tint_strength <
    string name = "Opacidad del Tinte de Agua";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.9;
    float step = 0.05;
> = 0.60;

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;

    float surface_wave = sin(uv.x * 12.0 + elapsed_time * wave_speed) * 0.012 +
                         cos(uv.x * 25.0 + elapsed_time * wave_speed * 1.3) * 0.006;

    float current_water_level = water_level + surface_wave;

    if (uv.y > current_water_level) {
        float depth = uv.y - current_water_level;

        float2 water_uv = uv;
        water_uv.x += sin(uv.y * 20.0 + elapsed_time * wave_speed) * wave_intensity;
        water_uv.y += cos(uv.x * 15.0 + elapsed_time * wave_speed * 0.8) * wave_intensity;

        water_uv.y = clamp(max(water_uv.y, current_water_level + 0.001), 0.0, 1.0);
        water_uv.x = clamp(water_uv.x, 0.0, 1.0);

        float4 base_color = image.Sample(textureSampler, water_uv);

        float caustic = sin(water_uv.x * 40.0 + elapsed_time * 2.0) *
                        cos(water_uv.y * 40.0 - elapsed_time * 2.5);
        caustic = smoothstep(0.7, 1.0, caustic) * 0.35;

        float3 tinted = base_color.rgb * water_color.rgb * 1.45;
        float3 final_rgb = lerp(base_color.rgb, tinted, tint_strength);

        final_rgb += caustic * max(0.0, (1.0 - depth * 1.4));

        float surface_dist = abs(uv.y - current_water_level);
        if (surface_dist < 0.005) {
            float line_glow = 1.0 - (surface_dist / 0.005);
            final_rgb += float3(0.55, 0.85, 1.0) * line_glow;
        }

        return float4(clamp(final_rgb, 0.0, 1.0), base_color.a);
    } else {
        return image.Sample(textureSampler, uv);
    }
}
