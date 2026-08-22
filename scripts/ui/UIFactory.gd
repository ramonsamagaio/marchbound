class_name UIFactory
extends RefCounted

static func panel(bg := Color("#171c2b"), radius := 12, border := Color("#303951")) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = border
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

static func button(text: String, callable: Callable, accent := Color("#28304a")) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, 38)
	b.add_theme_stylebox_override("normal", panel(accent, 8, accent.lightened(0.15)))
	b.add_theme_stylebox_override("hover", panel(accent.lightened(0.08), 8, accent.lightened(0.25)))
	b.add_theme_stylebox_override("pressed", panel(accent.darkened(0.08), 8, accent.lightened(0.12)))
	if callable.is_valid():
		b.pressed.connect(callable)
	return b

static func label(text: String, size := 16, color := Color("#dce5ff")) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func title(text: String, size := 26) -> Label:
	var l = label(text, size, Color("#f6e7ba"))
	l.add_theme_color_override("font_shadow_color", Color(0,0,0,0.6))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

static func hsep() -> HSeparator:
	var s = HSeparator.new()
	s.modulate = Color("#4a5574")
	return s

static func spacer() -> Control:
	var c = Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c

static func cost_text(cost: Dictionary) -> String:
	var parts = []
	for key in GameState.RESOURCE_ORDER:
		if cost.has(key):
			parts.append("%s %d" % [key.capitalize(), int(cost[key])])
	return " · ".join(parts)

static func clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
