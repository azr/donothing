;==============================================================================
; IN THE FLESH
; SKELETON Version 3.2.1
; Copyright 2000-2007 Wayne J. Radburn
;
; Assembles with Jeremy Gordon's GoAsm as follows:
;    GoAsm Flesh.asm
;
; Links with Jeremy Gordon's GoLink as follows:
;    GoLink Flesh.obj Flesh.res Kernel32.dll User32.dll Gdi32.dll ComDlg32.dll ComCtl32.dll AdvApi32.dll Shell32.dll hhctrl.ocx
;
; See Flesh.rc for how to create Flesh.res
;==============================================================================

UNICODE	= 1		;Remove to build ANSI version
STRINGS	UNICODE		;Remove to build ANSI version

#include "Kernel32.inc"
#include "User32.inc"
#include "Gdi32.inc"
#include "ComDlg32.inc"
#include "ComCtl32.inc"
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

IDM_HELPTOPICS	= 28h
IDM_ABOUT	= 29h

;;
;;	WINDOW IDs
;;

ID_TOOLBAR	= 0F0h
ID_STATUSBAR	= 0F1h
ID_VIEW		= 0F2h

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
		WM_WINDOWPOSCHANGED,\
		WM_ERASEBKGND,\
		WM_CREATE, WM_CLOSE, WM_DESTROY
MainM	DD	MainWM_NOTIFY, MainWM_COMMAND, MainWM_MENUSELECT,\
		MainWM_WINDOWPOSCHANGED,\
		MainWM_ERASEBKGND,\
		MainWM_CREATE, MainWM_CLOSE, MainWM_DESTROY

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
MainNtf	DD	TTN_GETDISPINFO
MainN	DD	TTNGetDispInfo

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
		IDM_TOOLBAR, IDM_STATUSBAR,\
		IDM_HELPTOPICS, IDM_ABOUT
MainC	DD	FileOPEN, FileCLOSE, MainWM_CLOSE,\
		ViewTB, ViewSB,\
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
tbButtons	TBBUTTON <0, IDM_OPEN, TBSTATE_ENABLED, TBSTYLE_BUTTON, 0, 0>

	DATA
	ALIGN	4
;Bits for View menu options
fOptions	DD	111b
OPT_TB		=	001b	;ToolBar bit
OPT_SB		=	010b	;StatusBar bit

mii	MENUITEMINFO <SIZEOF MENUITEMINFO,MIIM_STATE,>

hInst		DD	?
hwndMain	DD	?
hMenu		DD	?
hAccel		DD	?

hToolBar	DD	?
hStatusBar	DD	?

	CODE
	ALIGN	4
MainINIT:
	FRAME
	LOCAL	iccx:INITCOMMONCONTROLSEX, wcx:WNDCLASSEX

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
	push	OCR_NORMAL		;lpszName - image identifier
	push	0			;hinst - OEM image
	call	[LoadImage]		;User32

	mov	[wcx.hCursor],eax
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

;Initialize the View window
	call	ViewINIT

	test	eax,eax
	jz	>.Error

	xor	eax,eax		;return 0 to continue
.Return
	ret
.Error
	dec	eax		;return -1 to exit
	jmp	<.Return
	ENDU


;;
;;	MAIN WINDOW TERMINATION
;;

	CODE
	ALIGN	4
MainWM_CLOSE:
;Close the file
	call	FileUNMAP

;Send WM_DESTROY to destroy the Main window and exit
	push	[hwndMain]		;hWnd
	call	[DestroyWindow]		;User32

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


	ALIGN	4
MainWM_DESTROY:
;Post WM_QUIT to the message queue to exit
	push	0			;nExitCode
	call	[PostQuitMessage]	;User32

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


;;
;;	MAIN WINDOW PLACEMENT
;;

	DATA
	ALIGN	4
wpMain	WINDOWPLACEMENT	<SIZEOF WINDOWPLACEMENT,0,SW_SHOWDEFAULT,\
		<0,0>, <0,0>, <0, 0, 260h, 1A0h>>

rcMain		RECT	<>	;Main window client area
rcToolBar	RECT	<>	;ToolBar screen coordinates
rcStatusBar	RECT	<>	;StatusBar screen coordinates

	CODE
	ALIGN	4
MainWM_WINDOWPOSCHANGED:
	USEDATA	MainWND

;Get window placement of Main window
	push	ADDR wpMain		;lpwndpl
	push	[hwndMain]		;hWnd
	call	[GetWindowPlacement]	;User32

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
	mov	eax,[fOptions]

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
	sub	edi,esi		;adjusted by cyToolBar and cyStatusBar

;Update dimensions of the View window
	push	SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOSENDCHANGING	;uFlags
	push	edi			;cy
	push	[rcMain.right]		;cx
	push	esi			;Y
	push	0			;X
	push	0			;hWndInsertAfter
	push	[hwndView]		;hWnd
	call	[SetWindowPos]		;User32

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
	xor	eax,eax		;message processed, clear carry flag
	inc	eax		;return nonzero - background erased
	ret
	ENDU


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
;;	FILE MENU COMMANDS
;;

	CONST
	ALIGN	4
szTitle		DSS	"Flesh - "
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
ViewMsg	DD	WM_PAINT, WM_WINDOWPOSCHANGED
ViewM	DD	ViewWM_PAINT, ViewWM_WINDOWPOSCHANGED

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