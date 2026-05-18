#include <avr/io.h>
#include "definitions.inc"

; =============================================================
; INTERRUPT VECTOR TABLE - ATMega328P
; Setiap vektor = 2 byte (1 word)
; Reset = 0x0000, INT0 = 0x0002, INT1 = 0x0004
; =============================================================
.section .vectors
    rjmp reset_handler          ; 0x0000: Reset
    .org 0x0002
    rjmp int0_handler           ; 0x0002: INT0 (Encoder CLK / A → D2)
    .org 0x0004
    rjmp int1_handler           ; 0x0004: INT1 (Encoder DT / B → D3)

.section .text
.global int0_handler
.global int1_handler
.global interrupt_init

; --- Handler Reset ---
reset_handler:
    jmp main                    ; Melompat ke main di main.S

; --- 1. Inisialisasi Interrupt ---
interrupt_init:
    ; Set D2 dan D3 sebagai INPUT
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
    push r24
    push r25

    ; Hanya hitung skor jika sedang dalam mode FIGHT (state = 1)
    cpi state, 1
    brne int0_exit

    ; --- DEBOUNCE: Tunggu ~10ms lalu cek apakah D2 masih LOW ---
    ; 10ms @ 16MHz = 160.000 siklus, loop 4 siklus = 40.000 iterasi
    ldi r24, lo8(40000)
    ldi r25, hi8(40000)
debounce_wait:
    sbiw r24, 1
    brne debounce_wait

    ; Setelah delay, cek apakah D2 masih LOW (bukan noise/bounce)
    sbic _SFR_IO_ADDR(PIND), 2  ; Skip jika D2 LOW (valid pulse)
    rjmp int0_exit              ; D2 sudah HIGH lagi = bounce, abaikan

    inc score                   ; Tambah skor +1 (pulse valid)

int0_exit:
    pop r25
    pop r24
    pop temp
    out _SFR_IO_ADDR(SREG), temp
    pop temp
    reti

; --- 3. Handler INT1 (Rotary Encoder Channel B / DT → D3) ---
int1_handler:
    reti