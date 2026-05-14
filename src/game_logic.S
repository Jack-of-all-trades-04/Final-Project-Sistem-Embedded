#include <avr/io.h>
#include "definitions.inc"

.section .text
.global check_game_status
.global bcd_convert
; Fungsi untuk mengecek apakah skor sudah mencapai target
; Input: Register 'score'
; Output: Carry flag set jika menang
check_game_status:
    cpi score, 30        
    brsh player_win      
    clc                  
    ret
player_win:
    sec                  ; Hanya set carry flag
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