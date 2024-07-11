extends Node2D

# Settings
const snake_length = 3

# Runtime variables
var snakePos = []
var score : int
var game_prepared : bool
var game_started : bool
var snake_data : Array
var can_move : bool
var direction : Vector2i

# Constants
const floor_tile_id = 0
const snake_head_id = 1
const snake_body_id = 2
const apple_id = 3
const pear_id = 4

# Other
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	prepare_game()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	move_snake()
	pass

func create_snake():
	direction = Vector2i.UP
	var startX = $Background.get_used_rect().size.x / 2
	var startY = $Background.get_used_rect().size.y - snake_length
	add_segment(Vector2i(startX, startY), true)
	for i in range(1, snake_length):
		add_segment(Vector2i(startX, startY + i))

func add_segment(pos : Vector2i, is_head : bool = false):
	snake_data.append(pos)
	var tile_id = -1
	if is_head: tile_id = snake_head_id
	else: tile_id = snake_body_id
	$Background.set_cell(1, pos, 0, Vector2i(0, 0), tile_id)
	
func rem_segment(index : int):
	$Background.erase_cell(1, snake_data[index])
	snake_data.pop_at(index)

func prepare_game():
	get_tree().paused = false
	$GameOverMenu.hide()
	$Background.clear_layer(1)
	$Background.clear_layer(2)
	snake_data.clear()
	set_score(0)
	create_snake()
	place_object()
	game_prepared = true

func start_game():
	game_started = true
	$GameTimer.start()

func end_game():
	$GameTimer.stop()
	$GameOverMenu.show()
	game_prepared = false
	game_started = false
	get_tree().paused = true

func move_snake():
	if game_started and not can_move:
		return
		
	var update = func update():
		can_move = false
		if not game_started and game_prepared:
			start_game()
	
	if Input.is_action_just_pressed("move_up") and direction != Vector2i.DOWN:
		direction = Vector2i.UP
		update.call()
	if Input.is_action_just_pressed("move_down") and direction != Vector2i.UP:
		direction = Vector2i.DOWN
		update.call()
	if Input.is_action_just_pressed("move_left") and direction != Vector2i.RIGHT:
		direction = Vector2i.LEFT
		update.call()
	if Input.is_action_just_pressed("move_right") and direction != Vector2i.LEFT:
		direction = Vector2i.RIGHT
		update.call()

func is_out_of_bounds():
	var temp = $Background.get_cell_alternative_tile(0, snake_data[0])
	return temp == -1

func is_eating_itself():
	return snake_data.count(snake_data[0]) == 2

func set_score(new_score : int):
	score = new_score
	$Scoreboard.get_node("Score").text = 'SCORE: ' + str(score)

func _on_game_timer_timeout():
	# moves snake
	var last_cell_pos = snake_data.back()
	var first_cell_type = $Background.get_cell_alternative_tile(1, snake_data[0])
	for i in range(len(snake_data) - 2):
		$Background.set_cell(1, snake_data[i], 0, Vector2i(0, 0), $Background.get_cell_alternative_tile(1, snake_data[i+1]))
	$Background.erase_cell(1, last_cell_pos)
	$Background.set_cell(1, (snake_data[0] + direction), 0, Vector2i(0, 0), first_cell_type)
	for i in range(len(snake_data) - 1, 0, -1):
		snake_data[i] = snake_data[i-1]
	snake_data[0] += direction
	# enlarges the snake
	var obj_id = $Background.get_cell_alternative_tile(2, snake_data[0])
	if (obj_id != -1):
		$Background.erase_cell(2, snake_data[0])
		if obj_id == apple_id:
			add_segment(last_cell_pos)
			set_score(score + 1)
			# gotta put the winning condition
			pass
		elif obj_id == pear_id:
			set_score(score + 1)
			var center_offset = len(snake_data) / 2
			for i in range(center_offset, len(snake_data)):
				var other_pos = snake_data[len(snake_data) - i - 1]
				var other_id = $Background.get_cell_alternative_tile(1, other_pos)
				var this_id = $Background.get_cell_alternative_tile(1, snake_data[i])
				$Background.set_cell(1, other_pos, 0, Vector2i(0, 0), this_id)
				$Background.set_cell(1, snake_data[i], 0, Vector2i(0, 0), other_id)
			direction = direction * -1
			snake_data.reverse()
		place_object()
	
	if is_out_of_bounds() or is_eating_itself():
		end_game()
	else:
		can_move = true

func place_object():
	var rect = $Background.get_used_rect()
	while true:
		var pos = Vector2i(rng.randi_range(0, rect.size.x - 1),
			rng.randi_range(0, rect.size.y - 1))
		# avoids used tiles
		if $Background.get_cell_alternative_tile(1, pos) == -1 and $Background.get_cell_alternative_tile(2, pos) == -1:
			$Background.set_cell(2, pos, 0, Vector2i(0, 0), apple_id)
			break
		
	


func _on_game_over_menu_restart():
	prepare_game()
