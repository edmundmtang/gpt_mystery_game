class_name ChatGenerator
extends Node

var openai_api: OpenAI_API
var retry_counter := 0

enum TextType {
    CONVERSATION,
    DESCRIPTION,
    SUMMARY,
    ACTION
}

signal new_input_message(text: String, type: int)
signal new_output_message(text: String, type: int)

func _ready() -> void:
    openai_api = OpenAI_API.new()
    add_child(openai_api)

func format_input(text: String, type: int) -> Dictionary:
    var content: String
    if type == TextType.CONVERSATION:
        content = "{\n\"speaker\": \"Detective " + GameState.player_name + "\",\n\"content\": \"" + text + "\"\n}"
    elif type == TextType.DESCRIPTION:
        content = "I examine " + text
    else:
        push_error("Invalid text type provided.")
    return {"role": "user", "content": content}

func format_output(text: String) -> Dictionary:
    return { "role": "assistant", "content": text}

func add_input_message(text: String, type: int) -> void:
    var new_message := format_input(text, type)
    new_input_message.emit(new_message, type)

func prepare_messages(type: int) -> Array:
    # Format messages for chat completion call
    var res = []
    res.append({
        "role": "system",
        "content": get_base_context(type)
    })
    res.append_array(GameState.messages)
    return res

func get_base_context(type: int) -> String:
    var res: String
    if type == TextType.CONVERSATION:
        res = GameState.context["base"] + "\n" + GameState.context["conversation"] + "\n" + GameState.context["extra"]
    elif type == TextType.DESCRIPTION:
        res = GameState.context["base"] + "\n" + GameState.context["description"] + "\n" + GameState.context["extra"]
    else:
        push_error("Invalid text type provided.")
    return res

func continue_text(type: int) -> void:
    var message_array := prepare_messages(type)
    openai_api.do_chat_completion(message_array)
    var new_message = await openai_api.chat_response
    if verify_output_message(new_message["content"], type):
        # True: add to the ongoing list of messages and then do something to display
        new_output_message.emit(new_message)
    else:
        # False: increase the retry_counter -> if too high push_error
        # otherwise, call continue_text again & hope we randomly do better
        retry_counter += 1
        if retry_counter > 3:
            push_error("Failed to generate a properly formatted response after 3 attempts")
            # To-Do Instead of pushing an error, show a message suggesting the
            # user attempt to reword their request while also removing the most
            # recent request
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
