#include <avr/io.h>
#include "definitions.inc"

; =============================================================
; INTERRUPT VECTOR TABLE
; ATMega328P: Setiap vektor = 4 byte (2 word)
; Reset   = 0x0000
; INT0    = 0x0004
; INT1    = 0x0008
; =============================================================
.section .vectors
    rjmp reset_handler          ; 0x0000: Reset
    .org 0x0004
    rjmp int0_handler           ; 0x0004: INT0 (Encoder CLK / A → D2)
    .org 0x0008
    rjmp int1_handler           ; 0x0008: INT1 (Encoder DT / B → D3)

.section .text
.global int0_handler
.global int1_handler
.global interrupt_init

; --- Handler Reset ---
reset_handler:
    jmp main                    ; Melompat ke main di main.S

; --- 1. Inisialisasi Interrupt ---
interrupt_init:
    ; Set D2 dan D3 sebagai INPUT terlebih dahulu
    cbi _SFR_IO_ADDR(DDRD), 2   ; D2 = INPUT (CLK Encoder)
    cbi _SFR_IO_ADDR(DDRD), 3   ; D3 = INPUT (DT Encoder)

    ; Aktifkan Pull-up Internal pada D2 dan D3
    sbi _SFR_IO_ADDR(PORTD), 2
    sbi _SFR_IO_ADDR(PORTD), 3

    ; Set D4 sebagai INPUT (Touch Sensor)
    cbi _SFR_IO_ADDR(DDRD), 4

    ; Konfigurasi INT0: Falling Edge (ISC01=1, ISC00=0)
    ldi temp, (1 << ISC01)
    sts _SFR_MEM_ADDR(EICRA), temp

    ; Aktifkan INT0 di EIMSK
    ldi temp, (1 << INT0)
    sts _SFR_MEM_ADDR(EIMSK), temp

    sei                         ; Global Interrupt Enable
    ret

; --- 2. Handler INT0 (Rotary Encoder Channel A / CLK → D2) ---
; Dipicu setiap kali encoder diputar (Falling Edge pada D2)
int0_handler:
    push temp
    in temp, _SFR_IO_ADDR(SREG)
    push temp

    ; Hanya hitung skor jika sedang dalam mode FIGHT (state = 1)
    cpi state, 1
    brne int0_exit

    inc score                   ; Tambah skor +1 per putaran

int0_exit:
    pop temp
    out _SFR_IO_ADDR(SREG), temp
    pop temp
    reti

; --- 3. Handler INT1 (Rotary Encoder Channel B / DT → D3) ---
int1_handler:
    reti