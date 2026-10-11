uniform float cantidad_lineas <
    string name = "Cantidad de Rayas de Velocidad";
    string widget_type = "slider";
    float min = 30.0;
    float max = 140.0;
    float step = 5.0;
> = 75.0;

uniform float velocidad <
    string name = "Velocidad de las Rayas";
    string widget_type = "slider";
    float min = 2.0;
    float max = 25.0;
    float step = 1.0;
> = 12.0;

uniform float radio_seguro_centro <
    string name = "Espacio Libre en el Centro (%)";
    string widget_type = "slider";
    float min = 10.0;
    float max = 70.0;
    float step = 2.0;
> = 32.0;

uniform float intensidad_lineas <
    string name = "Opacidad de las Rayas";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.75;

uniform float4 color_lineas <
    string name = "Color de las Rayas";
    string widget_type = "color";
> = {1.0, 1.0, 1.0, 1.0};

uniform float centro_x <
    string name = "Posición Horizontal del Centro (%)";
    string widget_type = "slider";
    float min = 15.0;
    float max = 85.0;
    float step = 1.0;
> = 50.0;

uniform float centro_y <
    string name = "Posición Vertical del Centro (%)";
    string widget_type = "slider";
    float min = 15.0;
    float max = 85.0;
    float step = 1.0;
> = 50.0;

float hash_angle(float n)
{
    return frac(sin(n) * 43758.5453123);
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;
    float4 base_col = image.Sample(textureSampler, uv);

    float2 focus = float2(centro_x * 0.01, centro_y * 0.01);
    float2 delta = uv - focus;

    delta.x *= uv_size.x / uv_size.y;
    float dist = length(delta);

    float angle = atan2(delta.y, delta.x);
    float angle_norm = (angle + 3.14159265) / (2.0 * 3.14159265);

    float sector = floor(angle_norm * cantidad_lineas);
    float time_seed = floor(elapsed_time * velocidad);
    float line_prob = hash_angle(sector * 12.9898 + time_seed * 78.233);

    float line_mask = 0.0;
    if (line_prob > 0.6) {
        float sub_sector = frac(angle_norm * cantidad_lineas);
        line_mask = smoothstep(0.0, 0.2, abs(sub_sector - 0.5) * 2.0);
        line_mask = 1.0 - line_mask;
    }

    float safe_radius = (radio_seguro_centro * 0.01) * 0.7;
    float radial_fade = smoothstep(safe_radius, safe_radius + 0.25, dist);

    float alpha_ray = line_mask * radial_fade * intensidad_lineas;

    float3 final_rgb = lerp(base_col.rgb, color_lineas.rgb, alpha_ray * color_lineas.a);

    return float4(final_rgb, base_col.a);
}
