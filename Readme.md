
the [emmulator](https://cpulator.01xz.net/?sys=arm-de1soc)

typing Hello using a loop and uart
```
.equ uart, 0xff201000
.equ enddata, 0x00000000

.global _start
_start:
	b write
	
write:
	ldr r0,=uart
	ldr r3,=enddata
	ldr r1,=text
	b loop

loop:
	ldr r2,[r1],#4  // post-increment by #4 (one memory location)
	cmp r2, r3
	beq exit
	str r2,[r0]
	bal loop
	
exit:
	b .
	
.data
text:
	.word 0x48,0x65,0x6c,0x6c,0x6f
```