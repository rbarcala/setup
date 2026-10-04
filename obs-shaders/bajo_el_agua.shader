uniform float water_level <
    string name = "Nivel del Agua (0 arriba, 1 abajo)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.01;
> = 0.4;

uniform float wave_speed <
    string name = "Velocidad de Olas";
    string widget_type = "slider";
    float min = 0.0;
    float max = 10.0;
    float step = 0.1;
> = 2.0;

uniform float wave_intensity <
    string name = "Intensidad de Olas";
    string widget_type = "slider";
    float min = 0.0;
    float max = 0.1;
    float step = 0.001;
> = 0.015;

uniform float4 water_color <
    string name = "Color del Agua";
    string widget_type = "color";
> = {0.1, 0.5, 0.8, 1.0};

uniform float tint_strength <
    string name = "Opacidad del Color";
    string widget_type = "slider";
    float min = 0.0;
    float max = 1.0;
    float step = 0.05;
> = 0.65;



float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;
    
    // Calcular el nivel del agua dinámico (la superficie ondea)
    float surface_wave = sin(uv.x * 12.0 + elapsed_time * wave_speed) * 0.015 +
                         cos(uv.x * 25.0 + elapsed_time * wave_speed * 1.3) * 0.008;
    
    float current_water_level = water_level + surface_wave;
    
    // Las coordenadas Y van de 0 (arriba) a 1 (abajo)
    if (uv.y > current_water_level) {
        // --- ESTAMOS BAJO EL AGUA ---
        float depth = uv.y - current_water_level; // Qué tan profundo estamos
        
        // 1. Distorsión de las olas (refracción)
        float2 water_uv = uv;
        water_uv.x += sin(uv.y * 20.0 + elapsed_time * wave_speed) * wave_intensity;
        water_uv.y += cos(uv.x * 15.0 + elapsed_time * wave_speed * 0.8) * wave_intensity;
        
        // Evitar que la refracción muestre el aire por error
        water_uv.y = max(water_uv.y, current_water_level + 0.001);
        
        float4 base_color = image.Sample(textureSampler, water_uv);
        
        // 2. Caústicas (Rayos de luz bailando bajo el agua)
        // Usamos una combinación de senos cruzados para dar ese efecto de red de luz
        float caustic = sin(water_uv.x * 40.0 + elapsed_time * 2.0) * 
                        cos(water_uv.y * 40.0 - elapsed_time * 2.5);
        // Resaltar solo los picos de luz
        caustic = smoothstep(0.7, 1.0, caustic) * 0.4; 
        
        // 3. Aplicar color (Tinte azulado/verdoso)
        // Multiplicamos el color original para oscurecer y teñir, luego mezclamos
        float3 tinted = base_color.rgb * water_color.rgb * 1.5;
        float3 final_rgb = lerp(base_color.rgb, tinted, tint_strength);
        
        // Añadir las luces (menos luces a mayor profundidad)
        final_rgb += caustic * max(0.0, (1.0 - depth * 1.5));
        
        // 4. Línea de superficie brillante (Espuma/límite)
        float surface_dist = abs(uv.y - current_water_level);
        if (surface_dist < 0.005) {
            float line_glow = 1.0 - (surface_dist / 0.005);
            final_rgb += float3(0.5, 0.8, 1.0) * line_glow;
        }
        
        return float4(final_rgb, base_color.a);
    } else {
        // --- ESTAMOS AL AIRE LIBRE ---
        return image.Sample(textureSampler, uv);
    }
}
