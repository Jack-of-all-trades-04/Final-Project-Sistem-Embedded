#include <avr/io.h>
#include "definitions.inc"

.section .text
.global i2c_init
.global oled_init
.global oled_command
.global oled_data
.global oled_clear
.global oled_print_char

i2c_init:
    ldi temp, 72
    sts _SFR_MEM_ADDR(TWBR), temp
    ldi temp, 0
    sts _SFR_MEM_ADDR(TWSR), temp
    ret

i2c_start:
    ldi temp, (1<<TWINT) | (1<<TWSTA) | (1<<TWEN)
    sts _SFR_MEM_ADDR(TWCR), temp
wait_start:
    lds temp, _SFR_MEM_ADDR(TWCR)
    sbrs temp, TWINT
    rjmp wait_start
    ret

i2c_stop:
    ldi temp, (1<<TWINT) | (1<<TWSTO) | (1<<TWEN)
    sts _SFR_MEM_ADDR(TWCR), temp
    ret

i2c_write:
    sts _SFR_MEM_ADDR(TWDR), argument
    ldi temp, (1<<TWINT) | (1<<TWEN)
    sts _SFR_MEM_ADDR(TWCR), temp
wait_write:
    lds temp, _SFR_MEM_ADDR(TWCR)
    sbrs temp, TWINT
    rjmp wait_write
    ret

oled_command:
    push argument
    rcall i2c_start
    ldi argument, 0x78
    rcall i2c_write
    ldi argument, 0x00
    rcall i2c_write
    pop argument
    rcall i2c_write
    rcall i2c_stop
    ret

oled_init:
    rcall i2c_init
    ldi argument, 0xAE
    rcall oled_command
    ldi argument, 0x8D
    rcall oled_command
    ldi argument, 0x14
    rcall oled_command
    ldi argument, 0xAF
    rcall oled_command
    ret

oled_data:
    push argument
    rcall i2c_start
    ldi argument, 0x78
    rcall i2c_write
    ldi argument, 0x40
    rcall i2c_write
    pop argument
    rcall i2c_write
    rcall i2c_stop
    ret

oled_clear:
    ldi r24, 8
    ldi r22, 0xB0
page_loop:
    mov argument, r22
    rcall oled_command
    ldi argument, 0x00
    rcall oled_command
    ldi argument, 0x10
    rcall oled_command
    ldi r25, 128
column_loop:
    ldi argument, 0x00
    rcall oled_data
    dec r25
    brne column_loop
    inc r22
    dec r24
    brne page_loop
    ret

oled_print_char:
    ldi r25, 5
print_loop:
    lpm argument, Z+
    rcall oled_data
    dec r25
    brne print_loop
    ldi argument, 0x00
    rcall oled_data
    ret

.section .progmem
font_table:
.byte 0x7F, 0x09, 0x09, 0x01, 0x00 ; F
.byte 0x00, 0x41, 0x7F, 0x41, 0x00 ; I
.byte 0x26, 0x49, 0x49, 0x49, 0x32 ; S
.byte 0x7F, 0x08, 0x08, 0x08, 0x7F ; H