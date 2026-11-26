// Flashes what is drawn toward a colour and back, by the engine's time: as a hit's flash does.
extern number time;
extern number speed;
extern vec4 tint;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
  vec4 c = Texel(tex, uv) * color;
  c.rgb = mix(c.rgb, tint.rgb, 0.5 + 0.5 * sin(time * speed));
  return c;
}
