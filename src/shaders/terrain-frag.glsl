#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
// uniform sampler2D tExplosion;

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;

in float fs_Sine;
in vec4 fs_LightVec;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

flat in int fs_Time;
flat in int fs_Daylight;
flat in float fs_Flowspeed;


float random1( vec2 p , vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}


// Fractal Brownian Motion (referenced lecture code)
float interpNoise2D( float x, float y, vec2 seed) {

	float intX = floor(x);
	float fractX = fract(x);
	float intY = floor(y);
	float fractY = fract(y);

	float v1 = random1(vec2(intX, intY), seed);
	float v2 = random1(vec2(intX + 1.0, intY), seed);
	float v3 = random1(vec2(intX, intY + 1.0), seed);
	float v4 = random1(vec2(intX + 1.0, intY + 1.0), seed);

	float i1 = mix(v1, v2, fractX);
	float i2 = mix(v3, v4, fractY);
	return mix(i1, i2, fractY);

}

float fbm( float x, float y, vec2 seed) {

	float total = 0.0;
	float persistance = 0.5;
	float octaves = 8.0;

	for (float i = 0.0; i < octaves; i = i + 1.0) {
		float freq = pow(2.0, i);
		float amp = pow(persistance, i);
		total += interpNoise2D(x * freq, y * freq, seed) * amp;
	}
	return total;
}

void main()
{

	vec4 WATERFALL_BLUE = vec4(0.0/255.0, 191.0/255.0, 1.0 , 1.0);
	vec4 SWAMP_GREEN = vec4(1.0/255.0, 233.0/255.0, 160.0/255.0, 166.0/255.0);

  // Calculate the diffuse term for Lambert shading
  float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));

  // Control ambiance using user input
	float ambientTerm = float(fs_Daylight)/10.0;
	float lightIntensity = diffuseTerm + ambientTerm;  

	// Material base color (before shading)
	vec2 color_seed = vec2(0.4, 1.0);
	float randomizedFactor = fbm(fs_Pos.x, fs_Pos.z + float(fs_Time) * fs_Flowspeed/150.0, color_seed);
	vec4 terrain_Col =  randomizedFactor * WATERFALL_BLUE;

	// Compute Distance Fog
	float fog = clamp(smoothstep(50.0, 60.0, length(fs_Pos)), 0.0, 1.0); 

  // Compute final shaded color
  out_Col = vec4(mix(vec3(terrain_Col.rgb * lightIntensity), vec3(164.0 / 255.0, 233.0 / 255.0, 1.0), fog), terrain_Col.a);

}
