#extension GL_OES_standard_derivatives : enable
precision mediump float;

varying vec2 v_texcoord;
varying vec3 v_normal;
varying vec2 v_texSize;

uniform sampler2D msdf;
uniform float pxRange;
uniform vec4 fgColor;
uniform float texelSize;

float median(float r, float g, float b) {
    return max(min(r, g), min(max(r, g), b));
}

float sample_opacity(vec2 texcoord) {
    vec2 msdfUnit = pxRange / v_texSize;
    vec3 sample = texture2D(msdf, texcoord).rgb;
    float sigDist = median(sample.r, sample.g, sample.b) - 0.5;
    sigDist *= dot(msdfUnit, 0.5 / fwidth(texcoord * v_texSize));
    float opacity = clamp(sigDist + 0.5, 0.0, 1.0);

    return opacity;
}

void main() {
    vec2 dx3 = abs(dFdx(v_texcoord) / 3.0);
    vec2 dy3 = abs(dFdy(v_texcoord) / 3.0);

    float opacity_center = sample_opacity(v_texcoord);

    float opacity_corners =
        + sample_opacity(v_texcoord + dx3)
        + sample_opacity(v_texcoord - dx3)
        + sample_opacity(v_texcoord + dy3)
        + sample_opacity(v_texcoord - dy3)
        + sample_opacity(v_texcoord + dx3 + dy3)
        + sample_opacity(v_texcoord + dx3 - dy3)
        + sample_opacity(v_texcoord - dx3 + dy3)
        + sample_opacity(v_texcoord - dx3 - dy3);
    
    vec2 dx3tex = dx3 * texelSize;
    vec2 dy3tex = dy3 * texelSize;

    float is_tiny = step(min(length(dx3tex), length(dy3tex)), 1.0);

    float opacity = (opacity_center + is_tiny * opacity_corners) / (1.0 + is_tiny * 8.0);

    opacity = mix(opacity, smoothstep(0.1, 0.6, opacity), is_tiny); 

    gl_FragColor = vec4(fgColor.rgb, fgColor.a * opacity);
}
