; bite PEB

.386
.model flat, stdcall
option casemap :none
assume fs:nothing

    include \masm32\include\windows.inc
    include \masm32\include\user32.inc
    include \masm32\include\kernel32.inc

    includelib \masm32\lib\user32.lib
    includelib \masm32\lib\kernel32.lib

.data
    WndTextOut1 db  "Kernel32 base address: 0x"
    WndTextOut2 db  8 dup (66), 13, 10
    WndTextFmt  db  "%x"

.code

start:    
    xor     esi,esi
    mov     esi,fs:[030h]
    mov     esi,[esi + 0Ch]
    mov     esi,[esi + 01Ch]
    mov     esi,[esi]
    mov     esi,[esi + 08h]

    push    esi
    push    offset WndTextFmt
    push    offset WndTextOut2
    call    wsprintfA

    push    STD_OUTPUT_HANDLE
    call    GetStdHandle

    push    NULL
    push    NULL
    push    SIZEOF WndTextOut1 + SIZEOF WndTextOut2
    push    offset WndTextOut1
    push    eax
    call    WriteFile


    push    0
    call    ExitProcess
exitFail:   
    push    1
    call    ExitProcess

end start