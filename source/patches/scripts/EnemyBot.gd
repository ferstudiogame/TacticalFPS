extends CharacterBody3D
class_name EnemyBot

@export var max_health: float = 100.0
@export var patrol_speed: float = 1.35
@export var combat_speed: float = 3.4
@export var detection_range: float = 28.0
@export var attack_range: float = 23.0
@export var respawn_delay: float = 4.0

var current_health: float = 100.0
var _alive := true
var _patrol_direction := 1.0
var _patrol_origin_x := 0.0
var _patrol_origin_z := 0.0
var _fire_cooldown := 1.0
var _strafe_phase := 0.0
var _motion_phase := 0.0
var _health_display_left := 0.0
var _target: PlayerController
var _head_area: Area3D
var _torso_area: Area3D
var _health_bar_fill: MeshInstance3D
var _health_bar_root: Node3D
var _health_label: Label3D
var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _weapon_visual: MeshInstance3D
var _muzzle_flash: MeshInstance3D

func _ready() -> void:
	current_health = max_health
	_patrol_origin_x = position.x
	_patrol_origin_z = position.z
	collision_layer = 0
	collision_mask = 1
	floor_snap_length = 0.25
	var body_collision := CollisionShape3D.new()
	var body_shape := CapsuleShape3D.new()
	body_shape.radius = 0.30
	body_shape.height = 1.78
	body_collision.shape = body_shape
	body_collision.position.y = 0.89
	add_child(body_collision)
	_build_visuals()
	_build_hitboxes()

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	_health_display_left = maxf(_health_display_left - delta, 0.0)
	if _health_bar_root != null:
		_health_bar_root.visible = _health_display_left > 0.0
	if not is_instance_valid(_target):
		var candidate := get_tree().get_first_node_in_group("player")
		if candidate is PlayerController:
			_target = candidate as PlayerController

	var desired := Vector3.ZERO
	var moving_amount := 0.0
	var target_visible := false
	var distance_to_target := 999.0
	if is_instance_valid(_target):
		var offset := _target.global_position - global_position
		offset.y = 0.0
		distance_to_target = offset.length()
		if distance_to_target <= detection_range:
			target_visible = _has_line_of_sight()
		if target_visible:
			_strafe_phase += delta
			var toward := offset.normalized()
			var side := Vector3(-toward.z, 0.0, toward.x)
			if distance_to_target > 10.0:
				desired = toward
			elif distance_to_target < 6.0:
				desired = -toward + side * sin(_strafe_phase * 1.7) * 0.35
			else:
				desired = side * sin(_strafe_phase * 1.35)
			if distance_to_target <= attack_range and _fire_cooldown <= 0.0:
				_fire_at_player()
				_fire_cooldown = randf_range(0.9, 1.35)
			var look_target := Vector3(_target.global_position.x, global_position.y, _target.global_position.z)
			if global_position.distance_squared_to(look_target) > 0.01:
				var wanted_yaw := atan2(-(look_target.x - global_position.x), -(look_target.z - global_position.z))
				rotation.y = lerp_angle(rotation.y, wanted_yaw, clampf(delta * 5.0, 0.0, 1.0))
			moving_amount = desired.length()
		else:
			desired = _patrol_step()
			moving_amount = desired.length()
	else:
		desired = _patrol_step()
		moving_amount = desired.length()

	if is_on_floor():
		velocity.y = -0.35
	else:
		velocity.y -= 9.8 * delta
	var speed := combat_speed if target_visible else patrol_speed
	velocity.x = move_toward(velocity.x, desired.x * speed, delta * 7.0)
	velocity.z = move_toward(velocity.z, desired.z * speed, delta * 7.0)
	move_and_slide()
	_animate_swat(delta, moving_amount)

func _patrol_step() -> Vector3:
	var offset_x := position.x - _patrol_origin_x
	if offset_x > 3.5:
		_patrol_direction = -1.0
	elif offset_x < -3.5:
		_patrol_direction = 1.0
	return Vector3(_patrol_direction, 0.0, 0.0)

func _has_line_of_sight() -> bool:
	if not is_instance_valid(_target):
		return false
	var from := global_position + Vector3.UP * 1.45
	var to := _target.global_position + Vector3.UP * 1.15
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.get("collider") == _target

func _fire_at_player() -> void:
	if not is_instance_valid(_target):
		return
	var start := global_position + Vector3.UP * 1.34 + (-global_transform.basis.z * 0.42)
	var finish := _target.global_position + Vector3.UP * 1.12
	var tracer := BulletTracer.new()
	get_tree().current_scene.add_child(tracer)
	tracer.configure(start, finish)
	_muzzle_flash.visible = true
	_muzzle_flash.scale = Vector3.ONE * randf_range(0.7, 1.2)
	var flash_tween := create_tween()
	flash_tween.tween_interval(0.055)
	flash_tween.tween_callback(func() -> void:
		if is_instance_valid(_muzzle_flash):
			_muzzle_flash.visible = false
	)
	_target.take_damage(randf_range(5.5, 8.5))

func take_damage(amount: float, headshot: bool) -> bool:
	if not _alive:
		return false
	current_health = maxf(current_health - amount, 0.0)
	_health_display_left = 1.8
	_update_health_display()
	if headshot:
		_play_headshot_sound()
	if current_health <= 0.0:
		_die()
		return true
	return false

func _die() -> void:
	_alive = false
	visible = false
	velocity = Vector3.ZERO
	if _head_area != null:
		_head_area.monitorable = false
	if _torso_area != null:
		_torso_area.monitorable = false
	await get_tree().create_timer(respawn_delay).timeout
	if not is_inside_tree():
		return
	current_health = max_health
	global_position = Vector3(_patrol_origin_x, 0.0, _patrol_origin_z)
	_alive = true
	visible = true
	if _head_area != null:
		_head_area.monitorable = true
	if _torso_area != null:
		_torso_area.monitorable = true
	_update_health_display()

func _build_visuals() -> void:
	var uniform := _material(Color(0.075, 0.105, 0.105))
	var armor := _material(Color(0.13, 0.16, 0.15), 0.26)
	var armor_edge := _material(Color(0.25, 0.28, 0.25), 0.38)
	var helmet_mat := _material(Color(0.055, 0.08, 0.08), 0.32)
	var visor_mat := _material(Color(0.10, 0.18, 0.18), 0.52)
	var skin := _material(Color(0.31, 0.25, 0.19))
	var boot_mat := _material(Color(0.035, 0.04, 0.038), 0.2)
	var pouch_mat := _material(Color(0.19, 0.22, 0.19), 0.18)

	_add_box_part("Pelvis", Vector3(0.40, 0.25, 0.30), Vector3(0.0, 0.70, 0.0), uniform)
	_add_box_part("Torso_Uniform", Vector3(0.54, 0.66, 0.34), Vector3(0.0, 1.10, 0.0), uniform)
	_add_box_part("Plate_Carrier", Vector3(0.62, 0.53, 0.39), Vector3(0.0, 1.12, -0.025), armor)
	_add_box_part("Chest_Plate", Vector3(0.38, 0.29, 0.035), Vector3(0.0, 1.23, -0.232), armor_edge)
	_add_box_part("Shoulder_Left", Vector3(0.24, 0.20, 0.34), Vector3(-0.37, 1.34, -0.015), armor)
	_add_box_part("Shoulder_Right", Vector3(0.24, 0.20, 0.34), Vector3(0.37, 1.34, -0.015), armor)
	_add_box_part("Backpack", Vector3(0.42, 0.50, 0.20), Vector3(0.0, 1.15, 0.255), armor)
	for x in [-0.20, 0.0, 0.20]:
		_add_box_part("Magazine_Pouch", Vector3(0.14, 0.16, 0.11), Vector3(x, 0.96, -0.245), pouch_mat)
	_add_box_part("Radio", Vector3(0.12, 0.19, 0.10), Vector3(0.24, 1.40, 0.06), armor_edge)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.17
	head_mesh.height = 0.34
	head.mesh = head_mesh
	head.position = Vector3(0.0, 1.63, 0.0)
	head.material_override = skin
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(head)
	var helmet := MeshInstance3D.new()
	var helmet_mesh := SphereMesh.new()
	helmet_mesh.radius = 0.215
	helmet_mesh.height = 0.22
	helmet.scale = Vector3(1.0, 0.72, 1.0)
	helmet.mesh = helmet_mesh
	helmet.position = Vector3(0.0, 1.79, 0.015)
	helmet.material_override = helmet_mat
	helmet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(helmet)
	_add_box_part("Helmet_Visor", Vector3(0.31, 0.075, 0.12), Vector3(0.0, 1.70, -0.16), visor_mat)
	_add_box_part("Face_Protection", Vector3(0.24, 0.13, 0.08), Vector3(0.0, 1.55, -0.15), armor)
	_add_box_part("Helmet_Rail", Vector3(0.30, 0.035, 0.045), Vector3(0.0, 1.80, -0.18), armor_edge)

	_left_leg = _create_limb("Left_Leg", Vector3(-0.16, 0.68, 0.0), Vector3(0.23, 0.68, 0.25), uniform)
	_right_leg = _create_limb("Right_Leg", Vector3(0.16, 0.68, 0.0), Vector3(0.23, 0.68, 0.25), uniform)
	_add_box_child(_left_leg, "Left_Boot", Vector3(0.24, 0.15, 0.40), Vector3(0.0, -0.60, -0.065), boot_mat)
	_add_box_child(_right_leg, "Right_Boot", Vector3(0.24, 0.15, 0.40), Vector3(0.0, -0.60, -0.065), boot_mat)
	_add_box_child(_left_leg, "Left_Knee_Pad", Vector3(0.22, 0.18, 0.10), Vector3(0.0, -0.28, -0.14), armor_edge)
	_add_box_child(_right_leg, "Right_Knee_Pad", Vector3(0.22, 0.18, 0.10), Vector3(0.0, -0.28, -0.14), armor_edge)

	_left_arm = _create_limb("Left_Arm", Vector3(-0.37, 1.34, -0.02), Vector3(0.19, 0.57, 0.21), uniform)
	_right_arm = _create_limb("Right_Arm", Vector3(0.37, 1.34, -0.02), Vector3(0.19, 0.57, 0.21), uniform)
	_add_box_child(_left_arm, "Left_Glove", Vector3(0.20, 0.19, 0.22), Vector3(0.0, -0.34, -0.08), boot_mat)
	_add_box_child(_right_arm, "Right_Glove", Vector3(0.20, 0.19, 0.22), Vector3(0.0, -0.34, -0.08), boot_mat)
	_weapon_visual = _add_box_part("Hostile_Rifle", Vector3(0.12, 0.11, 0.70), Vector3(0.18, 1.10, -0.37), boot_mat)
	_add_box_part("Rifle_Handguard", Vector3(0.10, 0.095, 0.28), Vector3(0.18, 1.10, -0.67), armor_edge)
	_muzzle_flash = _add_box_part("Muzzle_Flash", Vector3(0.12, 0.12, 0.20), Vector3(0.18, 1.10, -0.85), _emissive(Color(1.0, 0.45, 0.08)))
	_muzzle_flash.visible = false

	_health_bar_root = Node3D.new()
	_health_bar_root.position = Vector3(0.0, 2.15, 0.0)
	_health_bar_root.visible = false
	add_child(_health_bar_root)
	_health_bar_root.add_child(_make_bar_piece(Vector3(0.92, 0.075, 0.025), Color(0.025, 0.03, 0.03)))
	_health_bar_fill = _make_bar_piece(Vector3(0.86, 0.045, 0.03), Color(0.85, 0.19, 0.13))
	_health_bar_fill.position.z = -0.02
	_health_bar_root.add_child(_health_bar_fill)
	_health_label = Label3D.new()
	_health_label.text = "100 HP"
	_health_label.font_size = 28
	_health_label.outline_size = 5
	_health_label.position.y = 0.16
	_health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_health_bar_root.add_child(_health_label)

func _create_limb(limb_name: String, pivot_position: Vector3, dimensions: Vector3, material: StandardMaterial3D) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = limb_name
	pivot.position = pivot_position
	add_child(pivot)
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = dimensions.x * 0.5
	capsule.height = dimensions.y
	mesh.mesh = capsule
	mesh.position.y = -dimensions.y * 0.46
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pivot.add_child(mesh)
	return pivot

func _add_box_part(part_name: String, dimensions: Vector3, part_position: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = part_name
	var box := BoxMesh.new()
	box.size = dimensions
	mesh.mesh = box
	mesh.position = part_position
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	return mesh

func _add_box_child(parent: Node3D, part_name: String, dimensions: Vector3, part_position: Vector3, material: StandardMaterial3D) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = part_name
	var box := BoxMesh.new()
	box.size = dimensions
	mesh.mesh = box
	mesh.position = part_position
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)

func _make_bar_piece(dimensions: Vector3, color: Color) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = dimensions
	piece.mesh = box
	var material := _material(color)
	piece.material_override = material
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return piece

func _build_hitboxes() -> void:
	_head_area = Area3D.new()
	_head_area.name = "HeadHitbox"
	_head_area.position = Vector3(0.0, 1.64, 0.0)
	_head_area.collision_layer = 2
	_head_area.collision_mask = 0
	_head_area.monitoring = false
	_head_area.monitorable = true
	_head_area.set_meta("headshot", true)
	var head_collision := CollisionShape3D.new()
	var head_shape := SphereShape3D.new()
	head_shape.radius = 0.19
	head_collision.shape = head_shape
	_head_area.add_child(head_collision)
	add_child(_head_area)

	_torso_area = Area3D.new()
	_torso_area.name = "TorsoHitbox"
	_torso_area.position = Vector3(0.0, 1.08, 0.0)
	_torso_area.collision_layer = 2
	_torso_area.collision_mask = 0
	_torso_area.monitoring = false
	_torso_area.monitorable = true
	var torso_collision := CollisionShape3D.new()
	var torso_shape := CapsuleShape3D.new()
	torso_shape.radius = 0.32
	torso_shape.height = 0.72
	torso_collision.shape = torso_shape
	_torso_area.add_child(torso_collision)
	_torso_area.set_meta("headshot", false)
	add_child(_torso_area)

func _update_health_display() -> void:
	if _health_bar_fill != null:
		var ratio := clampf(current_health / maxf(max_health, 1.0), 0.0, 1.0)
		_health_bar_fill.scale.x = maxf(ratio, 0.01)
		_health_bar_fill.position.x = -0.43 * (1.0 - ratio)
	if _health_label != null:
		_health_label.text = str(int(ceil(current_health))) + " HP"
	if _health_bar_root != null:
		_health_bar_root.visible = true
	_health_display_left = 1.8

func _animate_swat(delta: float, movement: float) -> void:
	var moving := clampf(movement, 0.0, 1.0)
	_motion_phase += delta * (2.0 + moving * 7.0)
	var swing := sin(_motion_phase) * 0.42 * moving
	if _left_leg != null:
		_left_leg.rotation.x = swing
	if _right_leg != null:
		_right_leg.rotation.x = -swing
	if _left_arm != null:
		_left_arm.rotation.x = -swing * 0.35 - 0.18
	if _right_arm != null:
		_right_arm.rotation.x = swing * 0.25 - 0.22

func _play_headshot_sound() -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = load("res://assets/audio/headshot.wav") as AudioStream
	player.volume_db = -8.0
	player.max_distance = 24.0
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _material(color: Color, metalness: float = 0.08) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	material.metallic = metalness
	return material

func _emissive(color: Color) -> StandardMaterial3D:
	var material := _material(color, 0.0)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.8
	return material
