uniform float speed <
    string name = "Velocidad";
    string widget_type = "slider";
    float min = -5.0;
    float max = 5.0;
    float step = 0.1;
> = 1.0;

uniform float scale <
    string name = "Tamaño de los Espejos";
    string widget_type = "slider";
    float min = 5.0;
    float max = 100.0;
    float step = 1.0;
> = 25.0;

uniform float4 tint <
    string name = "Tinte de Luz";
    string widget_type = "color";
> = {0.9, 0.9, 1.0, 1.0};

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;
    
    // Convertir coordenadas centradas -1..1
    float2 p = (uv - 0.5) * 2.0;
    p.x *= (uv_size.x / uv_size.y);
    
    float r = dot(p, p);
    
    // Si estamos fuera del círculo, hacemos transparente el fondo
    // pero permitimos ver la fuente original si quisieran (opcional). 
    // Usualmente una bola de disco es un objeto en sí mismo, pero
    // mezclaremos con la imagen original si se sale del círculo.
    float4 base_col = image.Sample(textureSampler, uv);
    
    if (r > 1.0) {
        return float4(0.0, 0.0, 0.0, 0.0); 
    }
    
    // Mapeo 3D de esfera plana (proyección)
    float z = sqrt(1.0 - r);
    // Coordenadas esféricas (longitude / latitude)
    float lon = atan2(p.x, z);
    float lat = asin(p.y);
    
    // Animación de rotación
    lon += elapsed_time * speed;
    
    // Cuadrícula esférica
    float2 sp = float2(lon, lat) * scale;
    
    float2 grid = frac(sp);
    float2 local_uv = (grid - 0.5) * 2.0;
    
    // Borde de los espejitos (bump mapping falso)
    float dist = max(abs(local_uv.x), abs(local_uv.y));
    float edge = smoothstep(0.7, 1.0, dist);
    
    // ID del espejito para pseudo-aleatoriedad
    float2 id = floor(sp);
    float random_val = frac(sin(dot(id, float2(12.9898, 78.233))) * 43758.5453);
    
    // Destello de colores tipo bola de disco
    float flash = pow(sin(elapsed_time * 2.0 + random_val * 6.28) * 0.5 + 0.5, 4.0);
    
    // Reflejo de la imagen base distorsionada por los espejos
    // Para que la bola de disco no sea solo gris, reflejamos la fuente de video
    float2 mirror_uv = frac(id / scale); 
    float4 mirror_tex = image.Sample(textureSampler, mirror_uv);
    
    float3 mirror_col = mirror_tex.rgb + tint.rgb * (random_val * 0.3 + flash * 0.7);
    
    // Oscurecer bordes entre espejos
    mirror_col *= (1.0 - edge * 0.8);
    
    // Sombrear los bordes de la esfera completa para que se vea redonda
    float sphere_shading = smoothstep(1.0, 0.4, sqrt(r));
    mirror_col *= sphere_shading;
    
    // Brillo especular global
    float specular = pow(max(0.0, p.x*0.5 - p.y*0.5 + z*0.7), 10.0);
    mirror_col += float3(specular, specular, specular) * 0.8;
    
    return float4(mirror_col, 1.0);
}
