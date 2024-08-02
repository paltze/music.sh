#! /bin/bash

#### INIT ####

DIR="$( dirname "$0" )"
REGISTRY_LOCATION="$DIR/REGISTRY"

# Check if given directory and files exist. Create new if not.
if ! [ -d "$DIR" ]; then
    mkdir "$DIR"
fi

if ! [ -f "$REGISTRY_LOCATION" ]; then
    touch "$REGISTRY_LOCATION"
fi

#Checks if required programs are accessible

if ! command -v yt-dlp &> /dev/null; then
    echo "yt-dlp not found, install to continue"
    exit 1
fi

if ! command -v mpv &> /dev/null; then
    echo "mpv not found, install to continue"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "jq not found, install to continue"
    exit 1
fi

if ! command -v grep &> /dev/null; then
    echo "grep not found, install to continue"
    exit 1
fi

#### INIT ####


#### REGISTRY Start ####

REGISTRY=()

# Adds every value in REGISTRY in a new line to registry file
save_registry() {
    IFS=$'\n'
    echo "${REGISTRY[*]}" > "$REGISTRY_LOCATION"
}

# Adds every value until next newline as a value to REGISTRY
load_registry() {
    IFS=$'\n' read -d '' -r -a REGISTRY < "$REGISTRY_LOCATION"
}

## To emulate nested arrays a system like (array0[0], array0[1], array1[0], array1[1], ...) is used

# Read REGISTRY. $1 is upper array index and $2 is inner array index
read_registry() {
    upper=$1
    inner=$2
    echo "${REGISTRY[$(( 2 * upper + inner ))]}"
}

# Sat values of REGISTRY. $1 is upper array index and $2 is inner array index
add_to_registry() {
    name=$1
    id=$2
    REGISTRY+=("$name")
    REGISTRY+=("$id")

    save_registry
}

# Delete values from REGISTRY
delete_from_registry() {
    index="$1"

    unset "REGISTRY[$(( index * 2 ))]"
    unset "REGISTRY[$(( index * 2 + 1 ))]"

    save_registry
}

registry_length() {
    echo $(( "${#REGISTRY[@]}" / 2 ))
}

load_registry

#### REGISTRY End ####


#### LIST Function Start ####

list () {
    length=$( registry_length )

    #Iterates over REGISTRY, printing every title name
    for (( i=0; i<length; i++ )) do
        echo "$(( i + 1 )). $( read_registry $i "0" )"
    done
}

#### LIST Function End ####


#### PLAY Function Start ####

play () {
    track_id="$(($1 - 1))"
    total_tracks=$(registry_length)

    # Validate input
    if [[ ! $track_id =~ ^[0-9]+$ ]] || (( track_id < 0 || track_id + 1 > total_tracks )); then
        echo "Invalid track ID. Please enter a number between 1 and $total_tracks."
        exit 1
    fi

    read_registry "$track_id" "0"
    mpv --loop "$DIR/$(read_registry "$track_id" "1")"
}

#### PLAY Function End ####


#### DOWNLOAD Function Start ####

down () {
    query="$1"

    titles=()
    ids=()
    i=1

    # !! Written By AI, do not touch !! #
    while IFS= read -r result; do
        title=$(echo "$result" | jq -r '.title')
        id=$(echo "$result" | jq -r '.id')
        duration=$(echo "$result" | jq -r '.duration')
        channel=$(echo "$result" | jq -r '.channel')

        echo "$i. [$duration s] $title {$channel}"

        titles+=("$title")
        ids+=("$id")
        i=$((i + 1))
    done < <(yt-dlp --no-warnings --dump-json "ytsearch5:${query}")

    read -r -p "Enter video id> " selected_id

    final_id=$((selected_id - 1))

    if [[ ! $selected_id =~ ^[0-9]+$ ]] || (( selected_id < 1 || selected_id >= i )); then
        echo "Invalid selection. Please enter a number between 1 and $((i-1))."
        return
    fi

    yt-dlp --no-warnings -o "$DIR/%(id)s" -f ba "${ids[$final_id]}"

    if ! [ -f "$DIR/${ids[$final_id]}" ]; then
        echo "Error: Unable to add the selected title to library"
        exit 1
    fi

    add_to_registry "${titles[$final_id]}" "${ids[$final_id]}"

    echo "Downloaded selected track"
}

#### DOWNLOAD Function End ####


#### DELETE Function Start ####

delete() {
    rm "$DIR/$(read_registry "$(( $1 - 1 ))" "1")"
    delete_from_registry "$(( $1 - 1 ))"

    echo "Deleted selected track"
}

#### DELETE Function End ####


#### STREAM Function Start ####

stream() {
    query="$1"

    declare -a titles
    declare -a ids
    i=1

    # !! Written By AI, do not touch !! #
    while IFS= read -r result; do
        title=$(echo "$result" | jq -r '.title')
        id=$(echo "$result" | jq -r '.id')
        duration=$(echo "$result" | jq -r '.duration')
        channel=$(echo "$result" | jq -r '.channel')

        echo "$i. [$duration s] $title {$channel}"

        titles+=("$title")
        ids+=("$id")
        i=$((i + 1))
    done < <(yt-dlp --no-warnings --dump-json "ytsearch5:${query}")

    read -r -p "Enter video id> " selected_id

    final_id=$((selected_id - 1))

    if [[ ! $selected_id =~ ^[0-9]+$ ]] || (( selected_id < 1 || selected_id >= i )); then
        echo "Invalid selection. Please enter a number between 1 and $((i-1))."
        return
    fi

    echo "${titles[$final_id]}"
    mpv --loop "$(yt-dlp --no-warnings -f ba --get-url "${ids[$final_id]}")"
}

#### STREAM Function End ####


#### SEARCH Function Start ####

search() {
    keyword=$1
    length=$(registry_length)
    indexed_titles=""
    index=1

    for ((i=0; i<length; i++)); do
        indexed_titles+="${index}. $(read_registry $i 0)\n"
        ((index++))
    done

    # Search for the keyword in the indexed titles
    echo -e "$indexed_titles" | grep -i "$keyword"
}

#### SEARCH Function End ####


#### HELP Function Start ####

usage="Usage: music.sh [option] [argument]

Options:

list                Lists all downloaded tracks in {id}. {title} format
play <id>           Plays the track corresponding to <id>
add <keyword>       Downloads music track, explained below in detail
delete <id>         Deletes the track corresponding to <id>
search <keyword>    Lists all tracks matching the keyword in {id}. {title} format
stream <keyword>    Streams music track, explained below in detail
help                Shows this usage information

 - music.sh add/stream <keyword>:
Searches and lists the top five search results on YouTube for the given <keyword>, numbered 1 to 5. Enter the serial number of the track you wish to download/stream in the prompt that follows.
"

help() {
    echo "$usage"
}

#### HELP Function End ####


if [ "$1" = "list" ]
then
    list
elif [ "$1" = "play" ]
then
    play "$2"
elif [ "$1" = "add" ]
then
    down "$2"
elif [ "$1" = "delete" ]
then
    delete "$2"
elif [ "$1" = "stream" ]
then
    stream "$2"
elif [ "$1" = "search" ]
then
    search "$2"
elif [ "$1" = "help" ]
then
    help
else
    echo "Error: Supply a mode, run \`[music.sh] help\` for more info"
fi
