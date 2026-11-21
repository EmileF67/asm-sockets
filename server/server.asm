; -- MACRO IN NASM --
%macro write 3
    mov rax, 1                    ; Numéro du syscall : sys_write
    mov rdi, %1                   ; Descripteur de fichier : 1 (stdout / écran)
    mov rsi, %2                   ; Adresse mémoire du message
    mov rdx, %3                   ; Taille du message en octets
    syscall                       ; Exécution de l'appel système
%endmacro

section .data
    sockaddr_in:
        dw 2                ; sin_family = AF_INET (2)
        dw 0x901f           ; sin_port = 8080 in network byte order (big-endian: 0x1f90 -> 0x901f)
        dd 0                ; sin_addr = INADDR_ANY (0.0.0.0)
        dq 0                ; sin_zero = 8 bytes of zero padding

    ; Error messages
    err1 db "Error1", 10
    err1_len equ $ - err1

    err2 db "Error2", 10
    err2_len equ $ - err2
    
    err3 db "Error3", 10
    err3_len equ $ - err3
    
    err4 db "Error4", 10
    err4_len equ $ - err4
    
    err5 db "Error5", 10
    err5_len equ $ - err5
    
    err6 db "Error6", 10
    err6_len equ $ - err6

section .bss
    send_buffer resb 4096           ; Buffer d'envoi
    recv_buffer resb 4096           ; Buffer de reception
    buffer resb 4096
    server_fd resq 1                ; Le File Descriptor du socket serveur
    client_fd resq 1                ; Le File Descriptor du socket

section .text
    global _start                 ; Point d'entrée requis par l'éditeur de liens (ld)

_start:
    ; Appel système sys_write (rax = 1)

    call create_socket              ; Créer le socket
    mov [server_fd], rax            ; rbx contiendra le File Descriptor du socket
    ; write 1, err1, err1_len

    call bind_socket                ; Bind le port
    ; write 1, err2, err2_len

    call listen_socket              ; Écouter pour des connexions
    ; write 1, err3, err3_len

    call accept_client              ; Accepter un client
    mov [client_fd], rax            ; save client_fd in r13
    ; write 1, err4, err4_len

    call receive_loop               ; Recevoir des données

    ; write 1, recv_buffer, rax       ; Ecrire les données

    ; Appel système sys_exit (rax = 60)
    mov rax, 60                     ; Numéro du syscall : sys_exit
    mov rdi, 0                      ; Code de retour : 0 (succès)
    syscall                         ; Exécution de l'appel système



receive_loop:
    call receive_data               ; Recevoir des données
    mov r12, rax
    ; call print_int
    write 1, recv_buffer, r12       ; Ecrire les données
    jmp receive_loop

    ret


print_int:
    mov rcx, buffer + 19
    mov byte [rcx], 10
    mov rbx, 10

.boucle_conversion:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rcx
    mov [rcx], dl
    test rax, rax
    jnz .boucle_conversion

    mov rax, 1
    mov rdi, 1
    mov rsi, rcx
    mov rdx, buffer + 20
    sub rdx, rcx
    syscall
    ret


create_socket:
    mov rax, 41                     ; sys_socket
    mov rdi, 2                      ; AF_INET (IPv4)
    mov rsi, 1                      ; SOCK_STREAM (TPC)
    xor rdx, rdx                    ; 0 (Protocole par défaut)
    syscall
    
    cmp rax, 0
    jl error                        ; Saute si RAX est négatif

    ret
    

bind_socket:
    mov rax, 49                     ; sys_bind
    mov rdi, [server_fd]            ; server_fd
    mov rsi, sockaddr_in            ; pointer to struct sockaddr_in or `lea rsi, [rel sockaddr_in]`
    mov rdx, 16                     ; sizeof(struct sockaddr_in)
    syscall

    ret


listen_socket:
    mov rax, 50                     ; SYS_listen
    mov rdi, [server_fd]            ; server_fd
    mov rsi, 10                     ; backlog
    syscall

    ret


accept_client:
    mov rax, 43                     ; SYS_accept
    mov rdi, [server_fd]            ; server_fd
    xor rsi, rsi                    ; addr = NULL (ignore client IP/port)
    xor rdx, rdx                    ; addrlen = NULL
    syscall
    
    ret


receive_data:
    mov rax, 0                      ; sys_read
    mov rdi, [client_fd]            ; client_fd
    mov rsi, recv_buffer            ; Votre tampon dans .bss
    mov rdx, 4096                   ; Taille max à lire
    syscall                         ; RAX = nombre d'octets reçus (0 si connexion fermée)

    cmp rax, 0
    je close_client                 ; Si RAX = 0, la connexion est fermée
    jl error_connect_client         ; Si RAX < 0, une erreur est survenue

    ret


send_data:
    mov rsi, send_buffer            ; Initialiser le pointeur avant la boucle

.send_loop:
    mov rax, 1                      ; sys_write
    mov rdi, [client_fd]               ; descripteur de fichier du socket
    syscall                         ; RAX = nombre d'octets reçus (0 si connexion fermée)

    cmp rax, 0
    jle error_connect_client        ; Si RAX <= 0, la connexion est fermée

    cmp rax, rdx
    jl .partially_sent_data         ; Si RAX < RDX, on essaye d'envoyer le reste des données

    ret

.partially_sent_data:
    add rsi, rax                    ; Avancer le pointeur de RAX octets
    sub rdx, rax                    ; Réduire la taille restante de RAX octets
    jmp .send_loop                  ; Recommencer l'envoi


close_client:
    mov rax, 3                      ; sys_close = 3
    mov rdi, [client_fd]            ; Descripteur du socket à fermer
    syscall

    ret

close_server:
    mov rax, 3                      ; sys_close = 3
    mov rdi, [server_fd]            ; Descripteur du socket à fermer
    syscall

    ret



; -- ERRORS --


error_connect_client:
    call close_client
    jmp error

error_connect_server:
    ; Fermer le socket avant de quitter en erreur
    call close_server
    jmp error


error:
    mov rax, 60                     ; sys_exit
    mov rdi, 1                      ; code = 1
    syscall