extends Node

class_name Main

#region variables

# essential participants variables
var b : Bot
var t : Tallier
var allBalls : Array[Ball]
var BotScene = preload("res://scenes/Bot.tscn")

var baseModels = []
var weightDims = [37,32,32,32,32,5]
var file
var botSpeed = 100

# main simulation variables
var simulation_time = 10.0
var simulation_timer = 0.0
var simulation_running = false

var n = 50
var current_generation = 0
var current_model_index = 0
var train_speeds := [1,5,10,20,50,100]
var train_speed_index = train_speeds.size()-1
var training_speed : int = train_speeds[train_speed_index]

var randseed = randf()*1000

# ballSpawningTimer variables
var timerWaitTime := 0.5

# controls
var shouldTrain = true

# item references
@onready var status_label = $status
#endregion

#region ready and process
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# speeds up simulation
	RenderingServer.render_loop_enabled = true
	Engine.time_scale = 1*training_speed
	Engine.physics_ticks_per_second = 60*training_speed
	
	status_label.text += "training speed: " + str(training_speed)
	
	file = FileAccess.open("res://output/method_pickSomeOutOfSomeAndEvolve/WeightMs.dat",FileAccess.WRITE)
	
	seed(114514)
	
	t = Tallier.new()
	
	baseModels = fill(weightDims)
	
	start_next_model()
	
func _process(delta: float) -> void:
	if Input.is_action_just_released("train"):
		shouldTrain = !shouldTrain
	elif Input.is_action_just_released("do_render"):
		RenderingServer.render_loop_enabled = !RenderingServer.render_loop_enabled
	elif Input.is_action_just_released("increse_train_speed"):
		train_speed_index += 1
		train_speed_index %= train_speeds.size()
		training_speed = train_speeds[train_speed_index]
		Engine.time_scale = 1*training_speed
		Engine.physics_ticks_per_second = 60*training_speed
	elif Input.is_action_just_released("decrease_train_speed"):
		train_speed_index -= 1
		train_speed_index %= train_speeds.size()
		training_speed = train_speeds[train_speed_index]
		Engine.time_scale = 1*training_speed
		Engine.physics_ticks_per_second = 60*training_speed
		
	status_label.text = ("training speed: " + str(training_speed) +
						"\nrendering: " + str(RenderingServer.render_loop_enabled) +
						"\ntraining: " + str(shouldTrain) +
						"\ngeneration: " + str(current_generation) +
						"\nmodel: " + str(current_model_index)
						)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if shouldTrain:
		update(delta)
#endregion

#region main training logic neuroevolution
func update(delta: float) -> void:
	timerWaitTime -= delta
	if timerWaitTime < 0:
		_on_ball_spawning_timer_timeout()
		timerWaitTime = 0.5
	
	if !simulation_running:
		return

	simulation_timer += delta

	for i in range(allBalls.size() - 1, -1, -1):
		var ball = allBalls[i]

		if is_offscreen(ball.position):
			allBalls.remove_at(i)
			ball.queue_free()
		else:
			ball.move(delta)
	
	b.simulate(allBalls, delta)
	
	t.update(t.getTallyTarget().scoreChange())
	
	if simulation_timer >= simulation_time || b.stopSim:

		simulation_running = false

		t.endTallySession()

		current_model_index += 1
		
		for ball in allBalls:
			ball.queue_free()
		allBalls.clear()


		# Finished all 100 models
		if current_model_index >= baseModels.size():
			randomize()
			finish_generation()
			randseed = randf()*1000

		else:
			
			start_next_model()
#endregion

#region calling beginning and ending of data tallying and resetting
func start_next_model():

	
	seed(randseed)
	var model = baseModels[current_model_index]

	var m1 = model[0]
	var m2 = model[1]
	var m3 = model[2]

	if b:
		b.queue_free()
		
	b = BotScene.instantiate()
	b.initialize(m1, m2, m3, botSpeed)
	add_child(b)

	t.setTallyTarget(b,current_model_index)

	simulation_timer = 0.0
	simulation_running = true

	print("Generation:",
		current_generation,
		"Model:",
		current_model_index)

func finish_generation():

	var top_ten = t.get_top_ten_keys()
	var best_score = t._tallies[top_ten[0]]

	file = FileAccess.open("res://output/method_pickSomeOutOfSomeAndEvolve/WeightMs.dat", FileAccess.READ_WRITE)
	file.seek_end()
	var bestWeightsThisGeneration : String = (
	"Best Model in generation %d, with a score of %f \n" 
	% [current_generation,best_score])
	for m in baseModels[top_ten[0]]:
		for row in m:
			bestWeightsThisGeneration += str(row) + "\n"
		bestWeightsThisGeneration += "\n"
	bestWeightsThisGeneration += "\n"
	file.store_string(bestWeightsThisGeneration)

	# Your evolution / mutation logic
	var new_models = generate_new_models(top_ten, weightDims)

	baseModels = new_models
	
	current_generation += 1
	current_model_index = 0

	print("best score:", best_score)

	t._tallies.clear()

	if current_generation >= n:

		simulation_running = false
		print("Training complete")
		print(b.w1)
		print(b.w2)
		print(b.w3)
		return
	
	start_next_model()
#endregion

#region model generation
func fill	(dims : Array) -> Array:
	randomize()
	var weights_input_1 : int = dims[0]
	var weights_output_1 : int = dims[1]
	var weights_input_2 : int = dims[2]
	var weights_output_2 : int = dims[3]
	var weights_input_3 : int = dims[4]
	var weights_output_3 : int = dims[5]
				
	var models := []
	for i in range(100):
		var m1 := []
		var m2 := []
		var m3 := []
		
		# xavier glorot range
		var xavierTyler1 : float = sqrt(6.0/(weights_input_1+weights_output_1))
		var xavierTyler2 : float = sqrt(6.0/(weights_input_2+weights_output_2))
		var xavierTyler3 : float = sqrt(6.0/(weights_input_3+weights_output_3))
		
		# xavier glorot initialization for all of the weight matrices
		for i1 in range(weights_input_1):
			var currCol := []
			for o1 in range(weights_output_1):
				currCol.append(randf_range(-xavierTyler1,xavierTyler1))
			m1.append(currCol)
				
		for i2 in range(weights_input_2):
			var currCol := []
			for o2 in range(weights_output_2):
				currCol.append(randf_range(-xavierTyler2,xavierTyler2))
			m2.append(currCol)
				
		for i3 in range(weights_input_3):
			var currCol := []
			for o3 in range(weights_output_3):
				currCol.append(randf_range(-xavierTyler3,xavierTyler3))
			m3.append(currCol)
				
		# filling the set of 3 weight matrices to baseModels
		models.append([m1,m2,m3])
		
	return models

func generate_new_models(top : Array, dims: Array) -> Array:
	randomize()
	var weights_input_1 : int = dims[0]
	var weights_output_1 : int = dims[1]
	var weights_input_2 : int = dims[2]
	var weights_output_2 : int = dims[3]
	var weights_input_3 : int = dims[4]
	var weights_output_3 : int = dims[5]
	# xavier glorot range
	var xavierTyler1 : float = sqrt(6.0/(weights_input_1+weights_output_1))
	var xavierTyler2 : float = sqrt(6.0/(weights_input_2+weights_output_2))
	var xavierTyler3 : float = sqrt(6.0/(weights_input_3+weights_output_3))
	
	var models := []

	# top ten as well as 80 mutated weights
	for i in range(top.size()):

		var parent = baseModels[top[i]]

		# keep original parent
		models.append(parent.duplicate(true))

		# create mutated children
		for j in range(8):

			var child_m1 = mutate_matrix(parent[0], 0.10, 0.10, xavierTyler1)
			var child_m2 = mutate_matrix(parent[1], 0.10, 0.10, xavierTyler2)
			var child_m3 = mutate_matrix(parent[2], 0.10, 0.10, xavierTyler3)

			models.append([
				child_m1,
				child_m2,
				child_m3
			])
				
	# ten entirely new random sets of weights
	for i in range(10):
		var m1 := []
		var m2 := []
		var m3 := []
		
		# xavier glorot initialization for all of the weight matrices
		for i1 in range(weights_input_1):
			var currCol := []
			for o1 in range(weights_output_1):
				currCol.append(randf_range(-xavierTyler1,xavierTyler1))
			m1.append(currCol)
				
		for i2 in range(weights_input_2):
			var currCol := []
			for o2 in range(weights_output_2):
				currCol.append(randf_range(-xavierTyler2,xavierTyler2))
			m2.append(currCol)
				
		for i3 in range(weights_input_3):
			var currCol := []
			for o3 in range(weights_output_3):
				currCol.append(randf_range(-xavierTyler3,xavierTyler3))
			m3.append(currCol)
				
		# filling the set of 3 weight matrices to baseModels
		models.append([m1,m2,m3])

	return models

func mutate_matrix(matrix: Array, mutation_rate: float, sigma: float, xavierTyler: float) -> Array:
	var new_matrix = matrix.duplicate(true)

	for i in range(new_matrix.size()):
		for j in range(new_matrix[i].size()):

			# mutate only some weights
			if randf() < mutation_rate:

				# apply gaussian noise
				new_matrix[i][j] += (new_matrix[i][j] * randfn(0.0, sigma))
				new_matrix[i][j] += randfn(0.0, sigma * 0.01)
				new_matrix[i][j] = clamp(new_matrix[i][j], -xavierTyler * 3.0, xavierTyler * 3.0)

	return new_matrix
#endregion

#region ball 
func _on_ball_spawning_timer_timeout() -> void:
	if simulation_running:
		var screen_size = get_tree().root.size  # half-width / half-height
		var pos_init_ball : Vector2
		var side = randi() % 4

		
		match side:
			# top
			0: pos_init_ball = Vector2(randf() * screen_size.x, 0)
			# bottom
			1: pos_init_ball = Vector2(randf() * screen_size.x, screen_size.y)
			# left
			2: pos_init_ball = Vector2(0, randf() * screen_size.y)
			# right
			3: pos_init_ball = Vector2(screen_size.x, randf() * screen_size.y)
		var newBall = Ball.new()
		newBall = newBall.BallScene.instantiate()
		newBall.initialize(pos_init_ball.x,pos_init_ball.y,randi_range(botSpeed,botSpeed*2),b)
		add_child(newBall)
		allBalls.append(newBall)
#endregion

#region helpers
func is_offscreen(pos: Vector2) -> bool:
	var screen_size = get_tree().root.size
	return (pos.x < 0 || 
			pos.x > screen_size.x || 
			pos.y < 0 || 
			pos.y > screen_size.y )
#endregion
