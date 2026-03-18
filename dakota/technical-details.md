# AppLogger: Technical Implementation Details

### Architecture
The tool uses a multi-threaded architecture to ensure that system-level keyboard hooking does not interfere with network exfiltration or local I/O.

- **Main Thread**: Initializes the keyboard listener and handles the primary execution loop.
- **Listener Thread**: Manages the `pynput.keyboard` hooks, monitoring for interrupts and managing the internal string buffer.
- **Exfiltration Thread**: A daemon thread that handles the 60-second beaconing interval and the thread-safe `queue.Queue`.

### Context-Aware Logic (HWND vs Title)
A critical technical refinement was made to address dynamic window titles (common in File Explorer and Browsers). Instead of flushing on every title change, the tool monitors the unique **Window Handle (HWND)** via `win32gui.GetForegroundWindow()`. This allows the tool to maintain a persistent buffer while the user is typing within a single application, even if the title text changes character-by-character.

### Data Exfiltration
Data is packaged into a JSON payload and transmitted via HTTP POST.
- **User-Agent**: Masqueraded as a standard Mozilla/5.0 browser.
- **Endpoint**: Directed to a pre-configured Red Team C2 infrastructure.
- **Resilience**: If the C2 is unreachable, data is preserved in the local fallback log in the `%TEMP%` directory.

### Operational Security
- **Obfuscation**: The local log file mimics a DirectX diagnostic artifact (`D3D_ShaderCache_Diag.log`).
- **Log Formatting**: Entries use a PID-based, component-labeled format to blend into standard Windows system logs.