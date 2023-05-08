

; Description: loads a game level from a file
readGameFile proc

    ;  OPEN FILE
    mov CX, 00
    mov AL, 00 ; Read only
    mov AH, 3dh ; Open
    mov dx, offset fileName
    int 21
    jc open_file_error
    mov filehandle, AX 


    ; READ FILE
    mov cx, 0 ; initial line
    read_row_loop:
        call readOneLineOfFile        
        lea si, readStringBuffer
        mov ax, 0 ; initial x coordinate
        read_col_loop:

            push ax
            push cx

            call checkNumber
            mov dx, ax ; Set the number reference
            inc si ; Skip the comma
            pop cx
            pop ax


            call setCell ; Set the cell

            inc ax ; Next x coordinate
            cmp ax, 35h ; 35h = 53d 
            jne read_col_loop

        inc cx ; Next line
        cmp cx, 1ch ; 1ch = 28d
        jne read_row_loop
    
    ; Close the file
    jmp close_file
    read_file_error:
        mPrint errorMessage
        mov ax, fileLine
        mNumberToString
        mPrint numberString

        mPrint newLine
        lea si, readStringBuffer
        mPrintAddress si
        jmp close_file

    open_file_error:
        mPrint errorMessage
        mov dx, 1
        jmp end_read

    close_file_error:
        mPrint errorMessage
        mov dx, 1
        jmp end_read

    close_file:
        ; Close the file
        mov bx, filehandle
        mov AH, 3eh
        int 21
        jc close_file_error

    end_read:
        ret

readGameFile endp


resetStringBuffer proc

    push si
    push cx
    push ax

    lea si, readStringBuffer
    mov cx, 100
    mov al, '$'

    reset_string_buffer:
        mov [si], al
        inc si
        loop reset_string_buffer


    pop ax
    pop cx
    pop si
    ret
resetStringBuffer endp

; Description: Read a line from handle
; Entry: None
; Output: DX = 0 if has a line; DX = 1 if EOF; DX = error;
readOneLineOfFile proc

    push di
    push si
    push ax
    push bx
    push cx

    call resetStringBuffer

    lea SI, readStringBuffer ; Load the destination buffer
    lea DI, readCharBuffer ; Load the char buffer

    read_line_loop:
        mov BX, filehandle ; Filehandle
        mov CX, 1 ; Read 1 byte
        mov DX, DI ; Saves char in char buffer
        mov AH, 3fh
        int 21
        jc read_line_error
        
        cmp ax, 1
        jne read_line_eof

        mov al, [DI]
        
        cmp al, 0dh ; CR
        je read_line_loop

        cmp al, ' '
        je read_line_loop

        cmp al, 0ah ; LF
        je finish_read_line
        
        mov [SI], al ; Copies the value
        inc SI

        jmp read_line_loop

    finish_read_line:
        ; mPrint readStringBuffer
        ; mPrint newLine

        mov dx, 0
        jmp end_read_line

    read_line_error:
        mov dx, 2
        jmp end_read_line

    read_line_eof: 
        mov dx, 1
        jmp end_read_line

    end_read_line:
        pop cx
        pop bx
        pop ax
        pop si
        pop di

        ret
readOneLineOfFile endp


; Description: Compares two strings
; Input : DI - string 1 address
;         SI - string 2 address
;         CX - Characters to compare
; Output: DX - 0 if equal, 1 if not equal
compareStrings proc
    ; REGISTER PROTECTION
    push ax
    push bx
    push cx
    push si
    push di

    mov dx, 1 ; Not equal
    compare_char:
        mov al, [di]
        mov bl, [si]
        cmp al, bl
        jne end_comparisson
        inc di
        inc si
        loop compare_char

    mov dx, 0 ; Equal
    jmp end_comparisson

    end_comparisson:
        ; REGISTER RESTORATION
        pop di
        pop si
        pop cx
        pop bx
        pop ax
        ret
compareStrings endp


; Description: Evaluates if the input buffer contains a number reference [Number]
; Input: si - input buffer address. [MODIFICATES] if it is a number reference
;                                   [NO MODIFICATION] if it is not a number reference
; Output: dx - 0 -> invalid reference
;            - 1 -> Number reference
;         ax - reference
checkNumber proc
    push bx
    push di
    push si

    ; String destination
    mResetNumberString
    mov di, 0 ; string relative address

    ; Check if it is a negative number
    mov al, [si] ; Load the first character
    cmp al, '-'
    je negative

    mov negativeNumber, 0

    eval_digit:
        mov al, [si] ; Load character
        cmp al, '0'
        jl no_num_reference

        cmp al, '9'
        jg no_num_reference

        mov numberString[di], al ; Save the digit

        inc si ; Skip the digit
        inc di ; Next string position

        ; Check if it is the end of the number (white space)
        mov al, [si] ; Load character
        ; Check if it is the end of the string
        cmp al, '$'
        je convert_number

        cmp al, 0dh
        je convert_number

        cmp al, ' '
        je convert_number

        cmp al, ',' ; For CSV files
        je convert_number

        cmp al, '"' ; For CSV files
        je convert_number

        cmp di, 6 ; Destination String Max length
        jge no_num_reference

        jmp eval_digit

    num_reference:
        mov dx, 1
        pop ax ; Restore prev value SI on AX, modify SI
        mov ax, numberReference
        jmp end_check_number

    no_num_reference:
        mov dx, 0
        pop si
        jmp end_check_number

    negative:
        mov negativeNumber, 1
        inc si ; Skip the negative sign
        jmp eval_digit

    convert_number:
        mStringToNumber
        cmp dx, 0
        je num_reference
        jmp no_num_reference

    end_check_number:
        pop di
        pop bx
        ret
checkNumber endp
