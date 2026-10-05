uniform float radio_sup_izq <
    string name = "Superior Izquierda";
    string widget_type = "slider";
    float min = 0.0;
    float max = 50.0;
    float step = 0.1;
> = 0.0;

uniform float radio_sup_der <
    string name = "Superior Derecha";
    string widget_type = "slider";
    float min = 0.0;
    float max = 50.0;
    float step = 0.1;
> = 0.0;

uniform float radio_inf_izq <
    string name = "Inferior Izquierda";
    string widget_type = "slider";
    float min = 0.0;
    float max = 50.0;
    float step = 0.1;
> = 0.0;

uniform float radio_inf_der <
    string name = "Inferior Derecha";
    string widget_type = "slider";
    float min = 0.0;
    float max = 50.0;
    float step = 0.1;
> = 0.0;

uniform bool diagonal <
    string name = "Corte Diagonal (marcado) / Redondo (desmarcado)";
> = false;

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;
    float2 px = uv * uv_size;
    
    // Usamos la dimensión menor para que el % del radio sea proporcional y circular
    float min_dim = min(uv_size.x, uv_size.y);
    float r_tl = (radio_sup_izq * 0.01) * min_dim;
    float r_tr = (radio_sup_der * 0.01) * min_dim;
    float r_bl = (radio_inf_izq * 0.01) * min_dim;
    float r_br = (radio_inf_der * 0.01) * min_dim;
    
    float alpha_mult = 1.0;
    
    // Esquina Superior Izquierda
    if (px.x < r_tl && px.y < r_tl) {
        if (diagonal) {
            alpha_mult = min(alpha_mult, clamp(((px.x + px.y) - r_tl) / 1.4142 + 0.5, 0.0, 1.0));
        } else {
            float d = length(float2(r_tl, r_tl) - px);
            alpha_mult = min(alpha_mult, clamp(r_tl - d + 0.5, 0.0, 1.0));
        }
    }
    
    // Esquina Superior Derecha
    float dx_tr = uv_size.x - px.x;
    if (dx_tr < r_tr && px.y < r_tr) {
        if (diagonal) {
            alpha_mult = min(alpha_mult, clamp(((dx_tr + px.y) - r_tr) / 1.4142 + 0.5, 0.0, 1.0));
        } else {
            float d = length(float2(r_tr, r_tr) - float2(dx_tr, px.y));
            alpha_mult = min(alpha_mult, clamp(r_tr - d + 0.5, 0.0, 1.0));
        }
    }
    
    // Esquina Inferior Izquierda
    float dy_bl = uv_size.y - px.y;
    if (px.x < r_bl && dy_bl < r_bl) {
        if (diagonal) {
            alpha_mult = min(alpha_mult, clamp(((px.x + dy_bl) - r_bl) / 1.4142 + 0.5, 0.0, 1.0));
        } else {
            float d = length(float2(r_bl, r_bl) - float2(px.x, dy_bl));
            alpha_mult = min(alpha_mult, clamp(r_bl - d + 0.5, 0.0, 1.0));
        }
    }
    
    // Esquina Inferior Derecha
    float dx_br = uv_size.x - px.x;
    float dy_br = uv_size.y - px.y;
    if (dx_br < r_br && dy_br < r_br) {
        if (diagonal) {
            alpha_mult = min(alpha_mult, clamp(((dx_br + dy_br) - r_br) / 1.4142 + 0.5, 0.0, 1.0));
        } else {
            float d = length(float2(r_br, r_br) - float2(dx_br, dy_br));
            alpha_mult = min(alpha_mult, clamp(r_br - d + 0.5, 0.0, 1.0));
        }
    }
    
    float4 col = image.Sample(textureSampler, uv);
    col.a *= alpha_mult; // Recorte con borde suavizado
    
    return col;
}
