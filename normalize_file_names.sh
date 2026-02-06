#!/usr/bin/env bash

print_help() {
    cat <<-HEREDOC
	usage: ${0##*/} [OPTION]... [--] FILE...

	DESCRIPTION
	    Normalize the names of all FILEs given by replacing spaces with underscores and
	    breaking up camel case with underscores.

	    FILE
	        Path to a file or directory (relative or absolute)

	OPTIONS
	    --help
	        Print this message and exit.

	    --recursive, -r
	        Normalize the entire contents of any directories given (including subdirectories).

	    --
	        End of options. Everything after is treated as a FILE
	HEREDOC
}

[[ $# -eq 0 ]] && { print_help; exit 0; }
shopt -s extglob

while [[ "$1" =~ ^- ]]
do
    curr_opt="$1"
    case "$curr_opt" in
        --help) print_help; exit 0 ;;
        --recursive|-r) recursive="true" ;;
        --) shift; break ;;
        *) echo "error: unrecognized option \"$curr_opt\""; exit 1 ;;
    esac
    shift
done

all_files_exist="true"
for arg in "$@"
do
    [[ ! -e "$arg" ]] && { echo "error: $arg does not exist"; all_files_exist="false"; }
done

[[ "$all_files_exist" != "true" ]] && exit 1

normalize() {
    local file
    for file in "$@"
    do
        # handle directories passed with a trailing /
        file="${file%/}"

        local path="${file%/*}"
        [[ "$path" == "$file" ]] && path=""

        # only operate on the file name part of the arg
        : "${file##*/}"

        # remove awkward characters like ', ", !, etc.
        : "${_//\'/}"
        : "${_//\"/}"
        : "${_//\!/}"
        : "${_//\:/}"
        : "${_//\[/}"
        : "${_//\]/}"

        # replace spaces with underscores
        : "${_//+([[:space:]])/_}"

        # replace _-_ or _- or -_ with just _
        : "${_//_-_/_}"
        : "${_//_-/_}"
        : "${_//-_/_}"

        # change camelCase to camel_Snake_Case
        local new_name="$(echo "$_" | sed -r 's/([a-z])([A-Z][a-z])/\1_\2/g')"

        local full_new_name="${path:+"$path/"}$new_name"

        if [[ "$file" != "$full_new_name" ]]
        then
            [[ -e "$full_new_name" ]] && { echo "error: $file normalizes to $new_name which already exists"; exit 1; }

            mv "$file" "$full_new_name" || { echo "error: mv \"$file\" \"$new_name\" failed"; exit 1; }
        fi

        [[ "$recursive" == "true" ]] && [[ -d "$new_name" ]] && normalize "$new_name"/*
    done
}

normalize "$@"
