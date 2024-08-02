# music.sh

music.sh is a simple Bash script that allows you to download, manage, and play music tracks from YouTube using `yt-dlp` and `mpv`. It provides a minimalist command-line interface for music management.

music.sh downloads or streams tracks from YouTube and allows you to list, search, play and delete downloaded tracks.

## Prerequisites

Ensure you have the following dependencies installed:
- `yt-dlp`
- `mpv`
- `jq`
- `grep`

## Installation

Clone the repository and make the script executable. The script, by default, stores the music files and other data alongside itself, you can change this my editing the `DIR` variable  at line 5.

## Usage

music.sh [option] [argument]

Options:

- `list`:  Lists all downloaded tracks in {id}. {title} format
- `play <id>`:  Plays the track corresponding to <id>
- `add <keyword>`:Downloads music track, explained below in detail
- `delete <id>`: Deletes the track corresponding to <id>
- `search <keyword>`: Lists all tracks matching the keyword in {id}. {title} format
- `stream <keyword>`: Streams music track, explained below in detail
- `help`: Shows this usage information.

`music.sh add/stream <search term>`:
Searches and lists the top five search results on YouTube for the given <keyword>, numbered 1 to 5. Enter the serial number of the track you wish to download/stream in the prompt that follows

## License

This project is licensed under the MIT License. See the LICENSE file for details.
