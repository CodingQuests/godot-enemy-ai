extends Node2D
## The demo arena: a faint reference grid, every enemy type plus the boss, a
## health readout, and a label over each enemy that shows the state its state
## machine is in right now. Press Tab to hide the labels, R to restart.
##
## Everything in this script is demo scaffolding. The AI itself is EnemyBase
## and its subclasses.

const GRID := 64        # spacing between grid lines, in pixels
const EXTENT := 1600    # how far the grid reaches from the origin
const LINE_COLOR := Color(1, 1, 1, 0.06)

const STATE_COLORS := {
	"IDLE": Color(0.75, 0.75, 0.8),
	"CHASE": Color(1, 1, 1),
	"TELEGRAPH": Color(1, 0.6, 0.2),
	"ATTACK": Color(1, 0.3, 0.3),
	"RECOVERY": Color(0.55, 0.75, 1),
}

@onready var _hp_label: Label = $HUD/HP
@onready var _enemies_label: Label = $HUD/Enemies

var _state_labels: Dictionary = {}  # EnemyBase -> Label
var _show_states := true


func _ready() -> void:
	var health: HealthComponent = $Player/Health
	health.damaged.connect(_on_player_damaged)
	health.died.connect(_on_player_died)
	_on_player_damaged(0.0, health.current_health, health.max_health)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		_add_state_label(enemy as EnemyBase)


func _draw() -> void:
	for x in range(-EXTENT, EXTENT + 1, GRID):
		draw_line(Vector2(x, -EXTENT), Vector2(x, EXTENT), LINE_COLOR, 1.0)
	for y in range(-EXTENT, EXTENT + 1, GRID):
		draw_line(Vector2(-EXTENT, y), Vector2(EXTENT, y), LINE_COLOR, 1.0)


func _process(_delta: float) -> void:
	var alive := 0
	for enemy in _state_labels.keys():
		if not is_instance_valid(enemy):
			_state_labels.erase(enemy)
			continue
		var label: Label = _state_labels[enemy]
		if enemy.state == EnemyBase.State.DEAD:
			label.visible = false
			continue
		alive += 1
		var state_name: String = EnemyBase.State.keys()[enemy.state]
		label.text = state_name
		label.modulate = STATE_COLORS.get(state_name, Color.WHITE)
		label.visible = _show_states
	if alive > 0:
		_enemies_label.text = "Enemies left: %d" % alive
	else:
		_enemies_label.text = "All enemies down. Press R to fight again."


func _add_state_label(enemy: EnemyBase) -> void:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.z_index = 20
	# Sit just above the sprite, whatever size this enemy is drawn at.
	var sprite: Sprite2D = enemy.get_node("Sprite2D")
	var half_height := sprite.texture.get_height() * sprite.scale.y * 0.5
	label.size = Vector2(90, 14)
	label.position = Vector2(-45, -half_height - 18)
	enemy.add_child(label)
	_state_labels[enemy] = label


func _on_player_damaged(_amount: float, current: float, maximum: float) -> void:
	_hp_label.text = "HP %d / %d" % [current, maximum]


func _on_player_died() -> void:
	_hp_label.text = "You died. Press R to restart."


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_R:
		get_tree().reload_current_scene()
	elif key.keycode == KEY_TAB:
		_show_states = not _show_states
