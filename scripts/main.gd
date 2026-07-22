extends Node2D

const VIEW_SIZE := Vector2(720, 1280)
const BOARD_RECT := Rect2(36, 116, 648, 628)
const TRAY_RECT := Rect2(36, 766, 648, 156)
const BATTLE_RECT := Rect2(36, 944, 648, 280)
const CARD_SIZE := Vector2(138, 166)
const BASE_LINE_X := 74.0
const BATTLE_GROUND_Y := 222.0

var board: Control
var tray: Control
var battlefield: Control
var card_layer: Control
var tray_cards: Array[String] = []
var tray_views: Array[Control] = []
var deck_cards: Array[CardView] = []
var battle_units: Array[BattleUnit] = []
var occupied_units := 0
var coin_count := 2480
var coin_label: Label
var status_label: Label
var restart_button: Button
var battle_button: Button
var battle_hint: Label
var battle_active := false
var battle_ended := false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_build_background()
	_build_top_bar()
	_build_board()
	_build_tray()
	_build_battlefield()
	_build_overlay()
	_start_round()

func _process(delta: float) -> void:
	if not battle_active or battle_ended:
		return
	_step_battle(delta)

func _build_background() -> void:
	var background := ColorRect.new()
	background.size = VIEW_SIZE
	background.color = Color("#5c3826")
	add_child(background)
	var wash := ColorRect.new()
	wash.position = Vector2(14, 14)
	wash.size = Vector2(692, 1252)
	wash.color = Color("#d69a60")
	add_child(wash)

func _panel_style(color: Color, border := Color("#70412c"), radius := 20, width := 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.16, 0.08, 0.04, 0.28)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 4)
	return style

func _label(parent: Node, text: String, position: Vector2, size: Vector2, font_size: int, color := Color("#fff0c7")) -> Label:
	var label := Label.new()
	label.position = position
	label.size = size
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _build_top_bar() -> void:
	var bar := Panel.new()
	bar.position = Vector2(30, 30)
	bar.size = Vector2(660, 70)
	bar.add_theme_stylebox_override("panel", _panel_style(Color("#a75d38"), Color("#633822"), 19, 3))
	add_child(bar)
	_label(bar, "🪨 牌桌远征", Vector2(18, 7), Vector2(240, 32), 22)
	_label(bar, "石器时代 · 备战", Vector2(20, 39), Vector2(220, 20), 12, Color("#f6d69f"))
	var coin := Panel.new()
	coin.position = Vector2(350, 12)
	coin.size = Vector2(120, 46)
	coin.add_theme_stylebox_override("panel", _panel_style(Color("#f5d18b"), Color("#93603c"), 12, 2))
	bar.add_child(coin)
	coin_label = _label(coin, "💰  2,480", Vector2(13, 8), Vector2(105, 30), 17, Color("#5f3927"))
	var level := Panel.new()
	level.position = Vector2(485, 12)
	level.size = Vector2(92, 46)
	level.add_theme_stylebox_override("panel", _panel_style(Color("#f5d18b"), Color("#93603c"), 12, 2))
	bar.add_child(level)
	_label(level, "关卡 1-1", Vector2(8, 8), Vector2(80, 30), 15, Color("#5f3927"))

func _build_board() -> void:
	board = Panel.new()
	board.position = BOARD_RECT.position
	board.size = BOARD_RECT.size
	board.add_theme_stylebox_override("panel", _panel_style(Color("#c58a53"), Color("#70412c"), 24, 3))
	add_child(board)
	var bg := TextureRect.new()
	bg.position = Vector2(8, 8)
	bg.size = BOARD_RECT.size - Vector2(16, 16)
	bg.texture = load("res://assets/bg_board.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(bg)
	_label(board, "🃏 牌堆", Vector2(20, 14), Vector2(150, 32), 21)
	_label(board, "点击没有被压住的卡牌", Vector2(22, 48), Vector2(230, 23), 12, Color("#6e452f"))
	card_layer = Control.new()
	card_layer.position = Vector2(26, 80)
	card_layer.size = Vector2(596, 526)
	card_layer.clip_contents = false
	card_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	card_layer.gui_input.connect(_on_card_layer_input)
	board.add_child(card_layer)

func _build_tray() -> void:
	tray = Panel.new()
	tray.position = TRAY_RECT.position
	tray.size = TRAY_RECT.size
	tray.add_theme_stylebox_override("panel", _panel_style(Color("#e7bd76"), Color("#70412c"), 20, 3))
	add_child(tray)
	_label(tray, "✨ 合成台", Vector2(18, 9), Vector2(150, 28), 19)
	_label(tray, "3 张同名卡 → 1 个部落棋子", Vector2(168, 13), Vector2(280, 22), 12, Color("#765035"))
	for index in range(7):
		var slot := Panel.new()
		slot.name = "Slot%d" % index
		slot.position = Vector2(16 + index * 89, 48)
		slot.size = Vector2(80, 88)
		var style := _panel_style(Color("#aa7044", 0.25), Color("#a66e43"), 12, 2)
		style.set_border_width_all(2)
		slot.add_theme_stylebox_override("panel", style)
		tray.add_child(slot)

func _build_battlefield() -> void:
	battlefield = Panel.new()
	battlefield.position = BATTLE_RECT.position
	battlefield.size = BATTLE_RECT.size
	battlefield.add_theme_stylebox_override("panel", _panel_style(Color("#8d5d3f"), Color("#70412c"), 22, 3))
	add_child(battlefield)
	var bg := TextureRect.new()
	bg.position = Vector2(7, 7)
	bg.size = BATTLE_RECT.size - Vector2(14, 14)
	bg.texture = load("res://assets/bg_battle.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battlefield.add_child(bg)
	_label(battlefield, "🛖 部落阵地", Vector2(18, 12), Vector2(210, 28), 18)
	battle_hint = _label(battlefield, "敌人会从右侧来袭", Vector2(310, 15), Vector2(190, 22), 12, Color("#f9deb0"))
	battle_button = Button.new()
	battle_button.position = Vector2(514, 12)
	battle_button.size = Vector2(112, 45)
	battle_button.text = "⚔ 开战"
	battle_button.add_theme_font_size_override("font_size", 17)
	battle_button.add_theme_stylebox_override("normal", _panel_style(Color("#e4863e"), Color("#713722"), 14, 3))
	battle_button.add_theme_stylebox_override("hover", _panel_style(Color("#f2a252"), Color("#713722"), 14, 3))
	battle_button.pressed.connect(_start_battle)
	battlefield.add_child(battle_button)
	var base_line := ColorRect.new()
	base_line.position = Vector2(74, 64)
	base_line.size = Vector2(3, 132)
	base_line.color = Color("#f3ca74", 0.72)
	base_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battlefield.add_child(base_line)
	_label(battlefield, "基地线", Vector2(32, 196), Vector2(80, 22), 11, Color("#ffe8b0"))
	_label(battlefield, "己方部落", Vector2(26, 245), Vector2(110, 22), 12, Color("#fff0c7"))
	_label(battlefield, "敌人来袭", Vector2(515, 245), Vector2(110, 22), 12, Color("#ffd5a7"))

func _build_overlay() -> void:
	status_label = _label(self, "", Vector2(75, 365), Vector2(570, 64), 22, Color("#fff2c4"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.visible = false
	restart_button = Button.new()
	restart_button.position = Vector2(275, 430)
	restart_button.size = Vector2(170, 52)
	restart_button.text = "重新开始"
	restart_button.add_theme_font_size_override("font_size", 19)
	restart_button.add_theme_stylebox_override("normal", _panel_style(Color("#d77a3d"), Color("#6d3724"), 15, 3))
	restart_button.add_theme_stylebox_override("hover", _panel_style(Color("#ec994d"), Color("#6d3724"), 15, 3))
	restart_button.pressed.connect(_start_round)
	restart_button.visible = false
	add_child(restart_button)

func _start_round() -> void:
	for card in deck_cards:
		if is_instance_valid(card):
			card.queue_free()
	deck_cards.clear()
	for view in tray_views:
		if is_instance_valid(view):
			view.queue_free()
	tray_views.clear()
	tray_cards.clear()
	occupied_units = 0
	battle_active = false
	battle_ended = false
	battle_button.disabled = false
	battle_button.text = "⚔ 开战"
	battle_hint.text = "敌人会从右侧来袭"
	status_label.visible = false
	restart_button.visible = false
	_remove_battle_units()
	var deck: Array[String] = []
	for id in GameData.STARTER_TYPES:
		for _count in range(3):
			deck.append(id)
	deck.shuffle()
	for index in range(deck.size()):
		_spawn_card(deck[index], index)
	_refresh_covered()

func _spawn_card(id: String, index: int) -> void:
	var card := CardView.new()
	card.setup(id, load("res://assets/cards/%s.png" % id), GameData.CARDS[id].color)
	card.position = _pile_position(index)
	card.rotation = rng.randf_range(-0.30, 0.30)
	card.z_index = index
	card.clicked.connect(_on_card_clicked)
	card_layer.add_child(card)
	deck_cards.append(card)

func _pile_position(index: int) -> Vector2:
	var columns := 5
	var column := index % columns
	var row := index / columns
	var x := 8.0 + column * 92.0 + rng.randf_range(-28.0, 28.0)
	var y := 3.0 + row * 86.0 + rng.randf_range(-28.0, 28.0)
	return Vector2(x, y)

func _refresh_covered() -> void:
	for card in deck_cards:
		if not is_instance_valid(card):
			continue
		card.set_locked(not _card_has_exposed_area(card))

func _on_card_layer_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	var canvas_point: Vector2 = card_layer.get_global_transform_with_canvas() * event.position
	var card := _top_card_at(canvas_point)
	if card != null and not card.locked:
		_on_card_clicked(card)
		card_layer.accept_event()

func _top_card_at(canvas_point: Vector2) -> CardView:
	var result: CardView
	var highest_z := -2147483648
	for card in deck_cards:
		if not is_instance_valid(card) or card.claimed:
			continue
		var card_point: Vector2 = card.get_global_transform_with_canvas().affine_inverse() * canvas_point
		if Rect2(Vector2.ZERO, CARD_SIZE).has_point(card_point) and card.z_index > highest_z:
			result = card
			highest_z = card.z_index
	return result

func _card_has_exposed_area(card: CardView) -> bool:
	# Sample the exact transformed rectangle with the same hit test used by clicks.
	# A 3px grid catches the visible edge slivers created by rotated cards.
	for y in range(1, int(CARD_SIZE.y), 3):
		for x in range(1, int(CARD_SIZE.x), 3):
			var local_point := Vector2(x, y)
			var canvas_point: Vector2 = card.get_global_transform_with_canvas() * local_point
			if _top_card_at(canvas_point) == card:
				return true
	return false

func _on_card_clicked(card: CardView) -> void:
	if card.locked or card.claimed:
		return
	card.claimed = true
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_cards.erase(card)
	_refresh_covered()
	var target_index := _first_open_slot()
	if target_index < 0:
		return
	var target := _slot_position(target_index)
	var selected_id := card.card_id
	card.reparent(self)
	card.z_index = 30
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(card, "global_position", target - CARD_SIZE / 2.0, 0.36)
	tween.parallel().tween_property(card, "rotation", 0.0, 0.36)
	tween.tween_callback(func() -> void:
		if is_instance_valid(card):
			card.queue_free()
		_add_to_tray(selected_id)
	)

func _first_open_slot() -> int:
	return tray_cards.size() if tray_cards.size() < 7 else -1

func _slot_position(index: int) -> Vector2:
	return tray.global_position + Vector2(16 + index * 89 + 40, 48 + 44)

func _add_to_tray(id: String) -> void:
	tray_cards.append(id)
	tray_cards.sort_custom(func(a: String, b: String) -> bool:
		return GameData.STARTER_TYPES.find(a) < GameData.STARTER_TYPES.find(b)
	)
	_rebuild_tray_visuals()
	_check_merges()
	if deck_cards.is_empty() and tray_cards.is_empty() and not battle_active:
		battle_hint.text = "牌堆清空！布阵完成，点击开战"
	elif tray_cards.size() == 7 and not _has_triple():
		_finish_round("卡住了！合成台已满")

func _rebuild_tray_visuals() -> void:
	for view in tray_views:
		if is_instance_valid(view):
			view.queue_free()
	tray_views.clear()
	for index in range(tray_cards.size()):
		var id: String = tray_cards[index]
		var icon := TextureRect.new()
		icon.position = Vector2(20 + index * 89, 52)
		icon.size = Vector2(72, 64)
		icon.texture = load("res://assets/cards/%s.png" % id)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tray.add_child(icon)
		tray_views.append(icon)

func _check_merges() -> void:
	for id in GameData.CARDS:
		var count := tray_cards.count(id)
		if count >= 3:
			for _count in range(3):
				tray_cards.erase(id)
			print("合成成功: 3 x %s -> %s" % [GameData.CARDS[id].name, GameData.CARDS[id].unit])
			_rebuild_tray_visuals()
			_spawn_ally(GameData.CARDS[id].unit)
			_check_merges()
			return

func _has_triple() -> bool:
	for id in GameData.CARDS:
		if tray_cards.count(id) >= 3:
			return true
	return false

func _spawn_ally(unit_id: String) -> void:
	var unit := BattleUnit.new()
	unit.setup(unit_id, "ally", GameData.ALLIES[unit_id], load("res://assets/units/%s.png" % unit_id))
	unit.position = Vector2(126 + (occupied_units % 3) * 68, BATTLE_GROUND_Y - (occupied_units / 3) * 12)
	unit.z_index = 4
	battlefield.add_child(unit)
	battle_units.append(unit)
	occupied_units += 1

func _start_battle() -> void:
	if battle_active or battle_ended:
		return
	var ally_count := _living_units("ally").size()
	if ally_count == 0:
		_finish_round("先合成至少一个部落棋子")
		return
	battle_active = true
	battle_ended = false
	battle_button.disabled = true
	battle_button.text = "战斗中"
	battle_hint.text = "自动战斗进行中…"
	var enemy_ids := ["sabertooth", "raptor", "boar", "enemy_caveman"]
	print("战斗开始: 己方 %d, 敌方 %d" % [ally_count, enemy_ids.size()])
	for index in range(enemy_ids.size()):
		_spawn_enemy(enemy_ids[index], index)

func _spawn_enemy(unit_id: String, index: int) -> void:
	var unit := BattleUnit.new()
	unit.setup(unit_id, "enemy", GameData.ENEMIES[unit_id], load("res://assets/enemies/%s.png" % unit_id))
	unit.position = Vector2(585 + (index % 2) * 20, BATTLE_GROUND_Y - (index / 2) * 18)
	unit.z_index = 4
	battlefield.add_child(unit)
	battle_units.append(unit)

func _step_battle(delta: float) -> void:
	for unit in battle_units:
		if not is_instance_valid(unit) or not unit.alive:
			continue
		unit.attack_cooldown = max(0.0, unit.attack_cooldown - delta)
		var target := _find_target(unit)
		if target == null:
			continue
		var distance: float = absf(target.position.x - unit.position.x)
		var attack_range := float(unit.stats.range)
		if distance > attack_range:
			var direction := 1.0 if unit.faction == "ally" else -1.0
			unit.position.x += direction * float(unit.stats.move_speed) * delta
		elif unit.attack_cooldown <= 0.0:
			_attack(unit, target)
	if _living_units("enemy").any(func(enemy: BattleUnit) -> bool: return enemy.position.x <= BASE_LINE_X):
		_finish_battle(false, "失败！敌人突破了基地线")
	elif _living_units("enemy").is_empty():
		_finish_battle(true, "胜利！部落守住了家园")
	elif _living_units("ally").is_empty():
		_finish_battle(false, "失败！部落棋子全部倒下")

func _find_target(unit: BattleUnit) -> BattleUnit:
	var candidates: Array[BattleUnit] = []
	if unit.stats.role == "healer" and unit.faction == "ally":
		for ally in _living_units("ally"):
			if ally != unit and ally.hp < ally.max_hp:
				candidates.append(ally)
	else:
		var enemy_faction := "enemy" if unit.faction == "ally" else "ally"
		candidates = _living_units(enemy_faction)
	if candidates.is_empty():
		return null
	var nearest: BattleUnit = candidates[0]
	var nearest_distance: float = absf(nearest.position.x - unit.position.x)
	for candidate in candidates:
		var distance: float = absf(candidate.position.x - unit.position.x)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest

func _attack(attacker: BattleUnit, target: BattleUnit) -> void:
	attacker.spend_attack_time()
	if attacker.stats.role == "healer":
		target.heal(22.0)
		_spawn_hit_fx(target.position, Color("#93e58b"), "✚")
	else:
		target.receive_damage(float(attacker.stats.attack))
		_spawn_hit_fx(target.position, Color("#ffd273"), "✦")

func _spawn_hit_fx(local_position: Vector2, color: Color, text: String) -> void:
	var fx := Label.new()
	fx.position = BATTLE_RECT.position + local_position + Vector2(-14, -130)
	fx.text = text
	fx.add_theme_font_size_override("font_size", 24)
	fx.add_theme_color_override("font_color", color)
	add_child(fx)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fx, "position:y", fx.position.y - 18, 0.3)
	tween.tween_property(fx, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.chain().tween_callback(fx.queue_free)

func _finish_battle(won: bool, message: String) -> void:
	if battle_ended:
		return
	battle_ended = true
	battle_active = false
	print("战斗结束: %s" % message.replace("\n", " "))
	if won:
		coin_count += 120
		coin_label.text = "💰  %d" % coin_count
		_finish_round("%s\n获得 +120 金币" % message)
	else:
		_finish_round(message)

func _living_units(side: String) -> Array[BattleUnit]:
	var result: Array[BattleUnit] = []
	for unit in battle_units:
		if is_instance_valid(unit) and unit.alive and unit.faction == side:
			result.append(unit)
	return result

func _remove_battle_units() -> void:
	for unit in battle_units:
		if is_instance_valid(unit):
			unit.queue_free()
	battle_units.clear()

func _finish_round(message: String) -> void:
	status_label.text = message
	status_label.visible = true
	restart_button.visible = true
