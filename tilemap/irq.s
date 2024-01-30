   OPT Z80
    OPT ZXNEXTREG  

   org $8000
IM_2_Table:
	dw vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl
	dw vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl
	dw vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl
	dw vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl
	dw vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl
	dw vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl
	dw vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl
	dw vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl,vbl
	dw vbl

init_vbl:
	di
	call GetMaxScanline
	inc hl
	inc hl
	ld a,(hl)
	;    ld a, 31    
	nextreg $23,a
	inc hl
	ld a, %110
	or (hl)
	;    or 1

	nextreg $22,a
	im 2
	ld a, IM_2_Table>>8
	ld i,a
	ei
	ret

irq_counter: db 0
irq_last_count: db 0

wait_vbl:
	halt
	ld a,(irq_counter)
	ld (irq_last_count),a
	ld a,0
	ld (irq_counter),a
	ret
        org $8181
vbl:
	di
	push hl
	push af

	ld a,6
	out ($fe),a

	ld hl,irq_counter
	inc (hl)

	ld a,5
	out ($fe),a

	pop af
	pop hl
	ei
	ret

