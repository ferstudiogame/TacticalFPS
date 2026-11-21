from pathlib import Path

player_path = Path("scripts/PlayerController.gd")
player = player_path.read_text(encoding="utf-8")
if "signal damage_taken(amount: float)" not in player:
    player = player.replace(
        "signal health_changed(current_health: float, maximum_health: float)",
        "signal health_changed(current_health: float, maximum_health: float)\nsignal damage_taken(amount: float)"
    )
    player = player.replace(
        "var _base_capsule_height: float = 1.8",
        "var _base_capsule_height: float = 1.8\nvar _spawn_position: Vector3 = Vector3.ZERO\nvar _is_respawning: bool = false"
    )
    player = player.replace(
        "func _ready() -> void:\n",
        "func _ready() -> void:\n\tadd_to_group(\"player\")\n\t_spawn_position = global_position\n"
    )
    player = player.replace(
        "func _physics_process(delta: float) -> void:\n",
        "func _physics_process(delta: float) -> void:\n\tif _is_respawning:\n\t\tvelocity = Vector3.ZERO\n\t\tweapon.set_fire_pressed(false)\n\t\treturn\n"
    )
    player += """
\n
func take_damage(amount: float) -> void:
	if _is_respawning or amount <= 0.0:
		return
	_health = maxf(_health - amount, 0.0)
	health_changed.emit(_health, 100.0)
	damage_taken.emit(amount)
	if _health <= 0.0:
		_is_respawning = true
		_touch_move = Vector2.ZERO
		_touch_fire = false
		_touch_aim = false
		weapon.set_fire_pressed(false)
		await get_tree().create_timer(2.2).timeout
		if not is_inside_tree():
			return
		global_position = _spawn_position
		velocity = Vector3.ZERO
		_health = 100.0
		_is_respawning = false
		health_changed.emit(_health, 100.0)
"""
    if "signal damage_taken(amount: float)" not in player or "func take_damage(amount: float)" not in player:
        raise RuntimeError("Player health extension did not apply cleanly")
    player_path.write_text(player, encoding="utf-8")

hud_path = Path("scripts/TouchHUD.gd")
hud = hud_path.read_text(encoding="utf-8")
if "func add_kill(headshot: bool = false)" not in hud:
    hud = hud.replace(
        "var _ads_active: bool = false",
        "var _ads_active: bool = false\nvar _kill_label: Label\nvar _damage_overlay: ColorRect\nvar _kills: int = 0"
    )
    hud = hud.replace(
        "\t_root.mouse_filter = Control.MOUSE_FILTER_PASS\n\tadd_child(_root)",
        "\t_root.mouse_filter = Control.MOUSE_FILTER_PASS\n\tadd_child(_root)\n\t_damage_overlay = ColorRect.new()\n\t_damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)\n\t_damage_overlay.color = Color(0.72, 0.04, 0.025, 0.0)\n\t_damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE\n\t_damage_overlay.z_index = 20\n\t_root.add_child(_damage_overlay)"
    )
    hud = hud.replace(
        '"N   035°   FIRING RANGE"',
        '"PORT AUTHORITY  //  SECTOR 07"'
    ).replace(
        '"RANGE\\n▦  ▪  ▦\\n  ▪  YOU"',
        '"WAREHOUSE\\nCONTROL ZONE\\nHOSTILES ACTIVE"'
    )
    hud = hud.replace(
        '\t_fps_label = _make_label("FPS  --", 16, Color(0.45, 0.92, 0.58))',
        '\t_kill_label = _make_label("HOSTILES  00", 18, Color(0.95, 0.68, 0.25))\n\t_kill_label.anchor_left = 0.78\n\t_kill_label.anchor_right = 0.975\n\t_kill_label.anchor_top = 0.035\n\t_kill_label.anchor_bottom = 0.085\n\t_kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT\n\t_root.add_child(_kill_label)\n\t_fps_label = _make_label("FPS  --", 16, Color(0.45, 0.92, 0.58))'
    )
    hud = hud.replace(
        "normal_style.set_corner_radius_all(15)",
        "normal_style.set_corner_radius_all(42)\n\tnormal_style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)\n\tnormal_style.shadow_size = 7"
    )
    hud += """
\n
func add_kill(headshot: bool = false) -> void:
	_kills += 1
	if _kill_label != null:
		_kill_label.text = "HOSTILES  " + str(_kills).pad_zeros(2)
		_kill_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.3) if headshot else Color(0.95, 0.68, 0.25))

func show_damage(amount: float) -> void:
	if _damage_overlay == null:
		return
	var intensity := clampf(0.18 + amount * 0.012, 0.18, 0.38)
	_damage_overlay.color = Color(0.72, 0.035, 0.02, intensity)
	var tween := create_tween()
	tween.tween_property(_damage_overlay, "color", Color(0.72, 0.035, 0.02, 0.0), 0.28)
"""
    if "func add_kill(headshot: bool = false)" not in hud or "func show_damage(amount: float)" not in hud:
        raise RuntimeError("HUD gameplay feedback extension did not apply cleanly")
    hud_path.write_text(hud, encoding="utf-8")

main_path = Path("scripts/Main.gd")
main = """extends Node3D

@onready var player: PlayerController = $Player
@onready var hud: TouchHUD = $TouchHUD
var _kills: int = 0

func _ready() -> void:
	hud.move_changed.connect(player.set_touch_move)
	hud.look_delta.connect(player.add_look_delta)
	hud.fire_changed.connect(player.set_touch_fire)
	hud.aim_changed.connect(player.set_touch_aim)
	hud.jump_pressed.connect(player.request_jump)
	hud.crouch_pressed.connect(player.request_crouch)
	hud.reload_pressed.connect(player.request_reload)
	player.weapon.ammo_changed.connect(hud.update_ammo)
	player.weapon.hit_confirmed.connect(_on_hit_confirmed)
	player.weapon.reload_progress.connect(hud.set_reload_progress)
	player.weapon.ads_state_changed.connect(hud.set_ads_state)
	player.health_changed.connect(hud.set_health)
	player.damage_taken.connect(hud.show_damage)
	hud.update_ammo(player.weapon.get_total_ammo(), player.weapon.get_reserve_ammo())
	hud.set_health(100.0, 100.0)

func _on_hit_confirmed(headshot: bool, killed: bool) -> void:
	if killed:
		_kills += 1
		hud.add_kill(headshot)
"""
main_path.write_text(main, encoding="utf-8")
