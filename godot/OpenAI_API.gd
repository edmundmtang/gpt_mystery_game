class_name OpenAI_API
extends Node

# Interfaces with the OpenAI web API to do chat completions. We could do other
# things, but it's all we really need for the mystery game. Note that we load
# the OpenAI API key from a text file and that'll need to be generated on the
# OpenAI platform

var api_key: String = FileAccess.open("res://openai_api_key.txt", FileAccess.READ).get_as_text()
var chat_url: String = "https://api.openai.com/v1/chat/completions"
var out_headers: Array = ["Content-Type: application/json", "Authorization: Bearer " + api_key]
var model: String = "gpt-3.5-turbo-16k"
var http_request: HTTPRequest

var max_tokens: int = 1024
var temperature: float = 0.7
var context: Dictionary

var message_cache: Array

signal chat_response(message)

func _ready() -> void:
    http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_request_completed)

func do_chat_completion(messages) -> void:
    message_cache = messages
    var body = JSON.stringify({
        "messages" : messages,
        "temperature": temperature,
        "max_tokens": max_tokens,
        "model": model
    })
    var error = http_request.request(chat_url, out_headers, HTTPClient.METHOD_POST, body)

    if error != 0:
        print("Error no: ", error)
        push_error("Something went wrong with the chat completion.")

func _on_request_completed(result, responseCode, _headers, body):
    if result != 0 or responseCode >= 400:
        push_error("Encountered a server-side error. [Result: " + result + "] [Response Code: " + responseCode + "]")
        # To-Do: Depending on the error type attempt to regenerate response
    chat_response.emit(JSON.parse_string(body.get_string_from_utf8())["choices"][0]["message"])

