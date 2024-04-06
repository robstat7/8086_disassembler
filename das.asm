format ELF64 executable 3

entry start

segment readable writable
input db 0x37
inst db "AAA", 10, 0

segment readable executable
start:
	mov al, [input]	; al = 0x37
	
	; if (al == 0x37)
	;	print "AAA\n"
	cmp al, 0x37
	jne .end
	; write string to stdout
	mov     rax, 1		; syscall 1 (write)
	mov     rdi, rax	; arg 1 = 1 (stdout)
	mov     rsi, inst	; arg 2 = msg ("AAA\n")
	mov	rdx, 4		; arg 3 = 4 (char count)
	syscall			; call write

.end:
	mov rax, 60     ; syscall 60 (exit)
	mov rdi, 0      ; arg 1 = 0 (OK)
	syscall         ; call exit
