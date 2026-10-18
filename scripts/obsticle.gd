extends Area2D

func _ready() -> void:
	body_entered.connect(_on_hit)

func _on_hit(b):
	if b.is_in_group("Player"):
		get_tree().current_scene.die()

func setup(frame: int):
	$AnimatedSprite2D.pause()
	$AnimatedSprite2D.frame = frame
