extends Node

var debug := true

var context: Dictionary
var messages: Array[Dictionary]
var display_messages: Array
var display_index := -1
var max_display_index := -1
var player_name: String
var has_unread_messages := false
var generating_output := false
var is_on_information := false # displaying information text

func _ready() -> void:
    load_context("context.json")

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

func fetch_display_message() -> String:
    return display_messages[display_index]

func add_display_message(message: String) -> void:
    display_messages.append(message)
    max_display_index += 1

func go_previous() -> void:
    if GameState.is_on_information:
        GameState.is_on_information = false
        return
    display_index -= 1
    if display_index < 0: display_index = 0

func go_next() -> void:
    if GameState.is_on_information:
        GameState.is_on_information = false
        return
    display_index += 1
    if display_index > max_display_index: display_index = max_display_index

func go_to(index: int) -> void:
    display_index = clampi(index, 0, max_display_index)

func restart_game() -> void:
    load_context("context.json")
    messages = []
    display_messages = []
    display_index = -1
    player_name = ""
