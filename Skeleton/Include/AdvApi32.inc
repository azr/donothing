;;
;; winreg.h -- This module contains the function prototypes and constant, type
;;             and structure definitions for the Windows 32-Bit Registry API.
;; Copyright (c) 1991-1999 Microsoft Corporation
;;
HKEY_CURRENT_USER	= 80000001h
;RegOpenKeyEx(hKey,lpSubKey,ulOptions,samDesired,phkResult)
RegOpenKeyEx	= RegOpenKeyEx##AW
;RegQueryValueEx(hKey,lpValueName,lpReserved,lpType,lpData,lpcbData)
RegQueryValueEx	= RegQueryValueEx##AW
;RegCreateKeyEx(hKey,lpSubKey,Reserved,lpClass,dwOptions,samDesired,lpSecurityAttributes,phkResult,lpdwDisposition)
RegCreateKeyEx	= RegCreateKeyEx##AW
;RegSetValueEx(hKey,lpValueName,Reserved,dwType,lpData,cbData)
RegSetValueEx	= RegSetValueEx##AW
;RegDeleteKey(hKey,lpSubKey)
RegDeleteKey	= RegDeleteKey##AW
;RegQueryInfoKey(hKey,lpClass,lpcbClass,lpReserved,lpcSubKeys,lpcbMaxSubKeyLen,lpcbMaxClassLen,lpcValues,lpcbMaxValueNameLen,lpcbMaxValueLen,lpcbSecurityDescriptor,lpftLastWriteTime)
RegQueryInfoKey	= RegQueryInfoKey##AW