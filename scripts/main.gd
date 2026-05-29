extends Node

#region variables
var n = 50
var current_generation = 0
var current_model_index = 0

var baseModels = []
var weightDims = [27,32,32,32,32,5]

var b : Bot
var t : Tallier

var simulation_time = 5.0
var simulation_timer = 0.0

var simulation_running = false
#endregion

#region ready and process
# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	
	t = Tallier.new()
	
	baseModels = fill(weightDims)
	
	start_next_model()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	if !simulation_running:
		return

	simulation_timer += delta

	b.simulate(delta)
	
	t.update(t.getTallyTarget().scoreChange()*delta)
	
	if simulation_timer >= simulation_time:

		simulation_running = false

		t.endTallySession()

		current_model_index += 1

		# Finished all 100 models
		if current_model_index >= baseModels.size():

			finish_generation()

		else:

			start_next_model()
#endregion

#region calling beginning and ending of data tallying and resetting
func start_next_model():

	var model = baseModels[current_model_index]

	var m1 = model[0]
	var m2 = model[1]
	var m3 = model[2]

	if b:
		b.queue_free()
	b = Bot.new(m1, m2, m3)
	add_child(b)

	t.setTallyTarget(b,current_model_index)

	simulation_timer = 0.0
	simulation_running = true

	print("Generation:",
		current_generation,
		"Model:",
		current_model_index)

func finish_generation():

	var top_ten = t.get_top_ten_indices()

	# Your evolution / mutation logic
	var new_models = generate_new_models(top_ten, weightDims)

	baseModels = new_models

	current_generation += 1
	current_model_index = 0

	if current_generation >= n:

		simulation_running = false
		print("Training complete")
		return

	start_next_model()
#endregion

#region model generation
func fill	(dims : Array) -> Array:
	
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
