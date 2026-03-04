# TODO
 
## Known Issues & Bugs
 
### 🔐 Encryption Not Implemented
- Encryption was partially attempted using RC4 (`Password1!`) but was **ultimately not implemented** in the final version.
- Task results were briefly encrypted client-side, but consistent decryption in the CLI was unsuccessful.
- Due to complexity and reliability issues, encryption was **disabled/removed** in the final build.
- Future versions should reintroduce encryption (preferably AES-GCM) with proper key exchange and consistent message formatting.
 
### ❌ sRDI & Shellcode Integration Broken
- sRDI integration (used to execute reflective DLLs like `ListPrivs` or `Mimikatz`) is **non-functional**.
- Mimikatz and other shellcode-based tasks currently **do not return any output**.
- Issues likely stem from shellcode execution, lack of in-memory output capture, or improper argument setup.
 
### ⚠️ CLI Output & Formatting
- CLI struggles with binary or non-UTF8 task outputs (e.g., RC4 output, Mimikatz results).
- No structured handling of binary vs text output.
- Garbled or empty results are shown with no debug info.
 
### 🧠 Error Handling & Logging Deficiencies
- No proper logging exists in the client, server, or CLI for:
  - Decryption errors
  - File transfer issues
  - Network problems
- Hard to debug failed tasks or empty results.
- Add verbosity and debug flags to CLI in the future.
 
### 🐞 Debug Crash in Client
- Intermittent crash was observed during encryption testing.
- Cause unknown but likely due to memory issues (buffer misuse or null pointers).
- May relate to how task results were encoded or base64 wrapped.
 
---
 
## Improvements Needed
 
### 🔐 Proper Encryption Support (Future)
- Fully re-implement secure communications using AES or RC4:
  - Encrypt full task messages (not just result)
  - Securely load key from config or environment
- Prefer AES-GCM over RC4 due to cryptographic safety
 
### 🧰 Shellcode & DLL Execution
- Fix broken shellcode execution flow
- Enable stdout/stderr capture from reflective DLLs
- Provide fallback method (e.g., temp DLL drop + rundll32)
 
### 📁 File Transfer Robustness
- Validate uploads/downloads with binary-safe chunking
- Add retries and progress tracking
- Currently, only basic local testing was done
 
---
 
## Documentation Gaps
 
- README should clearly state:
  - ❌ Encryption is **not** implemented
  - ❌ Mimikatz and reflective DLLs **do not work**
  - ✅ Simple tasks (like `pwd`, `pslist`) work reliably
- No support for dynamic config files or CLI key loading
- Add setup and troubleshooting tips
 
---
 
## Future Recommendations
 
- Add integration testing for agent ↔ server ↔ CLI
- Modularize communication logic and improve schema
- Introduce per-agent logging and output tracking
- Add operator commands to check encryption or shellcode status
- Use versioning or feature flags to toggle experimental features
 
---
 
**Status Summary**:
- ✅ Agent registration and simple tasks function correctly
- ❌ Encryption and reflective DLL support are disabled/broken
- ⚠️ CLI needs output handling, logging, and configuration support
 
This file reflects the current state and should be updated with future changes.