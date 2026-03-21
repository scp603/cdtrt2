import time
import random
import sys

try:
    from evdev import UInput, ecodes as e
except ImportError:
    print("Error: python3-evdev is required.")
    sys.exit(1)

def run_poltergeist():
    # UInput() automatically creates the virtual keyboard in /dev/uinput
    # and destroys it cleanly when the script stops.
    try:
        with UInput() as ui:
            while True:
                # Sleep for a random time between 10 and 30 seconds
                time.sleep(random.randint(10, 30))
                
                for _ in range(random.randint(1, 3)): # Simulate 1 to 3 key presses
                    # Simulate pressing and releasing the Caps Lock key
                    ui.write(e.EV_KEY, e.KEY_CAPSLOCK, 1) # Key Down
                    ui.write(e.EV_KEY, e.KEY_CAPSLOCK, 0) # Key Up
                    ui.syn() # Sync tells the kernel to execute the input
                    time.sleep(random.uniform(0.1, 0.5)) # Short random delay between key presses
                
    except PermissionError:
        print("This script must be run as root to access /dev/uinput.")
        sys.exit(1)
    except KeyboardInterrupt:
        sys.exit(0)

if __name__ == '__main__':
    run_poltergeist()
