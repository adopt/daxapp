# Daxe Application

This Linux/UNIX application serves to provide file access to the Daxe XML editor running in a web browser, to edit local files.
It turns the Daxe web application into a desktop application.

## Installation
- install the [Dart SDK](https://www.dartlang.org/tools/sdk/)
- use the `pub get` command in the `daxapp` directory
- get the [Daxe web application](https://github.com/adopt/daxe) on github
- build it with `build.sh`
- set the path to the Daxe web application directory, for instance:
    `export DAXE_HOME=/.../daxe/build/web`
    (alternatively, move the Daxe web application so that `daxe/daxe.html` is
    in the same directory as the command-line application)
- optionally, create a desktop icon to launch the application, using the included daxe_icon image and the daxe.sh script
  - [on Linux](http://xmodulo.com/create-desktop-shortcut-launcher-linux.html)
  - [on MacOS](http://apple.stackexchange.com/questions/115114/how-to-put-a-custom-launcher-in-the-dock-mavericks) (the application has not been tested on MacOS, but it might work)

## Usage
- command-line: `daxe.sh -config config_name` or `daxe.sh -config config_name file.xml` or `daxe.sh file.xml`.
If the configuration is not specified, Daxe will look for the right one based on the name of the root element.
- desktop application: a file can be opened with a drag-and-drop on the application icon.

Note that currently only one file may be opened at a time.
