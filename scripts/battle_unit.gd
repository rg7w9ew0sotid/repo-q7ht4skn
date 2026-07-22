class_name BattleUnit
extends Node2D

signal expired(unit: BattleUnit)

var unit_id := ""
var faction := ""
var stats: Dictionary = {}
var max_hp := 1.0
var hp := 1.0
var attack_cooldown := 0.0
var alive := true
var sprite: Sprite2D
var flash_time := 0.0

func setup(id: String, side: String, data: Dictionary, texture: Texture2D) -> void:
	unit_id = id
	faction = side
	stats = data
	max_hp = float(data.hp)
	hp = max_hp
	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.flip_h = side == "enemy"
	var desired_height := 104.0 if side == "ally" else 92.0
	var factor: float = desired_height / maxf(1.0, float(texture.get_height()))
	sprite.scale = Vector2(factor, factor)
	sprite.position.y = -desired_height * 0.5
	add_child(sprite)
	queue_redraw()

func _process(delta: float) -> void:
	if flash_time > 0.0:
		flash_time -= delta
		sprite.modulate = Color(1.0, 0.7, 0.5) if flash_time > 0.0 else Color.WHITE

func receive_damage(amount: float) -> void:
	if not alive:
		return
	hp = max(0.0, hp - amount)
	flash_time = 0.12
	queue_redraw()
	if hp <= 0.0:
		alive = false
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.38)
		tween.tween_property(self, "scale", Vector2(0.7, 0.7), 0.38)
		tween.chain().tween_callback(func() -> void: expired.emit(self))

func heal(amount: float) -> void:
	if not alive:
		return
	hp = min(max_hp, hp + amount)
	queue_redraw()

func spend_attack_time() -> void:
	attack_cooldown = 1.0 / max(0.1, float(stats.attack_speed))

func _draw() -> void:
	var bar_width := 72.0
	var bar_y := -122.0 if faction == "ally" else -111.0
	draw_rect(Rect2(-bar_width * 0.5, bar_y, bar_width, 8), Color("#43251d", 0.9), true)
	var ratio := hp / max_hp
	var bar_color := Color("#7fd65e") if faction == "ally" else Color("#ef6a4f")
	draw_rect(Rect2(-bar_width * 0.5 + 2, bar_y + 2, (bar_width - 4) * ratio, 4), bar_color, true)
	draw_line(Vector2(-bar_width * 0.5, bar_y + 9), Vector2(bar_width * 0.5, bar_y + 9), Color("#f7dfac", 0.7), 1.0)
