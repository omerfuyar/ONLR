// Draws in a red as bright as the part of a second that the game has run, from the engine's time.
extern number time;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
  return vec4(fract(time), 0.0, 0.0, 1.0);
}
