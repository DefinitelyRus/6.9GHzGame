class_name Log
extends Node

enum Mode { MESSAGE, WARNING, ERROR }


static func message(msg: String, mode: Mode, print_trace: bool) -> void:
	var stack: Array[Dictionary] = get_stack()
	var stack_is_empty: bool = stack.is_empty()
	
	if stack_is_empty:
		_print_fallback(msg, mode)
		return

	var relevant_frames: Array[Dictionary] = _get_relevant_frames(stack)
	var frames_size: int = relevant_frames.size()
	var last_index: int = frames_size - 1
	
	for i: int in range(frames_size):
		var frame: Dictionary = relevant_frames[i]
		var is_last: bool = (i == last_index)
		var depth: int = i
		
		var indent: String = " ".repeat(depth)
		var is_root_depth: bool = (depth == 0)
		
		if is_root_depth:
			var newline: String = "\n"
			indent = newline + indent
			pass
		
		# Format: [Script.gd:Line]
		var frame_source: String = frame.source
		var file_name: String = frame_source.get_file()
		var frame_line: int = frame.line
		var prefix: String = "%s[%s:%d]" % [indent, file_name, frame_line]
		
		if is_last:
			var severity: String = ""
			
			match mode:
				Mode.WARNING:
					severity = "WARN: "
					pass
					
				Mode.ERROR:
					severity = "ERROR: "
					pass
			
			var final_msg: String = "%s %s%s" % [prefix, severity, msg]
			
			# Push to debugger
			match mode:
				Mode.MESSAGE:
					print(final_msg)
					pass
					
				Mode.WARNING:
					push_warning(final_msg)
					pass
					
				Mode.ERROR:
					push_error(final_msg)
					pass
			pass
			
		elif print_trace:
			print(prefix)
			pass
		pass
	return


static func me(msg_or_factory: Variant, enabled: bool = true, print_trace: bool = false) -> void:
	if not enabled:
		return
		
	var msg: String
	var is_callable: bool = typeof(msg_or_factory) == TYPE_CALLABLE
	
	if is_callable:
		var call_result: Variant = msg_or_factory.call()
		msg = str(call_result)
		pass
	else:
		msg = str(msg_or_factory)
		pass
		
	message(msg, Mode.MESSAGE, print_trace)
	return


static func warn(msg_or_factory: Variant, enabled: bool = true, print_trace: bool = false) -> void:
	if not enabled:
		return
		
	var msg: String
	var is_callable: bool = typeof(msg_or_factory) == TYPE_CALLABLE
	
	if is_callable:
		var call_result: Variant = msg_or_factory.call()
		msg = str(call_result)
		pass
	else:
		msg = str(msg_or_factory)
		pass
		
	message(msg, Mode.WARNING, print_trace)
	return


static func err(msg_or_factory: Variant, enabled: bool = true, print_trace: bool = false) -> void:
	if not enabled:
		return
		
	var msg: String
	var is_callable: bool = typeof(msg_or_factory) == TYPE_CALLABLE
	
	if is_callable:
		var call_result: Variant = msg_or_factory.call()
		msg = str(call_result)
		pass
	else:
		msg = str(msg_or_factory)
		pass
		
	message(msg, Mode.ERROR, print_trace)
	return


static func _get_relevant_frames(stack: Array[Dictionary]) -> Array[Dictionary]:
	var relevant: Array[Dictionary] = []

	for frame: Dictionary in stack:
		var source: String = frame.source as String
		var is_empty: bool = source.is_empty()
		var ends_with_log: bool = source.ends_with("Log.gd")

		var should_skip: bool = is_empty or ends_with_log
		if should_skip:
			continue

		relevant.push_front(frame)
		pass

	return relevant


static func _print_fallback(msg: String, mode: Mode) -> void:
	match mode:
		Mode.MESSAGE:
			print(msg)
			pass
		Mode.WARNING:
			push_warning(msg)
			pass
		Mode.ERROR:
			push_error(msg)
			pass
			
	return
