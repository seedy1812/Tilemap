
	opt	sna=start:StackStart

    OPT Z80
    OPT ZXNEXTREG    

    org $8000

StackEnd:
	ds	128
StackStart:

start:
    ld sp , StackStart
go:
    call setup_interrupt
 
frame_loop:
    call wait_vbl

  ;  call setup_interrupt

 ;   ld      a,$5
 ;   out     ($fe),a

    ld b,0
loopppp:
    nop
    djnz loopppp

 ;   ld      a,$7
 ;   out     ($fe),a

    jr frame_loop

setup_interrupt:
    nextreg $22,%110
    nextreg $23,191
    call init_vbl
    ret


include "irq.s"