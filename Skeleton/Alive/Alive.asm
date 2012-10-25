;==============================================================================
; ALIVE AND KICKING
; SKELETON Version 3.2.1
; Copyright 2000-2007 Wayne J. Radburn
;
; Assembles with Jeremy Gordon's GoAsm as follows:
;    GoAsm Alive.asm
;
; Links with Jeremy Gordon's GoLink as follows:
;    GoLink Alive.obj Alive.res Kernel32.dll User32.dll Gdi32.dll ComDlg32.dll ComCtl32.dll AdvApi32.dll Shell32.dll hhctrl.ocx
;
; See Alive.rc for how to create Alive.res
;==============================================================================

UNICODE	= 1		;Remove to build ANSI version
STRINGS	UNICODE		;Remove to build ANSI version

#include "Kernel32.inc"
#include "User32.inc"
#include "Gdi32.inc"
#include "ComDlg32.inc"
#include "ComCtl32.inc"
#include "AdvApi32.inc"
#include "HtmlHelp.inc"

;;
;;	RESOURCE IDs
;;

IDI_ICON	= 1h
IDB_TOOLBAR	= 1h
IDM_MENU	= 1h
IDA_ACCEL	= 1h
IDD_ABOUT	= 1h

IDM_FILEMENU	= 20h
IDM_VIEWMENU	= 21h
IDM_HELPMENU	= 22h

IDM_OPEN	= 23h
IDM_CLOSE	= 24h
IDM_EXIT	= 25h

IDM_TOOLBAR	= 26h
IDM_STATUSBAR	= 27h
IDM_TREEVIEW	= 28h
IDM_SPLIT	= 29h
IDM_FONT	= 2Ah

IDM_HELPTOPICS	= 2Bh
IDM_ABOUT	= 2Ch

;;
;;	WINDOW IDs
;;

ID_TOOLBAR	= 0F0h
ID_STATUSBAR	= 0F1h
ID_TREEVIEW	= 0F2h
ID_VIEW		= 0F3h

;;
;;	MAIN THREAD, WINDOW, and MESSAGE LOOP
;;

	CODE
	ALIGN	4
Start:
;Initialize the Main window
	call	MainINIT

	test	eax,eax		;Z to continue
	jnz	>.Exit		;NZ to exit

;Process queued messages until WM_QUIT is received
	call	MsgLOOP		;returns exit code in EAX

;End this process and all its threads
.Exit
	push	eax			;uExitCode
	call	[ExitProcess]		;Kernel32

	ret


	ALIGN	4
MsgLOOP:
	FRAME
	LOCAL	msg:MSG

	lea	esi,[msg]
	mov	ebx,[hAccel]
	mov	edi,[hwndMain]
	jmp	>.Retrieve

;Dispatch the message to a window procedure
	ALIGN	4
.Dispatch
	push	esi			;lpMsg
	push	ebx			;hAccTable
	push	edi			;hWnd
	call	[TranslateAccelerator]	;User32

	test	eax,eax
	jnz	>.Retrieve	;NZ if already translated and processed

	push	esi			;lpMsg
	call	[TranslateMessage]	;User32

	push	esi			;lpMsg
	call	[DispatchMessage]	;User32

;Retrieve a message from the thread message queue
.Retrieve
	push	0			;wMsgFilterMax
	push	0			;wMsgFilterMin
	push	0			;hWnd
	push	esi			;lpMsg
	call	[GetMessage]		;User32

	cmp	eax,-1
	je	>.Exit		;E if error so exit

	test	eax,eax		;EAX=0 if WM_QUIT
	jnz	<.Dispatch	;NZ if other message retrieved so process it

	mov	eax,[msg.wParam]	;return ExitCode
.Exit
	ret
	ENDF


;;
;;	MAIN WINDOW MESSAGES
;;

       	CONST
	ALIGN	4
MainMsg	DD	WM_NOTIFY, WM_COMMAND, WM_MENUSELECT,\
		WM_SIZING, WM_ENTERSIZEMOVE, WM_WINDOWPOSCHANGED,\
		WM_MOUSEMOVE, WM_LBUTTONDOWN, WM_LBUTTONUP, WM_RBUTTONDOWN,\
		WM_KEYDOWN, WM_CANCELMODE,\
		WM_ERASEBKGND, WM_ACTIVATE,\
		WM_CREATE, WM_CLOSE, WM_DESTROY,\
		WM_SYSCOLORCHANGE, WM_SETTINGCHANGE
MainM	DD	MainWM_NOTIFY, MainWM_COMMAND, MainWM_MENUSELECT,\
		MainWM_SIZING, MainWM_ENTERSIZEMOVE, MainWM_WINDOWPOSCHANGED,\
		MainWM_MOUSEMOVE, MainWM_LBUTTONDOWN, MainWM_LBUTTONUP, MainWM_RBUTTONDOWN,\
		MainWM_KEYDOWN, MainWM_CANCELMODE,\
		MainWM_ERASEBKGND, MainWM_ACTIVATE,\
		MainWM_CREATE, MainWM_CLOSE, MainWM_DESTROY,\
		MainWM_SYSCOLORCHANGE, MainWM_SETTINGCHANGE

	CODE
	ALIGN	4
MainWND:
	FRAME	hWnd, uMsg, wParam, lParam
	USES	ebx,esi,edi

;IF message is found
	mov	eax,[uMsg]
	mov	edi,ADDR MainMsg
	mov	ecx,SIZEOF(MainMsg)/4
	repne scasd
	jne	>.Default

;THEN process this message possibly setting carry flag for default processing
	call	D[edi+SIZEOF(MainMsg)-4]
	jc	>.Default
.Return
	ret
;ELSE let DefWindowProc handle this message
	ALIGN	4
.Default
	push	[lParam]		;lParam
	push	[wParam]		;wParam
	push	[uMsg]			;Msg
	push	[hWnd]			;hWnd
	call	[DefWindowProc]		;User32

	jmp	<.Return
	ENDF


;;
;;	MAIN WINDOW NOTIFICATION MESSAGES
;;

	CONST
	ALIGN	4
MainNtf	DD	TVN_KEYDOWN, NM_SETFOCUS, TTN_GETDISPINFO
MainN	DD	TVNKeyDown, NMSetFocus, TTNGetDispInfo

	CODE
	ALIGN	4
MainWM_NOTIFY:
	USEDATA	MainWND SHIELDSIZE:20h

;IF message is found
	mov	ebx,[lParam]	;lParam=pNMHDR
	mov	edi,ADDR MainNtf
	mov	ecx,SIZEOF(MainNtf)/4
	mov	eax,[ebx+NMHDR.code]
	repne	scasd
	jne	>.Default

;THEN process this message possibly setting carry flag for default processing
	call	D[edi+SIZEOF(MainNtf)-4]
.Return
 	ret
;ELSE let DefWindowProc handle this message
	ALIGN	4
.Default
	stc			;set carry flag for default processing
	jmp	<.Return
	ENDU


;;
;;	MAIN WINDOW MENU COMMANDS
;;

	CONST
	ALIGN	4
MainCmd	DD	IDM_OPEN, IDM_CLOSE, IDM_EXIT,\
		IDM_TOOLBAR, IDM_STATUSBAR, IDM_TREEVIEW, IDM_SPLIT,\
		IDM_FONT,\
		IDM_HELPTOPICS, IDM_ABOUT
MainC	DD	FileOPEN, FileCLOSE, MainWM_CLOSE,\
		ViewTB, ViewSB, ViewTV, SplitCMD,\
		ViewFONT,\
		HelpTOPICS, HelpABOUT

	CODE
	ALIGN	4
MainWM_COMMAND:
	USEDATA	MainWND

;IF message is found
	mov	eax,[wParam]	;LOWORD(wParam)=ID
	mov	edi,ADDR MainCmd
	mov	ecx,SIZEOF(MainCmd)/4
	and	eax,0FFFFh
	repne	scasd
	jne	>.Default

;THEN process this message possibly setting carry flag for default processing
	call	D[edi+SIZEOF(MainCmd)-4]
.Return
 	ret
;ELSE let DefWindowProc handle this message
	ALIGN	4
.Default
	stc			;set carry flag for default processing
	jmp	<.Return
	ENDU


;;
;;	MAIN WINDOW CREATION
;;

	CONST
	ALIGN	4
szMainClass	DSS	"Main",0
	ALIGN	4
szTBclass	DSS	"ToolBarWindow32",0
	ALIGN	4
szSBclass	DSS	"msctls_statusbar32",0
	ALIGN	4
szTVclass	DSS	"SysTreeView32",0
	ALIGN	4
tbButtons	TBBUTTON <0, IDM_OPEN, TBSTATE_ENABLED, TBSTYLE_BUTTON, 0, 0>

	DATA
	ALIGN	4
;Bits for View menu options
fOptions	DD	111b
OPT_TB		=	001b	;ToolBar bit
OPT_SB		=	010b	;StatusBar bit
OPT_TV		=	100b	;TreeView bit

mii	MENUITEMINFO <SIZEOF MENUITEMINFO,MIIM_STATE,>

hInst		DD	?
hwndMain	DD	?
hMenu		DD	?
hAccel		DD	?

hToolBar	DD	?
hStatusBar	DD	?
hTreeView	DD	?
hCursor		DD	?

	CODE
	ALIGN	4
MainINIT:
	FRAME
	LOCAL	iccx:INITCOMMONCONTROLSEX, wcx:WNDCLASSEX

;Make sure only one instance of this application is running
	call	MainINSTANCE

	test	eax,eax
	jz	>>.Error

;Get module handle for this process
	push	0			;lpModuleName
	call	[GetModuleHandle]	;Kernel32

	test	eax,eax
	jz	>>.Error

	mov	[hInst],eax
	mov	ebx,eax		;EBX=hInst

;Initialize Common Controls
	mov	D[iccx.dwSize],SIZEOF INITCOMMONCONTROLSEX
	mov	D[iccx.dwICC],ICC_TREEVIEW_CLASSES | ICC_BAR_CLASSES

	push	ADDR iccx		;lpInitCtrls
	call	[InitCommonControlsEx]	;ComCtl32

;Register the Main window class
	xor	eax,eax		;EAX=0
	mov	D[wcx.cbSize],SIZEOF WNDCLASSEX
	mov	[wcx.style],eax
	mov	[wcx.lpfnWndProc],ADDR MainWND
	mov	[wcx.cbClsExtra],eax
	mov	[wcx.cbWndExtra],eax
	mov	[wcx.hInstance],ebx

	push	0			;fuLoad
	push	32			;cyDesired
	push	32			;cxDesired
	push	IMAGE_ICON		;uType
	push	IDI_ICON		;lpszName - image identifier
	push	ebx			;hinst
	call	[LoadImage]		;User32

	mov	[wcx.hIcon],eax

	push	LR_DEFAULTSIZE | LR_SHARED	;fuLoad
	push	0			;cyDesired - uses default
	push	0			;cxDesired - uses default
	push	IMAGE_CURSOR		;uType
	push	OCR_SIZEWE		;lpszName - image identifier
	push	0			;hinst - OEM image
	call	[LoadImage]		;User32

	mov	[wcx.hCursor],eax
	mov	[hCursor],eax

	mov	D[wcx.hbrBackground],0	;paint own background
	mov	D[wcx.lpszMenuName],IDM_MENU
	mov	[wcx.lpszClassName],ADDR szMainClass

	push	0			;fuLoad
	push	16			;cyDesired
	push	16			;cxDesired
	push	IMAGE_ICON		;uType
	push	IDI_ICON		;lpszName - image identifier
	push	ebx			;hinst
	call	[LoadImage]		;User32

	mov	[wcx.hIconSm],eax

	push	ADDR wcx		;lpwcx
	call	[RegisterClassEx]	;User32

	test	eax,eax
	jz	>.Error

;Get system info
	call	MainSETTING

;Get saved settings from the Registry
	call	RegGET

;Create the Main window
	xor	eax,eax		;EAX=0

	push	eax			;lpParam
	push	ebx			;hInstance
	push	eax			;hMenu - NULL, use class menu
	push	eax			;hWndParent
	push	eax			;nHeight
	push	eax			;nWidth
	push	eax			;Y
	push	eax			;X
	push	WS_OVERLAPPEDWINDOW	;dwStyle
	push	eax			;lpWindowName
	push	ADDR szMainClass	;lpClassName
	push	eax			;dwExStyle
	call	[CreateWindowEx]	;User32

	test 	eax,eax		;EAX=hwndMain
	jz	>.Error

;Set the Main window placement
	mov	esi,ADDR wpMain
	mov	edi,eax		;EDI=hwndMain
	mov	eax,[esi+WINDOWPLACEMENT.showCmd]
	mov	edx,SW_SHOWNORMAL
	cmp	eax,SW_SHOWMINIMIZED	;do not open minimized
	jne	>

	mov	[esi+WINDOWPLACEMENT.showCmd],edx
:
	push	esi			;lpwndpl
	push	edi			;hWnd
	call	[SetWindowPlacement]	;User32

;Update the Main window
	push	edi			;hWnd
	call	[UpdateWindow]		;User32

;Set the text for the Main window title bar
	call	FileINIT

	xor	eax,eax		;return 0 to continue
.Return
	ret
.Error
	inc	eax		;return non-zero exit code
	jmp	<.Return
	ENDF


	ALIGN	4
MainINSTANCE:
;IF a Semaphore can be created for the first instance
	push	ADDR szTitle		;lpName
	push	1			;lMaximumCount
	push	0			;lInitialCount
	push	0			;lpSemaphoreAttributes
	call	[CreateSemaphore]	;Kernel32

	mov	edi,eax		;EDI=hSemaphore

	call	[GetLastError]		;Kernel32

	cmp	eax,ERROR_ALREADY_EXISTS
	je	>.Exists

	cmp	eax,ERROR_SUCCESS
	jne	>.Find		;NE if CreateSemaphore failed so find other instance

;THEN continue
	xor	eax,eax
	inc	eax		;return non-zero to continue
	jmp	>.Return

;ELSE the Semaphore already exists so close its handle
.Exists
	push	edi			;hObject
	call	[CloseHandle]		;Kernel32

;THEN try to find another instance already running
.Find
	push	0			;lpWindowName
	push	ADDR szMainClass	;lpClassName
	call	[FindWindow]		;User32

	test	eax,eax
	jz	>.Return		;return 0 to exit

	push	eax			;hWnd
	call	[GetLastActivePopup]	;User32

	mov	esi,eax		;ESI=hMainWnd or hPopupWnd

;IF the window is minimized
	push	esi			;hWnd
	call	[IsIconic]		;User32

	test	eax,eax
	jz	>.Activate	;Z if not minimized

;THEN restore window to its normal placement
	push	SW_RESTORE		;nCmdShow
	push	esi			;hWnd
	call	[ShowWindow]		;User32

	jmp	>.Return0		;return 0 to exit

;ELSE activate the window and bring it to the foreground
.Activate
	push	esi			;hWnd
	call	[SetForegroundWindow]	;User32
.Return0
	xor	eax,eax		;return 0 to exit
.Return
	ret


	ALIGN	4
MainWM_CREATE:
	USEDATA	MainWND
	LOCAL	tbab:TBADDBITMAP

;Get handle to Main window and save it
	mov	esi,[hWnd]	;ESI=hwndMain
	mov	ebx,[hInst]	;EBX=hInst
	mov	[hwndMain],esi

;Load Accelerators
	push	IDA_ACCEL		;lpTableName - resource identifier
	push	ebx			;hInstance
	call	[LoadAccelerators]	;User32

	test	eax,eax
	jz	>>.Error

	mov	[hAccel],eax

;Get handle to Main menu and save it
	push	esi			;hWnd
	call	[GetMenu]		;User32

	test	eax,eax
	jz	>>.Error

	mov	[hMenu],eax
	mov	edi,eax		;EDI=hMenu

;Create the ToolBar window and update its menu item info
	mov	eax,MFS_UNCHECKED	;hidden state
	mov	ecx,WS_CHILD | TBSTYLE_TOOLTIPS | TBSTYLE_FLAT
	test	D[fOptions],OPT_TB
	jz	>

	mov	eax,MFS_CHECKED		;visible state
	or	ecx,WS_VISIBLE		;visible style adjustment
:
	mov	[mii.fState],eax
	xor	eax,eax		;EAX=0

	push	eax			;lpParam
	push	ebx			;hInstance
	push	ID_TOOLBAR		;hMenu - window identifier
	push	esi			;hWndParent
	push	eax			;nHeight
	push	eax			;nWidth
	push	eax			;Y
	push	eax			;X
	push	ecx			;dwStyle
	push	eax			;lpWindowName
	push	ADDR szTBclass		;lpClassName
	push	eax			;dwExStyle
	call	[CreateWindowEx]	;User32

	test	eax,eax
	jz	>>.Error

	mov	[hToolBar],eax

	push	ADDR mii		;lpmii
	push	FALSE			;fByPosition
	push	IDM_TOOLBAR		;uItem
	push	edi			;hMenu
	call	[SetMenuItemInfo]	;User32

;Initialize the ToolBar window
	push	edi			;save hMenu

	mov	edi,[hToolBar]		;EDI=hToolBar
	mov	[tbab.hInst],ebx
	mov	D[tbab.nID],IDB_TOOLBAR

	push	0			;lParam
	push	SIZEOF TBBUTTON 	;wParam - cbSize
	push	TB_BUTTONSTRUCTSIZE	;Msg
	push	edi			;hWnd
	call	[SendMessage]		;User32

	push	0			;lParam
	push	8			;wParam - indentation in pixels
	push	TB_SETINDENT		;Msg
	push	edi			;hWnd
	call	[SendMessage]		;User32

	push	00100010h		;lParam - 16x16
	push	0			;wParam
	push	TB_SETBITMAPSIZE	;Msg
	push	edi			;hWnd
	call	[SendMessage]		;User32

	push	ADDR tbab		;lParam	- ptbab
	push	1			;wParam - nButtons
	push	TB_ADDBITMAP		;Msg
	push	edi			;hWnd
	call	[SendMessage]		;User32

	push	ADDR tbButtons		;lParam	- pButtons
	push	1			;wParam - uNumButtons
	push	TB_ADDBUTTONS		;Msg
	push	edi			;hWnd
	call	[SendMessage]		;User32

	push	0			;lParam
	push	0			;wParam
	push	TB_AUTOSIZE		;Msg
	push	edi			;hWnd
	call	[SendMessage]		;User32

	pop	edi			;restore hMenu

;Create the StatusBar window and update its menu item info
	mov	eax,MFS_UNCHECKED	;hidden state
	mov	ecx,WS_CHILD		;hidden style
	test	D[fOptions],OPT_SB
	jz	>

	mov	eax,MFS_CHECKED		;visible state
	or	ecx,WS_VISIBLE		;visible style adjustment
:
	mov	[mii.fState],eax
	xor	eax,eax

	push	eax			;lpParam
	push	ebx			;hInstance
	push	ID_STATUSBAR		;hMenu - window identifier
	push	esi			;hWndParent
	push	eax			;nHeight
	push	eax			;nWidth
	push	eax			;Y
	push	eax			;X
	push	ecx			;dwStyle
	push	ADDR szReady		;lpWindowName
	push	ADDR szSBclass		;lpClassName
	push	eax			;dwExStyle
	call	[CreateWindowEx]	;User32

	test	eax,eax
	jz	>>.Error

	mov	[hStatusBar],eax

	push	ADDR mii		;lpmii
	push	FALSE			;fByPosition
	push	IDM_STATUSBAR		;uItem
	push	edi			;hMenu
	call	[SetMenuItemInfo]	;User32

;Create the TreeView window with keyboard focus and update its menu item info
	mov	eax,MFS_UNCHECKED	;hidden state
	mov	ecx,WS_CHILD | TVS_SHOWSELALWAYS | TVS_LINESATROOT | TVS_HASLINES | TVS_HASBUTTONS
	test	D[fOptions],OPT_TV
	jz	>

	mov	eax,MFS_CHECKED		;visible state
	or	ecx,WS_VISIBLE		;visible style adjustment
:
	mov	[mii.fState],eax
	xor	eax,eax

	push	eax			;lpParam
	push	ebx			;hInstance
	push	ID_TREEVIEW		;hMenu - window identifier
	push	esi			;hWndParent
	push	eax			;nHeight
	push	eax			;nWidth
	push	eax			;Y
	push	eax			;X
	push	ecx			;dwStyle
	push	eax			;lpWindowName
	push	ADDR szTVclass		;lpClassName
	push	WS_EX_CLIENTEDGE	;dwExStyle
	call	[CreateWindowEx]	;User32

	test	eax,eax
	jz	>.Error

	mov	[hTreeView],eax
	mov	[hwndFocus],eax

	push	eax			;hWnd
	call	[SetFocus]		;User32

	push	ADDR mii		;lpmii
	push	FALSE			;fByPosition
	push	IDM_TREEVIEW		;uItem
	push	edi			;hMenu
	call	[SetMenuItemInfo]	;User32

;Set state of Split menu item based on TreeView visibility
	mov	eax,MFS_DISABLED
	test	D[fOptions],OPT_TV
	jz	>

	mov	eax,MFS_ENABLED
:
	mov	[mii.fState],eax

	push	ADDR mii		;lpmii
	push	FALSE			;fByPosition
	push	IDM_SPLIT		;uitem
	push	edi			;hMenu
	call	[SetMenuItemInfo]	;User32

;Initialize the View window
	call	ViewINIT

	test	eax,eax
	jz	>.Error

;Update Font for windows
	call	FontUPDATE

	xor	eax,eax		;return 0 to continue
.Return
	ret
.Error
	dec	eax		;return -1 to exit
	jmp	<.Return
	ENDU


	ALIGN	4
MainWM_SETTINGCHANGE:
	call	MainSETTING	;get settings
	call	MainCHANGED	;update display
	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


	ALIGN	4
MainSETTING:
;Get system scroll bar size used to limit sizing of Main window
	push	SM_CXVSCROLL		;nIndex
	call	[GetSystemMetrics]	;User32

	mov	[cxVScroll],eax

;Get system drag state used in display of splitter bar movement
	push	0			;fWinIni
	push	ADDR bDragFull		;pvParam
	push	0			;uiParam
	push	SPI_GETDRAGFULLWINDOWS	;uiAction
	call	[SystemParametersInfo]	;User32

	ret


;;
;;	MAIN WINDOW TERMINATION
;;

	CODE
	ALIGN	4
MainWM_CLOSE:
;Close the file
	call	FileUNMAP

;IF maximized THEN adjust split position back to normal position
	xor	esi,esi
	call	SplitFIX

;Save settings to the Registry
	call	RegSET

;Delete saved settings from the Registry?
	push	MB_YESNO		;uType
	push	ADDR szRegDc		;lpCaption
	push	ADDR szRegDt		;lpText
	push	[hwndMain]		;hWnd
	call	[MessageBox]		;User32

	cmp	eax,IDNO
	je	>

	call	RegDELETE
:
;Send WM_DESTROY to destroy the Main window and exit
	push	[hwndMain]		;hWnd
	call	[DestroyWindow]		;User32

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


	ALIGN	4
MainWM_DESTROY:
;Delete the Font
	push	[hOldFont]		;hgdiobj
	push	[hdcView]		;hdc
	call	[SelectObject]		;Gdi32

	push	[hFont]			;hObject
	call	[DeleteObject]		;Gdi32

;Post WM_QUIT to the message queue to exit
	push	0			;nExitCode
	call	[PostQuitMessage]	;User32

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


;;
;;	REGISTRY MANAGEMENT FOR SAVED SETTINGS
;;

	CONST
	ALIGN	4
szMainKey 	DSS	"Software\WJR",0
	ALIGN	4
szSubKey	DSS	"Software\WJR\Alive",0
	ALIGN	4
szFont		DSS	"Font",0
	ALIGN	4
szOptions	DSS	"Options",0
	ALIGN	4
szPlacement	DSS	"Placement",0
	ALIGN	4
szRegDc		DSS	"Alive - Delete Settings?",0
	ALIGN	4
szRegDt		DSS	"Settings have been saved in the Registry.",0Dh,0Ah
		DSS	"If you have finished playing with Alive,",0Dh,0Ah
		DSS	"would you like these settings removed?",0

	DATA
hkSubKey	DD	?
cbData		DD	?
cSubKeys	DD	?

	CODE
	ALIGN	4
RegGET:
	xor	ebx,ebx		;EBX=0 for some parameters

;Get handle to Registry SubKey if it exists
	mov	esi,ADDR hkSubKey

	push	esi			;phkResult
	push	KEY_READ		;samDesired
	push	ebx			;ulOptions - reserved 0
	push	ADDR szSubKey		;lpSubKey
	push	HKEY_CURRENT_USER	;hKey
	call	[RegOpenKeyEx]		;AdvApi32

	test	eax,eax		;ERROR_SUCCESS=0
	jnz	>.Return	;NZ if run for the first time

;Get saved information in Registry
	mov	edi,ADDR cbData	;EDI=pcbData
	mov	esi,[esi]	;ESI=hkSubKey
;Font
	mov	D[edi],SIZEOF LOGFONT

	push	edi			;lpcbData
	push	ADDR lfView		;lpData
	push	ebx			;lpType
	push	ebx			;lpReserved
	push	ADDR szFont		;lpValueName
	push	esi			;hKey
	call	[RegQueryValueEx]	;AdvApi32
;Options
	mov	D[edi],4

	push	edi			;lpcbData
	push	ADDR fOptions		;lpData
	push	ebx			;lpType
	push	ebx			;lpReserved
	push	ADDR szOptions		;lpValueName
	push	esi			;hKey
	call	[RegQueryValueEx]	;AdvApi32
;Placement
	mov	D[edi],SIZEOF WINDOWPLACEMENT+4	;wpMain + rcSplit.Left

	push	edi			;lpcbData
	push	ADDR wpMain		;lpData
	push	ebx			;lpType
	push	ebx			;lpReserved
	push	ADDR szPlacement	;lpValueName
	push	esi			;hKey
	call	[RegQueryValueEx]	;AdvApi32

;Close handle to Registry SubKey - should return ERROR_SUCCESS=0
	push	esi			;hKey
	call	[RegCloseKey]		;AdvApi32
.Return
	ret


	ALIGN	4
RegSET:
	xor	ebx,ebx		;EBX=0 for some parameters

;Get handle to Registry SubKey and create it if it does not exist
	mov	esi,ADDR hkSubKey

	push	ebx			;lpdwDisposition - NULL, not needed
	push	esi			;phkResult
	push	ebx			;lpSecurityAttributes
	push	KEY_WRITE		;samDesired
	push	REG_OPTION_NON_VOLATILE	;dwOptions
	push	ebx			;lpClass
	push	ebx			;Reserved
	push	ADDR szSubKey		;lpSubKey
	push	HKEY_CURRENT_USER	;hKey
	call	[RegCreateKeyEx]	;AdvApi32

	test	eax,eax		;ERROR_SUCCESS=0
	jnz	>.Return

;Save settings in Registry
	mov	esi,[esi]	;ESI=hkSubKey
;Font
	push	SIZEOF LOGFONT		;cbData
	push	ADDR lfView		;lpData
	push	REG_BINARY		;dwType
	push	ebx			;Reserved
	push	ADDR szFont		;lpValueName
	push	esi			;hKey
	call	[RegSetValueEx]		;AdvApi32
;Options
	push	4			;cbData
	push	ADDR fOptions		;lpData
	push	REG_DWORD		;dwType
	push	ebx			;Reserved
	push	ADDR szOptions		;lpValueName
	push	esi			;hKey
	call	[RegSetValueEx]		;AdvApi32
;Placement
	push	SIZEOF WINDOWPLACEMENT+4;cbData = wpMain + rcSplit.Left
	push	ADDR wpMain		;lpData
	push	REG_BINARY		;dwType
	push	ebx			;Reserved
	push	ADDR szPlacement	;lpValueName
	push	esi			;hKey
	call	[RegSetValueEx]		;AdvApi32

;Close handle to Registry SubKey - should return ERROR_SUCCESS=0
	push	esi			;hKey
	call	[RegCloseKey]		;AdvApi32
.Return
	ret


	ALIGN	4
RegDELETE:
	xor	ebx,ebx		;EBX=0 for some parameters

;Delete Registry SubKey for saved settings
	push	ADDR szSubKey		;lpSubKey
	push	HKEY_CURRENT_USER	;hKey
	call	[RegDeleteKey]		;AdvApi32

;IF Registry MainKey exists
	mov	esi,ADDR hkSubKey

	push	esi			;phkResult
	push	KEY_READ		;samDesired
	push	ebx			;ulOptions - reserved 0
	push	ADDR szMainKey		;lpSubKey
	push	HKEY_CURRENT_USER	;hKey
	call	[RegOpenKeyEx]		;Advpi32

	test	eax,eax		;ERROR_SUCCESS=0
	jnz	>.Return	;NZ if it does not exist

;THEN get the number of SubKeys
	mov	esi,[esi]		;ESI=hMainKey
	mov	edi,ADDR cSubKeys	;EDI=pcSubKeys

	push	ebx			;lpftLastWriteTime
	push	ebx			;lpcbSecurityDescriptor
	push	ebx			;lpcbMaxValueLen
	push	ebx			;lpcbMaxValueNameLen
	push	ebx			;lpcValues
	push	ebx			;lpcbMaxClassLen
	push	ebx			;lpcbMaxSubKeyLen
	push	edi			;lpcSubKeys
	push	ebx			;lpReserved
	push	ebx			;lpcbClass
	push	ebx			;lpClass
	push	esi			;hKey
	call	[RegQueryInfoKey]	;AdvApi32

	push	esi			;hKey
	call	[RegCloseKey]		;AdvApi32

;AND IF SubKeys do not exist
	mov	eax,[edi]
	test	eax,eax
	jnz	>.Return	;NZ if subkeys exist so do not delete

;THEN delete Registry MainKey - should return ERROR_SUCCESS=0
	push	ADDR szMainKey		;lpSubKey
	push	HKEY_CURRENT_USER	;hKey
	call	[RegDeleteKey]		;AdvApi32
.Return
	ret


;;
;;	MAIN WINDOW PLACEMENT
;;

	DATA
	ALIGN	4
wpMain	WINDOWPLACEMENT	<SIZEOF WINDOWPLACEMENT,0,SW_SHOWDEFAULT,\
		<0,0>, <0,0>, <0, 0, 260h, 1A0h>>
;IMPORTANT to keep rcSplit after wpMain for Registry Placement setting.
;Split bar becomes effective Main client area after removing child window areas
rcSplit		RECT	<0BCh,0,0,0>	;rcSplit.right=0 when not visible

rcMain		RECT	<>	;Main window client area
rcToolBar	RECT	<>	;ToolBar screen coordinates
rcStatusBar	RECT	<>	;StatusBar screen coordinates

rcSizing	RECT	<>	;used to limit sizing

cxVScroll	DD	?	;initialized in MainSETTING

	CODE
	ALIGN	4
MainWM_ENTERSIZEMOVE:
	USEDATA	MainWND
	LOCAL	rc:RECT

;Set rcSizing limits for left and right movement
	mov	esi,ADDR rcSizing
	mov	edi,[hwndMain]

	mov	ecx,[cxVScroll]
	mov	eax,[rcSplit.left]
	mov	edx,[rcSplit.right]
	lea	ecx,[ecx+ecx*2]	;3*cxVScroll to limit left and right movement
	test	edx,edx		;NZ if TreeView visible
	jnz	>.Adjust

	add	ecx,ecx		;x2
	mov	eax,[rcMain.right]
	mov	edx,[rcMain.left]
.Adjust
	sub	eax,ecx
	add	edx,ecx
	sub	eax,4		;adjustment for borders
	add	edx,2
	mov	[esi+RECT.left],eax
	mov	[esi+RECT.right],edx

	push	esi			;lpPoint
	push	edi			;hWnd
	call	[ClientToScreen]	;User32

	push	ADDR rcSizing.right	;lpPoint
	push	edi			;hWnd
	call	[ClientToScreen]	;User32

;Set rcSizing limits for top and bottom movement
	push	ADDR rc			;lpRect
	push	edi			;hWnd
	call	[GetWindowRect]		;User32

	mov	eax,[cyChar]		;allow for three lines of text
	lea	ecx,[eax+eax*2+80h]	;3*cyChar + adjustment for title and menu

	mov	eax,[rc.bottom]	;for limit of top movement
	mov	edx,[rc.top]	;for limit of bottom movement
	sub	eax,ecx
	add	edx,ecx
	mov	[esi+RECT.top],eax
	mov	[esi+RECT.bottom],edx

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret
	ENDU


	ALIGN	4
MainWM_SIZING:
	USEDATA	MainWND

	mov	esi,ADDR rcSizing
	mov	edi,[lParam]
;Limit left movement
	mov	eax,[esi+RECT.left]
	cmp	eax,[edi+RECT.left]
	jge	>

	mov	[edi+RECT.left],eax
:
;Limit top movement
	mov	eax,[esi+RECT.top]
	cmp	eax,[edi+RECT.top]
	jge	>

	mov	[edi+RECT.top],eax
:
;Limit right movement
	mov	eax,[esi+RECT.right]
	cmp	eax,[edi+RECT.right]
	jle	>

	mov	[edi+RECT.right],eax
:
;Limit bottom movement
	mov	eax,[esi+RECT.bottom]
	cmp	eax,[edi+RECT.bottom]
	jle	>

	mov	[edi+RECT.bottom],eax
:
	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret
	ENDU


	ALIGN	4
MainWM_WINDOWPOSCHANGED:
	USEDATA	MainWND

;Get window placement of Main window
	push	ADDR wpMain		;lpwndpl
	push	[hwndMain]		;hWnd
	call	[GetWindowPlacement]	;User32

;Keep split bar position fixed when sizing with left border
	mov	esi,[lParam]		;ESI=pWINDOWPOS
	call	SplitFIX

;Get client area of Main window
	mov	edi,ADDR rcMain

	push	edi			;lpRect
	push	[hwndMain]		;hWnd
	call	[GetClientRect]		;User32

;Set HIWORD(EBX)=nHeight and LOWORD(EBX)=nWidth for ToolBar and StatusBar
	mov	eax,[edi+RECT.bottom]
	mov	ebx,[edi+RECT.right]
	shl	eax,16
	add	ebx,eax		;EBX=client area

;Notify ToolBar of size change and get new dimensions in screen coordinates
	mov	edi,[hToolBar]

	push	ebx			;lParam	- client area
	push	SIZE_RESTORED		;wParam - resizing flag
	push	WM_SIZE			;Msg
	push	edi			;hWnd
	call	[SendMessage]		;User32

	push	ADDR rcToolBar		;lpRect
	push	edi			;hWnd
	call	[GetWindowRect]		;User32

;Notify StatusBar of size change and get new dimensions in screen coordinates
	mov	edi,[hStatusBar]

	push	ebx			;lParam - client area
	push	SIZE_RESTORED		;wParam - resizing flag
	push	WM_SIZE			;Msg
	push	edi			;hWnd
	call	[SendMessage]		;User32

	push	ADDR rcStatusBar	;lpRect
	push	edi			;hWnd
	call	[GetWindowRect]		;User32

;Update display
	call	MainCHANGED

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret
	ENDU


	ALIGN	4
MainCHANGED:
;Limit left and right splitter bar movement
	mov	ecx,[cxVScroll]
	mov	eax,[rcSplit.left]
	lea	ecx,[ecx+ecx*2]		;3*cxVScroll
	mov	edx,[rcMain.right]
	cmp	eax,ecx
	jg	>		;G if split position is OK at left

	mov	eax,ecx		;ELSE set to left most position
:
	sub	edx,ecx
	dec	edx
	cmp	eax,edx
	jbe	>		;BE if split position is OK at right

	mov	eax,edx		;ELSE set to right most position
:
	mov	[rcSplit.left],eax

	mov	eax,[fOptions]
	xor	ecx,ecx		;rcSplit.right=0 if not visible
	test	eax,OPT_TV
	jz	>.NoTV		;Z if not visible

	mov	ecx,[rcSplit.left]
	add	ecx,3		;rcSplit.right if visible
.NoTV
	mov	[rcSplit.right],ecx

;Set vertical position and size of View and TreeView windows
	mov	esi,[rcMain.top]	;ESI=yView
	mov	edi,[rcMain.bottom]	;EDI=cyView
	test	eax,OPT_TB
	jz	>.NoTB		;Z if not visible

	mov	ecx,[rcToolBar.bottom]
	mov	edx,[rcToolBar.top]
	sub	ecx,edx
	add	esi,ecx		;adjusted by cyToolBar
.NoTB
	test	eax,OPT_SB
	jz	>.NoSB		;Z if not visible

	mov	ecx,[rcStatusBar.bottom]
	mov	edx,[rcStatusBar.top]
	sub	ecx,edx
	sub	edi,ecx		;adjusted by cyStatusBar
.NoSB
	mov	[rcSplit.top],esi
	mov	[rcSplit.bottom],edi
	sub	edi,esi		;adjusted by cyToolBar and cyStatusBar

	mov	eax,[rcSplit.right]	;EAX=xView  =0 if TreeView not visible
	mov	ecx,[rcMain.right]
	sub	ecx,eax			;ECX=cxView  =cxMain-cxTreeView

;Update dimensions of the View window
	push	SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOSENDCHANGING	;uFlags
	push	edi			;cy
	push	ecx			;cx
	push	esi			;Y
	push	eax			;X
	push	0			;hWndInsertAfter
	push	[hwndView]		;hWnd
	call	[SetWindowPos]		;User32

;Update dimensions of the TreeView window
	push	SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOSENDCHANGING	;uFlags
	push	edi			;cy
	push	[rcSplit.left]		;cx
	push	esi			;Y
	push	0			;X
	push	0			;hWndInsertAfter
	push	[hTreeView]		;hWnd
	call	[SetWindowPos]		;User32

	ret


;;
;;	SPLITTER BAR MOVEMENT SUPPORT
;;

	DATA
	ALIGN	4
bDragFull	DD	?	;initialized in MainSETTING
bDragSplit	DD	?	;0 inactive, 1 active
hdcSplit	DD	?
xSplit		DD	?
dxSplit		DD	?	;SplitFIX adjustment to split position
xMain		DD	?	;SplitFIX uses this to track change in position
cxMain		DD	?	;SplitFIX uses this to track change in size
hwndFocus	DD	?	;used with SplitBEGIN and SplitEND
				; and with MainWM_ACTIVATE, NMSetFocus

	CODE
	ALIGN	4
SplitCMD:
	FRAME
	LOCAL	rc:RECT

;Get midpoint coordinates of splitter bar
	mov	edx,[rcSplit.left]
	mov	eax,[rcSplit.top]
	mov	[rc.left],edx
	mov	[rc.top],eax
	mov	edx,[rcSplit.right]
	mov	eax,[rcSplit.bottom]
	mov	[rc.right],edx
	mov	[rc.bottom],eax

	push	ADDR rc			;lpPoint
	push	[hwndMain]		;hWnd
	call	[ClientToScreen]	;User32

	push	ADDR rc.right		;lpPoint
	push	[hwndMain]		;hWnd
	call	[ClientToScreen]	;User32

	mov	ecx,[rc.bottom]
	mov	edx,[rc.top]
	mov	eax,[rc.left]	;EAX=xPos of cursor

	add	ecx,edx
	shr	ecx,1		;ECX=yPos of cursor

;Set cursor position to midpoint of splitter bar
	push	ecx			;X
	push	eax			;Y
	call	[SetCursorPos]		;User32

;Display split cursor
	push	[hCursor]		;hCursor
	call	[SetCursor]		;User32

;Activate split movement
	call	SplitBEGIN
	xor	eax,eax
	ret
	ENDF


	ALIGN	4
SplitBEGIN:
	FRAME
	LOCAL	rcClip:RECT

;IF already active THEN cancel ELSE activate
	mov	ebx,[bDragSplit]
	mov	edi,[hwndMain]
	test	ebx,ebx
	jnz	>>.Cancel	;NZ if already active so end

	inc	ebx
	mov	[bDragSplit],ebx	;1=active

;Direct all keyboard input to Main window saving previous keyboard focus
	push	edi			;hWnd
	call	[SetFocus]		;User32

	mov	[hwndFocus],eax

;Direct all mouse input to Main window
	push	edi			;hWnd
	call	[SetCapture]		;User32

;Limit cursor movement to within the Main window
	mov	ecx,[cxVScroll]		;used to further limit horizontal range
	mov	eax,[rcSplit.top]
	lea	ecx,[ecx+ecx*2]		;ECX=3*cxVScroll
	mov	[rcClip.top],eax
	mov	[rcClip.left],ecx	;left most position
	mov	edx,[rcMain.right]
	mov	eax,[rcSplit.bottom]
	sub	edx,ecx			;right most position
	mov	[rcClip.bottom],eax
	mov	[rcClip.right],edx

	push	ADDR rcClip		;lpPoint
	push	edi			;hWnd
	call	[ClientToScreen]	;User32

	push	ADDR rcClip.right	;lpPoint
	push	edi			;hWnd
	call	[ClientToScreen]	;User32

	push	ADDR rcClip		;lpRect
	call	[ClipCursor]		;User32

;Save split position
	mov	eax,[rcSplit.left]
	mov	[xSplit],eax

;Initialize split drawing
	push	edi			;hWnd
	call	[GetDC]			;User32

	mov	[hdcSplit],eax

	xor	ebx,ebx		;EBX=0 to draw new drag rectangle
	call	SplitDRAW
.Return
	ret
.Cancel
	mov	ebx,[rcSplit.left]	;EBX=split xPosition
	call	SplitEND
	jmp	<.Return
	ENDF


	ALIGN	4
SplitDRAW:			;EBX=0 on/off ELSE xPosition
	mov	eax,[bDragSplit]
	mov	esi,ADDR rcSplit
	test	eax,eax
	jz	>.Return

;Support for SPI_GETDRAGFULLWINDOWS - no drag rectangle
	mov	edx,[bDragFull]
	mov	eax,[esi+RECT.left]	;previous split position
	test	edx,edx
	jz	>.DrawIf	;Z if no drag full windows

	test	ebx,ebx
	jz	>.Return	;Z to turn on/off (nothing to turn off)

	cmp	ebx,eax		;IF no position change
	je	>.Return	;THEN do not update

	mov	[esi+RECT.left],ebx	;ELSE update position
	add	ebx,3
	mov	[esi+RECT.right],ebx
	call	MainCHANGED		;update display

	jmp	>.Return

;IF still active AND split position has moved
.DrawIf
	mov	edi,[hdcSplit]
	test	ebx,ebx
	jz	>.DrawElse	;Z to turn on/off

	cmp	ebx,eax		;IF no position change
	je	>.Return	;THEN do not update

;THEN erase old drag rectangle
	push	esi			;lprc
	push	edi			;hDC
 	call	[DrawFocusRect]		;User32

	mov	[esi+RECT.left],ebx	;update position
	add	ebx,3
	mov	[esi+RECT.right],ebx

;ELSE draw new OR erase old drag rectangle
.DrawElse
	push	esi			;lprc
	push	edi			;hDC
 	call	[DrawFocusRect]		;User32
.Return
	ret


	ALIGN	4
SplitEND:			;EBX=xPosition
;IF deactivated THEN return ELSE deactivate
	mov	eax,[bDragSplit]
	test	eax,eax
	jz	>.Return	;Z if already inactive so end

;Restore normal mouse input
	push	0			;lpRect - NULL to move anywhere
	call	[ClipCursor]		;User32

	call	[ReleaseCapture]	;User32

;Erase drag rectangle and end split drawing
	push	ebx		;save position

	xor	ebx,ebx		;EBX=0 to erase drag rectangle
	call	SplitDRAW

	pop	ebx		;restore position

	push	[hdcSplit]		;hDC
	push	[hwndMain]		;hWnd
	call	[ReleaseDC]		;User32

;Update the split position and display if moved
	mov	edx,ebx
	add	ebx,3
	mov	eax,[xSplit]
	mov	[rcSplit.left],edx
	mov	[rcSplit.right],ebx
	cmp	edx,eax
	je	>.Done

	call	MainCHANGED	;update display only if moved
.Done
	xor	eax,eax
	mov	[bDragSplit],eax	;0=inactive

;Restore the keyboard focus
	push	[hwndFocus]		;hWnd
	call	[SetFocus]		;User32
.Return
	ret


	ALIGN	4
SplitFIX:			;ESI=pWINDOWPOS or 0
	mov	ecx,[wpMain.showCmd]
	test	esi,esi		;NZ for WM_WINDOWPOSCHANGED processing
	jz	>.Close		;Z for WM_CLOSE processing

;Adjust split position so that sizing with left border does not move split bar
	cmp	ecx,SW_SHOWMINIMIZED
	je	>.Return	;E if minimized so no Split adjustment

	mov	eax,[esi+WINDOWPOS.x]	;get new position and width
	mov	edx,[esi+WINDOWPOS.cx]
	mov	ecx,[xMain]	;get old position and width
	mov	ebx,[cxMain]
	mov	[xMain],eax	;set new position and width
	mov	[cxMain],edx

	test	ebx,ebx		;no Split adjustment if cxMain=0 on startup
	jz	>.Return

	sub	ecx,eax		;ECX=change in xMain position
	jz	>.Return	;Z if no change so no Split adjustment

	sub	edx,ebx		;EDX=change in cxMain width
	jz	>.Return	;Z if no change so no Split adjustment

	mov	[dxSplit],ecx	;save adjustment for WM_CLOSE
.Adjust
	mov	eax,[rcSplit.left]
	mov	edx,[rcSplit.right]
	add	eax,ecx		;adjust split position
	test	edx,edx		;rcSplit.right=0 if not visible
	mov	[rcSplit.left],eax
	jz	>.Return

	add	eax,3		;rcSplit.right if visible
	mov	[rcSplit.right],eax
.Return
	ret

;IF maximized THEN adjust split position back to normal position
.Close
	cmp	ecx,SW_SHOWMAXIMIZED
	jne	<.Return

	mov	ecx,[dxSplit]
	neg	ecx		;adjustment for split position
	jmp	<.Adjust


;;
;;	SPLITTER BAR MOVEMENT MESSAGES
;;

	CODE
	ALIGN	4
MainWM_MOUSEMOVE:
	USEDATA	MainWND

	movsx	ebx,W[lParam]	;EBX=split xPosition from LOWORD(lParam) = x-coordinate of cursor
	call	SplitDRAW

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret
	ENDU


	ALIGN	4
MainWM_LBUTTONDOWN:
	call	SplitBEGIN

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


	ALIGN	4
MainWM_LBUTTONUP:
	mov	ebx,[rcSplit.left]	;EBX=split xPosition
	call	SplitEND

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


	ALIGN	4
MainWM_RBUTTONDOWN:
	mov	ebx,[xSplit]	;EBX=split xPosition
	call	SplitEND

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


	ALIGN	4
MainWM_KEYDOWN:
	USEDATA	MainWND
	LOCAL	pt:POINT

	mov	eax,[wParam]	;virtual-key code
	cmp	eax,VK_LEFT
	je	>.KeyL

	cmp	eax,VK_RIGHT
	je	>.KeyR

	cmp	eax,VK_ESCAPE
	je	>.KeyEsc

	cmp	eax,VK_RETURN
	je	>.KeyRet

	stc			;set carry flag for default processing
	jmp	>.Return
.KeyL
	mov	edi,-4
	jmp	>.Update
.KeyR
	mov	edi,4
	jmp	>.Update
.KeyEsc
	mov	ebx,[xSplit]	;EBX=split xPosition
	call	SplitEND
	jmp	>.Return0
.KeyRet
	mov	ebx,[rcSplit.left]	;EBX=split xPosition
	call	SplitEND
	jmp	>.Return0

;Update cursor xPosition by +/- amount in EDI
.Update
	push	ADDR pt			;lpPoint
	call	[GetCursorPos]		;User32

	mov	eax,[pt.x]
	mov	edx,[pt.y]
	add	eax,edi

	push	edx			;Y
	push	eax			;X
	call	[SetCursorPos]		;User32
.Return0
	xor	eax,eax		;return 0 - message processed, clear carry flag
.Return
	ret
	ENDU


	ALIGN	4
MainWM_CANCELMODE:
	mov	ebx,[xSplit]	;EBX=split xPosition
	call	SplitEND

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


;;
;;	OTHER MAIN WINDOW MESSAGES
;;

	CODE
	ALIGN	4
MainWM_ERASEBKGND:
	USEDATA	MainWND
	LOCAL	rcTB:RECT

;IF the ToolBar is visible
	mov	ebx,[fOptions]
	xor	ecx,ecx		;ECX=0 for left and top
	test	ebx,OPT_TB
	jz	>.NoTB		;Z if ToolBar not visible

;THEN erase background for transparent ToolBar
	mov	eax,[rcToolBar.right]
	mov	edx,[rcToolBar.left]
	sub	eax,edx			;width
	mov	[rcTB.left],ecx
	mov	[rcTB.right],eax
	mov	eax,[rcToolBar.bottom]
	mov	edx,[rcToolBar.top]
	sub	eax,edx			;height
	mov	[rcTB.top],ecx
	mov	[rcTB.bottom],eax

	push	COLOR_3DFACE + 1	;hbr
	push	ADDR rcTB      		;lprc
	push	[wParam]      		;hDC
	call	[FillRect]    		;User32
.NoTB
;IF the TreeView is visible
	test	ebx,OPT_TV
	jz	>.NoTV		;Z if TreeView not visible

;THEN erase background for splitter bar
	push	COLOR_3DFACE + 1	;hbr
	push	ADDR rcSplit		;lprc
	push	[wParam]      		;hDC
	call	[FillRect]    		;User32
.NoTV
	xor	eax,eax		;message processed, clear carry flag
	inc	eax		;return nonzero - background erased
	ret
	ENDU


	ALIGN	4
MainWM_ACTIVATE:
	USEDATA	MainWND

;IF activated AND not minimized
	mov	eax,[wParam]	;fActive = LOWORD(wParam)
	mov	edx,0FFFF0000h
	test	eax,WA_ACTIVE | WA_CLICKACTIVE
	jz	>.Return

	and	eax,edx		;fMinimized = HIWORD(wParam)
	jnz	>.Return

;THEN use saved TreeView or View keyboard focus OR set View as default
	mov	eax,[hwndFocus]
	mov	edx,[hwndView]
	test	eax,eax
	jnz	>.SetFocus

	mov	eax,edx
.SetFocus
	push	eax			;hWnd
	call	[SetFocus]		;User32
.Return
	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret
	ENDU


	ALIGN	4
MainWM_SYSCOLORCHANGE:
;TreeView should get this message too
	push	0			;lParam
	push	0			;wParam
	push	WM_SYSCOLORCHANGE	;Msg
	push	[hTreeView]		;hWnd
	call	[SendMessage]		;User32

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


;;
;;	STATUS BAR MANAGEMENT
;;

	CONST
	ALIGN	4
MenuHelpIDs	DD	0, IDM_FILEMENU	;for StatusBar help text
		DD	0, 0
szReady		DSS	"Ready",0
	ALIGN	4
szOpening	DSS	"Opening...",0
	ALIGN	4
szClosing	DSS	"Closing...",0

	CODE
	ALIGN	4
MainWM_MENUSELECT:
	USEDATA	MainWND

	push	ADDR MenuHelpIDs	;lpwIDs
	push	[hStatusBar]		;hwndStatus
	push	[hInst]			;hInst
	push	[hMenu]			;hMainMenu
	push	[lParam]		;lParam
	push	[wParam]		;wParam
	push	[uMsg]			;uMsg
	call	[MenuHelp]		;ComCtl32

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret
	ENDU


	ALIGN	4
StatusUPDATE:			;ESI=pszStatusText
;Update StatusBar text with given string
	push	esi			;lParam - pszText
	push	0			;wParam - iPart | uType
	push	SB_SETTEXT		;Msg
	push	[hStatusBar]		;hWnd
	call	[SendMessage]		;User32

	ret


;;
;;	TOOLTIP NOTIFICATION MESSAGES
;;

	CODE
	ALIGN	4
TTNGetDispInfo:			;EBX=lParam
	mov	eax,[ebx+NMTTDISPINFO.hdr.idFrom]
	mov	edx,[hInst]
	add	eax,80h		;EAX=Tooltip StringID
	mov	[ebx+NMTTDISPINFO.lpszText],eax
	mov	[ebx+NMTTDISPINFO.hinst],edx
	ret


;;
;;	TREEVIEW NOTIFICATION MESSAGES
;;

	CODE
	ALIGN	4
NMSetFocus:
;TreeView now has keyboard focus
	mov	eax,[hTreeView]
	mov	[hwndFocus],eax
	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


	ALIGN	4
TVNKeyDown:			;EBX=lParam PTR NMTVKEYDOWN
	xor	eax,eax
	mov	ax,[ebx+NMTVKEYDOWN.wVKey]
	cmp	eax,VK_TAB
	je	>.KeyTab

	xor	eax,eax		;return zero - include character in search
	jmp	>.Return

;TAB key sets the View window to have the keyboard focus
.KeyTab
	mov	esi,[hwndView]
	mov	[hwndFocus],esi

	push	esi			;hWnd
	call	[SetFocus]		;User32

	xor	eax,eax
	inc	eax		;return non-zero - exclude character from search
.Return
	ret


;;
;;	FILE MENU COMMANDS
;;

	CONST
	ALIGN	4
szTitle		DSS	"Alive - "
szUntitled	DSS	"Untitled",0
	ALIGN	4
szFilter	DSS	"All Files (*.*)",0,"*.*",0,0

	DATA
	ALIGN	4
ofn	OPENFILENAME <SIZEOF OPENFILENAME, 0, 0,\
			ADDR szFilter, 0, 0, 1,\
			ADDR szFileTemp, MAX_PATH,\
			0, 0,\
			0, 0, 0, 0, 0,\
			0, 0, 0, 0>

pCmdLine	DD	?
szWindowName	DB	SIZEOF szTitle DUP ?
szFile		DSS	MAX_PATH DUP ?
szFileTemp	DSS	MAX_PATH DUP ?

	CODE
	ALIGN	4
FileINIT:
;Set the text for the Main window title bar to the default
	xor	esi,esi
	call	FileNAME

;Process command line arguments
	call	[GetCommandLine]	;Kernel32

	mov	[pCmdLine],eax

	;;**** COMMAND LINE PROCESSING ****
	;;* possibly calling FileOPENING  *

	ret


	ALIGN	4
FileNAME:			;ESI=pszFileTemp or NULL for Untitled
;Set the text for the Main window title bar
	test	esi,esi
	jz	>.Untitled

	mov	edi,ADDR szFile
	mov	ecx,SIZEOF szFile
	jmp	>.Update
.Untitled
	mov	esi,ADDR szTitle
	mov	edi,ADDR szWindowName
	mov	ecx,SIZEOF szTitle + SIZEOF szUntitled

;Update the Main window title bar
.Update
	rep movsb

	push	ADDR szWindowName	;lpString
	push	[hwndMain]		;hWnd
	call	[SetWindowText]		;User32

	ret


	ALIGN	4
FileOPEN:
;Select a new file to open
	mov	esi,ADDR ofn
	mov	eax,[hwndMain]
	mov	ecx,OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY | OFN_EXPLORER
	mov	[esi+OPENFILENAME.hwndOwner],eax
	mov	[esi+OPENFILENAME.Flags],ecx

	push	esi			;lpofn
	call	[GetOpenFileName]	;ComDlg32

	test	eax,eax
	jz	>.Return

;Close the current file
	call	FileCLOSE

;Open the new file
	call	FileOPENING

.Return
	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


	ALIGN	4
FileOPENING:
;Display "Opening..." on the status bar
	mov	esi,ADDR szOpening
	call	StatusUPDATE

;Open the file
	call	FileMAP		;returns EAX=cbFile or 0

	test	eax,eax
	jz	>.Error		;Z if error opening file

;Update the name of the currently opened file
	mov	esi,ADDR szFileTemp
	call	FileNAME

;Set szFileTemp to NULL for next OPENFILENAME
	xor	eax,eax
	mov	D[szFileTemp],eax

;Set the state for the File Close menu item
	mov	D[mii.fState],MFS_ENABLED

	push	ADDR mii		;lpmii
	push	FALSE			;fByPosition
	push	IDM_CLOSE		;uItem
	push	[hMenu]			;hMenu
	call	[SetMenuItemInfo]	;User32

;View the file
	call	ViewFILE
.Return
	ret
.Error
;Close the file
	call	FileUNMAP

;Display "Ready" on the status bar
	mov	esi,ADDR szReady
	call	StatusUPDATE

	jmp	<.Return


	ALIGN	4
FileCLOSE:
;Display "Closing..." on the status bar
	mov	esi,ADDR szClosing
	call	StatusUPDATE

;Close the file
	call	FileUNMAP

;Set the text for the Main window title bar to the default
	xor	esi,esi
	call	FileNAME

;Disable the File Close menu item
	mov	D[mii.fState],MFS_DISABLED

	push	ADDR mii		;lpmii
	push	FALSE			;fByPosition
	push	IDM_CLOSE		;uItem
	push	[hMenu]			;hMenu
	call	[SetMenuItemInfo]	;User32

;Display "Ready" on the status bar
	mov	esi,ADDR szReady
	call	StatusUPDATE

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


;;
;;	MEMORY MAPPED FILE MANAGEMENT
;;

	DATA
	ALIGN	4
hFile		DD	?
hMapFile	DD	?
pMapFile	DD	?
cbFile		DD	?

	CODE
	ALIGN	4
FileMAP:
;Open the file
	push	0			;hTemplateFile
	push	FILE_ATTRIBUTE_NORMAL	;dwFlagsAndAttributes
	push	OPEN_EXISTING		;dwCreationDisposition
	push	0			;lpSecurityAttributes
	push	FILE_SHARE_READ		;dwShareMode
	push	GENERIC_READ		;dwDesiredAccess
	push	ADDR szFileTemp		;lpFileName
	call	[CreateFile]		;Kernel32

	cmp	eax,INVALID_HANDLE_VALUE
	je	>.Error

	mov	[hFile],eax

;Create file mapping
	push	0			;lpName
	push	0			;dwMaximumSizeLow
	push	0			;dwMaximumSizeHigh
	push	PAGE_READONLY		;fProtect
	push	0			;lpAttributes
	push	eax			;hFile
	call	[CreateFileMapping]	;Kernel32

	test	eax,eax
	jz	>.Error

	mov	[hMapFile],eax

;Map view of file
	push	0			;dwNumberOfBytesToMap
	push	0			;dwFileOffsetLow
	push	0			;dwFileOffsetHigh
	push	FILE_MAP_READ		;dwDesiredAccess
	push	eax			;hFileMappingObject
	call	[MapViewOfFile]		;Kernel32

	test	eax,eax
	jz	>.Error

	mov	[pMapFile],eax

;Get the file size
	xor	eax,eax
	mov	[cbFile],eax

	push	0			;lpFileSizeHigh
	push	[hFile]			;hFile
	call	[GetFileSize]		;Kernel32

	cmp	eax,0FFFFFFFFh
	je	>.Error

	mov	[cbFile],eax	;return EAX=cbFile
.Return
	ret
.Error
;Close the file
	call	FileUNMAP	;returns EAX=0
	jmp	<.Return


	ALIGN	4
FileUNMAP:
;Unmap view of file
	mov	eax,[pMapFile]
	test	eax,eax
	jz	>.NopMap

	push	eax			;lpBaseAddress
	call	[UnmapViewOfFile]	;Kernel32

	xor	eax,eax
	mov	[pMapFile],eax
.NopMap
;Close file mapping
	mov	eax,[hMapFile]
	test	eax,eax
	jz	>.NohMap

	push	eax			;hObject
	call	[CloseHandle]		;Kernel32

	xor	eax,eax
	mov	[hMapFile],eax
.NohMap
;Close the file
	mov	eax,[hFile]
	test	eax,eax
	jz	>.NohFile

	push	eax			;hObject
	call	[CloseHandle]		;Kernel32

	xor	eax,eax
	mov	[hFile],eax
.NohFile
	ret			;return 0


;;
;;	VIEW MENU COMMANDS
;;

	CODE
	ALIGN	4
ViewTB:
;Switch state of ToolBar
	mov	esi,ADDR fOptions
	mov	ebx,OPT_TB
	mov	eax,[esi]
	mov	edx,SW_HIDE
	mov	ecx,MFS_UNCHECKED
	xor	eax,ebx
	mov	edi,ADDR mii
	mov	[esi],eax
	test	eax,ebx
	jz	>

	mov	edx,SW_SHOW
	mov	ecx,MFS_CHECKED
:
	mov	[edi+MENUITEMINFO.fState],ecx

;Set new show state and menu item info
	push	edx			;nCmdShow
	push	[hToolBar]		;hWnd
	call	[ShowWindow]		;User32

	push	edi			;lpmii
	push	FALSE			;fByPosition
	push	IDM_TOOLBAR		;uItem
	push	[hMenu]			;hMenu
	call	[SetMenuItemInfo]	;User32

;Update display
	call	MainCHANGED

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


	ALIGN	4
ViewSB:
;Switch state of StatusBar
	mov	esi,ADDR fOptions
	mov	ebx,OPT_SB
	mov	eax,[esi]
	mov	edx,SW_HIDE
	mov	ecx,MFS_UNCHECKED
	xor	eax,ebx
	mov	edi,ADDR mii
	mov	[esi],eax
	test	eax,ebx
	jz	>

	mov	edx,SW_SHOW
	mov	ecx,MFS_CHECKED
:
	mov	[edi+MENUITEMINFO.fState],ecx

;Set new show state and menu item info
	push	edx			;nCmdShow
	push	[hStatusBar]		;hWnd
	call	[ShowWindow]		;User32

	push	edi			;lpmii
	push	FALSE			;fByPosition
	push	IDM_STATUSBAR		;uItem
	push	[hMenu]			;hMenu
	call	[SetMenuItemInfo]	;User32

;Update display
	call	MainCHANGED

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


	ALIGN	4
ViewTV:
;Switch state of TreeView
	mov	esi,ADDR fOptions
	mov	ebx,OPT_TV
	mov	eax,[esi]
	mov	edx,SW_HIDE
	mov	ecx,MFS_UNCHECKED
	xor	eax,ebx
	mov	edi,ADDR mii
	mov	[esi],eax
	test	eax,ebx
	jz	>

	mov	edx,SW_SHOW
	mov	ecx,MFS_CHECKED
:
	mov	[edi+MENUITEMINFO.fState],ecx

;Set new show state and menu item info
	push	edx			;nCmdShow
	push	[hTreeView]		;hWnd
	call	[ShowWindow]		;User32

	push	edi			;lpmii
	push	FALSE			;fByPosition
	push	IDM_TREEVIEW		;uItem
	push	[hMenu]			;hMenu
	call	[SetMenuItemInfo]	;User32

;Set state of Split menu item based on TreeView visibility
	mov	eax,[esi]	;fOptions
	mov	ecx,MFS_DISABLED
	test	eax,ebx		;TreeView bit
	jz	>

	mov	ecx,MFS_ENABLED
:
	mov	[edi+MENUITEMINFO.fState],ecx

	push	edi			;lpmii
	push	FALSE			;fByPosition
	push	IDM_SPLIT		;uItem
	push	[hMenu]			;hMenu
	call	[SetMenuItemInfo]	;User32

;Update display
	call	MainCHANGED

;IF TreeView is visible THEN set keyboard focus to it ELSE to View window
	mov	eax,[fOptions]
	mov	edx,[hwndView]
	test	eax,OPT_TV
	jz	>

	mov	edx,[hTreeView]
:
	push	edx			;hWnd
	call	[SetFocus]		;User32

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


;;
;;	FONT MANAGEMENT
;;

	DATA
	ALIGN	4
lfView	LOGFONT	<16,,,, FW_NORMAL,,,,,,,\
		PROOF_QUALITY, FIXED_PITCH | FF_MODERN, "Arial">
cf	CHOOSEFONT <SIZEOF CHOOSEFONT,,,ADDR lfView,,\
		CF_INITTOLOGFONTSTRUCT | CF_BOTH,>

hFont		DD ?
hOldFont	DD ?
cyChar		DD ?

	CODE
	ALIGN	4
ViewFONT:
;Choose a new Font
	mov	eax,[hwndMain]
	mov	[cf.hwndOwner],eax

	push	ADDR cf			;lpcf
	call	[ChooseFont]		;ComDlg32

	test	eax,eax
	jz	>.Return

;Restore previous Font and delete current Font
	push	[hOldFont]		;hgdiobj
	push	[hdcView]		;hdc
	call	[SelectObject]		;User32

	push	eax			;hObject
	call	[DeleteObject]		;User32

;Update windows with new Font
	call	FontUPDATE

	xor	eax,eax		;return 0 - message processed, clear carry flag
.Return
	ret


	ALIGN	4
FontUPDATE:
;Create new Font
	push	ADDR lfView		;lplf
	call	[CreateFontIndirect]	;Gdi32

	test	eax,eax		;EAX=hFont
	jz	>.Return

	mov	[hFont],eax

;Select new Font into View window device context
	mov	esi,[hdcView]

	push	eax			;hgdiobj
	push	esi			;hDC
	call	[SelectObject]		;Gdi32

	mov	[hOldFont],eax

;Get height of characters
	sub	esp,40h		;LOCAL ESP=ADDR tm  SIZEOF TEXTMETRIC + padding

	push	esp			;lptm
	push	esi			;hdc
	call	[GetTextMetrics]	;Gdi32

	mov	eax,[esp+TEXTMETRIC.tmHeight]
	mov	[cyChar],eax
	add	esp,40h		;LOCAL tm removed

;Notify TreeView of new Font
	push	TRUE			;lParam	- TRUE to redraw
	push	[hFont]			;wParam - hFont
	push	WM_SETFONT		;Msg
	push	[hTreeView]		;hWnd
	call	[SendMessage]		;User32

;Update View window with new Font
	push	TRUE			;bErase - erase background
	push	ADDR rcView		;lpRect
	push	[hwndView]		;hWnd
	call	[InvalidateRect]	;User32
.Return
	ret


;;
;;	HELP MENU COMMANDS
;;

	CONST
	ALIGN	4
szHelpFile DSS	"Skeleton.chm",0

	CODE
	ALIGN	4
HelpTOPICS:
	push	0	       		;dwData
	push	HH_DISPLAY_TOPIC	;uCommand
	push	ADDR szHelpFile		;pszFile
	push	[hwndMain] 		;hwndCaller
	call	HtmlHelp		;HtmlHelp

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


	ALIGN	4
HelpABOUT:
	push	0	       		;dwInitParam
	push	ADDR AboutDLG		;lpDialogFunc
	push	[hwndMain] 		;hWndParent
	push	IDD_ABOUT		;lpTemplateName - integer resource identifierID
	push	[hInst]	       		;hInstance
	call	[DialogBoxParam]	;User32

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


	ALIGN	4
AboutDLG:
	FRAME	hWnd, uMsg, wParam, lParam
;	USES	ebx,esi,edi	;need to save these if used below

	mov	eax,[uMsg]

	cmp	eax,WM_INITDIALOG
	je	>.Processed	;E to process - no initializing required

	cmp	eax,WM_COMMAND
	je	>.Commands
.Default
	xor	eax,eax		;return FALSE for message not processed
	jmp	>.Return
.Commands
	mov	eax,[wParam]
	and	eax,0FFFFh
	cmp	eax,IDOK
	je	>.Done

	cmp	eax,IDCANCEL
	je	>.Done

	jmp	<.Default
.Done
	push	TRUE			;nResult
	push	[hWnd]			;hDlg
	call	[EndDialog]		;User32
.Processed
	mov	eax,TRUE	;return TRUE for message processed
.Return
	ret
	ENDF


;;
;;	VIEW WINDOW CREATION
;;

	CONST
	ALIGN	4
szViewClass	DSS	"View",0

	DATA
hwndView	DD	?
hdcView		DD	?

	CODE
	ALIGN	4
ViewINIT:
	FRAME
	LOCAL	wcx:WNDCLASSEX

;Register View window class
	xor	eax,eax		;EAX=0
	mov	ebx,[hInst]	;EBX=hInst

	mov	D[wcx.cbSize],SIZEOF WNDCLASSEX
	mov	D[wcx.style],CS_OWNDC
	mov	[wcx.lpfnWndProc],ADDR ViewWND
	mov	[wcx.cbClsExtra],eax
	mov	[wcx.cbWndExtra],eax
	mov	[wcx.hInstance],ebx
	mov	[wcx.hIcon],eax
	mov	[wcx.hIconSm],eax

	push	LR_DEFAULTSIZE | LR_SHARED	;fuLoad
	push	0			;cyDesired - uses default
	push	0			;cxDesired - uses default
	push	IMAGE_CURSOR		;uType
	push	OCR_NORMAL		;lpszName - image identifier
	push	0			;hinst - OEM image
	call	[LoadImage]		;User32

	mov	[wcx.hCursor],eax
	mov	D[wcx.hbrBackground],COLOR_WINDOW + 1
	mov	D[wcx.lpszMenuName],0
	mov	[wcx.lpszClassName],ADDR szViewClass

	push	ADDR wcx		;lpwcx
	call	[RegisterClassEx]	;User32

	test	eax,eax
	jz	>.Return

;Create the View window
	xor	eax,eax		;EAX=0

	push	eax			;lpParam
	push	ebx			;hInstance
	push	ID_VIEW			;hMenu - window identifier
	push	[hwndMain]		;hWndParent
	push	eax			;nHeight
	push	eax			;nWidth
	push	eax			;Y
	push	eax			;X
	push	WS_CHILD | WS_CLIPSIBLINGS | WS_VISIBLE | WS_VSCROLL | WS_HSCROLL ;dwStyle
	push	eax			;lpWindowName
	push	ADDR szViewClass	;lpClassName
	push	WS_EX_CLIENTEDGE | WS_EX_NOPARENTNOTIFY	;dwExStyle
	call	[CreateWindowEx]	;User32

	test 	eax,eax		;EAX=hwndView
	jz	>.Return

	mov	[hwndView],eax

;Get CS_OWNDC for the View window
	push	eax			;hWnd
	call	[GetDC]			;User32

	mov	[hdcView],eax	;return non-zero to continue
.Return
	ret
	ENDF

;;
;;	VIEW WINDOW MESSAGES
;;

       	CONST
	ALIGN	4
ViewMsg	DD	WM_PAINT, WM_KEYDOWN, WM_WINDOWPOSCHANGED
ViewM	DD	ViewWM_PAINT, ViewWM_KEYDOWN, ViewWM_WINDOWPOSCHANGED

	CODE
	ALIGN	4
ViewWND:
	FRAME	hWnd, uMsg, wParam, lParam
	USES	ebx,esi,edi

;IF message is not found
	mov	eax,[uMsg]
	mov	edi,ADDR ViewMsg
	mov	ecx,SIZEOF(ViewMsg)/4
	repne scasd
	je	>.Process

;THEN let DefWindowProc handle this message
.Default
	push	[lParam]		;lParam
	push	[wParam]		;wParam
	push	[uMsg]			;uMsg
	push	[hWnd]			;hWnd
	call	[DefWindowProc]		;User32

	jmp	>.Return

;ELSE process this message possibly setting carry flag for default processing
	ALIGN	4
.Process
	call	D[edi+SIZEOF(ViewMsg)-4]
	jc	.Default
.Return
	ret
	ENDF

;;
;;	VIEW WINDOW PLACEMENT
;;

	DATA
	ALIGN	4
rcView	RECT	<>		;View window client area

	CODE
	ALIGN	4
ViewWM_WINDOWPOSCHANGED:
;Get client area of View window
	push	ADDR rcView		;lpRect
	push	[hwndView]		;hWnd
	call	[GetClientRect]		;User32

	;;****  OTHER SIZE/POSITION PROCESSING  ****

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


;;
;;	OTHER VIEW WINDOW MESSAGES
;;

	CODE
	ALIGN	4
ViewWM_PAINT:
	USEDATA	ViewWND
	LOCAL	ps:PAINTSTRUCT

	push	ADDR ps			;lpPaint
	push	[hwndView]		;hWnd
	call	[BeginPaint]		;User32

	;;****  PAINT CLIENT AREA  ****

	push	ADDR ps			;lpPaint
	push	[hwndView]		;hWnd
	call	[EndPaint]		;User32

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret
	ENDU


	ALIGN	4
ViewWM_KEYDOWN:
	USEDATA	ViewWND

	mov	eax,[wParam]	;virtual-key code
	cmp	eax,VK_TAB
	je	>.KeyTab

	stc		;set carry flag for default processing
	jmp	>.Return

;TAB key sets the TreeView window to have the keyboard focus
.KeyTab
	mov	eax,[hTreeView]
	mov	[hwndFocus],eax

	push	eax			;hWnd
	call	[SetFocus]		;User32
.Return0
	xor	eax,eax		;return 0 - message processed, clear carry flag
.Return
	ret
	ENDU


	ALIGN	4
ViewFILE:
	;;**** OTHER FILE PROCESSING ****

;Update the client area of the View window
	push	TRUE			;bErase - erase background
	push	ADDR rcView		;lpRect
	push	[hwndView]		;hWnd
	call	[InvalidateRect]	;User32

;Display "Ready" on the status bar
	mov	esi,ADDR szReady
	call	StatusUPDATE

	ret