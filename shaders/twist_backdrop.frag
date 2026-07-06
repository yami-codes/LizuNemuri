#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

// uSize.xy, uTime
uniform vec2 uSize;
uniform float uTime;
uniform sampler2D uTexture;

out vec4 fragColor;

const float PI = 3.14159265;

vec2 twist(vec2 coord, vec2 offset, float radius, float maxAngle) {
  coord -= offset;
  float dist = length(coord);
  if (dist < radius) {
    float ratioDist = (radius - dist) / radius;
    float angleMod = ratioDist * ratioDist * maxAngle;
    float s = sin(angleMod);
    float c = cos(angleMod);
    coord = vec2(coord.x * c - coord.y * s, coord.x * s + coord.y * c);
  }
  return coord + offset;
}

vec2 rotate(vec2 p, float angle) {
  float s = sin(angle);
  float c = cos(angle);
  return vec2(p.x * c - p.y * s, p.x * s + p.y * c);
}

vec4 sampleLayer(vec2 uv, float scale, float spin, vec2 orbitAmp, float orbitSpeed, float t) {
  vec2 center = vec2(0.5, 0.5);
  vec2 p = (uv - center) / scale + center;
  p += orbitAmp * vec2(sin(t * orbitSpeed), cos(t * orbitSpeed * 0.87));
  p = rotate(p - center, spin * t) + center;
  p = twist(p, vec2(0.52, 0.48), 0.58, 4.0);
  if (p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0) {
    return vec4(0.0);
  }
  return texture(uTexture, p);
}

vec3 saturate(vec3 color, float amount) {
  float gray = dot(color, vec3(0.299, 0.587, 0.114));
  return mix(vec3(gray), color, amount);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  float t = uTime;

  // Four stacked copies — sizes/motion from decompiled Apple Music web client.
  vec4 l1 = sampleLayer(uv, 0.25, 0.0010, vec2(0.14, 0.10), 0.75, t);
  vec4 l2 = sampleLayer(uv, 0.50, -0.0005, vec2(0.11, 0.08), 0.65, t * 1.05);
  vec4 l3 = sampleLayer(uv, 0.80, 0.0008, vec2(0.0, 0.0), 0.0, t);
  vec4 l4 = sampleLayer(uv, 1.25, -0.0006, vec2(0.0, 0.0), 0.0, t * 0.92);

  vec4 col = (l1 + l2 + l3 + l4) * 0.25;
  col.rgb = saturate(col.rgb, 1.2);
  col.rgb *= 0.62;
  col.rgb = mix(col.rgb, col.rgb * col.rgb, 0.08);

  fragColor = vec4(col.rgb, 1.0);
}
