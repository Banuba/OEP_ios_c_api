#version 300 es

precision lowp float;

in vec4 var_uv;

layout( location = 0 ) out vec4 F;

uniform sampler2D glfx_BLUR_BACKGROUND;
uniform sampler2D glfx_BACKGROUND;
uniform sampler2D glfx_BG_MASK;

void main()
{
	vec3 blurred = texture(glfx_BLUR_BACKGROUND,var_uv.xy).xyz;
	vec3 bg = texture(glfx_BACKGROUND,var_uv.xy).xyz;

	float mask = texture(glfx_BG_MASK,var_uv.zw).x;

	F = vec4(mix(bg,blurred,mask),1.);
}
