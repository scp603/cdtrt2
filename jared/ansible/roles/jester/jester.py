#!/usr/bin/env python3

"""Terminal Jester

Randomly annoys logged-in users by sending bell characters to their ttys and
posting brief "pop-up" messages via wall. This is intended to be annoying but
not destructive.
"""

import os
import random
import subprocess
import time


MESSAGES = [
    "Hey, pay attention! Something weird just happened...",
    "Did you just see that? No? Keep looking.",
    "A suspicious process just ran. (Maybe?)",
    "System alert: nothing to see here... or is there?",
    "Your terminal is being watched. Or maybe it's just me.",
]


def get_ttys() -> list[str]:
    """Return a list of ttys for currently logged-in users."""
    try:
        output = subprocess.check_output(["who"], text=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []

    ttys = []
    for line in output.splitlines():
        parts = line.split()
        if len(parts) >= 2:
            tty = parts[1]
            if tty.startswith("pts/") or tty.startswith("tty"):
                ttys.append(tty)
    return ttys


def ring_bell(tty: str) -> None:
    """Send a bell character to a specific tty."""
    path = f"/dev/{tty}"
    try:
        with open(path, "wb", buffering=0) as f:
            f.write(b"\a")
    except Exception:
        pass


def wall_message(msg: str) -> None:
    """Send a short wall message to all logged-in terminals."""
    try:
        subprocess.run(["wall", msg], check=False)
    except FileNotFoundError:
        pass


def run() -> None:
    while True:
        # Sleep (so it doesn't feel too regular)
        time.sleep(random.uniform(15, 50))

        # Pick an action: bell, wall, or both.
        action = random.random()

        ttys = get_ttys()
        if ttys and action < 0.6:
            tty = random.choice(ttys)
            ring_bell(tty)

        if action > 0.4:
            wall_message(random.choice(MESSAGES))


if __name__ == "__main__":
    run()
