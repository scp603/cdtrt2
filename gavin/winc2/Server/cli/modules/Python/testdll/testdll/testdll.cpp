#include <windows.h>
#include <iostream>

typedef const wchar_t* (__cdecl* ScreenshotFunc)();

int main() {
	// Load the DLL
	HMODULE hDLL = LoadLibraryW(L"GDI-ScreenShot.dll");
	if (!hDLL) {
		std::wcerr << L"[-] Failed to load DLL\n";
		return 1;
	}

	// Get the function
	ScreenshotFunc fn = (ScreenshotFunc)GetProcAddress(hDLL, "ExecuteW");
	if (!fn) {
		std::wcerr << L"[-] Failed to find ExecuteW in DLL\n";
		FreeLibrary(hDLL);
		return 1;
	}

	// Call the function
	const wchar_t* base64Screenshot = fn();
	if (!base64Screenshot || wcslen(base64Screenshot) < 10) {
		std::wcerr << L"[-] ExecuteW returned invalid or empty base64 string\n";
	}
	else {
		std::wcout << L"[+] ExecuteW succeeded. Base64 Output:\n";
		std::wcout << base64Screenshot << std::endl;
	}

	// Clean up
	FreeLibrary(hDLL);
	return 0;
}
