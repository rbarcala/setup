uniform int modo_color <
    string name = "Modo de Color (0: Normal, 1: Game Boy, 2: CGA Retro, 3: Monocromático)";
    string widget_type = "slider";
    int min = 0;
    int max = 3;
    int step = 1;
> = 0;

uniform float pixel_size <
    string name = "Tamaño de Píxel";
    string widget_type = "slider";
    float min = 1.0;
    float max = 64.0;
    float step = 1.0;
> = 8.0;

uniform float niveles_color <
    string name = "Niveles de Color (Modo Normal)";
    string widget_type = "slider";
    float min = 2.0;
    float max = 32.0;
    float step = 1.0;
> = 6.0;

uniform float dither_strength <
    string name = "Intensidad de Dither (Bayer 4x4)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.02;
> = 0.3;

// Matriz de dithering Bayer 4x4 evaluada sin array inicializador C
float bayer4x4(float2 pos)
{
    int x = int(fmod(pos.x, 4.0));
    int y = int(fmod(pos.y, 4.0));
    
    float val = 0.0;
    if (y == 0) {
        if (x == 0) val = 0.0;
        else if (x == 1) val = 8.0;
        else if (x == 2) val = 2.0;
        else val = 10.0;
    } else if (y == 1) {
        if (x == 0) val = 12.0;
        else if (x == 1) val = 4.0;
        else if (x == 2) val = 14.0;
        else val = 6.0;
    } else if (y == 2) {
        if (x == 0) val = 3.0;
        else if (x == 1) val = 11.0;
        else if (x == 2) val = 1.0;
        else val = 9.0;
    } else {
        if (x == 0) val = 15.0;
        else if (x == 1) val = 7.0;
        else if (x == 2) val = 13.0;
        else val = 5.0;
    }

    return (val / 16.0) - 0.5;
}

float3 get_gb_color(int idx)
{
    if (idx == 0) return float3(0.06, 0.22, 0.06);
    if (idx == 1) return float3(0.19, 0.38, 0.19);
    if (idx == 2) return float3(0.53, 0.75, 0.44);
    return float3(0.61, 0.73, 0.06);
}

float3 get_cga_color(int idx)
{
    if (idx == 0) return float3(0.0, 0.0, 0.0);
    if (idx == 1) return float3(0.0, 0.85, 0.85);
    if (idx == 2) return float3(0.85, 0.0, 0.85);
    return float3(1.0, 1.0, 1.0);
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 coord_px = v_in.uv * uv_size;
    // Pixelación
    float2 block_coord = floor(coord_px / pixel_size) * pixel_size;
    float2 pixel_uv = (block_coord + 0.5 * pixel_size) / uv_size;

    float4 col = image.Sample(textureSampler, pixel_uv);
    if (col.a <= 0.001) return col;

    float dither = bayer4x4(floor(coord_px / pixel_size)) * dither_strength;
    float luma = dot(col.rgb, float3(0.299, 0.587, 0.114));

    if (modo_color == 1) {
        // Paleta Clásica Game Boy (4 tonos verdes)
        float val = clamp(luma + dither, 0.0, 0.999) * 4.0;
        int idx = clamp(int(floor(val)), 0, 3);
        col.rgb = get_gb_color(idx);
    }
    else if (modo_color == 2) {
        // Paleta Retro CGA (Negro, Cian, Magenta, Blanco)
        float val = clamp(luma + dither, 0.0, 0.999) * 4.0;
        int idx = clamp(int(floor(val)), 0, 3);
        col.rgb = get_cga_color(idx);
    }
    else if (modo_color == 3) {
        // Monocromático 1-bit / escala de grises reducida
        float val = clamp(luma + dither, 0.0, 1.0);
        float quantized = floor(val * niveles_color + 0.5) / niveles_color;
        col.rgb = float3(quantized, quantized, quantized);
    }
    else {
        // Modo Normal con reducción de canales RGB y dither
        float3 dithered = col.rgb + dither;
        col.rgb = clamp(floor(dithered * (niveles_color - 1.0) + 0.5) / (niveles_color - 1.0), 0.0, 1.0);
    }

    return col;
}
