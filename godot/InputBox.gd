extends MarginContainer

signal command_event(text: String, type: int)
signal navigation_event(event_id: int)
@onready var text_box = %TextBox
@onready var send_button = %SendButton

var instructions := """=== Text Commands ===
/help           : Show available commands.
/say [text]     : Say something. [text] is what you're saying.
/examine [text] : Examine something. [text] is the thing to examine.
/previous       : Go to the previous page in the story.
/next           : Go to the next page in the story.
/current        : Go to the most recent page in the story.
/summary        : Generate a summary of events so far.
/restart        : Restart the scenario.
/exit           : Get a summary of the ending then exit the game.

=== Hotkeys ===
Enter           : Send command.
CTRL+Backspace  : Go to the previous page in the story.
CTRL+Enter      : Go to the next page in the story."""

func _ready() -> void:
    set_waiting_for_player_name()

func process_command() -> void:
    if GameState.player_name == "":
        update_player_name()
        set_default_placeholder_text()
        navigation_event.emit(DisplayBox.navigation.INSTRUCTIONS)
    else:
        var input_array := Array(text_box.text.strip_edges().split(" "))
        var command : String = input_array.pop_front().to_lower()
        var command_text = " ".join(input_array)
        if GameState.debug:
            print("COMMAND: [", command, "]")
            print("RAW TEXT: [", command_text, "]")
        if command == "/say" or command == "/examine" or command == "":
            if GameState.has_unread_messages:
                accept_event()
                navigation_event.emit(DisplayBox.navigation.NEXT)
                return
            elif GameState.generating_output:
                accept_event()
                return
        match command:
            "/help":
                print(instructions)
            "/say":
                GameState.generating_output = true
                var text_type = ChatGenerator.TextType.CONVERSATION
                command_event.emit(command_text, text_type)
            "/examine":
                GameState.generating_output = true
                var text_type = ChatGenerator.TextType.DESCRIPTION
                command_event.emit(command_text, text_type)
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
                    print("Invalid command")
                    pass
    call_deferred("clear_text")

func update_player_name():
    GameState.player_name = " ".join(Array(text_box.text.strip_edges().split(" "))) # Clean white space
    GameState.insert_player_name()

func clear_text() -> void:
    text_box.clear()

func set_waiting_for_player_name():
    text_box.placeholder_text = "Enter player name here."

func set_default_placeholder_text():
    text_box.placeholder_text = "Waiting for command...\nUse /help to see commands and other info."

func update_confirmation_button() -> void:
    if GameState.has_unread_messages:
        send_button.text = "Continue"
    else:
        send_button.text = "Send"
