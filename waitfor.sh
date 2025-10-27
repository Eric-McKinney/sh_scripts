#!/usr/bin/env bash
set -e
set -u
set -o pipefail

[[ $# -ne 1 ]] && { echo "usage: ${0##*/} PID/NAME"; exit 1; }

if [[ "$1" =~ ^[[:digit:]]+$ ]]
then
    pid="$1"
else
    pid="$(pidof "$1")"

    # more than one pid returned
    if [[ "$(echo "$pid" | wc -w)" -ne 1 ]]
    then
        i=1
        for p in $pid
        do
            echo "$((i++))) $(ps --format pid,ruser,cmd $p | tail -n 1)"
        done
        read -p "Which one? "
        [[ $REPLY -ge $i ]] && { echo "${0##*/}: invalid choice"; exit 1; }

        pid="$(echo "$pid" | awk "{print \$$REPLY}" )"
    fi
fi

tail --pid="$pid" -f /dev/null
