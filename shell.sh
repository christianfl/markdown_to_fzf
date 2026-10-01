# Source with the exported commands.fzf path.
if [[ $# -ne 1 || ! -r $1 || -d $1 ]]; then
    printf '%s\n' 'Usage: source /path/to/shell.sh /path/to/readable/commands.fzf' >&2
    return 1
fi
MARKDOWN_COMMANDS_FILE=$1

# Picker records: command + US (\037) + display text + NULL (\0).
# Command lines have two-space display padding, removed before insertion.
_markdown_history() {
    if [[ -n ${BASH_VERSION:-} ]]; then
        # Compare plain and marked snapshots: only real entry headers change,
        # even if a command contains "  123  literal". Missing timestamps get ??.
        # The third snapshot preserves the user timestamp format for display.
        {
            HISTTIMEFORMAT= builtin history
            printf '\0'
            HISTTIMEFORMAT=MARKER builtin history
            printf '\0'
            builtin history
            printf '\0'
        } | awk -v RS='\0' '
            # Each NULL-delimited record is a snapshot, with a final newline.
            NR == 1 { count = split($0, plain, "\n") - 1 }
            NR == 2 { split($0, marked, "\n") }
            NR == 3 {
                split($0, formatted, "\n")
                for (line = 1; line <= count; line++) {
                    if (plain[line] != marked[line]) {
                        n++
                        sub(/^ *[0-9]+[ *] /, "", plain[line])
                        sub(/^ *[0-9]+[ *] /, "", formatted[line])
                        commands[n] = plain[line]
                        displays[n] = formatted[line]
                    } else {
                        commands[n] = commands[n] "\n" plain[line]
                        displays[n] = displays[n] "\n" formatted[line]
                    }
                }
            }
            END {
                for (i = n; i > 0; i--) {
                    command = commands[i]
                    # The display prefix is the timestamp, the suffix is the command.
                    stamp = substr(displays[i], 1, length(displays[i]) - length(command))
                    sub(/[ \t]+$/, "", stamp)
                    command = "  " command
                    gsub(/\n/, "\n  ", command)
                    display = stamp == "" ? command : stamp "  " substr(command, 3)
                    printf "%s\037%s%c", command, display, 0
                }
            }
        '
    else
        local id command
        for id in ${(Onk)history}; do
            command=${history[$id]}
            command=${command//$'\n'/$'\n  '}
            printf '  %s\037  %s\0' "$command" "$command"
        done
    fi
}
_markdown_commands() {
    local selected
    selected=$({ _markdown_history
        awk -v RS='\0' '{ sub(/\n$/, ""); printf "%s\037%s%c", $0, $0, 0 }' "$MARKDOWN_COMMANDS_FILE"
    } |
        FZF_DEFAULT_OPTS= FZF_DEFAULT_OPTS_FILE= fzf --read0 --no-multi \
            --delimiter=$'\037' --with-nth=2.. \
            --layout=default --height=80% --gap --tiebreak=index \
            --query "${READLINE_LINE:-${BUFFER:-}}") || return 0
    # Remove description comments before unindenting, preserving command comments.
    selected=$(printf '%s\n' "${selected%%$'\037'*}" | sed '/^# /d; s/^  //')
    if [[ -n ${BASH_VERSION:-} ]]; then
        READLINE_LINE=$selected
        # Bash measures the Readline cursor position in bytes, not characters.
        local LC_ALL=C
        READLINE_POINT=${#READLINE_LINE}
    else
        BUFFER=$selected
        CURSOR=${#BUFFER}
        zle redisplay
    fi
}
if [[ -n ${BASH_VERSION:-} ]]; then
    bind -m emacs-standard -x '"\C-r":_markdown_commands'
else
    zmodload zsh/parameter
    zle -N _markdown_commands
    bindkey -M emacs '^R' _markdown_commands
fi
