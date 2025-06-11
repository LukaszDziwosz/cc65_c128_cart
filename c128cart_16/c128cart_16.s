;
; Startup code for cc65 (C128 cartridge version)
;

    .export     _exit
    .export     __STARTUP__ : absolute = 1      ; Mark as startup
    .import     initlib, donelib
    .import     zerobss
    .import     callmain, pushax, _puts, _cgetc, _memcpy, push0
    .import     RESTOR, BSOUT, CLRCH
    .import     __RAM_START__, __RAM_SIZE__
    .import     __DATA_LOAD__, __DATA_RUN__, __DATA_SIZE__
    .importzp   ST

    .include    "zeropage.inc"
    .include    "c128.inc"

; ------------------------------------------------------------------------
; Constants

; $00 : Do not autostart ROM/cartridge, no BASIC.
; $01 : Autostart immediately using the cartridge cold-start vector.
; $FF : Autostart through BASIC cold-start sequence ($FF commonly used for >$01).

CART_MODE = $FF    ; Autostart flag for cartridge

; ------------------------------------------------------------------------
; Cartridge header and startup code

.segment "STARTUP"

startup:
    ; C128 cartridge header structure (must be at $8000)
    jmp     coldstart       ; Cold-start vector at $8000
    jmp     warmstart       ; Warm-start vector at $8003
    .byte   CART_MODE       ; Identifier byte at $8006
    .byte   $43,$42,$4D     ; "CBM" string at $8007-$8009

coldstart:
warmstart:
    ; Disable interrupts during setup
    sei
    ; Initialize stack
    ldx     #$FF
    txs
    cld

    ; Set up C128 processor ports (similar to C64 but C128 specific)
    lda #$e3
    sta $01
    lda #$37
    sta $00

    ; Before doing anything else, we have to set up our banking configuration.
    ; Otherwise, just the lowest 16K are actually RAM. Writing through the ROM
    ; to the underlying RAM works; but, it is bad style.

    lda     MMU_CR          ; Get current memory configuration...
    pha                     ; ...and save it for later
    
    ; Configure MMU for cartridge operation
    ; BIT 0   : $D000-$DFFF (0 = I/O Block)
    ; BIT 1   : $4000-$7FFF (1 = RAM)
    ; BIT 2/3 : $8000-$BFFF (10 = External ROM)
    ; BIT 4/5 : $C000-$CFFF/$E000-$FFFF (00 = Kernal ROM)
    ; BIT 6/7 : RAM used. (00 = RAM 0)
    lda #%00001010
    sta     MMU_CR

    ; Save the zero-page locations that we need.
    ldx     #zpspace-1
L1: lda     sp,x
    sta     zpsave,x
    dex
    bpl     L1

    ; Initialize BASIC system
    jsr     $FF8A           ; RESTOR - Restore Kernal Vectors
    jsr     $FF84           ; IOINIT - Init I/O Devices
    jsr     $FF81           ; CINT - Init Editor & Video Chips
    
    ; Clear channels
    jsr     CLRCH
    
    ; Clear the screen
    ; lda     #147            ; Clear screen character
    ; jsr     BSOUT
    
    ; Switch to second charset
    lda     #14
    jsr     BSOUT
    
    ; Clear BSS segment
    jsr     zerobss

    ; Save some system stuff; and, set up the stack.
    pla                     ; Get MMU setting
    sta     mmusave

    tsx
    stx     spsave          ; Save the system stack pointer
    
    ; Set up argument stack pointer
    lda    #<(__RAM_START__ + __RAM_SIZE__)
    sta sp
    lda #>(__RAM_START__ + __RAM_SIZE__)
    sta sp+1

    ; Copy initialized data from ROM to RAM
    lda #<__DATA_RUN__
    ldx #>__DATA_RUN__
    jsr pushax
    lda #<__DATA_LOAD__
    ldx #>__DATA_LOAD__
    jsr pushax
    lda #<__DATA_SIZE__
    ldx #>__DATA_SIZE__
    jsr _memcpy
    
    ; Call module constructors
    jsr     initlib
    
    ; Call main function
    jsr     callmain
    
    ; Fall through to exit

; ------------------------------------------------------------------------
; Exit routine

; Back from main() [this is also the exit() entry]. Run the module destructors.

_exit:
    pha                     ; Save the return code on stack
    jsr     donelib

    ; Copy back the zero-page stuff.
    ldx     #zpspace-1
L2: lda     zpsave,x
    sta     sp,x
    dex
    bpl     L2

    ; Place the program return code into BASIC's status variable.
    pla
    sta     ST

    ; Reset the stack and the memory configuration.
    ldx     spsave
    txs
    ldx     mmusave
    stx     MMU_CR

    ; Done.
    ; I currently cant find safe way to return to BASIC
    ; For now we will restart the program while I investigate, it could be CC65 issue
    jmp warmstart

    ; I tried it just finishes program execution
    ; jmp $FF71
   
    ; Same as above
    ; cli
    ; rts

    ; Also tried manually setup BASIC, the same :(
    ; Set up for BASIC in Bank 15
    ; lda #15
    ; sta $02        ; RAM Bank
    ; lda #$40
    ; sta $03        ; Start at $4000
    ; lda #$03
    ; sta $04
    ; lda #0
    ; sta $05
    ; sta $06
    ; sta $07
    ; sta $08
    ; cli
    ; jmp $FF71      ; C128 BASIC interpreter start

; ------------------------------------------------------------------------
; Data

.segment        "INIT"

zpsave: .res    zpspace

; ------------------------------------------------------------------------

.bss

spsave: .res    1
mmusave:.res    1
