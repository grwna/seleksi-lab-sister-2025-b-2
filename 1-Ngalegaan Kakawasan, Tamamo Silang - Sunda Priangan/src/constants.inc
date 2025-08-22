; Syscall numbers
SYS_READ   equ 0
SYS_WRITE  equ 1
SYS_OPEN   equ 2
SYS_CLOSE  equ 3
SYS_STAT   equ 4
SYS_SOCKET equ 41
SYS_BIND   equ 49
SYS_LISTEN equ 50
SYS_ACCEPT equ 43
SYS_FORK   equ 57
SYS_EXIT   equ 60

; Socket constants
AF_INET    equ 2
SOCK_STREAM equ 1

; Standard File Descriptors
STDIN      equ 0
STDOUT     equ 1
STDERR     equ 2

; Buffer sizes
REQUEST_BUFFER_SIZE equ 4096

; OTHER
PORT equ 8080



; Calling Convention of x86-64 (System V ABI)
; rax = syscall number
; rdi = 1st argument 
; rsi = 2nd argument
; rdx = 3rd argument
; r10 = 4th argument
; r8  = 5th argument
; r9  = 6th argument