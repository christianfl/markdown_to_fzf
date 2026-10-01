# markdown_to_fzf

> Search commands from your Obsidian vault or other Markdown folder alongside your shell history with `Ctrl-R` in Bash or Zsh.

## Prerequisites

Exporting:

- Python 3.8+
- Bash (plus Zsh for `zsh` blocks)

Using:

- Bash or Zsh with Emacs keybindings
- `fzf` 0.56+
- `awk` with NULL-delimited record support (such as GNU awk)
- `sed`

## Usage

Export:

```bash
python3 export_commands.py --in ~/notes --out commands.fzf
```

Add the printed `source` line at the end of your `.bashrc` or `.zshrc`, after any fzf integration or other keybindings:

```bash
source /path/to/shell.sh /path/to/commands.fzf
```

## How?

Commands are extracted recursively from fenced `bash`, `sh`, `shell`, and `zsh` blocks in `.md` files:

````markdown
```bash
# List files, including hidden ones
ls -la
```
````

- Comments appear above commands.
- Keeps multiline commands.
- Bash history timestamps follow your `HISTTIMEFORMAT` (but you should use a single-line format).
