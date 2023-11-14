class_name DisplayBox
extends MarginContainer

var conversation: Array # An array of the messages that should be displayed.
var introduction: String = "The setting is during the 19th century at a picturesque town in the countryside. You are a famous detective that happened to be traveling through town when news reaches you of a theft at Thornton Manor. Your aid is called upon to solve this mystery.\n\nBefore we begin, please type your name below and press enter."
var instruction_index := 999 # Initialize to arbitrarily large number
var is_growing_text := false
var ticks := 0
var tick_spacing := 1
var sound_tick := 0
var sound_spacing := 4
var is_generating_description := false

@onready var text_box := %RichTextLabel
@onready var back_button := %BackButton
@onready var next_button := %NextButton
@onready var text_panel := $VBoxContainer/ScrollContainer/PanelContainer
@onready var text_scroll := $VBoxContainer/ScrollContainer
@onready var typing_sound := %TypingSound

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
    INVALID,
}

const help_text := """[center]=== Text Commands ===[/center]
/help - Show available commands.
/say [text] - Say something. [text] is what you're saying.
/examine [text] - Examine something. [text] is the thing to examine.
/previous - Go to the previous page in the story.
/next - Go to the next page in the story.
/current - Go to the most recent page in the story.
/summary - Generate a summary of events so far.
/restart - Restart the scenario.
/exit - Get a summary of the ending then exit the game.

[center]=== Hotkeys ===[/center]
Enter - Send command.
Ctrl+Backspace - Go to the previous page in the story.
Ctrl+Enter - Go to the next page in the story.
Ctrl+Shift+Enter - Go to the newest page in the story."""

const error_text := "An error was encountered while attempting to generate a response. Please reword your command and try again."

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
    text_panel.resized.connect(
        func() -> void:
            text_scroll.scroll_vertical += 50 # Arbitrarily num
    )

    back_button.button_down.connect(typing_sound.play_random)
    back_button.button_up.connect(typing_sound.play_random)
    next_button.button_down.connect(typing_sound.play_random)
    next_button.button_up.connect(typing_sound.play_random)

func start_scenario():
    # Clear player name
    # Set input box to state for receiving a new name
    add_display_messages([{"description": introduction}], ChatGenerator.TextType.INFORMATION)
    do_update_navigation()

func show_instructions():
    if len(GameState.display_messages) > instruction_index:
        text_box.text = GameState.display_messages[instruction_index]["content"]
    else:
        var instructions: String = "As Detective " + GameState.player_name + ", you have arrived at Thornton Manor to help solve a mysterious theft. To interact with the scenario you will need to type out commands in a particular format in the box below. All commands begin with a slash followed by the command itself then further details or instructions. For example, if you want to introduce yourself, it would look something like this:\n\n/say Hello, I am Detective " + GameState.player_name + ".\n\nYou can interact with the scenario by either saying something (/say) or examining something (/examine). For more commands, hotkeys, and further information, type '/help'."
        add_display_messages([{"description": instructions}], ChatGenerator.TextType.INFORMATION)
        instruction_index = len(GameState.display_messages) - 1 # is the newest message
        GameState.is_on_information = false

func add_display_messages(messages: Array[Dictionary], type: int) -> void:
    # Format and add messages array to GameState.display_messages
    if GameState.last_message_type == ChatGenerator.TextType.DESCRIPTION_REQUEST:
        is_generating_description = true
    else:
        GameState.display_index += 1
    for message in messages:
        var formatted_message = format_message(message, type)
        GameState.add_display_message(formatted_message, type)
    if GameState.display_index < GameState.max_display_index:
        GameState.has_unread_messages = true
    update_display()

func update_display() -> void:
    # change what is displayed in text_box
    # should do this in a gradual manner that looks nice + maybe has sound
    var display_message = GameState.fetch_display_message()
    text_box.text = display_message["content"]
    if display_message["is_new"]:
        is_growing_text = true
        if !is_generating_description:
            text_box.visible_characters = 0
        else:
            is_generating_description = false
    else:
        text_box.visible_characters = -1
        is_growing_text = false
    display_message["is_new"] = false
    if GameState.display_index == GameState.max_display_index:
        GameState.has_unread_messages = false
    update_navigation.emit()

func grow_text() -> void:
    # gradually increase text_box.visible_characters
    text_box.visible_characters += 1
    if text_box.visible_characters >= len(text_box.text):
        is_growing_text = false
    # play sounds while adding text
    # possibly scroll box down if the text gets long

func set_text_full() -> void:
    text_box.visible_characters = -1
    is_growing_text = false

func display_information(type: int) -> void:
    GameState.is_on_information = true
    match type:
        navigation.INSTRUCTIONS:
            show_instructions()
        navigation.HELP:
            text_box.text = help_text
            set_text_full()
        navigation.INVALID:
            text_box.text = error_text
            set_text_full()


func format_message(message: Dictionary, type: int) -> String:
    # take message as a dictionary then format it as BBCode to use in display
    var res: String
    match type:
        ChatGenerator.TextType.DESCRIPTION_REQUEST:
            type = ChatGenerator.TextType.DESCRIPTION
        ChatGenerator.TextType.CONVERSATION_REQUEST:
            type = ChatGenerator.TextType.CONVERSATION
    match type:
        ChatGenerator.TextType.DESCRIPTION:
            res = "[left]" + message["description"] + "[/left]"
        ChatGenerator.TextType.INFORMATION:
            res = "[left]" + message["description"] + "[/left]"
        ChatGenerator.TextType.CONVERSATION:
            res = "[left][u][b]" + message["speaker"] + "[/b][/u]"
            if message.has("status"):
                res += "\n[i]" + message["status"].capitalize() + "[/i]"
            res += "\n" + message["content"] + "[/left]"
    return res

func do_update_navigation() -> void:
    if GameState.debug:
        print("Current Location: ", GameState.display_index + 1, "/", GameState.max_display_index + 1)
    if GameState.display_index <= 0:
        back_button.disabled = true
    else:
        back_button.disabled = false
    if GameState.display_index == GameState.max_display_index:
        next_button.disabled = true
    else:
        next_button.disabled = false

func _physics_process(_delta) -> void:
    # periodically call grow_text() so it doesn't blast all the letters
    if is_growing_text:
        ticks += 1
        sound_tick += 1
        if ticks >= tick_spacing:
            grow_text()
            ticks = 0
        if sound_tick >= sound_spacing:
            typing_sound.play_random()
            sound_tick = 0
