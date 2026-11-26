// Takes the colour out of what is drawn: amount 0 keeps it, and 1 leaves it gray.
extern number amount;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
  vec4 c = Texel(tex, uv) * color;
  float gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));
  c.rgb = mix(c.rgb, vec3(gray), amount);
  return c;
}
