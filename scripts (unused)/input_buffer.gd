class_name InputBuffer
extends Node

@export var default_buffer_time := 50

var buffered_actions := {}

func _process(delta):

	for action in buffered_actions.keys().duplicate():

		buffered_actions[action] -= delta

		if buffered_actions[action] <=0:
			buffered_actions.erase(action)

func buffer_action(action: String, duration := -1.0):
	if duration < 0:
		duration = default_buffer_time

	buffered_actions[action] = duration

func is_buffered(action: String) -> bool:
	return buffered_actions.has(action)

func consume(action: String) -> bool:
	if buffered_actions.has(action):
		buffered_actions.erase(action)
		return true


	return false
