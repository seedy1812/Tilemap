PAL_INDEX       equ $40
PAL_VALUE_8BIT	equ  $41
TILE_X_LO       equ $30
TILE_X_HI       equ $2f
TILE_Y          equ $31

video_setup:

       nextreg $43,%01100000   ; select tilemap 1st palette
       nextreg $40,0           ; palette index

       nextreg $68,%00000000   ;ula disable
       nextreg $6b,%10000011    ; Tilemap Control 512 tiles + above ula
       nextreg $6c,%00000000
       nextreg $6f,HI(TILE_GRAPHICS) ; tile pattern @ $4000
       nextreg $6e,HI(TILE_MAP) ; tilemap @ $7600

       nextreg $1c,%00001000 ; Clip Window control : reset tilemap index

       nextreg $1b,+((0+8)/2) ; Clip Window Tilemap : x1 /2     
       nextreg $1b,+((320-8)/2-1)              ; x2 /2
       nextreg $1b,(8)                          ; y1
       nextreg $1b,(192+32+32-8-1)               ; y2

       nextreg $2f,0           ; Tilemap Offset X MSB ; windows x = 0
       nextreg $30,0           ; Tilemap Offset X LSB

       nextreg $31,0           ; Tilemap Offset Y ;windows y = 0

       nextreg $15,%00000001 ; no low rez , LSU , no sprites , no over border

       ret

 ReadNextReg:
       push bc
       ld bc,$243b
       out (c),a
       inc b
       in a,(c)
       pop bc
       ret


;; Detect current video mode:
;; 0, 1, 2, 3 = HDMI, ZX48, ZX128, Pentagon (all 50Hz), add +4 for 60Hz modes
;; (Pentagon 60Hz is not a valid mode => value 7 shouldn't be returned in A)
DetectMode:
       ld      a,$05 ; PERIPHERAL_1_NR_05
       call    ReadNextReg
       and     $04             ; bit 2 = 50Hz/60Hz configuration
       ld      b,a             ; remember the 50/60 as +0/+4 value in B
       ; read HDMI vs VGA info
       ld      a,$11 ; VIDEO_TIMING_NR_11
       call    ReadNextReg
       inc     a               ; HDMI is value %111 in bits 2-0 -> zero it
       and     $07
       jr      z,.hdmiDetected
       ; if VGA mode, read particular zx48/zx128/pentagon setting
       ld      a,$03
       call    ReadNextReg
       ; a = bits 6-4: %00x zx48, %01x zx128, %100 pentagon
       swapnib
       rra
       inc     a
       and     $03             ; A = 1/2/3 for zx48/zx128/pentagon
.hdmiDetected:
       add     a,b             ; add 50/60Hz value to final result
       ret

VideoScanLines: ; 1st copper ,2nd irq
       dw 312-24 ,312-32                           ; hdmi_50
       dw 312-24 ,312-32                           ; zx48_50
       dw 311-24 ,311-32                           ; zx128_50
       dw 320-24 ,320-32                           ; pentagon_50

       dw 262-24 , 262-32                           ; hdmi_60
       dw 262-24 , 262-32                            ; zx48_60
       dw 261-24 , 261-32                            ; zx128_60
       dw 262-24 , 262-32                            ; pentagon_60

GetMaxScanline:
       call DetectMode:
       ld hl, VideoScanLines
       add a,a
       add a,a
       add hl,a
       ret


copy_palette_8bp:
       ld a,(palette_page)  
       nextreg $57,a
       ld hl, $e000
       ld b,32

       nextreg $43,%00110000 
       nextreg $40, 0
cp_lp_8bp: 
	ld a,(hl)
       	nextreg $41,a
	inc hl
	djnz cp_lp_8bp       
       	ret

copy_palette:
       ld a,(palette_page)  
       nextreg $57,a
       ld hl, $e000
       ld b,32

       nextreg $43,%00110000 
       nextreg $40, 0
       ld a, 0

       call pal_05bgr_8bit
       ret


pal_05brg_8bit:
;;   odd      even
// 0BBBBBRR RRRGGGGG
// 0000000R RRGGGBBB
       ld a,(hl)
       inc hl
       ld e,a
       and %11100          ; 000GGG00
       ld c, a

       ld d,(hl)
       inc hl
       ld a, %01100000 
       and d                ;0BB00000
       swapnib              ;00000BB0
       sra a                ;000000BB
       or c                 ;000GGGBB
       ld c,a

       ld a,%11
       and d
       sla e                ; R now in Carry
       adc a,a                 ;00000RRR
       swapnib              ;0RRR0000
       add a,a              ;RRR00000
       or c                 ;RRRGGGBB

       nextreg $41,a
       djnz pal_05brg_8bit
       ret
pal_05rbg_8bit:
;;   odd      even
// 0RRRRRBB BBBGGGGG
// 0000000R RRGGGBBB
       ld a,%00011100       ;000GGG00
       and (hl)
       add a,a
       ld e,a               ;00GGG00

       inc hl
       ld a, %01110011      ;0RRR00GG
       and (hl)
       inc hl
       ld d,a
       and %11
       push af
       or e
       ld e,a
       pop af
       add a,a
       and %11100000
       or e

       nextreg $41,a
       djnz pal_05rbg_8bit
       ret

;; Bits 0-4 is red, 5-9 is green, 10-14 is blue. Bit 15 is unused.

pal_05rgb_8bit:
;;   odd      even
// 0RRRRRGG GGGBBBBB
// 0000000R RRGGGBBB
       ld a,%10011000       ;G00BB000
       and (hl)
       ld e,a
       inc hl
       ld a, %01110011      ;0RRR00GG
       and (hl)
       inc hl
       push bc

       ld d,a
       add a,a
       and %11100000
       ld b,a               ;RRR00000

       ld a,e
       and %11000           ;000BB000
       swapnib              ;B000000B
       rlca                 ;000000BB
       or b                 ;RRR000BB
       ld b,a

       ld a,d                ; a= 00000GGG
       rlc e
       adc a,a
       and %111

       add a,a
       add a,a              ; a = 000GGG00
       or   b               ; a = RRRGGGBB                

       pop bc

       nextreg $41,a
       djnz pal_05rgb_8bit
       ret

;; Bits 0-4 is red, 5-9 is green, 10-14 is blue. Bit 15 is unused.


pal_05bgr_8bit:
;;   odd      even
// 0BBBBBGG GGGRRRRR
// 0000000R RRGGGBBB
       ld a,%10011100       ;G00RRR00
       and (HL)
       ld d,a
       inc hl
       ld a, %01100011      ;0BB000GG
       and (hl)
       ld e,a
       inc hl

       push bc

       ld a,%11100
       and d        ; 000RRR00
       sra a        ; 0000RRR0
       swapnib      ; RRR00000
       ld c,a
       
       rlc d         ; d = 00RRR000 ; +G
       ld a,e
       adc a,a        ; e = BB000GGG

       rlca            
       rlca           ; d = 000GGGBB

       or c

       pop bc
      
       nextreg $41,a
       djnz pal_05bgr_8bit
       ret



pal_0555_9bit:

;;   odd      even
// 0RRRRRGG GGGBBBBB
// 00000000 RRRGGGBB
       ld e,(HL)
       inc hl
       ld d,(hl)
       inc hl

       push bc

       push de
       ld b,2 
       BSRA de,b       ;c = % 0000RRRR ,RGGGGGBB

       ld a,%111        ; a = B - 3bits
       and e
       ld c,a

       pop de
       rlc     e
       ld      a,d
       adc     a,a       ; a= % RRRRR GGG
       ld d,a

       and %111000000    ; d= RRR00GGG
       ld e,a            ; e = RRR00000
       
       xor d             ; a = 00000GGG
       add a,a
       add a,a           ; a = 000GGG00

       or e              ; a = RRRGGG00

       sla c             ; c = 000000BB  Bcarry

       jr c, Rcarry
       or c
       nextreg $44,a
       nextreg $44,0

       pop bc

       djnz pal_0555_9bit
       ret
Rcarry:
       or c
       nextreg $44,a
       nextreg $44,1

       pop bc

       djnz pal_0555_9bit
       ret


StartCopper:
	ld a,(copper_active)
	or a
	jr z,copper_run

	ld      hl,no_copper_data_start
	ld      bc,no_copper_data_end-no_copper_data_start
	jr do_copper

copper_run:
       call GetMaxScanline
 ;      inc hl
 ;      inc hl
       ld de, copper_data_start+1
       ld     a,(hl)
       ld     (de),a
       dec de
       inc hl
       ld a,(hl)
       or     $80
       ld     (de),a


	call make_copper

	ld a,0
	out ($fe),a

	ld      hl,copper_data_start
	ld      bc,copper_data_end-copper_data_start
do_copper:
	nextreg	$61,0   ; LSB = 0
	nextreg $62,0   ;// copper stop | MSBs = 00

@lp1:	ld	a,(hl)  ;// write the bytes of the copper
	nextreg $60,a

	inc	hl
	dec	bc
	ld	a,b
	or	c
	cp	0
	jr	nz,@lp1		

	nextreg $62,%01000000 ;// copper start | MSBs = 00

	ld a,255
	out ($fe),a

	ret
 

  
		// copper WAIT  VPOS,HPOS
COPPER_WAIT	macro
		db	HI($8000+(\0&$1ff)+(( (\1/8) &$3f)<<9))
		db	LO($8000+(\0&$1ff)+(( ((\1/8) >>3) &$3f)<<9))
		endm
		// copper MOVE reg,val
COPPER_MOVE		macro
		db	HI($0000+((\0&$ff)<<8)+(\1&$ff))
		db	LO($0000+((\0&$ff)<<8)+(\1&$ff))
		endm
COPPER_NOP	macro
		db	0,0
		endm

COPPER_HALT     macro
                db 255,255
                endm

no_copper_data_start:
	COPPER_MOVE($1c,%00001000) ; Clip Window control : reset tilemap index
	COPPER_MOVE($1b,0) ; Clip Window Tilemap : x1 /2     
	COPPER_MOVE($1b,((320-0)/2-1))              ; x2 /2
	COPPER_MOVE($1b,0)                          ; y1
	COPPER_MOVE($1b,(192+32+32-1))               ; y2

	COPPER_MOVE(PAL_INDEX,0)
	COPPER_MOVE(PAL_VALUE_8BIT,0)
	COPPER_MOVE(TILE_X_LO,0) 
	COPPER_MOVE(TILE_X_HI,0)
	COPPER_MOVE(TILE_Y,0)
	COPPER_HALT
no_copper_data_end:

copper_data_start:
       db $80+1, 1+(20)
	      ; for status bar
	COPPER_MOVE(PAL_INDEX,0)
	COPPER_MOVE(PAL_VALUE_8BIT,%11100)
	COPPER_MOVE(TILE_X_LO,0) 
	COPPER_MOVE(TILE_X_HI,0)
	COPPER_MOVE(TILE_Y,-32)
	COPPER_MOVE($1b,((0+8)/2)) ; Clip Window Tilemap : x1 /2     
	COPPER_MOVE($1b,((320-8)/2-1))              ; x2 /2
	COPPER_MOVE($1b,(8))                          ; y1
	COPPER_MOVE($1b,(192+32+32-8-1))               ; y2


	db $80, 0
	       ; first part of the map
copper_set_part:
	COPPER_MOVE(TILE_X_LO,0)
	COPPER_MOVE(TILE_X_HI,0)
	COPPER_MOVE(TILE_Y,0)

	COPPER_MOVE(PAL_INDEX,0)
	COPPER_MOVE(PAL_VALUE_8BIT,%11)

copper_set_part1:
	; change this to halt if 1 piece on screen else y scan line
        db $80, 16			
	COPPER_MOVE(TILE_Y,0) ; y will change depending upong the scanline

	COPPER_MOVE(PAL_INDEX,0)
	COPPER_MOVE(PAL_VALUE_8BIT,%11111100)
	COPPER_HALT
copper_data_end:
  

make_copper
	ld ix,copper_set_part +1

	ld de, (map_x)
	add de , -8

	ld a,d		;; keep de in 0 to 320 range
	inc a
	jr nz,@ok_2
	add de ,320
@ok_2:
	ld a, 1
	and d

	ld (ix+0),e
	ld (ix+2),a

	ld a,(map_y)
	ld c,a

	cp 16
	jr nc, @split

@no_split:

	sub 32		;// 24 for status bar and 8 for border
	ld (ix+4),a

	ld a,$ff	; overite wait to a halt
	ld c ,a
	jr @write_me
@split:

	sub 32		;// 24 for status bar and 8 for border
	ld (ix+4),a

	ld a,192+32+8
	sub c
	ld c,a
	ld a,$80 ; // wait 0 y
@write_me:
	ld hl,copper_set_part1
	ld (hl),a	; write the halt or wait
	inc hl
	ld (hl),c
	inc hl

	inc hl
	ld a, -32	; now set the y for the next part of the screen
	sub c
	ld (hl),a

	ret
