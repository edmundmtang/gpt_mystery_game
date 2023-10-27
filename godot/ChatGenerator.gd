extends Node

var openai_api: OpenAI_API
var context: Dictionary
var messages: Array[Dictionary]
var player_name: String = "Anne Holloway"

var retry_counter := 0

enum TextType {
    CONVERSATION,
    DESCRIPTION,
    ACTION
}

signal display_text(content: Dictionary, type: int)

func _ready() -> void:
    openai_api = OpenAI_API.new()
    add_child(openai_api)
    load_context("context.json")
    insert_player_name()

#    var a_message = format_input("Hello. I am Detective Anne Holloway.", TextType.CONVERSATION)
#
#    messages.append(a_message)
#
#    continue_text(TextType.CONVERSATION)

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

func format_input(text: String, type: int) -> Dictionary:
    var content: String
    if type == TextType.CONVERSATION:
        content = "{\n\"speaker\": \"Detective " + player_name + "\",\n\"content\": \"" + text + "\"\n}"
    elif type == TextType.DESCRIPTION:
        content = "I examine " + text
    else:
        push_error("Invalid text type provided.")
    return {"role": "user", "content": content}

func format_output(text: String) -> Dictionary:
    return { "role": "assistant", "content": text}

func prepare_messages(type: int) -> Array:
    # Format messages for chat completion call
    var res = []
    res.append({
        "role": "system",
        "content": get_base_context(type)
    })
    res.append_array(messages)
    return res

func get_base_context(type: int) -> String:
    var res: String
    if type == TextType.CONVERSATION:
        res = context["base"] + "\n" + context["conversation"] + "\n" + context["extra"]
    elif type == TextType.DESCRIPTION:
        res = context["base"] + "\n" + context["description"] + "\n" + context["extra"]
    else:
        push_error("Invalid text type provided.")
    return res

func continue_text(type: int) -> void:
    var message_array := prepare_messages(type)
    openai_api.do_chat_completion(message_array)
    var new_message = await openai_api.chat_response
    if verify_output_message(new_message["content"], type):
        # True: add to the ongoing list of messages and then do something to display
        messages.append(new_message)
    else:
        # False: increase the retry_counter -> if too high push_error
        # otherwise, call continue_text again & hope we randomly do better
        retry_counter += 1
        if retry_counter > 3:
            push_error("Failed to generate a properly formatted response after 3 attempts")
        continue_text(type)
    retry_counter = 0

func verify_output_message(message, type) -> bool:
    # Take JSON string and verify that it has the necessary keys
    var data = JSON.parse_string(message)
    var targets := []
    if type == TextType.CONVERSATION:
        targets = ["speaker", "status", "content"]
    elif type == TextType.DESCRIPTION:
        targets = ["description"]
    else:
        push_error("Invalid text type provided.")
        return false
    for target in targets:
        for item in data:
            if target in item.keys():
                pass
            else:
                return false
    return true
