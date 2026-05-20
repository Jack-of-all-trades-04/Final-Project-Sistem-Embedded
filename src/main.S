#include <avr/io.h>
#include "definitions.inc"

.section .text
.global main

main:
    ldi temp, lo8(RAMEND)
    out _SFR_IO_ADDR(SPL), temp
    ldi temp, hi8(RAMEND)
    out _SFR_IO_ADDR(SPH) , temp

    rcall pwm_init          
    rcall motor_stop        
    rcall oled_init
    rcall oled_clear
    
    ; Inisialisasi Pin Encoder sebagai Input dengan Pull-up
    cbi _SFR_IO_ADDR(DDRD), ENC_A
    sbi _SFR_IO_ADDR(PORTD), ENC_A
    
    ldi state, 0
    clr score
    clr last_enc       

show_waiting:
    ldi state, 0
    clr score
    rcall process_escape_logic ; Gunakan fungsi faktorisasi
    
    ; Tampilkan UI WAIT
    ldi argument, 0xB0
    ldi r22, 0
    rcall oled_set_cursor
    ldi r30, lo8(font_waiting)
    ldi r31, hi8(font_waiting)
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char

    ; Baris 2: "Your Score:" (Page 1)
    ldi argument, 0xB1      ; Page 1 (Baris Baru)
    ldi r22, 0
    rcall oled_set_cursor
    ldi r30, lo8(font_your_score)
    ldi r31, hi8(font_your_score)
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char

    ; Baca EEPROM untuk total tangkapan
    ldi r24, 0
    rcall eeprom_read
    mov r23, r24            ; r23 sebagai akumulator total
    cpi r24, 255
    brne display_wait_score
    clr r24
display_wait_score:
    rcall bcd_convert
    rcall display_digit     ; Puluhan
    mov r24, r22
    rcall display_digit     ; Satuan

game_loop:
    tst state
    breq check_strike
    rjmp fight_logic
    
fight_logic:
    ; --- 1. DETEKSI ENCODER (POLLING) ---
    ; Kita mencari kondisi "Falling Edge" (dari HIGH ke LOW)
    in temp, _SFR_IO_ADDR(PIND)
    andi temp, (1 << ENC_A) ; Isolasi pin D2
    
    cp temp, last_enc       ; Bandingkan dengan status sebelumnya
    breq skip_encoder       ; Jika tidak ada perubahan, skip
    
    mov last_enc, temp      ; Simpan status sekarang untuk loop depan
    
    tst temp                ; Apakah sekarang LOW? (Falling Edge)
    brne skip_encoder
    
    ; Jika terjadi putaran (D2 pindah ke LOW):
    subi score, 5           ; Jarak mendekat ke user
    brcc skip_encoder
    ldi score, 5            ; Batas minimum
skip_encoder:
    ; --- 2. LOGIKA IKAN (DELAY & PULL) ---
    ldi r24, lo8(50000)     ; Sesuaikan kecepatan ikan di sini
    ldi r25, hi8(50000)
delay_fight:
    sbiw r24, 1
    brne delay_fight

    inc score               ; Ikan menjauh secara otomatis

    ; --- 3. CEK MENANG / KALAH ---
    rcall check_game_status 
    brcs do_win             ; Carry = Menang (score <= 10)
    breq do_escape          ; Zero = Lepas (score >= 100)
    
    ldi argument, 0xB0      ; Page 1 (Baris Baru)
    ldi r22, 0
    rcall oled_set_cursor
    ldi r30, lo8(font_strike)
    ldi r31, hi8(font_strike)
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char

    ; --- 4. UPDATE OLED ---

    ldi argument, 0xB2
    ldi r22, 0
    rcall oled_set_cursor
    ldi r30, lo8(font_distance)
    ldi r31, hi8(font_distance)
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    mov r24, score
    rcall bcd_convert
    rcall display_digit     ; Puluhan
    mov r24, r22
    rcall display_digit     ; Satuan

    rjmp game_loop

check_strike:
    sbis _SFR_IO_ADDR(PIND), TOUCH_PIN 
    rjmp game_loop
    
    ; Transisi ke STRIKE
    ldi state, 1
    ldi score, 50           ; Jarak awal
    rcall oled_clear

    ldi r30, lo8(font_strike)
    ldi r31, hi8(font_strike)
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall oled_print_char
    rcall motor_set_speed
    rcall buzzer_on
    
    rjmp game_loop

do_win:
    rcall process_win_logic
    inc r23                 ; Tambah total tangkapan
    ldi r24, 0
    mov r22, r23
    rcall eeprom_write
delay_w: 
    sbiw r24, 1
    rjmp show_waiting

do_escape:
    rcall process_escape_logic
    rjmp show_waiting

; --- Fungsi Utility ---
display_digit:
    push r30
    push r31
    push r24
    push r25
    ldi r30, lo8(font_numbers)
    ldi r31, hi8(font_numbers)
    ldi r25, 5
    mul r24, r25
    add r30, r0
    adc r31, r1
    clr r1
    rcall oled_print_char
    pop r25
    pop r24
    pop r31
    pop r30
    ret

; --- Data Font ---
.section .progmem
font_waiting: .byte 0x7F, 0x20, 0x18, 0x20, 0x7F, 0x7E, 0x11, 0x11, 0x11, 0x7E, 0x00, 0x41, 0x7F, 0x41, 0x00, 0x01, 0x01, 0x7F, 0x01, 0x01
font_strike:  .byte 0x26, 0x49, 0x49, 0x49, 0x32, 0x01, 0x01, 0x7F, 0x01, 0x01, 0x7F, 0x09, 0x19, 0x29, 0x46, 0x00, 0x41, 0x7F, 0x41, 0x00, 0x7F, 0x08, 0x14, 0x22, 0x41, 0x7F, 0x49, 0x49, 0x49, 0x41
font_your_score:
    ; Y
    .byte 0x03, 0x04, 0x78, 0x04, 0x03
    ; o
    .byte 0x38, 0x44, 0x44, 0x44, 0x38
    ; u
    .byte 0x3C, 0x40, 0x40, 0x20, 0x7C
    ; r
    .byte 0x7C, 0x08, 0x04, 0x04, 0x08
    ; (Spasi)
    .byte 0x00, 0x00, 0x00, 0x00, 0x00
    ; S
    .byte 0x26, 0x49, 0x49, 0x49, 0x32
    ; c
    .byte 0x38, 0x44, 0x44, 0x44, 0x20
    ; o
    .byte 0x38, 0x44, 0x44, 0x44, 0x38
    ; r
    .byte 0x7C, 0x08, 0x04, 0x04, 0x08
    ; e
    .byte 0x38, 0x54, 0x54, 0x54, 0x18
    ; :
    .byte 0x00, 0x36, 0x36, 0x00, 0x00

font_numbers:
    .byte 0x3E, 0x51, 0x49, 0x45, 0x3E ; 0
    .byte 0x00, 0x42, 0x7F, 0x40, 0x00 ; 1
    .byte 0x42, 0x61, 0x51, 0x49, 0x46 ; 2
    .byte 0x21, 0x41, 0x45, 0x4B, 0x31 ; 3
    .byte 0x18, 0x14, 0x12, 0x7F, 0x10 ; 4
    .byte 0x27, 0x45, 0x45, 0x45, 0x39 ; 5
    .byte 0x3C, 0x4A, 0x49, 0x49, 0x30 ; 6
    .byte 0x01, 0x71, 0x09, 0x05, 0x03 ; 7
    .byte 0x36, 0x49, 0x49, 0x49, 0x36 ; 8
    .byte 0x06, 0x49, 0x49, 0x29, 0x1E ; 9

font_distance:
    ; D
    .byte 0x7F, 0x41, 0x41, 0x22, 0x1C
    ; i
    .byte 0x00, 0x44, 0x7D, 0x40, 0x00
    ; s
    .byte 0x48, 0x54, 0x54, 0x54, 0x20
    ; t
    .byte 0x04, 0x3F, 0x44, 0x40, 0x20
    ; a
    .byte 0x20, 0x54, 0x54, 0x54, 0x78
    ; n
    .byte 0x7C, 0x08, 0x04, 0x04, 0x78
    ; c
    .byte 0x38, 0x44, 0x44, 0x44, 0x20
    ; e
    .byte 0x38, 0x54, 0x54, 0x54, 0x18
    ; :
    .byte 0x00, 0x36, 0x36, 0x00, 0x00