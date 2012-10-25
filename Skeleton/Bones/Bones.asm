;==============================================================================
; BARE BONES
; SKELETON Version 3.2.1
; Copyright 2000-2007 Wayne J. Radburn
;
; Assembles with Jeremy Gordon's GoAsm as follows:
;    GoAsm Bones.asm
;
; Links with Jeremy Gordon's GoLink as follows:
;    GoLink Bones.obj Bones.res Kernel32.dll User32.dll Gdi32.dll ComDlg32.dll ComCtl32.dll AdvApi32.dll Shell32.dll hhctrl.ocx
;
; See Bones.rc for how to create Bones.res
;==============================================================================

UNICODE	= 1		;Remove to build ANSI version
STRINGS	UNICODE		;Remove to build ANSI version

#include "Kernel32.inc"
#include "User32.inc"
#include "HtmlHelp.inc"

;;
;;	RESOURCE IDs
;;

IDI_ICON	= 1h
IDM_MENU	= 1h
IDD_ABOUT	= 1h

IDM_FILEMENU	= 20h
IDM_HELPMENU	= 21h

IDM_EXIT	= 22h

IDM_HELPTOPICS	= 23h
IDM_ABOUT	= 24h


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
	jmp	>.Retrieve

;Dispatch the message to a window procedure
	ALIGN	4
.Dispatch
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
MainMsg	DD	WM_COMMAND,\
		WM_WINDOWPOSCHANGED,\
		WM_PAINT,\
		WM_CREATE, WM_CLOSE, WM_DESTROY
MainM	DD	MainWM_COMMAND,\
		MainWM_WINDOWPOSCHANGED,\
		MainWM_PAINT,\
		MainWM_CREATE, MainWM_CLOSE, MainWM_DESTROY

	CODE
	ALIGN	4
MainWND:
	FRAME	hWnd, uMsg, wParam, lParam
	USES	ebx,esi,edi

;IF message is not found
	mov	eax,[uMsg]
	mov	edi,ADDR MainMsg
	mov	ecx,SIZEOF(MainMsg)/4
	repne scasd
	je	>.Process

;THEN let DefWindowProc handle this message
.Default
	push	[lParam]		;lParam
	push	[wParam]		;wParam
	push	[uMsg]			;Msg
	push	[hWnd]			;hWnd
	call	[DefWindowProc]		;User32

	jmp	>.Return

;ELSE process this message possibly setting carry flag for default processing
	ALIGN	4
.Process
	call	D[edi+SIZEOF(MainMsg)-4]
	jc	<.Default
.Return
	ret
	ENDF


;;
;;	MAIN WINDOW MENU COMMANDS
;;

	CONST
	ALIGN	4
MainCmd	DD	IDM_EXIT,\
		IDM_HELPTOPICS, IDM_ABOUT
MainC	DD	MainWM_CLOSE,\
		HelpTOPICS, HelpABOUT

	CODE
	ALIGN	4
MainWM_COMMAND:
	USEDATA	MainWND

;IF message is not found
	mov	eax,[wParam]	;LOWORD(wParam)=ID
	mov	edi,ADDR MainCmd
	mov	ecx,SIZEOF(MainCmd)/4
	and	eax,0FFFFh
	repne	scasd
	je	>.Process

;THEN let DefWindowProc handle this message
	stc			;set carry flag for default processing
	jmp	>.Return

;ELSE process this message possibly setting carry flag for default processing
.Process
	call	D[edi+SIZEOF(MainCmd)-4]
.Return
 	ret
	ENDU


;;
;;	MAIN WINDOW CREATION
;;

	CONST
	ALIGN	4
szMainClass	DSS	"Main",0

	DATA
	ALIGN	4
hInst		DD	?
hwndMain	DD	?

	CODE
	ALIGN	4
MainINIT:
	FRAME
	LOCAL	wcx:WNDCLASSEX

;Get module handle for this process
	push	0			;lpModuleName
	call	[GetModuleHandle]	;Kernel32

	test	eax,eax
	jz	>>.Error

	mov	[hInst],eax
	mov	ebx,eax		;EBX=hInst

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
	mov	D[wcx.hbrBackground],COLOR_WINDOW + 1
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
	push	WS_OVERLAPPEDWINDOW | WS_VSCROLL | WS_HSCROLL	;dwStyle
	push	ADDR szTitle		;lpWindowName
	push	ADDR szMainClass	;lpClassName
	push	WS_EX_CLIENTEDGE	;dwExStyle
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

;Get handle to Main window and save it
	mov	esi,[hWnd]	;ESI=hwndMain
	mov	ebx,[hInst]	;EBX=hInst
	mov	[hwndMain],esi

	;;****  OTHER CREATION PROCESSING  ****

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

	CODE
	ALIGN	4
MainWM_WINDOWPOSCHANGED:
;Get window placement of Main window
	push	ADDR wpMain		;lpwndpl
	push	[hwndMain]		;hWnd
	call	[GetWindowPlacement]	;User32

;Get client area of Main window
	push	ADDR rcMain		;lpRect
	push	[hwndMain]		;hWnd
	call	[GetClientRect]		;User32

	;;****  OTHER SIZE/POSITION PROCESSING  ****

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret


;;
;;	OTHER MAIN WINDOW MESSAGES
;;

	CODE
	ALIGN	4
MainWM_PAINT:
	USEDATA	MainWND
	LOCAL	ps:PAINTSTRUCT

	push	ADDR ps			;lpPaint
	push	[hwndMain]		;hWnd
	call	[BeginPaint]		;User32

	;;****  PAINT CLIENT AREA  ****

	push	ADDR ps			;lpPaint
	push	[hwndMain]		;hWnd
	call	[EndPaint]		;User32

	xor	eax,eax		;return 0 - message processed, clear carry flag
	ret
	ENDU


;;
;;	FILE MENU COMMANDS
;;

	CONST
	ALIGN	4
szTitle		DSS	"Bones",0


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