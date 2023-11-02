class_name DisplayBox
extends MarginContainer

var conversation: Array # An array of the messages that should be displayed.
var introduction: String = "The setting is during the 19th century at a picturesque town in the countryside. You are a famous detective that happened to be traveling through town when news reaches you of a theft at Thornton Manor. Your aid is called upon to solve this mystery.\n\nBefore we begin, please type your name below and press enter."

@onready var text_box = %RichTextLabel

enum navigation {
    HELP,
    PREVIOUS,
    NEXT,
    CURRENT,
    SUMMARY,
    RESTART,
    EXIT,
}

func _ready():
    start_scenario()

func start_scenario():
    # Clear player name
    # Set input box to state for receiving a new name
    multi_update_display([{"description": introduction}], ChatGenerator.TextType.DESCRIPTION)

func multi_update_display(messages: Array[Dictionary], type: int) -> void:
    # Format and add messages array to GameState.display_messages
    for message in messages:
        var formatted_message = format_message(message, type)
        GameState.display_messages.append(formatted_message)
    # Figure out the appropriate max index based on number of new messages
    # Update display message index by 1 then use update_display() to update view
    GameState.display_index += 1
    update_display(GameState.fetch_display_message())

func update_display(message: String) -> void:
    # parse the dictionary of text information in message and then
    # change what is displayed in text_box
    # should do this in a gradual manner that looks nice + maybe has sound
    text_box.text = message

func format_message(message: Dictionary, type: int) -> String:
    # take message as a dictionary then format it as BBCode to use in display
    var res: String
    match type:
        ChatGenerator.TextType.DESCRIPTION:
            res = "[left]" + message["description"] + "[/left]"
    return res

