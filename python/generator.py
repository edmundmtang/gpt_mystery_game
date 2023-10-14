import os
import time
import string
import re
import hashlib
import json
import openai

try:
    openai.api_key = os.environ["OPENAI_API_KEY"]  # GPT-3.5 key
except:
    print("There is no OpenAI API Key on this machine.")
# try:
#     openai.organization = os.environ["OPENAI_ORG_ID"]
# except:
#     print("There is no OpenAI organization ID on this machine.")

CHAT_COMPLETION_MODEL = "gpt-3.5-turbo-16k"
cache_file = "cache.json"
cache = {}

context = {}
messages = []

debug = False

# serialize the whole cache to a local json file
def save_cache():
    try:
        with open(cache_file, 'w') as f:
            json.dump(cache, f)
    except:
        pass

# load the cache from a local json file (check empty)
def load_cache():
    global cache
    try:
        with open(cache_file, 'r') as f:
            cache = json.load(f)
    except:
        cache = {}

# clear the cache
def clear_cache():
    global cache
    cache = {}

def clear_stored_cache():
    global cache_file
    if os.path.exists(cache_file):
        os.remove(cache_file)
    else:
        print("Tried to clear stored cache, but couldn't find the file.")

def cache_wrapper(func):
    def wrapped(*args, **kwargs):
        if not caching:
            return func(*args, **kwargs)
        key = func.__name__ + ' ## ' + ' ## '.join([str(a) for a in args])
        if kwargs:
            key += str(kwargs)
        # key = key.encode('utf-8')
        key = hashlib.md5(key.encode('utf-8', errors='ignore')).hexdigest()
        if key in cache:
            return cache[key]
        res = func(*args, **kwargs)
        cache[key] = res
        save_cache()
        return res

    return wrapped

@cache_wrapper
def do_chat_completion(messages, base_context, stop=None, max_tokens=1000):
    global debug
    global api_input
    model = CHAT_COMPLETION_MODEL
    context = []
    for i, message in enumerate(messages):
        context.append({
            "role": "user" if i % 2 == 0 else "assistant",
            "content": message
        })
    assert context[-1]["role"] == "user"
    context = [{"role": "system", "content": base_context}] + context
    if debug:
        api_input = context
    for _ in range(1, 10):
        try:
            response = openai.ChatCompletion.create(
                model=model,
                messages=context,
                stop=stop,
                max_tokens=max_tokens
            )
            break
        except openai.error.InvalidRequestError as err:
            raise Exception(err)
        except openai.error.RateLimitError:
            print("rate limit hit")
            sleep(60)
    else:
        raise Exception("rate limit keeps timing out")
    token_counts = {
        "prompt_tokens": response["usage"]["prompt_tokens"],
        "completion_tokens": response["usage"]["completion_tokens"],
        "total_tokens": response["usage"]["total_tokens"]
    }
    return [response["choices"][0]["message"]["content"], token_counts]

def load_context(context_file):
    try:
        with open(context_file, 'r') as f:
            raw_context = json.load(f)
    except FileNotFoundError as err:
        print("No context file found to generate scenario:", err.args)
    context = {
        "base": raw_context["base"],
        "conversation": raw_context["conversation"],
        "description": raw_context["description"],
        "extra": ""
    }
    return context

def replace_name():
    global player_name
    global context
    context["base"] = re.sub("\[player name\]", player_name, context["base"])
    context["conversation"] = re.sub("\[player name\]", player_name, context["conversation"])
    context["description"] = re.sub("\[player name\]", player_name, context["description"])

def continue_text(input_text, text_type, max_output_tokens=1000):
    global messages
    global context
    global debug
    if text_type == "conversation":
        messages.append(format_converse_input(input_text))
        target_context = context["base"] + "\n" + context["conversation"] + "\n" + context["extra"]
    elif text_type == "description":
        messages.append(format_examine_input(input_text))
        target_context = context["base"] + "\n" + context["description"] + "\n" + context["extra"]
    else:
        raise Exception("No valid text_type provided. Please indicate either 'conversation' or 'description'.")
    output_message, token_counts = do_chat_completion(messages, target_context, max_tokens=max_output_tokens)
    if debug:
        print("CONTINUING TEXT")
        print("===============")
        if text_type == "conversation":
            print("Player says: ", input_text, "\n")
        elif text_type == "description":
            print("Player examines ", input_text, "\n")
        print(output_message)
        print("\nTotal tokens: ", token_counts["total_tokens"], "\n")
    messages.append(output_message)
    if token_counts["total_tokens"] > 12000: # To-Do - Come up with a proper heuristic for estimating summarization compression and needed space
        summarize_text()
    return output_message

def format_converse_input(raw_text):
    global player_name
    return "{\n\"speaker\": \"Detective " + player_name + "\",\n\"content\": \"" + raw_text + "\"\n}"

def format_examine_input(raw_text):
    return "I examine " + raw_text + "."

def summarize_text():
    global messages
    global context
    global debug
    instruction = "Summarize the above conversations and descriptions. Do so in plain English."
    target_context = "You are a bot designed to summarize text.\n" + context["extra"]
    target_messages = messages.copy()
    target_messages.append(instruction)
    extra_context, token_counts = do_chat_completion(target_messages, target_context, max_tokens=4000)
    if debug:
        print("SUMMARIZING TEXT")
        print("================")
        print(extra_context, "\n")
        print("Prompt tokens:", token_counts["prompt_tokens"])
        print("Completion tokens:", token_counts["completion_tokens"])
        print("Total tokens:", token_counts["total_tokens"])
    context["extra"] = extra_context
    messages = []
    return extra_context

def initialize():
    global context
    global messages
    context = load_context("context.json")

if __name__ == "__main__":
    
    caching = False
    debug = True
    api_input = {}
    if caching:
        cache = {}
        load_cache()

    initialize()
    player_name = "Anne Holloway"
    replace_name()

    if debug:
        print("\nBASE CONTEXT")
        print("============\n")
        print(context["base"])
        print("\nCONVERSATION CONTEXT")
        print("====================\n")
        print(context["conversation"])
        print("\nDESCRIPTION CONTEXT")
        print("===================\n")
        print(context["description"])
        print()

    input_message = "Greetings, I am detective Anne Holloway. Could you please tell me what has transpired here tonight?"
    continue_text(input_message, "conversation")
    input_message = "Who is here tonight?"
    continue_text(input_message, "conversation")
    input_message = "Who would be interested in stealing the sapphire?"
    continue_text(input_message, "conversation")
    input_message = "Is there any suspicious activity you could tell me about?"
    continue_text(input_message, "conversation")
    input_message = "Everyone, tell me what you were doing prior to the theft."
    continue_text(input_message, "conversation")
    input_message = "The thief is Miss Dawson!"
    continue_text(input_message, "conversation")
    examine_input = "the room"
    continue_text(examine_input, "description")
    examine_input = "the case"
    continue_text(examine_input, "description")
    examine_input = "the people"
    continue_text(examine_input, "description")
    examine_input = "Mr. Blackwood's wrist"
    continue_text(examine_input, "description")
    examine_input = "Lady Eleanor's figure"
    continue_text(examine_input, "description")
    summarize_text()
    print("END")