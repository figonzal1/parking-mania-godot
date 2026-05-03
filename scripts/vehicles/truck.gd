extends VehicleBody

@onready var reverse_audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

var _is_reversing: bool = false

func _physics_process(delta: float) -> void:
	super(delta)
	_handle_reverse_audio()

func _handle_reverse_audio() -> void:
	var should_reverse := current_speed < -5.0 or (
		Input.get_action_strength("ui_down") > 0.0 and current_speed < 5.0
	)

	if should_reverse and not _is_reversing:
		if reverse_audio and not reverse_audio.playing:
			reverse_audio.play()
		_is_reversing = true
	elif not should_reverse and _is_reversing:
		if reverse_audio and reverse_audio.playing:
			reverse_audio.stop()
		_is_reversing = false
