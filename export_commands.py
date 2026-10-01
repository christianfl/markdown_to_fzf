#!/usr/bin/env python3
"""Export shell commands within Markdown files as null separated fzf entries."""

import argparse
import re
import shlex
import subprocess
from pathlib import Path


def commands(lines, language):
    """Group shell lines into commands with their preceding comments."""
    shell = "zsh" if language == "zsh" else "bash"
    comments, pending = [], []
    for line in lines:
        if not pending and line.lstrip().startswith("#"):
            comments.append(line.lstrip()[1:].strip())
            continue
        if not pending and not line.strip():
            comments.clear()
            continue
        pending.append(line)
        command = "\n".join(pending)
        # Check syntax without executing commands; retain unfinished constructs.
        check = subprocess.run(
            [shell, "-n"],
            input=command + "\n",
            text=True,
            capture_output=True,
            check=False,
        )
        trailing_backslashes = len(line) - len(line.rstrip("\\"))
        continues_on_next_line = trailing_backslashes % 2 == 1
        if check.returncode or check.stderr or continues_on_next_line:
            continue
        yield "\n".join(comments), command
        comments, pending = [], []
    if pending:
        # Keep invalid or incomplete commands visible so the source notes can be fixed.
        yield "\n".join(comments), "\n".join(pending)


def extract(path):
    """Yield commands from supported fenced code blocks in a Markdown file."""
    fence, language, block = "", "", []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not fence:
            match = re.fullmatch(r" {0,3}(`{3,}|~{3,})(.*)", line)
            if match:
                fence, language = match[1], match[2].strip().lower()
                closing_fence = r" {0,3}" + fence[0] + "{" + str(len(fence)) + r",}\s*"
                block = []
        elif re.fullmatch(closing_fence, line):
            if language in {"bash", "sh", "shell", "zsh"}:
                yield from commands(block, language)
            fence = ""
        else:
            block.append(line)


def main():
    """Parse CLI arguments, export commands, and print the shell setup command."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--in", dest="input_dir", type=Path, required=True,
                        help="Markdown folder to search recursively")
    parser.add_argument("--out", type=Path, default=Path("commands.fzf"),
                        help="output catalog (default: commands.fzf)")
    args = parser.parse_args()
    folder = args.input_dir.expanduser()
    if not folder.is_dir():
        parser.error(f"Markdown folder is not a directory: {folder}")
    out = args.out.expanduser().resolve()
    try:
        with out.open("w", newline="", encoding="utf-8") as output:
            for path in sorted(folder.rglob("*.md")):
                if any(part.startswith(".") for part in path.relative_to(folder).parts):
                    continue
                for comments, command in extract(path):
                    description = "".join(f"# {line}\n" for line in comments.splitlines())
                    indented_command = "  " + command.replace("\n", "\n  ")
                    output.write(description + indented_command + "\n\0")
    except (OSError, UnicodeError) as error:
        parser.exit(1, f"Export failed: {error}\n")
    script = Path(__file__).resolve()
    print(shlex.join(["source", str(script.with_name("shell.sh")), str(out)]))


if __name__ == "__main__":
    main()
