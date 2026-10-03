class_name SkitterlingEnemy
extends EnemyBase
## Fast, fragile swarmer. Weaves toward the player and snaps with a very short
## telegraph. Dangerous in numbers, trivial one-on-one. Best placed in pairs.

@export var attack_range: float = 30.0
@export var attack_cooldown: float = 0.6
@export var telegraph_time: float = 0.18
@export var attack_active_time: float = 0.1
@export var recovery_time: float = 0.2

var _cd: float = 0.0
var _wobble: float = 0.0


func _on_ready() -> void:
	max_health = 18.0
	speed = 140.0
	attack_damage = 7.0
	attack_knockback = 120.0
	health.max_health = max_health
	health.current_health = max_health
	state = State.CHASE
	_wobble = randf() * TAU  # desync the weave between siblings


func _ai_process(delta: float) -> void:
	if _cd > 0.0:
		_cd -= delta
	_wobble += delta * 9.0

	match state:
		State.IDLE, State.CHASE:
			# Weave toward the player instead of a straight line.
			var dir := dir_to_player()
			var weave := dir.orthogonal() * sin(_wobble) * 0.45
			velocity = (dir + weave).normalized() * speed
			if has_player() and distance_to_player() <= attack_range and _cd <= 0.0:
				_enter_telegraph()
		State.TELEGRAPH:
			velocity = velocity.move_toward(Vector2.ZERO, 900 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_attack()
		State.ATTACK:
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_recovery()
		State.RECOVERY:
			velocity = velocity.move_toward(Vector2.ZERO, 900 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.CHASE


func _enter_telegraph() -> void:
	state = State.TELEGRAPH
	state_timer = telegraph_time
	show_telegraph_circle(attack_range * 0.7, Color(1, 0.4, 0.1, 0.4))


func _enter_attack() -> void:
	hide_telegraph()
	state = State.ATTACK
	state_timer = attack_active_time
	var dir := dir_to_player()
	enable_attack_area(dir * 18.0, 16.0)
	velocity = dir * 150.0  # quick lunge bite


func _enter_recovery() -> void:
	_disable_attack_area()
	state = State.RECOVERY
	state_timer = recovery_time
	_cd = attack_cooldown
