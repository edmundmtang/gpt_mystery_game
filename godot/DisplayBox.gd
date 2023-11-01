class_name DisplayBox
extends MarginContainer

var conversation: Array # An array of the messages that should be displayed.
@onready var text_box = %RichTextLabel

enum navigation {
    HELP,
    PREVIOUS,
    NEXT,
    CURRENT,
    SUMMARY,
    EXIT,
}

func update_display(message: Dictionary) -> void:
    # parse the dictionary of text information in message and then
    # change what is displayed in text_box
#    text_box.text =
    pass
