; Disassembler written in FASM assembly language
format ELF64 executable 3	; value 3 marks the executable for Linux system

entry start

struc object_code byte0, num_succ_bytes, mnemonic {
        .byte0 db byte0
        .num_succ_bytes db num_succ_bytes
	.mnemonic db mnemonic
}

obj_code_a0 object_code "a0", 2, "mov al, op"
obj_code_8a object_code "8a", 3, "mov op, op"

object_codes:
	dq obj_code_a0
	dq obj_code_8a
	dq "NL"

segment readable writable

usage		db "das86: usage: das86 src [dst]", 10, 0
default_dst	dq "out.asm", 0					; default dst file

segment readable writable

argc		db ?	; `argc` as passed to the main function
src		dq ?	; src file at cmdline arg #2
dst		dq ?	; dst file at cmdline arg #3
src_fd		dq ?	; src file descriptor
dst_fd		dq ?	; destination file descriptor
buffer		dw ?	; buffer to hold the data read using read syscall
tmp_buff	dw ?

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
	jmp .lseek

.create_dst:
	; create the default destination file "out.asm"
	mov rax, 85 		; syscall #85 (creat)
	mov rdi, default_dst	; arg1 = filename
	mov rsi, 453		; arg2 = O_WRONLY | O_CREAT | S_IRWXU
	syscall			; call creat
	cmp rax, 0
	jl .error_close
	mov [dst_fd], rax

.lseek:
	; reposition read file offset to 10 bytes (at the first instruction mnemonic)
	mov rax, 8		; syscall #8 (lseek)
	mov rdi, [src_fd]	; arg1 = fd
	mov rsi, 10		; arg2 = offset
	mov rdx, 0		; arg3 = SEEK_SET
	syscall			; call lseek
	cmp rax, rsi
	jne .close_fds

.main:
	; read the first instruction mnemonic (byte #0)
	mov rdx, 2		; arg3 = nbyte
	call read
	cmp rax, rdx
	jne .close_fds
	; retrieve object code information for buffer (byte #0)
	call find_obj_code
	jmp .exit
	; call find_num_succ_bytes


.close_fds:
	mov rdi, [src_fd]	; arg1 = fd
	call close
	mov rdi, [dst_fd]
	call close
	jmp .exit

.error_close:
	; error; close src fd
	mov rdi, [src_fd]	; arg1 = fd
	call close

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


; function to read machine code src file
read:
	mov rax, 0		; syscall #0 (read)
	mov rdi, [src_fd]	; arg1 = fd
	lea rsi, [buffer]	; arg2 = buffer
	syscall			; call read
	ret

; function to close file descriptor
close:
	mov rax, 3		; syscall #3 (close)
	syscall			; call close
	ret

find_obj_code:
	mov rdx, object_codes

find_obj_code_loop:
	mov rax, [rdx]
	mov cx, word [rax]
	add rdx, 8

	mov bx, [buffer]
	cmp cx, bx
	jne find_obj_code_loop
	ret	; result in rax

find_num_succ_bytes:
