;;
;; winbase.h -- This module defines the 32-Bit Windows Base APIs
;; Copyright (c) Microsoft Corp. All rights reserved.
;;
INVALID_HANDLE_VALUE	= -1
OPEN_EXISTING	= 3
FILE_MAP_READ	= SECTION_MAP_READ
;ExitProcess(uExitCode)
;GetLastError()
;GetFileSize(hFile,lpFileSizeHigh)
;CloseHandle(hObject)
;MapViewOfFile(hFileMappingObject,dwDesiredAccess,dwFileOffsetHigh,dwFileOffsetLow,dwNumberOfBytesToMap)
;UnmapViewOfFile(lpBaseAddress)
;CreateSemaphore(lpSemaphoreAttributes,lInitialCount,lMaximumCount,lpName)
CreateSemaphore	= CreateSemaphore##AW
;CreateFileMapping(hFile,lpFileMappingAttributes,flProtect,dwMaximumSizeHigh,dwMaximumSizeLow,lpName)
CreateFileMapping	= CreateFileMapping##AW
;GetModuleHandle(lpModuleName)
GetModuleHandle	= GetModuleHandle##AW
;GetCommandLine()
GetCommandLine	= GetCommandLine##AW
;CreateFile(lpFileName,dwDesiredAccess,dwShareMode,lpSecurityAttributes,dwCreationDisposition,dwFlagsAndAttributes,hTemplateFile)
CreateFile	= CreateFile##AW
#include	<WinError.inc>