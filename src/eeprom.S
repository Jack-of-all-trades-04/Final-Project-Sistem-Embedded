#include <avr/io.h>
#include "definitions.inc"

.section .text
.global eeprom_write
.global eeprom_read

; Menulis satu byte ke EEPROM
; Input: r24 (Alamat), r22 (Data)
eeprom_write:
    sbic _SFR_IO_ADDR(EECR), EEPE
    rjmp eeprom_write    ; Tunggu jika ada penulisan sebelumnya
    
    out _SFR_IO_ADDR(EEARL), r24 ; Set alamat (0-255)
    out _SFR_IO_ADDR(EEDR), r22  ; Set data
    sbi _SFR_IO_ADDR(EECR), EEMPE ; Master Write Enable
    sbi _SFR_IO_ADDR(EECR), EEPE  ; Start Write
    ret

; Membaca satu byte dari EEPROM
; Input: r24 (Alamat), Output: r24 (Data)
eeprom_read:
    sbic _SFR_IO_ADDR(EECR), EEPE
    rjmp eeprom_read
    
    out _SFR_IO_ADDR(EEARL), r24
    sbi _SFR_IO_ADDR(EECR), EERE  ; Start Read
    in r24, _SFR_IO_ADDR(EEDR)
    ret