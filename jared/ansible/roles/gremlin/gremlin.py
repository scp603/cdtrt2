#!/usr/bin/env python3

"""Keyboard Gremlin

Periodically sends small, annoying keyboard events so defenders notice strange input but can
quickly regain control (e.g., CapsLock/NumLock toggles and occasional Alt+Tab).

This is intentionally low-impact: it does not delete data or execute commands.
"""

import random
import sys
import time

try:
    from evdev import UInput, ecodes as e
except ImportError:
    print("Error: python3-evdev is required.")
    sys.exit(1)

# Keys to toggle (LEDs + minor keyboard disruption)
LED_KEYS = [
    e.KEY_CAPSLOCK,
    e.KEY_NUMLOCK,
    e.KEY_SCROLLLOCK,
]

# Mild nuisance keys (not destructive)
MILD_KEYS = [
    e.KEY_ESC,
    e.KEY_TAB,
]

# Optional combo sequence that may briefly switch windows in a GUI environment
COMBO_SEQUENCE = [
    (e.KEY_LEFTALT, True),
    (e.KEY_TAB, True),
    (e.KEY_TAB, False),
    (e.KEY_LEFTALT, False),
]


def press_key(ui: UInput, key_code: int) -> None:
    ui.write(e.EV_KEY, key_code, 1)
    ui.write(e.EV_KEY, key_code, 0)
    ui.syn()


def run_gremlin() -> None:
    try:
        with UInput() as ui:
            while True:
                # Sleep for a random short period so it doesn't feel too regular
                time.sleep(random.uniform(20, 60))

                # 1) Toggle one of the lock keys (Caps/Num/Scroll)
                press_key(ui, random.choice(LED_KEYS))

                # 2) Occasionally send an extra nudge (Esc/Tab)
                if random.random() < 0.3:
                    press_key(ui, random.choice(MILD_KEYS))

                # 3) Rarely send an Alt+Tab sequence to shift focus in GUIs
                if random.random() < 0.1:
                    for key, down in COMBO_SEQUENCE:
                        ui.write(e.EV_KEY, key, 1 if down else 0)
                    ui.syn()

    except PermissionError:
        print("This script must be run as root to access /dev/uinput.")
        sys.exit(1)
    except KeyboardInterrupt:
        sys.exit(0)


if __name__ == '__main__':
    run_gremlin()
