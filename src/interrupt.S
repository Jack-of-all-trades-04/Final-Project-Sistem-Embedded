#include <avr/io.h>
#include "definitions.inc"

.section .vectors
    rjmp reset_handler          ; 0x0000: Reset
    .org 0x0002
    rjmp int0_handler           ; 0x0002: INT0 (Encoder A)
    .org 0x0004
    rjmp int1_handler           ; 0x0004: INT1 (Encoder B)

.section .text
.global int0_handler
.global int1_handler
.global interrupt_init

main_reset:
    jmp main                 ; Melompat ke main di main.S

; --- 1. Inisialisasi Interrupt ---
interrupt_init:
    sbi _SFR_IO_ADDR(PORTD), 2
    sbi _SFR_IO_ADDR(PORTD), 3

    ldi temp, (1 << ISC01)      ; HANYA aktifkan Falling Edge untuk INT0 (D2)
    sts _SFR_MEM_ADDR(EICRA), temp
    
    ldi temp, (1 << INT0)       ; HANYA aktifkan Mask untuk INT0
    sts _SFR_MEM_ADDR(EIMSK), temp
    
    cbi _SFR_IO_ADDR(DDRD), 4
    sei 
    ret

; --- 2. Handler INT0 (Rotary Encoder Channel A) ---
; Dipicu saat joran diputar
int0_handler:
    push temp
    in temp, _SFR_IO_ADDR(SREG)
    push temp

    ; Hanya hitung jika dalam mode FIGHT (state 1)
    cpi state, 1
    brne int0_exit

    inc score       ; Tambah skor sekali saja per falling edge
    
int0_exit:
    pop temp
    out _SFR_IO_ADDR(SREG), temp
    pop temp
    reti            ; Kembali ke main loop dengan aman

; --- 3. Handler INT1 (Rotary Encoder Channel B) ---
; Digunakan jika ingin pembacaan quadrature yang lebih presisi
int1_handler:
    ; Untuk proyek sederhana, kita bisa membiarkannya kosong 
    ; atau digunakan untuk logika tambahan.
    reti

; --- Handler Reset akan melompat ke label main di main.S ---
reset_handler:
    jmp main