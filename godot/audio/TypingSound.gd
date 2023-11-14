extends Node

@onready var sound_list := get_children()
@onready var max_index : int = len(sound_list) - 1

func _ready() -> void:
    pass

func play_sound(index: int) -> void:
    var sound = sound_list[index]
    sound.play()

func play_random() -> void:
    play_sound(randi_range(0, max_index))
