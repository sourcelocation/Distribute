#version 320 es

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 u_resolution;
uniform float u_rotation;
uniform vec4 u_effect_color;
uniform vec4 u_base_color;
uniform float u_cover_radius;
uniform float u_style;
uniform float u_cover_scale;
uniform sampler2D u_cover;
uniform sampler2D u_spinning;
uniform sampler2D u_static;
uniform sampler2D u_scratches;

out vec4 fragColor;

const float kMinAlpha = 0.2;

float gradientAlpha(float t) {
  if (t <= 0.4) {
    return kMinAlpha;
  }
  if (t <= 0.5) {
    return mix(kMinAlpha, 1.0, (t - 0.4) * 10.0);
  }
  if (t <= 0.6) {
    return mix(1.0, kMinAlpha, (t - 0.5) * 10.0);
  }
  return kMinAlpha;
}

vec2 rotate2d(vec2 v, float angle) {
  float c = cos(angle);
  float s = sin(angle);
  return vec2(c * v.x - s * v.y, s * v.x + c * v.y);
}

void main() {
  if (u_resolution.x <= 0.0 || u_resolution.y <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  vec2 frag = FlutterFragCoord();
  vec2 uv = frag / u_resolution;
  vec2 centered = uv - vec2(0.5);
  vec2 rotated = rotate2d(centered, u_rotation);
  vec2 rotUv = clamp(rotated + vec2(0.5), 0.0, 1.0);
  vec2 coverCentered = centered * u_cover_scale;
  vec2 coverRot = clamp(rotate2d(coverCentered, u_rotation) + vec2(0.5), 0.0,
      1.0);
  float dist = length(centered);
  float edge = 1.5 / min(u_resolution.x, u_resolution.y);
  float discMask = smoothstep(0.5 + edge, 0.5 - edge, dist);

  vec4 base = vec4(u_base_color.rgb, 1.0);
  float coverEdge = 1.5 / min(u_resolution.x, u_resolution.y);
  float coverMask = smoothstep(u_cover_radius + coverEdge,
      u_cover_radius - coverEdge, dist);
  vec4 cover = texture(u_cover, coverRot);
  cover.a *= coverMask;
  vec4 spinning = texture(u_spinning, rotUv);
  vec4 stat = texture(u_static, uv);

  base = mix(base, cover, cover.a);
  base = mix(base, spinning, spinning.a);
  base = mix(base, stat, stat.a);

  float gradient = gradientAlpha(clamp((1.0 - uv.x + uv.y) * 0.5, 0.0, 1.0));
  vec4 scratchTex = texture(u_scratches, rotUv);
  vec3 effectRgb = u_effect_color.rgb;
  float effectA = scratchTex.a * gradient * u_effect_color.a;
  base.rgb = mix(base.rgb, effectRgb, effectA);

  // float rim = smoothstep(u_cover_radius, 0.5, dist);
  // base.rgb *= mix(1.0, 0.96, rim);
  base.a *= discMask;
  fragColor = vec4(base.rgb * base.a, base.a);
}
