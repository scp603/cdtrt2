# Custom C2 Framework
 
A lightweight and modular Command & Control (C2) framework built for red team operations, offering agent tasking, process and file control, and support for reflective DLL execution.
 
> ⚠️ **Disclaimer**: This project is for educational use or lawful engagements only. Do not deploy in environments where you do not have authorization.
 
---
 
## 🚀 Getting Started
 
### 📦 Prerequisites
- **Python 3.10+**
- **Windows 10+** for the agent
- `requests` and `cmd2` libraries (`pip install -r requirements.txt`)
- Visual Studio (to compile the C++ agent)
- Administrator access for DLL injection tasks
 
---
 
## 🛠️ Installation
 
### 1. Start the C2 Server
```bash
cd server/app/
python server.py
```
 
### 2. Start the Command-Line Interface
```bash
cd server/cli/
python cli.py
```
 
### 3. Deploy the Agent
- Open client/main.cpp in Visual Studio
- Set the IP/port of the Server in config.h
- Compile in Release/Debug x64
- Run on the target:
```bash
Client.exe
```
 
## 🧑‍💻 CLI Operator Usage
 
### Agent Control
```bash
agents                  # terminal in to agents screen
use <agent_id>          # Focus on one agent
```
 
### Core Tasking Commands
```bash
shell <cmd>             # Run a shell command
ps                      # List running processes
whoami                  # Identity of the client
pwd                     # Show current directory
upload <file>           # Upload a file to the agent
download <remote>       # Download a file from the agent
scinject <pid> <dll>      # DLL injection via LoadLibrary
```
 
### Task Management
```bash
tasks                   # Show history of tasks
task <task_id>          # Show output of a specific task
```
 
### CLI Enhancements
- Command auto-completion
- Aliases for common commands
- Alias loading from config file (see aliases.txt)
 
## 🔐 Encryption Status
 
⚠️ Not implemented in this version
 
RC4 encryption was planned but not implemented in the final version due to:
- Development time constraints
- Complexity with base64 encoding
- Potential stability concerns
 
All communication is plaintext in the final build. Operators must deploy over a VPN or tunnel if encryption is required.
 
## 🔎 Features Overview
 
| Feature | Status |
|---------|--------|
| Agent registration | ✅ Working |
| Shell / PsList / Pwd | ✅ Working |
| File upload/download | ✅ Working |
| DLL injection (LoadLibrary) | ✅ Working |
| sRDI support (Mimikatz, Listprivs, Setpriv) | ❌ Broken |
| Encryption | ❌ Not implemented |
| CLI enhancements (cmd2) | ✅ Working |
 
## 🧪 Operational Tips
- Use pslist, pwd, and shell for safe tasking.
- Use upload and download for file exfil/implant delivery.
- Avoid loading sRDIs for now (e.g., Mimikatz) — outputs are not reliable.
- Task IDs can be copied/pasted into task <id> for viewing output.
 
## 🗂️ Directory Structure
```
.
├── client/      # Agent (C++ Windows)
│   └── main.cpp, rc4.hpp, ...
├── server/      # Backend REST server
│   └── data/    # screenshot data
|   └── libs/    
|       └── sRDI/ # holds functions to convert dll to
|                   shellcode
|   └── app/
|       └── main.py # where to run the server
|   └── cli/
|       └── modules/
|           └── screenshot/
|           └── setpriv/
|			└── mimikatz/
|			...
|       └── cli.py # where to run the cli
└── README.md    # This file
```
 
## ⚠️ Known Issues & Bugs
 
- **CLI Output Formatting**
  - Some output has encoding issues with binary content.
  - Consider handling binary task results more gracefully.
 
- **Error Handling**
  - If task results are corrupted, the CLI just prints a generic error or empty result.
  - Improve logging/debugging for failed operations.
 
- **Communication Security**
  - All communications (inputs to tasks, agent registration, task results) are in plaintext.
  - No encryption is currently implemented.
 
- **Debug Crash in Client**
  - A debug crash was observed in certain cases; needs investigation (possibly due to invalid memory write or improper null termination).
 
- **Base64 Encoding Edge Cases**
  - The client uses base64 to encode some results. There may be edge cases where newline characters or special bytes cause JSON formatting issues.
 
## 🔧 Planned Improvements
- Fix sRDI implementation so that it loads the shellcode and runs it
- Implement comprehensive encryption for all communications (inputs, outputs, agent check-ins).
- Create a proper encryption system using strong algorithms like AES.
- Add integrity checks (e.g., HMAC) to ensure results aren't tampered with.
- Improve CLI command auto-completion and command history persistence.
- Add logging/debug mode to the CLI for troubleshooting network issues.
- Ensure compatibility with large outputs (chunked results or pagination).
- Add secure key management via config files or environment variables.
- Create documentation for the encryption system once implemented.
