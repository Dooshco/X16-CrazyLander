; Assembly Collission check between Sprite and background
; System: Commander X16
; Version: Emulator R.38+
; Author: Dusan Strakl
; Date: December 2020
; Compiler: CC65
; Build using:	cl65 -t cx16 Col.asm -o COL.PRG
; Build using:	cl65 -t cx16 Col.asm -C cx16-asm.cfg -o COL.PRG

;.org $080D
;.segment "STARTUP"
;.segment "INIT"
;.segment "ONCE"
;.segment "CODE"

.org $8000
.segment "CODE"

* = $8000
.cpu "4510"

; VERA Registers
VERA_LOW	    = $9F20
VERA_MID	    = $9F21
VERA_HIGH	    = $9F22
VERA_DATA0	    = $9F23
VERA_CTRL	    = $9F25


; VRAM Locations
SPRITE_GRAPHICS = $4000
SPRITE1         = $FC08

; Temp Inputs

;XPOS            = $02
;YPOS            = $03

ADDRESS         = $04

COLLISION       = $06

jmp main

; Variables
PosY:           .byte 0
PosX:           .word 0
PosXDiv:        .word 0
BuffPtr:        .byte 0
Buffer:         .res 128,0
RowCount:       .byte 0

;******************************************************************************
; MAIN PROGRAM
;******************************************************************************
main:
    ; Read X and Y position of the sprite 1 - $1FC08
    stz VERA_CTRL
    lda #$11
    sta VERA_HIGH
    lda #$FC
    sta VERA_MID
    lda #$0A
    sta VERA_LOW
    lda VERA_DATA0
    sta PosX
    sta PosXDiv
    lda VERA_DATA0
    sta PosX+1
    sta PosXDiv+1
    lda VERA_DATA0
    sta PosY

    lsr PosXDiv+1                       ; Divide PosX by 2
    ror PosXDiv


    ; calculate VRAM address using formula Y*160+X/2 to determine top left byte sprite is covering
    stz BuffPtr
    lda #16
    sta RowCount
    lda #$10                            ; Point to VRAM $02000 and Set Increment to 1
    sta VERA_HIGH

:   ldy PosY                            ; store PosY*160 to ADDRESS
    lda M160LO,y 
    sta ADDRESS
    lda M160HI,y 
    sta ADDRESS+1
  
    clc                                 ; add PosX/2 to ADDRESS
    lda PosXDiv
    adc ADDRESS
    sta ADDRESS
    lda PosXDiv+1
    adc ADDRESS+1
    sta ADDRESS+1

    clc                                 ; Add $2000 to ADDRESS, playfield starts at $02000
    lda #$20
    adc ADDRESS+1
    sta ADDRESS+1


    lda ADDRESS                         ; Set VERA address to point to first byte sprite is overlapping
    sta VERA_LOW
    lda ADDRESS+1
    sta VERA_MID

    ldy BuffPtr                         ; Read one row
    ldx #8
:   lda VERA_DATA0
    sta Buffer,y
    iny
    inc BuffPtr
    dex
    bne :-

    inc PosY
    dec RowCount
    bne :--                             ; Repeat 16 times for 16 rows

    ; Choose the mask
    lda PosX
    and #1
    bne :+
    ldx #0
    bra :++
:   ldx #128

    ; Check for collision
:   ldy #0
:   lda Buffer,y
    and Mask,x
    bne hit
    inx
    iny
    cpy #128
    bne :-
    stz COLLISION
    rts
hit:
    lda #1
    sta COLLISION
    rts

Mask:
    .byte $00,$00,$00,$00,$0F,$00,$00,$00       ; 0
    .byte $00,$00,$00,$00,$0F,$00,$00,$00       ; 1
    .byte $00,$FF,$F0,$00,$0F,$00,$00,$00       ; 2
    .byte $00,$FF,$FF,$FF,$FF,$00,$00,$00       ; 3
    .byte $00,$FF,$FF,$FF,$FF,$F0,$00,$00       ; 4
    .byte $00,$0F,$FF,$FF,$FF,$FF,$00,$00       ; 5
    .byte $00,$0F,$FF,$FF,$FF,$FF,$00,$00       ; 6
    .byte $00,$0F,$FF,$FF,$FF,$FF,$00,$00       ; 7
    .byte $00,$00,$FF,$FF,$FF,$F0,$00,$00       ; 8
    .byte $00,$0F,$FF,$FF,$FF,$FF,$00,$00       ; 9
    .byte $00,$FF,$FF,$FF,$FF,$FF,$F0,$00       ; 10
    .byte $00,$FF,$FF,$FF,$FF,$FF,$F0,$00       ; 11
    .byte $0F,$F0,$FF,$FF,$FF,$F0,$FF,$00       ; 12
    .byte $0F,$F0,$0F,$FF,$FF,$00,$FF,$00       ; 13
    .byte $0F,$00,$00,$0F,$00,$00,$0F,$00       ; 14
    .byte $FF,$F0,$00,$FF,$F0,$00,$FF,$F0       ; 15
Mask1:
    .byte $00,$00,$00,$00,$00,$F0,$00,$00       ; 0
    .byte $00,$00,$00,$00,$00,$F0,$00,$00       ; 1
    .byte $00,$0F,$FF,$00,$00,$F0,$00,$00       ; 2
    .byte $00,$0F,$FF,$FF,$FF,$F0,$00,$00       ; 3
    .byte $00,$0F,$FF,$FF,$FF,$FF,$00,$00       ; 4    
    .byte $00,$00,$FF,$FF,$FF,$FF,$F0,$00       ; 5
    .byte $00,$00,$FF,$FF,$FF,$FF,$F0,$00       ; 6
    .byte $00,$00,$FF,$FF,$FF,$FF,$F0,$00       ; 7
    .byte $00,$00,$0F,$FF,$FF,$FF,$00,$00       ; 8
    .byte $00,$00,$FF,$FF,$FF,$FF,$F0,$00       ; 9
    .byte $00,$0F,$FF,$FF,$FF,$FF,$FF,$00       ; 10
    .byte $00,$0F,$FF,$FF,$FF,$FF,$FF,$00       ; 11
    .byte $00,$FF,$0F,$FF,$FF,$FF,$0F,$F0       ; 12
    .byte $00,$FF,$00,$FF,$FF,$F0,$0F,$F0       ; 13
    .byte $00,$F0,$00,$00,$F0,$00,$00,$F0       ; 14
    .byte $0F,$FF,$00,$0F,$FF,$00,$0F,$FF       ; 15




M160HI:
    .byte $00,$00,$01,$01,$02,$03,$03,$04,$05,$05,$06,$06,$07,$08,$08,$09,$0A,$0A,$0B,$0B,$0C,$0D,$0D,$0E,$0F,$0F,$10,$10,$11,$12,$12,$13,$14,$14,$15,$15,$16,$17,$17,$18,$19,$19,$1A,$1A,$1B,$1C,$1C,$1D,$1E,$1E,$1F,$1F,$20,$21,$21,$22,$23,$23,$24,$24,$25,$26,$26,$27,$28,$28,$29,$29,$2A,$2B,$2B,$2C,$2D,$2D,$2E,$2E,$2F
    .byte $30,$30,$31,$32,$32,$33,$33,$34,$35,$35,$36,$37,$37,$38,$38,$39,$3A,$3A,$3B,$3C,$3C,$3D,$3D,$3E,$3F,$3F,$40,$41,$41,$42,$42,$43,$44,$44,$45,$46,$46,$47,$47,$48,$49,$49,$4A,$4B,$4B,$4C,$4C,$4D,$4E,$4E,$4F,$50,$50,$51,$51,$52,$53,$53,$54,$55,$55,$56,$56,$57,$58,$58,$59,$5A,$5A,$5B,$5B,$5C,$5D,$5D,$5E,$5F,$5F
    .byte $60,$60,$61,$62,$62,$63,$64,$64,$65,$65,$66,$67,$67,$68,$69,$69,$6A,$6A,$6B,$6C,$6C,$6D,$6E,$6E,$6F,$6F,$70,$71,$71,$72,$73,$73,$74,$74,$75,$76,$76,$77,$78,$78,$79,$79,$7A,$7B,$7B,$7C,$7D,$7D,$7E,$7E,$7F,$80,$80,$81,$82,$82,$83,$83,$84,$85,$85,$86,$87,$87,$88,$88,$89,$8A,$8A,$8B,$8C,$8C,$8D,$8D,$8E,$8F,$8F
    .byte $90,$91,$91,$92,$92,$93,$94,$94,$95


M160LO:
    .byte $00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80
    .byte $20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0
    .byte $40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0,$60,$00,$A0,$40,$E0,$80,$20,$C0
    .byte $60,$00,$A0,$40,$E0,$80,$20,$C0,$60

