#!/usr/bin/env bash

set -e
set -u

# run a command in the background and discard its stdout and stderr

if test -t 1; then
  exec 1>/dev/null
fi

if test -t 2; then
  exec 2>/dev/null
fi

"$@" &
