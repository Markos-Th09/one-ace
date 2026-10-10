shader_type canvas_item;

uniform float Climb_Amount :hint_range(0.0, 1.0, 0.1) = 0;
uniform float Hit_Amount :hint_range(0.0, 1.0, 0.1) = 0;

uniform vec4 Climbtint : source_color = vec4(1., 1., 0., 1);
uniform vec4 HitTint : source_color = vec4(1., 1., 0., 1);

void fragment() {
	
	vec4 tint_copy = Climbtint;
	vec4 Hit_tint_copy = HitTint;
	
	vec4 previous_color = texture(TEXTURE, UV);

	tint_copy.a = previous_color.a;
	Hit_tint_copy.a = previous_color.a;
	
	previous_color.a = previous_color.a-Climb_Amount;
	tint_copy = tint_copy*Climb_Amount;
	Hit_tint_copy = Hit_tint_copy*Hit_Amount;

	vec4 Total = tint_copy+previous_color+Hit_tint_copy;
	COLOR = Total;

}
