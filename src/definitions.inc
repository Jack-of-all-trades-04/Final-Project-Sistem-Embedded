; I2C OLED (A4, A5)
.equ SDA_PIN, 4
.equ SCL_PIN, 5

; Rotary Encoder
.equ ENC_A, 2
.equ ENC_B, 3

; Capacitive Touch Sensor
.equ TOUCH_PIN, 4

; Motor Driver L298N
.equ MOTOR_PWM, 6
.equ MOTOR_DIR,  7

; Buzzer Passive
.equ BUZZER_PIN, 5

; --- REGISTER ALIASING ---
#define temp      r16
#define argument  r17
#define state     r18
#define score     r19
#define last_enc  r21 