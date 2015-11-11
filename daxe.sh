#!/bin/bash

# usage: daxe.sh file.xml  or  daxe.sh file.xml config_name
# DAXE_HOME should be set to the directory containing daxe.html
# (requires the Dart SDK)

# check at least 1 arg
if [ $# -eq 0 ]; then
  case $(tty) in
    /dev/*) echo "Usage: daxe.sh file.xml [config_name]";;
    *) xmessage -buttons Ok:0 -default Ok -nearmouse "Usage: daxe.sh file.xml [config_name]" -timeout 10;;
  esac
  exit 1
fi

# change path to file into absolute path
pwd=`pwd`
file="$1"
if ! expr "$file" : '/.*' > /dev/null; then
  file="$pwd/$file"
fi

# get configuration name, if any
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

case $(tty) in
  /dev/*)
    dart "$DAXAPP_HOME/bin/main.dart" "$file" $config
  ;;
  *)
    error=$( { dart "$DAXAPP_HOME/bin/main.dart" "$file" $config > /dev/null; } 2>&1 )
    if [ "$?" -ne "0" ]; then
      xmessage -buttons Ok:0 -default Ok -nearmouse "$error" -timeout 10
    fi
  ;;
esac
