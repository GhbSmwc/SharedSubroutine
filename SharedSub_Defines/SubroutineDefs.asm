
!F = |$800000

!FreespaceU = $84A200
;^[BytesUsed = RatsSpace+(NumberOfJMLs*4)]
; RatsIfNeeded = 0 if you have [BankNumber & $7F] less than $10
;  (so if you are in banks $00-$7F, its $10-$7F, for $80-$FF, its $90-$FF).
; RatsIfNeeded = 8 otherwise.
;
; The fixed location where the JMLs list to be inserted.
; Be careful that editing this address and re-inserting
; does NOT remove the old JML list. Use a debugger or
; some hex editor to erase it.
;
;Defines you shouldn't touch:

	!JMLListRatsTagSize = $00			;\A displacement to place the list
	if (!FreespaceU>>16)&$7F >= $10			;|AFTER the 8-byte rats tag if the
		!JMLListRatsTagSize = $08		;|rats tags exist.
	endif						;/

	!prev = first					;\Starting address of the JML list.
	!first = !FreespaceU+!JMLListRatsTagSize	;/

	macro SetDefine(name)				;\Macro to assign each Subroutine label 
		!{<name>} #= !{!prev}+4			;|to a !Define. Remember, JML takes 4 bytes:
		!prev = <name>				;|[JML $123456] -> [5C 56 34 12]
	endmacro					;/
	;Just to let you know, as of 4/27/2018, asar's manuel nor xkas
	;mentioned that {} brackets can be used for label magic, thus
	;something like:
	;
	;!Define = !{Label}
	;
	;Turns into:
	;
	;!Define = !Label ;>!Label is now a define.
	;
	;This macro basically have !prev, !name, and !first (contained in !prev)
	;being label names. This essentially makes it so that it becomes
	;!LabelDefine #= !LabelDefine+4

;This inserts the JML instruction into the fixed address.
;A define will hold a subroutine name. For example: if
;you have a label "MyRoutine", the define would be
;"!MyRoutine", which you can just do JSL !MyRoutine.
;
;Note that the orders in JML list in sharedsub.asm and the
;macros here must match.
!FindFreeUploadSlot = JMLListStart	;>The first JML doesn't get a macro so that it doesn't skip 4 bytes after "JMLListStart".
%SetDefine(GetRand2)			;>the first +4.
%SetDefine(RangedRandomRt)
%SetDefine(ChangeMap16)
%SetDefine(FindMap16ActsLike)
%SetDefine(FindMap16TileNum)
%SetDefine(SubGetItemMemory)
%SetDefine(SubSetItemMemory)
%SetDefine(UploadDataToVRAM)
%SetDefine(UploadGFXFileToVRAM)
%SetDefine(HexToDec2)
%SetDefine(HexToDec3)
%SetDefine(BitCheck1)
%SetDefine(BitCheck2)
%SetDefine(BitCheck3)
%SetDefine(BitCheck4)
%SetDefine(SubVertPos2)
%SetDefine(GetExtraDrawInfo)
%SetDefine(GetExtraDrawInfo2)
%SetDefine(FindTilemapIndex)
%SetDefine(SubEllipseMove)
%SetDefine(AimingRt)
%SetDefine(SetTargetPosition)
%SetDefine(SetTargetPositionD)
%SetDefine(SetSpriteClipping2)
%SetDefine(SetPlayerClipping2)
%SetDefine(CheckForContact2)
%SetDefine(CheckForContact2A)
%SetDefine(SubSmokeSpr)
%SetDefine(GetDynamicSprSlot)
%SetDefine(DynamicSprDMA)
%SetDefine(FindFreeC)
%SetDefine(GetDrawInfoC)
%SetDefine(GetDrawInfoC2)
%SetDefine(GenericGFXRt16x16C)
%SetDefine(GenericGFXRt8x8C)
%SetDefine(ClusterUpdatePosG)
%SetDefine(ClusterUpdateXPos)
%SetDefine(ClusterUpdateYPos)
%SetDefine(SetClusterClipping2)
%SetDefine(ClusterHurtPlayer)
%SetDefine(ClusterInteract16x16)
%SetDefine(ClusterInteract8x8)
%SetDefine(FindLevelEventSlot)
%SetDefine(ClearLevelEventMisc)
%SetDefine(SubSmoke)
%SetDefine(FindTilemapIndexSub)
%SetDefine(CustSolidSpriteRt)
%SetDefine(CustSolidSpriteRtA)
%SetDefine(LoseYoshi)
