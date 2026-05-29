extends Node2D

class_name Bot

var mod1 : Array
var mod2 : Array
var mod3 : Array

func _init(m1: Array, m2: Array, m3: Array):
	mod1 = m1
	mod2 = m2
	mod3 = m3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# moves around according to the collected data of the most dangerous balls
func simulate(inp : Array) -> void:
	pass
	
func scoreChange() -> float:
	return 0
