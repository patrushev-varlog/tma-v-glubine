shader_type canvas_item;
// Замена трёх тонов кожи на другую рампу той же палитры (Resurrect 64): так стадии Тьмы
// бледнеют без новых картинок и без цветов вне палитры. Ключи — цвета базового портрета.

uniform vec3 key_hi : source_color = vec3(0.992, 0.796, 0.690);  // #fdcbb0
uniform vec3 key_mid : source_color = vec3(0.988, 0.655, 0.565); // #fca790
uniform vec3 key_sh : source_color = vec3(0.804, 0.408, 0.239);  // #cd683d
uniform vec3 to_hi : source_color = vec3(0.992, 0.796, 0.690);
uniform vec3 to_mid : source_color = vec3(0.988, 0.655, 0.565);
uniform vec3 to_sh : source_color = vec3(0.804, 0.408, 0.239);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	const float EPS = 0.02;
	if (distance(c.rgb, key_hi) < EPS) c.rgb = to_hi;
	else if (distance(c.rgb, key_mid) < EPS) c.rgb = to_mid;
	else if (distance(c.rgb, key_sh) < EPS) c.rgb = to_sh;
	COLOR = c;
}
