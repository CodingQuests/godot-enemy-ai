class_name BossEnemy
extends EnemyBase
## The boss ("The Forge Warden"). Cycles through three telegraphed attack
## patterns (ground slam AoE, radial projectile volley, line charge) and turns
## enraged below half health (faster wind-ups, denser volleys). set_level()
## scales it up for later levels.

const PROJECTILE := preload("res://scenes/Projectile.tscn")

enum Pattern { SLAM, VOLLEY, CHARGE }

@export var projectile_damage: float = 12.0

var _pattern: int = Pattern.SLAM
var _move_timer: float = 0.0
var _charge_dir := Vector2.RIGHT
var _level: int = 1


func _on_ready() -> void:
	max_health = 420.0
	speed = 52.0
	attack_damage = 22.0
	attack_knockback = 360.0
	health.max_health = max_health
	health.current_health = max_health
	state = State.CHASE
	_move_timer = 1.0
	add_to_group("boss")


func set_level(lv: int) -> void:
	_level = lv
	max_health = 420.0 + float(lv - 1) * 150.0
	attack_damage = 22.0 + float(lv - 1) * 4.0
	projectile_damage = 12.0 + float(lv - 1) * 2.0
	health.max_health = max_health
	health.current_health = max_health


func _enraged() -> bool:
	return health.get_ratio() < 0.5


func _ai_process(delta: float) -> void:
	match state:
		State.IDLE, State.CHASE:
			_move_timer -= delta
			var d := distance_to_player()
			var dir := dir_to_player()
			if d > 120.0:
				velocity = dir * speed
			elif d < 70.0:
				velocity = -dir * speed * 0.6
			else:
				velocity = dir.orthogonal() * speed * 0.4
			if _move_timer <= 0.0:
				_choose_pattern()
		State.TELEGRAPH:
			velocity = velocity.move_toward(Vector2.ZERO, 400 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				_execute_pattern()
		State.ATTACK:
			if _pattern == Pattern.CHARGE:
				velocity = _charge_dir * 340.0
				if is_on_wall():
					_enter_recovery()
			else:
				velocity = velocity.move_toward(Vector2.ZERO, 600 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_recovery()
		State.RECOVERY:
			velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.CHASE
				_move_timer = randf_range(0.6, 1.1) * (0.55 if _enraged() else 1.0)


func _choose_pattern() -> void:
	_pattern = [Pattern.SLAM, Pattern.VOLLEY, Pattern.CHARGE].pick_random()
	state = State.TELEGRAPH
	var tt := 0.5 if _enraged() else 0.65
	match _pattern:
		Pattern.SLAM:
			show_telegraph_circle(80.0, Color(1, 0.2, 0.2, 0.4))
			state_timer = tt
		Pattern.VOLLEY:
			show_telegraph_circle(34.0, Color(0.8, 0.3, 1, 0.45))
			state_timer = tt
		Pattern.CHARGE:
			_charge_dir = dir_to_player()
			show_telegraph_rect(280.0, 46.0, _charge_dir)
			state_timer = tt + 0.05


func _execute_pattern() -> void:
	hide_telegraph()
	state = State.ATTACK
	match _pattern:
		Pattern.SLAM:
			state_timer = 0.2
			enable_attack_area(Vector2.ZERO, 80.0)
			GameManager.shake_camera(0.5)
			GameManager.hit_stop(0.05)
		Pattern.VOLLEY:
			state_timer = 0.3
			_fire_ring(10 if _enraged() else 8)
		Pattern.CHARGE:
			state_timer = 0.5
			enable_attack_area(Vector2.ZERO, 34.0)
			GameManager.shake_camera(0.2)


func _enter_recovery() -> void:
	_disable_attack_area()
	state = State.RECOVERY
	state_timer = 0.5 if _enraged() else 0.7


func _fire_ring(count: int) -> void:
	var container := get_tree().get_first_node_in_group("projectiles")
	if container == null:
		container = get_tree().current_scene
	for i in range(count):
		var a := TAU * float(i) / count
		var dir := Vector2(cos(a), sin(a))
		var proj := PROJECTILE.instantiate()
		container.add_child(proj)
		proj.global_position = global_position + dir * 24.0
		proj.setup(dir, projectile_damage, self)
