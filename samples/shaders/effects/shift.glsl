// Moves the picture to the right by shift pixels, as a ripple moves what it covers.
extern number shift;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
  return Texel(tex, uv - vec2(shift / love_ScreenSize.x, 0.0)) * color;
}
