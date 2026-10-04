// Spotlight Pro (Mejorado con controles de desvío, apertura e intensidad)
uniform float Velocidad<
    string label = "Velocidad del movimiento";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 100.0;
    float step = 0.01;
> = 100.0; 

uniform float Movimiento_Amplitud<
    string label = "Desvio / Amplitud";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.01;
> = 0.15; // Valor por defecto más bajo para que no se desvíe locamente

uniform float Apertura_Luz<
    string label = "Apertura de la luz";
    string widget_type = "slider";
    float minimum = 1.0;
    float maximum = 100.0;
    float step = 0.1;
> = 85.0;

uniform float Intensidad<
    string label = "Intensidad";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 5.0;
    float step = 0.01;
> = 1.0;

uniform float Luz_Ambiente<
    string label = "Luz Ambiente (Fondo)";
    string widget_type = "slider";
    float minimum = 0.0;
    float maximum = 1.0;
    float step = 0.01;
> = 0.0;

uniform float4 Spotlight_Color;

uniform float Horizontal_Offset<
    string label = "Centro Horizontal";
    string widget_type = "slider";
    float minimum = -1.0;
    float maximum = 1.0;
    float step = 0.001;
> = 0.0;

uniform float Vertical_Offset<
    string label = "Centro Vertical";
    string widget_type = "slider";
    float minimum = -1.0;
    float maximum = 1.0;
    float step = 0.001;
> = 0.0;


float4 mainImage(VertData v_in) : TARGET
{
    float speed = Velocidad * 0.01;
    // Invertimos matemáticamente el valor para que sea intuitivo: 
    // Más "Apertura_Luz" en el slider = haz de luz más ancho.
    float focus = 101.0 - Apertura_Luz;
    
    float PI = 3.14159265358979323846;
    float4 c0 = image.Sample(textureSampler, v_in.uv);
    
    // Cálculo del desvío ondulatorio (cuánto se mueve)
    float moveX = sin(elapsed_time * speed * PI * 0.667) * Movimiento_Amplitud;
    float moveY = cos(elapsed_time * speed * PI) * Movimiento_Amplitud;
    
    // Posición origen de la fuente de luz (X, Y, Z)
    float3 lightsrc = float3(0.5 + Horizontal_Offset + moveX, 0.5 + Vertical_Offset + moveY, 1.0);
    
    // Vector direccional desde el origen hasta el píxel
    float3 light = normalize(lightsrc - float3(v_in.uv.x, v_in.uv.y, 0.0));
    
    // Cálculo central del brillo del spotlight
    float light_power = pow(max(dot(light, float3(0.0, 0.0, 1.0)), 0.0), focus);
    
    // Luz final combinando intensidad y asegurando que no baje del ambiente
    float final_light = max(light_power * Intensidad, Luz_Ambiente);
    
    c0.rgb *= final_light;
    c0 *= Spotlight_Color;

    return c0;
}

