
	DMA_PORT    equ $6b ;//: zxnDMA

	TILE_GRAPHICS       equ $4000
	TILE_MAP            equ $7600

	DIGIT_0		equ 100

	OPT Z80
	OPT ZXNEXTREG    

    seg     CODE_SEG, 4:$0000,$8000
    seg     STNICC_SEG, $30:$0000,$0000 
    

    seg     CODE_SEG

	include "irq.s"

	org $8200                    ; Start of application
StackEnd:
	ds	128
StackStart:
	ds  2

start:

;; set the stack pointer
	ld sp , StackStart

; first page to load stuff
	ld a,(mem_init_page)

; load top layer map
	ld (load_page),a

// set the address to load the file
;    ld de,$e000
;   ld (load_address),de
; load the 32x32 map layer
;    ld (map_32x32_page),a
;    ld de, map_32x32_name
;    call load_file
;    jr c,error

; move onto next page
;    ld a,(load_page)
;    inc a

; load the 8x8 map meta tiles
;    ld (map_8x8_page),a
;    ld de, map_8x8_name
;    call load_file
;    jr c,error

;    ld a,(load_page)
;    inc a

// now the graphics
;    ld (tiles_8x8_page),a
;    ld de, tiles_8x8_name
;    call load_file
;    jr c,error

;    ld a,(load_page)
;    inc a
; and the palette
	ld (palette_page),a
	ld de, palette_name
	call load_file
	jr c,error

// set the address to load the status bar map 
// same page but after the palette ( 256 *2 = 16 bit values)
	ld de,$e000 + 256*2
	ld (load_address),de

	ld a,(palette_page)
	ld (load_page),a

	ld de, map_statusbar_name
	call load_file
	jr c,error


// load the status bar graphics into next page
	ld a,(load_page)
	inc a

// now the graphics
	ld de,$e000
	ld (load_address),de

	ld (map_statusbar_tile_page),a
	ld (load_page),a
	ld de, map_statusbar_tile
	call load_file
	jr c,error


	jr go
error:   
	xor 7
	and 7
	out($fe),a
	jr error    
go: 
	nextreg 7,%10 ;/ 14mhz
	call video_setup
	call dummy_setup

	call test_y
	
	call copy_status_map
	call copy_status_tiles_4bpp
	call copy_palette_8bp
	call init_vbl
	call copy_num_tiles

	call wait_vbl
frame_loop:
	call read_keyboard
	call StartCopper
	call wait_vbl
	jp frame_loop


copy_status_tiles_4bpp:
	ld a,(map_statusbar_tile_page)  
	nextreg $57,a

	ld de,TILE_GRAPHICS
	ld hl,$e000
	ld bc , 8*576
	ldir
	ret

copy_status_tiles:
	ld a,(map_statusbar_tile_page)  
	nextreg $57,a

	ld de,TILE_GRAPHICS
	ld hl,$e000
	ld bc , 8*576
cst:
	push bc
	ld a,(hl)
	inc hl
	ld b,(hl)
	inc hl
	swapnib
	or b
	ld (de),a
	inc de
	pop bc
	dec bc
	ld a,b
	or c
	jr nz,cst
	ret


copy_status_map:
	ld a,(palette_page)  
	nextreg $57,a

	ld de,TILE_MAP+40*2*(32-3)
	ld hl,$e000 + 256*2 +8;// status bar tiles 
	ld bc , 3*40*2
	ldir
	ret

dummy_setup;

	ld hl, TILE_MAP

	ld a,0
	ld c,0
	ld b, 40
lp1:
	ld (hl),a
	inc l
	ld (hl),c
	inc hl
	inc a
	djnz lp1

	ld hl, TILE_MAP
	ld de, TILE_MAP+40*2

	ld bc,40*2 *28
	ldir

	ld a, 0
	ld hl, TILE_MAP
	ld b , 32-3
	ld e,DIGIT_0
digits:
	push af
	swapnib
	ld d,a

	and $f


	push af
	add a,e
	ld (hl),a
	pop af
	inc hl
	ld (hl),c
	inc hl

	xor d
	swapnib
	add a,e
	ld (hl),a
	inc hl
	ld (hl),c
	inc hl

	ld (hl),c
	inc hl
	ld (hl),c
	inc hl


	add  hl, 40*2-4-2

	pop af
	scf
	adc a,c
	daa

	djnz digits
	ret

     
mem_init_page:  db 16
map_32x32_page: db 1
map_32x32_name: db "m32x32.bin",0

map_8x8_page: db 1
map_8x8_name: db "m8x8.bin",0


tiles_8x8_page: db 1
tiles_8x8_name: db "tiles8x8.bin",0
palette_page: db 1
palette_name: db "statusb.8bp",0
map_statusbar_name: db "statusbar.map",0
map_statusbar_tile_page: db 1
map_statusbar_tile db "statusb.raw",0


include "loading.s"
include "video.s"
include "map.s"
copy_num_tiles
	ld de,TILE_GRAPHICS+ 8*4*DIGIT_0
	ld hl,num_tiles
	ld bc , 8*4*10
	ldir
	ret


num_tiles:
	db $00,$00,$00,$00	;'0'
	db $00,$99,$99,$00
	db $09,$00,$09,$90
	db $09,$00,$90,$90
	db $09,$09,$00,$90
	db $09,$90,$00,$90
	db $00,$99,$99,$00
	db $00,$00,$00,$00
	db $00,$00,$00,$00	;'1'
	db $00,$09,$90,$00
	db $00,$90,$90,$00
	db $00,$00,$90,$00
	db $00,$00,$90,$00
	db $00,$00,$90,$00
	db $00,$99,$99,$90
	db $00,$00,$00,$00
	db $00,$00,$00,$00	;'2'
	db $00,$99,$99,$00
	db $09,$00,$00,$90
	db $00,$00,$00,$90
	db $00,$99,$99,$00
	db $09,$00,$00,$00
	db $09,$99,$99,$90
	db $00,$00,$00,$00
	db $00,$00,$00,$00	;'3'
	db $00,$99,$99,$00
	db $09,$00,$00,$90
	db $00,$00,$99,$00
	db $00,$00,$00,$90
	db $09,$00,$00,$90
	db $00,$99,$99,$00
	db $00,$00,$00,$00
	db $00,$00,$00,$00	;'4'
	db $00,$00,$90,$00
	db $00,$09,$90,$00
	db $00,$90,$90,$00
	db $09,$00,$90,$00
	db $09,$99,$99,$90
	db $00,$00,$90,$00
	db $00,$00,$00,$00
	db $00,$00,$00,$00	;'5'
	db $09,$99,$99,$90
	db $09,$00,$00,$00
	db $09,$99,$99,$00
	db $00,$00,$00,$90
	db $09,$00,$00,$90
	db $00,$99,$99,$00
	db $00,$00,$00,$00
	db $00,$00,$00,$00	;'6'
	db $00,$99,$99,$00
	db $09,$00,$00,$00
	db $09,$99,$99,$00
	db $09,$00,$00,$90
	db $09,$00,$00,$90
	db $00,$99,$99,$00
	db $00,$00,$00,$00
	db $00,$00,$00,$00	;'7'
	db $09,$99,$99,$90
	db $00,$00,$00,$90
	db $00,$00,$09,$00
	db $00,$00,$90,$00
	db $00,$09,$00,$00
	db $00,$09,$00,$00
	db $00,$00,$00,$00
	db $00,$00,$00,$00	;'8'
	db $00,$99,$99,$00
	db $09,$00,$00,$90
	db $00,$99,$99,$00
	db $09,$00,$00,$90
	db $09,$00,$00,$90
	db $00,$99,$99,$00
	db $00,$00,$00,$00
	db $00,$00,$00,$00	;'9'
	db $00,$99,$99,$00
	db $09,$00,$00,$90
	db $09,$00,$00,$90
	db $00,$99,$99,$90
	db $00,$00,$00,$90
	db $00,$99,$99,$00
	db $00,$00,$00,$00

read_keyboard:
	ld a,(is_pressed)
	ld (was_pressed),a
	
	LD A, $f7
	IN A, ($FE)
	ld d,a
	ld (is_pressed),a

	BIT 0, d
	jr nz,.not_1

	ld hl,(map_x)
	dec hl
	ld a,h
	cp $ff
	jr nz ,.not_xminus
	add hl,320
.not_xminus:
	ld (map_x),hl
.not_1:	bit 1,d
	jr nz,.not_2

	ld hl,(map_x)
	inc hl
	ld a,h
	cp $1
	jr nz ,.not_xplus
	ld a,l
	cp 320-256
	jr nz ,.not_xplus
	ld l,0
	ld h,l
.not_xplus:
	ld (map_x),hl
.not_2:	bit 2,d
	jr nz,.not_3
	ld hl,map_y
	ld a,(hl)
	inc a
	cp 256-24
	jr nz,.no_wrap_x
	ld a,0
.no_wrap_x:
	ld (hl),a
.not_3:	bit 3,d
	jr nz,.not_4

	ld hl,map_y
	ld a,(hl)
	or a
	jr nz,.no_wrap_y
	add 256-24
.no_wrap_y:
	dec a
	ld (hl),a
	ret

.not_4:	
	bit 4,d
	jr nz,.not_5

	ld a,(was_pressed)
	xor d

	bit 4,a
	jr z,.not_5

	ld a,(copper_active)
	xor $ff
	ld (copper_active),a

.not_5:	ret

map_y:	db 0
map_x:	db 0,0


was_pressed: db 0
is_pressed: db 0

copper_active: db 0

 	savenex "player.nex",start

