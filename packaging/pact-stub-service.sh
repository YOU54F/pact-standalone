#!/bin/sh
set -e

SOURCE="$0"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  TARGET="$(readlink "$SOURCE")"
  START="$( echo "$TARGET" | cut -c 1 )"
  if [ "$START" = "/" ]; then
    SOURCE="$TARGET"
  else
    DIR="$( dirname "$SOURCE" )"
    SOURCE="$DIR/$TARGET" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  fi
done
RDIR="$( dirname "$SOURCE" )"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

  APP="$DIR/pact"
  if [ -x "$APP" ]; then
    if [ "$#" -eq 0 ]; then
      exec "$APP" stub --help
    else
      exec "$APP" stub "$@"
    fi
    exit $?
  else
    echo "Cannot execute $APP"
    exit 1
  fi