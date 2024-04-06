; Disassembler written in FASM assembly language
format ELF64 executable 3	; value 3 marks the executable for Linux system

entry start

segment readable writable

usage		db "das86: usage: das86 src [dst]", 10, 0
default_dst	dq "out.asm", 0					; default dst file

segment readable writable

argc		db ?	; `argc` as passed to the main function
src		dq ?	; src file at cmdline arg #2
dst		dq ?	; dst file at cmdline arg #3
src_fd		dq ?	; src file descriptor
dst_fd		dq ?	; destination file descriptor
buffer		dq ?	; buffer to hold the data read using read syscall

segment readable executable

start:
	; get the command line arguments
	; int main(int argc, char *argv[ ])
	mov rax, [rsp]		; rax = argc
	cmp rax, 2
	je .valid
	cmp rax, 3
	jne .error		; invalid number of cmdline args

.valid:
	; We have a valid number of cmdline args. Proceed ahead.
	mov rsi, [rsp + 16] 	; rsi = argv[1]
	mov [src], rsi		; store the address of src file
	mov [argc], al		; store `argc`

	cmp rax, 3		
	jne .open_src		; rax = argc = 2
	mov rsi, [rsp + 24]	; rsi = argv[2]
	mov [dst], rsi
	mov [argc], al

.open_src:
	; open src file
	mov rax, 2		; syscall #2 (open)
	mov rdi, [src]		; arg1 = filename
	mov rsi, 0		; arg2 = O_RDONLY
	syscall			; call open
	cmp rax, 0
	jl .error
	mov [src_fd], rax	; store src fd if open syscall was successful
	
	mov al, [argc]
	cmp rax, 3
	jne .create_dst		; the user requested writing to the default dst file

.open_dst:
	; open destination file
	mov rax, 2		; syscall #2 (open)
	mov rdi, [dst]		; arg1 = filename
	mov rsi, 1		; arg2 = O_WRONLY
	syscall			; call open
	cmp rax, 0
	jl .error_close
	mov [dst_fd], rax
	jmp .read

.create_dst:
	; create the default destination file "out.asm"
	mov rax, 85 		; syscall #85 (creat)
	mov rdi, default_dst	; arg1 = filename
	mov rsi, 453		; arg2 = O_WRONLY | O_CREAT | S_IRWXU
	syscall			; call creat
	cmp rax, 0
	jl .error_close
	mov [dst_fd], rax

.read:
	; read machine code file
	mov rax, 0		; syscall #0 (read)
	mov rdi, [src_fd]	; arg1 = fd
	; mov rdi, 3	; arg1 = fd
	lea rsi, [buffer]	; arg2 = buffer
	mov rdx, 49		; arg3 = nbyte
	syscall			; call read
	call close_src
	call close_dst
	jmp .exit

.error_close:
	; error; close src fd
	call close_src

.error:
	; error; no need to close src fd
	mov rsi, usage		; arg 2 = msg
	mov rdx, 30		; arg 3 = char count
	jmp .print

.print:
	; write string to stdout
	mov     rax, 1		; syscall #1 (write)
	mov     rdi, rax	; arg 1 = 1 (stdout)
	syscall			; call write
	jmp .exit

.exit:
	mov rax, 60     ; syscall #60 (exit)
	mov rdi, 0      ; arg 1 = 0 (OK)
	syscall         ; call exit


; function to close src file
close_src:
	mov rax, 3		; syscall #3 (close)
	mov rdi, [src_fd]	; arg1 = fd
	syscall			; call close
	ret

; function to close dst file
close_dst:
	mov rax, 3		; syscall #3 (close)
	mov rdi, [dst_fd]	; arg1 = fd
	syscall			; call close
	ret
