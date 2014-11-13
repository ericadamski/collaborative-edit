# collaborative-edit package

Local, simple collaborative editing.

### Installation

```
apm install collaborative-edit
```

### Features

* Host local server
* Connect multiple clients to a single hosted document

### Settings

* `ServerAddress` : The address of the document hosting server. (default: 127.0.0.1)
* `Port` : The port of the document hosting server. (default: 8080)
* `DocumentName` : The name of the document which you want to share, creates the document in the server if it does not already exist. (default: 'untitled')
* `Debug` : Prints some extra information to the console. (default: false)

### Key Bindings

* `ctrl-alt-h`: Hosts the current open document
* `ctrl-alt-c`: Connects using the configuration parameters
* `ctrl-alt-shift-c`: Disconnect close the shared Atom pane, and if you are hosting close the server.

### License

MIT
