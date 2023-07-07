#![no_main]
#![no_std]

use core::arch::global_asm;

mod panic_wait;

// Assembly counterpart to this file.
global_asm!(include_str!("boot.s"));
