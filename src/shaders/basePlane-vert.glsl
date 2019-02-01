#version 300 es

// varying vec2 vUv;  

uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
                            // but in HW3 you'll have to generate one yourself
uniform int u_Time;
uniform int u_Daylight;
uniform float u_Flowspeed;

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;

out float fs_Sine;
out vec4 fs_LightVec;  // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader
out vec3 vertexViewPos;

flat out int fs_Time;
flat out int fs_Daylight;
flat out float fs_Flowspeed;


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


// Voronoi Noise (Modified from http://www.iquilezles.org/www/articles/voronoilines/voronoilines.htm)
// Hash function taken from http://www.iquilezles.org/www/articles/voronoise/voronoise.htm

vec3 hash3( vec2 p ) {

    vec3 q = vec3( dot(p,vec2(127.1,311.7)), 
				   				 dot(p,vec2(269.5,183.3)), 
				   				 dot(p,vec2(419.2,371.9)));

	return fract(sin(q) * 43758.5453);
}

float voronoi(float x, float y, vec2 seed){
 
 	vec2 coord = vec2(x, y);
  float r1 = seed.x;
  float r2 = seed.y; 

  vec2 p = floor(coord);
  vec2 rem = fract(coord);
		
	float k = 1.0 + 10.0 * pow(1.0 - r2, 4.0);
	
	float avg_dist = 0.0;
	float tot_weight = 0.0;

	// Check neighbors
  for (float j = -2.0; j <= 2.0 ;  j = j + 1.0 ) {
  	for (float i = -2.0; i <= 2.0 ; i = i + 1.0) {

      vec2 coord = vec2(i, j);
			vec3 rand_coord = hash3(p + coord) * vec3(r1, r1, 1.0);
			vec2 r = coord - rem + rand_coord.xy;
			float dist = dot(r,r);
			float weight = pow(1.0 - smoothstep(0.0, 2.03, sqrt(dist)), k);
			avg_dist += rand_coord.z * weight;
			tot_weight += weight;
    }
  }
  return avg_dist/tot_weight;
}

float max4 (vec4 v) {
  return max(max(max(v.x, v.y), v.z), v.a);
}

void main()
{

  fs_Time = u_Time;
  fs_Daylight = u_Daylight;
  fs_Flowspeed = u_Flowspeed;

  // Introduce Light (taken from HW0)
	vec4 lightPos = vec4(5, 5, 5, 1);
	mat3 invTranspose = mat3(u_ModelInvTr);
  fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          

  // Permute FBM and Voronoi to create trees in places where there arent waterfalls
  vec2 height_seed = vec2(3, 3.53);
	vec2 height = vec2(vs_Pos.x+ u_PlanePos.x, vs_Pos.z + u_PlanePos.y)/11.0;
  float voronoi_height = voronoi(height.x, height.y, height_seed) * 3.0;

  float voronoi_inverse = 0.0;
  if (voronoi_height > 0.0) {
  	voronoi_inverse = 0.0;
  } else {
  	voronoi_inverse = 1.0;
  }

  float fbm_height = fbm(height.x, height.y, height_seed);
  if (fbm_height < 1.57) {
  	fbm_height = 0.0;
  }

	float randomized_height = fbm_height * voronoi_inverse * 15.0;
  vec4 modelposition = vec4(vs_Pos.x, randomized_height , vs_Pos.z, 1.0);
  fs_Pos = modelposition.xyz;

  fs_LightVec = lightPos - modelposition; 
  modelposition = u_Model * modelposition;
  gl_Position = u_ViewProj * modelposition;

}



