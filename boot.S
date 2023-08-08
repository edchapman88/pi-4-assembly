.section ".text.boot"  // Make sure the linker puts this at the start of the kernel image

.global _start  // Execution starts here

.equ AUX_BASE,0xFE215000

// ((AUX_UART_CLOCK/(baud*8))-1) = 541
// where, baud = 115200
// AUX_UART_CLOCK = 500000000
.equ BAUD_RATE, 0x21D

.equ GPPUPPDN0, 0xFE2000E4
.equ GPPUPPDN0_SETTING, 0x0FFFFFFF

.equ GPFSEL1, 0xFE200004
.equ GPFSEL1_SETTING,0xFFFF8FFF 

_start:
    // Check processor ID is zero (executing on main core), else hang
    mrs     x1, mpidr_el1
    and     x1, x1, #3
    cbz     x1, 2f
    // We're not on the main core, so hang in an infinite wait loop
1:  wfe
    b       1b
2:  // We're on the main core!

    // Set stack to start below our code
    ldr     x1, =_start
    mov     sp, x1

    // Clean the BSS section
    ldr     x1, =__bss_start     // Start address
    ldr     w2, =__bss_size      // Size of the section
3:  cbz     w2, 4f               // Quit loop if zero
    str     xzr, [x1], #8
    sub     w2, w2, #1
    cbnz    w2, 3b               // Loop if non-zero

    // Jump to our main() routine in C (make sure it doesn't return)
4:  
    // enable uart
    ldr x0,=AUX_BASE
    add x0,x0,#0x4 // aux enable is offset 0x04 from aux base
    mov w1,#1
    str w1,[x0]

    // set baud rate
    ldr x0,=AUX_BASE
    add x0,x0,#0x68 // baud rate is offset 0x68 from aux base
    ldr x1,=BAUD_RATE
    str x1,[x0]

    // set GPIO 14 and 15 to float
    // 14 -> bits 29:28 on GPPUPPDN0
    // 15 -> bits 31:30 on GPPUPPDN0
    //     00 = No resistor is selected
    //     01 = Pull up resistor is selected
    //     10 = Pull down resistor is selected
    //     11 = Reserved
    
    // first read GPPUPPDN0 to get current setting
    ldr x0,=GPPUPPDN0
    ldr w2,=GPPUPPDN0_SETTING   // 0x0FFFFFFF
    ldr w1,[x0]
    and w1,w1,w2 // force leftmost 4 bits (28:31) of a half register to be 0
    str w1,[x0]


    // set GPIO function of pins 14 and 15 to function5 (TX, RX)
    // 14 -> bits 14:12 on GPFSEL1
    // 15 -> bits 17:15 on GPFSEL1
    //     010 = alternative function 5
    // first read GPFSEL1 and set low 17:12
    ldr x0,=GPFSEL1
    mov w1,#0x3F    // 111111
    lsl w1,w1,#12
    neg w1,w1   // created mask to AND with current val of GPFSEL1
    ldr w2,[x0]
    and w2,w2,w1    // w2 has GPFSEL1 with 17:12 set low

    mov w3,#0x12   // 17:12 need to be 010010 (=0x12)
    lsl w3,w3,#12
    orr w2,w2,w3    // OR mask with correctly set 17:12
    str w2,[x0]

    // enable tx,rx
    ldr x0,=AUX_BASE
    add x0,x0,#0x60
    mov w1,#3
    str w1,[x0]

    bl      main
    // In case it does return, halt the master core too
    b       1b