import generator
import json
import string
import argparse
import re
from time import sleep

def request_name():
    # Ask the user for their name.
    print_by_word("You are a detective. Type your name and press Enter: ")
    generator.player_name = input().strip()
    print("")
    generator.replace_name()
    return

instructions = """/help           : Show available commands.
/say [text]     : Say something. [text] is what you're saying.
/examine [text] : Examine something. [text] is the thing to examine.
/exit           : Get a summary of the ending then exit the game."""

debug_instructions = """\n=== Debug Commands ===
/breakpoint     : If using an IDE, can trigger a breakpoint.
/summarize      : Force a generator.summarize() call."""

def introduction():
    # Prints introduction to the game and provides instructions on how to interact with the game
    # /say - the main character speaks
    # /examine - the main character examines something
    # 
    introduction_text = "The setting is a picturesque town in the countryside. It is the late 19th century and you are the famous detective " + generator.player_name + ". You happen to be traveling through town when news reaches you of a theft at the Thornton Manor. Your aid is called upon to solve this mystery."
    print_by_word(introduction_text)
    print_by_word("\n\nPress Enter to continue >>>")
    input()

    instruction_text = "\nTo interact with the scenario you will need to type out all of your commands following a particular format. When you see >>>, the game is waiting for an input. All commands begin with a \"/\", followed by the command and then instructions. For example, if you want to introduce yourself, the command is:\n\n>>> /say Hello, I am Detective Anne Holloway.\n\nYou can interact with the scenario either by saying something or by examining something. To show the available commands, type \"/help\"."
    print_by_word(instruction_text)

def request_input():
    # Requests user provide input. Then parses input into either a conversation request or a description request
    global debug
    user_input = input("\n\n>>> ").strip()
    if user_input == '':
        print("\nNo command found. Please try again. Type \"/help\" for a list of commands.")
        return
    input_list = user_input.split()
    command = input_list.pop(0).lower()
    command_body = ' '.join(input_list)
    print()
    match command:
        case "/help":
            print(instructions, end = '')
            if debug:
                print(debug_instructions, end = '')
            return 0
        case "/say":
            text_type = "conversation"
        case "/examine":
            text_type = "description"
        case "/breakpoint":
            if debug:
                print("Breakpoint requested.")
            else:
                incorrect_command()
            return 0
        case "/summarize":
            if debug:
                generator.summarize_text()
            else:
                incorrect_command()
            return 0
        case "/exit":
            return 1
        case _:
            incorrect_command()
            return 0
    output = generator.continue_text(command_body, text_type)
    parsed_output = parse_output(output, text_type)
    if debug:
        return 0
    print_by_block(parsed_output)
    return 0

def incorrect_command():
    print_by_block(["Incorrect command. Type \"/help\" for a list of commands."])

def parse_output(generator_output, text_type):
    # Take the chat generation json output and parses it to be easier to read
    json_object = json.loads(generator_output)
    output_list = []
    for item in json_object:
        if text_type == "conversation":
            text_block = "[" + item["speaker"] + "]\n*" + string.capwords(item["status"]) + "*\n" + item["content"]
        elif text_type == "description":
            text_block = item["description"]
        else:
            raise Exception("Invalid text_type provided to parse_output().")
        output_list.append(text_block)
    return output_list

def print_by_block(text_list):
    # Processes print requests gradually to print words one-by-one
    last_text_block = text_list[-1]
    for text_block in text_list:
        print_by_word(text_block)
        if text_block != last_text_block:
            input("\n\nContinue >>>")
            print()

def print_by_word(text):
    text_list = re.split('[ ]', text)
    n_total = len(text_list)
    for n, text in enumerate(text_list, start=1):
        print(text, end='')
        sleep(0.03)
        if n != n_total:
            print(' ', end='')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Mystery Game driven by chat AI")
    parser.add_argument('-d', '--debug', dest="debug", action='store_true', 
                        help="enable debug features and verbose outputs")
    parser.add_argument('-c', '--caching', dest="caching", action='store_true',
                        help="enable chatbot response caching to cache.json file")

    args = parser.parse_args()
    
    debug = False
    caching = False

    if args.debug:
        debug = True
        generator.debug = True
        print("Debug mode enabled.")

    if args.caching:
        caching = True
        generator.caching = True
        generator.cache = {}
        generator.load_cache()
        print("Chatbot caching enabled.")

    generator.initialize()
    request_name()
    generator.replace_name()

    introduction()

    while True:
        if request_input() == 1:
            break

    print_by_block([generator.summarize_text(is_end=True)])