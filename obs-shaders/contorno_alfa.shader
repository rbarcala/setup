uniform float outline_size <
    string name = "Grosor del Contorno";
    string widget_type = "slider";
    float min = 0.0;
    float max = 50.0;
    float step = 0.5;
> = 5.0;

uniform float4 outline_color <
    string name = "Color del Contorno";
    string widget_type = "color";
> = {0.0, 0.0, 0.0, 1.0};

uniform int samples <
    string name = "Calidad (Muestras)";
    string widget_type = "slider";
    int min = 8;
    int max = 128;
    int step = 8;
> = 32;

float4 mainImage(VertData v_in) : TARGET
{
    float4 col = image.Sample(textureSampler, v_in.uv);
    
    // Si no hay contorno o el pixel ya es totalmente opaco, devolvemos el original
    if (outline_size <= 0.0 || col.a >= 0.99) {
        return col;
    }
    
    float max_alpha = col.a;
    float golden_angle = 2.39996323; // Ángulo de proporción áurea para distribuir los puntos
    
    // Buscamos en un radio alrededor del pixel usando una espiral de Fibonacci
    // Esto garantiza un contorno sólido detectando si hay partes opacas cerca
    for (int i = 1; i <= samples; ++i) {
        float fi = float(i);
        float fsamples = float(samples);
        
        float r = sqrt(fi / fsamples) * outline_size;
        float theta = fi * golden_angle;
        
        float2 offset = float2(cos(theta), sin(theta)) * r * uv_pixel_interval;
        float sample_alpha = image.Sample(textureSampler, v_in.uv + offset).a;
        
        if (sample_alpha > max_alpha) {
            max_alpha = sample_alpha;
        }
    }
    
    // Si detectamos píxeles vecinos opacos, dibujamos el contorno
    if (max_alpha > col.a) {
        float4 out_col = float4(outline_color.rgb, outline_color.a * max_alpha);
        
        // Fusión estándar (Alpha Compositing: SrcOver)
        float out_a = col.a + out_col.a * (1.0 - col.a);
        if (out_a > 0.0) {
            float3 out_rgb = (col.rgb * col.a + out_col.rgb * out_col.a * (1.0 - col.a)) / out_a;
            return float4(out_rgb, out_a);
        }
    }
    
    return col;
}
