# Context-Aware Keylogger (AppLogger)

## 1. Tool Overview
AppLogger is a targeted information-gathering tool that records keystrokes while explicitly tracking the active application window. This fits perfectly into Category 5: Information Gathering Tool. It provides Red Teams with highly filtered data and features a robust, stealthy exfiltration mechanism. It stores data locally, encrypts the payload, and periodically exfiltrates it disguised as standard secure web traffic.

## 2. Requirements & Dependencies
* Target OS: Windows 10/11
* Privileges: User-level execution
* Libraries: `pynput`, `pywin32`, `requests`

## 3. Installation Instructions
1. Clone the repository to the target system.
2. Install dependencies: `pip install -r requirements.txt`
3. Configure the `C2_URL` (ensure it is an HTTPS endpoint) and insert your symmetric encryption key into `config.json`.
4. Verify functionality by running the script and monitoring the C2 server.
5. Run `python -m PyInstaller --onefile --noconsole --name D3D_Diag_Tool "Keylogger.py"` to update the executable.

## 4. Usage Instructions
1. Execute the script silently in the background.
2. Keystrokes are written to a hidden local cache.
3. Every 300 seconds (with added jitter), the tool packages the cache into a JSON structure mimicking standard application telemetry, and sends it via an HTTPS POST request.
4. The local cache is wiped upon a 200 OK response from the C2.

## 5. Operational Notes
* OpSec: The tool utilizes dual-layer encryption. HTTPS encrypts the transport channel, masking the traffic as standard web browsing. Application-layer AES encryption ensures the payload remains secure even if the Blue Team is utilizing SSL/TLS decryption on their firewalls. 
* Detection Risks: Process monitoring might flag the Python execution or the API hooks used for logging. Network analysis might detect the beaconing behavior despite the encryption.
* Mitigation: Implemented randomized jitter for the check-in interval to defeat basic beacon analysis. 
* Cleanup: Terminate the process and securely wipe the local cache file.

## 6. Limitations
* Hardcoded for Windows OS environments.
* Requires the C2 infrastructure to handle decryption before the logs can be analyzed.
* Messages/traffic are not encrypted.

## 7. Credits & References
* Built using Python standard libraries.
* Developed strictly for authorized Red Team operations.
