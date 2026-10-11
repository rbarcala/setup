uniform float centro_x <
    string name = "Posición Horizontal de la Lupa (%)";
    string widget_type = "slider";
    float min = 5.0;
    float max = 95.0;
    float step = 0.5;
> = 50.0;

uniform float centro_y <
    string name = "Posición Vertical de la Lupa (%)";
    string widget_type = "slider";
    float min = 5.0;
    float max = 95.0;
    float step = 0.5;
> = 50.0;

uniform float radio_lente <
    string name = "Tamaño de la Lupa (píxeles en 1080p)";
    string widget_type = "slider";
    float min = 40.0;
    float max = 450.0;
    float step = 5.0;
> = 180.0;

uniform float factor_zoom <
    string name = "Nivel de Aumento (Zoom)";
    string widget_type = "slider";
    float min = 1.1;
    float max = 4.0;
    float step = 0.05;
> = 2.0;

uniform float grosor_borde <
    string name = "Grosor del Marco de la Lupa (px)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 16.0;
    float step = 0.5;
> = 5.0;

uniform float4 color_marco <
    string name = "Color del Marco";
    string widget_type = "color";
> = {0.9, 0.9, 0.95, 1.0};

uniform float distorsion_lente <
    string name = "Efecto Lente Curvo (Ojo de Pez)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.8;
    float step = 0.05;
> = 0.30;

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;
    float2 px = uv * uv_size;
    float2 center_px = float2(centro_x * 0.01 * uv_size.x, centro_y * 0.01 * uv_size.y);

    float dist = length(px - center_px);

    if (dist > radio_lente + grosor_borde) {
        return image.Sample(textureSampler, uv);
    }

    if (dist > radio_lente) {
        float highlight = 0.8 + 0.3 * sin((px.x - center_px.x + px.y - center_px.y) * 0.05);
        return float4(clamp(color_marco.rgb * highlight, 0.0, 1.0), 1.0);
    }

    float normalized_dist = dist / radio_lente;
    float lens_curvature = 1.0;
    if (distorsion_lente > 0.001) {
        lens_curvature += pow(normalized_dist, 2.0) * distorsion_lente;
    }

    float2 offset_from_center = (px - center_px) / (factor_zoom * lens_curvature);
    float2 magnified_px = center_px + offset_from_center;
    float2 magnified_uv = clamp(magnified_px / uv_size, 0.0, 1.0);

    float4 zoomed_col = image.Sample(textureSampler, magnified_uv);

    float glass_specular = smoothstep(0.7, 1.0, (center_px.y - px.y + px.x - center_px.x) / radio_lente) * 0.15;
    zoomed_col.rgb += glass_specular;

    float inner_shadow = smoothstep(radio_lente * 0.85, radio_lente, dist) * 0.25;
    zoomed_col.rgb *= (1.0 - inner_shadow);

    return float4(clamp(zoomed_col.rgb, 0.0, 1.0), zoomed_col.a);
}
