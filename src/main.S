#include <avr/io.h>
#include "definitions.inc"

.section .text
.global main

main:
    ; --- 1. Inisialisasi Stack & I/O Dasar ---
    ldi temp, lo8(RAMEND)
    out _SFR_IO_ADDR(SPL), temp
    ldi temp, hi8(RAMEND)
    out _SFR_IO_ADDR(SPH), temp

    ; Set PB0 (LED) sebagai Output dan matikan di awal
    sbi _SFR_IO_ADDR(DDRB), 0
    cbi _SFR_IO_ADDR(PORTB), 0

    ; --- 2. Inisialisasi Modul ---
    rcall pwm_init          ; Inisialisasi Timer PWM
    rcall motor_stop        ; MOTOR MATI TOTAL
    rcall oled_init
    rcall oled_clear
    rcall interrupt_init    ; Aktifkan Interrupt & Pull-ups

    ldi state, 0
    clr score

; main.S - Bagian show_waiting
show_waiting:
    ldi state, 0
    clr score
    cbi _SFR_IO_ADDR(PORTB), 0 
    rcall motor_stop           
    rcall buzzer_off

    rcall oled_clear
    
    ; --- TAMPILKAN "WAIT" ---
    ldi argument, 0xB0      ; Baris 1
    rcall oled_command
    ldi r30, lo8(font_waiting)
    ldi r31, hi8(font_waiting)
    rcall oled_print_char   ; W
    rcall oled_print_char   ; A
    rcall oled_print_char   ; I
    rcall oled_print_char   ; T

    ; --- TAMPILKAN SKOR TERAKHIR ---
    ldi argument, 0xB1      ; Pindah ke Baris 2 (Page 1)
    rcall oled_command

    ldi r24, 0              ; Alamat EEPROM 0
    rcall eeprom_read       ; Hasil skor di r24
    
    rcall bcd_convert       ; r24 = Puluhan, r22 = Satuan
    
    push r22                ; Simpan Satuan ke stack
    mov r24, r24            ; Register r24 sudah berisi Puluhan
    rcall display_digit     ; Tampilkan Puluhan
    
    pop r24                 ; Ambil Satuan dari stack ke r24
    rcall display_digit     ; Tampilkan Satuan

    rjmp game_loop

; Rutin pembantu untuk mengarahkan ke font angka
; --- Rutin untuk menampilkan angka 0-9 ---
; Input: r24 (Angka 0-9 yang ingin ditampilkan)
display_digit:
    push r30
    push r31
    push r24
    push r25

    ; Hitung Offset: Alamat = font_numbers + (angka * 5)
    ldi r30, lo8(font_numbers)
    ldi r31, hi8(font_numbers)
    
    ldi r25, 5          ; Tiap angka lebarnya 5 byte
    mul r24, r25        ; r1:r0 = angka * 5
    add r30, r0         ; Tambahkan offset ke Z pointer
    adc r31, r1
    clr r0              ; Bersihkan r0 (karena r0 digunakan oleh instruksi mul)
    
    rcall oled_print_char ; Cetak karakter berdasarkan Z pointer
    
    pop r25
    pop r24
    pop r31
    pop r30
    ret

game_loop:
    tst state
    breq check_strike
    rjmp check_fight

check_strike:
    ; Cek sensor pada PIN D4 (TOUCH_PIN)
    sbis _SFR_IO_ADDR(PIND), TOUCH_PIN 
    rjmp game_loop

    ; --- 3. Mekanisme STRIKE ---
    ldi state, 1
    sbi _SFR_IO_ADDR(PORTB), 0 ; NYALAKAN LED saat Strike (Tanda Fight dimulai)
    
    rcall oled_clear
    ldi argument, 0xB0
    rcall oled_command
    ldi r30, lo8(font_strike)
    ldi r31, hi8(font_strike)
    rcall oled_print_char   ; S, T, R
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char

    ldi argument, 180       ; Nyalakan motor perlawanan
    rcall motor_set_speed
    
    rcall buzzer_on
    rjmp game_loop

check_fight:
    ; Indikasi visual: Nyalakan LED PB0 jika skor > 0
    tst score
    breq no_led
    sbi _SFR_IO_ADDR(PORTB), 0
no_led:

    rcall check_game_status 
    brcs win_game           ; Jika skor >= 30, menang
    rjmp game_loop

win_game:
    rcall motor_stop
    rcall buzzer_off
    cbi _SFR_IO_ADDR(PORTB), 0 
    
    rcall oled_clear        
    
    ldi argument, 0xB0      ; Page 0
    rcall oled_command
    ldi argument, 0x00      ; Set Lower Column Address to 0
    rcall oled_command
    ldi argument, 0x10      ; Set Higher Column Address to 0 (PENTING)
    rcall oled_command

    ldi r30, lo8(font_WIN)
    ldi r31, hi8(font_WIN)
    rcall oled_print_char   ; W
    rcall oled_print_char   ; I
    rcall oled_print_char   ; N

    ; EEPROM
    ldi r24, 0
    mov r22, score
    rcall eeprom_write

    ; Delay ~1 detik agar layar WIN sempat terbaca
    ; 1 detik @ 16MHz = 16.000.000 siklus
    ; Loop luar x loop dalam: 250 x 16000 = 4.000.000 iterasi x 4 siklus = ~1 detik
    ldi r25, 250            ; Loop luar (r25)
delay_outer:
    ldi r24, lo8(16000)     ; Loop dalam low byte
    ldi temp, hi8(16000)    ; Loop dalam high byte (pakai temp/r16 sebagai hi)
delay_inner:
    subi r24, 1
    sbci temp, 0
    brne delay_inner
    dec r25
    brne delay_outer

    rjmp show_waiting

; --- 5. Data Font Tambahan ---
.section .progmem
font_waiting:
.byte 0x7F, 0x20, 0x18, 0x20, 0x7F ; W
.byte 0x7E, 0x11, 0x11, 0x11, 0x7E ; A
.byte 0x00, 0x41, 0x7F, 0x41, 0x00 ; I
.byte 0x01, 0x01, 0x7F, 0x01, 0x01 ; T

font_strike:
.byte 0x26, 0x49, 0x49, 0x49, 0x32 ; S
.byte 0x01, 0x01, 0x7F, 0x01, 0x01 ; T
.byte 0x7F, 0x09, 0x19, 0x29, 0x46 ; R
.byte 0x00, 0x41, 0x7F, 0x41, 0x00 ; I
.byte 0x7F, 0x08, 0x14, 0x22, 0x41 ; K
.byte 0x7F, 0x49, 0x49, 0x49, 0x41 ; E

font_WIN:
.byte 0x7F, 0x20, 0x18, 0x20, 0x7F ; W
.byte 0x00, 0x41, 0x7F, 0x41, 0x00 ; I
.byte 0x7F, 0x04, 0x08, 0x10, 0x7F ; N

font_numbers:
; Pola angka 0-9 (Lebar 5 pixel per karakter)
font_0: .byte 0x3E, 0x51, 0x49, 0x45, 0x3E
font_1: .byte 0x00, 0x42, 0x7F, 0x40, 0x00
font_2: .byte 0x42, 0x61, 0x51, 0x49, 0x46
font_3: .byte 0x21, 0x41, 0x45, 0x4B, 0x31
font_4: .byte 0x18, 0x14, 0x12, 0x7F, 0x10
font_5: .byte 0x27, 0x45, 0x45, 0x45, 0x39
font_6: .byte 0x3C, 0x4A, 0x49, 0x49, 0x30
font_7: .byte 0x01, 0x71, 0x09, 0x05, 0x03
font_8: .byte 0x36, 0x49, 0x49, 0x49, 0x36
font_9: .byte 0x06, 0x49, 0x49, 0x29, 0x1E
font_colon: .byte 0x00, 0x36, 0x36, 0x00, 0x00 ; Titik dua (:)