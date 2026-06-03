extends CharacterBody2D

class_name Bot

var w1 : Array
var w2 : Array
var w3 : Array

var dir := Vector2(0,0)
var SPEED
var collided : KinematicCollision2D
var stopSim := false
@onready var screen_size = get_tree().root.size

var b1
var b2
var b3


func initialize(m1: Array, m2: Array, m3: Array, spd: float):
	w1 = m1
	w2 = m2
	w3 = m3
	SPEED = spd


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position.x = screen_size.x/2
	position.y = screen_size.y/2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#region data collection
func getTopDangers(allBalls : Array[Ball]) -> Array:
	var topDangers := {}
	
	for ball in allBalls:
		var dot = 	ball.direction.normalized().dot(
					Vector2(position.x-ball.position.x, position.y-ball.position.y).normalized())
		var dirMultiplier = max(0,dot)
		var dangerLvl = dirMultiplier * ball.SPEED
		
		topDangers[ball] = dangerLvl
		
	return _get_top_five_keys(topDangers)
	
func returnInputMatrix(allBalls : Array[Ball]) -> Array:
	var inputMatrix := []
	var topDangers = getTopDangers(allBalls)
	
	for danger in topDangers:
		if danger == null:
			inputMatrix.append_array([0,0,0,0,0,0,0])
		else:
			var relX = danger.position.x - position.x
			var relY = danger.position.y - position.y
			var to_ball = Vector2(relX, relY)
			var dist = to_ball.length()
			var speed = danger.SPEED
			var to_ball_norm = to_ball / max(dist, 0.0001)
			var vel = danger.direction.normalized()
			# how directly it's heading toward bot
			var threat_alignment = vel.dot(-to_ball_norm)
			
			to_ball.x /= screen_size.x
			to_ball.y /= screen_size.y
			dist /= sqrt(screen_size.x * screen_size.x + screen_size.y * screen_size.y)
			speed /= get_parent().botSpeed*2
			
			inputMatrix.append_array([
				to_ball.x,
				to_ball.y,
				vel.x,
				vel.y,
				threat_alignment,
				speed,
				dist
			])
	
	inputMatrix.append_array([position.x/screen_size.x,position.y/screen_size.y])
	
	return [inputMatrix]
#endregion

#region simulation
# moves around according to the collected data of the most dangerous balls
func simulate(allBalls : Array[Ball], delta : float) -> void:
	# get the action
	var input = returnInputMatrix(allBalls)
	
	var output_1 = _multiply_matrices(input,w1)
	
	for i in range(output_1[0].size()):
		output_1[0][i] = max(0, output_1[0][i])
		#output_1[0][i] += randf_range(-0.1,0.1)
	
	var output_2 = _multiply_matrices(output_1,w2)
	for i in range(output_2[0].size()):
		output_2[0][i] = max(0, output_2[0][i])
		#output_2[0][i] += randf_range(-0.1,0.1)
	
	var output_3 = _multiply_matrices(output_2,w3)
	for i in range(output_3[0].size()):
		var element = output_3[0][i]
		output_3[0][i] = 1.0 / (1 + exp(-element))
		
	var output = output_3[0]
	
	# actions: up, left, down, right, stay
	var action_index = _index_of_max(output)
	match action_index:
		0:
			dir.x = 0
			dir.y = -1
		1:
			dir.x = -1
			dir.y = 0
		2:
			dir.x = 0
			dir.y = 1
		3:
			dir.x = 1
			dir.y = 0
		4:
			dir.x = 0
			dir.y = 0
	
	collided = move_and_collide(dir*SPEED*delta)
	
func scoreChange() -> float:
	if collided:
		stopSim = true
		return -10
	elif outOfScreen():
		stopSim = true
		return -5
	else:
		return 0.03
#endregion

#region helpers
func outOfScreen() -> bool:
	var xEdge = get_tree().root.size.x
	var yEdge = get_tree().root.size.y
	
	return 	(
	position.x > xEdge || 
	position.x < 0 || 
	position.y > yEdge || 
	position.y < 0
	)

func _get_top_five_keys(dict: Dictionary) -> Array:
	# Sort keys by their values in descending order
	var sorted_keys = dict.keys()
	sorted_keys.sort_custom(func(a, b):
		return dict[a] > dict[b]
	)
	
	# Take top 5 keys
	var top_keys = sorted_keys.slice(0, 5)
	
	# Fill with null if less than 5
	while top_keys.size() < 5:
		top_keys.append(null)
	
	return top_keys
	
func _multiply_matrices(a: Array, b: Array) -> Array:
	# Validate input: must be non-empty 2D arrays
	if a.is_empty() or b.is_empty():
		push_error("Matrices cannot be empty.")
		get_tree().quit()
	if typeof(a[0]) != TYPE_ARRAY or typeof(b[0]) != TYPE_ARRAY:
		push_error("Both inputs must be 2D arrays.")
		get_tree().quit()

	var rows_a = a.size()
	var cols_a = a[0].size()
	var rows_b = b.size()
	var cols_b = b[0].size()

	# Check if all rows have consistent lengths
	for row in a:
		if row.size() != cols_a:
			push_error("Matrix A has inconsistent row lengths.")
			get_tree().quit()
	for row in b:
		if row.size() != cols_b:
			push_error("Matrix B has inconsistent row lengths.")
			get_tree().quit()

	# Check multiplication compatibility
	if cols_a != rows_b:
		push_error("Matrix dimensions do not match for multiplication.")
		get_tree().quit()

	# Initialize result matrix with zeros
	var result := []
	for i in range(rows_a):
		result.append([])
		for j in range(cols_b):
			result[i].append(0)

	# Perform multiplication
	for i in range(rows_a):
		for j in range(cols_b):
			var sum := 0.0
			for k in range(cols_a):
				sum += (float)(a[i][k]) * b[k][j]
			result[i][j] = sum

	return result
	
func _index_of_max(arr: Array) -> int:
	if arr.is_empty():
		return -1  # Return -1 if array is empty

	var max_index := 0
	var max_value = arr[0]

	for i in range(1, arr.size()):
		if arr[i] > max_value:
			max_value = arr[i]
			max_index = i

	return max_index
#endregion
