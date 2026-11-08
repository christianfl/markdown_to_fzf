# markdown_to_fzf

> Search commands from your Obsidian vault or other Markdown folder with `Alt+M` in Plain Bash, Zsh, or Bash + [Flyline](https://github.com/HalFrgrd/flyline).

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

Add the printed `source` line at the end of your `.bashrc` or `.zshrc`:

```bash
source /path/to/shell.sh /path/to/commands.fzf
```

Press **Alt+M** to search your saved Markdown commands. The selected command is inserted into the prompt without being executed.

### Keybindings

By default, `Alt+m` is used. To choose a different key, set `MARKDOWN_TO_FZF_KEY` before sourcing:

```bash
MARKDOWN_TO_FZF_KEY=Alt+k
source /path/to/shell.sh /path/to/commands.fzf
```

- Use `Alt+<lowercase letter>`, `Ctrl+<lowercase letter>`, or `none`.

### Flyline integration

When the Flyline Bash builtin is loaded, `shell.sh` automatically registers the configured shortcut via Flyline's `runBashCommand` action.

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
