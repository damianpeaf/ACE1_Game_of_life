initBoard proc
    
    mInitVideoMode

    mov iterations, 0
    ; set cursor position to 0,0
    mov ah, 02h 
    mov bh, 0
    mov dh, 0 ; row
    mov dl, 0 ; column
    int 10h
    mPrint sGameOfLife

    ; Set the cursor position to 0, 23d
    mov ah, 02h
    mov bh, 0
    mov dh, 0; row
    mov dl, 17h; column
    int 10h
    mPrint sIteration

    mov ax, iterations
    call numberToString
    mPrint numberString

    call paintSeparators

    mov ah, 02h
    mov bh, 0
    mov dh, 18h; row
    mov dl, 0; column
    int 10h
    mPrint sPressEnter

    mWaitForEnter
    call readGameFile
    call paintBoard

    mWaitForEnter

    resume_game:
    call deleteLastLine
    mov ah, 02h
    mov bh, 0
    mov dh, 18h; row
    mov dl, 0; column
    int 10h
    mPrint sPause

    mov pauseGame, 0
    mov endGame, 0

    game_sequence:
        call nextIteration
        call defaultDelay
        call paintBoard

        call userInput

        cmp pauseGame, 1
        je pause_game

        cmp endGame, 1
        je end_game

        jmp game_sequence
    
        pause_game: 
            call deleteLastLine
            mov ah, 02h
            mov bh, 0
            mov dh, 18h; row
            mov dl, 0; column
            int 10h
            mPrint sPressEnter
            mWaitForEnter
            jmp resume_game
    
    end_game:
    ret
initBoard endp



; Description: Paints the initial board
paintBoard proc
    
    lea si, gameBoard

    ; From x (0, 53d=35h) to y (3, 31d=1fh)
    mov cx, 3
    line_cell_loop:
        mov ax, 0 ; X = 0
        column_cell_loop:

            lea di, dead_cell
            mov dl, [si]
            cmp dl, 0
            je paint_cell_a

            lea di, alive_cell

            paint_cell_a:
            call paint6Sprite
            inc ax
            inc si
            cmp ax, 35h ; 53d
            jne column_cell_loop

        inc cx
        cmp cx, 1fh ; 31d
        jne line_cell_loop

    ret
paintBoard endp

; Input: AX = x coordinate; CX = y coordinate; DL 0 = dead cell, 1 = alive cell
setAuxCell proc

    push ax
    push bx
    push cx
    push dx
    push di 

    push dx ; Save the cell state

    ; ROW major order -> y * 53 + x
    xchg ax, cx ; AX = y; CX = x
    mov bx, 35h ; 53d
    xor dx, dx ; DX = 0
    mul bx ; AX = y * 53

    add ax, cx ; AX = y * 53 + x

    lea di, auxGameBoard
    add di, ax ; DI = &gameBoard[y * 53 + x]

    pop dx ; DX = cell state
    mov al, dl ; AL = 0 or 1
    mov [di], al ; gameBoard[y * 53 + x] = 0 or 1

    pop di
    pop dx
    pop cx
    pop bx
    pop ax

    ret
setAuxCell endp

; Input: AX = x coordinate; CX = y coordinate; DL 0 = dead cell, 1 = alive cell
setCell proc

    push ax
    push bx
    push cx
    push dx
    push di 

    push dx ; Save the cell state

    ; ROW major order -> y * 53 + x
    xchg ax, cx ; AX = y; CX = x
    mov bx, 35h ; 53d
    xor dx, dx ; DX = 0
    mul bx ; AX = y * 53

    add ax, cx ; AX = y * 53 + x

    lea di, gameBoard
    add di, ax ; DI = &gameBoard[y * 53 + x]

    pop dx ; DX = cell state
    mov al, dl ; AL = 0 or 1
    mov [di], al ; gameBoard[y * 53 + x] = 0 or 1

    pop di
    pop dx
    pop cx
    pop bx
    pop ax

    ret
setCell endp

; INPUT: AX = x coordinate; CX = y coordinate
; OUTPUT: DL = 0 if dead cell, 1 if alive cell
getCell proc
    
    push ax
    push bx
    push cx
    push di 

    ; ROW major order -> y * 53 + x
    xchg ax, cx ; AX = y; CX = x
    mov bx, 35h ; 53d
    xor dx, dx ; DX = 0
    mul bx ; AX = y * 53

    add ax, cx ; AX = y * 53 + x

    lea di, gameBoard
    add di, ax ; DI = &gameBoard[y * 53 + x]

    mov dl, [di] ; DL = gameBoard[y * 53 + x]

    pop di
    pop cx
    pop bx
    pop ax

    ret
getCell endp 

; INPUT: AX = x coordinate; CX = y coordinate
surroundingCells proc
    
    push ax
    push bx
    push cx
    push dx

    mov aliveSurroundingCells, 0
    mov deathSurroundingCells, 0

    ; Check the surrounding cells

    ; Check the cell above
    push cx ; Save the y coordinate
    dec cx ; y - 1
    cmp cx, 0 ; Check if the cell is in the first row
    jl check_cell_below ; If it is, check the cell below
    call getCell ; Get the cell
    cmp dl, 0 ; Check if the cell is dead
    je dead_cell_above ; If it is, jump to dead_cell_above
    inc aliveSurroundingCells ; If not, increment the alive surrounding cells
    jmp check_cell_below ; Jump to check_cell_below
    dead_cell_above:
        inc deathSurroundingCells ; Increment the death surrounding cells
    check_cell_below:
    pop cx ; Restore the y coordinate

    ; Check the cell below
    push cx ; Save the y coordinate
    inc cx ; y + 1
    cmp cx, 1ch ; Check if the cell is in the last row
    jg check_cell_left ; If it is, check the cell left
    call getCell ; Get the cell
    cmp dl, 0 ; Check if the cell is dead
    je dead_cell_below ; If it is, jump to dead_cell_below
    inc aliveSurroundingCells ; If not, increment the alive surrounding cells
    jmp check_cell_left ; Jump to check_cell_left
    dead_cell_below:
        inc deathSurroundingCells ; Increment the death surrounding cells
    check_cell_left:
    pop cx ; Restore the y coordinate

    ; Check the cell left
    push ax ; Save the x coordinate
    dec ax ; x - 1
    cmp ax, 0 ; Check if the cell is in the first column
    jl check_cell_right ; If it is, check the cell right
    call getCell ; Get the cell
    cmp dl, 0 ; Check if the cell is dead
    je dead_cell_left ; If it is, jump to dead_cell_left
    inc aliveSurroundingCells ; If not, increment the alive surrounding cells
    jmp check_cell_right ; Jump to check_cell_right
    dead_cell_left:
        inc deathSurroundingCells ; Increment the death surrounding cells
    check_cell_right:
    pop ax ; Restore the x coordinate

    ; Check the cell right
    push ax ; Save the x coordinate
    inc ax ; x + 1
    cmp ax, 35h ; Check if the cell is in the last column
    jg check_cell_above_left ; If it is, check the cell above left
    call getCell ; Get the cell
    cmp dl, 0 ; Check if the cell is dead
    je dead_cell_right ; If it is, jump to dead_cell_right
    inc aliveSurroundingCells ; If not, increment the alive surrounding cells
    jmp check_cell_above_left ; Jump to check_cell_above_left
    dead_cell_right:
        inc deathSurroundingCells ; Increment the death surrounding cells
    check_cell_above_left:
    pop ax ; Restore the x coordinate

    ; Check the cell above left
    push cx ; Save the y coordinate
    push ax ; Save the x coordinate
    dec cx ; y - 1
    dec ax ; x - 1
    cmp cx, 0 ; Check if the cell is in the first row
    jl check_cell_below_right ; If it is, check the cell below right
    cmp ax, 0 ; Check if the cell is in the first column
    jl check_cell_below_right ; If it is, check the cell below right
    call getCell ; Get the cell
    cmp dl, 0 ; Check if the cell is dead
    je dead_cell_above_left ; If it is, jump to dead_cell_above_left
    inc aliveSurroundingCells ; If not, increment the alive surrounding cells
    jmp check_cell_below_right ; Jump to check_cell_below_right
    dead_cell_above_left:
        inc deathSurroundingCells ; Increment the death surrounding cells
    check_cell_below_right:
    pop ax ; Restore the x coordinate
    pop cx ; Restore the y coordinate

    ; Check the cell below right
    push cx ; Save the y coordinate
    push ax ; Save the x coordinate
    inc cx ; y + 1
    inc ax ; x + 1
    cmp cx, 1ch ; Check if the cell is in the last row
    jg check_cell_above_right ; If it is, check the cell above right
    cmp ax, 35h ; Check if the cell is in the last column
    jg check_cell_above_right ; If it is, check the cell above right
    call getCell ; Get the cell
    cmp dl, 0 ; Check if the cell is dead
    je dead_cell_below_right ; If it is, jump to dead_cell_below_right
    inc aliveSurroundingCells ; If not, increment the alive surrounding cells
    jmp check_cell_above_right ; Jump to check_cell_above_right
    dead_cell_below_right:
        inc deathSurroundingCells ; Increment the death surrounding cells
    check_cell_above_right:
    pop ax ; Restore the x coordinate
    pop cx ; Restore the y coordinate

    ; Check the cell above right
    push cx ; Save the y coordinate
    push ax ; Save the x coordinate
    dec cx ; y - 1
    inc ax ; x + 1
    cmp cx, 0 ; Check if the cell is in the first row
    jl check_cell_below_left ; If it is, check the cell below left
    cmp ax, 35h ; Check if the cell is in the last column
    jg check_cell_below_left ; If it is, check the cell below left
    call getCell ; Get the cell
    cmp dl, 0 ; Check if the cell is dead
    je dead_cell_above_right ; If it is, jump to dead_cell_above_right
    inc aliveSurroundingCells ; If not, increment the alive surrounding cells
    jmp check_cell_below_left ; Jump to check_cell_below_left
    dead_cell_above_right:
        inc deathSurroundingCells ; Increment the death surrounding cells
    check_cell_below_left:
    pop ax ; Restore the x coordinate
    pop cx ; Restore the y coordinate

    ; Check the cell below left
    push cx ; Save the y coordinate
    push ax ; Save the x coordinate
    inc cx ; y + 1
    dec ax ; x - 1
    cmp cx, 1ch ; Check if the cell is in the last row
    jg end_check ; If it is, check the cell above left
    cmp ax, 0 ; Check if the cell is in the first column
    jl end_check ; If it is, check the cell above left
    call getCell ; Get the cell
    cmp dl, 0 ; Check if the cell is dead
    je dead_cell_below_left ; If it is, jump to dead_cell_below_left
    inc aliveSurroundingCells ; If not, increment the alive surrounding cells
    jmp end_check ; Jump to end_check
    dead_cell_below_left:
        inc deathSurroundingCells ; Increment the death surrounding cells
    end_check:
    pop ax ; Restore the x coordinate
    pop cx ; Restore the y coordinate
    
    pop dx
    pop cx
    pop bx
    pop ax

    ret
surroundingCells endp

paintSeparators  proc
    
    lea di, separtor_sprite

    mov ax, 0 ; X = 0
    mov cx, 1 ; Y = 1

    first_separator_loop:
        call paint8Sprite   
        inc ax
        cmp ax, 28h ; 40d
        jne first_separator_loop

    mov ax, 0 ; X = 0
    mov cx, 17h ; Y = 23d

    second_separator_loop:
        call paint8Sprite   
        inc ax
        cmp ax, 28h ; 40d
        jne second_separator_loop

    ret
paintSeparators  endp

; Description: Converts a sign number of 16 bits to an ascii representation string
; Input : AX - number to convert
; Output: DX - 0 if no error, 1 if error
;         numberString - the string representation of the number
numberToString proc

    ; REGISTER PROTECTION
    push ax
    push bx
    push cx
    push si
    
    mov cx, 0
    ; Comparte if its a negative number
    mov negativeNumber, 0
    cmp ax, 0
    jge convert_positive

    convert_negative:
        mov negativeNumber, 1 ; Set the negative number flag to 1
        inc cx

        ; Convert to positive
        neg ax
        jmp convert_positive
    
    convert_positive:
        mov bx, 0ah

        extract_digit:
            mov dx, 0 ; Clear the dx register [Remainder]
            div bx ; Divide the AX number by 10 and store the remainder in dx
            add dl, '0' ; Convert the remainder to ascii
            push dx ; Push the remainder to the stack
            inc cx ; Increment the digit counter
            cmp ax, 0 ; Check if the number is 0
            jne extract_digit ; If not, extract the next digit

    ; No representable number
    cmp cx, 6
    jg representation_error

    ; ------------------- Fill the string -------------------
    mov si, 0

    ; ! Fill with 0 every digit that is not used <- Change this to fill with spaces
    mov dx, 6
    sub dx, cx
    cmp dx, 0
    jz set_negative

    fill_with_0:
        mov numberString[si], '0'
        inc si
        dec dx
        jnz fill_with_0

    set_negative:

    ; If the number is negative, add the '-' sign
    cmp negativeNumber, 1
    jne set_digit
    mov numberString[si], '-'
    inc si
    dec cx

    ; Copy the digits to the string
    set_digit:
        pop dx
        mov numberString[si], dl
        inc si
        loop set_digit

    mov dx, 0 ; NO ERROR
    jmp end_number_string

    representation_error:
        mPrint numberRepresentationError

        ; empty the stack
        empty_stack:
            pop dx
            loop empty_stack

        mov dx, 1 ; ERROR

    end_number_string:
        ; REGISTER RESTORATION
        pop si
        pop cx
        pop bx
        pop ax

        ret
numberToString endp


; Paints the sprite on video memory
; Entry: AX = x coordinate
;        CX = y coordinate
;        DI = sprite offset
paint8Sprite proc

    push ax
    push bx
    push cx
    push dx
    push di

    mov bx, 0 
    mov dl, 08 ; 8 rows
    mul dl ; AX = x * 8
    add bx, ax ; bx = x * 8

    xchg ax, cx ; AX = y; CX = x * 8
    mul dl ; AX = y * 8
    mov dx, 140h ; 320d -> pixel width
    mul dx ; AX = y * 8 * 320d
    add bx, ax ; bx = x * 8 + y * 8 * 320d
    end_position:
        mov cx, 8 ; 8 rows
    
    paint_sprite_row:
        push cx
        mov cx, 8 ; 8 columns

    paint_sprite_col:

        mov al, [di] ; get sprite column
        push ds ; save ds

        mov dx, 0A000h ; video memory
        mov ds, dx ; ds = video memory

        mov [BX], AL ; paint sprite

        inc bx ; next column on video memory
        inc di ; next column on sprite
        
        pop ds ; restore ds

        loop paint_sprite_col

        pop cx ; restore row counter
        sub bx, 8 ; go to the next row on video memory
        add bx, 140 ; 320d -> pixel width
        loop paint_sprite_row


    pop di
    pop dx
    pop cx
    pop bx
    pop ax

    ret

paint8Sprite endp


deleteLastLine proc
    
    mov ax, 0
    mov cx, 18h ; 24d
    lea di, empty_sprite
    delete_last_line_loop:
        call paint8Sprite
        inc ax
        cmp ax, 28h ; 40d
        jne delete_last_line_loop

    ret
deleteLastLine endp

paint6Sprite proc
    push ax
    push bx
    push cx
    push dx
    push di

    mov bx, 0 
    mov dl, 6 ; 6 rows
    mul dl ; AX = x * 6
    add bx, ax ; bx = x * 6

    xchg ax, cx ; AX = y; CX = x * 6
    mul dl ; AX = y * 6
    mov dx, 140h ; 320d -> pixel width
    mul dx ; AX = y * 6 * 320d
    add bx, ax ; bx = x * 6 + y * 6 * 320d
    end_position_6:
        mov cx, 6 ; 6 rows
    
    paint_sprite_row_6:
        push cx
        mov cx, 6 ; 6 columns

    paint_sprite_col_6:

        mov al, [di] ; get sprite column
        push ds ; save ds

        mov dx, 0A000h ; video memory
        mov ds, dx ; ds = video memory

        mov [BX], AL ; paint sprite

        inc bx ; next column on video memory
        inc di ; next column on sprite
        
        pop ds ; restore ds

        loop paint_sprite_col_6

        pop cx ; restore row counter
        sub bx, 6 ; go to the next row on video memory
        add bx, 140 ; 320d -> pixel width
        loop paint_sprite_row_6


    pop di
    pop dx
    pop cx
    pop bx
    pop ax

    ret

paint6Sprite endp


defaultDelay proc

    push bp
    push si

    mov BP, 03000
    default_delay_loop_b:		
        mov SI, 00010
    default_delay_loop_a:		
        dec SI
		cmp SI, 00
		jne default_delay_loop_a
		dec BP
		cmp BP, 00
		jne default_delay_loop_b

        pop si
        pop bp
		ret
defaultDelay endp

userInput proc
    mov ah, 1
    int 16h ; get user input

    jz return_input

    cmp al, 1b ; ESC
    je input_pause_game

    cmp al, 71h ; q
    je input_end_game

    mov ah, 0
    int 16h ; clear buffer
    ret

   
    input_pause_game:
        mov al, 1        
        mov pauseGame, al ; toggle endGame

        mov ah, 0
        int 16h ; clear buffer
        ret 

    input_end_game:
        mov al, 1        
        mov endGame, al ; toggle endGame

        mov ah, 0
        int 16h ; clear buffer
        ret
    
    return_input:
        ret


userInput endp

nextIteration proc
    
    inc iterations

    ; Set the cursor position to 0, 23d
    ; mov ah, 02h
    ; mov bh, 0
    ; mov dh, 0; row
    ; mov dl, 17h; column
    ; int 10h
    ; mPrint sIteration

    ; mov ax, iterations
    ; call numberToString
    ; mPrint errorMessage
    ; lea di, numberString
    ; mPrintAddress di

    mov cx, 0 ; initial y coordinate

    row_next_iter_loop:
        mov ax, 0 ; initial x coordinate

        col_next_iter_loop:
            call surroundingCells
            ; Now in aliveSurroundingCells we have the number of alive surrounding cells
            ; and in deathSurroundingCells we have the number of death surrounding cells
            call getCell ; Now in DL we have the cell value

            cmp dl, 0 ; if the cell is dead
            je dead_cell_rules

            ; * ALIVE CELL RULES
            cmp aliveSurroundingCells, 2 ; if the cell has 2 or 3 alive surrounding cells
            jl write_dead_cell ; the cell dies

            cmp aliveSurroundingCells, 3
            jg write_dead_cell ; the cell dies

            jmp write_alive_cell ; the cell lives

            dead_cell_rules:

            ; * DEAD CELL RULES
            cmp aliveSurroundingCells, 3 ; if the cell has 3 alive surrounding cells
            je write_alive_cell ; the cell lives

            jmp write_dead_cell ; the cell dies

            write_alive_cell:
                mov dl, 1
                call setAuxCell
                jmp next_cell

            write_dead_cell:
                mov dl, 0
                call setAuxCell
                jmp next_cell

            next_cell:
                inc ax ; next column
                cmp ax, 35h ; 53d
                jne col_next_iter_loop

        inc cx
        cmp cx, 1fh ; 31d
        jne row_next_iter_loop


        call copyAuxToMain

    ret
nextIteration endp

copyAuxToMain proc
    
    lea di, auxGameBoard
    lea si, gameBoard

    mov cx, 5cch
    copy_aux_to_main_loop:
        mov al, [di]
        mov [si], al

        inc di
        inc si

        loop copy_aux_to_main_loop

    ret
copyAuxToMain endp