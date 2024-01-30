
M_GETSETDRV  equ $89
F_OPEN       equ $9a
F_CLOSE      equ $9b
F_READ       equ $9d
F_WRITE      equ $9e
F_SEEK       equ $9f

FA_READ      equ $01
FA_APPEND    equ $06
FA_OVERWRITE equ $0C

load_page: ds 1
file_handle: ds 1

DefaultDrive: db 1

; a= 8 k page
; de = filename
load_file
	ld (load_page),a

	push ix

	xor	a	; set drive. 0 is default
	rst	$08
	db	$89
	ld	(DefaultDrive),a

;	ld a,'*'
	ld b,FA_READ
	push de
	pop ix
	rst	$08
	db	F_OPEN
	jr c,load_error
	or a
	jr z,load_error
	ld (file_handle),a

load_loop:
	ld hl,load_page
	ld a,(hl)
	nextreg $57,a
	inc (hl)
load_address: equ *+2
	ld ix,$e000
	ld bc,$2000
	ld a,(file_handle)
	rst	$08
	db	F_READ
	jr c,load_error
	ld a,$20
	sub b
	or c
	jr z,load_loop

	ld a,(file_handle)
	rst	$08
	db	F_CLOSE

	and a
	pop ix
	ret
load_error:
	scf
	pop ix
	ret
