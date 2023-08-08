
.section ".text.boot"  // Make sure the linker puts this at the start of the kernel image

.global _start  // Execution starts here

.equ BASE, 0xFE000000
.equ AUX_BASE, 0xFE215000
.equ UART, 0xFE215040

// ((AUX_UART_CLOCK/(baud*8))-1) = 541
// where, baud = 115200
// AUX_UART_CLOCK = 500000000
.equ BAUD_RATE, 0x21D

.equ GPFSEL1, 0xFE200004    
.equ GPFSEL1_SETTING,0x0FFD2FFF 
.equ GPPUPPDN0, 0xFE2000E4
.equ GPPUPPDN0_SETTING, 0x0FFFFFFF

.equ GPSET0, 0xFE20001C
.equ GPCLR0, 0xFE200028

_start:
    // check processor ID is 0 (main core), else hang

    // mpidr_el1 is Multiprocessor Affinity Register:
    // The processor and cluster IDs, in multi-core or cluster systems.

    // mrs = move from PSR (program status register eg. CPRS) to register

    // Except that it does not change the condition code flags,
    // CBZ Rn, label
    // is equivalent to:
    // CMP     Rn, #0
    // BEQ     label

    

    // 2f instructs to jump forard to label 2
    // 1b instructs to jump back to label 1

    // cbz     x1, 2f
    // mpidr_el1 = 0, so it's the main core
    // mpidr_el1 = 1 would be the cluster

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


4:
    // set GPIO 14 and 15 to float
    // 14 -> bits 29:28 on GPPUPPDN0
    // 15 -> bits 31:30 on GPPUPPDN0
    //     00 = No resistor is selected
    //     01 = Pull up resistor is selected
    //     10 = Pull down resistor is selected
    //     11 = Reserved
    
    // first read GPPUPPDN0 to get current setting
    ldr x0,=GPPUPPDN0
    LDR x3,=GPPUPPDN0_SETTING   // 0x0FFFFFFF
    ldr x1,[x0]
    and x1,x1,x3 // force leftmost 4 bits (28:31) to be 0
    str x1,[x0]


    // set GPIO function of pins 14 and 15 to function5 (TX, RX)
    // 14 -> bits 14:12 on GPFSEL1
    // 15 -> bits 17:15 on GPFSEL1
    //     010 = alternative function 5
    ldr x0,=GPFSEL1
    ldr x3,=GPFSEL1_SETTING // 0x0FFD2FFF
    ldr x1,[x0]
    and x1,x1,x3
    // 18:12 must be 11010010 -> D2 where the leading 2 ones are not relevant
    // to pins 14 or 15 but preserve the previous setting via the AND
    str x1,[x0]


    // enable uart
    ldr x0,=AUX_BASE
    add x0,x0,#0x4 // aux enable is offset 0x04 from aux base
    mov x1,#0x1
    str x1,[x0]

    // set baud rate
    ldr x0,=AUX_BASE
    add x0,x0,#0x68 // baud rate is offset 0x68 from aux base
    mov x1,#0x1
    str x1,[x0]

    // disable interupts
    ldr x0,=AUX_BASE
    add x0,x0,#0x48
    mov x1,#0xC6
    str x1,[x0]

    // LCR - Line Control
    ldr x0,=AUX_BASE
    add x0,x0,#0x4c
    mov x1,#3
    str x1,[x0]

    // enable tx,rx
    ldr x0,=AUX_BASE
    add x0,x0,#0x60
    mov x1,#3
    str x1,[x0]

check:
    // wait for ready
    ldr x0,=AUX_BASE
    add x0,x0,#0x54
    and x1,x0,#0x20
    cmp x1,#0x20
    beq ready
    b check

ready:
    // write to IO
    ldr x0,=UART
    mov x1,#0x48
    str x1,[x0]

    b check
