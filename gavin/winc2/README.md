# Custom C2 Framework
 
A lightweight and modular Command & Control (C2) framework built for red team operations, offering agent tasking, process and file control, and support for reflective DLL execution.
 
> ⚠️ **Disclaimer**: This project is for educational use or lawful engagements only. Do not deploy in environments where you do not have authorization.
 
---
 
## 🚀 Getting Started
 
### 📦 Prerequisites
- **Python 3.10+**
- **Windows 10+** or **Windows Server 2022+** for the agent
- `requests` and `cmd2` libraries (`pip install -r requirements.txt`)
- Visual Studio (to compile the C++ agent)
 
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
| sRDI support (Listprivs, Setpriv) | ✅  Working |
| Encryption | ❌ Not implemented |
| CLI enhancements (cmd2) | ✅ Working |
 
## 🧪 Operational Tips
- Use pslist, pwd, and shell for safe tasking.
- Use upload and download for file exfil/implant delivery.
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
 
## ⚠️ Known Issues & Bug
 
- **Communication Security**
  - All communications (inputs to tasks, agent registration, task results) are in plaintext.
  - No encryption is currently implemented.
 
- **Mimikatz DLL Broken**
  - The mimikatz DLL seemed to partially work, but due to static analysis evasion modification, other functions cause it to crash
  - I need to fork the mimikatz github repository and work on it separately to make slight modifications in order to allow it to work as a DLL to track it separately.
 
## 🔧 Planned Improvements
- Create a proper encryption system using strong algorithms like AES.
- Improve CLI command auto-completion and command history persistence.
- Fork mimikatz github repo and link it in this readme, include DLL inside of the server files
- Cleanup Server directory (contains multiple versions of a couple DLLs in separate directories)
- Add process hollowing functionality
- Add hooks into LSA
