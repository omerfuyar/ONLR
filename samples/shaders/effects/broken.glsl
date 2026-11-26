// A shader that does not compile: line 4 names a value that it does not declare.
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
  vec4 c = Texel(tex, uv) * color;
  c.r = brightness;
  return c;
}
