// Flashes what is drawn toward a colour and back, by the engine's time: as a hit's flash does.
extern number time;
extern number speed; // 0 to 20, default 6: how fast it flashes
extern vec4 tint;    // color, default 1 1 1 1: the colour that it flashes to

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
  vec4 c = Texel(tex, uv) * color;
  c.rgb = mix(c.rgb, tint.rgb, 0.5 + 0.5 * sin(time * speed));
  return c;
}
