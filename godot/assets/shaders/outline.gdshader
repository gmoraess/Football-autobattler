shader_type canvas_item;
// Contorno suave em volta da arte (onde há borda de alfa). Destaca as feras do fundo.
uniform vec4 line_color : source_color = vec4(0.04, 0.02, 0.0, 0.55);
uniform float width : hint_range(0.0, 4.0) = 1.5;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 ps = TEXTURE_PIXEL_SIZE * width;
	float o = 0.0;
	o = max(o, texture(TEXTURE, UV + vec2(ps.x, 0.0)).a);
	o = max(o, texture(TEXTURE, UV + vec2(-ps.x, 0.0)).a);
	o = max(o, texture(TEXTURE, UV + vec2(0.0, ps.y)).a);
	o = max(o, texture(TEXTURE, UV + vec2(0.0, -ps.y)).a);
	o = max(o, texture(TEXTURE, UV + vec2(ps.x, ps.y)).a);
	o = max(o, texture(TEXTURE, UV + vec2(-ps.x, ps.y)).a);
	o = max(o, texture(TEXTURE, UV + vec2(ps.x, -ps.y)).a);
	o = max(o, texture(TEXTURE, UV + vec2(-ps.x, -ps.y)).a);
	float edge = clamp(o - c.a, 0.0, 1.0);
	vec3 rgb = mix(line_color.rgb, c.rgb, c.a);
	float alpha = max(c.a, edge * line_color.a);
	COLOR = vec4(rgb, alpha);
}
