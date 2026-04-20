;This "anti-patch" removes the shared subroutines code (both the fixed-located JML list and the varying-located subroutines)
;Useful if you need to relocate the JML list elsewhere.

;To use this. Make sure you:
; - Have previously patched shared subroutines.
; - Did not modify define "!Freespace_SharedSub_JMLList" in "SharedSubroutineDefs.asm" after patching "SharedSub.asm"
; - Did not modify the define list in "SharedSubroutineDefs.asm" and the JML list in "sharedsub.asm" after patching "SharedSub.asm"
; - Make sure the number of items in the JML list and the define list matches (else it could clear more or less bytes
;   that it should have)



;MAKE SURE YOU DIDN'T MODIFY "!Freespace_SharedSub_JMLList" and the define list in "SharedSubroutineDefs.asm"
;before patching this.

incsrc "SharedSub_Defines/SharedSubroutineDefs.asm"

!JMLListToClear = !Freespace_SharedSub_JMLList+!JMLListRatsTagSize
!CurrentJMLToClear = !JMLListToClear

!NumberOfJMLs #= (!SharedSub_CurrentJMLAddress-(!Freespace_SharedSub_JMLList+!JMLListRatsTagSize))/4

;First, clear the subroutine codes
	for i = 0..!NumberOfJMLs
		autoclean read3(!CurrentJMLToClear+1)
		!CurrentJMLToClear #= !CurrentJMLToClear+4
	endfor
;Second, clear the JML list
	if notequal(!JMLListRatsTagSize, 0)
		autoclean !JMLListToClear
	else
		fillbyte $00
		fill !NumberOfJMLs*4
	endif
;Done
	print "Removed the Shared Subroutines patch."
	print "JML list cleared: $", hex(!Freespace_SharedSub_JMLList), " to $", hex(!CurrentJMLToClear-1), " (", dec(!CurrentJMLToClear-!Freespace_SharedSub_JMLList), " bytes, including RATS if applicable)."