extends MarginContainer

# Main is acting as the input bus, but we might create a separate
# node specifically for handling inputs later

@onready var display_box = $Display/DisplayBox
@onready var input_box = $Display/InputBox
@onready var chat_generator = $ChatGenerator

func _input(event) -> void:
    if event is InputEventKey:
        parse_key_input(event)

func parse_key_input(input_event) -> void:
    if input_event.echo == true:
        return
    if input_event.pressed == false:
        return
    if input_event.keycode == 4194309: # Enter key
        if input_event.ctrl_pressed == true:
            print("Go forward in messages")
            handle_navigation_event(DisplayBox.navigation.NEXT)
        else:
            if input_event.shift_pressed == true:
                # Actually do nothing because if we're in the text box
                # then we'd just make a new line
                pass
            else:
                # Take the text in the input box and use it as a command
                # Then clear the text box
                print("Enter command")
                input_box.process_command()
                pass
    if input_event.keycode == 4194308: # Backspace key
        if input_event.ctrl_pressed == true:
            # Go back in messsages
            print("Go back in messages")
            handle_navigation_event(DisplayBox.navigation.PREVIOUS)

func _ready() -> void:
    get_tree().get_root().min_size = Vector2i(350, 400) # window min size
    input_box.command_event.connect(
        func(text: String, type: int) -> void:
            chat_generator.add_input_message(text, type)
    )
    input_box.navigation_event.connect(
        func(type: int) -> void:
            handle_navigation_event(type)
    )
    chat_generator.new_display_message.connect(
        func(messages: Array[Dictionary], type: int) -> void:
            display_box.add_display_messages(messages, type)
    )
    chat_generator.new_input_message.connect(
        func(message: Dictionary, type: int) -> void:
            GameState.messages.append(message)
            chat_generator.continue_text(type)
    )
    chat_generator.new_output_message.connect(
        func(message: Dictionary, _type: int) -> void:
            GameState.messages.append(message)
    )

func handle_navigation_event(type: int) -> void:
    match type:
        DisplayBox.navigation.INSTRUCTIONS:
            display_box.show_instructions()
        DisplayBox.navigation.PREVIOUS:
            GameState.go_previous()
            display_box.update_display()
        DisplayBox.navigation.NEXT:
            GameState.go_next()
            display_box.update_display()
        DisplayBox.navigation.CURRENT:
            pass
        DisplayBox.navigation.SUMMARY:
            pass
        DisplayBox.navigation.RESTART:
            pass
        DisplayBox.navigation.EXIT:
            pass
