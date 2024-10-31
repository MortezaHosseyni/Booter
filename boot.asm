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

wait_for_choice:
    MOV ah, 0             ; BIOS interrupt to wait for a keypress
    int 0x16              ; Result in AL

    CMP al, '1'           ; Check if '1' was pressed
    je about_os
    CMP al, '2'           ; Check if '2' was pressed
    je system_info
    CMP al, '3'           ; Check if '3' was pressed
    je screen_info
    CMP al, '4'           ; Check if '4' was pressed
    je shutdown

    jmp wait_for_choice   ; Loop if invalid choice

about_os:
    call cls
    MOV si, about_msg
    call print_string
    jmp display_menu

system_info:
    call cls
    MOV si, sys_info_msg
    call print_string

    ; Detect if CPUID is supported
    pushfd                 ; Save original EFLAGS
    POP ax                 ; Load EFLAGS into AX
    MOV cx, ax             ; Copy original EFLAGS
    xor ax, 1 << 21        ; Toggle bit 21 of EFLAGS
    PUSH ax
    popfd                  ; Update EFLAGS with modified value
    pushfd
    POP ax                 ; Load updated EFLAGS
    xor ax, cx
    jz no_cpuid            ; If no change in bit 21, CPUID unsupported

    ; CPUID is supported
    MOV ax, 0              ; CPUID function 0 (vendor string)
    cpuid
    MOV word [vendor+0], bx
    MOV word [vendor+2], dx
    MOV word [vendor+4], cx
    MOV si, vendor_msg
    call print_string
    MOV si, vendor
    call print_string
    jmp display_menu

no_cpuid:
    MOV si, no_cpuid_msg
    call print_string
    jmp display_menu

screen_info:
    call cls
    call get_screen_info
    jmp display_menu

shutdown:
    cli                   ; Disable interrupts
    hlt                   ; Halt the system

display_menu:
    call cls
    MOV si, menu_msg
    call print_string
    jmp wait_for_choice

get_screen_info:
    MOV ah, 0x0F          ; BIOS interrupt to get video mode
    int 0x10              ; Result in AL (mode) and other registers

    MOV si, screen_info_msg
    call print_string

    MOV si, video_mode_msg
    call print_string
    ADD al, '0'           ; Convert mode number to ASCII
    call print_char

    MOV si, linefeed_msg
    call print_string

    RET

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

; Menu and message strings
menu_msg db "++ BOOTER ++", 0x0D, 0x0A
         db "1. About OS", 0x0D, 0x0A
         db "2. System Information", 0x0D, 0x0A
         db "3. Screen Information", 0x0D, 0x0A
         db "4. Shutdown", 0x0D, 0x0A, 0
about_msg db "This is a simple OS bootloader created for learning purposes. | Morteza Hosseini", 0x0D, 0x0A, 0
sys_info_msg db "System Info:", 0x0D, 0x0A, 0
no_cpuid_msg db "CPUID not supported on this CPU.", 0x0D, 0x0A, 0
vendor_msg db "CPU Vendor: ", 0
screen_info_msg db "Screen Information:", 0x0D, 0x0A, 0
video_mode_msg db "Video Mode: ", 0
linefeed_msg db 0x0D, 0x0A, 0

vendor db "Unknown", 0, 0, 0, 0, 0, 0

times 510-($-$$) db 0     ; Pad the boot sector to 512 bytes
dw 0xAA55                 ; Boot signature