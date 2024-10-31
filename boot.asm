; A simple bootloader with a text-based menu

BITS 16
ORG 0x7C00                ; Bootloader will load here by BIOS

start:
    MOV ax, 0x07C0        ; Set up stack
    ADD ax, 0x200
    MOV ss, ax
    MOV sp, 0x200

    call cls              ; Clear screen
    call display_menu     ; Show menu options

about_os:
    call cls
    MOV si, about_msg
    call print_string
    jmp display_menu

system_info:
    call cls
    MOV si, sys_info_msg
    call print_string
    jmp display_menu

screen_info:
    call cls
    call get_screen_info
    jmp display_menu

shutdown:
    cli                   ; Disable interrupts
    hlt                   ; Halt the system

; Clear the screen by writing spaces across it
cls:
    MOV ah, 0x06          ; BIOS scroll up function
    MOV al, 0             ; Clear entire screen
    MOV bh, 0x07          ; Attribute (gray on black)
    MOV cx, 0             ; Upper left corner (0,0)
    MOV dx, 0x184F        ; Bottom right corner (80x25)
    int 0x10
    RET

; Print a null-terminated string
print_string:
    .print_char:
        lodsb             ; Load byte from SI
        or al, al         ; Check if zero (end of string)
        jz .done
        MOV ah, 0x0E      ; BIOS teletype function
        int 0x10
        jmp .print_char
    .done:
        RET

; Print a single character
print_char:
    MOV ah, 0x0E          ; BIOS teletype function
    int 0x10
    RET