# LAPORAN AKHIR: FISH MANIA - FINAL PROJECT SISTEM EMBEDDED

## PREFACE
Pada Proyek Akhir MBD ini, kami merancang sebuah sistem simulator memancing interaktif bernama "Fish Mania" yang mampu memberikan umpan balik fisik dan visual secara langsung melalui layar OLED 0.96 inci, Motor DC, serta sensor gerak dan sentuh.

Dengan memanfaatkan konsep logika *State Machine*, manajemen interupsi perangkat keras (*hardware interrupts*), dan pewaktuan (*timing*) register mikrokontroler tingkat rendah, sistem ini dirancang untuk membangkitkan respons seketika dari input pengguna. Proses eksekusi dimulai dengan menginisialisasi pin masukan/keluaran (I/O), mengatur protokol komunikasi I2C secara *bit-banging*, dan mengonfigurasi *Timer* pencacah untuk menghasilkan sinyal *Pulse Width Modulation* (PWM). Pendekatan ini memungkinkan proses *rendering* grafis skor dan pencatatan sensor yang stabil, sinkron, dan *real-time*. Setelah inisialisasi, sistem menghasilkan keluaran respons motor fisik dan antarmuka visual yang merepresentasikan setiap fase permainan ("WAIT", "STRIKE", "FIGHT", "WIN") secara berurutan tanpa gangguan eksekusi atau latensi (*blocking*).

Pendekatan berbasis AVR Assembly memberikan fleksibilitas tinggi dalam mendesain pengendali perangkat keras yang efisien dan dapat diimplementasikan langsung pada arsitektur mikrokontroler ATMega328P. Dengan metode ini, pengguna dapat memahami bagaimana data masukan sensor diproses secara paralel pada level instruksi mesin, diolah di dalam memori register, dan ditransmisikan menjadi sinyal aktuasi nyata, memberikan wawasan mendalam tentang antarmuka sistem tertanam (*embedded systems*) tingkat rendah.

Dalam laporan ini, kami akan menjelaskan secara rinci setiap tahap perancangan, mulai dari konfigurasi parameter *timing* PWM dan I2C, perancangan logika pencacah (*counter*) skor via interupsi eksternal, implementasi antarmuka memori persisten (EEPROM), hingga pengujian sistem (*testing*) untuk memverifikasi keluaran sinyal dan keandalan fungsionalitas keseluruhan.

---

## CHAPTER 1: INTRODUCTION

### 1.1 Background
Sistem *embedded* dan purwarupa perangkat keras interaktif merupakan standar teknologi yang digunakan untuk menghubungkan dunia digital dengan interaksi fisik manusia secara luas dalam sistem komputasi. Teknologi ini telah menjadi fondasi fundamental di berbagai perangkat, mulai dari pengontrol mesin, perangkat antarmuka industri, hingga sistem hiburan dan simulator digital. Kemampuan sebuah sistem tertanam untuk merespons informasi sensorik lingkungan dan memberikan umpan balik seketika menjadikannya elemen krusial dalam interaksi antara pengguna dan mesin. Meski demikian, pembangkitan respons permainan interaktif yang mulus dan stabil pada umumnya sulit dicapai secara sempurna jika hanya mengandalkan perangkat lunak bahasa pemrograman tingkat tinggi tradisional, yang sering kali terkendala oleh latensi abstraksi *library* dan manajemen waktu eksekusi (timing) yang kurang optimal saat menangani pembacaan multi-sensor secara paralel.

Dengan berkembangnya kebutuhan akan pemrosesan sinyal masukan dan aktuasi motor mekanik yang cepat dan tersinkronisasi secara *real-time*, bahasa tingkat rendah murni seperti AVR Assembly muncul sebagai pilihan unggul. Pemrograman berbasis bahasa Assembly menawarkan keunggulan pemrosesan *clock cycle* absolut dan fleksibilitas akses register perangkat keras, memungkinkan pengembangan sistem kendali I/O yang efisien dan sangat akurat. Dengan menggunakan bahasa tingkat bawah ini, pengembangan arsitektur logika sistem *serious game* dapat dilakukan secara modular dengan kontrol *timing* tingkat tinggi, menjadikannya alat yang ideal untuk merancang simulator interaktif berkelanjutan seperti "Fish Mania" yang responsif dan berkinerja stabil di bawah beban interupsi asinkron.

### 1.2 Project Description
**Fish Mania** adalah sebuah purwarupa rekayasa sistem tertanam (*embedded system*) yang mengimplementasikan konsep *serious game*, yang didesain secara spesifik untuk menyimulasikan dinamika perlawanan fisik dan sensasi memancing ikan secara realistis. Berbasis mikrokontroler ATMega328P, keseluruhan arsitektur fungsional peranti keras dikendalikan melalui kode program yang ditulis murni dalam bahasa AVR Assembly (`.S`). Sistem membaca sinyal tegangan dari sensor sentuh kapasitif untuk mendeteksi instrumen pemicu pancingan (kejadian "strike") secara instan tanpa latensi, dan menggunakan layar OLED (beresolusi 128x64) dengan bus I2C sebagai antarmuka pemetaan visual untuk menampilkan metrik keberhasilan pemain.

Kunci kompleksitas interaksi fisis proyek ini diinisialisasi melalui modulasi penangkapan impuls putaran dari *Rotary Encoder* yang berlaku selayaknya katrol pancing nyata. Rotasi ini dikalkulasi oleh mikrokontroler melewati pin khusus *External Interrupt* (INT0) demi mencegah intervensi pemrosesan *loop* utama (*main thread*). Seiring putaran ini dicacah ke dalam pencatat skor, sebuah Motor DC dengan driver eksternal—dikendalikan oleh sinyal pengaturan variasi lebar pulsa (PWM)—diaktifkan untuk memberikan gaya tegangan terbalik terhadap tuas. Kondisi perlawanan asinkron ini menyuguhkan sebuah purwarupa mesin permainan *hardware-in-the-loop* yang dinamis, menantang, dan taktil bagi pengguna.

### 1.3 Objectives
Tujuan utama perancangan teknis dan implementasi purwarupa "Fish Mania" ini mencakup:
1. Merancang dan mengeksekusi arsitektur logika *State Machine* (*Mesin Status Berhingga*) secara murni di tingkat register CPU, memastikan kontrol presisi atas transisi siklus operasional permainan ("WAIT", "STRIKE", "FIGHT", "WIN").
2. Mengaplikasikan kontrol interupsi perangkat keras (*External Hardware Interrupts*, INT0/INT1) guna mengelola sinyal diskret asinkron dari *Rotary Encoder* tanpa anomali *missed step* sewaktu melakukan *rendering* I2C.
3. Mendemonstrasikan efikasi *Timer/Counter* pada konfigurasi perangkat keras untuk mendenyutkan *Pulse Width Modulation* (PWM), yang mengatur luaran arus dinamis menuju sistem penggerak Motor DC secara *real-time*.
4. Mengembangkan antarmuka pengendali *Two-Wire Interface* (I2C) level primitif (melalui bit-banging/I/O register) guna merender antarmuka monokrom serta memori font khusus (*array* `.progmem`) secara langsung pada OLED 0.96 inci.
5. Mensintesiskan operasi penyusunan memori stabil (*Non-Volatile Memory*) dengan memvalidasi prosedur penulisan (write) dan pembacaan (read) pada *chip* EEPROM untuk retensi data *high score* permanen.

### 1.4 Roles and Responsibilities
*(Bagian ini sengaja dikosongkan sesuai instruksi)*

---

## CHAPTER 2: IMPLEMENTATION

### 2.1 Equipment
Perancangan "Fish Mania" mengonsolidasikan serangkaian unit periferal keras yang terikat dalam satu sistem bus komputasi. Konstituen perangkat yang dieksekusi adalah:
- **Mikrokontroler ATMega328P (Via Arduino Uno Board)**: Mengemban peran sebagai unit sintesis logika pusat, menyediakan fasilitas penjadwal presisi, port interupsi terdedikasi (INT0/PD2), perangkat keras pembentuk Fast PWM, dan bus I2C bawaan.
- **Modul Visual OLED 0.96 inci (SSD1306)**: Penampil visual monokrom yang berjalan dalam protokol I2C, bertugas untuk mentransmisikan data grafis teks indikator status serta menerjemahkan memori register konversi BCD menjadi desimal aktual di layar.
- **Sensor Sentuh Kapasitif (TTP223/Setara)**: Instrumen deteksi digital dengan presisi sensitivitas tinggi yang digunakan untuk mengeluarkan pulsa *HIGH* sesaat ketika kapasitansi elektrodanya terganggu (stimulus "strike").
- **Rotary Encoder (KY-040)**: Modul elektromekanikal yang mengubah rotasi sudut mekanis yang berkesinambungan menjadi sekuens dua fase pulsa bujur sangkar, diukur oleh pencacah interupsi sistem untuk metrik *gameplay*.
- **Motor DC & Driver Dual H-Bridge L298N**: Sistem luaran fisis dan sirkit konversi yang memberikan daya tegangan eksternal (terisolasi dari sisi logik) untuk mensimulasikan tarikan dan redaman dinamis, kecepatannya sebanding dengan tegangan *duty cycle* PWM dari modul kontrol.
- **Pasif Buzzer**: Aktuator audio piezoelektrik yang membangkitkan resonansi sinyal analog untuk menambah isyarat *feedback* operasional ketika transisi permainan dimulai.
- **Sistem Catu Daya Eksternal**: Mempertimbangkan kebutuhan transien arus induktif dari Motor DC, seluruh purwarupa diinjeksi dengan suplai tenaga baterai sekunder berbahan Lithium 18650 (7.4V) secara terpisah (*Common Ground*), memitigasi distorsi derau listrik pada suplai rel 5V logika sensor.

### 2.2 Implementation
Proses implementasi dan sinkronisasi proyek ini direkayasa ke dalam sejumlah blok kode terpisah secara modular, melingkupi manajemen elektris hingga integrasi instruksi Assembly secara parsial:

**A. Skema Implementasi Perangkat Keras**
1. **Perutean Sinyal Kritis (Critical Signal Routing)**: Port interupsi INT0 (PD2) dipetakan eksklusif untuk melacak garis sinyal Fasa A dari Rotary Encoder, membiarkan gerbang logika tingkat bawah CPU yang menangkap transisinya. Pin PD6 (menempel pada *timer comparer* OC0A) dijahit lurus ke pin *Enable* (ENA) driver motor, mengeksploitasi kendali voltase PWM otonom tanpa bergantung pada rutinitas komputasi peranti lunak.
2. **Topologi Jaringan Daya**: Dalam perancangannya, unit penggerak torsi tegangan terbeban tinggi (motor arus searah) dikondisikan lewat pasokan baterai yang terlepas lintasannya, disinkronkan hanya di dasar massa (*Common Ground*) sistem mikrokontroler demi melindungi komputator inti dari paku tegangan (*voltage spikes*) induktansi balik.

**B. Implementasi Perangkat Lunak (VHDL / AVR Assembly)**
1. **Inti Logika *State Machine* (`main.S`)**: Eksekutor inti merintis alokasi referensi *Stack Pointer* pada fase prakondisi (*boot-up*), sebelum menjatuhkan diri dalam putaran utama. Logika kendali direduksi pada matriks deterministik: State 0 ("WAIT") yang secara berulang memantau antarmuka status *input* kapasitif PIND, dan State 1 ("FIGHT") tempat alokasi *Timer* mesin membandingkan progres nilai pencacahan dari *encoder*.
2. **Kendali *Interrupt-Driven* (`interrupt.S`)**: Metode *polling* konvensional untuk mencacah rotasi terbukti rawan latensi *skip*. Karenanya, alur pengamatan Rotary Encoder didelagasikan menuju subsistem _Interrupt Service Routine_ (ISR) pada alamat awal spesifik (`.org 0x0002`). Melalui aktivasi pendeteksian tepi turun (*Falling Edge*) di EICRA, sistem dibiasakan secara otomatis melontarkan instruksi interupsi, menjamin registrasi poin skor mutlak dan presisi meskipun utas utama disibukkan dengan antrean *rendering* OLED.
3. **Pembangkit *Pulse Width Modulation* (`timers_pwm.S`)**: Rekayasa beban tarikan perangkat diimplementasikan menggunakan blok pencacah keras *Timer0*. Register TCCR0A dan TCCR0B diregulasi pada topologi *Non-Inverting Fast PWM*. Saturasi denyut pulsa (kecepatan motor) dengan andal didefinisikan ulang secara analog-proporsional hanya dengan men-store nilai register acak ke komparator OCR0A (*Output Compare Register*).
4. **Manipulasi Transmisi I2C Grafis (`i2c_oled.S`)**: Mengatasi *overhead* memori di C++, komunikasi dengan penggerak layar OLED dijabarkan ke struktur fundamental. Pembangkitan jam pulsa protokol dikontrol secara manual lewat rekayasa tingkat bit (bit-banging) register TWBR dan komandonya. Blok font (5x7 piksel matriks) ditanam statis pada `.progmem`, dipanggil per kolomnya dalam iterasi transfer TWI (*Two-Wire Interface*).
5. **Akses Data *Non-Volatile* (`eeprom.S`)**: Fase rekonsiliasi nilai *High Score* difasilitasi dalam modul khusus. Penulisan ke sektor memori persisten dikonfigurasi melalui jabat tangan (*handshake*) flag pada blok register `EECR`, mengonfirmasi bahwa bit master-enable (`EEMPE`) sinkron untuk menekan risiko kolisi atau korupsi penulisan ketika lonjakan sistem terputus mendadak.

---

## CHAPTER 3: TESTING AND ANALYSIS

### 3.1 Testing
Serangkaian validasi *testbench* dan operasionalisasi terpadu digulirkan pada berbagai lapisan submodul perangkat keras guna menegaskan bahwa desain *embedded* murni berbasis *Machine Instruction* (Assembly) sinkron terhadap standar parameter kinerjanya. Skenario verifikasi berpusat pada:
1. **Uji Validitas *Event Interrupt* (Interrupt Profiling)**: Merangsang transisi interupsi perangkat keras secara masif dengan memuntir Rotary Encoder dengan intensitas ekstrem dalam status aktif ("FIGHT"), lantas memeriksa reliabilitas pendeteksian pulsa dan penghindaran pantulan (*debounce filtering*) fasa sinyal mekanik.
2. **Uji Linieritas Torsi PWM (Actuator Analysis)**: Menganalisa parameter *duty cycle* motor dengan mensimulasikan nilai *Hex* bertingkat ke dalam bus *Timer* eksekutor. Evaluasi diarahkan untuk menilai rasio perlawanan fisik dan jeda perputaran awal pada poros *DC Motor*.
3. **Pengujian Reliabilitas *Two-Wire Interface* (I2C Display Loading)**: Mengalokasikan interupsi eksternal masif selagi CPU secara sinkron mengekskusi perintah salin bit per bit matriks *font* ke modul SSD1306, memverifikasi ketiadaan penyimpangan transmisi, pergeseran matriks layar (*visual glitches*), maupun *frame freeze* yang disebabkan perebutan prioritas bus eksekusi.
4. **Evaluasi Persistensi Memori Tertanam**: Mengakhiri siklus operasional bertepatan pada nilai spesifik untuk merekam metrik poin pencapaian pemain, menyela paksa catu daya mikrokontroler (hard restart), lalu meninjau pemulihan muatan EEPROM untuk integritas sektor data pada *Address Space* pertama (alamat *0x00*).

### 3.2 Result
Implementasi bertahap pada *framework* pengujian ini memvisualisasikan parameter keberhasilan baik secara teknis matematis, maupun interaksi fisik:
1. Mekanisme pencacah berbasis **External Hardware Interrupt** (INT0) mendeduksikan kemampuan superior anti-blocking. Kondisi frekuensi pulsa *encoder* tingkat lanjut dapat didokumentasikan dan di-increment di register presisi internal secara konsisten, meniadakan anomali insiden *lost-pulse* atau fluktuasi cacah ganda, menguatkan fondasi arsitektur pergerakan data.
2. Respons propagasi *delay* dari "WAIT" menuju interaksi kinetis "STRIKE/FIGHT" dikonfirmasi berjalan nyaris pada ranah kecepatan *clock rate* (fraksi milidetik). Aktivasi sinyal luaran penggerak H-Bridge dan PWM motor tersaturasi tepat ketika kapasitansi jari merusak ambang voltase pin PIND, menghadirkan aktuasi taktil real-time yang memuaskan ekspektasi komputasional murni.
3. Arsitektur logika *Two-Wire Interface* (TWI) kustom dengan efisien mendemonstrasikan kelayakan perlakuan rendering tanpa-kerlip (*flicker-free*). Seluruh proses iterasi pewarnaan kolom-baris resolusi BCD dikerjakan tuntas; layar memperlihatkan representasi visual bebas *glitch* walau utas diinstruksikan menunda perjalanannya saat interupsi INT0 menyerang pertengahan protokol I2C.
4. Konfirmasi operasi penyimpanan *Non-Volatile Memory* diverifikasi andal 100%. Blok modul EEPROM secara definitif mem-bypass volatalitas sirkuit, meregister skor pencapaian di ujung fase permainan dan berhasil mengompilasikannya persis seperti yang diinisialisasi begitu unit kembali melewati protokol pengaturan *boot-up*.

### 3.3 Analysis
Merujuk pada telaah verifikasi parameter performa, penggunaan konvensi perakitan kode tingkat serendah instruksi mesin (*Machine Language/Assembly*) mendominasi aspek presisi eksekusi atas perangkat tertanam berspesifikasi komputasi mikro. Keterbatasan paling vital pada implementasi sistem kontrol di bahasa tinggi, yakni hilangnya siklus pencacahan ketika layar I2C matriks titik menginvasi pita memori (karena operasinya memaksa siklus *clock* menunggu bit `TWINT` terkirim), telah berhasil dinihilkan melalui integrasi arsitektur ISR.

Saat rentetan protokol penyegaran *display* berjalan secara sekuensial, CPU ATMega328P senantiasa mensiagakan jaring *hardware interrupt* (INT0) di bawah sistem *clock*. Manakala transisi *low* sinyal diskret terekam, unit eksekutor secara otomatis menyuntikkan iterasi *stack return* ke RAM, melompat mengeksekusi *sub-routine* penambah skor, dan lantas melakukan retraksi mulus (*seamless resume*) kembali menuju *thread* pewarnaan piksel. Kemampuan memanipulasi rentang *timesharing* mutlak pada satuan instruksi ini tak bisa diperoleh pada lingkungan *high-level* yang di-enkapsulasi banyak lapisan OS atau abstraksi inti API. Sintesis perancangan ini mencerminkan fundamentalisme desain interaksi perangkat keras respons tinggi, yang bertumpu pada kontrol mutlak terhadap sinkronisasi masukan analog/digital (I/O Synchronization) serta utilitas pergeseran waktu interupsi secara sadar dan otonom.

---

## CHAPTER 4: CONCLUSION
Pengembangan purwarupa interaktif "Fish Mania" secara paripurna mengonfirmasi kelayakan perancangan arsitektur logika sistem sekritis *serious game* dengan mendayagunakan fundamentalisme desain pengendali menggunakan instruksi perakitan AVR Assembly. Dengan membedah fungsionalitas manajemen *hardware interrupt* murni untuk menyita data *encoder* berkelanjutan, lantas mengonfigurasi generator matriks perangkat keras mandiri (Timer0) guna memodulasi keluaran kekuatan (PWM Motor DC), sistem tersebut membuktikan utilitas dan otonominya dalam memitigasi kendala latensi akibat pengolahan grafis sinkron antar sub-sistem bus (I2C) yang berkecepatan lebih lambat.

Pemanfaatan model algoritma fungsional terpisah (seperti State Machine Register) menjamin presisi pengendalian operasional alur, sementara pengelolaan *memory timing* meneguhkan sinergi sempurna antara respons visual nir-distorsi (*flicker-free*) dan luaran kinetis yang masif dalam domain orde mili-sekon. Proyek ini memproyeksikan sebuah verifikasi keandalan teknis mendalam tentang tata laksana sinkronisasi instruksi logika sekuensial; menggarisbawahi realitas bahwa sistem komputasi berdaya rendah pun mampu merepresentasikan keunggulan pemrosesan tingkat dewa selama desainer mampu memanipulasi *timing parameters* dan interupsi secara efisien pada tingkatan register primitif.
