#!/usr/bin/env bash

if [[ "$1" == "--help" ]] || [[ $# -eq 0 ]]
then
    cat <<-HEREDOC
	usage: ${0##*/} FILE...

	Rename each FILE with an interactive prompt
	HEREDOC

    exit
fi

err() {
    local msg="$1"
    >&2 echo "error: $msg"
    exit 1
}

rename_file() {
    local file="$1"
    local new_name=""

    [[ "$file" == "" ]] && err "given empty file name"
    [[ ! -f "$file" ]] && err "file $file does not exist"

    read -ep "edit file name: " -i "$file" new_name

    [[ "$new_name" == "" ]] && err "new file name is empty"

    mv -i "$file" "$new_name"
}

for file in "$@"
do
    rename_file "$file"
done
