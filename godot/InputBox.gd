extends MarginContainer

signal command_event(text: String, type: int)
signal navigation_event(event_id: int)
@onready var text_box = $VBoxContainer/ScrollContainer/TextEdit

var instructions := """=== Text Commands ===
/help           : Show available commands.
/say [text]     : Say something. [text] is what you're saying.
/examine [text] : Examine something. [text] is the thing to examine.
/previous       : Go to the previous page in the story.
/next           : Go to the next page in the story.
/current        : Go to the most recent page in the story.
/summary        : Generate a summary of events so far.
/exit           : Get a summary of the ending then exit the game.

=== Hotkeys ===
Enter           : Send command.
CTRL+Backspace  : Go to the previous page in the story.
CTRL+Enter      : Go to the next page in the story."""

func process_command() -> void:
    var input_array := Array(text_box.text.strip_edges().split(" "))
    var command : String = input_array.pop_front().to_lower()
    var command_text = " ".join(input_array)
    if GameState.debug:
        print("COMMAND: [", command, "]")
        print("RAW TEXT: [", command_text, "]")
    match command:
        "/help":
            print(instructions)
        "/say":
            var text_type = ChatGenerator.TextType.CONVERSATION
            command_event.emit(command_text, text_type)
        "/examine":
            var text_type = ChatGenerator.TextType.DESCRIPTION
            command_event.emit(command_text, text_type)
        "/previous":
            navigation_event.emit(DisplayBox.navigation.PREVIOUS)
        "/next":
            navigation_event.emit(DisplayBox.navigation.NEXT)
        "/current":
            navigation_event.emit(DisplayBox.navigation.CURRENT)
        "/summary":
            navigation_event.emit(DisplayBox.navigation.SUMMARY)
        "/exit":
            navigation_event.emit(DisplayBox.navigation.EXIT)
    call_deferred("clear_text")

func clear_text() -> void:
    text_box.clear()
