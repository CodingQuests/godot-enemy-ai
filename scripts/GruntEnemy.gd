class_name GruntEnemy
extends EnemyBase
## Melee chaser. Runs at the player, stops, flashes a red danger ring
## (telegraph), then swings. Readable and easy to dodge with a dash.

@export var attack_range: float = 45.0
@export var attack_cooldown: float = 1.1
@export var telegraph_time: float = 0.35
@export var attack_active_time: float = 0.14
@export var recovery_time: float = 0.45

var _cd: float = 0.0


func _on_ready() -> void:
	max_health = 50.0
	speed = 95.0
	attack_damage = 12.0
	attack_knockback = 200.0
	health.max_health = max_health
	health.current_health = max_health
	state = State.CHASE


func _ai_process(delta: float) -> void:
	if _cd > 0.0:
		_cd -= delta

	match state:
		State.IDLE, State.CHASE:
			velocity = dir_to_player() * speed
			if has_player() and distance_to_player() <= attack_range and _cd <= 0.0:
				_enter_telegraph()
		State.TELEGRAPH:
			velocity = velocity.move_toward(Vector2.ZERO, 700 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_attack()
		State.ATTACK:
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_recovery()
		State.RECOVERY:
			velocity = velocity.move_toward(Vector2.ZERO, 700 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.CHASE


func _enter_telegraph() -> void:
	state = State.TELEGRAPH
	state_timer = telegraph_time
	show_telegraph_circle(attack_range * 0.85)


func _enter_attack() -> void:
	hide_telegraph()
	state = State.ATTACK
	state_timer = attack_active_time
	var dir := dir_to_player()
	enable_attack_area(dir * 24.0, 22.0)
	velocity = dir * 120.0  # small lunge


func _enter_recovery() -> void:
	_disable_attack_area()
	state = State.RECOVERY
	state_timer = recovery_time
	_cd = attack_cooldown
