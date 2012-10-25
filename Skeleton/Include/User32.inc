;;
;; winuser.h -- USER procedure declarations, constant definitions and macros
;; Copyright (c) 1985 - 1999, Microsoft Corporation
;;
SW_HIDE	= 0
SW_SHOWNORMAL	= 1
SW_SHOWMINIMIZED	= 2
SW_SHOWMAXIMIZED	= 3
SW_SHOW	= 5
SW_RESTORE	= 9
SW_SHOWDEFAULT	= 10
VK_TAB	= 9h
VK_RETURN	= 0Dh
VK_ESCAPE	= 1Bh
VK_LEFT	= 25h
VK_RIGHT	= 27h
WNDCLASSEX	STRUCT
cbSize	DD
style	DD
lpfnWndProc	DD
cbClsExtra	DD
cbWndExtra	DD
hInstance	DD
hIcon	DD
hCursor	DD
hbrBackground	DD
lpszMenuName	DD
lpszClassName	DD
hIconSm	DD
	ENDS
MSG	STRUCT
hwnd	DD
message	DD
wParam	DD
lParam	DD
time	DD
pt	POINT
	ENDS
WM_CREATE	= 1h
WM_DESTROY	= 2h
WM_SIZE	= 5h
WM_ACTIVATE	= 6h
WA_ACTIVE	= 1
WA_CLICKACTIVE	= 2
WM_PAINT	= 0Fh
WM_CLOSE	= 10h
WM_ERASEBKGND	= 14h
WM_SYSCOLORCHANGE	= 15h
WM_SETTINGCHANGE	= 1Ah
WM_CANCELMODE	= 1Fh
WM_SETFONT	= 30h
WM_WINDOWPOSCHANGED	= 47h
WM_NOTIFY	= 4Eh
WM_KEYDOWN	= 100h
WM_INITDIALOG	= 110h
WM_COMMAND	= 111h
WM_MENUSELECT	= 11Fh
WM_MOUSEMOVE	= 200h
WM_LBUTTONDOWN	= 201h
WM_LBUTTONUP	= 202h
WM_RBUTTONDOWN	= 204h
WM_SIZING	= 214h
WM_ENTERSIZEMOVE	= 231h
WM_USER	= 400h
SIZE_RESTORED	= 0
WINDOWPOS	STRUCT
hwnd	DD
hwndInsertAfter	DD
x	DD
y	DD
cx	DD
cy	DD
flags	DD
	ENDS
WS_OVERLAPPED	= 0h
WS_CHILD	= 40000000h
WS_VISIBLE	= 10000000h
WS_CLIPSIBLINGS	= 4000000h
WS_CAPTION	= 0C00000h
WS_BORDER	= 800000h
WS_VSCROLL	= 200000h
WS_HSCROLL	= 100000h
WS_SYSMENU	= 80000h
WS_THICKFRAME	= 40000h
WS_MINIMIZEBOX	= 20000h
WS_MAXIMIZEBOX	= 10000h
WS_OVERLAPPEDWINDOW	= WS_OVERLAPPED|WS_CAPTION|WS_SYSMENU|WS_THICKFRAME|WS_MINIMIZEBOX|WS_MAXIMIZEBOX
WS_EX_NOPARENTNOTIFY	= 4h
WS_EX_CLIENTEDGE	= 200h
CS_OWNDC	= 20h
PAINTSTRUCT	STRUCT
hdc	DD
fErase	DD
rcPaint	RECT
fRestore	DD
fIncUpdate	DD
rgbReserved	DB 32 DUP ?
	ENDS
WINDOWPLACEMENT	STRUCT
length	DD
flags	DD
showCmd	DD
ptMinPosition	POINT
ptMaxPosition	POINT
rcNormalPosition	RECT
	ENDS
NMHDR	STRUCT
hwndFrom	DD
idFrom	DD
code	DD
	ENDS
;GetMessage(lpMsg,hWnd,wMsgFilterMin,wMsgFilterMax)
GetMessage	= GetMessage##AW
;TranslateMessage(lpMsg)
;DispatchMessage(lpMsg)
DispatchMessage	= DispatchMessage##AW
;SendMessage(hWnd,Msg,wParam,lParam)
SendMessage	= SendMessage##AW
;DefWindowProc(hWnd,Msg,wParam,lParam)
DefWindowProc	= DefWindowProc##AW
;PostQuitMessage(nExitCode)
;RegisterClassEx(lpwcx)
RegisterClassEx	= RegisterClassEx##AW
;CreateWindowEx(dwExStyle,lpClassName,lpWindowName,dwStyle,X,Y,nWidth,nHeight,hWndParent,hMenu,hInstance,lpParam)
CreateWindowEx	= CreateWindowEx##AW
;DestroyWindow(hWnd)
;ShowWindow(hWnd,nCmdShow)
;SetWindowPos(hWnd,hWndInsertAfter,X,Y,cx,cy,uFlags)
;GetWindowPlacement(hWnd,lpwndpl)
;SetWindowPlacement(hWnd,lpwndpl)
;IsIconic(hWnd)
SWP_NOZORDER	= 4h
SWP_NOACTIVATE	= 10h
SWP_NOSENDCHANGING	= 400h
;DialogBoxParam(hInstance,lpTemplateName,hWndParent,lpDialogFunc,dwInitParam)
DialogBoxParam	= DialogBoxParam##AW
;EndDialog(hDlg,nResult)
;SetFocus(hWnd)
;SetCapture(hWnd)
;ReleaseCapture()
;LoadAccelerators(hInstance,lpTableName)
LoadAccelerators	= LoadAccelerators##AW
;TranslateAccelerator(hWnd,hAccTable,lpMsg)
TranslateAccelerator	= TranslateAccelerator##AW
SM_CXVSCROLL	= 2
;GetSystemMetrics(nIndex)
;GetMenu(hWnd)
MIIM_STATE	= 1h
MENUITEMINFO	STRUCT
cbSize	DD
fMask	DD
fType	DD
fState	DD
wID	DD
hSubMenu	DD
hbmpChecked	DD
hbmpUnchecked	DD
dwItemData	DD
dwTypeData	DD
cch	DD
hbmpItem	DD
	ENDS
;SetMenuItemInfo(hMenu,uItem,fByPosition,lpmii)
SetMenuItemInfo	= SetMenuItemInfo##AW
;UpdateWindow(hWnd)
;SetForegroundWindow(hWnd)
;GetDC(hWnd)
;ReleaseDC(hWnd,hDC)
;BeginPaint(hWnd,lpPaint)
;EndPaint(hWnd,lpPaint)
;InvalidateRect(hWnd,lpRect,bErase)
;SetWindowText(hWnd,lpString)
SetWindowText	= SetWindowText##AW
;GetClientRect(hWnd,lpRect)
;GetWindowRect(hWnd,lpRect)
MB_YESNO	= 4h
;MessageBox(hWnd,lpText,lpCaption,uType)
MessageBox	= MessageBox##AW
;SetCursorPos(X,Y)
;SetCursor(hCursor)
;GetCursorPos(lpPoint)
;ClipCursor(lpRect)
;ClientToScreen(hWnd,lpPoint)
COLOR_WINDOW	= 5
COLOR_BTNFACE	= 15
COLOR_3DFACE	= COLOR_BTNFACE
;DrawFocusRect(hDC,lprc)
;FillRect(hDC,lprc,hbr)
;FindWindow(lpClassName,lpWindowName)
FindWindow	= FindWindow##AW
;GetLastActivePopup(hWnd)
MFS_DISABLED	= 3h
MFS_UNCHECKED	= 0h
MFS_CHECKED	= 8h
MFS_ENABLED	= 0h
IMAGE_ICON	= 1
IMAGE_CURSOR	= 2
LR_DEFAULTSIZE	= 40h
LR_SHARED	= 8000h
;LoadImage(hinst,lpszName,uType,cxDesried,cyDesired,fuLoad)
LoadImage	= LoadImage##AW
OCR_NORMAL	= 32512
OCR_SIZEWE	= 32644
IDOK	= 1
IDCANCEL	= 2
IDNO	= 7
SPI_GETDRAGFULLWINDOWS	= 26h
;SystemParametersInfo(uiAction,uiParam,pvParam,fWinIni)
SystemParametersInfo	= SystemParametersInfo##AW