; Disassembler written in FASM assembly language
format ELF64 executable 3	; value 3 marks the executable for Linux system

entry start

segment readable writable

valid		db "das86: valid!", 10, 0
usage		db "das86: usage: das86 src [dst]", 10, 0
error_msg	db "das86: error: error closing file!", 10, 0	

segment readable writable

argc		db ?
src		dq ?
dst		dq ?
src_fd		dq ?
dst_fd		dq ?
buffer		dq ?

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
	jne .open
	mov rsi, [rsp + 24] ; argv[2]
	mov [dst], rsi
	mov [argc], al

.open:
	; open a file
	mov rax, 2		; syscall 2 (open)
	mov rdi, [src]		; arg1 = filename
	mov rsi, 0		; arg2 = O_RDONLY
	syscall			; call open
	cmp rax, 0
	jl .error
	mov [src_fd], rax
	
	mov al, [argc]
	cmp rax, 3
	jne .read		; bypass close syscall for now
	mov rax, 2		; syscall 2 (open)
	mov rdi, [dst]		; arg1 = filename
	mov rsi, 1		; arg2 = O_WRONLY
	syscall			; call open
	cmp rax, 0
	jl .error
	mov [dst_fd], rax

.read:
	; read machine code file
	mov rax, 0		; syscall 0 (read)
	mov rdi, [src_fd]	; arg1 = fd
	; mov rdi, 3	; arg1 = fd
	lea rsi, [buffer]	; arg2 = buffer
	mov rdx, 49		; arg3 = nbyte
	syscall			; call read
	cmp rax, 49
	je .close_src

.error:
	mov rsi, usage		; arg 2 = msg
	mov rdx, 30		; arg 3 = char count
	jmp .print

.close_error:
	mov rsi, error_msg	; arg 2 = msg
	mov rdx, 35		; arg 3 = char count

.print:
	; write string to stdout
	mov     rax, 1		; syscall 1 (write)
	mov     rdi, rax	; arg 1 = 1 (stdout)
	syscall			; call write
	jmp .exit

.close_src:
	; close src file
	mov rax, 3		; syscall 3 (close)
	mov rdi, [src_fd]	; arg1 = fd
	syscall			; call close
	cmp rax, 0
	jne .close_error

.close_dst:
	; close dst file
	mov rax, 3		; syscall 3 (close)
	mov rdi, [dst_fd]	; arg1 = fd
	syscall			; call close
	cmp rax, 0
	jne .close_error

.exit:
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
