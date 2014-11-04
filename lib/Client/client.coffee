{allowUnsafeEval} = require 'loophole'
sharejs = (allowUnsafeEval -> require 'share')
client = sharejs.client

ws = new WebSocket 'ws://127.0.0.1:8080'
client = new sharejs.client.Connection ws
doc = client.get('hello', 'doc')

console.log doc
