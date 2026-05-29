extends Node2D

class_name Ball

var SPEED : float
var direction : Vector2
var starting_X : float
var starting_Y : float

@onready var this = $"."


func _init(startingX : float, startingY : float, SPEED : float, target):
	this.SPEED = SPEED
	this.starting_X = startingX
	this.starting_Y = startingY
	
	var aimX : float = target.getX() + randf_range(-20,20)
	var aimY : float = target.getY() + randf_range(-20,20)
	var rawDir : Vector2 = Vector2(aimX,aimY) - Vector2(startingX,startingY)
	this.direction = rawDir.normalized()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
