#version 300 es
precision highp float;

// The vertex shader used to render the background of the scene
uniform int u_Daylight;

in vec4 vs_Pos;

flat out int fs_Daylight;

void main() {

	fs_Daylight = u_Daylight;
  gl_Position = vs_Pos;
}
