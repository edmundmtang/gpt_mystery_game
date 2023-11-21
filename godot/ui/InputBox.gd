class_name InputBox
extends MarginContainer

signal command_event(text: String, type: int)
signal navigation_event(event_id: int)
signal send_button_pressed()
@onready var text_box = %TextBox
@onready var send_button = %SendButton
@onready var typing_sound = %TypingSound

enum placeholder_state {
    DEFAULT,
    NAME,
    INVALID
}

func _ready() -> void:
    set_start_state()
    send_button.button_down.connect(typing_sound.play_random)
    send_button.button_up.connect(typing_sound.play_random)
    send_button.pressed.connect(
        func() -> void:
            send_button_pressed.emit()
    )

func set_start_state() -> void:
    set_placeholder_text(placeholder_state.NAME)

func process_command() -> void:
    typing_sound.play_random()
    set_placeholder_text(placeholder_state.DEFAULT)
    if GameState.player_name == "":
        update_player_name()
    else:
        var input_array := Array(text_box.text.strip_edges().split(" "))
        var command : String = input_array.pop_front().to_lower()
        var command_text = " ".join(input_array)
        if command == "/say" or command == "/examine" or command == "":
            if GameState.has_unread_messages:
                accept_event()
                navigation_event.emit(DisplayBox.navigation.NEXT)
                return
            elif GameState.generating_output:
                accept_event()
                return
        if GameState.debug:
            print("Command: [", command, "] [", command_text, "]")
        match command:
            "/say":
                GameState.generating_output = true
                var text_type = ChatGenerator.TextType.CONVERSATION_REQUEST
                command_event.emit(command_text, text_type)
            "/examine":
                GameState.generating_output = true
                var text_type = ChatGenerator.TextType.DESCRIPTION_REQUEST
                command_event.emit(command_text, text_type)
            "/instructions":
                navigation_event.emit(DisplayBox.navigation.INSTRUCTIONS)
            "/help":
                navigation_event.emit(DisplayBox.navigation.HELP)
            "/previous":
                navigation_event.emit(DisplayBox.navigation.BACK)
            "/next":
                navigation_event.emit(DisplayBox.navigation.NEXT)
            "/current":
                navigation_event.emit(DisplayBox.navigation.CURRENT)
            "/summary":
                navigation_event.emit(DisplayBox.navigation.SUMMARY)
            "/restart":
                navigation_event.emit(DisplayBox.navigation.RESTART)
            "/exit":
                navigation_event.emit(DisplayBox.navigation.EXIT)
            _:
                if GameState.has_unread_messages:
                    accept_event()
                    navigation_event.emit(DisplayBox.navigation.NEXT)
                    return
                else:
                    navigation_event.emit(DisplayBox.navigation.INVALID)
    call_deferred("clear_text")

func update_player_name() -> void:
    GameState.player_name = " ".join(Array(text_box.text.strip_edges().split(" "))) # Clean white space
    GameState.insert_player_name()
    if GameState.player_name == "":
        # Raise some issue with not having a proper name and do not advance
        print("No player name set. Please try again.")
        set_placeholder_text(placeholder_state.NAME)
        return
    navigation_event.emit(DisplayBox.navigation.INSTRUCTIONS)
    if GameState.debug:
        print("Player name set to: " + GameState.player_name)

func clear_text() -> void:
    text_box.clear()

func set_placeholder_text(type: int) -> void:
    match type:
        placeholder_state.DEFAULT:
            text_box.placeholder_text = "Waiting for command...\nUse /help to see commands and other info."
        placeholder_state.NAME:
            text_box.placeholder_text = "Enter player name here."
        placeholder_state.INVALID:
            text_box.placeholder_text = """Unable to process command. Please rewrite and try again.\nUse \"help\" for more information."""

func update_confirmation_button() -> void:
    if GameState.has_unread_messages:
        send_button.text = "Continue"
    else:
        send_button.text = "Send"
