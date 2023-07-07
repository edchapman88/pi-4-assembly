.global _start

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

    mrs x1,mpidr_el1
    and x1,x1, #3
    cbz x1,2f

// We're not on the main core, so hang in an infinite wait loop
1:
    wfe
    b 1b

// We're on the main core!
// Set stack to start below our code
2:
    // load _start pointer into x1
    // load data in memory pointed to by _start into sp (stack pointer)
    ldr x1,=_start
    mov sp,x1