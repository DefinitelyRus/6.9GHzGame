class_name Level
extends Node2D

# ---------- DOMAIN CONTROL ----------
@onready var camera: CameraManager = CameraManager.instance
@onready var real_domain: Domain = $RealDomain
@onready var fantasy_domain: Domain = $fantasy_domain
var active_domain: Domain
var _using_fantasy_domain: bool = false


func use_fantasy_domain(enable: bool) -> void:
	# TODO: Write logic to swap over to/from the fantasy domain.
	if enable:
		active_domain = fantasy_domain

		camera.visibility_layer
		pass

	else:
		active_domain = real_domain
		pass



	_using_fantasy_domain = enable
	return


func toggle_domain() -> void:
	if _using_fantasy_domain: use_fantasy_domain(false)
	else: use_fantasy_domain(true)
	return
