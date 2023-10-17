extends Node

var context: Dictionary
var messages: Array[String]

func _ready() -> void:
    var openai_api = OpenAI_API.new()
    add_child(openai_api)
    openai_api.chat_response.connect(
        func(message) -> void:
            print(message)
    )
    load_context("context.json")

    print(messages)

    messages = ["Hi.", "I'm doing well."]

    print(messages)

func load_context(context_file: String) -> void:
    var json_file = FileAccess.open(context_file, FileAccess.READ)
    assert(json_file != null, "Something went wrong loading context file.")
    context = JSON.parse_string(json_file.get_as_text())
