;map_x:	ds 2  ;pixels
;map_y:	ds 2  ;pixels

map_width: ds 2
map_height: ds 2


map_meta_x: ds 2 ;  = map_x /32
map_meta_y: ds 2 ; map_y /32


map_meta_width:	ds 2
map_meta_height ds 2

; top layer is the 4 * 4 mega tiles



test_y:
	ret
	ld de,0000
.lp1:	ld (map_y),de

	push de
	call mapYtoTilemapY
	pop de
	add de,8
	jr .lp1


mapYtoTilemapY:
	ld de,(map_y)
	ld b,3	; / divide by 8
	bsrl de,b

	ld h,d
	ld l,e
	ld c,29

HL_Div_C:
;Inputs:
;     HL is the numerator
;     C is the denominator
;Outputs:
;     A is the remainder
;     B is 0
;     C is not changed
;     DE is not changed
;     HL is the quotient
;
       ld b,16
       xor a
.outer:         add hl,hl
         rla
         cp c
         jr c,.skip
           inc l
           sub c
.skip:     djnz .outer
       ret





; return hl as offet into the map ( relative to start if the mata tile map)
get_meta_tile:
	ld a, (map_meta_width)
	ld de,(map_meta_y)
	ld l, e			; save e for later
	ld e, a
	mul			;de = HI(map_meta_x) * map_meta_width
	ld h,d			;only need top byte
	ld d,l
	ld e, a
	mul
	ld a,h
	add a,d
	ld d,a
	ld hl,(map_meta_x)
	add hl,de
	ret

map_x_lo equ map_x+0
map_y_lo equ map_y+0

get_meta_tile_offset:
	ld a,(map_x_lo)  ; ...XXxxx
	add a,a		 ; ..XXxxx0
	swapnib		 ; xxx0..XX
	and 3		 ; 000000XX	
	ld l,a	; mx = (x/8)&3

	ld a,(map_y_lo)	; ...YYyyy
	sra a		; y...YYyy
	and %1100	; 0000YY00

	add a,l		; X+Y = 0000YYXX
	ret
	
