#version 300 es
precision highp float;

// The fragment shader used to render the background of the scene
// Modify this to make your background more interesting

out vec4 out_Col;
flat in int fs_Daylight;

void main() {

	   // Material base color (before shading)
	vec4 diffuseColor =  vec4(164.0 / 255.0, 233.0 / 255.0, 1.0, 1.0);

	// Calculate the diffuse term for Lambert shading
	// float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));

	float ambientTerm = float(fs_Daylight)/5.0;
	float lightIntensity = ambientTerm; 

  out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
}
