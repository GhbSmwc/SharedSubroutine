

!RAM_xSprTbl = $7F9000			; 0x600 bytes - used for extra sprite tables when needed (128 12-byte tables)

; 4 event slots, RAM as follows:
; - Byte 1: Event number (00 = none).
; - Byte 2: State.  (Can be used for miscellaneous purposes otherwise.)
; - Bytes 3-4: Frame counter.
; - Bytes 5-6: X position.
; - Bytes 7-8: Y position.
; - Bytes 9-64: Miscellaneous.
!RAM_LevelEvents = $7F9600

; 8x12 bytes - used to indicate which GFX file numbers a sprite can use
; (usually, only 4 of the 8 tables are used; the other 4 are for sprites that display other sprites, such as the Baron von Zeppelin)
!RAM_SprGFXFiles = $7F9700
; used to store the tilemap offset during the init routine
!RAM_SprGFXOffset = $7F9760

!RAM_DMASlotIndex = $7FA004
!RAM_DMASlotsEnabled = $7FA005

; list of the 8 sprite GFX files currently in use
!RAM_SpriteGFXList = $7FA300

;Slot used for dynamic sprites.
!SlotsUsed = $06FE