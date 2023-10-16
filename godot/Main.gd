extends Node2D


var api_key: String = FileAccess.open("res://openai_api_key.txt", FileAccess.READ).get_as_text()
var max_tokens = 1024
var temperature = 0.7
var chat_url = "https://api.openai.com/v1/chat/completions"
var headers = ["Content-Type: application/json", "Authorization: Bearer " + api_key]
var engine = "gpt-3.5-turbo-16k"
@onready var http_request: HTTPRequest = $HTTPRequest

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    print("API_KEY: ", api_key)
    http_request.connect("request_completed", _on_request_completed)
    do_chat_completion("Hello")

func do_chat_completion(message):
    var body = JSON.new().stringify({
        "messages" : [
        {
        "role": "user",
        "content": message
        }
        ],
        "temperature": temperature,
        "max_tokens": max_tokens,
        "model": engine
    })
    var error = http_request.request(chat_url, ["Content-Type: application/json", "Authorization: Bearer " + api_key], HTTPClient.METHOD_POST, body)

func _on_request_completed(result, responseCode, headers, body):
    print("RESULT: ", result)
    print("RESPONSECODE: ", responseCode)
    print("HEADERS: ", headers)
    print("BODY: ", body.get_string_from_utf8())
