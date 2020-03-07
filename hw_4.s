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

NUMBERS_PER_LINE equ 10

section .data
    intro db "Random number generator and sorter, by Duncan Freeman", 0
    unsorted_label db "Unsorted:", 0
    sorted_label db "Sorted:", 0
    request_prompt db "Enter the number of integers you wish to generate below (between 10 and 200):", 0
    average_msg db "Average:", 0
    median_msg db "Median:", 0
    outro db "Goodbye.", 0

section .bss
    integers resd MAX_REQUEST ;DUP(0)
    requested_integers resd 1 ; DWORD ?

section .text
    
main:
    ; Introduce program
    call introduce_program

    ; Request number of integers to generate
    push requested_integers ; OFFSET
    call request_range

    ; Generate random integers in range
    push RAND_MAX
    push RAND_MIN
    push dword [requested_integers] ; No []
    push integers ; OFFSET
    call random_generation

    ; Display "Unsorted:"
    mov edx, unsorted_label ; OFFSET
    call WriteString
    call Crlf

    ; Print random generated integers
    push dword [requested_integers] ; No []
    push integers ; OFFSET
    call print_array
    call Crlf

    ; Sort generated integers
    push dword [requested_integers] ; No []
    push integers ; OFFSET
    call sort_array

    ; Calculate and display average
    push dword [requested_integers] ; No []
    push integers ; OFFSET
    call display_average
    call Crlf

    ; Calculate and display median
    push dword [requested_integers] ; No []
    push integers ; OFFSET
    call display_median
    call Crlf

    ; Display "Sorted:"
    mov edx, sorted_label ; OFFSET
    call WriteString
    call Crlf

    ; Print sorted integers
    push dword [requested_integers]
    push integers
    call print_array
    call Crlf

    ; Say goodbye
    call goodbye

stop:
    ; Exit with EXIT_SUCCESS
    mov edi, 0
    call exit

; Introduces the program
; Clobbers: edx
introduce_program:
    mov edx, intro ; OFFSET
    call WriteString
    call Crlf
    ret

; Request number of generated integers from user
; Receives: Pointer to destination requested integers
; Returns: User input (validated) integer in global
; Clobbers: eax, ebx, edx
request_range:
    push ebp ; Set up stack frame
    mov ebp, esp

    request_loop:
        mov edx, request_prompt
        call WriteString
        call Crlf
        call ReadInt
        cmp eax, MIN_REQUEST
        jl request_loop
        cmp eax, MAX_REQUEST
        jg request_loop
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
; Clobbers: eax, ebx, ecx, edx
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
; Clobbers: eax, ebx, ecx, edx
print_array:
    push ebp
    mov ebp, esp

    mov edx, 0 ; Columns/Row counter
    mov ecx, [ebp+12] ; Loop counter
    mov ebx, [ebp+8] ; Pointer to the array element
    print_loop:
        ; Print *edx and a space
        mov eax, [ebx]
        call WriteInt
        mov eax, ' '
        call WriteChar

        ; Move to a new row if we've filled this one
        inc edx
        cmp edx, NUMBERS_PER_LINE 
        jl print_loop_continue
        mov edx, 0
        call Crlf
        print_loop_continue:

        ; Increase array pointer and loop
        add ebx, 4
        loop print_loop
    call Crlf

    pop ebp
    ret 8

; Sorts the array
; Receives:
;   ebp+12: Number of integers to sort
;   ebp+ 8: Pointer to integer array
; Clobbers: eax, ebx, ecx, edx, edi, esi
sort_array:
    ; Create stack frame
    push ebp
    mov ebp, esp
    
    mov ebx, [ebp+8] ; Pointer to array beginning
    mov ecx, [ebp+12] ; k
    sub ecx, 1 ; k = len - 1

    sort_array_top_loop:
        mov edx, ecx ; i = k

        ; Enter inner loop
        push ecx
        sub ecx, 1 ; j

        sort_array_inner_loop:

            mov eax, [ebx + 4*ecx]
            cmp [ebx + 4*edx], eax
            jle sort_array_skip
                mov edx, ecx ; i = j
            sort_array_skip:

            dec ecx
            cmp ecx, 0
            jge sort_array_inner_loop

        pop ecx

        ; Swap elements
        mov esi, [ebx + 4*edx]
        mov edi, [ebx + 4*ecx]
        mov [ebx + 4*edx], edi
        mov [ebx + 4*ecx], esi
        loop sort_array_top_loop

    ; Destructure stack frame and return
    pop ebp
    ret 8

; Prints the average of the specified array
; Receives:
;   ebp+12: Number of integers to average
;   ebp+ 8: Pointer to integer array
; Clobbers: eax, ebx, ecx, edx
display_average:
    push ebp
    mov ebp, esp

    mov eax, 0 ; Accumulator for average
    mov ecx, [ebp+12] ; Loop counter
    mov ebx, [ebp+8] ; Pointer to the array element
    average_loop:
        ; Print *edx and a space
        add eax, [ebx]

        ; Increase array pointer and loop
        add ebx, 4
        loop average_loop

    ; Divide accumulator by count
    mov ebx, [ebp+12]
    mov edx, 0
    div ebx

    ; Display average
    mov edx, average_msg
    call WriteString
    call Crlf
    call WriteInt
    call Crlf

    pop ebp
    ret 8


; Prints the median of the specified array
; Precondition: Array is sorted
; Receives:
;   ebp+12: Number of integers to average
;   ebp+ 8: Pointer to integer array
; Clobbers: eax, ebx, ecx, edx
display_median:
    push ebp
    mov ebp, esp

    mov ebx, [ebp+8]
    mov ecx, [ebp+12]
    mov edx, ecx
    shr edx, 1

    test ecx, 1b
    je dm_is_even

        ; If it is odd, pick the middle
        mov eax, [ebx + 4*edx]

        jmp dm_end
    dm_is_even:

        ; If it is even, average the two centers
        mov eax, [ebx + 4*edx]
        dec edx
        add eax, [ebx + 4*edx]
        shr eax, 1

    dm_end:

    ; Display median
    mov edx, median_msg
    call WriteString
    call Crlf
    call WriteInt
    call Crlf

    pop ebp
    ret 8

; Says goodbye to the user
; Clobbers: edx
goodbye:
    mov edx, outro ; OFFSET
    call WriteString
    call Crlf
    ret
