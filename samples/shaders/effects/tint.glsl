// Mixes what is drawn with a colour: amount 0 keeps it, and 1 gives the colour.
extern number amount;
extern vec4 tint;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
  vec4 c = Texel(tex, uv) * color;
  c.rgb = mix(c.rgb, tint.rgb, amount);
  return c;
}
