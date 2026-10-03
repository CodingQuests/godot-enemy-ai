class_name ChargerEnemy
extends EnemyBase
## Heavy bruiser. Creeps forward, locks onto the player at medium range, shows a
## long rectangular telegraph, then dashes in a straight line. Collides with the
## player during the charge. Easy to side-step once you read the telegraph.

@export var charge_speed: float = 360.0
@export var charge_range: float = 180.0
@export var cooldown: float = 1.8
@export var windup_time: float = 0.5
@export var charge_time: float = 0.45
@export var recovery_time: float = 0.6

var _cd: float = 0.0
var _charge_dir := Vector2.RIGHT


func _on_ready() -> void:
	max_health = 65.0
	speed = 70.0
	attack_damage = 18.0
	attack_knockback = 320.0
	health.max_health = max_health
	health.current_health = max_health
	state = State.CHASE


func _ai_process(delta: float) -> void:
	if _cd > 0.0:
		_cd -= delta

	match state:
		State.IDLE, State.CHASE:
			velocity = dir_to_player() * speed
			if has_player() and distance_to_player() <= charge_range and _cd <= 0.0:
				_enter_windup()
		State.TELEGRAPH:
			velocity = velocity.move_toward(Vector2.ZERO, 600 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_charge()
		State.ATTACK:
			velocity = _charge_dir * charge_speed
			state_timer -= delta
			if state_timer <= 0.0 or is_on_wall():
				_enter_recovery()
		State.RECOVERY:
			velocity = velocity.move_toward(Vector2.ZERO, 800 * delta)
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.CHASE


func _enter_windup() -> void:
	state = State.TELEGRAPH
	state_timer = windup_time
	_charge_dir = dir_to_player()  # lock the charge direction now
	show_telegraph_rect(charge_speed * charge_time * 0.7, 34.0, _charge_dir)


func _enter_charge() -> void:
	hide_telegraph()
	state = State.ATTACK
	state_timer = charge_time
	enable_attack_area(Vector2.ZERO, 18.0)  # the body itself hurts during the charge
	GameManager.shake_camera(0.12)


func _enter_recovery() -> void:
	_disable_attack_area()
	state = State.RECOVERY
	state_timer = recovery_time
	_cd = cooldown
