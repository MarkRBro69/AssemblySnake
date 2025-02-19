; game.asm

EXTERN malloc:PROC
EXTERN free:PROC

EXTERN InvalidateRect:PROC
EXTERN Sleep:PROC

EXTERN Read_Msg:PROC
EXTERN ProcessInput:PROC

;---------------------------------------------------------------------------------------------------------------

.data

    fieldSideSize equ 20        ; Field side size
    startX equ 10               ; Starting X position
    startY equ 10               ; Starting Y position
    WM_QUIT equ 12h             ; Quit message value
    arraySegmentSize equ 16     ; Size of one array segment

    emptyCellId equ 0           ; Empty cell id
    snakeHeadId equ 1           ; Snake head id
    snakeBodyId equ 2           ; Snake body id
    appleId equ 3               ; Apple id

    upKey equ 57h               ; Up key
    downKey equ 53h             ; Down key
    rightKey equ 44h            ; Right key
    leftKey equ 41h             ; Left key

    gameFlags db 00000001b      ; Game flags: 0 - is_runing

    hwndHandle dq 0             ; Window handler
    fieldArray dq 0             ; Field array
    fieldArrayLength dq 0       ; Field array length
    lastKey dq 0                ; Last key pressed

    snakeHead dq 0              ; Snake head
    snakeTail dq 0              ; Snake tail

;---------------------------------------------------------------------------------------------------------------

.code

;---------------------------------------------------------------------------------------------------------------
Read_Key PROC
; Read key and select direction
;   Parameters:
;       RCX - CL - Current X position
;       RDX - DL - Current Y position
;   Return:
;       RCX - Updated X position
;       RDX - Updated Y position

    mov rbx, qword ptr [lastKey]    ; RBX = lastKey address
    mov al, byte ptr [rbx]          ; AL = lastKeyPressed
    cmp al, upKey                   ; If lastKeyPressed == upKey
    je _up                          ; Decrement current Y position
    cmp al, downKey                 ; If lastKeyPressed == downKey
    je _down                        ; Increment current Y position
    cmp al, rightKey                ; If lastKeyPressed == rightKey
    je _right                       ; Increment current X position
    cmp al, leftKey                 ; If lastKeyPressed == leftKey
    je _left                        ; Decrement current X position

    ret

_up:
    dec dl                          ; Move up: Decrease Y
    ret

_down:
    inc dl                          ; Move down: Increase Y
    ret

_right:
    inc cl                          ; Move right: Increase X
    ret

_left:
    dec cl                          ; Move left: Decrease X
    ret

Read_Key ENDP
;---------------------------------------------------------------------------------------------------------------
Check_Position PROC
; Checking new head position
;   Parameters:
;       RCX = xCord (CL)
;       RDX = yCord (DL)

   cmp cl, fieldSideSize
   jae _out_of_range
   cmp dl, fieldSideSize
   jae _out_of_range

    ret

_out_of_range:
    and byte ptr [gameFlags], 11111110b

    ret

Check_Position ENDP
;---------------------------------------------------------------------------------------------------------------
Get_Random_Position PROC
; Get random position 0 - fieldSideSize
;   Return:
;       EDX - Random position

    rdtsc
    mov ecx, fieldSideSize
    xor edx, edx
    div ecx

    ret

Get_Random_Position ENDP
;---------------------------------------------------------------------------------------------------------------
Move_Head PROC
; Move head

    ; Add new head
    mov rcx, arraySegmentSize               ; RCX = arraySegmentSize (size of one array segment)
    sub rsp, 40
    call malloc                             ; Call malloc to allocate memory
    add rsp, 40
    test rax, rax                           ; Check if allocation was successful
    jz _error                               ; If allocation failed, jump to error

    mov r10, rax                            ; r10 = newSegmentAdress

    mov r11, snakeHead                      ; R11 = currentHeadAddress
    mov cl, byte ptr [r11 + 8]              ; CL = currentXPosition
    mov dl, byte ptr [r11 + 9]              ; DL = currentYPosition
    call Read_Key                           ; CL, DL = Updated (X, Y) position
    call Check_Position                     ; If new position is out of range, set is running flag to 0

    mov byte ptr [r10 + 8], cl              ; 9th byte (first byte of x-coordinate) = xCord
    mov byte ptr [r10 + 9], dl              ; 10th byte (first byte of y-coordinate) = yCord
    mov r8, snakeHeadId                     ; R8 = R8B = snakeHeadId
    call Fill_Array_Position                ; Fill field array position (x - cl, y - dl) with snakeHeadId

    mov cl, byte ptr [r11 + 8]              ; CL = Current snake tail X position
    mov dl, byte ptr [r11 + 9]              ; DL = Current snake tail Y position
    mov r8, snakeBodyId                     ; R8 = R8B = snakeBodyId
    call Fill_Array_Position                ; Fill field array position (x - cl, y - dl) with snakeBodyId
    
    mov qword ptr[r11], r10                 ; Set nextSegmentAddress
    mov snakeHead, r10

    ; Check if apple collected
    test byte ptr [gameFlags], 00000010b
    jnz _doNotRemoveTail


    ; Remove tail
    mov r10, snakeTail                      ; R10 = currentSnakeTailAddress

    mov cl, byte ptr [r10 + 8]              ; CL = Current snake tail X position
    mov dl, byte ptr [r10 + 9]              ; DL = Current snake tail Y position
    mov r8, emptyCellId                     ; R8 = R8B = emptyCellId
    call Fill_Array_Position                ; Fill field array position (x - cl, y - dl) with emptyCellId

    mov r11, qword ptr [r10]                ; R11 = nextSnakeTailAddress
    mov snakeTail, r11                      ; Set new tail

    mov rcx, r10                            ; RCX = currentSnakeTailAddress
    sub rsp, 40
    call free
    add rsp, 40

    ret

_error:
    ret

_doNotRemoveTail:
    and byte ptr [gameFlags], 11111101b
    call Add_Apple

    ret

Move_Head ENDP
;---------------------------------------------------------------------------------------------------------------
Fill_Array_Position PROC
; Calc and fill position in field array with an element
;   Parameters:
;       RCX - CL - xCord
;       RDX - DL - yCord
;       R8 - R8B - element id
    
    movzx rax, dl                           ; RAX = yCord
    mov rbx, fieldSideSize                  ; RBX = fieldSideSize
    mul rbx                                 ; RAX = startY * fieldSideSize = yCordOffset
    movzx rbx, cl                           ; RBX = xCord
    add rax, rbx                            ; RAX = yCordOffset + xCord = objCordOffset
    add rax, fieldArray                     ; RAX = objCordOffset + fieldArray = newObjAddress

    cmp r8b, snakeHeadId
    je _snakeHead
    cmp r8b, appleId
    je _appleId

_setNewElement:
    mov byte ptr [rax], r8b                 ; Set newObjAddress with element id
    ret

_snakeHead:
    cmp byte ptr [rax], appleId
    je _gotApple
    cmp byte ptr [rax], snakeBodyId
    je _gotBody
    jmp _setNewElement

    _gotApple:
        or byte ptr [gameFlags], 00000010b
        jmp _setNewElement

    _gotBody:
        and byte ptr [gameFlags], 11111110b
        jmp _setNewElement

_appleId:
    cmp byte ptr [rax], 0
    jne _appleFail
    jmp _setNewElement

    _appleFail:
        call Add_Apple
        ret

Fill_Array_Position ENDP
;---------------------------------------------------------------------------------------------------------------
Add_Apple PROC
; Add apple in random position

    call Get_Random_Position                ; EAX = random value 0 - fieldSideSize
    mov r10d, edx                           ; R10 = xCord
    call Get_Random_Position                ; EAX = random value 0 - fieldSideSize
    mov r11d, edx                           ; R11 = yCord

    mov rcx, r10                            ; RCX = CL = xCord
    mov rdx, r11                            ; RDX = DL = yCord
    mov r8, appleId                         ; R8 = R8B = appleId
    call Fill_Array_Position                ; Fill field array position (x - cl, y - dl) with appleId

    ret

Add_Apple ENDP
;---------------------------------------------------------------------------------------------------------------
Snake_Init PROC
; Snake initialization

    ; Allocate memory for start segment
    mov rcx, arraySegmentSize               ; RCX = arraySegmentSize (size of one array segment)
    sub rsp, 40
    call malloc                             ; Call malloc to allocate memory
    add rsp, 40

    test rax, rax                           ; Check if allocation was successful
    jz _error                               ; If allocation failed, jump to error
    mov snakeHead, rax                      ; Store the pointer to the head of the snake
    mov snakeTail, rax                      ; Store the pointer to the tail of the snake

    ; Set start position
    mov r10, startX                         ; 9th byte (first byte of x-coordinate) = startX
    mov byte ptr [rax + 8], r10b             
    mov r10, startY                         ; 10th byte (first byte of y-coordinate) = startY
    mov byte ptr [rax + 9], r10b             

    ; Calculate start position
    mov rax, startY                         ; RAX = startY
    mov rbx, fieldSideSize                  ; RBX = fieldSideSize
    mul rbx                                 ; RAX = startY * fieldSideSize = yCordOffset
    add rax, startX                         ; RAX = yCordOffset + startX = objCordOffset
    add rax, fieldArray                     ; RAX = objCordOffset + fieldArray = newObjAddress
    mov byte ptr [rax], 1                   ; Set newObjAddress with 1 (snake head)

    ; Set start direction
    mov rax, qword ptr [lastKey]
    mov bl, rightKey
    mov byte ptr [rax], bl

    ; Add first apple
    call Add_Apple

    ret

_error:
    ret

Snake_Init ENDP
;---------------------------------------------------------------------------------------------------------------
Game_Turn PROC
; Game turn 

    call ProcessInput
    call Move_Head

    mov rcx, hwndHandle     ; RCX = hwndHandle
    xor rdx, rdx            ; RDX = 0
    xor r8, r8              ; R8 = 0

    call InvalidateRect

    ret

Game_Turn ENDP
;---------------------------------------------------------------------------------------------------------------
Game_Loop PROC
; Game loop
    _loop:
        call Read_Msg
        mov rax, [rsp + 24]
        cmp rax, WM_QUIT
        je _exit

        mov rcx, 200
        sub rsp, 40
        call Sleep
        add rsp, 40

        call Game_Turn

        test byte ptr [gameFlags], 00000001b
        jz _exit

        jmp _loop

    _exit:
        ret

Game_Loop ENDP
;---------------------------------------------------------------------------------------------------------------
Game_Init PROC
; void Game_Init(HWND hwnd, unsigned char* fieldArray, int fieldArrayLength);
;   Parameters:
;       RCX - hwnd
;       RDX - fieldArray
;       R8 - fieldArrayLength
;       R9 - lastKey
    
    mov hwndHandle, rcx         ; Save hwndHandle adress
    mov fieldArray, rdx         ; Save fieldArray adress
    mov fieldArrayLength, r8    ; Save fieldArrayLength adress
    mov lastKey, r9             ; Save lastKey adress

    call Snake_Init  
    
    call Game_Loop

    ret

Game_Init ENDP
;---------------------------------------------------------------------------------------------------------------

end