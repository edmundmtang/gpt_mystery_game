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
        if input_event.ctrl_pressed:
            handle_navigation_event(DisplayBox.navigation.NEXT)
            accept_event()
        else:
            if input_event.shift_pressed:
                # Actually do nothing and just make a new line
                pass
            else:
                input_box.process_command()
    if input_event.keycode == 4194308: # Backspace key
        if input_event.ctrl_pressed == true:
            handle_navigation_event(DisplayBox.navigation.BACK)
            accept_event()

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
    display_box.navigation_event.connect(
        func(type: int) -> void:
            handle_navigation_event(type)
    )
    display_box.update_navigation.connect(
        func() -> void:
            input_box.update_confirmation_button()
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
            if GameState.debug:
                print("Navigation Event: INSTRUCTIONS")
        DisplayBox.navigation.BACK:
            GameState.go_previous()
            display_box.update_display()
            if GameState.debug:
                print("Navigation Event: BACK")
        DisplayBox.navigation.NEXT:
            GameState.go_next()
            display_box.update_display()
            if GameState.debug:
                print("Navigation Event: NEXT")
        DisplayBox.navigation.CURRENT:
            if GameState.debug:
                print("Navigation Event: CURRENT")
        DisplayBox.navigation.SUMMARY:
            if GameState.debug:
                print("Navigation Event: SUMMARY")
        DisplayBox.navigation.RESTART:
            if GameState.debug:
                print("Navigation Event: RESTART")
        DisplayBox.navigation.EXIT:
            if GameState.debug:
                print("Navigation Event: EXIT")
