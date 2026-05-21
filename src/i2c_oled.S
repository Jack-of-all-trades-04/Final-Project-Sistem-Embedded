.global oled_set_cursor

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
    ldi argument, 0xAE ; display OFF
    rcall oled_command
    ldi argument, 0xA8 ; Set Multiplex Ratio
    rcall oled_command
    ldi argument, 0x1F ; 31 (berarti 32 baris untuk 128x32)
    rcall oled_command
    ldi argument, 0xD3 ; Set Display Offset
    rcall oled_command
    ldi argument, 0x00 ; no offset
    rcall oled_command
    ldi argument, 0x40 ; Set Display Start Line = 0
    rcall oled_command
    ldi argument, 0xDA ; Set COM Pins Hardware Configuration
    rcall oled_command
    ldi argument, 0x02 ; Penting untuk 128x32
    rcall oled_command
    ldi argument, 0x81 ; Contrast
    rcall oled_command
    ldi argument, 0x7F
    rcall oled_command
    ldi argument, 0xA1 ; Segment remap
    rcall oled_command
    ldi argument, 0xC8 ; COM scan direction
    rcall oled_command
    ldi argument, 0xA6 ; Normal display
    rcall oled_command
    ldi argument, 0x8D ; Charge pump
    rcall oled_command
    ldi argument, 0x14
    rcall oled_command
    ldi argument, 0xAF ; Display ON
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

; input:
; argument = page OLED, contoh 0xB0 untuk baris/page 0
; r22 = column, contoh 0 untuk kolom paling kiri
oled_set_cursor:
    ; set page
    rcall oled_command
    ; set lower column nibble
    mov temp, r22
    andi temp, 0x0F
    mov argument, temp
    rcall oled_command
    ; set higher column nibble
    mov temp, r22
    swap temp
    andi temp, 0x0F
    ori temp, 0x10
    mov argument, temp
    rcall oled_command

    ret

.section .progmem
font_table:
.byte 0x7F, 0x09, 0x09, 0x01, 0x00 ; F
.byte 0x00, 0x41, 0x7F, 0x41, 0x00 ; I
.byte 0x26, 0x49, 0x49, 0x49, 0x32 ; S
.byte 0x7F, 0x08, 0x08, 0x08, 0x7F ; H