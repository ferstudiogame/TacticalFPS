extends Node3D
class_name ArenaBuilder

const ENEMY_SCENE: PackedScene = preload("res://scenes/EnemyBot.tscn")
var _materials: Dictionary = {}

func _ready() -> void:
	_build_industrial_yard()
	_spawn_enemies()
	_build_environment()

func _build_industrial_yard() -> void:
	var asphalt := _mat("asphalt", Color(0.105, 0.125, 0.125), 0.96)
	var concrete := _mat("concrete", Color(0.27, 0.29, 0.28), 0.92)
	var wall := _mat("wall", Color(0.20, 0.235, 0.23), 0.88)
	var metal := _mat("metal", Color(0.105, 0.135, 0.14), 0.72, 0.38)
	var yellow := _mat("safety_yellow", Color(0.92, 0.59, 0.12), 0.78)
	var white := _mat("paint_white", Color(0.72, 0.75, 0.70), 0.86)
	var rust := _mat("rust_red", Color(0.39, 0.13, 0.085), 0.8, 0.12)
	var blue := _mat("container_blue", Color(0.07, 0.20, 0.29), 0.76, 0.18)
	var green := _mat("container_green", Color(0.16, 0.24, 0.19), 0.8, 0.1)
	var wood := _mat("pallet_wood", Color(0.30, 0.22, 0.14), 0.92)
	var dark := _mat("rubber", Color(0.035, 0.043, 0.043), 0.98)

	_add_box("Asphalt_Yard", Vector3(84.0, 0.5, 84.0), Vector3(0.0, -0.25, 0.0), asphalt, true)
	_add_box("North_Perimeter", Vector3(84.0, 5.2, 0.7), Vector3(0.0, 2.6, -42.0), wall, true)
	_add_box("South_Perimeter", Vector3(84.0, 5.2, 0.7), Vector3(0.0, 2.6, 42.0), wall, true)
	_add_box("West_Perimeter", Vector3(0.7, 5.2, 84.0), Vector3(-42.0, 2.6, 0.0), wall, true)
	_add_box("East_Perimeter", Vector3(0.7, 5.2, 84.0), Vector3(42.0, 2.6, 0.0), wall, true)

	_build_warehouse(wall, metal, yellow, concrete)
	_add_container("Container_Red_A", Vector3(-17.0, 1.45, -8.0), rust, metal)
	_add_container("Container_Blue_B", Vector3(17.0, 1.45, -9.0), blue, metal)
	_add_container("Container_Green_C", Vector3(-17.0, 1.45, 17.0), green, metal)
	_add_container("Container_Red_D", Vector3(18.0, 1.45, 18.0), rust, metal)

	_add_box("Loading_Dock", Vector3(25.0, 1.0, 4.0), Vector3(0.0, 0.5, -14.0), concrete, true)
	_add_box("Dock_Step_Left", Vector3(5.0, 0.35, 1.2), Vector3(-8.0, 0.175, -11.3), concrete, true)
	_add_box("Dock_Step_Right", Vector3(5.0, 0.35, 1.2), Vector3(8.0, 0.175, -11.3), concrete, true)

	_add_box("Center_Cover_A", Vector3(6.0, 1.25, 1.0), Vector3(-5.0, 0.625, 3.0), concrete, true)
	_add_box("Center_Cover_B", Vector3(1.0, 1.45, 5.8), Vector3(7.5, 0.725, 7.0), concrete, true)
	_add_box("Center_Cover_C", Vector3(5.0, 0.85, 1.0), Vector3(1.5, 0.425, -1.0), wall, true)
	_add_box("South_Cover_A", Vector3(4.5, 1.1, 1.0), Vector3(-7.0, 0.55, 29.0), concrete, true)
	_add_box("South_Cover_B", Vector3(1.0, 1.1, 4.5), Vector3(9.0, 0.55, 25.0), concrete, true)
	_add_box("West_Cover", Vector3(5.0, 1.0, 1.0), Vector3(-29.0, 0.5, -1.0), concrete, true)
	_add_box("East_Cover", Vector3(5.0, 1.0, 1.0), Vector3(29.0, 0.5, 1.0), concrete, true)

	_build_catwalk(metal, yellow)
	_build_pipe_rack(metal, yellow)
	_build_pallet_stacks(wood, dark)
	_build_barrels(metal, yellow)
	_build_lighting(metal, yellow)

	for x in [-30.0, -20.0, -10.0, 10.0, 20.0, 30.0]:
		_add_box("Lane_Marking", Vector3(0.16, 0.018, 7.0), Vector3(x, 0.012, 0.0), yellow, false)
	for z in [-34.0, -28.0, 23.0, 34.0]:
		_add_box("Yard_Line", Vector3(66.0, 0.018, 0.12), Vector3(0.0, 0.012, z), white, false)
	_add_label("SECTOR 07  /  PORT AUTHORITY", Vector3(0.0, 5.8, -31.1), 42, Color(0.78, 0.83, 0.79))
	_add_label("LOADING BAY  /  04", Vector3(0.0, 7.1, -17.4), 30, Color(0.94, 0.63, 0.18))
	_add_label("AUTHORIZED PERSONNEL ONLY", Vector3(-40.8, 3.7, 0.0), 26, Color(0.91, 0.62, 0.2), Vector3(0.0, deg_to_rad(90.0), 0.0))

func _build_warehouse(wall: StandardMaterial3D, metal: StandardMaterial3D, yellow: StandardMaterial3D, concrete: StandardMaterial3D) -> void:
	_add_box("Warehouse_Back_Wall", Vector3(28.0, 8.0, 0.65), Vector3(0.0, 4.0, -32.0), wall, true)
	_add_box("Warehouse_Left_Wall", Vector3(0.65, 8.0, 14.0), Vector3(-14.0, 4.0, -24.5), wall, true)
	_add_box("Warehouse_Right_Wall", Vector3(0.65, 8.0, 14.0), Vector3(14.0, 4.0, -24.5), wall, true)
	_add_box("Warehouse_Roof", Vector3(28.0, 0.7, 15.0), Vector3(0.0, 8.1, -24.5), metal, true)
	for x in [-11.5, -7.5, 7.5, 11.5]:
		_add_box("Warehouse_Pillar", Vector3(0.48, 7.5, 0.5), Vector3(x, 3.75, -17.5), metal, true)
	for x in [-9.0, 0.0, 9.0]:
		_add_box("Roller_Door_Rail", Vector3(0.12, 5.8, 0.12), Vector3(x, 2.9, -17.1), yellow, false)
	_add_box("Warehouse_Interior_Cover", Vector3(7.0, 1.1, 1.0), Vector3(0.0, 0.55, -25.0), concrete, true)
	_add_box("Roof_Beam_A", Vector3(27.0, 0.24, 0.24), Vector3(0.0, 7.35, -20.0), metal, true)
	_add_box("Roof_Beam_B", Vector3(27.0, 0.24, 0.24), Vector3(0.0, 7.35, -29.0), metal, true)

func _add_container(container_name: String, center: Vector3, body_material: StandardMaterial3D, rib_material: StandardMaterial3D) -> void:
	var size := Vector3(10.0, 2.9, 3.1)
	_add_box(container_name, size, center, body_material, true)
	for i in range(19):
		var x := center.x - 4.65 + float(i) * 0.515
		for side in [-1.0, 1.0]:
			_add_box(container_name + "_Rib", Vector3(0.075, 2.72, 0.11), Vector3(x, center.y, center.z + side * 1.57), rib_material, false)
	for side in [-1.0, 1.0]:
		_add_box(container_name + "_Corner_Post", Vector3(0.16, 2.86, 0.16), Vector3(center.x + side * 4.84, center.y, center.z - 1.54), rib_material, false)
		_add_box(container_name + "_Door_Rail", Vector3(0.11, 2.7, 0.11), Vector3(center.x + side * 4.55, center.y, center.z - 1.57), rib_material, false)
	_add_box(container_name + "_Top_Rail", Vector3(9.8, 0.12, 0.12), Vector3(center.x, center.y + 1.46, center.z - 1.58), rib_material, false)

func _build_catwalk(metal: StandardMaterial3D, yellow: StandardMaterial3D) -> void:
	_add_box("Catwalk_Platform", Vector3(15.0, 0.35, 3.0), Vector3(27.0, 4.0, -20.0), metal, true)
	for x in [20.0, 34.0]:
		_add_box("Catwalk_Support", Vector3(0.45, 4.0, 0.45), Vector3(x, 2.0, -20.0), metal, true)
	for x in [20.0, 34.0]:
		_add_box("Catwalk_Rail_Front", Vector3(0.12, 1.0, 3.0), Vector3(x, 4.65, -20.0), yellow, true)
	_add_box("Catwalk_Rail_Long", Vector3(14.0, 1.0, 0.12), Vector3(27.0, 4.65, -21.45), yellow, true)
	_add_box("Catwalk_Rail_Back", Vector3(14.0, 1.0, 0.12), Vector3(27.0, 4.65, -18.55), yellow, true)
	for i in range(10):
		_add_box("Ladder_Rung", Vector3(0.75, 0.09, 0.12), Vector3(34.0, 0.5 + float(i) * 0.36, -17.8), metal, false)

func _build_pipe_rack(metal: StandardMaterial3D, yellow: StandardMaterial3D) -> void:
	_add_box("Pipe_Rack_Base", Vector3(13.0, 0.25, 2.2), Vector3(-28.0, 0.45, -23.0), metal, true)
	for x in [-33.5, -28.0, -22.5]:
		_add_box("Pipe_Rack_Support", Vector3(0.3, 4.0, 0.3), Vector3(x, 2.3, -23.0), metal, true)
		for z in [-23.9, -22.1]:
			var pipe := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.22
			mesh.bottom_radius = 0.22
			mesh.height = 5.2
			pipe.mesh = mesh
			pipe.rotation.z = deg_to_rad(90.0)
			pipe.position = Vector3(-28.0, 3.8, z)
			pipe.material_override = yellow if z > -23.0 else metal
			pipe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(pipe)

func _build_pallet_stacks(wood: StandardMaterial3D, dark: StandardMaterial3D) -> void:
	for center in [Vector3(-28.0, 0.2, 7.0), Vector3(27.0, 0.2, 8.0), Vector3(0.0, 0.2, 32.0)]:
		_add_box("Pallet_Base", Vector3(2.8, 0.22, 1.8), center, wood, true)
		for i in range(5):
			_add_box("Pallet_Slat", Vector3(0.38, 0.14, 1.72), center + Vector3(-1.1 + float(i) * 0.55, 0.17, 0.0), dark, false)
		_add_box("Crate_Lower", Vector3(1.65, 1.15, 1.35), center + Vector3(0.1, 0.82, 0.0), wood, true)
		_add_box("Crate_Upper", Vector3(1.15, 0.9, 1.0), center + Vector3(0.2, 1.82, 0.0), wood, true)

func _build_barrels(metal: StandardMaterial3D, yellow: StandardMaterial3D) -> void:
	for center in [Vector3(-12.0, 0.0, 8.0), Vector3(-11.0, 0.0, 10.0), Vector3(12.0, 0.0, -1.0), Vector3(14.0, 0.0, -1.0), Vector3(28.0, 0.0, -5.0)]:
		var barrel := MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.42
		cylinder.bottom_radius = 0.42
		cylinder.height = 1.05
		barrel.mesh = cylinder
		barrel.position = center + Vector3(0.0, 0.53, 0.0)
		barrel.material_override = metal
		barrel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(barrel)
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = 0.42
		shape.height = 1.05
		collision.shape = shape
		body.position = barrel.position
		body.collision_layer = 1
		body.collision_mask = 1
		body.add_child(collision)
		add_child(body)
		var band := MeshInstance3D.new()
		var band_mesh := CylinderMesh.new()
		band_mesh.top_radius = 0.43
		band_mesh.bottom_radius = 0.43
		band_mesh.height = 0.13
		band.mesh = band_mesh
		band.position = center + Vector3(0.0, 0.72, 0.0)
		band.material_override = yellow
		band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(band)

func _build_lighting(metal: StandardMaterial3D, yellow: StandardMaterial3D) -> void:
	for center in [Vector3(-35.0, 0.0, -34.0), Vector3(35.0, 0.0, -34.0), Vector3(-35.0, 0.0, 34.0), Vector3(35.0, 0.0, 34.0)]:
		_add_box("Floodlight_Pole", Vector3(0.22, 8.0, 0.22), center + Vector3(0.0, 4.0, 0.0), metal, true)
		_add_box("Floodlight_Arm", Vector3(1.8, 0.18, 0.18), center + Vector3(0.7, 7.8, 0.0), metal, false)
		var lamp := OmniLight3D.new()
		lamp.position = center + Vector3(0.7, 7.5, 0.0)
		lamp.light_color = Color(1.0, 0.72, 0.43)
		lamp.light_energy = 1.0
		lamp.omni_range = 16.0
		lamp.shadow_enabled = false
		add_child(lamp)

func _add_label(text_value: String, label_position: Vector3, size: int, tint: Color, label_rotation: Vector3 = Vector3.ZERO) -> void:
	var label := Label3D.new()
	label.text = text_value
	label.font_size = size
	label.outline_size = 7
	label.modulate = tint
	label.position = label_position
	label.rotation = label_rotation
	label.no_depth_test = false
	add_child(label)

func _add_box(box_name: String, box_size: Vector3, box_position: Vector3, material: StandardMaterial3D, with_collision: bool, box_rotation: Vector3 = Vector3.ZERO) -> void:
	var root := Node3D.new()
	root.name = box_name
	root.position = box_position
	root.rotation = box_rotation
	add_child(root)
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mesh_instance)
	if with_collision:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 1
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = box_size
		collision.shape = shape
		body.add_child(collision)
		root.add_child(body)

func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.055, 0.085, 0.105)
	sky_material.sky_horizon_color = Color(0.27, 0.31, 0.30)
	sky_material.ground_bottom_color = Color(0.055, 0.065, 0.065)
	sky_material.ground_horizon_color = Color(0.20, 0.23, 0.22)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.57, 0.62, 0.60)
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.24, 0.29, 0.29)
	environment.fog_density = 0.004
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_energy = 0.82
	sun.shadow_enabled = false
	add_child(sun)

func _mat(key: String, color: Color, roughness: float = 0.86, metallic: float = 0.05) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	_materials[key] = material
	return material

func _spawn_enemies() -> void:
	var spawn_positions: Array[Vector3] = [
		Vector3(-27.0, 0.0, -5.0),
		Vector3(9.0, 0.0, -26.0),
		Vector3(24.0, 0.0, 11.0),
		Vector3(-8.0, 0.0, 30.0),
		Vector3(0.0, 0.0, -8.0),
		Vector3(-32.0, 0.0, 24.0)
	]
	for spawn_position in spawn_positions:
		var enemy := ENEMY_SCENE.instantiate() as EnemyBot
		enemy.position = spawn_position
		add_child(enemy)
