extends Node

var debug := true

var context: Dictionary
var messages: Array[Dictionary]
var display_messages: Array
var display_index := 0
var player_name: String = "Anne Holloway"

func _ready() -> void:
    load_context("context.json")
    insert_player_name()

func load_context(context_file: String) -> void:
    var json_file = FileAccess.open(context_file, FileAccess.READ)
    assert(json_file != null, "Something went wrong loading context file.")
    context = JSON.parse_string(json_file.get_as_text())
    context["extra"] = ""

func insert_player_name() -> void:
    var regex = RegEx.new()
    regex.compile("\\[player name\\]")
    context["base"] = regex.sub(context["base"], player_name, true)
    context["conversation"] = regex.sub(context["conversation"], player_name, true)
    context["description"] = regex.sub(context["description"], player_name, true)

func add_new_output_message(new_message: String) -> void:
    messages.append(new_message)
    # parse new_message and also add to display messages
