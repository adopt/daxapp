#!/bin/bash

# usage: daxe.sh file.xml  or  daxe.sh file.xml config_name
# DAXE_HOME should be set to the directory containing daxe.html
# (requires the Dart SDK)

# check at least 1 arg
if [ $# -eq 0 ]; then
  case $(tty) in
    /dev/*) echo "Usage: daxe.sh [-config config_name] file.xml";;
    *) xmessage -buttons Ok:0 -default Ok -nearmouse "Usage: daxe.sh [-config config_name] file.xml" -timeout 10;;
  esac
  exit 1
fi

# get parameters
config=""
file=""
if [ "$1" == "-config" ]; then
  config="$2"
  if [ $# -gt 1 ]; then
    file="$3";
  fi
else
  file="$1";
  if [ "$2" == "-config" ]; then
    config="$3";
  fi
fi

# change path to file into absolute path
if [ "$file" != "" ]; then
  pwd=`pwd`
  if ! expr "$file" : '/.*' > /dev/null; then
    file="$pwd/$file"
  fi
fi

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

cmd="dart \"$DAXAPP_HOME/bin/main.dart\""
if [ "$config" != "" ]; then
  cmd="$cmd -config \"$config\""
fi
if [ "$file" != "" ]; then
  cmd="$cmd \"$file\""
fi
case $(tty) in
  /dev/*)
    eval $cmd
  ;;
  *)
    error=$( { eval $cmd > /dev/null; } 2>&1 )
    if [ "$?" -ne "0" ]; then
      xmessage -buttons Ok:0 -default Ok -nearmouse "$error" -timeout 10
    fi
  ;;
esac
