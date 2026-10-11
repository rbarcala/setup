uniform float Velocidad <
    string name = "Velocidad de Movimiento de la Linterna (%)";
    string label = "Velocidad de Movimiento de la Linterna (%)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 150.0;
    float minimum = 0.0;
    float maximum = 150.0;
    float step = 1.0;
> = 75.0;

uniform float Movimiento_Amplitud <
    string name = "Recorrido / Amplitud del Movimiento";
    string label = "Recorrido / Amplitud del Movimiento";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.65;
    float minimum = 0.0;
    float maximum = 0.65;
    float step = 0.01;
> = 0.25;

uniform float Apertura_Luz <
    string name = "Tamaño del Haz de Luz (%)";
    string label = "Tamaño del Haz de Luz (%)";
    string widget_type = "slider";
    float min = 20.0;
    float max = 98.0;
    float minimum = 20.0;
    float maximum = 98.0;
    float step = 0.5;
> = 80.0;

uniform float Intensidad <
    string name = "Brillo de la Linterna";
    string label = "Brillo de la Linterna";
    string widget_type = "slider";
    float min = 0.2;
    float max = 3.0;
    float minimum = 0.2;
    float maximum = 3.0;
    float step = 0.05;
> = 1.2;

uniform float Luz_Ambiente <
    string name = "Brillo del Fondo Oscuro (Ambiente)";
    string label = "Brillo del Fondo Oscuro (Ambiente)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.8;
    float minimum = 0.0;
    float maximum = 0.8;
    float step = 0.01;
> = 0.04;

uniform float4 Spotlight_Color <
    string name = "Color del Foco de Luz";
    string label = "Color del Foco de Luz";
    string widget_type = "color";
> = {1.0, 1.0, 1.0, 1.0};

uniform float Horizontal_Offset <
    string name = "Posición Horizontal del Foco (X)";
    string label = "Posición Horizontal del Foco (X)";
    string widget_type = "slider";
    float min = -0.5;
    float max = 0.5;
    float minimum = -0.5;
    float maximum = 0.5;
    float step = 0.01;
> = 0.0;

uniform float Vertical_Offset <
    string name = "Posición Vertical del Foco (Y)";
    string label = "Posición Vertical del Foco (Y)";
    string widget_type = "slider";
    float min = -0.5;
    float max = 0.5;
    float minimum = -0.5;
    float maximum = 0.5;
    float step = 0.01;
> = 0.0;

float4 mainImage(VertData v_in) : TARGET
{
    float speed = Velocidad * 0.01;
    float focus = 101.0 - Apertura_Luz;

    float PI = 3.14159265358979323846;
    float4 c0 = image.Sample(textureSampler, v_in.uv);

    float moveX = sin(elapsed_time * speed * PI * 0.667) * Movimiento_Amplitud;
    float moveY = cos(elapsed_time * speed * PI) * Movimiento_Amplitud;

    float3 lightsrc = float3(0.5 + Horizontal_Offset + moveX, 0.5 + Vertical_Offset + moveY, 1.0);
    float3 light = normalize(lightsrc - float3(v_in.uv.x, v_in.uv.y, 0.0));

    float light_power = pow(max(dot(light, float3(0.0, 0.0, 1.0)), 0.0), focus);
    float final_light = max(light_power * Intensidad, Luz_Ambiente);

    c0.rgb *= final_light;
    if (Spotlight_Color.a > 0.01) {
        c0.rgb *= Spotlight_Color.rgb;
    }

    return c0;
}
