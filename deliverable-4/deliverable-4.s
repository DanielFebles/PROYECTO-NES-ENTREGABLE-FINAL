; Setup constants to make code less redundant and more legible
OAMPAGE   = $0200           ; Page of memory that will be copied to OAM
PPUCTRL   = $2000           ; Writes PPU control flags
PPUMASK   = $2001           ; Writes PPU mask flags
PPUSTATUS = $2002           ; Reads PPU action flags and resets PPUADDR
OAMADDR   = $2003           ; Points to where in OAM we write to
PPUSCROLL = $2005           ; Handles where the PPU scroll lines are
PPUADDR   = $2006           ; Stores an address (hi then lo byte) to PPU
PPUDATA   = $2007           ; Writes data to and increments said PPUADDR
OAMDMA    = $4014           ; Receives address to transfer mempage to OAM
P1CONTROL = $4016           ; Latch address for player 1's controller

; Bytemapped player inputs (MUST FOLLOW A HASH [#], THESE ARE INSTANTS)
BTN_RIGHT = %00000001 
BTN_LEFT  = %00000010
BTN_DOWN  = %00000100
BTN_UP    = %00001000
BTN_START = %00010000
BTN_SELCT = %00100000
BTN_B     = %01000000
BTN_A     = %10000000



.segment "HEADER"
.byte $4E, $45, $53, $1A    ; iNES magic word
.byte $02                   ; Number of 16KB PRG-ROM banks
.byte $01                   ; Number of 8KB CHR-ROM banks
.byte %00000001             ; Vertical mirroring, no save RAM, no mapper
.byte %00000000             ; No special-case flags or mapper
.byte $00                   ; No PRG-RAM
.byte $00                   ; NTSC



.segment "ZEROPAGE"
player_x: .res 1            ; Player x-position
player_y: .res 1            ; Player y-position
player_d: .res 1            ; Player sprite offset for direction
player_s: .res 1            ; Player sprite offset for animation state
anim_cnt: .res 1            ; Animation count clock that player_s uses
p1_holds: .res 1            ; Bytes that deal with player 1's held inputs
p1_press: .res 1            ; Bytes that deal with player 1's press inputs
ppu_tile: .res 1            ; PPU tile to write onto the nametable
ppu_hibt: .res 1            ; High byte of the PPU offset to write to
ppu_lobt: .res 1            ; Low byte of the PPU offset to write to
t_offset: .res 1            ; Tile offset to use when getting the PPU tile
tilechnk: .res 1            ; Chunk of tiles being extracted for writing
scroll_x: .res 1            ; X-pos of the scroll line
screen_n: .res 1            ; Nametable screen to use
stages_n: .res 1            ; Which stage to load



.segment "RODATA"
; First set of palettes
palette_1:
.byte $0B, $30, $10, $00
.byte $0B, $10, $15, $07
.byte $0B, $35, $22, $04
.byte $0B, $37, $22, $1B
.byte $0B, $27, $14, $0F
.byte $0B, $27, $14, $0F
.byte $0B, $27, $14, $0F
.byte $0B, $27, $14, $0F
; Second set of palettes
palette_2:
.byte $0C, $30, $10, $00
.byte $0C, $32, $27, $06
.byte $0C, $37, $29, $18
.byte $0C, $34, $2B, $10
.byte $0C, $27, $14, $0F
.byte $0C, $27, $14, $0F
.byte $0C, $27, $14, $0F
.byte $0C, $27, $14, $0F
; The player's sprite data
; Each group is a direction and each subgroup of 4 is an animation frame
; Direction groups are ordered {Down, Up, Left, Right}
; Animation groups are ordered {Still, Right Leg Lean, Left Leg Lean}
sprites:
.byte $00, $02, %00100000, $00
.byte $00, $03, %00100000, $08
.byte $08, $12, %00100000, $00
.byte $08, $13, %00100000, $08
.byte $00, $00, %00100000, $00
.byte $00, $01, %00100000, $08
.byte $08, $10, %00100000, $00
.byte $08, $11, %00100000, $08
.byte $00, $00, %00100000, $00
.byte $00, $01, %00100000, $08
.byte $08, $14, %00100000, $00
.byte $08, $15, %00100000, $08

.byte $00, $06, %00100000, $00
.byte $00, $07, %00100000, $08
.byte $08, $16, %00100000, $00
.byte $08, $17, %00100000, $08
.byte $00, $08, %00100000, $00
.byte $00, $09, %00100000, $08
.byte $08, $04, %00100000, $00
.byte $08, $05, %00100000, $08
.byte $00, $08, %00100000, $00
.byte $00, $09, %00100000, $08
.byte $08, $18, %00100000, $00
.byte $08, $19, %00100000, $08
; NOTE: Sideways still frames have a dummy $FF sprite since they only use 3 sprites
.byte $00, $0C, %00100000, $00
.byte $00, $0D, %00100000, $08
.byte $08, $1C, %00100000, $04
.byte $08, $FF, %00100000, $08
.byte $00, $0A, %00100000, $00
.byte $00, $0B, %00100000, $08
.byte $08, $1A, %00100000, $00
.byte $08, $1B, %00100000, $08
.byte $00, $0A, %00100000, $00
.byte $00, $0B, %00100000, $08
.byte $08, $1E, %00100000, $00
.byte $08, $1F, %00100000, $08

.byte $00, $0D, %01100000, $00
.byte $00, $0C, %01100000, $08
.byte $08, $1D, %00100000, $04
.byte $08, $FF, %00100000, $08
.byte $00, $0B, %01100000, $00
.byte $00, $0A, %01100000, $08
.byte $08, $0E, %00100000, $00
.byte $08, $1E, %01100000, $08
.byte $00, $0B, %01100000, $00
.byte $00, $0A, %01100000, $08
.byte $08, $0F, %00100000, $00
.byte $08, $1A, %01100000, $08
; Map tiles, split into stages 1 and 2 respectively
stagetiles:
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101
.byte %01000011, %10111000, %00000000, %00111111, %00000010, %11111100, %10000000, %10111001
.byte %01101011, %10110000, %10101010, %10111011, %10101010, %11101110, %10001000, %00111101
.byte %01001011, %11111000, %00000000, %10111011, %00000010, %11111100, %00001010, %10100001
.byte %01001000, %10101010, %00101000, %10111111, %10100000, %00101000, %10111111, %00100001
.byte %01111111, %00001011, %11111000, %10001000, %00100010, %00100000, %10111011, %10100001
.byte %01101011, %10001011, %10110011, %10101010, %00100010, %00101010, %10111111, %10111101
.byte %01111111, %10101011, %11111011, %10110000, %00100000, %00001000, %10101000, %10101101
.byte %01001000, %10001010, %00101011, %11111000, %10100010, %10001000, %00000000, %11111101
.byte %01001000, %00001011, %11111010, %10101000, %10111111, %10001000, %10101010, %10100001
.byte %00001000, %10000011, %10110000, %00000000, %00111011, %00001000, %00001111, %10000000
.byte %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000

.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101
.byte %01001000, %00000010, %00100000, %10001111, %11001000, %00001000, %00111111, %00000001
.byte %01111010, %00101010, %00101000, %10101010, %10000000, %10101010, %00101010, %00100001
.byte %01111000, %00111111, %00111100, %10000000, %10100010, %10001000, %00000010, %00000001
.byte %01000000, %10100010, %00101000, %00001000, %00100000, %00001010, %10001010, %10101101
.byte %01001010, %10000010, %00001011, %10001010, %00100010, %11101000, %00001000, %00101101
.byte %01101000, %10001010, %10000011, %10101000, %11110010, %11100000, %10001000, %10101101
.byte %01000011, %10101000, %00001011, %10000000, %10100010, %11100010, %10001000, %00101101
.byte %01101011, %10001010, %00101000, %00001000, %00101010, %00000010, %00001010, %00101101
.byte %01001011, %00001000, %00001010, %10101010, %00100010, %10100010, %10000000, %00101101
.byte %00000000, %10000000, %10001111, %11111111, %00100011, %11110010, %00001000, %10100000
.byte %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.byte %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000



.segment "CODE"

.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  ; Copy mempage 2 into OAM on every interrupt
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA

  ; Read player input
  JSR p1_read

  ; OAM reads $00s as sprites so $FF the rest of it
  LDX #$00
oam_clean:
  LDA #$FF
  STA OAMPAGE, X
  INX
  CPX #$00
  BNE oam_clean

  ; Animate player (goes before draw_player since this updates the XY coords)
  JSR anim_player

  ; Animate player
  JSR draw_player

  ; Alternate stages on select, A or B button press
  LDA p1_press
  AND #%11100000
  BEQ stage_skip

  ; If any of the said buttons are pressed, disable PPU flags
  LDX #$00
  STX PPUCTRL
  LDX #%00000110
  STX PPUMASK

  ; Load second stage palette
  LDX #$3F
  STX PPUADDR
  LDX #$00
  STX PPUADDR
load_palette_2:
  LDA palette_2,X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palette_2

  ; Call drawing routine with given parameters then reenable PPUMASK
  LDA #$01
  STA stages_n
  LDA #$00
  STA ppu_hibt
  STA ppu_lobt
  JSR draw_screens
  LDA #%00011110
  STA PPUMASK
stage_skip:
  
  ; Update PPUSCROLL based on player position
  LDX scroll_x
  STX PPUSCROLL
  LDX #$00
  STX PPUSCROLL

  ; Determine on which screen to load the player on
  LDA screen_n
  LSR A
  LDA #%01001000
  ROL A
  STA PPUCTRL

  RTI
.endproc

.proc reset_handler
  ; Ignore random IRQs then clear useless BCD logic
  SEI
  CLD
  
  ; Disable audio IRQs
  LDX #$40
  STX $4017

  ; Set up the stack
  LDX #$FF
  TXS

  ; FF -> 00 to clear CTRL and MASK
  INX
  STX PPUCTRL
  STX PPUMASK
  STX $4010

  ; Wait for PPU to fully boot
  BIT PPUSTATUS
vblankwait:
  BIT PPUSTATUS
  BPL vblankwait
vblankwait2:
  BIT PPUSTATUS
  BPL vblankwait2

  ; Set defaults for all the variables
  LDA #$00
  STA player_x
  LDA #$BF
  STA player_y
  LDA #$00
  STA player_d
  STA player_s
  STA anim_cnt
  STA p1_holds
  STA p1_press
  STA ppu_tile
  STA ppu_hibt
  STA ppu_lobt
  STA t_offset
  STA tilechnk
  STA scroll_x
  STA screen_n
  STA stages_n

  JMP main
.endproc

.proc main
  ; Clear PPUADDR
  LDX PPUSTATUS

  ; Load palette table
  LDX #$3F
  STX PPUADDR
  LDX #$00
  STX PPUADDR
load_palette_1:
  LDA palette_1,X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palette_1

  ; Draw the first level
  LDA #$00
  STA stages_n
  STA ppu_hibt
  STA ppu_lobt
  JSR draw_screens

  ; Fix PPUSCROLL because PPUADDR is borked and uses the same registers
  LDX #$00
  STX PPUSCROLL
  STX PPUSCROLL

  ; Wait for PPU to boot again
vblankwait:
  BIT PPUSTATUS
  BPL vblankwait

  ; Initiate both control and mask flags
  LDA #%10010000
  STA PPUCTRL
  LDA #%00011110
  STA PPUMASK

forever:
  JMP forever
.endproc

; Draws four successive sprites from the player's sprite table
; Parameters include position (player_x, player_y), direction (player_d),
; and animation state (player_s)
.proc draw_player
  ; Stack push
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; Initialize counter, then load player direction and add animation state
  LDX #$00
  LDA player_d
  CLC
  ADC player_s
  TAY
load_sprites:
  ; Add player y-coord to the sprite y-coord
  LDA sprites, Y
  CLC
  ADC player_y
  STA OAMPAGE, X
  INY
  INX

  ; Sprite ID
  LDA sprites, Y
  STA OAMPAGE, X
  INY
  INX

  ; Sprite flags
  LDA sprites, Y
  STA OAMPAGE, X
  INY
  INX

  ; Add player x-coord to the sprite x-coord
  LDA sprites, Y
  CLC
  ADC player_x
  STA OAMPAGE, X
  INY
  INX

  ; Have we written four sprites? If not, continue loop
  CPX #$10
  BNE load_sprites

  ; Stack pull
  PLA
  TYA
  PLA
  TXA
  PLA
  PLP
  RTS
.endproc

; Handles both player movement and animation
; Parameters include position (player_x, player_y), direction (player_d),
; animation state (player_s), buttons (p1_holds, p1_press) and a clock
; (anim_cnt)
.proc anim_player
  ; Stack push
  PHP
  PHA

  ; Create a pause function with the highest bit of the animation counter
  LDA p1_press
  AND #BTN_START
  BEQ pause_check
  LDA anim_cnt
  EOR #%10000000
  STA anim_cnt

  ; Ignores player inputs and freezes animations if paused (too big to just branch)
pause_check:
  LDA anim_cnt
  AND #%10000000
  BEQ right_check
  JMP end

  ; Check each of the button inputs, starting with right
  ; Depending on button input, change player direction and xy coords
  ; If player is on the centerline, it will change scroll coord instead
right_check:
  LDA p1_holds
  AND #BTN_RIGHT
  BEQ left_check
  LDA #$90
  STA player_d
  LDA #$78
  CMP player_x
  BEQ right_scroll
right_move:
  LDA #$F0
  CMP player_x
  BEQ left_check
  INC player_x
  JMP end_check
left_check:
  LDA p1_holds
  AND #BTN_LEFT
  BEQ down_check
  LDA #$60
  STA player_d
  LDA #$78
  CMP player_x
  BEQ left_scroll
left_move:
  LDA #$00
  CMP player_x
  BEQ down_check
  DEC player_x
  JMP end_check
down_check:
  LDA p1_holds
  AND #BTN_DOWN
  BEQ up_check
  LDA #$00
  STA player_d
  LDA #$D7
  CMP player_y
  BEQ end_check
  INC player_y
  JMP end_check
up_check:
  LDA p1_holds
  AND #BTN_UP
  BEQ end_check
  LDA #$30
  STA player_d
  LDA #$07
  CMP player_y
  BEQ end_check
  DEC player_y
  JMP end_check
right_scroll:
  LDA #$01
  CMP screen_n
  BEQ right_move
  INC scroll_x
  LDA #$00
  CMP scroll_x
  BNE end_check
  INC screen_n
  JMP end_check
left_scroll:
  LDA #$00
  ORA screen_n
  CMP scroll_x
  BEQ left_move
  DEC scroll_x
  LDA #$FF
  CMP scroll_x
  BNE end_check
  DEC screen_n
  JMP end_check
end_check:

  ; Ignore animation procedure and reset counter if no direction is being held
  LDA p1_holds
  AND #%00001111
  BEQ cnt_reset

  ; Increase then load animation counter
  INC anim_cnt
  LDA anim_cnt

  ; Compare counter to four possible states
  CMP #$10
  BCC frame_right
  CMP #$20
  BCC frame_mid
  CMP #$30
  BCC frame_left
  CMP #$40
  BCC frame_mid

  ; Reset counter if it reaches 40 or player isn't pressing any directions
cnt_reset:
  LDA #$00
  STA anim_cnt
  JMP frame_mid

  ; Load corresponding frame then store to player animation state
frame_right:
  LDA #$10
  JMP store_frame
frame_left:
  LDA #$20
  JMP store_frame
frame_mid:
  LDA #$00
store_frame:
  STA player_s
end:

  ; Stack pull
  PLA
  PLP
  RTS
.endproc

; Gets player 1's inputs, whether it'd be a button press or hold
; Parameters include buttons (p1_press, p1_holds)
.proc p1_read
  ; Stack push
  PHP
  PHA

  ; Copy the prior frame's player inputs to press variable
  LDA p1_holds
  STA p1_press

  ; Activate player 1's latch
  LDA #$01
  STA P1CONTROL
  LDA #$00
  STA P1CONTROL

  ; Initiate shift
  LDA #%00000001
  STA p1_holds

  ; Loop until we get all button inputs
get_buttons:
  LDA P1CONTROL
  LSR A
  ROL p1_holds
  BCC get_buttons

  ; Isolate the buttons that were newly pressed and store into press variable
  LDA p1_press
  EOR p1_holds
  AND p1_holds
  STA p1_press

  ; Stack pull
  PLA
  PLP
  RTS
.endproc

; Renders both screens of the nametable, based on which stage the player is on
; Parameters include stage (stages_n), tile manipulators (t_offset, tilechnk),
; and PPU values (ppu_hibt, ppu_lobt, ppu_tile)
.proc draw_screens
  ; Stack push
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; Shift stage number accordingly to get correct offset
  LSR stages_n
  ROR stages_n

  ; Change offset of tile IDs depending on which stage we're writing to
  LDX #$00
  LDY #$00
  LDA #$04
  STA t_offset
  LDA stages_n
  CMP #$00
  BEQ byte_loop
  ASL t_offset

  ; Firstly, offset counter with stage offset
byte_loop:
  TXA
  CLC
  ADC stages_n 
  TAX

  ; Now load the first byte chunk to cycle through and store it in tilechnk
  LDA stagetiles, X
  STA tilechnk

  ; Clear accumulator and bitshift two bits of the tile chunk into it
chunk_loop:
  LDA #$00
  ASL tilechnk
  ROL A
  ASL tilechnk
  ROL A

  ; Add the tile ID offset before storing it in ppu_tile and draw the metatile
  CLC
  ADC t_offset
  STA ppu_tile
  JSR draw_metatile

  ; With our metatile written, adjust ppu_lobt and Y-reg as necessary
  INC ppu_lobt
  INC ppu_lobt
  INY

  ; Check if the entire chunk has been iterated through (4 blocks per chunk)
  CPY #$04
  BNE chunk_loop

  ; Reset Y-reg, and check if the low bit has reached the next row
  LDY #$00
  LDA ppu_lobt
  AND #%00100000
  BEQ sum_skip

  ; Skip that row since draw_metatile already drew on it
  LDA ppu_lobt
  CLC
  ADC #$20
  STA ppu_lobt

  ; If there was a carry, then store it into ppu_hibt
  LDA ppu_hibt
  ADC #$00
  STA ppu_hibt

  ; Finally, skip the next four bytes
  INX
  INX
  INX
  INX
sum_skip:

  ; Increase the byte counter and subtract the stage offset
  INX
  TXA
  SEC
  SBC stages_n
  TAX

  ; Branch to end if we've gone through both screens
  CPX #$7C
  BEQ end

  ; Branch to the byte loop, unless we're done with the first screen
  CPX #$78
  BNE byte_loop

  ; If done with first screen, set counter and PPU offsets to second screen and jump
  LDX #$04
  STX ppu_hibt
  LDA #$00
  STA ppu_lobt
  JMP byte_loop
end:

  ; After drawing both screens, end it off by drawing attributes
  JSR draw_attributes

  ; Correct stage number
  ASL stages_n
  ROL stages_n

  ; Stack pull
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

; Subroutine of draw_screens that draws a metatile on the given coord
; Parameters include PPU values (ppu_hibt, ppu_lobt, ppu_tile)
.proc draw_metatile
  ; Stack push
  PHP
  PHA
  TXA
  PHA

  ; Setup and draw first row of the metatile with PPU offsets
  LDA PPUSTATUS
  LDA #$20
  CLC 
  ADC ppu_hibt
  STA PPUADDR
  LDA #$00
  CLC 
  ADC ppu_lobt
  STA PPUADDR
  LDX #$00

loop:
  ; Load PPU tile and write it twice
  LDA ppu_tile
  STA PPUDATA
  STA PPUDATA

  ; Did we just draw the second row?
  CPX #$01
  BEQ end

  ; If not, setup and draw second row of the metatile
  INX
  LDA PPUSTATUS
  LDA #$20
  CLC 
  ADC ppu_hibt
  STA PPUADDR
  LDA #$20
  CLC 
  ADC ppu_lobt
  STA PPUADDR
  JMP loop
end:

  ; Stack pull
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

; Subroutine of draw_screens that converts screen data into an attribute table
; Parameters include stage (stages_n) and tile manipulators (tilechnk)
.proc draw_attributes
  ; Stack push
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; Initiate PPU address to attribute section and initiate counter
  LDA PPUSTATUS
  LDA #$23
  STA PPUADDR
  LDA #$C0
  STA PPUADDR
  LDX #$00

byte_loop:
  ; Offset counter with stage offset and reset accumulator
  TXA
  CLC
  ADC stages_n 
  TAX

  ; Store the current byte into tilechnk
  LDY stagetiles, X
  STY tilechnk

  ; Do a series of rotates to extract the first attribute's lonibble
  LDA #$00
  ROL tilechnk
  ROL tilechnk
  ROR A
  ROR tilechnk
  ROR A
  ROL tilechnk
  ROL tilechnk
  ROL tilechnk
  ROR A
  ROR tilechnk
  ROR A

  ; Offset counter to the tilechnk below the current one
  INX
  INX
  INX
  INX
  INX
  INX
  INX
  INX

  ; Repeat rotates to extract the first attribute's hinibble
  LDY stagetiles, X
  STY tilechnk
  ROL tilechnk
  ROL tilechnk
  ROR A
  ROR tilechnk
  ROR A
  ROL tilechnk
  ROL tilechnk
  ROL tilechnk
  ROR A
  ROR tilechnk
  ROR A

  ; Return to the original tilechnk we were just on
  DEX
  DEX
  DEX
  DEX
  DEX
  DEX
  DEX
  DEX
  
  ; Store extracted attribute to PPUDATA, then reset accumulator
  STA PPUDATA
  LDA #$00

  ; Another series of rotates, this time for the second attribute's lonibble
  LDY stagetiles, X
  STY tilechnk
  ROR tilechnk
  ROR tilechnk
  ROR tilechnk
  ROR A
  ROR tilechnk
  ROR A
  ROL tilechnk
  ROL tilechnk
  ROL tilechnk
  ROR A
  ROR tilechnk
  ROR A

  ; Offset counter again
  INX
  INX
  INX
  INX
  INX
  INX
  INX
  INX

  ; Repeat rotates again to extract the second attribute's hinibble
  LDY stagetiles, X
  STY tilechnk
  ROR tilechnk
  ROR tilechnk
  ROR tilechnk
  ROR A
  ROR tilechnk
  ROR A
  ROL tilechnk
  ROL tilechnk
  ROL tilechnk
  ROR A
  ROR tilechnk
  ROR A

  ; Reduce offset once more
  DEX
  DEX
  DEX
  DEX
  DEX
  DEX
  DEX
  DEX

  ; Store second attribute to PPUDATA
  STA PPUDATA

  ; Store the prior counter, increase the counter and remove stage offset
  TXA
  AND #%00000100
  STA tilechnk
  INX
  TXA
  SEC
  SBC stages_n
  TAX

  ; Check if this is the end of a screen row and add accordingly
  AND #%00000100
  CMP tilechnk
  BEQ counter_checks
  TXA
  CLC
  ADC #$0C
  TAX

counter_checks:
  ; If we have written to both screens, end subroutine
  CPX #$84
  BEQ end

  ; Check the next byte of the loop unless we finished the first screen
  CPX #$80
  BNE byte_loop_jump
  
  ; Set counter and PPUADDR to the second screen before returning to loop
  LDX #$04
  LDA PPUSTATUS
  LDA #$27
  STA PPUADDR
  LDA #$C0
  STA PPUADDR
byte_loop_jump:
  JMP byte_loop
end:

  ; Stack pull
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc



; Setup interrupt vector addresses at the end of the PRG-ROM, CHR-ROM and startup
.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler
.segment "CHARS"
.incbin "sprites.chr"
.segment "STARTUP"
