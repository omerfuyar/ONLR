// Bends the picture in waves that move with the engine's time: each row of pixels moves sideways by its own amount.
extern number time;
extern number height;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
  float shift = sin(screen.y / 12.0 + time * 4.0) * height;
  return Texel(tex, uv + vec2(shift / love_ScreenSize.x, 0.0)) * color;
}
