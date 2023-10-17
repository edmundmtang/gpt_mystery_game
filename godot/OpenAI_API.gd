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

signal chat_response(message)

func _ready() -> void:
    http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_on_request_completed)

func do_chat_completion(message) -> void:
    var body = JSON.stringify({
        "messages" : [
        {
        "role": "user",
        "content": message
        }
        ],
        "temperature": temperature,
        "max_tokens": max_tokens,
        "model": model
    })
    var error = http_request.request(chat_url, out_headers, HTTPClient.METHOD_POST, body)

    if error != 0:
        push_error("Something went wrong with the chat completion.")

func _on_request_completed(_result, _responseCode, _headers, body):
    chat_response.emit(body.get_string_from_utf8())

