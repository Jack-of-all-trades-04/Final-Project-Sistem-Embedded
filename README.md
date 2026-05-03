# Fish Mania - Final Project Sistem Embedded

Kelompok 16 :
1. Ferdyano 2406353723
2. Valiant Joshua 2406352153
3. Novan Agung Wicaksono 2406401294
4. Zulfahmi Fajri 2406345425

Aslab Pendamping : Jesaya David [JD]

Sistem simulasi memancing interaktif berbasis AVR Assembly (.S) yang menggabungkan berbagai sensor dan aktuator untuk memberikan pengalaman bermain yang imersif.

## 1. Introduction to the Problem and the Solution
**Problem:**
Banyak sistem embedded edukatif hanya berfokus pada logika input-output sederhana tanpa memberikan umpan balik (feedback) fisik yang nyata. Hal ini membuat pembelajaran interaksi manusia dan mesin (HCI) menjadi kurang menantang, terutama saat menggunakan bahasa pemrograman tingkat rendah seperti Assembly.

**Solution:**
**Fish Mania** adalah sebuah rangkaian yang mengimplementasikan konsep *serious game* yang mensimulasikan dinamika memancing. Sistem ini menggunakan sensor sentuh untuk mendeteksi "strike" (ikan memakan umpan) secara instan, dan mewajibkan pengguna memberikan input balik melalui Rotary Encoder untuk memenangkan permainan. Solusi ini mengintegrasikan mekanisme perlawanan fisik menggunakan Motor DC yang dikontrol secara real-time, memberikan tantangan motorik sekaligus mendemonstrasikan efisiensi kode Assembly dalam menangani sistem multi-modul.

## 2. Hardware Design and Implementation Details
Sistem ini menggunakan **Arduino Uno (ATMega328P)** sebagai kontroler utama dengan alokasi hardware sebagai berikut:

![Full Rangkaian](https://hackmd.io/_uploads/r1tsyxrAbl.png)

| Komponen | Pin Arduino | Fungsi |
| :--- | :--- | :--- |
| **Capacitive Sensor** | D7 | Mendeteksi sentuhan pemain saat ikan memakan umpan. |
| **Rotary Encoder** | D2, D3, D4 | Memanfaatkan External Interrupt (INT0, INT1) untuk menghitung gulungan senar. |
| **DC Motor & L298N** | D5, D6 | Menjalankan mekanisme perlawanan ikan (Belt Loop) menggunakan PWM. |
| **OLED 0.96" I2C** | A4, A5 | Menampilkan UI, skor, dan status sistem via protokol I2C. |
| **Passive Buzzer** | B1 | Memberikan feedback suara (Timer1 PWM). |
| **EEPROM** | Internal | Menyimpan skor tertinggi dan inventaris ikan secara permanen. |

**Power Design:** Sistem ditenagai secara mandiri menggunakan 2 unit baterai Lithium 18650 (7.4V) yang dihubungkan ke pin VIN untuk mobilitas total.

## 3. Software Implementation Details
Seluruh program ditulis dalam **Assembly (.S)** dengan implementasi modul sebagai berikut:
- **I2C Driver:** Implementasi manual untuk inisialisasi, pengiriman data, dan perintah ke OLED 128x64 dengan memanipulasi register `TWCR`, `TWDR`, dan `TWSR`.
- **Real-Time Interrupt:** Menggunakan ISR untuk menangani pulse dari Rotary Encoder agar tidak ada input yang terlewat saat CPU sedang merender tampilan di layar.
- **State Machine:** Logika game dibagi menjadi state `IDLE`, `STRIKE`, `FIGHT`, dan `RESULT` untuk menjaga alur program tetap terstruktur di level register.
- **PWM Control:** Mengonfigurasi register Timer/Counter untuk mengatur kecepatan motor secara dinamis sesuai dengan "kekuatan" ikan yang sedang dipancing.

## 4. Test Results and Performance Evaluation
**Test Results:**
- **Fungsionalitas:**
- **Efisiensi:** 
- **Stabilitas:**

**Performance Evaluation:**


## 5. Conclusion and Future Work
**Conclusion:**

**Future Work:**
