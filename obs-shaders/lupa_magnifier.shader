uniform float centro_x <
    string name = "Posición Centro X (%)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 100.0;
    float step = 0.5;
> = 50.0;

uniform float centro_y <
    string name = "Posición Centro Y (%)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 100.0;
    float step = 0.5;
> = 50.0;

uniform float radio_lente <
    string name = "Radio de la Lupa (píxeles)";
    string widget_type = "slider";
    float min = 20.0;
    float max = 600.0;
    float step = 5.0;
> = 180.0;

uniform float factor_zoom <
    string name = "Nivel de Aumento (Zoom)";
    string widget_type = "slider";
    float min = 1.0;
    float max = 5.0;
    float step = 0.05;
> = 2.2;

uniform float grosor_borde <
    string name = "Grosor del Marco";
    string widget_type = "slider";
    float min = 0.0;
    float max = 20.0;
    float step = 0.5;
> = 5.0;

uniform float4 color_marco <
    string name = "Color del Marco";
    string widget_type = "color";
> = {0.9, 0.9, 0.95, 1.0};

uniform float distorsion_lente <
    string name = "Curvatura Óptica de la Lente (Ojo de Pez)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.35;

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;
    float2 px = uv * uv_size;
    float2 center_px = float2(centro_x * 0.01 * uv_size.x, centro_y * 0.01 * uv_size.y);

    float dist = length(px - center_px);

    // Si está fuera del radio de la lupa + marco, mostramos la imagen normal
    if (dist > radio_lente + grosor_borde) {
        return image.Sample(textureSampler, uv);
    }

    // Dibujar el marco exterior metálico / bisel
    if (dist > radio_lente) {
        float border_rel = (dist - radio_lente) / max(grosor_borde, 0.001);
        // Sombra y brillo cilíndrico en el marco
        float highlight = 0.8 + 0.3 * sin((px.x - center_px.x + px.y - center_px.y) * 0.05);
        return float4(color_marco.rgb * highlight, 1.0);
    }

    // Dentro de la lupa: calcular zoom y distorsión esférica
    float normalized_dist = dist / radio_lente;
    float lens_curvature = 1.0;
    if (distorsion_lente > 0.001) {
        lens_curvature += pow(normalized_dist, 2.0) * distorsion_lente;
    }

    float2 offset_from_center = (px - center_px) / (factor_zoom * lens_curvature);
    float2 magnified_px = center_px + offset_from_center;
    float2 magnified_uv = magnified_px / uv_size;

    float4 zoomed_col = image.Sample(textureSampler, magnified_uv);

    // Brillo sutil de cristal en la superficie
    float glass_specular = smoothstep(0.7, 1.0, (center_px.y - px.y + px.x - center_px.x) / radio_lente) * 0.15;
    zoomed_col.rgb += glass_specular;

    // Sombra interior en el borde de la lente
    float inner_shadow = smoothstep(radio_lente * 0.85, radio_lente, dist) * 0.25;
    zoomed_col.rgb *= (1.0 - inner_shadow);

    return zoomed_col;
}

