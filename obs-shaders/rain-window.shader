uniform float size <
    string name = "Tamaño de las Gotas de Lluvia";
    string label = "Tamaño de las Gotas de Lluvia";
    string widget_type = "slider";
    float min = 0.05;
    float max = 0.35;
    float minimum = 0.05;
    float maximum = 0.35;
    float step = 0.01;
> = 0.14;

uniform float blurSize <
    string name = "Desenfoque de Empañado del Vidrio (px)";
    string label = "Desenfoque de Empañado del Vidrio (px)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 40.0;
    float minimum = 0.0;
    float maximum = 40.0;
    float step = 0.5;
> = 12.0;

uniform float trail_strength <
    string name = "Visibilidad de los Rastros de Agua (%)";
    string label = "Visibilidad de los Rastros de Agua (%)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 100.0;
    float minimum = 0.0;
    float maximum = 100.0;
    float step = 1.0;
> = 85.0;

uniform float trail_color <
    string name = "Oscurecimiento del Rastro (%)";
    string label = "Oscurecimiento del Rastro (%)";
    string widget_type = "slider";
    float min = 0.0;
    float max = 80.0;
    float minimum = 0.0;
    float maximum = 80.0;
    float step = 1.0;
> = 35.0;

uniform float speed <
    string name = "Velocidad de Caída de la Lluvia (%)";
    string label = "Velocidad de Caída de la Lluvia (%)";
    string widget_type = "slider";
    float min = 10.0;
    float max = 160.0;
    float minimum = 10.0;
    float maximum = 160.0;
    float step = 5.0;
> = 80.0;

uniform bool debug <
    string name = "Mostrar Cuadrícula de Depuración";
> = false;

float fract(float v) {
    return v - floor(v);
}

float2 fract2(float2 v) {
    return float2(v.x - floor(v.x), v.y - floor(v.y));
}

float3 fract3(float3 v) {
    return float3(v.x - floor(v.x), v.y - floor(v.y), v.z - floor(v.z));
}

float3 fract4(float4 v) {
    return float4(v.x - floor(v.x), v.y - floor(v.y), v.z - floor(v.z), v.w - floor(v.w));
}

float3 N13(float p) {
    float3 p3 = fract3(float3(p, p, p) * float3(.1031, .11369, .13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract3(float3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
}

float N(float t) {
    return fract(sin(t * 12345.564) * 7658.76);
}

float Saw(float b, float t) {
    return smoothstep(0., b, t) * smoothstep(1., b, t);
}

float2 Drops(float2 uv, float t) {
    float2 UV = uv;

    uv.y += t * 0.8;
    float2 a = float2(6., 1.);
    float2 grid = a * 2.;
    float2 id = floor(uv * grid);

    float colShift = N(id.x);
    uv.y += colShift;

    id = floor(uv * grid);
    float3 n = N13(id.x * 35.2 + id.y * 2376.1);
    float2 st = fract2(uv * grid) - float2(.5, 0);

    float x = n.x - .5;
    float y = UV.y * 20.;

    float distort = sin(y + sin(y));
    x += distort * (.5 - abs(x)) * (n.z - .5);
    x *= .7;
    float ti = fract(t + n.z);
    y = (Saw(.85, ti) - .5) * .9 + .5;
    float2 p = float2(x, y);

    float d = length((st - p) * a.yx);
    float dSize = size;
    float Drop = smoothstep(dSize, .0, d);

    float r = sqrt(smoothstep(1., y, st.y));
    float cd = abs(st.x - x);

    float trail = smoothstep((dSize * .5 + .03) * r, (dSize * .5 - .05) * r, cd);
    float trailFront = smoothstep(-.02, .02, st.y - y);
    trail *= trailFront;

    y = UV.y;
    y += N(id.x);
    float trail2 = smoothstep(dSize * r, .0, cd);
    float droplets = max(0., (sin(y * (1. - y) * 120.) - st.y)) * trail2 * trailFront * n.z;
    y = fract(y * 10.) + (st.y - .5);
    float dd = length(st - float2(x, y));
    droplets = smoothstep(dSize * N(id.x), 0., dd);
    float m = Drop + droplets * r * trailFront;
    if (debug) {
        m += st.x > a.y * .45 || st.y > a.x * .165 ? 1.2 : 0.;
    }

    return float2(m, trail);
}

float2 Rain(float2 uv, float t) {
    float2 r1 = Drops(uv, t);
    float2 r2 = Drops(uv * 1.8, t);
    float c;
    if (debug) {
        c = r1.x;
    } else {
        c = r1.x + r2.x;
    }

    c = smoothstep(.3, 1., c);

    if (debug) {
        return float2(c, r1.y);
    } else {
        return float2(c, max(r1.y, r2.y));
    }
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 uv = v_in.uv;
    uv.y = 1.0 - uv.y;
    uv = uv * uv_scale;
    float2 UV = v_in.uv;
    float T = elapsed_time * speed / 100.0;
    float t = T * .2;

    float2 c = Rain(uv, t);

    float2 e = float2(.001, 0.);
    float cx = Rain(uv + e, t).x;
    float cy = Rain(uv + e.yx, t).x;
    float2 n = float2(cx - c.x, cy - c.x);

    float Pi = 6.28318530718;
    float Directions = 24.0;
    float Quality = 6.0;
    float2 Radius = blurSize / uv_size;
    float3 col = image.Sample(textureSampler, UV).rgb;

    if (blurSize > 0.0) {
        for (float d = 0.0; d < Pi; d += Pi / Directions) {
            for (float i = 1.0 / Quality; i <= 1.0; i += 1.0 / Quality) {
                float2 uv2;
                if (debug) {
                    uv2 = UV + c + float2(cos(d), sin(d)) * Radius * i;
                } else {
                    uv2 = UV + n + float2(cos(d), sin(d)) * Radius * i;
                }
                col += image.Sample(textureSampler, uv2).rgb;
            }
        }
        col /= Quality * Directions;
    }

    float3 tex = image.Sample(textureSampler, UV + n).rgb;

    c.y = clamp(c.y, 0.0, 1.);
    c.y = c.y * trail_strength / 100.0;
    col -= c.y;
    col += c.y * (tex + 1.0 - trail_color / 100.0);

    return float4(col, 1.);
}