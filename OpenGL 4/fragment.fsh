#version 330

in vec3 positionEye, normalEye;
//in vec2 texcoords;
out vec4 frag_color;


vec3 light_position_world  = vec3 (0.0, 0.0, 0.0);
vec3 Ls = vec3 (0.0, 0.0, 1.0); // white specular colour
vec3 Ld = vec3 (0.7, 0.7, 0.7); // dull white diffuse light colour
vec3 La = vec3 (0.2, 0.2, 0.2); // grey ambient colour

// surface reflectance
vec3 Ks = vec3 (0.0, 1.0, 1.0); // fully reflect specular light
vec3 Kd = vec3 (1.0, 1, 1); // pink diffuse surface reflectance
vec3 Ka = vec3 (1.0, 1.0, 1.0); // fully reflect ambient light
float specular_exponent = 100.0; // specular 'power'


//Uniforms
uniform mat4 viewMatrix;

uniform sampler2D basicTexture;

void main()
{
 ///*
    //Kd = texture2D(basicTexture, texcoords).rgb;
    
    // ambient intensity
	vec3 Ia = La * Ka;
    
	// diffuse intensity
    // raise light position to eye space
    vec3 light_position_eye = vec3 (viewMatrix * vec4 (light_position_world, 1.0));
    vec3 distance_to_light_eye = light_position_eye - positionEye;
    vec3 direction_to_light_eye = normalize (distance_to_light_eye);
    float dot_prod = dot (direction_to_light_eye, normalEye);
    dot_prod = max (dot_prod, 0.0);
    vec3 Id = Ld * Kd * dot_prod; // final diffuse intensity
	
	// specular intensity
    vec3 reflection_eye = reflect (-direction_to_light_eye, normalEye);
    vec3 surface_to_viewer_eye = normalize (-positionEye);
    float dot_prod_specular = dot (reflection_eye, surface_to_viewer_eye);
    dot_prod_specular = max (dot_prod_specular, 0.0);
    float specular_factor = pow (dot_prod_specular, specular_exponent);
    vec3 Is = Ls * Ks * specular_factor; // final specular intensity
	
	// final colour
	frag_color = vec4 (Is + Id + Ia, 1.0);
  
  //*/
   // frag_color = vec4(Kd, 1);
}