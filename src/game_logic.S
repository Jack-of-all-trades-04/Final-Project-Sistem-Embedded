#include <avr/io.h>
#include "definitions.inc"

.section .text
.global check_game_status
.global process_win_logic
.global process_escape_logic
.global bcd_convert

; --- Cek Menang atau Kalah ---
check_game_status:
    cpi score, 11        ; Jarak <= 10?
    brlo is_win
    cpi score, 100       ; Jarak >= 100?
    brsh is_escape
    clc
    clz
    ret
is_win:
    sec
    ret
is_escape:
    sez
    clc
    ret

; --- Logika Menang (Faktorisasi) ---
process_win_logic:
    rcall motor_stop
    rcall buzzer_off
    cbi _SFR_IO_ADDR(PORTB), 0 
    rcall oled_clear        
    ldi argument, 0xB0
    ldi r22, 0
    rcall oled_set_cursor
    ldi r30, lo8(font_WIN)
    ldi r31, hi8(font_WIN)
    rcall oled_print_char   ; W
    rcall oled_print_char   ; I
    rcall oled_print_char   ; N
    ; Delay Panjang
    ldi r24, lo8(100000)
    ldi r25, hi8(100000)
delay_loop_win:
    sbiw r24, 1             ; Kurangi nilai r25:r24 sebanyak 1
    brne delay_loop_win     ; Jika belum nol, lompat kembali ke delay_loop_win
    
    ; Jika ingin delay lebih lama lagi, Anda bisa menumpuk loop ini
    ldi r24, lo8(100000)
    ldi r25, hi8(100000)
delay_loop_win_2:
    sbiw r24, 1
    brne delay_loop_win_2

    ret                     ; Kembali ke main loop

; --- Logika Ikan Lepas (Faktorisasi) ---
process_escape_logic:
    rcall motor_stop
    rcall buzzer_off
    rcall oled_clear
    ; Tampilkan "ESC" singkat jika perlu
    ret

; Input: r24 (skor dari EEPROM)
; Output: r24 (Puluhan), r22 (Satuan)

bcd_convert:
    ldi r22, 0          ; Reset satuan
    ldi r20, 10         ; Pembagi

div_loop:
    cp r24, r20
    brlo done_div       ; Jika r24 < 10, selesai
    sub r24, r20        ; r24 = r24 - 10
    inc r22             ; r22 (Puluhan) bertambah
    rjmp div_loop

done_div:
    ; Sekarang r22 = Puluhan, r24 = Satuan
    ; Tukar agar r24 Puluhan, r22 Satuan
    mov temp, r24
    mov r24, r22
    mov r22, temp
    ret

.section .progmem
font_WIN:     .byte 0x7F, 0x20, 0x18, 0x20, 0x7F, 0x00, 0x41, 0x7F, 0x41, 0x00, 0x7F, 0x04, 0x08, 0x10, 0x7F