class_name Level
extends Node2D

# ---------- DOMAIN CONTROL ----------
@onready var camera: CameraManager = CameraManager.instance
@onready var real_domain: Domain = $RealDomain
@onready var fantasy_domain: Domain = $fantasy_domain
var active_domain: Domain
var _using_fantasy_domain: bool = false


## Sets the active domain to the fantasy domain.
func use_fantasy_domain(enable: bool) -> void:
	if enable:
		fantasy_domain.set_enabled(true)
		real_domain.set_enabled(false)
		active_domain = fantasy_domain
		pass

	else:
		fantasy_domain.set_enabled(false)
		real_domain.set_enabled(true)
		active_domain = real_domain
		pass

	_using_fantasy_domain = enable
	return
