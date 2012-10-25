;;
;; wingdi.h -- GDI procedure declarations, constant definitions and macros
;; Copyright (c) 1985-1999, Microsoft Corp. All rights reserved.
;;
TEXTMETRIC	STRUCT
tmHeight	DD
tmAscent	DD
tmDescent	DD
tmInternalLeading	DD
tmExternalLeading	DD
tmAveCharWidth	DD
tmMaxCharWidth	DD
tmWeight	DD
tmOverhang	DD
tmDigitizedAspectX	DD
tmDigitizedAspectY	DD
tmFirstChar	DSS
tmLastChar	DSS
tmDefaultChar	DSS
tmBreakChar	DSS
tmItalic	DB
tmUnderlined	DB
tmStruckOut	DB
tmPitchAndFamily	DB
tmCharSet	DB
	DB
	DB
	DB
	ENDS
LF_FACESIZE	= 32
LOGFONT	STRUCT
lfHeight	DD
lfWidth	DD
lfEscapement	DD
lfOrientation	DD
lfWeight	DD
lfItalic	DB
lfUnderline	DB
lfStrikeOut	DB
lfCharSet	DB
lfOutPrecision	DB
lfClipPrecision	DB
lfQuality	DB
lfPitchAndFamily	DB
lfFaceName	DSS LF_FACESIZE DUP ?
	ENDS
PROOF_QUALITY	= 2
FIXED_PITCH	= 1
FW_NORMAL	= 400
FF_MODERN	= 30h
;CreateFontIndirect(lplf)
CreateFontIndirect	= CreateFontIndirect##AW
;DeleteObject(hObject)
;SelectObject(hdc,hgdiobj)
;GetTextMetrics(hdc,lptm)
GetTextMetrics	= GetTextMetrics##AW