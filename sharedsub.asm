;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;
; Shared Subroutines 2.0, by imamelia
;
; This patch inserts a lot of common subroutines into your ROM so that you can
; use them without having to copy-paste them.  Some examples are GetDrawInfo,
; SubOffscreen, and the Map16 tile-generating subroutine.
;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;header
;lorom

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;SA-1 stuff
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	!dp = $0000
	!addr = $0000
	!sa1 = 0
	!gsu = 0

if read1($00FFD6) == $15
	sfxrom
	!dp = $6000
	!addr = !dp
	!gsu = 1
elseif read1($00FFD5) == $23
	sa1rom
	!dp = $3000
	!addr = $6000
	!sa1 = 1
endif


	!sprite_slots = 12
if !sa1 != 0
	!sprite_slots = 22
endif

macro define_sprite_table(name, name2, addr, addr_sa1)
if !sa1 == 0
    !<name> = <addr>
else
    !<name> = <addr_sa1>
endif
    !<name2> = !<name>
endmacro

; Regular sprite tables
%define_sprite_table(sprite_num, "9E", $9E, $3200)
%define_sprite_table(sprite_speed_y, "AA", $AA, $9E)
%define_sprite_table(sprite_speed_x, "B6", $B6, $B6)
%define_sprite_table(sprite_misc_c2, "C2", $C2, $D8)
%define_sprite_table(sprite_y_low, "D8", $D8, $3216)
%define_sprite_table(sprite_x_low, "E4", $E4, $322C)
%define_sprite_table(sprite_status, "14C8", $14C8, $3242)
%define_sprite_table(sprite_y_high, "14D4", $14D4, $3258)
%define_sprite_table(sprite_x_high, "14E0", $14E0, $326E)
%define_sprite_table(sprite_speed_y_frac, "14EC", $14EC, $74C8)
%define_sprite_table(sprite_speed_x_frac, "14F8", $14F8, $74DE)
%define_sprite_table(sprite_misc_1504, "1504", $1504, $74F4)
%define_sprite_table(sprite_misc_1510, "1510", $1510, $750A)
%define_sprite_table(sprite_misc_151c, "151C", $151C, $3284)
%define_sprite_table(sprite_misc_1528, "1528", $1528, $329A)
%define_sprite_table(sprite_misc_1534, "1534", $1534, $32B0)
%define_sprite_table(sprite_misc_1540, "1540", $1540, $32C6)
%define_sprite_table(sprite_misc_154c, "154C", $154C, $32DC)
%define_sprite_table(sprite_misc_1558, "1558", $1558, $32F2)
%define_sprite_table(sprite_misc_1564, "1564", $1564, $3308)
%define_sprite_table(sprite_misc_1570, "1570", $1570, $331E)
%define_sprite_table(sprite_misc_157c, "157C", $157C, $3334)
%define_sprite_table(sprite_blocked_status, "1588", $1588, $334A)
%define_sprite_table(sprite_misc_1594, "1594", $1594, $3360)
%define_sprite_table(sprite_off_screen_horz, "15A0", $15A0, $3376)
%define_sprite_table(sprite_misc_15ac, "15AC", $15AC, $338C)
%define_sprite_table(sprite_slope, "15B8", $15B8, $7520)
%define_sprite_table(sprite_off_screen, "15C4", $15C4, $7536)
%define_sprite_table(sprite_being_eaten, "15D0", $15D0, $754C)
%define_sprite_table(sprite_obj_interact, "15DC", $15DC, $7562)
%define_sprite_table(sprite_oam_index, "15EA", $15EA, $33A2)
%define_sprite_table(sprite_oam_properties, "15F6", $15F6, $33B8)
%define_sprite_table(sprite_misc_1602, "1602", $1602, $33CE)
%define_sprite_table(sprite_misc_160e, "160E", $160E, $33E4)
%define_sprite_table(sprite_index_in_level, "161A", $161A, $7578)
%define_sprite_table(sprite_misc_1626, "1626", $1626, $758E)
%define_sprite_table(sprite_behind_scenery, "1632", $1632, $75A4)
%define_sprite_table(sprite_misc_163e, "163E", $163E, $33FA)
%define_sprite_table(sprite_in_water, "164A", $164A, $75BA)
%define_sprite_table(sprite_tweaker_1656, "1656", $1656, $75D0)
%define_sprite_table(sprite_tweaker_1662, "1662", $1662, $75EA)
%define_sprite_table(sprite_tweaker_166e, "166E", $166E, $7600)
%define_sprite_table(sprite_tweaker_167a, "167A", $167A, $7616)
%define_sprite_table(sprite_tweaker_1686, "1686", $1686, $762C)
%define_sprite_table(sprite_off_screen_vert, "186C", $186C, $7642)
%define_sprite_table(sprite_misc_187b, "187B", $187B, $3410)
%define_sprite_table(sprite_tweaker_190f, "190F", $190F, $7658)
%define_sprite_table(sprite_misc_1fd6, "1FD6", $1FD6, $766E)
%define_sprite_table(sprite_cape_disable_time, "1FE2", $1FE2, $7FD6)

; Romi's Sprite Tool defines.
%define_sprite_table(sprite_extra_bits, "7FAB10", $7FAB10, $6040)
%define_sprite_table(sprite_new_code_flag, "7FAB1C", $7FAB1C, $6056) ;note that this is not a flag at all.
%define_sprite_table(sprite_extra_prop1, "7FAB28", $7FAB28, $6057)
%define_sprite_table(sprite_extra_prop2, "7FAB34", $7FAB34, $606D)
%define_sprite_table(sprite_custom_num, "7FAB9E", $7FAB9E, $6083)

incsrc "SharedSub_Defines/OtherDefines.asm"
incsrc "SharedSub_Defines/SubroutineDefs.asm"

org !FreespaceU
;^This is the starting address for the subroutines.  All "JSL [insert subroutine here]" commands should
; be JSLing to this bank.

print "----------------------------------------------------------------------------------------------"
if !JMLListRatsTagSize != 0
	print "RATS tag memory address range: $", hex(JMLListRatsStart), " to $", hex(JMLListRatsEnd-1), " (8 bytes)"
endif
print "JML list memory address range: $", hex(JMLListStart), " to $", hex(JMLListEnd-1), " (", dec(JMLListEnd-JMLListStart), " bytes, last JML location is at $", hex(JMLListEnd-4), ")"
print "Number of JMLs in list: ", dec((JMLListEnd-JMLListStart)/4)

if (!FreespaceU>>16)&$7F >= $10
	JMLListRatsStart:
	db "S","T","A","R"					;>[4 bytes] rats tag itself
	dw JMLListEnd-JMLListStart-1			;>[2 bytes] size-1
	dw (JMLListEnd-JMLListStart-1)^$FFFF			;>[2 bytes] XOR of above.
	JMLListRatsEnd:
endif
print "----------------------------------------------------------------------------------------------"
;Once patched, in the ROM code, it should look like this:
;<Rats tag ["S", "T", "A", "R"], $XXXX, $YYYY>	;>8 bytes
;	JML $xxxxxx				;>4 bytes
;	JML $xxxxxx				;>4 bytes
;	JML $xxxxxx				;>4 bytes
;	;...

;Make sure you place your JMLs in between the labels "JMLListStart:" and "JMLListEnd"
;to ensure that none of them get overwritten by other programs that modify the ROM.

JMLListStart: ;>The start byte-address of the RATS
;Note: The order of this JML list must match with the defines list (the [%SetDefine(RoutineName)]).

; general
autoclean JML FindFreeUploadSlot		; find a free slot for the DMA setup routine
autoclean JML GetRand2				; alternate random number generator
autoclean JML RangedRandomRt		; random number generator that returns a number within a specified range
autoclean JML ChangeMap16			; ChangeMap16: changes one Map16 tile to another
autoclean JML FindMap16ActsLike		; FindMap16ActsLike: calculates the acts-like setting of the Map16 tile at a specified position
autoclean JML FindMap16TileNum		; FindMap16TileNum: calculates the tile number of the Map16 tile at a specified position
autoclean JML SubGetItemMemory		; routine for checking item memory bits
autoclean JML SubSetItemMemory		; routine for setting item memory bits
autoclean JML UploadDataToVRAM		; upload data from a specified address to VRAM
autoclean JML UploadGFXFileToVRAM	; decompress a GFX file, then upload it to VRAM
autoclean JML HexToDec2			; hexadecimal-to-decimal conversion subroutine (0 <= A <= 99)
autoclean JML HexToDec3			; hexadecimal-to-decimal conversion subroutine (0 <= A <= 255)
autoclean JML BitCheck1				; check how many bits of A are set
autoclean JML BitCheck2				; find the highest set bit of A
autoclean JML BitCheck3				; check how many bits of A are clear
autoclean JML BitCheck4				; find the lowest set bit of A
; sprite
autoclean JML SubVertPos2			; SubVertPos2: like SubVertPos except that it uses the player's bottom tile instead of his/her top tile
autoclean JML GetExtraDrawInfo		; use after GetDrawInfo to set a few extra values (including the GFX offset)
autoclean JML GetExtraDrawInfo2		; same as GetExtraDrawInfo, but sets the GFX offset on the fly instead of requiring it to be initialized
autoclean JML FindTilemapIndex		; FindTilemapIndex: figure out a tilemap offset for a sprite depending on which GFX files it uses
autoclean JML SubEllipseMove			; elliptical movement routine
autoclean JML AimingRt				; aim projectile at player
autoclean JML SetTargetPosition		; target-setting code for the aiming routine
autoclean JML SetTargetPositionD		; alternate entry point for the above
autoclean JML SetSpriteClipping2		; sprite clipping routine with user-specified values (set sprite clipping)
autoclean JML SetPlayerClipping2		; sprite clipping routine with user-specified values (set player clipping)
autoclean JML CheckForContact2		; sprite clipping routine with user-specified values (check for contact)
autoclean JML CheckForContact2A		; a version of the contact-checking routine that also checks which side the player is on
autoclean JML SubSmokeSpr			; smoke-spawning routine for normal sprites
autoclean JML GetDynamicSprSlot		; dynamic sprite slot-finding routine
autoclean JML DynamicSprDMARt		; dynamic sprite DMA transfer routine
; cluster sprites
autoclean JML FindFreeC				; find a slot
autoclean JML GetDrawInfoC			; GetDrawInfo
autoclean JML GetDrawInfoC2			; GetDrawInfo (alternate)
autoclean JML GenericGFXRt16x16C	; 16x16 GFX routine
autoclean JML GenericGFXRt8x8C		; 8x8 GFX routine
autoclean JML ClusterUpdatePosG		; update position with gravity
autoclean JML ClusterUpdateXPos		; update X position
autoclean JML ClusterUpdateYPos		; update Y position
autoclean JML SetClusterClipping2		; clipping routine
autoclean JML ClusterHurtPlayer		; damage the player
autoclean JML ClusterInteract16x16	; 16x16 interaction
autoclean JML ClusterInteract8x8		; 8x8 interaction
; more
autoclean JML FindLevelEventSlot		; slot-finding routine for level events
autoclean JML ClearLevelEventMisc		; clear all miscellaneous RAM for the current level event slot
autoclean JML SubSmoke				; smoke-spawning routine for whatever
autoclean JML FindTilemapIndexSub	; find tilemap index without setting the GFX file numbers inside the routine
autoclean JML CustSolidSpriteRt		; custom solid block/platform sprite interaction
autoclean JML CustSolidSpriteRtA		; custom solid block/platform sprite interaction that uses customizable positions rather than the sprite tables
autoclean JML LoseYoshi				; make Yoshi run away

JMLListEnd: ;>The byte-address +1 from the last byte. Make sure that this label does not have any JML list items after here.
freecode

incsrc subroutinecode.asm

