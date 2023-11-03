class_name DisplayBox
extends MarginContainer

var conversation: Array # An array of the messages that should be displayed.
var introduction: String = "The setting is during the 19th century at a picturesque town in the countryside. You are a famous detective that happened to be traveling through town when news reaches you of a theft at Thornton Manor. Your aid is called upon to solve this mystery.\n\nBefore we begin, please type your name below and press enter."
var instruction_index := 999 # Initialize to arbitrarily large number

@onready var text_box = %RichTextLabel
@onready var back_button = %BackButton
@onready var next_button = %NextButton

signal navigation_event(type: int)
signal update_navigation()

enum navigation {
    INSTRUCTIONS,
    HELP,
    BACK,
    NEXT,
    CURRENT,
    SUMMARY,
    RESTART,
    EXIT,
}

func _ready():
    start_scenario()
    update_navigation.connect(do_update_navigation)
    back_button.pressed.connect(
        func() -> void:
            navigation_event.emit(navigation.BACK)
    )
    next_button.pressed.connect(
        func() -> void:
            navigation_event.emit(navigation.NEXT)
    )

func start_scenario():
    # Clear player name
    # Set input box to state for receiving a new name
    add_display_messages([{"description": introduction}], ChatGenerator.TextType.DESCRIPTION)

func show_instructions():
    if len(GameState.display_messages) > instruction_index:
        GameState.go_to(instruction_index) # Instructions should always be at index 1
        update_display()
    else:
        var instructions: String = "As Detective " + GameState.player_name + ", you have arrived at Thornton Manor to help solve a mysterious theft. To interact with the scenario you will need to type out commands in a particular format in the box below. All commands begin with a slash followed by the command itself then further details or instructions. For example, if you want to introduce yourself, it would look something like this:\n\n/say Hello, I am Detective " + GameState.player_name + ".\n\nYou can interact with the scenario by either saying something (/say) or examining something (/examine). For more commands, hotkeys, and further information, type '/help'."
        add_display_messages([{"description": instructions}], ChatGenerator.TextType.DESCRIPTION)
        instruction_index = len(GameState.display_messages) - 1 # is the newest message

func add_display_messages(messages: Array[Dictionary], type: int) -> void:
    # Format and add messages array to GameState.display_messages
    for message in messages:
        var formatted_message = format_message(message, type)
        GameState.add_display_message(formatted_message)
    # Figure out the appropriate max index based on number of new messages
    # Update display message index by 1 then use update_display() to update view
    GameState.display_index += 1
    if GameState.display_index < GameState.max_display_index:
        GameState.has_unread_messages = true
    update_display()

func update_display() -> void:
    # change what is displayed in text_box
    # should do this in a gradual manner that looks nice + maybe has sound
    text_box.text = GameState.fetch_display_message()
    if GameState.display_index == GameState.max_display_index:
        GameState.has_unread_messages = false
    update_navigation.emit()

func format_message(message: Dictionary, type: int) -> String:
    # take message as a dictionary then format it as BBCode to use in display
    var res: String
    match type:
        ChatGenerator.TextType.DESCRIPTION:
            res = "[left]" + message["description"] + "[/left]"
        ChatGenerator.TextType.CONVERSATION:
            res = "[left][u][b]" + message["speaker"] + "[/b][/u]"
            if message.has("status"):
                res += "\n[i]" + message["status"] + "[/i]"
            res += "\n" + message["content"] + "[/left]"
    return res

func do_update_navigation() -> void:
    if GameState.debug:
        print("Current Location: ", GameState.display_index, "/", GameState.max_display_index)
    if GameState.display_index <= 0:
        back_button.disabled = true
    else:
        back_button.disabled = false
    if GameState.display_index == GameState.max_display_index:
        next_button.disabled = true
    else:
        next_button.disabled = false
