uniform float segments <
    string name = "Segmentos";
    string widget_type = "slider";
    float min = 1.0;
    float max = 32.0;
    float step = 1.0;
> = 6.0;

uniform float rotation_speed <
    string name = "Velocidad de Órbita";
    string widget_type = "slider";
    float min = -5.0;
    float max = 5.0;
    float step = 0.1;
> = 1.0;

uniform float zoom <
    string name = "Zoom";
    string widget_type = "slider";
    float min = 0.1;
    float max = 5.0;
    float step = 0.05;
> = 0.8;

uniform float center_x <
    string name = "Centro X";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.01;
> = 0.5;

uniform float center_y <
    string name = "Centro Y";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.01;
> = 0.5;

uniform float rgb_split <
    string name = "Aberración Cromática";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.1;
    float step = 0.001;
> = 0.01;

// Función para un módulo seguro en HLSL (para float)
float custom_mod(float x, float y) {
    return x - y * floor(x/y);
}

// Función para un módulo seguro en HLSL (para float2)
float2 custom_mod2(float2 x, float y) {
    return x - y * floor(x/y);
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;
    float2 center = float2(center_x, center_y);
    float2 p = uv - center;
    
    // Corregir la relación de aspecto (para que el círculo no sea un óvalo)
    float aspect = uv_size.x / uv_size.y;
    p.x *= aspect;
    
    float radius = length(p) * zoom;
    float angle = atan2(p.y, p.x);
    
    // Aplicar la órbita/rotación continua
    angle += elapsed_time * rotation_speed;
    
    // Lógica del caleidoscopio
    float pi = 3.14159265359;
    float segmentAngle = pi * 2.0 / max(1.0, segments);
    
    angle = custom_mod(angle, segmentAngle);
    angle = abs(angle - segmentAngle / 2.0);
    
    // Calcular coordenadas para cada canal de color (desfase RGB para hacerlo vistoso)
    float2 uv_r = float2(cos(angle), sin(angle)) * radius * (1.0 - rgb_split);
    float2 uv_g = float2(cos(angle), sin(angle)) * radius;
    float2 uv_b = float2(cos(angle), sin(angle)) * radius * (1.0 + rgb_split);
    
    // Devolver al espacio de textura normal
    uv_r.x /= aspect; uv_r += float2(0.5, 0.5);
    uv_g.x /= aspect; uv_g += float2(0.5, 0.5);
    uv_b.x /= aspect; uv_b += float2(0.5, 0.5);
    
    // Espejar si se sale de los bordes para que no haya cortes negros
    uv_r = 1.0 - abs(custom_mod2(uv_r, 2.0) - 1.0);
    uv_g = 1.0 - abs(custom_mod2(uv_g, 2.0) - 1.0);
    uv_b = 1.0 - abs(custom_mod2(uv_b, 2.0) - 1.0);
    
    // Tomar las muestras de colores
    float r = image.Sample(textureSampler, uv_r).r;
    float g = image.Sample(textureSampler, uv_g).g;
    float b = image.Sample(textureSampler, uv_b).b;
    
    return float4(r, g, b, 1.0);
}
