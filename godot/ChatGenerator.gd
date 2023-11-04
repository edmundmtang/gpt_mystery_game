class_name ChatGenerator
extends Node

var openai_api: OpenAI_API
var retry_counter := 0

enum TextType {
    INFORMATION,
    CONVERSATION,
    CONVERSATION_REQUEST,
    DESCRIPTION,
    DESCRIPTION_REQUEST,
    SUMMARY,
    ACTION,
    NONE
}

signal new_display_message(text: Array[Dictionary], type: int)
signal new_input_message(text: Dictionary, type: int)
signal new_output_message(text: Dictionary, type: int)

func _ready() -> void:
    openai_api = OpenAI_API.new()
    add_child(openai_api)

func format_input_for_llm(text: String, type: int) -> Dictionary:
    var content: String
    match type:
        TextType.CONVERSATION_REQUEST:
            content = "{\n\"speaker\": \"Detective " + GameState.player_name + "\",\n\"content\": \"" + text + "\"\n}"
        TextType.DESCRIPTION_REQUEST:
            content = "I examine " + text
        _:
            push_error("Invalid text type provided.")
    return {"role": "user", "content": content}

func format_input_for_display(text: String, type: int) -> Array[Dictionary]:
    var res: Array[Dictionary]
    match type:
        TextType.CONVERSATION_REQUEST:
            res = [{"speaker": "Detective " + GameState.player_name,
                "content": text}]
        TextType.DESCRIPTION_REQUEST:
            res = [{"description": "You examine " + text + "."}]
        _:
            push_error("Invalid text type provided.")
    return res

func format_output(text: String) -> Dictionary:
    return { "role": "assistant", "content": text}

func add_input_message(text: String, type: int) -> void:
    var display_message := format_input_for_display(text, type)
    new_display_message.emit(display_message, type)
    var llm_message := format_input_for_llm(text, type)
    new_input_message.emit(llm_message, type)

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
    if type == TextType.CONVERSATION_REQUEST:
        res = GameState.context["base"] + "\n" + GameState.context["conversation"] + "\n" + GameState.context["extra"]
    elif type == TextType.DESCRIPTION_REQUEST:
        res = GameState.context["base"] + "\n" + GameState.context["description"] + "\n" + GameState.context["extra"]
    else:
        push_error("Invalid text type provided.")
    return res

func continue_text(type: int) -> void:
    var message_array := prepare_messages(type)
    openai_api.do_chat_completion(message_array)
    var new_output = await openai_api.chat_response
    var output_type = get_output_type(type)
    if verify_output_message(new_output["content"], output_type):
        # True: add to the ongoing list of messages and then do something to display
        new_display_message.emit(parse_output_for_display(new_output), output_type)
        new_output_message.emit(new_output, output_type)
        GameState.generating_output = false
    else:
        # False: increase the retry_counter -> if too high push_error
        # otherwise, call continue_text again & hope we randomly do better
        retry_counter += 1
        if retry_counter > 3:
            print("Failed to generate a properly formatted response after 3 attempts")
            # To-Do Instead of pushing an error, show a message suggesting the
            # user attempt to reword their request while also removing the most
            # recent request
            DisplayBox.navigation_event.emit(DisplayBox.navigation.LM_ERROR)
        continue_text(type)
    retry_counter = 0

func reduce_context() -> void:
    # Ask LLM to summarize the events so far and then replace existing context
    # with the reduced context
    pass

func summarize_text(is_end: bool = false) -> String:
    # Ask the LLM to summarize the events so far as simple text
    if is_end:
        pass
    else:
        pass
    return ""

func verify_output_message(message, type) -> bool:
    # Take JSON string and verify that it has the necessary keys
    var data = JSON.parse_string(message)
    var targets := []
    print(data)
    if data == null or !(data is Array):
        if GameState.debug:
            print("Output message could not be parsed. Output message below.")
            print(message)
        return false
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

func parse_output_for_display(output: Dictionary) -> Array[Dictionary]:
    var res : Array[Dictionary] = []
    # we're probably struggling to properly parse this output so we'd
    # need to break it down into a couple of steps
    var data = JSON.parse_string(output["content"])
    for item in data:
        res.append(item)
    return res

func get_output_type(type: int) -> int:
    match type:
        TextType.CONVERSATION_REQUEST:
            return TextType.CONVERSATION
        TextType.DESCRIPTION_REQUEST:
            return TextType.DESCRIPTION
        _:
            return TextType.NONE
