import generator
import re

def request_name():
    # Ask the user for their name.
    generator.player_name = input("You are a detective. Type your name and press Enter: ").strip()
    print("")
    generator.replace_name()
    return

instructions = """/help           : Show available commands.
/say [text]     : Say something. [text] is what you're saying.
/examine [text] : Examine something. [text] is the thing to examine."""

def introduction():
    # Prints introduction to the game and provides instructions on how to interact with the game
    # /say - the main character speaks
    # /examine - the main character examines something
    # 
    introduction_text = "The setting is a picturesque town in the countryside. It is the late 19th century and you are the famous detective " + generator.player_name + ". You happen to be traveling through town when news reaches you of a theft at the Thornton Manor. Your aide is called upon to solve this mystery.\n"
    gradual_print(introduction_text)
    input("Press Enter to continue...")

    instruction_text = "\nTo interact with the scenario you will need to type out all of your commands following a particular format. All commands begin with a \"/\", followed by the command and then instructions. For example, if you want to introduce yourself, the command is:\n\n/say Hello, I am Detective Anne Holloway.\n\nYou can interact with the scenario either by saying something or by examining something. To show the available commands, type \"/help\"."
    gradual_print(instruction_text)

def request_input():
    # Requests user provide input. Then parses input into either a conversation request or a description request
    global debug
    user_input = input("\n>>> ").strip()
    if user_input == '':
        print("\nNo command found. Please try again. Type \"/help\" for a list of commands.")
        return
    input_list = user_input.split()
    command = input_list.pop(0).lower()
    command_body = ' '.join(input_list)
    print()
    match command:
        case "/help":
            print(instructions)
        case "/say":
            output = generator.continue_text(command_body, "conversation")
            # parsed_output = parse_output(output)
            parsed_output = output
            if debug:
                return
            gradual_print(parsed_output)
        case "/examine":
            output = generator.continue_text(command_body, "description")
            # parsed_output = parse_output(output)
            parsed_output = output
            if debug:
                return
            gradual_print(parsed_output)
        case "/breakpoint":
            if debug:
                print("Breakpoint requested.")
        case _:
            gradual_print("/nIncorrect command. Type \"/help\" for a list of commands.")

def parse_output(generator_output):
    # Take the chat generation json output and parses it to be easier to read
    return

def gradual_print(text):
    # Processes print requests gradually to print words one-by-one
    print(text)

if __name__ == "__main__":
    # To-Do: put context and messages back into the generator object and have the generator be the model of the system
    # To-Do: main will be the controller and view

    debug = True
    if debug:
        generator.debug = True

    generator.caching = False
    if generator.caching:
        generator.cache = {}
        generator.load_cache()

    generator.initialize()
    request_name()
    generator.replace_name()

    introduction()

    while True:
        request_input()

    print("END") 