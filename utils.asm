
mVariables macro

    initialMessage db  "Universidad de San Carlos de Guatemala", 0dh, 0ah,"Facultad de Ingenieria", 0dh, 0ah,"Escuela de Ciencias y Sistemas", 0dh, 0ah,"Arquitectura de Compiladores y ensabladores 1", 0dh, 0ah,"Seccion B", 0dh, 0ah,"Damian Ignacio Pena Afre", 0dh, 0ah,"202110568", 0dh, 0ah, "$"
    sGameOfLife db "Game of life$"
    sIteration db "Iteration $"
    sPressEnter db "Presione enter para continuar$"
    sPause db "ESC: Pausa q: Salir$"

    ; Game vars
    iterations dw 0
    gameBoard db 5cch dup(0)
    auxGameBoard db 5cch dup(0)
    delimiter db "$"
    aliveSurroundingCells db 0
    deathSurroundingCells db 0
    pauseGame db 0
    endGame db 0

    ; Strings proc
    numberString db 6 dup ("$")
    numberStringEnd1 db "$"
    numberStringEnd2 db "$"
    numberStringEnd3 db "$"
    numberRepresentationError db "El numero no puede ser representado", 0dh, 0ah, "$"
    negativeNumber db 0
    maxReprestableNumber equ 7fffh
    numberReference dw 0


    ; Files
    fileLine dw 1
    newLine db 0ah, "$"
    errorMessage db "Error", 0dh, 0ah, "$"
    fileHandle dw 0
    readStringBuffer db 100 dup ("$")
    readCharBuffer db 2 dup(0)
    fileName db "load.gol", 0

    ; Sprites

    separtor_sprite db 1,1,1,1,1,1,1,1
                    db 1,1,1,1,1,1,1,1
                    db 1,1,1,1,1,1,1,1
                    db 1,1,1,1,1,1,1,1
                    db 1,1,1,1,1,1,1,1
                    db 1,1,1,1,1,1,1,1
                    db 1,1,1,1,1,1,1,1
                    db 1,1,1,1,1,1,1,1

    empty_sprite    db 0,0,0,0,0,0,0,0
                    db 0,0,0,0,0,0,0,0
                    db 0,0,0,0,0,0,0,0
                    db 0,0,0,0,0,0,0,0
                    db 0,0,0,0,0,0,0,0
                    db 0,0,0,0,0,0,0,0
                    db 0,0,0,0,0,0,0,0
                    db 0,0,0,0,0,0,0,0

    alive_cell  db 0eh,0eh,0eh,0eh,0eh,7
                db 0eh,0eh,0eh,0eh,0eh,7
                db 0eh,0eh,0eh,0eh,0eh,7
                db 0eh,0eh,0eh,0eh,0eh,7
                db 0eh,0eh,0eh,0eh,0eh,7
                db 7,7,7,7,7,7

    dead_cell   db 0,0,0,0,0,7
                db 0,0,0,0,0,7
                db 0,0,0,0,0,7
                db 0,0,0,0,0,7
                db 0,0,0,0,0,7
                db 7,7,7,7,7,7

endm

mPrint macro variable
    push ax
    push dx

    mov dx, offset variable
    mov ah, 09h
    int 21h

    pop dx
    pop ax
endm

mWaitForEnter macro
    LOCAL press_enter

    push ax

    press_enter:
        mov AH, 08h
        int 21h
        cmp AL, 0dh
        jne press_enter

    pop ax
endm

mInitVideoMode macro

    mov ax, 0013h
    int 10h

endm

mEndVideoMode macro

    mov ax, 0003h
    int 10h
endm

; Description: Converts a string to a sign number of 16 bits
; Input : None, uses the [numberString] variable and the [negativeNumber] variable
; Output: saves the number in [numberReference] variable
;         DX - 0 if no error [No representable number], 1 if error
mStringToNumber macro

    local eval_digit, error, end, save

    ; Register protection
    push ax
    push bx
    push cx
    push si
    push di

    mov bx, 0ah
    mov si, 0
    mov ax, 0
    mov dx, 0

    eval_digit:
        mul bx
        mov dl, numberString[si]
        sub dl, '0'
        add ax, dx

        inc si

        cmp numberString[si], "$"
        jne eval_digit

    ; represetable number validation
    cmp ax, maxReprestableNumber
    ja error

    cmp negativeNumber, 1
    jne save

    neg ax

    save:
        mov dx, 0
        mov numberReference, ax
        jmp end

    error:
        mPrint numberRepresentationError
        mPrint newLine
        
        mov dx, 1
        jmp end

    end: 
        ; Register restoration
        pop di
        pop si
        pop cx
        pop bx
        pop ax

endm


; Description: Converts a sign number of 16 bits to an ascii representation string
; Input : AX - number to convert
; Output: DX - 0 if no error, 1 if error
;         numberString - the string representation of the number
mNumberToString macro

    LOCAL convert_positive, convert_negative, extract_digit, representation_error, fill_with_0, set_digit, end, empty_stack, set_negative
    
    ; REGISTER PROTECTION
    push ax
    push bx
    push cx
    push si
    
    mov cx, 0
    ; Comparte if its a negative number
    mov [negativeNumber], 0
    cmp ax, 0
    jge convert_positive

    convert_negative:
        mov [negativeNumber], 1 ; Set the negative number flag to 1
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

    ; Fill with 0 every digit that is not used
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
    cmp [negativeNumber], 1
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
    jmp end

    representation_error:
        mPrint numberRepresentationError

        ; empty the stack
        empty_stack:
            pop dx
            loop empty_stack

        mov dx, 1 ; ERROR

    end:
        ; REGISTER RESTORATION
        pop si
        pop cx
        pop bx
        pop ax

endm



mPrintAddress macro address
    mov dx, address
    mov ah, 09h
    int 21h
endm


mResetNumberString macro
    local reset

    push cx
    push si

    mov cx, 6
    mov si, 0

    reset:
        mov numberString[si], "$"
        inc si
        loop reset

    pop si
    pop cx
endm