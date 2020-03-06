; CS 271 Homework #4
; Name: Duncan Freeman
; Date: 3/5/20
; Purpose: Generates, sorts, and prints random numbers according to user input

%include 'Along32.inc'

extern exit
global main

MIN_REQUEST equ 10
MAX_REQUEST equ 200

RAND_MIN equ 100
RAND_MAX equ 999

section .data
    intro db "Random number generator and sorter, by Duncan Freeman", 0
    request_prompt db "Enter the number of integers you wish to generate below (between 10 and 200):", 0

section .bss
    integers resd MAX_REQUEST ;DUP(0)
    requested_integers resd 1 ; DWORD ?

section .text
    
main:
    call introduce_program

    push requested_integers ; OFFSET
    call request_range

    push RAND_MAX
    push RAND_MIN
    push dword [requested_integers] ; No []
    push integers ; OFFSET
    call random_generation

    push dword [requested_integers]
    push integers
    call print_array
    ; mov eax, [requested_integers] ; without []
    ; call WriteInt
    ; call Crlf

stop:
    ; Exit with EXIT_SUCCESS
    mov edi, 0
    call exit

; Introduces the program
introduce_program:
    mov edx, intro
    call WriteString
    call Crlf
    ret

; Request number of generated integers from user
; Receives: Pointer to requested integers on stack
; Returns: User input (validated) integer in global
request_range:
    push ebp ; Set up stack frame
    mov ebp, esp

    mov edx, request_prompt
    call WriteString
    call Crlf
    call ReadInt
    cmp eax, MIN_REQUEST
    jl request_range
    cmp eax, MAX_REQUEST
    jg request_range
    mov ebx, [ebp+8] ; ebx = ptr to n requested integers
    mov [ebx], eax

    pop ebp 
    ret 4 ; Destructure stack frame

; Generates random numbers
; Receives: (In order of stack population)
;   ebp+20: Maximum integer
;   ebp+16: Minimum integer
;   ebp+12: Number of requested integers
;   ebp+ 8: Pointer to destination for integers
random_generation:
    push ebp
    mov ebp, esp

    ; Seed the RNG
    call Randomize

    mov ecx, [ebp+12] ; Loop counter
    mov ebx, [ebp+8] ; Array pointer

    ; edx = Max - min
    mov edx, [ebp+20]
    sub edx, [ebp+16]

    rand_loop:
        ; eax = randrange(0, max - min) + min
        mov eax, edx
        call RandomRange
        add eax, [ebp+16]

        ; *ebx = eax
        mov [ebx], eax

        add ebx, 4
        loop rand_loop

    pop ebp
    ret 16

; Prints the array
; Receives:
;   ebp+12: Number of integers to print
;   ebp+ 8: Pointer to integer array
print_array:
    push ebp
    mov ebp, esp

    mov ecx, [ebp+12]
    mov ebx, [ebp+8]
    print_loop:
        mov eax, [ebx]
        call WriteInt
        call Crlf
        add ebx, 4
        loop print_loop

    pop ebp
    ret 8
