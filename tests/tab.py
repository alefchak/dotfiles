"""Press Tab in a real interactive shell and print the edited line.

usage: tab.py <bash|zsh> <text>

Runs the shell in a pseudo-terminal, binds Ctrl-X to write the line buffer to a file, types the
text, Tab, then Ctrl-X. Keys are handled in order, so the file is written once completion is done.
Waits on the prompt and the file rather than on fixed delays.
"""

import os
import pty
import select
import shutil
import sys
import tempfile
import time

TIMEOUT = 30


def main():
    shell, text = sys.argv[1], sys.argv[2]
    dump = os.path.join(tempfile.mkdtemp(), "line")
    # The prompt is split in the command so its echo cannot be mistaken for the prompt itself
    if shell == "zsh":
        setup = ('dumpbuf() { print -r -- "$BUFFER" > %s }; zle -N dumpbuf; bindkey "^X" dumpbuf; '
                 "PS1='TAB''READY> '\n" % dump)
    else:
        setup = ('dumpbuf() { printf "%%s\\n" "$READLINE_LINE" > %s; }; bind -x \'"\\C-x": dumpbuf\'; '
                 "PS1='TAB''READY> '\n" % dump)

    pid, fd = pty.fork()
    if pid == 0:
        os.environ["TERM"] = "xterm"   # zsh turns off line editing on a dumb terminal
        os.execvp(shell, [shell, "-i"])

    output = b""

    def read_until(done):
        nonlocal output
        deadline = time.time() + TIMEOUT
        while not done():
            if time.time() > deadline:
                sys.exit("tab.py: timed out; shell output:\n" + output.decode(errors="replace")[-2000:])
            ready, _, _ = select.select([fd], [], [], 0.05)
            if ready:
                try:
                    output += os.read(fd, 65536)
                except OSError:
                    break

    try:
        os.write(fd, setup.encode())
        read_until(lambda: b"TABREADY> " in output)
        os.write(fd, text.encode() + b"\t\x18")
        read_until(lambda: os.path.exists(dump) and open(dump).read().endswith("\n"))
        with open(dump) as f:
            sys.stdout.write(f.read())
    finally:
        try:
            os.kill(pid, 9)
        except OSError:
            pass
        os.waitpid(pid, 0)
        shutil.rmtree(os.path.dirname(dump))


main()
