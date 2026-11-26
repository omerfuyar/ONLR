// Draws with the colour of an image of the project, which the node file names.
extern Image pattern;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
  return Texel(pattern, vec2(0.5, 0.5));
}
