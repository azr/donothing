;;
;; windef.h -- Basic Windows Type Definitions
;; Copyright (c) 1985-1999, Microsoft Corp. All rights reserved.
;;
MAX_PATH	= 260
NULL	= 0
FALSE	= 0
TRUE	= 1
#include	<WinNT.inc>
RECT 	STRUCT
left	DD
top 	DD
right	DD
bottom	DD
	ENDS
POINT	STRUCT
x   	DD
y   	DD
	ENDS