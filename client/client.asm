

section .rodata
    ; Structure sockaddr_in pour 127.0.0.1:8080 (16 octets au total)
    server_addr:
        dw 2                        ; sin_family = AF_INET (2)
        dw 0x901f                   ; sin_port = 8080 (0x1f90) inversé en Big-Endian (0x901f)
        db 127, 0, 0, 1             ; sin_addr = 127.0.0.1 (chaque octet dans l'ordre)
        dq 0                        ; sin_zero = 8 octets à 0

section .bss
    send_buffer resb 4096           ; Buffer d'envoi
    recv_buffer resb 4096           ; Buffer de reception
    sockfd resq 1                   ; Le File Descriptor du socket

section .text
    global _start                   ; Point d'entrée requis par l'éditeur de liens (ld)


_start:
    call create_socket              ; Créer le socket -> rax
    mov [sockfd], rax               ; rbx contiendra le File Descriptor du socket

    call connect_server             ; Se connecter au serveur

    call fill                       ; Remplir le buffer

    mov rbx, 1000000                ; 1000000 fois
    call send_rbx_times             ; Envoyer les 27 chars

    call close_connection           ; Fermer la connexion
    
    mov rax, 60                     ; sys_exit
    xor rdi, rdi                    ; code = 0
    syscall


send_rbx_times:
    mov rdx, 27

.loop:
    cmp rbx, 0                      ; As-t-on envoyé le message RBX fois ?
    je .end_loop                    ; Si oui, alors on sort
    call send_data                  ; On envoie le message
    dec rbx                         ; RBX--
    jmp .loop                       ; Refaire la boucle

.end_loop:
    ret



; Remplir le buffer
fill:
    xor rcx, rcx                    ; Index i = 0
    mov al, 'A'                     ; Caractère courant = 'A' (65)

.loop_fill:
    mov [send_buffer + rcx], al     ; send_buffer[i] = caractère
    inc al                          ; Lettre suivante ('A' -> 'B' -> ...)
    inc rcx                         ; i++
    cmp rcx, 26                     ; A-t-on écrit 26 lettres ?
    jl .loop_fill                   ; Tant que i < 26, on continue

    mov byte [send_buffer + 26], 10 ; Ajoute '\n' à l'index 26
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


connect_server:
    mov rax, 42                     ; sys_connect
    mov rdi, [sockfd]               ; sockfd
    mov rsi, server_addr            ; Pointeur vers struct sockaddr_in (ou lea rsi, [rel server_addr])
    mov rdx, 16                     ; sizeof(struct sockaddr_in) = 16 octets
    syscall

    cmp rax, 0
    jl error_connect                ; Si RAX < 0, la connexion a échoué

    ret


send_data:
    mov rsi, send_buffer            ; Initialiser le pointeur avant la boucle

.send_loop:
    mov rax, 1                      ; sys_write
    mov rdi, [sockfd]               ; descripteur de fichier du socket
    syscall                         ; RAX = nombre d'octets reçus (0 si connexion fermée)

    cmp rax, 0
    je error_connect                ; Si RAX = 0, la connexion est fermée

    cmp rax, rdx
    jl .partially_sent_data         ; Si RAX < RDX, on essaye d'envoyer le reste des données

    ret

.partially_sent_data:
    add rsi, rax                    ; Avancer le pointeur de RAX octets
    sub rdx, rax                    ; Réduire la taille restante de RAX octets
    jmp send_data                   ; Recommencer l'envoi


receive_data:
    mov rax, 0                      ; sys_read
    mov rdi, [sockfd]               ; sockfd
    mov rsi, recv_buffer            ; Votre tampon dans .bss
    mov rdx, 4096                   ; Taille max à lire
    syscall                         ; RAX = nombre d'octets reçus (0 si connexion fermée)

    cmp rax, 0
    je error_connect                ; Si RAX = 0, la connexion est fermée

    ret

close_connection:
    mov rax, 3                      ; sys_close = 3
    mov rdi, [sockfd]               ; Descripteur du socket à fermer
    syscall

    ret



; -- ERRORS --

error_connect:
    ; Fermer le socket avant de quitter en erreur
    call close_connection


error:
    mov rax, 60                     ; sys_exit
    mov rdi, 1                      ; code = 1
    syscall
