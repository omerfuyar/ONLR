// Fades what is drawn toward a colour. Its line "float one = 1;" is GLSL that a computer takes and a phone's GLSL ES does
// not, so the editor warns of it (DESIGN 6.7).
extern number amount; // 0 to 1, default 0.5: how much of the colour
extern vec4 tint;     // color

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
  float one = 1;
  vec4 c = Texel(tex, uv) * color;
  c.rgb = mix(c.rgb, tint.rgb, amount * one);
  return c;
}
