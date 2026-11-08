# Source with the exported commands.fzf path.
if [[ $# -ne 1 || ! -r $1 || -d $1 ]]; then
    printf '%s\n' 'Usage: source /path/to/shell.sh /path/to/readable/commands.fzf' >&2
    return 1
fi
MARKDOWN_COMMANDS_FILE=$1

# Picker records: command + US (\037) + display text + NULL (\0).
# Command lines have two-space display padding, removed before insertion.
_markdown_commands() {
    local selected
    selected=$(awk -v RS='\0' '{ sub(/\n$/, ""); printf "%s\037%s%c", $0, $0, 0 }' "$MARKDOWN_COMMANDS_FILE" |
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

_markdown_bind_key() {
    local key=${MARKDOWN_TO_FZF_KEY:-Alt+m}
    local letter bash_sequence zsh_sequence

    case $key in
        none) return 0 ;;
        Alt+[a-z])
            letter=${key#Alt+}
            bash_sequence="\\e$letter"
            zsh_sequence="^[$letter"
            ;;
        Ctrl+[a-z])
            letter=${key#Ctrl+}
            bash_sequence="\\C-$letter"
            zsh_sequence="^$letter"
            ;;
        *)
            printf 'markdown_to_fzf: unsupported key %s (use Alt+<letter>, Ctrl+<letter>, or none)\n' "$key" >&2
            return 1
            ;;
    esac

    if [[ -n ${BASH_VERSION:-} ]]; then
        # Retain Readline binding as a fallback if Flyline is disabled later.
        bind -m emacs-standard -x "\"$bash_sequence\":_markdown_commands"
        # Flyline replaces Readline and needs its own registration.
        if [[ $(type -t flyline 2>/dev/null) == builtin ]]; then
            flyline key bind "$key" 'always=runBashCommand(_markdown_commands)'
        fi
    else
        zle -N _markdown_commands
        bindkey -M emacs "$zsh_sequence" _markdown_commands
    fi
}
_markdown_bind_key || { unset -f _markdown_bind_key; return 1; }
unset -f _markdown_bind_key
