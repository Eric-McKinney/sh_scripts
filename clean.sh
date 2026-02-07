#!/usr/bin/env bash

print_help() {
    cat <<-HEREDOC
	usage: ${0##*/} [OPTION...] [DIR...]

	DESCRIPTION
	    Clean the given directories of files named 'a.out' and files ending with '.o'.
	    If no DIRs are given, the current directory will be cleaned.

	OPTIONS
	    --help
	        Print this message and exit.

	    -i, --interactive
	        Ask for confirmation before removing each file.

	    -p, --pattern GLOB
	        Add GLOB (a shell glob) to list of patterns to be cleaned. This option can be
	        used multiple times to add multiple patterns. To avoid immediate expansion of
	        given GLOB, wrap it in single quotes or double quotes.

	    -r, --recursive
	        Clean recursively, traversing and cleaning all subdirectories.

	    --
	        End of options. Everything after is treated as a DIR.
	HEREDOC
}

#
# flag defaults
#
interactive="-delete"
recursive="-maxdepth 1"
declare -a patterns=("*.o" "a.out")

while [[ $1 =~ ^- ]]
do
    curr_opt="$1"

    while [[ "$curr_opt" != "-" ]]
    do
        if [[ "$curr_opt" =~ ^-[^-]{2,} ]]  # chained short options
        then
            chained_opts="${curr_opt:2}"
            curr_opt="${curr_opt::2}"
        fi

        case "$curr_opt" in
            --help) print_help; exit 0 ;;
            --interactive|-i) interactive="-ok rm {} ;" ;;
            --pattern|-p)
                shift

                if [[ $# -eq 0 ]] 
                then
                    >&2 echo "error: $curr_opt missing argument"
                    exit 1
                fi

                patterns[${#patterns[@]}]="$1"
                ;;
            --recursive|-r) recursive="" ;;
            --) shift; break ;;
            *) >&2 echo "error: unrecognized option \"$curr_opt\""; exit 1 ;;
        esac

        curr_opt="-$chained_opts"
        chained_opts=""
    done

    shift
done

patstring=""
for p in "${patterns[@]}"
do
    patstring+="-name $p -or "
done
patstring="${patstring%-or }"

for arg in "$@"
do
    [[ -d "$arg" ]] || { >&2 echo "error: $arg is not a directory"; exit 1; }
done

set -f  # disable globbing so patterns don't expand to filenames immediately
find $@ -mindepth 1 $recursive -type f '(' $patstring ')' $interactive
set +f
