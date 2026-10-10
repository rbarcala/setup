uniform float offset_x <
    string name = "Desplazamiento X (píxeles)";
    string widget_type = "slider";
    float min = -50.0;
    float max = 50.0;
    float step = 1.0;
> = 12.0;

uniform float offset_y <
    string name = "Desplazamiento Y (píxeles)";
    string widget_type = "slider";
    float min = -50.0;
    float max = 50.0;
    float step = 1.0;
> = 14.0;

uniform float radio_desenfoque <
    string name = "Difuminado de la Sombra";
    string widget_type = "slider";
    float min = 0.0;
    float max = 30.0;
    float step = 1.0;
> = 12.0;

uniform float opacidad_sombra <
    string name = "Opacidad de la Sombra";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.65;

uniform float4 color_sombra <
    string name = "Color de la Sombra";
    string widget_type = "color";
> = {0.0, 0.0, 0.0, 1.0};

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;
    float4 foreground = image.Sample(textureSampler, uv);

    // Muestreo del alfa en la posición desplazada para calcular la sombra proyectada
    float2 shadow_center_uv = uv - float2(offset_x, offset_y) / uv_size;

    float shadow_alpha = 0.0;

    if (radio_desenfoque <= 0.5) {
        shadow_alpha = image.Sample(textureSampler, shadow_center_uv).a;
    } else {
        // Muestreo de 12 puntos en círculo para difusión suave de la sombra
        float rad = radio_desenfoque / uv_size.y;
        float total_samples = 12.0;
        float alpha_acc = 0.0;

        for (float i = 0.0; i < 12.0; i += 1.0) {
            float angle = i * (6.2831853 / 12.0);
            float2 s_uv = shadow_center_uv + float2(cos(angle), sin(angle)) * rad;
            alpha_acc += image.Sample(textureSampler, s_uv).a;
        }
        shadow_alpha = (alpha_acc / total_samples) * 0.7 + image.Sample(textureSampler, shadow_center_uv).a * 0.3;
    }

    shadow_alpha *= opacidad_sombra;

    // Componer: la sombra aparece solo donde el foreground no es 100% opaco
    float3 shadow_color = color_sombra.rgb;
    float out_alpha = foreground.a + shadow_alpha * (1.0 - foreground.a);
    float3 out_rgb = foreground.rgb * foreground.a + shadow_color * (shadow_alpha * (1.0 - foreground.a));

    if (out_alpha > 0.001) {
        out_rgb /= out_alpha;
    }

    return float4(out_rgb, clamp(out_alpha, 0.0, 1.0));
}

