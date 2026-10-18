extends Node2D


func _input(event):
	if event.is_action_pressed("ui_accept"):   # Space/Enter
		$Skier.inverted = !$Skier.inverted


var obstacle_scene = preload("res://Scenes/obstacle.tscn")
@export var allowed_frames: Array[int] = [0, 1, 2]   # pick which obstacles to use
var hard := false                                    # set true for "double obstacles"

func spawn_obstacles(chunk: Node2D):
	if rain_pending:
		rain_pending = false     # only once
		spawn_rain(chunk)
		return
	var placed: Array[Vector2] = []
	var deck: Array = []
	for row in 8:
		var count = randi_range(1, 2) if hard else 1
		for i in count:
			if deck.is_empty():
				deck = [-150, -100, -50, 0, 50, 100, 150]
				deck.shuffle()
			var x = deck.pop_back()
			var pos = Vector2.ZERO
			for t in 10:   # retry until it's not near another obstacle
				pos = Vector2(x + randf_range(-25, 25), -300 + row * 84 + randf_range(-25, 25))
				var ok = true
				for p in placed:
					if p.distance_to(pos) < 70:
						ok = false
						break
				if ok:
					break
			placed.append(pos)
			var o = obstacle_scene.instantiate()
			o.position = pos
			chunk.add_child(o)
			o.setup(allowed_frames.pick_random())


var dead := false

func die():
	if dead: return
	dead = true
	FileAccess.open(SAVE_PATH, FileAccess.WRITE).store_32(high_score)
	set_process(false)                  # stops the scrolling
	$Skier.set_physics_process(false)   # freezes the skier
	var d = AcceptDialog.new()
	d.title = "Game Over"
	d.dialog_text = "You died! Restart?"
	d.ok_button_text = "Restart"
	d.confirmed.connect(func(): get_tree().reload_current_scene())
	d.canceled.connect(func(): get_tree().reload_current_scene())
	add_child(d)
	d.popup_centered()

const CHUNK_H := 672.0
@export var speed := 300
var chunks: Array[Node2D] = []
var template: Node2D

func _ready():
	template = $TileMap.duplicate()   # clean copy to spawn from
	chunks.append($TileMap)
	setup_score()

func _process(delta):
	update_timer(delta)
	update_score(delta)
	
	if shaking:
		$Camera2D.offset = Vector2(randf_range(-6, 6), randf_range(-6, 6))   # 6 = shake strength
	
	for c in chunks:
		c.position.y -= speed * delta
	
	
	
	# spawn a new chunk exactly 672 px below the last one
	var last = chunks.back()
	if last.position.y <= CHUNK_H:
		var n = template.duplicate()
		n.position = Vector2(last.position.x, last.position.y + CHUNK_H)
		add_child(n)
		spawn_obstacles(n)   # <-- this was missing
		chunks.append(n)
	
	
	# delete the top chunk once it's 672 px above
	if chunks[0].position.y <= -CHUNK_H:
		chunks.pop_front().queue_free()




@export var event_time := 15.0  # change in Inspector or here
var time_left := event_time
var sudden_death := 0
var recent: Array[int] = []

func update_timer(delta):
	time_left -= delta
	if time_left <= 0:
		time_left = event_time
		pick_event()
	$CanvasLayer/Timer.text = "%dsec" % int(ceil(time_left))

var base_scale := Vector2.ONE

func pick_event():
	clear_event()   # the last event ends here
	var options = range(1, 11).filter(func(n): return n not in recent)
	sudden_death = options.pick_random()
	recent.append(sudden_death)
	if recent.size() > 2:
		recent.pop_front()
	show_popup(EVENT_NAMES[sudden_death])
	apply_event()

func apply_event():
	print("sudden death: ", sudden_death)
	match sudden_death:
		1: start_1()
		2: start_2()
		3: start_3()
		4: start_4()
		5: start_5()
		6: start_6()
		7: start_7()
		8: start_8()
		9: start_9()
		10: start_10()

func clear_event():
	match sudden_death:   # still holds the OLD event here
		1: end_1()
		2: end_2()
		3: end_3()
		4: end_4()
		5: end_5()
		6: end_6()
		7: end_7()
		8: end_8()
		9: end_9()
		10: end_10()

# ---- EVENT 1: big skier ----
func start_1(): $Skier.scale = base_scale * 3
func end_1():   $Skier.scale = base_scale

# ---- EVENT 2: small skier ----
func start_2(): $Skier.scale = base_scale * 0.5
func end_2():   $Skier.scale = base_scale

# ---- EVENTS 3-10: fill in later ----
var old_speed := 200.0

func start_3(): old_speed = speed; speed = old_speed * 2
func end_3():   speed = old_speed

func start_4(): old_speed = speed; speed = old_speed * 0.5
func end_4():   speed = old_speed


var fog: ColorRect
func start_5():
	fog = ColorRect.new()
	fog.color = Color(1, 1, 1, 0)
	fog.set_anchors_preset(Control.PRESET_FULL_RECT)
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$CanvasLayer.add_child(fog)
	$CanvasLayer.move_child(fog, 0)          # behind the timer label
	create_tween().tween_property(fog, "color:a", 0.7, 1.0)   # fades in
func end_5():
	if fog: fog.queue_free()


func start_6(): $Skier.wind = [-1, 1].pick_random() * 120   # random side, 120 = strength
func end_6():   $Skier.wind = 0.0


func start_7(): $Skier.slippery = true
func end_7():   $Skier.slippery = false


var rain_pending := false
func start_8(): rain_pending = true
func end_8():   rain_pending = false

func spawn_rain(chunk: Node2D):
	var path_x = clamp($Skier.position.x, -110.0, 110.0)
	for row in 8:
		var y = -300 + row * 84
		path_x = clamp(path_x + randf_range(-40, 40), -110.0, 110.0)   # path wanders
		var x = -170.0
		while x <= 170.0:
			if abs(x - path_x) > 50:         # 50 = half the gap width
				var o = obstacle_scene.instantiate()
				o.position = Vector2(x + randf_range(-8, 8), y + randf_range(-10, 10))
				chunk.add_child(o)
				o.setup(allowed_frames.pick_random())
			x += 40                          # distance between obstacles


var shaking := false
func start_9(): shaking = true
func end_9():
	shaking = false
	$Camera2D.offset = Vector2.ZERO




var old_skier_speed := 150.0
func start_10():
	old_skier_speed = $Skier.speed
	$Skier.speed = 200
func end_10():
	$Skier.speed = old_skier_speed


const EVENT_NAMES := {
	1: "BIG SKIER!", 2: "TINY SKIER!", 3: "SPEED UP!", 4: "SLOW DOWN!",
	5: "FOG!", 6: "WIND!", 7: "SLIPPERY ICE!", 8: "OBSTACLE RAIN!",
	9: "EARTHQUAKE!", 10: "TURBO SKIER!"
}

func show_popup(text: String):
	var l = Label.new()
	l.add_theme_color_override("font_color", Color.BLUE)
	l.text = text
	l.set_anchors_preset(Control.PRESET_TOP_WIDE)
	l.offset_top = 60                                   # distance from the top
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", 32)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	$CanvasLayer.add_child(l)
	var tw = create_tween()
	tw.tween_interval(0.7)                              # visible 0.7s
	tw.tween_property(l, "modulate:a", 0.0, 0.3)        # fades over 0.3s = 1s total
	tw.tween_callback(l.queue_free)



const SAVE_PATH := "user://highscore.save"
var score := 0
var score_timer := 0.0
var high_score := 0
var score_label: Label
var high_label: Label

func setup_score():
	if FileAccess.file_exists(SAVE_PATH):
		high_score = FileAccess.open(SAVE_PATH, FileAccess.READ).get_32()
	score_label = make_corner_label("Score: 0", true)
	high_label = make_corner_label("Best: %d" % high_score, false)

func make_corner_label(text: String, right: bool) -> Label:
	var l = Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color.YELLOW)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	$CanvasLayer.add_child(l)
	var preset = Control.PRESET_BOTTOM_RIGHT if right else Control.PRESET_BOTTOM_LEFT
	l.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, 12)
	l.grow_vertical = Control.GROW_DIRECTION_BEGIN
	if right:
		l.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	return l

func update_score(delta):
	score_timer += delta
	if score_timer >= 1.0:
		score_timer -= 1.0
		score += 1
		score_label.text = "Score: %d" % score
		if score > high_score:
			high_score = score
			high_label.text = "Best: %d" % high_score
