# Daxe Application

This command-line application serves to provide file access to Daxe running in a web browser, to edit local files.
It turns the Daxe web application into a desktop application.

## Installation
- Install the [Dart SDK](https://www.dartlang.org/tools/sdk/)
- Use the `pub get` command in the `daxapp` directory
- get the [Daxe web application](https://github.com/adopt/daxe) on github
- build it with `build.sh`
- set the path to the Daxe web application directory, for instance:
    `export DAXE_HOME=/.../daxe/build/web`
    (alternatively, move the Daxe web application so that `daxe/daxe.html` is
    in the same directory as the command-line application)

## Usage
`daxe.sh file.xml config_name`
OR: `daxe.sh file.xml`
