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
messages = {}

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
    model = CHAT_COMPLETION_MODEL
    context = []
    for i, message in enumerate(messages):
        context.append({
            "role": "user" if i % 2 == 0 else "assistant",
            "content": message
        })
    assert context[-1]["role"] == "user"
    context = [{"role": "system", "content": base_context}] + context
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
    return [response["choices"][0]["message"]["content"], response["usage"]["total_tokens"]]

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
        "extra_conversation": "",
        "extra_description": ""
    }
    return context

def replace_name():
    global player_name
    global context
    context["base"] = re.sub("\[player name\]", player_name, context["base"])
    context["conversation"] = re.sub("\[player name\]", player_name, context["conversation"])
    context["description"] = re.sub("\[player name\]", player_name, context["description"])

def continue_text(input_text, conv_type, max_output_tokens=1000):
    global messages
    global context
    if conv_type == "conversation":
        target_messages = messages["conversation"]
        target_messages.append(format_converse_input(input_text))
        target_context = context["base"] + "\n" + context["conversation"] + "\n" + context["extra_conversation"]
    elif conv_type == "description":
        target_messages = messages["description"]
        target_messages.append(format_examine_input(input_text))
        target_context = context["base"] + "\n" + context["description"] + "\n" + context["extra_description"]
    else:
        raise Exception("No valid conv_type provided. Please indicate either 'conversation' or 'description'.")
    output_message, output_length = do_chat_completion(target_messages, target_context, max_tokens=max_output_tokens)
    target_messages.append(output_message)
    if output_length > 12000: # To-Do - Come up with a proper heuristic for estimating summarization compression and needed space
        summarize_text(target_messages, context, conv_type)
    return output_message

def format_converse_input(raw_text):
    global player_name
    return "{\n\"speaker\": \"Detective " + player_name + "\",\n\"content\": \"" + raw_text + "\"\n}"

def format_examine_input(raw_text):
    return "I examine " + raw_text + "."

def summarize_text(conv_type):
    global messages
    global context
    if conv_type == "conversation":
        instruction = "Summarize the conversation so far."
        target_extra = "extra_conversation"
        target_context = context["conversation"] + "\n" + context[target_extra]
    elif conv_type == "description":
        instruction = "Summarize the descriptions so far."
        target_extra = "extra_description"
        target_context = context["description"] + "\n" + context[target_extra]
    else:
        raise Exception("No valid conv_type provided. Please indicate either 'conversation' or 'description'.")
    target_messages = messages.copy()
    target_messages.append(instruction)
    extra_context, _ = do_chat_completion(target_messages, target_context)
    context[target_extra] = extra_context
    return extra_context

def initialize():
    global context
    global messages
    context = load_context("context.json")
    messages = {
        "conversation": [],
        "description": []
    }

if __name__ == "__main__":
    
    caching = False
    if caching:
        cache = {}
        load_cache()
        clear_stored_cache()

    initialize()
    player_name = "Anne Holloway"
    replace_name()

    input_message = "Greetings, I am detective Anne Holloway. Could you please tell me what has transpired here tonight?"
    continue_text(input_message, "conversation")
    # input_message = "Who is here tonight?"
    # continue_text(input_message, messages, context, "conversation")
    # input_message = "Who would be interested in stealing the sapphire?"
    # continue_text(input_message, messages, context, "conversation")
    # input_message = "Is there any suspicious activity you could tell me about?"
    # continue_text(input_message, messages, context, "conversation")
    # input_message = "Everyone, tell me what you were doing prior to the theft."
    # continue_text(input_message, messages, context, "conversation")
    # input_message = "The thief is Miss Dawson!"
    # continue_text(input_message, messages, context, "conversation")

    print("END")