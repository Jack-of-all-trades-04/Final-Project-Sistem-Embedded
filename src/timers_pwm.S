#include <avr/io.h>
#include "definitions.inc"

.section .text
.global pwm_init
.global motor_set_speed
.global motor_stop
.global buzzer_init
.global buzzer_play_note
.global buzzer_off

pwm_init:
    ; Timer0: Fast PWM, Non-Inverting, Prescaler 64
    ldi temp, (1 << COM0A1) | (1 << WGM01) | (1 << WGM00)
    sts _SFR_MEM_ADDR(TCCR0A), temp
    ldi temp, (1 << CS01) | (1 << CS00) ; Prescaler 64 (Timer Berjalan)
    sts _SFR_MEM_ADDR(TCCR0B), temp

    ; Set Pins as Output
    sbi _SFR_IO_ADDR(DDRD), MOTOR_PWM ; D6
    sbi _SFR_IO_ADDR(DDRD), MOTOR_DIR  ; D7
    sbi _SFR_IO_ADDR(DDRD), BUZZER_PIN ; D5
    ret

motor_set_speed:
    sbi _SFR_IO_ADDR(PORTD), MOTOR_PWM ; ENA HIGH
    sbi _SFR_IO_ADDR(PORTD), MOTOR_DIR ; Searah jarum jam
    sts _SFR_MEM_ADDR(OCR0A), argument ; Kecepatan (0-255)
    ret

motor_stop:
    ldi temp, 0
    sts _SFR_MEM_ADDR(OCR0A), temp
    cbi _SFR_IO_ADDR(PORTD), MOTOR_DIR
    cbi _SFR_IO_ADDR(PORTD), MOTOR_PWM
    ret

; --- Inisialisasi Timer 1 untuk Passive Buzzer ---
buzzer_init:
    ; Mode 4: CTC (Clear Timer on Compare Match) dengan TOP di OCR1A
    ldi temp, (1 << COM1B0) 
    sts _SFR_MEM_ADDR(TCCR1A), temp
    
    ; WGM12: CTC Mode, CS11: Prescaler 8
    ldi temp, (1 << WGM12) | (1 << CS11)
    sts _SFR_MEM_ADDR(TCCR1B), temp
    
    sbi _SFR_IO_ADDR(DDRD), BUZZER_PIN ; D5 sebagai Output
    ret

; --- Memainkan Nada ---
; Input: r25:r24 (Menentukan FREKUENSI melalui OCR1A)
buzzer_play_note:
    ; Dalam mode CTC, kita harus menulis ke OCR1A untuk mengubah frekuensi
    sts _SFR_MEM_ADDR(OCR1AH), r25
    sts _SFR_MEM_ADDR(OCR1AL), r24
    
    ; Aktifkan kembali toggle jika sebelumnya dimatikan
    ldi temp, (1 << COM1B0)
    sts _SFR_MEM_ADDR(TCCR1A), temp
    ret

buzzer_off:
    ldi temp, 0
    sts _SFR_MEM_ADDR(TCCR1A), temp
    ret