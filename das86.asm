; Disassembler written in FASM assembly language
format ELF64 executable 3

entry start

segment readable writable
valid db "das86: valid!", 10, 0
usage db "das86: usage: das86 src [dst]", 10, 0

segment readable executable
start:
	; get the command line arguments
	; int main(int argc, char *argv[ ])
	mov rax, [rsp] ; argc
	cmp rax, 2
	je .valid
	cmp rax, 3
	jne .error

	; mov rcx, [rsp + 8] ; *argv
.valid:
	mov     rsi, valid	; arg 2 = msg
	mov	rdx, 14		; arg 3 = char count
	jmp .print

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
