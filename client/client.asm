

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

    mov byte [send_buffer], 65      ; A dans le buffer

    mov r12, 26                     ; compteur 26 lettres
    call .loop                      ; Lancer la boucle

    call close_connection           ; Fermer la connexion
    
    mov rax, 60                     ; sys_exit
    xor rdi, rdi                    ; code = 0
    syscall


.loop:
    cmp r12, 0                      ; Si on a finit la boucle
    je .end_loop                    ; On sort de la boucle
    mov rdx, 1                      ; On va envoyer qu'un seul char
    call send_data                  ; Envoyer les données
    inc byte [send_buffer]          ; On passe à la lettre suivante
    dec r12
    jmp .loop
    
.end_loop:
    mov byte [send_buffer], 10      ; \n dans le buffer
    mov rdx, 1                      ; On va envoyer qu'un seul char
    call send_data                  ; Dernier envoi pour le retour à la ligne

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
    mov rax, 1                      ; sys_write
    mov rdi, [sockfd]               ; sockfd
    mov rsi, send_buffer            ; Votre tampon dans .bss
    syscall                         ; RAX = nombre d'octets reçus (0 si connexion fermée)

    cmp rax, 0
    je error_connect                ; Si RAX = 0, la connexion est fermée

    ret

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
