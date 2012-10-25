;;
;;   commdlg.h -- This module defines the 32-Bit Common Dialog APIs
;;   Copyright (c) 1992-1999, Microsoft Corp. All rights reserved.
;;
OPENFILENAME	STRUCT
lStructSize	DD
hwndOwner	DD
hInstance	DD
lpstrFilter	DD
lpstrCustomFilter	DD
nMaxCustFilter	DD
nFilterIndex	DD
lpstrFile	DD
nMaxFile	DD
lpstrFileTitle	DD
nMaxFileTitle	DD
lpstrInitialDir	DD
lpstrTitle	DD
Flags	DD
nFileOffset	DW
nFileExtension	DW
lpstrDefExt	DD
lCustData	DD
lpfnHook	DD
lpTemplateName	DD
	ENDS
;GetOpenFileName(lpofn)
GetOpenFileName	= GetOpenFileName##AW
OFN_HIDEREADONLY	= 4h
OFN_PATHMUSTEXIST	= 800h
OFN_FILEMUSTEXIST	= 1000h
OFN_EXPLORER	= 80000h
CHOOSEFONT	STRUCT
lStructSize	DD
hwndOwner	DD
hDC	DD
lpLogFont	DD
iPointSize	DD
Flags	DD
rgbColors	DD
lCustData	DD
lpfnHook	DD
lpTemplateName	DD
hInstance	DD
lpszStyle	DD
nFontType	DW
	DW
nSizeMin	DD
nSizeMax	DD
	ENDS
;ChooseFont(lpcf)
ChooseFont	= ChooseFont##AW
CF_SCREENFONTS	= 00000001h
CF_PRINTERFONTS	= 00000002h
CF_BOTH	= CF_SCREENFONTS | CF_PRINTERFONTS
CF_INITTOLOGFONTSTRUCT	= 00000040h