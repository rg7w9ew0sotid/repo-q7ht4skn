class_name CardView
extends Control

signal clicked(card: CardView)

var card_id: String
var card_name: String
var locked := true
var claimed := false
var card_texture: TextureRect
var shadow: Panel

func setup(id: String, texture: Texture2D, tint: Color) -> void:
	card_id = id
	card_name = GameData.CARDS[id].name
	size = Vector2(138, 166)
	custom_minimum_size = size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	shadow = Panel.new()
	shadow.position = Vector2(4, 7)
	shadow.size = Vector2(138, 166)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0.16, 0.08, 0.04, 0.32)
	shadow_style.corner_radius_top_left = 18
	shadow_style.corner_radius_top_right = 18
	shadow_style.corner_radius_bottom_left = 18
	shadow_style.corner_radius_bottom_right = 18
	shadow.add_theme_stylebox_override("panel", shadow_style)
	add_child(shadow)

	var frame := Panel.new()
	frame.size = Vector2(138, 166)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color("#f4d29a")
	frame_style.border_color = Color("#784b31")
	frame_style.set_border_width_all(4)
	frame_style.set_corner_radius_all(17)
	frame.add_theme_stylebox_override("panel", frame_style)
	add_child(frame)

	card_texture = TextureRect.new()
	card_texture.position = Vector2(8, 8)
	card_texture.size = Vector2(122, 122)
	card_texture.texture = texture
	card_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_texture)
	if texture == null:
		var placeholder := Panel.new()
		placeholder.position = Vector2(14, 14)
		placeholder.size = Vector2(110, 108)
		var placeholder_style := StyleBoxFlat.new()
		placeholder_style.bg_color = tint
		placeholder_style.border_color = Color("#784b31")
		placeholder_style.set_border_width_all(2)
		placeholder_style.set_corner_radius_all(12)
		placeholder.add_theme_stylebox_override("panel", placeholder_style)
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(placeholder)

	var name_label := Label.new()
	name_label.position = Vector2(5, 130)
	name_label.size = Vector2(128, 28)
	name_label.text = card_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", Color("#573728"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_label)
	modulate = Color(0.62, 0.62, 0.62, 1)

func set_locked(value: bool) -> void:
	locked = value
	modulate = Color(0.58, 0.58, 0.58, 1) if locked else Color.WHITE
	mouse_default_cursor_shape = Control.CURSOR_ARROW

func _gui_input(event: InputEvent) -> void:
	# CardLayer handles hit testing so visual state and input geometry stay identical.
	pass
