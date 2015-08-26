#!/bin/sh

# usage: daxe.sh file.xml config_name path_to_daxe.html
# OR: daxe.sh file.xml config_name  if DAXE_HOME is set or if daxe.html is in the same directory
# (requires the Dart SDK)

# change path to file into absolute path
pwd=`pwd`
file="$1"
if ! expr "$file" : '/.*' > /dev/null; then
  file="$pwd/$file"
fi

# get configuration name
config="$2"

# link resolution - $0 could be a symbolic link
if [ -z "$DAXAPP_HOME" -o ! -d "$DAXAPP_HOME" ] ; then
  PRG="$0"
  progname=`basename "$0"`

  while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
      PRG="$link"
    else
      PRG=`dirname "$PRG"`"/$link"
    fi
  done

  DAXAPP_HOME=`dirname "$PRG"`

  # absolute path
  DAXAPP_HOME=`cd "$DAXAPP_HOME" && pwd`
fi

# get path for daxe.html
if [ -n "$3" ] ; then
  DAXEHTML="$3"
else
  if [ -z "$DAXE_HOME" -o ! -d "$DAXE_HOME" ] ; then
    DAXE_HOME='.'
  fi
  DAXEHTML="$DAXE_HOME/daxe.html"
fi

dart "$DAXAPP_HOME/bin/main.dart" "$file" "$config" "$DAXEHTML"

