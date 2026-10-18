extends CanvasLayer

var label: Label

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS   # keeps working while the game is paused
	layer = 10
	label = Label.new()
	label.text = "PAUSED\nPress P to resume"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	label.visible = false
	add_child(label)
	label.add_theme_color_override("font_color", Color.YELLOW)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		if get_tree().current_scene.dead:
			return                            # can't pause on the game-over screen
		get_tree().paused = not get_tree().paused
		label.visible = get_tree().paused
