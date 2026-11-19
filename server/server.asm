; -- MACRO IN NASM --
%macro write 3
    mov rax, 1                    ; Numéro du syscall : sys_write
    mov rdi, %1                   ; Descripteur de fichier : 1 (stdout / écran)
    mov rsi, %2                   ; Adresse mémoire du message
    mov rdx, %3                   ; Taille du message en octets
    syscall                       ; Exécution de l'appel système
%endmacro

; Va remplacer les valeurs dans les registres utiliser.
; Il faut donc les sauvegarder au préalable si besoin.


section .data
    msg db "Hello, World!", 10    ; Chaîne de caractères suivie d'un saut de ligne (ASCII 10)
    len equ $ - msg               ; Calcul automatique de la longueur de la chaîne

section .text
    global _start                 ; Point d'entrée requis par l'éditeur de liens (ld)

_start:
    ; Appel système sys_write (rax = 1)
    write 1, msg, len


    ; Appel système sys_exit (rax = 60)
    mov rax, 60                   ; Numéro du syscall : sys_exit
    mov rdi, 0                    ; Code de retour : 0 (succès)
    syscall                       ; Exécution de l'appel système