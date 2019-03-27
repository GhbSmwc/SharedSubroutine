@includefrom "../sharedsub.asm"

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; slot finder for the custom DMA setup routine (when necessary)
;
; Output: X = slot index (also updates the RAM address that holds the index)
; if no free slots are found, it will return 0
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FindFreeUploadSlot:
	LDA !RAM_DMASlotsEnabled
	INC
	BEQ .Return
	LDA !RAM_DMASlotIndex
	TAX
.Loop
	LDA !RAM_DMASlotsEnabled
	AND.l BitTable1,x
	BEQ .FoundSlot
	INX
	BRA .Loop
.FoundSlot
	LDA !RAM_DMASlotsEnabled
	ORA.l BitTable1,x
	STA !RAM_DMASlotsEnabled
	TXA
	ASL #2
	STA $00
	ASL
	ADC $00
	TAX
	LDA !RAM_DMASlotIndex
	INC
	CMP #$08
	BCC .SlotsLeft
	LDA #$00
	LDY #$01
.SlotsLeft
	STA !RAM_DMASlotIndex
	TAX
.Return
	RTL

BitTable1:
	db $01,$02,$04,$08,$10,$20,$40,$80

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; Alternate random number generator
;
; Note: The two EOR values are the high and low bytes of "magic" numbers as described here: http://codebase64.org/doku.php?id=base:small_fast_16-bit_prng
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

GetRand2:
	LDA $148B|!addr
	BEQ .LowZero
	ASL $148B|!addr
	LDA $148C|!addr
	ROL
	BCC .NoEOR
.DoEOR
	EOR #$F5
	STA $148C|!addr
	STA $148E|!addr
	LDA $148B|!addr
	EOR #$7B
	STA $148B|!addr
	STA $148D|!addr
	RTL
.LowZero
	LDA $148C|!addr
	BEQ .DoEOR
	ASL
	BEQ .NoEOR
	BCS .DoEOR
.NoEOR
	STA $148C|!addr
	STA $148E|!addr
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; Ranged random number generator
;
; Input:  A (8-bit) = maximum value
; Output: A (8-bit) = ranged RNG (0 to max)
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 ;Formula: RNGVal*MaxVal/256 (division round down)
RangedRandomRt:
	PHX
	PHP
	SEP #$30
	PHA
	JSL GetRand2
	PLX			;>push A and pull out as X.
	CPX #$FF
	BNE .Normal
	LDA $148D|!addr
	BRA .End
	if !sa1 == 0
		.Normal
		INX
		LDA $148D|!addr
		STA $4202
		STX $4203
		NOP #4
		LDA $4217	;>divide by 256 by simply loading the high byte.

		.End
	else
		.Normal
		INX
		STZ $2250
		LDA $148D|!addr
		STA $2251
		STZ $2252
		STX $2253
		STZ $2254
		NOP
		BRA $00
		LDA $2307	

		.End
	endif
	
	PLP
	PLX
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; ChangeMap16
;
; - Changes a specified Map16 tile to a specified other tile number
; - Input: $03-$04 = new tile number, $98-$9B = tile position
; - Output: None
;
;Note: No SA-1 compatibility due to map16 storage ($C800s) are
;remapped.
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ChangeMap16:
	PHP
	REP #$30
	PHY
	PHX
	LDA $03
	PHA
	TAX
	JSL .Sub8034
	PLA
	STA $03
	PLX
	PLY
	PLP
	RTL
.Return18
	PLX
	PLB
	PLP
	RTL
.Sub8034
	PHP
	SEP #$20
	PHB
	LDA #$00
	PHA
	PLB
	REP #$30
	PHX
	LDA $9A
	STA $0C
	LDA $98
	STA $0E
	LDA.w #$0000
	SEP #$20
	LDA $5B
	STA $09
	LDA $1933
	BEQ .NoShift
	LSR $09
.NoShift
	LDY $0E
	LDA $09
	AND #$01
	BEQ .Horiz
	LDA $9B
	STA $00
	LDA $99
	STA $9B
	LDA $00  
	STA $99
	LDY $0C
.Horiz
	CPY #$0200
	BCS .Return18
	LDA $1933
	ASL
	TAX
	LDA $BEA8,x
	STA $65
	LDA $BEA9,x
	STA $66
	STZ $67
	LDA $1925
	ASL
	TAY
	LDA ($65),y
	STA $04
	INY
	LDA ($65),y
	STA $05
	STZ $06
	LDA $9B
	STA $07
	ASL
	CLC
	ADC $07
	TAY
	LDA ($04),y
	STA $6B
	STA $6E
	INY
	LDA ($04),y
	STA $6C
	STA $6F
	LDA #$7E
	STA $6D
	INC
	STA $70
	LDA $09
	AND #$01
	BEQ .NoAnd
	LDA $99
	LSR
	LDA $9B
	AND #$01
	BRA .Label52
.NoAnd
	LDA $9B
	LSR
	LDA $99
.Label52
	ROL
	ASL #2
	ORA #$20
	STA $04
	CPX.w #$0000
	BEQ .NoAdd
	CLC
	ADC #$10 
	STA $04
.NoAdd
	LDA $98
	AND #$F0
	CLC
	ASL
	ROL
	STA $05
	ROL
	AND #$03
	ORA $04
	STA $06
	LDA $9A
	AND #$F0
	LSR #3
	STA $04
	LDA $05
	AND #$C0
	ORA $04
	STA $07
	REP #$20
	LDA $09
	AND #$0001
	BNE .Label51
	LDA $1A
	SEC
	SBC #$0080
	TAX
	LDY $1C
	LDA $1933
	BEQ .Label50
	LDX $1E
	LDA $20
	SEC
	SBC #$0080
	TAY
	BRA .Label50
.Label51
	LDX $1A
	LDA $1C
	SEC
	SBC #$0080
	TAY
	LDA $1933
	BEQ .Label50
	LDA $1E
	SEC
	SBC.w #$0080
	TAX  
	LDY $20
.Label50
	STX $08
	STY $0A
	LDA $98
	AND #$01F0
	STA $04
	LDA $9A
	LSR #4
	AND #$000F
	ORA $04
	TAY
	PLA
	SEP #$20
	STA [$6B],y
	XBA
	STA [$6E],y
	XBA
	REP #$20
	ASL
	TAY
	PHK
	PEA.w .Map16Return-$01
	PEA $804C
	JML $00C0FB!F
.Map16Return
	PLB
	PLP
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; Map16 tile number finder
;
; - Finds the tile number of the Map16 tile at the specified location
; - Input: $00-$01 = tile X position; $02-$03 = tile Y position
; - Output: AB = tile number
;
;Note: SA-1 not supported, since the $C800s are remapped.
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FindMap16TileNum:
	PHX
	LDA $02
	AND #$F0
	STA $06
	LDA $00
	LSR #4
	ORA $06
	PHA
	LDA $5B
	AND #$01
	BNE .L0
	PLA
	LDX $01
	CLC
	ADC $00BA60!F,x
	STA $05
	LDA $00BA9C!F,x
	ADC $03
	STA $06
	BRA .L1
.L0
	PLA
	LDX $03
	CLC
	ADC $00BA80!F,x
	STA $05
	LDA $00BABC!F,x
	ADC $01
	STA $06
.L1
	LDA #$7E
	STA $07
	PLX
	LDA [$05]
	XBA
	INC $07
	LDA [$05]
	XBA
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; Map16 acts-like setting finder
;
; - Finds the acts-like setting of the Map16 tile at the specified location
; - Input: $00-$01 = tile X position; $02-$03 = tile Y position
; - Output: AB = tile acts-like setting
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FindMap16ActsLike:
	JSL FindMap16TileNum
.Loop
	REP #$20
	ASL
	ADC $06F624!F
	STA $0D
	SEP #$20
	LDA $06F626!F
	STA $0F
	REP #$20
	LDA [$0D]
	CMP #$0200
	BCS .Loop
	SEP #$20
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; item memory routines
; Input: $0A-$0B = X position, $0C-$0D = Y position
; Output: For the "get" routine, A will be 0 if the item memory bit is not set
; Used: A, $08-$0E
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SubGetItemMemory:
	PHX
	PHY
	JSR ItemMemoryIndexRt
	LDA ($08),y
	AND $018000!F,x
	STA $08
	PLY
	PLX
	LDA $08
	RTL

SubSetItemMemory:
	PHX
	PHY
	JSR ItemMemoryIndexRt
	LDA ($08),y
	ORA $018000!F,x
	STA ($08),y
	PLY
	PLX
	RTL

ItemMemoryIndexRt:
	LDA $5B
	LSR
	BCC .NotVertical
	PEI ($0A)
	REP #$20
	LDA $0C
	STA $0A
	PLA
	STA $0C
	SEP #$20
.NotVertical
	LDX $13BE
	LDA #$F8
	CLC
	ADC $0DA8AE!F,x
	STA $08
	LDA #$19
	ADC $0DA8B1!F,x
	STA $09
	LDA $0C
	ASL #2
	STA $0E
	LDA $0D
	BEQ .UpperSubscreen
	LDA $0E
	ORA #$02
	STA $0E
.UpperSubscreen
	LDA $0A
	AND #$80
	BEQ .LeftHalf
	LDA $0E
	ORA #$01
	STA $0E
.LeftHalf
	LDA $0A
	LSR #4
	AND #$07
	TAX
	LDY $0E
	RTS

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; VRAM data upload routine
;
; - Uploads data from a specified location to a specified VRAM address
; - Input: $00-$02 = source address, X = destination address, $8D = size
; - Output: None
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

UploadDataToVRAM:
	PHY
	PHX
	PHP
	JSR .Sub
	PLP
	PLX
	PLY
	RTL
.Sub
	REP #$10
	SEP #$20
	LDA #$80
	STA $2115
	STX $2116
	LDA #$01
	STA $4310
	LDA #$18
	STA $4311
	LDX $00
	STX $4312
	LDA $02
	STA $4314
	LDX $8D
	STX $4315
	LDA #$02
	STA $420B
	RTS

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; GFX upload routine
;
; - Uploads a specified graphics file to a specified VRAM address
; - Input: $00-$02 = source address, X = destination address, $8D = size,
; A = GFX file number to use
; - Output: None
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

UploadGFXFileToVRAM:
	PHY
	PHX
	PHP
	JSL $0FF900!F
	JSR UploadDataToVRAM_Sub
	PLP
	PLX
	PLY
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; HexToDec2
;
; - Converts a hexadecimal number to decimal (separating the digits)
; - Input: A = 2-digit number to convert (0-99, or 0x00-0x63)
; - Output: A = 1s digit, Y = 10s digit
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

HexToDec2:
	LDY #$00
.Loop
	CMP #$0A
	BCC .Return
	SBC #$0A
	INY
	BRA .Loop
.Return
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; HexToDec3
;
; - Converts a hexadecimal number to decimal (separating the digits)
; - Input: A = 3-digit number to convert (0-255, or 0x00-0xFF)
; - Output: A = 1s digit, Y = 10s digit, X = 100s digit
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

HexToDec3:
	LDX #$00
	LDY #$00
.Loop1
	CMP #$64
	BCC .Loop2
	SBC #$64
	INX
	BRA .Loop1
.Loop2
	CMP #$0A
	BCC .Return
	SBC #$0A
	INY
	BRA .Loop2
.Return
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; BitCheck1
;
; - Checks how many bits of the specified value are set
; - Input: A = value to check
; - Output: Y = number of set bits
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

BitCheck1:
	PHX
	PHA
	LDY #$00
	LDX #$07
.Loop
	LSR
	BCC $01
	INY
	DEX
	BPL .Loop
	PLA
	PLX
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; BitCheck2
;
; - Checks what the highest set bit of the specified value is
; - Input: A = value to check
; - Output: Y = highest set bit number (if carry clear, none set)
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

BitCheck2:
	PHA
	LDY #$07
	STY $00
.Loop
	ASL
	BCS .End
	DEC $00
	BPL .Loop
.End
	PLA
	LDY $00
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; BitCheck3
;
; - Checks how many bits of the specified value are clear
; - Input: A = value to check
; - Output: Y = number of cleared bits
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

BitCheck3:
	PHX
	PHA
	LDY #$00
	LDX #$07
.Loop
	LSR
	BCS $01
	INY
	DEX
	BPL .Loop
	PLA
	PLX
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; BitCheck4
;
; - Checks what the lowest set bit of the specified value is
; - Input: A = value to check
; - Output: Y = lowest set bit number (if carry clear, none set)
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

BitCheck4:
	PHA
	LDY #$07
	STZ $00
.Loop
	LSR
	BCS .End
	INC $00
	DEY
	BPL .Loop
	STY $00
.End
	PLA
	LDY $00
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; SubVertPos2
;
; - Checks whether the sprite is above or below the player, using his/her lower tile
; - Also outputs the distance between them (low byte only)
; - Input: None
; - Output:
;	- Y = direction status (00 -> sprite above, 01 -> sprite below)
;	- $0F = 8-bit signed vertical distance between the player and the sprite
;	- $0C = The player's Y position (lower tile)
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SubVertPos2:
	REP #$20		;\Get lower 16x16 tile of player.
	LDA $96			;
	CLC			;
	ADC #$0010		;
	STA $0C			;
	SEP #$20		;/
	LDY #$00
	LDA $0C
	SEC
	SBC !D8,x
	STA $0F
	LDA $0D
	SBC !14D4,x
	BPL $01
	INY
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; GetExtraDrawInfo
;
; - Sets up a few extra variables for sprite graphics routines
; - Input: None
; - Output:
;	- $02 = sprite tilemap index (using the custom spriteset routine)
;	- $03 = sprite palette, GFX page, and priority
;	- $04 = sprite animation frame (value of $1602,x)
;	- $05 = sprite horizontal direction (value of $157C,x)
;	- $06 = sprite palette/GFX page/priority with horizontal direction flip
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

GetExtraDrawInfo:
	LDA !RAM_SprGFXOffset,x
	STA $02
	LDA !15F6,x
	ORA $64
	STA $03
	LDA !1602,x
	STA $04
	LDA !157C,x
	STA $05
	ROR #3
	AND #$40
	EOR #$40
	ORA $03
	STA $06
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; GetExtraDrawInfo2
;
; - Sets up a few extra variables for sprite graphics routines
; - Input: None
; - Output:
;	- $02 = sprite tilemap index (using the custom spriteset routine)
;	- $03 = sprite palette, GFX page, and priority
;	- $04 = sprite animation frame (value of $1602,x)
;	- $05 = sprite horizontal direction (value of $157C,x)
;	- $06 = sprite palette/GFX page/priority with horizontal direction flip
; *Note: The difference between this routine and the previous one is that this one
; finds the tilemap index on the fly, while the other uses whatever was last left
; in the table for it (normally set during the init routine).
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

GetExtraDrawInfo2:
	JSL FindTilemapIndex
	STA $02
	LDA !15F6,x
	ORA $64
	STA $03
	LDA !1602,x
	STA $04
	LDA !157C,x
	STA $05
	ROR #3
	AND #$40
	EOR #$40
	ORA $03
	STA $06
	RTL

;------------------------------------------------
; tilemap index subroutine
; - checks for either of 2 possible GFX files specified by
; !RAM_SprGFXFiles,x and the three tables after it
; - returns a multiple of 0x20 depending on which slot the
; correct GFX file was found in
;------------------------------------------------

FindTilemapIndex:
	LDA !RAM_SprGFXFiles,x
	STA $06
	LDA !RAM_SprGFXFiles+$0C,x
	STA $07
	LDA !RAM_SprGFXFiles+$18,x
	STA $08
	LDA !RAM_SprGFXFiles+$24,x
	STA $09
FindTilemapIndexSub:
	REP #$20
	PHX
	LDX #$00
.Loop
	LDA !RAM_SpriteGFXList,x
	CMP $06
	BEQ .FoundSlot
	CMP $08
	BEQ .FoundSlot
	INX #2
	CPX #$10
	BCC .Loop
.FoundSlot
	SEP #$20
	TXA
	ASL #4
	PLX
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; Ellipse motion routine
;
; - Allows a sprite (or other entity) to move in an elliptical pattern
; - Input:
;	- $04-$05 = angle
;	- $06 = X radius
;	- $07 = Y radius
; - Output:
;	- $08-$09 = X offset
;	- $0A-$0B = Y offset
;
;Not compatible when running under SA-1 mode (uses mode 7 registers).
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SubEllipseMove:
	PHB
	PHK
	PLB
	PHX
	JSR circleX
	JSR circleY
	PLX
	PLB
	RTL

circleX:
	LDA $04
	CLC : ADC #$80
	TAX
	LDA $05
	ADC #$00
	LSR
	LDA sincostable,x
	STA $211B
	STZ $211B
	LDA $06
	STA $211C
	REP #$20
	LDA $2135
	BCC +
	EOR #$FFFF : INC
+
	STA $08
	SEP #$20
	RTS

circleY:
	LDA $05
	LSR
	LDX $04
	LDA sincostable,x
	STA $211B
	STZ $211B
	LDA $07
	STA $211C
	REP #$20
	LDA $2135
	BCC +
	EOR #$FFFF : INC
+
	STA $0A
	SEP #$20
	RTS

sincostable:
	db $00,$03,$06,$09,$0C,$0F,$12,$15,$19,$1C,$1F,$22,$25,$28,$2B,$2E
	db $31,$35,$38,$3B,$3E,$41,$44,$47,$4A,$4D,$50,$53,$56,$59,$5C,$5F
	db $61,$64,$67,$6A,$6D,$70,$73,$75,$78,$7B,$7E,$80,$83,$86,$88,$8B
	db $8E,$90,$93,$95,$98,$9B,$9D,$9F,$A2,$A4,$A7,$A9,$AB,$AE,$B0,$B2
	db $B5,$B7,$B9,$BB,$BD,$BF,$C1,$C3,$C5,$C7,$C9,$CB,$CD,$CF,$D1,$D3
	db $D4,$D6,$D8,$D9,$DB,$DD,$DE,$E0,$E1,$E3,$E4,$E6,$E7,$E8,$EA,$EB
	db $EC,$ED,$EE,$EF,$F1,$F2,$F3,$F4,$F4,$F5,$F6,$F7,$F8,$F9,$F9,$FA
	db $FB,$FB,$FC,$FC,$FD,$FD,$FE,$FE,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF

	db $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FE,$FE,$FD,$FD,$FC,$FC,$FB
	db $FB,$FA,$F9,$F9,$F8,$F7,$F6,$F5,$F4,$F4,$F3,$F2,$F1,$EF,$EE,$ED
	db $EC,$EB,$EA,$E8,$E7,$E6,$E4,$E3,$E1,$E0,$DE,$DD,$DB,$D9,$D8,$D6
	db $D4,$D3,$D1,$CF,$CD,$CB,$C9,$C7,$C5,$C3,$C1,$BF,$BD,$BB,$B9,$B7
	db $B5,$B2,$B0,$AE,$AB,$A9,$A7,$A4,$A2,$9F,$9D,$9B,$98,$95,$93,$90
	db $8E,$8B,$88,$86,$83,$80,$7E,$7B,$78,$75,$73,$70,$6D,$6A,$67,$64
	db $61,$5F,$5C,$59,$56,$53,$50,$4D,$4A,$47,$44,$41,$3E,$3B,$38,$35
	db $31,$2E,$2B,$28,$25,$22,$1F,$1C,$19,$15,$12,$0F,$0C,$09,$06,$03

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; aiming routine and related
;
; - Sets X and Y speed values such that a sprite will aim for the player
; Input:
; - $00-$01 = spawner X position - target X position
; - $02-$03 = spawner Y position - target Y position
; - A = projectile speed
; Output:
; - $00 = X speed
; - $02 = Y speed
;
; For the target position routines:
; - $08-$0B are the spawner's X and Y position (the "D" variant, for "default",
; uses $E4, $14E0, $D8, and $14D4)
; - if the routine returns with the carry flag clear, the distance is out of range
;
;Not compatible with SA-1 becaise it uses 16-bit signed
;multiplication division.
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

recip_sqrt_lookup:
	dw $0000,$FFFF,$B505,$93CD,$8000,$727D,$6883,$60C2
	dw $5A82,$5555,$50F4,$4D30,$49E7,$4700,$446B,$4219
	dw $4000,$3E17,$3C57,$3ABB,$393E,$37DD,$3694,$3561
	dw $3441,$3333,$3235,$3144,$3061,$2F8A,$2EBD,$2DFB
	dw $2D41,$2C90,$2BE7,$2B46,$2AAB,$2A16,$2987,$28FE
	dw $287A,$27FB,$2780,$270A,$2698,$262A,$25BF,$2557
	dw $24F3,$2492,$2434,$23D9,$2380,$232A,$22D6,$2285
	dw $2236,$21E8,$219D,$2154,$210D,$20C7,$2083,$2041
	dw $2000,$1FC1,$1F83,$1F46,$1F0B,$1ED2,$1E99,$1E62
	dw $1E2B,$1DF6,$1DC2,$1D8F,$1D5D,$1D2D,$1CFC,$1CCD
	dw $1C9F,$1C72,$1C45,$1C1A,$1BEF,$1BC4,$1B9B,$1B72
	dw $1B4A,$1B23,$1AFC,$1AD6,$1AB1,$1A8C,$1A68,$1A44
	dw $1A21,$19FE,$19DC,$19BB,$199A,$1979,$1959,$1939
	dw $191A,$18FC,$18DD,$18C0,$18A2,$1885,$1869,$184C
	dw $1831,$1815,$17FA,$17DF,$17C5,$17AB,$1791,$1778
	dw $175F,$1746,$172D,$1715,$16FD,$16E6,$16CE,$16B7
	dw $16A1,$168A,$1674,$165E,$1648,$1633,$161D,$1608
	dw $15F4,$15DF,$15CB,$15B7,$15A3,$158F,$157C,$1568
	dw $1555,$1542,$1530,$151D,$150B,$14F9,$14E7,$14D5
	dw $14C4,$14B2,$14A1,$1490,$147F,$146E,$145E,$144D
	dw $143D,$142D,$141D,$140D,$13FE,$13EE,$13DF,$13CF
	dw $13C0,$13B1,$13A2,$1394,$1385,$1377,$1368,$135A
	dw $134C,$133E,$1330,$1322,$1315,$1307,$12FA,$12ED
	dw $12DF,$12D2,$12C5,$12B8,$12AC,$129F,$1292,$1286
	dw $127A,$126D,$1261,$1255,$1249,$123D,$1231,$1226
	dw $121A,$120F,$1203,$11F8,$11EC,$11E1,$11D6,$11CB
	dw $11C0,$11B5,$11AA,$11A0,$1195,$118A,$1180,$1176
	dw $116B,$1161,$1157,$114D,$1142,$1138,$112E,$1125
	dw $111B,$1111,$1107,$10FE,$10F4,$10EB,$10E1,$10D8
	dw $10CF,$10C5,$10BC,$10B3,$10AA,$10A1,$1098,$108F
	dw $1086,$107E,$1075,$106C,$1064,$105B,$1052,$104A
	dw $1042,$1039,$1031,$1029,$1020,$1018,$1010,$1008

SetTargetPositionD:
	LDA !E4,x
	STA $08
	LDA !14E0,x
	STA $09
	LDA !D8,x
	STA $0A
	LDA !14D4,x
	STA $0B
SetTargetPosition:
	REP #$20
	LDA $08
	SEC
	SBC $94
	STA $00
	LDA $96
	CLC
	ADC #$0010
	STA $02
	LDA $0A
	SEC
	SBC $02
	STA $02
	BPL $04
	EOR #$FFFF
	INC
	CMP #$0100
	BCS .OutOfRange
	LDA $00
	BPL $04
	EOR #$FFFF
	INC
	CMP #$0100
	BCS .OutOfRange
	SEP #$21
	RTL
.OutOfRange
	SEP #$20
	CLC
	RTL
	
AimingRt:
	PHX
	PHY
	PHP
	SEP #$30
	STA $0F
	LDX #$00
	REP #$20
	LDA $00
	BPL .pos_dx
	EOR #$FFFF
	INC
	INX #2
	STA $00
.pos_dx
	SEP #$20
	STA $4202
	STA $4203
	NOP #3
	REP #$20
	LDA $4216
	STA $04
	LDA $02
	BPL .pos_dy
	EOR #$FFFF
	INC
	INX
	STA $02
.pos_dy
	SEP #$20
	STA $4202
	STA $4203
	STX $0E
	REP #$30
	LDA $04
	CLC
	ADC $4216
	LDY #$0000
	BCC .loop
	INY
	ROR
	LSR
.loop
	CMP #$0100
	BCC +
	INY
	LSR
	LSR
	BRA .loop
+
	CLC
	ASL
	TAX
	LDA recip_sqrt_lookup,x
-	
	DEY
	BMI +
	LSR
	BRA -
+
	SEP #$30
	STA $4202
	LDA $0F
	STA $4203
	NOP
	STZ $05
	STZ $07
	LDA $4217
	STA $04
	XBA
	STA $4202
	LDA $0F
	STA $4203
	REP #$20
	LDA $04
	CLC
	ADC $4216
	STA $04
	SEP #$20
	LDX #$02
-
	LDA $04
	STA $4202
	LDA $00,x
	STA $4203
	NOP #4
	LDA $4217
	STA $06
	LDA $05
	STA $4202
	LDA $00,x
	STA $4203
	REP #$20
	LDA $06
	CLC
	ADC $4216
	SEP #$20
	LSR $0E
	BCS +
	EOR #$FF
	INC
+	
	STA $00,x
	DEX #2
	BPL -
	PLP
	PLY
	PLX
	RTL


;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; custom sprite clipping routine
;
; - Sets up a sprite's interaction field with 16-bit values
; - Input:
;	- $08-$09 = X displacement
;	- $0A-$0B = Y displacement
;	- $0C-$0D = width
;	- $0E-$0F = height
; - Output: None
; - Note: This should be used in conjunction with the following two routines.
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SetSpriteClipping2:
	LDA !14E0,x
	XBA
	LDA !E4,x
	REP #$20
	CLC
	ADC $08
	STA $08
	SEP #$20
	LDA !14D4,x
	XBA
	LDA !D8,x
	REP #$20
	CLC
	ADC $0A
	STA $0A
	SEP #$20
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; custom player clipping routine
;
; - Sets up the player's interaction field with 16-bit values
; - Input: None
; - Output: None
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SetPlayerClipping2:
	PHX
	REP #$20
	LDA $94
	CLC
	ADC #$0002
	STA $00
	LDA #$000C
	STA $04
	SEP #$20
	LDX #$00
	LDA $73
	BNE .Inc1
	LDA $19
	BNE .Next1
.Inc1
	INX
.Next1
	LDA $187A|!addr
	BEQ .Next2
	INX #2
.Next2
	LDA $03B660!F,x
	STA $06
	STZ $07
	LDA $03B65C!F,x
	REP #$20
	AND #$00FF
	CLC
	ADC $96
	STA $02
	SEP #$20
	PLX
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; custom contact check routine
;
; - Checks for contact between whatever two things were set up previously
; - Input: $00-$07 = clipping set 1, $08-$0F = clipping set 2
; - Output: Carry clear = no contact, carry set = contact
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CheckForContact2:
	REP #$20
.CheckX
	LDA $00
	CMP $08
	BCC .CheckXSub2
.CheckXSub1
	SEC
	SBC $08
	CMP $0C
	BCS .ReturnNoContact
	BRA .CheckY
.CheckXSub2
	LDA $08
	SEC
	SBC $00
	CMP $04
	BCS .ReturnNoContact
.CheckY
	LDA $02
	CMP $0A
	BCC .CheckYSub2
.CheckYSub1
	SEC
	SBC $0A
	CMP $0E
	BCS .ReturnNoContact
.ReturnContact
	SEP #$21
	RTL
.CheckYSub2
	LDA $0A
	SEC
	SBC $02
	CMP $06
	BCC .ReturnContact
.ReturnNoContact
	CLC
	SEP #$20
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; custom contact check routine 2
;
; - Checks for contact between whatever two things were set up previously; also
; checks where one clipping field is in relation to the other
; - Input: $00-$07 = clipping set 1, $08-$0F = clipping set 2
; - Output:
;	- Carry clear = no contact, carry set = contact
;	- Negative flag clear = field 1 left of 2, negative set = field 1 right of 2
;	- Overflow flag clear = field 1 above 2, overflow set = field 1 below 2
; *Note: This routine overwrites $8A, unlike the previous one.
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CheckForContact2A:
	LDA #$31
	STA $8A
	REP #$20
.CheckX
	LDA $00
	CMP $08
	BCC .PlayerOnLeft
.PlayerOnRight
	SEC
	SBC $08
	CMP $0C
	BCS .ReturnNoContact
	LDA #$80
	TSB $8A
	BRA .CheckY
.PlayerOnLeft
	LDA $08
	SEC
	SBC $00
	CMP $04
	BCS .ReturnNoContact
.CheckY
	LDA $02
	CMP $0A
	BCC .PlayerAbove
.PlayerBelow
	SEC
	SBC $0A
	CMP $0E
	BCS .ReturnNoContact
	LDA #$40
	TSB $8A
.ReturnContact
	PEI ($8A)
	PLP
	PLA
	RTL
.PlayerAbove
	LDA $0A
	SEC
	SBC $02
	CMP $06
	BCC .ReturnContact
.ReturnNoContact
	CLC
	SEP #$20
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; smoke routine for sprites
;
; - generates a puff of smoke at a sprite's position
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SubSmokeSpr:
	JSR .OffscreenSmoke
	BNE .Invalid
	PHY
	LDY #$03
.FindFree
	LDA $17C0|!addr,y
	BEQ .FoundOne
	DEY
	BPL .FindFree
	PLY
.Invalid
	RTL
.FoundOne
	LDA #$01
	STA $17C0|!addr,y
	LDA !D8,x
	STA $17C4|!addr,y
	LDA !E4,x
	STA $17C8|!addr,y
	LDA #$1B
	STA $17CC|!addr,y
	PLY
	RTL

.OffscreenSmoke
	LDA !D8,x
	CMP $1C
	LDA !14D4,x
	SBC $1D
	BNE .End
	LDA !E4,x
	CMP $1A
	LDA !14E0,x
	SBC $1B
.End
	RTS

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; dynamic sprite slot finder
;
; - Finds a free slot for a dynamic sprite's GFX
; - Input: A = frame number, $09-$0A = GFX address (low and high bytes; bank byte is the data bank)
; - Output: None
; - Overwrites $0B-$0F
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

!SlotPtr = $0B
!SlotBank = $0D
!SlotDest = $0E

GetDynamicSprSlot:
	PHY
	PHA
	LDA !SlotsUsed
	CMP #$04
	BEQ .NoneFree
	PLA
	REP #$20
	AND #$00FF
	XBA
	LSR
	CLC
	ADC $09
	STA !SlotPtr
	SEP #$20
	PHB
	PLA
	STA !SlotBank
	LDY !SlotsUsed
	PHB
	PHK
	PLB
	LDA .Slots,y
	PLB
	PHA
	SEC
	SBC #$C0
	REP #$20
	AND #$00FF
	ASL #5
	ADC #$0B44
	STA !SlotDest
	JSL DynamicSprDMARt
	SEP #$20
	INC !SlotsUsed
	PLA
	PLY
	RTL
.NoneFree
	PLA
	PLY
	LDA #$00
	RTL

.Slots
	db $CC,$C8,$C4,$C0

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; dynamic sprite GFX upload routine
;
; - uploads a dynamic sprite's graphics to the correct location
; - Input: None, other than setting !SlotDest, !SlotPtr, and !SlotBank
; - Output: None
;
;Not SA-1 compatible due to 16-bit signed number.
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

DynamicSprDMARt:
	REP #$20
	LDA !SlotDest
	STA $2181
	LDY #$7F
	STY $2183
	STZ $4320
	LDY #$80
	STY $4321
	LDA !SlotPtr
	STA $4322
	LDY !SlotBank
	STY $4324
	LDY #$80
	STY $4325
	LDY #$04
	STY $420B
	LDA !SlotDest
	CLC
	ADC #$0200
	STA !SlotDest
	STA $2181
	LDA !SlotPtr
	CLC
	ADC #$0200
	STA !SlotPtr
	STA $4322
	LDY !SlotBank
	STY $4324
	LDY #$80
	STY $4325
	LDY #$04
	STY $420B
	LDA !SlotDest
	CLC
	ADC #$0200
	STA !SlotDest
	STA $2181
	LDA !SlotPtr
	CLC
	ADC #$0200
	STA !SlotPtr
	STA $4322
	LDY !SlotBank
	STY $4324
	LDY #$80
	STY $4325
	LDY #$04
	STY $420B
	LDA !SlotDest
	CLC
	ADC #$0200
	STA !SlotDest
	STA $2181
	LDA !SlotPtr
	CLC
	ADC #$0200
	STA !SlotPtr
	STA $4322
	LDY !SlotBank
	STY $4324
	LDY #$80
	STY $4325
	LDY #$04
	STY $420B
	SEP #$20
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; level event slot finder
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

FindLevelEventSlot:
	LDX #$00
.Loop
	LDA !RAM_LevelEvents,x
	BEQ .FoundOne
	TXA
	CLC
	ADC #$40
	TAX
	BCC .Loop
	RTL
.FoundOne
	CLC
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; level event misc. RAM clear
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ClearLevelEventMisc:
	LDA #$00
	STA !RAM_LevelEvents+$01,x
	STA !RAM_LevelEvents+$08,x
	STA !RAM_LevelEvents+$09,x
	STA !RAM_LevelEvents+$0A,x
	STA !RAM_LevelEvents+$0B,x
	STA !RAM_LevelEvents+$0C,x
	STA !RAM_LevelEvents+$0D,x
	STA !RAM_LevelEvents+$0E,x
	STA !RAM_LevelEvents+$0F,x
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; cluster sprite stuff (some of these routines might need to be checked and optimized, though...)
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

!ExtSlotStart = $20

;------------------------------------------------
; GetDrawInfo (2 variants)
;------------------------------------------------

GetDrawInfoC:
	STZ $04
	LDA $1E16|!addr,x
	STA $0C
	LDA $1E3E|!addr,x
	STA $0D
	LDA $1E02|!addr,x
	STA $0E
	LDA $1E2A|!addr,x
	STA $0F
	REP #$20
	LDA $0C
	SEC
	SBC $1A
	STA $00
	CLC
	ADC #$0010
	CMP #$0110
	BCS .Offscreen
	CMP #$0010
	BCS $02
	INC $04
	LDA $0E
	SEC
	SBC $1C
	SEP #$20
	STA $01
	REP #$20
	CLC
	ADC #$0010
	CMP #$00F0
	SEP #$20
	BCS .Offscreen2
;	LDA $0E
;	STA $01
	JSR FindExtOAMSlotSub
;	LDY !RAM_ExtOAMIndex
	SEC
	RTL
.Offscreen2
	LDY #$00
	CLC
	RTL
.Offscreen
	SEP #$20
;	STZ $170B|!addr,x
	LDY #$01
	CLC
	RTL

GetDrawInfoC2:
	LDA $1E16|!addr,x
	SEC
	SBC $1A
	STA $00
	LDA $1E3E|!addr,x
	SBC $1B
	STA $02
	LDA $1E02|!addr,x
	SEC
	SBC $1C
	STA $01
	LDA $1E2A|!addr,x
	SBC $1D
	BNE .End
	LDA $01
	CMP #$E1
	BCC .NoOffScrV
	LDA #$F0
	STA $01
.NoOffScrV
	STZ $04
	LDA $02
	BEQ .Continue
	INC
	BNE .End
	INC $04
.Continue
	JSR FindExtOAMSlotSub
	BNE .End
	SEC
	RTL
.End
	CLC
	RTL

FindExtOAMSlotSub:
	LDY #!ExtSlotStart
.Loop
	LDA $0201|!addr,y
	CMP #$F0
	BEQ .FoundSlot
	INY #4
	BNE .Loop
	DEY
.FoundSlot
	RTS

;------------------------------------------------
; routine to find a free sprite slot
;------------------------------------------------

FindFreeC:
	LDY #$13
.Loop
	LDA $1892|!addr,y
	BEQ .FoundSlot
	DEY
	BPL .Loop
.FoundSlot
	RTL

;------------------------------------------------
; speed routines
;------------------------------------------------

ClusterUpdatePosG:
	JSR ClusterUpdateXPosMain
	JSR ClusterUpdateYPosMain
	LDA $1E52|!addr,x
	CLC
	ADC #$03
	STA $1E52|!addr,x
	BMI .Skip
	CMP #$40
	BCC .Skip
	LDA #$40
	STA $1E52|!addr,x
.Skip
	RTL

ClusterUpdateXPos:
	JSR ClusterUpdateXPosMain
	RTL

ClusterUpdateXPosMain:
	STZ $1491|!addr
	LDA $1E16|!addr,x
	PHA
	LDA $1E66|!addr,x
	ASL #4
	CLC
	ADC $1E8E|!addr,x
	STA $1E8E|!addr,x
	PHP
	LDA $1E66|!addr,x
	LSR #4
	CMP #$08
	LDY #$00
	BCC $03
	ORA #$F0
	DEY
	PLP
	ADC $1E16|!addr,x
	STA $1E16|!addr,x
	TYA
	ADC $1E3E|!addr,x
	STA $1E3E|!addr,x
	PLA
	LDA $1E16|!addr,x
	SEC
	SBC $00,s
	STA $1491|!addr
	RTS

ClusterUpdateYPos:
	JSR ClusterUpdateYPosMain
	RTL

ClusterUpdateYPosMain:
	STZ $1491
	LDA $1E02|!addr,x
	PHA
	LDA $1E52|!addr,x
	ASL #4
	CLC
	ADC $1E7A|!addr,x
	STA $1E7A|!addr,x
	PHP
	LDA $1E52|!addr,x
	LSR #4
	CMP #$08
	LDY #$00
	BCC $03
	ORA #$F0
	DEY
	PLP
	ADC $1E02|!addr,x
	STA $1E02|!addr,x
	TYA
	ADC $1E2A|!addr,x
	STA $1E2A|!addr,x
	PLA
	LDA $1E02|!addr,x
	SEC
	SBC $00,s
	STA $1491|!addr
	RTS

;------------------------------------------------
; clipping routine (equivalent to $03B69F)
;------------------------------------------------

SetClusterClipping2:
	LDA $1E3E|!addr,x
	XBA
	LDA $1E16|!addr,x
	REP #$20
	CLC
	ADC $08
	STA $08
;	LDA $0C
;	STA $0C
	SEP #$20
	LDA $1E2A|!addr,x
	XBA
	LDA $1E02|!addr,x
	REP #$20
	CLC
	ADC $0A
	STA $0A
;	LDA $0E
;	STA $0E
	SEP #$20
	RTL

;------------------------------------------------
; generic base 16x16 GFX routine
; input: $02 = tile number, $03 = palette and GFX page, $04 = direction
;------------------------------------------------

GenericGFXRt16x16C:
	JSL GetDrawInfoC
	BCC .Offscreen
	LDA $00
	STA $0200|!addr,y
	LDA $01
	STA $0201|!addr,y
	LDA $02
	STA $0202|!addr,y
	LDA $04
	LSR
	LDA $03
	ORA $64
	BCS $02
	ORA #$40
	STA $0203|!addr,y
	TYA
	LSR #2
	TAY
	LDA #$02
	STA $0420|!addr,y
	LDX $15E9|!addr
	RTL
.Offscreen
	STZ $1892|!addr,x
	RTL

;------------------------------------------------
; generic base 8x8 GFX routine
; input: $02 = tile number, $03 = palette and GFX page, $04 = direction
;------------------------------------------------

GenericGFXRt8x8C:
	JSL GetDrawInfoC
	BCC .Offscreen
	LDA $00
	STA $0200|!addr,y
	LDA $01
	STA $0201|!addr,y
	LDA $02
	STA $0202|!addr,y
	LDA $04
	LSR
	LDA $03
	ORA $64
	BCS $02
	ORA #$40
	STA $0203|!addr,y
	TYA
	LSR #2
	TAY
	LDA #$00
	STA $0420|!addr,y
	LDX $15E9|!addr
	RTL
.Offscreen
	STZ $1892|!addr,x
	RTL

;------------------------------------------------
; player hurt routine
;------------------------------------------------

ClusterHurtPlayer:
	JSR ClusterHurtPlayerMain
	RTL

ClusterHurtPlayerMain:
	LDA $187A|!addr
	BEQ .NoYoshi
	JMP LoseYoshi_Sub
.NoYoshi
	JSL $00F5B7!F
	RTS

;------------------------------------------------
; 8x8 interaction routine
;------------------------------------------------

ClusterInteract8x8:
;	LDA $13F9
;	EOR $1779,x
;	BNE .Return
	LDA #$01
	STA $08
	STA $0A
	STZ $09
	STZ $0B
	LDA #$06
	STA $0C
	STA $0E
	STZ $0D
	STZ $0F
	JSL SetClusterClipping2
	JSL SetPlayerClipping2
	JSL CheckForContact2
.Return
	RTL

;------------------------------------------------
; 16x16 interaction routine
;------------------------------------------------

ClusterInteract16x16:
;	LDA $13F9
;	EOR $1779,x
;	BNE .Return
	LDA #$01
	STA $08
	STA $0A
	STZ $09
	STZ $0B
	LDA #$0E
	STA $0C
	STA $0E
	STZ $0D
	STZ $0F
	JSL SetClusterClipping2
	JSL SetPlayerClipping2
	JSL CheckForContact2
.Return
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; smoke routine for whatever
;
; Input: $00-$03 = XY position
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SubSmoke:
	JSR .OffscreenSmoke
	BNE .Invalid
	PHY
	LDY #$03
.FindFree
	LDA $17C0|!addr,y
	BEQ .FoundOne
	DEY
	BPL .FindFree
	PLY
.Invalid
	RTL
.FoundOne
	LDA #$01
	STA $17C0|!addr,y
	LDA $02
	STA $17C4|!addr,y
	LDA $00
	STA $17C8|!addr,y
	LDA #$1B
	STA $17CC|!addr,y
	PLY
	RTL

.OffscreenSmoke
	LDA $02
	CMP $1C
	LDA $03
	SBC $1D
	BNE .End
	LDA $00
	CMP $1A
	LDA $01
	SBC $1B
.End
	RTS

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; better routine for solid sprites
;
; Input:
;	- A = area size, format yyyyxxxx (xxxx gets multiplied by 16)
;	- carry = crush the player or not (0 = no, 1 = yes)
; return value in $8A:
; yx--rlbt
; t = touching top, b = touching bottom, l = touching left side, r = touching right side, m = in middle
; - 00 - no contact
; - 01 - touching top
; - 02 - touching bottom
; - 04 - touching left side
; - 08 - touching right side
; - 40 - in the middle X range
; - 80 - in the middle Y range

; Scratch ram $00-$0F will not be restored.
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CustSolidSpriteRt:
	PHP
	STA $8A
	JSL SolidSprSubSetInteractBounds
	LDA $45
	CMP $08
	BCC .SetLeft
	CMP $0C
	BCC .SetMiddleX
.SetRight
	LDY #$08
	BRA .SetXBits
.SetLeft
	LDY #$04
	BRA .SetXBits
.SetMiddleX
	LDY #$80
.SetXBits
	STY $8B
	LDA $47
	CMP $0A
	BCC .SetTop
	CMP $0E
	BCC .SetMiddleY
.SetBottom
	LDY #$02
	BRA .SetYBits
.SetTop
	LDY #$01
	BRA .SetYBits
.SetMiddleY
	LDY #$40
.SetYBits
	STY $8C
	SEP #$20
	LDA $8B
	ORA $8C
	STA $8A
	TAY
	LDA !190F,x
	LSR
	BCS .Platform
	CPY #$C0
	BEQ .CrushInMiddle
	TYA
	LSR
	BCS .PosTop
	LSR
	BCS .PosBottom
.TryAgain
	LSR
	BCS .PosLeft
	LSR
	BCS .PosRight
	PLP
	RTL
.CrushInMiddle
	PLP
	BCC .Return
	JML $00F606!F
.Return
	RTL
.Platform
	TYA
	LSR
	BCS .PosTop
	PLP
	RTL
.PosBottom
	AND #$03
	BNE .TryAgain
	LDA #$10
	CLC
	ADC $AA,x
	STA $7D
	LDA #$01
	STA $1DF9|!addr
	PLP
	RTL
.PosLeft
	LDA $E4,x
	SEC
	SBC #$0E
	STA $94
	LDA !14E0,x
	SBC #$00
	STA $95
	LDA $7B
	BEQ ..Enough
	BMI ..Enough
	STZ $7B
..Enough
..Return
	PLP
	RTL
.PosRight
	LDA $0C
	SEC
	SBC #$02
	STA $94
	LDA $0D
	SBC #$00
	STA $95
	LDA $7B
	BEQ ..Enough
	BPL ..Enough
	STZ $7B
..Enough
..Return
	PLP
	RTL
.PosTop
	LDA $7D
	BMI ..Return
	LDA $77
	AND #$08
	BNE ..Return
	LDA #$E0
	LDY $187A|!addr
	BEQ $03
	SEC
	SBC #$10
	LDY.w !AA,x
	BEQ $05
	BMI $03
	CLC
	ADC #$02
	CLC
	ADC !D8,x
	STA $96
	LDA !14D4,x
	ADC #$FF
	STA $97
	LDY #$00
	LDA $1491|!addr
	BPL ..MovingRight
	DEY
..MovingRight
	CLC
	ADC $94
	STA $94
	TYA
	ADC $95
	STA $95
	LDA #$01
	STA $1471|!addr
	LDA #$10
	STA $7D
	LDA #$80
	STA $1406|!addr
..Return
	PLP
	RTL

; after this:
; - $00-$01 = X position of player hitbox left boundary
; - $02-$03 = Y position of player hitbox top boundary
; - $04-$05 = X position of player hitbox right boundary
; - $06-$07 = Y position of player hitbox bottom boundary
; - $08-$09 = X position of sprite hitbox left boundary
; - $0A-$0B = Y position of sprite hitbox top boundary
; - $0C-$0D = X position of sprite hitbox right boundary
; - $0E-$0F = Y position of sprite hitbox bottom boundary
; - $45-$46 = X position of player hitbox middle boundary
; - $47-$48 = Y position of player hitbox middle boundary
; - $49-$4A = X position of sprite hitbox middle boundary
; - $4B-$4C = Y position of sprite hitbox middle boundary
SolidSprSubSetInteractBounds:
	STZ $08
	STZ $09
	LDA #$FE
	STA $0A
	LDA #$FF
	STA $0B
	STZ $0D
	STZ $0F
	LDA $8A
	AND #$0F
	ASL #4
	CLC
	ADC #$10
	STA $0C
	BCC $02
	INC $0D
	LDA $8A
	AND #$F0
	CLC
	ADC #$14
	STA $0E
	BCC $02
	INC $0F
	JSL SetSpriteClipping2
	JSL SetPlayerClipping2
	JSL CheckForContact2
	BCC .ReturnNoContact
	REP #$20
	LDA $04
	LSR
	CLC
	ADC $00
	STA $45
	LDA $00
	CLC
	ADC $04
	STA $04
	LDA $06
	LSR
	CLC
	ADC $02
	STA $47
	LDA $02
	CLC
	ADC $06
	STA $06
	LDA $0C
	LSR
	CLC
	ADC $08
	STA $49
	LDA $08
	CLC
	ADC $0C
	STA $0C
	LDA $0E
	LSR
	CLC
	ADC $0A
	STA $4B
	LDA $0A
	CLC
	ADC $0E
	STA $0E
	RTL
.ReturnNoContact
	PLA
	PLA
	LDA #$00
	PLP
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; same as the above, but allows you to set the position manually rather than using the sprite tables
;
; Input:
;	- A = area size, format yyyyxxxx (xxxx gets multiplied by 16)
;	- carry = crush the player or not (0 = no, 1 = yes)
;	- $51-$54 = position of the interaction field (X low, X high, Y low, Y high)
; return value in $8A:
; yx--rlbt
; t = touching top, b = touching bottom, l = touching left side, r = touching right side, m = in middle
; - 00 - no contact
; - 01 - touching top
; - 02 - touching bottom
; - 04 - touching left side
; - 08 - touching right side
; - 40 - in the middle X range
; - 80 - in the middle Y range

; Scratch ram $00-$0F will not be restored.
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;*NOTE: This routine is unfinished, untested, and probably does not work as it is.

CustSolidSpriteRtA:
	PHP
	STA $8A
	JSL SolidSprSubSetInteractBounds
	LDA $45
	CMP $08
	BCC .SetLeft
	CMP $0C
	BCC .SetMiddleX
.SetRight
	LDY #$08
	BRA .SetXBits
.SetLeft
	LDY #$04
	BRA .SetXBits
.SetMiddleX
	LDY #$80
.SetXBits
	STY $8B
	LDA $47
	CMP $0A
	BCC .SetTop
	CMP $0E
	BCC .SetMiddleY
.SetBottom
	LDY #$02
	BRA .SetYBits
.SetTop
	LDY #$01
	BRA .SetYBits
.SetMiddleY
	LDY #$40
.SetYBits
	STY $8C
	SEP #$20
	LDA $8B
	ORA $8C
	STA $8A
	TAY
	LDA !190F,x
	LSR
	BCS .Platform
	CPY #$C0
	BEQ .CrushInMiddle
	TYA
	LSR
	BCS .PosTop
	LSR
	BCS .PosBottom
.TryAgain
	LSR
	BCS .PosLeft
	LSR
	BCS .PosRight
	PLP
	RTL
.CrushInMiddle
	PLP
	BCC .Return
	JML $00F606!F
.Return
	RTL
.Platform
	TYA
	LSR
	BCS .PosTop
	PLP
	RTL
.PosBottom
	AND #$03
	BNE .TryAgain
	LDA #$10
	CLC
	ADC !AA,x
	STA $7D
	LDA #$01
	STA $1DF9|!addr
	PLP
	RTL
.PosLeft
	LDA $51
	SEC
	SBC #$0E
	STA $94
	LDA $52
	SBC #$00
	STA $95
	LDA $7B
	BEQ ..Enough
	BMI ..Enough
	STZ $7B
..Enough
..Return
	PLP
	RTL
.PosRight
	LDA $0C
	SEC
	SBC #$02
	STA $94
	LDA $0D
	SBC #$00
	STA $95
	LDA $7B
	BEQ ..Enough
	BPL ..Enough
	STZ $7B
..Enough
..Return
	PLP
	RTL
.PosTop
	LDA $7D
	BMI ..Return
	LDA $77
	AND #$08
	BNE ..Return
	LDA #$E0
	LDY $187A|!addr
	BEQ $03
	SEC
	SBC #$10
	LDY.w !AA,x
	BEQ $05
	BMI $03
	CLC
	ADC #$02
	CLC
	ADC $53
	STA $96
	LDA $54
	ADC #$FF
	STA $97
	LDY #$00
	LDA $1491|!addr
	BPL ..MovingRight
	DEY
..MovingRight
	CLC
	ADC $94
	STA $94
	TYA
	ADC $95
	STA $95
	LDA #$01
	STA $1471|!addr
	LDA #$10
	STA $7D
	LDA #$80
	STA $1406|!addr
..Return
	PLP
	RTL

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; make Yoshi run away (usually as a result of being hit)
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

LoseYoshi:
	JSR .Sub
	RTL
.Sub
	PHX
	LDX $18DF|!addr
	LDA #$10
	STA.w !163E-1,x			;>163D
	LDA #$03
	STA $1DFA|!addr
	LDA #$13
	STA $1DFC|!addr
	LDA #$02
	STA.b !C2-1,x			;>$C1
	STZ $187A|!addr
	STZ $0DC1|!addr
	LDA #$C0
	STA $7D
	STZ $7B
	LDY.w !157C-1,x			;>$157B
	LDA .RunAwaySpeed,y
	STA.b !B6-1,x			;>$B5
	STZ.w !1594-1,x			;>$1593
	STZ.w !151C-1,x			;>$151B
	STZ $18AE|!addr
	LDA #$30
	STA $1497|!addr
	PLX
	RTS

.RunAwaySpeed
	db $10,$F0
