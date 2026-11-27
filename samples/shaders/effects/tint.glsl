// Mixes what is drawn with a colour: amount 0 keeps it, and 1 gives the colour. The notes give the inspector a slider and a
// colour, and the values that a node that sets none starts with (DESIGN 6.7).
extern number amount; // 0 to 1, default 0.5: how much of the colour
extern vec4 tint;     // color, default 0 0 1 1

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
  vec4 c = Texel(tex, uv) * color;
  c.rgb = mix(c.rgb, tint.rgb, amount);
  return c;
}
