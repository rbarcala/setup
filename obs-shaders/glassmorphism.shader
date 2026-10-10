uniform float desenfoque_radio <
    string name = "Radio de Difuminado (Blur)";
    string widget_type = "slider";
    float min = 1.0;
    float max = 20.0;
    float step = 0.5;
> = 8.0;

uniform float4 tinte_cristal <
    string name = "Color / Tinte del Vidrio";
    string widget_type = "color";
> = {1.0, 1.0, 1.0, 0.25};

uniform float brillo_especular <
    string name = "Brillo y Gradiente de Cristal";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.35;

uniform float ruido_escarcha <
    string name = "Textura de Escarcha / Esmerilado";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.5;
    float step = 0.01;
> = 0.08;

float rand(float2 co)
{
    return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;
    float2 texel = 1.0 / uv_size;

    float4 accum = float4(0.0, 0.0, 0.0, 0.0);
    float frost = (rand(uv * 500.0) - 0.5) * ruido_escarcha * desenfoque_radio;
    float r = (desenfoque_radio + frost) * texel.y;

    // Muestreo circular en 2 anillos (16 muestras) sin arrays estilo C
    accum += image.Sample(textureSampler, uv);
    
    // Anillo exterior (8 direcciones)
    accum += image.Sample(textureSampler, uv + float2( 1.0,  0.0) * r);
    accum += image.Sample(textureSampler, uv + float2(-1.0,  0.0) * r);
    accum += image.Sample(textureSampler, uv + float2( 0.0,  1.0) * r);
    accum += image.Sample(textureSampler, uv + float2( 0.0, -1.0) * r);
    accum += image.Sample(textureSampler, uv + float2( 0.7,  0.7) * r);
    accum += image.Sample(textureSampler, uv + float2(-0.7,  0.7) * r);
    accum += image.Sample(textureSampler, uv + float2( 0.7, -0.7) * r);
    accum += image.Sample(textureSampler, uv + float2(-0.7, -0.7) * r);

    // Anillo medio (8 direcciones a media distancia)
    float r_half = r * 0.5;
    accum += image.Sample(textureSampler, uv + float2( 0.92,  0.38) * r_half);
    accum += image.Sample(textureSampler, uv + float2(-0.92,  0.38) * r_half);
    accum += image.Sample(textureSampler, uv + float2( 0.38,  0.92) * r_half);
    accum += image.Sample(textureSampler, uv + float2(-0.38, -0.92) * r_half);
    accum += image.Sample(textureSampler, uv + float2(-0.38,  0.92) * r_half);
    accum += image.Sample(textureSampler, uv + float2( 0.38, -0.92) * r_half);
    accum += image.Sample(textureSampler, uv + float2( 0.92, -0.38) * r_half);
    accum += image.Sample(textureSampler, uv + float2(-0.92, -0.38) * r_half);

    float4 blurred = accum / 17.0;

    // Gradiente diagonal característico de glassmorphism (luz en esquina superior izquierda)
    float grad = (1.0 - uv.y * 0.7 + (1.0 - uv.x) * 0.3) * brillo_especular;

    // Mezcla de tinte blanco translúcido
    float3 frosted_rgb = lerp(blurred.rgb, tinte_cristal.rgb, tinte_cristal.a);
    frosted_rgb += grad * 0.25;

    return float4(frosted_rgb, blurred.a);
}
