; --------------------- INCLUDES ---------------------


include utils.asm

.model small
.stack
.radix 16

.data

; --------------------- VARIABLES ---------------------

mVariables

.code

include procs.asm
include file.asm
.startup

    mPrint initialMessage
    mWaitForEnter

    call initBoard
    
end_program:
    mEndVideoMode
    mov al, 0c
    mov ah, 4ch                         
    int 21h
end