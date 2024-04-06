; Disassembler written in FASM assembly language
format ELF64 executable 3	; value 3 marks the executable for Linux system

entry start

segment readable writable

valid		db "das86: valid!", 10, 0
usage		db "das86: usage: das86 src [dst]", 10, 0
argc		db 0

segment readable writable

src		dq ?
dst		dq ?

segment readable executable

start:
	; get the command line arguments
	; int main(int argc, char *argv[ ])
	mov rax, [rsp] ; argc
	cmp rax, 2
	je .valid
	cmp rax, 3
	jne .error

.valid:
	mov rsi, [rsp + 16] ; argv[1]
	mov [src], rsi
	mov [argc], al

	cmp rax, 3
	jne .end
	mov rsi, [rsp + 24] ; argv[2]
	mov [dst], rsi
	mov [argc], al
	jmp .end

.error:
	mov rsi, usage		; arg 2 = msg
	mov rdx, 30		; arg 3 = char count

.print:
	; write string to stdout
	mov     rax, 1		; syscall 1 (write)
	mov     rdi, rax	; arg 1 = 1 (stdout)
	syscall			; call write

.end:
	mov rax, 60     ; syscall 60 (exit)
	mov rdi, 0      ; arg 1 = 0 (OK)
	syscall         ; call exit

; Determines the length of a C-style NULL-terminated string.
;
; Inputs:   RSI = address of beginning of string buffer
; Outputs:  RDX = length of the string, including the NULL terminator
; Clobbers: CL, flags
strlen:
    lea    rdx, [rsi + 1]

strlen_loop:
    mov    cl, byte [rdx]
    inc    rdx
    test   cl, cl
    jnz    strlen_loop

    sub    rdx, rsi	; arg 3 = char count
    ret
