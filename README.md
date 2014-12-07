# collaborative-edit package

Local, simple collaborative editing.

>The current version only supports a single file being hosted at a time.
>Multiple files can be hosted but there are unpredictable results.

### Installation

```
apm install collaborative-edit
```
OR

>Open the Settings from within Atom, select the packages tab, search and install the package from there.

### Features

* Host local server
* Connect multiple clients to a single hosted document

### Settings

* `ServerAddress` : The address of the document hosting server. (default: 127.0.0.1)
* `Port` : The port of the document hosting server. (default: 8080)
* `Debug` : Prints some extra information to the console. (default: false)

### Key Bindings

* `ctrl-alt-h`: Hosts the current open document
* `ctrl-alt-c`: Connects using the configuration parameters
* `ctrl-alt-shift-c`: Disconnect close the shared Atom pane, and if you are hosting close the server.

### Contributing

>Fork the repository

* OS X
 * Open a terminal of your choice
 * `cd` to the directory which you have 'checked out' the source
 * do `apm link -d`
 * Open a development window of Atom
 * Develop away!
  * Reload the window (`ctrl-alt-cmd-l`) for changes to take affect in the current Development Atom Window

>When creating a Pull Request assign @ericadamski and/or @sieniawsky

### License

MIT
