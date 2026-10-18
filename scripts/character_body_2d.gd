extends CharacterBody2D

@export var speed := 150
@export var limit_x := 176   # keeps him inside the slope


var inverted := false          # set true to flip controls
var wind := 0.0


var slippery := false
var vx := 0.0

func _physics_process(delta):
	velocity = Vector2(vx + wind, 0)
	var dir = Input.get_axis("ui_left", "ui_right")
	if inverted:
		dir = -dir
	if slippery:
		vx = lerp(vx, dir * speed, 1.5 * delta)   # lower = more slide
	else:
		vx = dir * speed
	velocity = Vector2(vx, 0)
	move_and_slide()
	position.x = clamp(position.x, -limit_x, limit_x)
