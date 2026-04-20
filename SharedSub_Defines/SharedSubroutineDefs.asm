!Freespace_SharedSub_JMLList = $128000
	;^[BytesUsed = RatsIfNeeded+(NumberOfJMLs*4)]
	; RatsIfNeeded = 0 if you have [BankNumber & $7F] less than $10
	;  (so if you are in banks $00-$7F, its $10-$7F, for $80-$FF, its
	; $90-$FF). RatsIfNeeded = 8 otherwise.
	;
	; The fixed location where the JMLs list to be inserted to.
	; Must be a freespace location.
	;
	; Warning: Patching this, editing this address, then re-patching
	; does not remove the old JML list and the subroutines the list
	; points to. This causes freespace leaks (unused data that tools
	; would think it's reserved space).
	;
	; To move this without causing freespace leaks, do this instead:
	;
	; Patch "SharedSubRemover.asm" without the above define changed.
	; It will first clear the subroutine code, then the JML list.


;Define setter. Places marked "[Safe to Edit]" indicates an area you can safely edit,
;while "[Don't touch]" means don't touch unless you know what you're doing.
	;[Don't touch]
		!JMLListRatsTagSize = $00					;\A displacement to place the list
		if greaterequal((!Freespace_SharedSub_JMLList>>16)&$7F, $10)	;|AFTER the 8-byte rats tag if the
			!JMLListRatsTagSize = $08				;|rats tags exist.
		endif								;/
	
		!SharedSub_CurrentJMLAddress #= !Freespace_SharedSub_JMLList+!JMLListRatsTagSize	;Start at a freespace.
		if not(defined("SharedSubMacroDefined"))
			!SharedSubMacroDefined = 1			;>Mark that the macros and its calls have been invoked (dangerous if it can be invoked again)
			;^The above if statement is a workaround of a flaw of asar's "includeonce"
			;failing to work if two ASMs at different directories "incsrc" at different
			;paths to the same ASM file. See report here:
			; https://github.com/RPGHacker/asar/issues/287
			macro SetSharedSubDefine(Define_Name)
				!{<Define_Name>} #= !SharedSub_CurrentJMLAddress			;>First set define at current address
				!SharedSub_CurrentJMLAddress #= !SharedSub_CurrentJMLAddress+4		;>Then update the current address position for the next JML instruction location
			endmacro
		endif
	;[Safe to Edit]
	;These below assign each subroutine JML address location to a define.
	;Afterwards, you can utilize them by having "JSL !RoutineDefineName"
	;
	;Syntax: %SetSharedSubDefine(RoutineDefineName)
	;
	;Notes
	; - The orders in JML list in sharedsub.asm and the macro define list
	;   here must match.
	; - If you run into another ASM resource whose defines conflicts with
	;   Shared Subroutines's routine defines, to restore the define names,
	;   you can re-include this define file at where you want it to be
	;   restored (rather than at the top of the ASM file).
		%SetSharedSubDefine(FindFreeUploadSlot)
		%SetSharedSubDefine(GetRand2)
		%SetSharedSubDefine(RangedRandomRt)
		%SetSharedSubDefine(ChangeMap16)
		%SetSharedSubDefine(FindMap16ActsLike)
		%SetSharedSubDefine(FindMap16TileNum)
		%SetSharedSubDefine(SubGetItemMemory)
		%SetSharedSubDefine(SubSetItemMemory)
		%SetSharedSubDefine(UploadDataToVRAM)
		%SetSharedSubDefine(UploadGFXFileToVRAM)
		%SetSharedSubDefine(HexToDec2)
		%SetSharedSubDefine(HexToDec3)
		%SetSharedSubDefine(BitCheck1)
		%SetSharedSubDefine(BitCheck2)
		%SetSharedSubDefine(BitCheck3)
		%SetSharedSubDefine(BitCheck4)
		%SetSharedSubDefine(SubVertPos2)
		%SetSharedSubDefine(GetExtraDrawInfo)
		%SetSharedSubDefine(GetExtraDrawInfo2)
		%SetSharedSubDefine(FindTilemapIndex)
		%SetSharedSubDefine(SubEllipseMove)
		%SetSharedSubDefine(AimingRt)
		%SetSharedSubDefine(SetTargetPosition)
		%SetSharedSubDefine(SetTargetPositionD)
		%SetSharedSubDefine(SetSpriteClipping2)
		%SetSharedSubDefine(SetPlayerClipping2)
		%SetSharedSubDefine(CheckForContact2)
		%SetSharedSubDefine(CheckForContact2A)
		%SetSharedSubDefine(SubSmokeSpr)
		%SetSharedSubDefine(GetDynamicSprSlot)
		%SetSharedSubDefine(DynamicSprDMA)
		%SetSharedSubDefine(FindFreeC)
		%SetSharedSubDefine(GetDrawInfoC)
		%SetSharedSubDefine(GetDrawInfoC2)
		%SetSharedSubDefine(GenericGFXRt16x16C)
		%SetSharedSubDefine(GenericGFXRt8x8C)
		%SetSharedSubDefine(ClusterUpdatePosG)
		%SetSharedSubDefine(ClusterUpdateXPos)
		%SetSharedSubDefine(ClusterUpdateYPos)
		%SetSharedSubDefine(SetClusterClipping2)
		%SetSharedSubDefine(ClusterHurtPlayer)
		%SetSharedSubDefine(ClusterInteract16x16)
		%SetSharedSubDefine(ClusterInteract8x8)
		%SetSharedSubDefine(FindLevelEventSlot)
		%SetSharedSubDefine(ClearLevelEventMisc)
		%SetSharedSubDefine(SubSmoke)
		%SetSharedSubDefine(FindTilemapIndexSub)
		%SetSharedSubDefine(CustSolidSpriteRt)
		%SetSharedSubDefine(CustSolidSpriteRtA)
		%SetSharedSubDefine(LoseYoshi)