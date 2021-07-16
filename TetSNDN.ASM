;=============================================================================================
;=============This is my variant of famous tetris game on fasm================================
;=============================================================================================
;===================made by  Artiom Drankevich================================================
;===================artem.drankevich@gmail.com================================================
;=============================================================================================
;============================2021=============================================================
;=============================================================================================
;=============================================================================================       
		
		
		
		include 'macro\proc16.inc'

        org     100h

        FIELD_W = 12; 12
        FIELD_H = 23

        BLOCK_W = 7

        TRUE    = 1
        FALSE   = 0

        START_TICK_SPEED  = 10

        INC_EVERY_FIGS    = 31;31; power of 2 - 1

        ; general info about blocks colors
        ; $20 - $3F -- general color
        ; 1A - border color


EntryPoint:
        ; save video mode
        mov     ah, 0Fh
        int     10h

        mov     [bVideoMode], al
        mov     [bVideoPage], bh

        ; set videomode
        mov     ax, 0013h; 03h; add переменная с смещением процедуры д/текущего граф режима
        int     10h

        ; setup videoseg
        mov     ax, cs
        add     ax, 1000h
        mov     [Screen.Segment], ax

GameStart:
        ; setup game
        call    Game.Initialize
        stdcall SoundPlayer.Initialize


        ; setup main timer
        xor     ax, ax
        int     1ah; got cur time in dx (18 ticks)
        mov     [timerCounter], dx

GameLoop:
        xor     ax, ax
        int     1ah; got cur time in cx:dx (18 ticks)

        cmp     [timerCounter], dx
        je      GameLoop
        ; passed -- do game update
        mov     [timerCounter], dx ; save new time tick

        ; check game status
        cmp     [Game.Playing], TRUE
        je      Exit

        ; read control key to cx
        xor     cx, cx  ; key expected in cx

        mov     ah, 06h; read  key
        mov     dl, 0ffh
        int     21h

        mov     cl, al

        cmp     al, 0
        jne     @F

        mov     ah, 06h; read extended key
        mov     dl, 0ffh
        int     21h

        mov     ch, al
@@:

        ; check on controls
        cmp     cx, KEY_ESCAPE
        je      Exit

        cmp     cx, 'p' ; pause clicked
        jne     @F
        xor     [Game.Pause], 1; PAUSE
        ;stdcall SoundPlayer.Stop; stop sound
@@:
        cmp     [Game.Pause], 0; exit loop on pause
        jne     GameLoop

        ; play sound
        mov     ax, [Game.CurSoundTick]
        inc     ax
        cmp     ax, 4
        jl      @F
        mov     [Game.CurSoundTick], dx
        xor      ax, ax
        stdcall SoundPlayer.PlayNext
@@:
        mov     [Game.CurSoundTick], ax


;#######; check game status update (THIS PART IS FOR USER CHECKING)

        ; game controls

        ; mk moves
        ; 1st -- save initial state
        mov     si, [Game.FigX]
        mov     bx, [Game.CurFigNumber]
        shl     bx, 2; bc figs are stored as 2 bytes * 4 states
        mov     dx, [Game.CurFigRotation]

        ; decode key (cx) and apply x cord changes
        cmp     cx, KEY_UP  ; rotation
        jne     @F
        inc     dx
        and     dx, 0000'0000'0000'0011b
@@:
        cmp     cx, KEY_DOWN ; rotation
        jne     @F
        dec     dx
        and     dx, 0000'0000'0000'0011b
@@:
        cmp     cx, KEY_LEFT
        jne     @F
        dec     si
@@:
        cmp     cx, KEY_RIGHT
        jne     @F
        inc     si
@@:
        add     bx, dx ; apply rotation
        shl     bx, 1  ; each fig is 2 bytes long
        mov     bx, [figArr + bx] ; is cur figure

        ; speed up on space
        cmp     cx, ' '
        jne     @F ; if space pressed

        ; go down loop
        mov     di, [Game.FigY] ; initial
.GoDownLoop:
        inc     di

        ; check on collision
        stdcall Game.CollideFigure, bx, [Game.FigX], di
        test    ax, ax
        jz      .GoDownLoop

        dec     di
        mov     [Game.FigY], di
        jmp     .Collided
@@:
        ; collision
        stdcall Game.CollideFigure, bx, si, [Game.FigY]
        test    ax, ax
        jnz     @F; ignore changes if collided
        mov     [Game.FigX], si ; not collided
        mov     [Game.CurFig], bx
        mov     [Game.CurFigRotation], dx
@@:

;#######; check game status update (THIS PART IS FOR EVENT CHECKING)
        dec     [Game.CurTick]
        cmp     [Game.CurTick], 0
        jg      .UpdateView; exit + dec cur tick

        ; restart timer
        mov     ax, [Game.TickSpeed]
        mov     [Game.CurTick], ax

        ; load initial state of figure
        mov     bx, [Game.CurFig]
        ; draw fig preview
        stdcall View.DrawFigure, bx, [Game.FigX], di, $0A ;fig, x, y, color
        ; load initial Y
        mov     di, [Game.FigY]

        ; mk changes
        inc     di

        ; check on collision
        stdcall Game.CollideFigure, bx, [Game.FigX], di
        test    ax, ax
        jnz     .Collided
        ; regular
        mov     [Game.FigY], di

        jmp     .UpdateView

.Collided:
        ; 1st -- place cur fig to field
        stdcall Game.PlaceFigure, bx, [Game.FigX], [Game.FigY], [Game.CurFigColor]
        mov     bx, [Game.NextFig] ; change cur fig to next
        mov     [Game.CurFig], bx

        mov     bx, [Game.NextFigNumber]; same with its number
        mov     [Game.CurFigNumber], bx

        ; play sound
        ;stdcall SoundPlayer.PlaySingle

        ; gen new figure and draw it
        stdcall Random.Get, $20, $3F
        mov     [Game.CurFigColor], ax
        mov     [Game.FigX], FIELD_W/2-2
        mov     [Game.FigY], 0
        mov     [Game.CurFigRotation], 0

        stdcall Random.Get, 0, [figNum]
        mov     [Game.NextFigNumber], ax
        mov     bx, ax
        shl     bx, 3 ; 3
        mov     ax, [figArr + bx]
        mov     [Game.NextFig], ax

        ;draw next fig
        stdcall View.DrawFigure, $FFFF, (FIELD_W + 3), 1, $00 ;fig, x, y, color
        stdcall View.DrawFigure, [Game.NextFig], (FIELD_W + 3), 1, $0C ;fig, x, y, color

        ; inc counts of figure
        inc     [Game.FigsPlaced]
        ; encount new speed
        test    [Game.FigsPlaced], INC_EVERY_FIGS; 111; every 16 figs
        jnz     @F
        fild    [Game.TickSpeed]
        fld     [Game.SpeedMul]
        fmul    st1, st0
        fistp   [Game.TickSpeed]
        fistp   [Game.TickSpeed]
@@:
        ; ---check game is valid---------------
        stdcall Game.CheckOnLine; check on full lines completed
        stdcall Game.CheckOnEnd; result in ax
        mov     [Game.Playing], ax

.UpdateView:
        ; update View
        stdcall View.DrawField

        ; GET PREVIEW
        ; go down loop
        mov     di, [Game.FigY]
        mov     bx, [Game.CurFig]
.GoDownLoopB:
        inc     di

        ; check on collision
        stdcall Game.CollideFigure, bx, [Game.FigX], di
        test    ax, ax
        jz      .GoDownLoopB

        dec     di
        stdcall View.DrawFigure, bx, [Game.FigX], di, $15 ;fig, x, y, color
        ; DRAW cur fig
        stdcall View.DrawFigure, bx, [Game.FigX], [Game.FigY], [Game.CurFigColor] ;fig, x, y, color

        ; update full screen
        stdcall Screen.Update

        ; repeat cycle
        jmp     GameLoop

;#######; Exit from programm
Exit:
        stdcall Screen.WriteStr.Mode13h, (FIELD_W / 2 * BLOCK_W - 5 * 5), BLOCK_W*2, Game.OverStr, $1F, alCustom
        stdcall SoundPlayer.Stop

        ; check score if new high
        mov     ax, [Game.Score]
        cmp     ax, [Settings.strHighScore]
        jle     @F
        ; set and display new high
        mov     [Settings.strHighScore], ax
        push    0
        push    ax
        stdcall Settings.SetHigh
        ;push    0
        ;push    ax
        push    Game.HighStrEnd
        call    DecimalWrite.ExtMem
        stdcall Screen.DrawRect, FIELD_W*(BLOCK_W+1)+30, 100, 20*5, 5, $00
        stdcall Screen.WriteStr.Mode13h, FIELD_W*(BLOCK_W+1)+30, 100, Game.HighStr, $1F, alCustom
@@:
        ; update full screen
        stdcall Screen.Update
@@:
        call    Keyboard.ReadKey; wait for exit key
        cmp     ax, 'p' ; restart game
        je      GameStart
        cmp     ax, KEY_ESCAPE
        jne     @B

        ; restore videomode
        movzx   ax, [bVideoMode]
        int     10h

        mov     ah, $05
        mov     al, [bVideoPage]
        int     10h

        ret


;========Game model==============
Game.CurFig             dw      ?
Game.CurFigColor        dw      ?
Game.CurFigRotation     dw      ?
Game.CurFigNumber       dw      ?
Game.NextFig            dw      ?
Game.NextFigNumber      dw      ?
Game.FigX               dw      ?
Game.FigY               dw      ?
Game.TickSpeed          dw      ?
Game.CurTick            dw      ?
Game.Score              dw      ?
Game.Playing            dw      ?
Game.Pause              dw      ?
Game.FigsPlaced         dw      ?
Game.CurSoundTick       dw      ?

Game.FigLowY            dw      ?

Game.OverStr            db      10, 'Game over!'
Game.NextStr            db      12, 'Next figure '
Game.C1                 db      8, 'Controls'
Game.C2                 db      19, 'ESC    - leave game'
Game.C3                 db      24, 'P      - pause/continue game'
Game.C4                 db      21, 'P      - restart game'
Game.C5                 db      23, 'ARROWS - figure control'
Game.C6                 db      24, 'SPACE  - forse push down'
Game.ScoreStr           db      15, 'Your score ',?,?,?
Game.ScoreStrEnd        db      0
Game.HighStr            db      15, 'High score ',?,?,?
Game.HighStrEnd         db      0

Game.UserNameLen        db      20
Game.UserName           db      ?, 20 dup ?

Game.SpeedMul           dd      0.87;0___0111'1110___110'1000_0000'0000_0000'0000b; 0.9062  0.89

;#############CHECK ON END OF GAME ####################
; - rets TRUE in ax if game ends
proc Game.CheckOnEnd uses bx cx

        xor     ax, ax

        mov     cx, FIELD_W - 2
        mov     bx, FIELD_W * 3 + 1; from 3rd line
.CheckLoop:
        cmp     byte [bx + blocksArr], 0
        je      @F
        mov     ax, TRUE
        jmp     .EndProc
@@:
        inc     bx
        loop    .CheckLoop
.EndProc:
        ret
endp

;#############CHECK ON FULL LINES AND ENCOUNT SCORE ####################
proc Game.CheckOnLine uses dx bx cx

        xor     ax, ax
        mov     bx, 1
        mov     cx, FIELD_H - 1
.CheckLoop:
        push    cx
        push    bx

        mov     cx, FIELD_W - 2
.InnerCheckLoop:
        cmp     byte [bx + blocksArr], 0
        je      .skipLine

        inc     bx
        loop    .InnerCheckLoop
        ; if non skipped -- rm line

        sub     bx, FIELD_W
        mov     cx, bx
.RmLineLoop:
        mov     dx, [bx + blocksArr]
        cmp     dx, $1A; check if it is border block
        je      @F
        mov     [bx + blocksArr + FIELD_W], dx
@@:
        dec     bx
        loop    .RmLineLoop
        ; rm line end
        inc     ax; add score

.skipLine:
        pop     bx
        add     bx, FIELD_W

        pop     cx
        loop    .CheckLoop
 ; END LOOP
        test    ax, ax  ; add score
        jz      .EndProc

        mov     cx, 2   ; count
        xchg    ax, cx
        shl     ax, cl
        dec     ax
        shl     ax, 2

        add     [Game.Score], ax ; add

        push    0
        push    [Game.Score]; SCORE
        push    Game.ScoreStrEnd
        call    DecimalWrite.ExtMem
        stdcall Screen.DrawRect, FIELD_W*(BLOCK_W+1)+30, 90, 20*5, 5, $00
        stdcall Screen.WriteStr.Mode13h, FIELD_W*(BLOCK_W+1)+30, 90, Game.ScoreStr, $1F, alCustom

.EndProc:
        ret
endp


;#############MOVES FIGURE TO FIELD ARRAY ####################
; - fig   -- 2 bytes figure
; - x     -- x cord
; - y     -- y cord
; - color -- fig color
proc Game.PlaceFigure uses bx cx si,\
     fig, x, y, color

        mov     ax, FIELD_W
        mul     byte [y]
        add     ax, [x]
        mov     bx, ax

        mov     si, [fig]
        mov     ax, [color]

        mov     cx, 16

        ; inner loop -- draw line of matrix
.DrawLoop:
        shl     si, 1
        jae     @F ; CF = 0 => exit
        ; paste figure
        mov     [bx + blocksArr], al
@@:
        add     bx, 1; setup cords
        dec     cx
        test    cx, 0000'0000'0000'0011b; if % 4 => move to next line
        jnz     @F
        add     bx, FIELD_W - 4
@@:
        inc     cx
        loop    .DrawLoop

        ret
endp

;#############CHECK ON COLLISION####################
; - fig   -- 2 bytes figure
; - x     -- x cord
; - y     -- y cord
proc Game.CollideFigure uses bx cx si,\
     fig, x, y
        ; prep cords
        mov     ax, FIELD_W
        mul     byte [y]
        add     ax, [x]
        mov     bx, ax

        mov     si, [fig]
        xor     ax, ax

        mov     cx, 16

        ; inner loop -- draw line of matrix
.DrawLoop:
        shl     si, 1
        jae     @F ; CF = 0 => exit
        ; check collision
        cmp     byte [bx + blocksArr], 0
        jne     .Collided
@@:
        add     bx, 1; setup cords
        dec     cx
        test    cx, 0000'0000'0000'0011b
        jnz     @F
        add     bx, FIELD_W - 4
@@:
        inc     cx
        loop    .DrawLoop

        jmp     .EndProc
.Collided:
        mov     ax, TRUE
.EndProc:
        ret
endp



;#############GAME INITIALIZATION####################
proc Game.Initialize

        call    Random.Initialize

        ; clear screen
        stdcall Screen.Clear.Mode13h

        ; clear field
        mov     si, blocksArrCopy
        mov     di, blocksArr
        mov     cx, FIELD_W*FIELD_H
        rep movsb

        ; write score
        mov     word [Game.ScoreStrEnd - 3], $0000; clear string for score
        mov     word [Game.ScoreStrEnd - 1], $0000

        mov     [Game.Score], 0; set score to 0
        push    0
        push    [Game.Score]
        push    Game.ScoreStrEnd
        call    DecimalWrite.ExtMem
        stdcall Screen.DrawRect, FIELD_W*(BLOCK_W+1)+30, 90, 20*5, 5, $00
        stdcall Screen.WriteStr.Mode13h, FIELD_W*(BLOCK_W+1)+30, 90, Game.ScoreStr, $1F, alCustom

        ; write high scoree
        stdcall Settings.GetHigh
        push    0
        push    ax
        push    Game.HighStrEnd
        call    DecimalWrite.ExtMem
        stdcall Screen.WriteStr.Mode13h, FIELD_W*(BLOCK_W+1)+30, 100, Game.HighStr, $1F, alCustom
        ; write info str
        stdcall Screen.WriteStr.Mode13h, FIELD_W*(BLOCK_W+1)+30, 8, Game.NextStr, $1F, alCustom
        stdcall Screen.WriteStr.Mode13h, FIELD_W*(BLOCK_W+1)+30, 120, Game.C1, $1F, alCustom
        stdcall Screen.WriteStr.Mode13h, FIELD_W*(BLOCK_W+1)+30, 130, Game.C2, $1F, alCustom
        stdcall Screen.WriteStr.Mode13h, FIELD_W*(BLOCK_W+1)+30, 140, Game.C3, $1F, alCustom
        stdcall Screen.WriteStr.Mode13h, FIELD_W*(BLOCK_W+1)+30, 150, Game.C4, $1F, alCustom
        stdcall Screen.WriteStr.Mode13h, FIELD_W*(BLOCK_W+1)+30, 160, Game.C5, $1F, alCustom
        stdcall Screen.WriteStr.Mode13h, FIELD_W*(BLOCK_W+1)+30, 170, Game.C6, $1F, alCustom

        stdcall View.DrawField

        ; setup
        mov     [Game.FigX], FIELD_W/2-2
        mov     [Game.FigY], 0
        mov     [Game.CurFigRotation], 0

        stdcall Random.Get, 0, [figNum]
        mov     [Game.CurFigNumber], ax
        mov     bx, ax
        shl     bx, 3
        mov     ax, [figArr + bx]
        mov     [Game.CurFig], ax

        stdcall Random.Get, 0, [figNum]
        mov     [Game.NextFigNumber], ax
        mov     bx, ax
        shl     bx, 3
        mov     ax, [figArr + bx]
        mov     [Game.NextFig], ax
        stdcall View.DrawFigure, [Game.NextFig], (FIELD_W + 3), 1, $0C ;fig, x, y, color

        mov     [Game.CurFigColor], $2A
        mov     [Game.Score], 0

        mov     [Game.CurTick], START_TICK_SPEED
        mov     [Game.TickSpeed], START_TICK_SPEED
        mov     [Game.Pause], TRUE;
        mov     [Game.Playing], 0

        mov     [Game.CurSoundTick], 0

        mov     [Game.FigLowY], 0

        fld     [Game.SpeedMul]

        ; update screen
        stdcall Screen.Update

        ret
endp



;#############DRAW FIGURE####################
; - fig    -- 2 bytes fig data
; - x,y    -- x,y cord
proc View.DrawFigure uses bx cx si di dx,\ ; ax si di bx cx
     fig, x, y, color

        mov     ax, BLOCK_W+1
        mul     [x]
        mov     si, ax
        add     si, BLOCK_W+1

        mov     ax, BLOCK_W+1
        mul     [y]
        mov     di, ax
        add     di, BLOCK_W+1

        mov     bx, [fig]
        mov     ax, [color]

        mov     cx, 16

        ; inner loop -- draw line of matrix
.DrawLoop:
        shl     bx, 1
        jae     @F ; CF = 0 => exit
        stdcall Screen.DrawRect, si, di, BLOCK_W, BLOCK_W, ax
@@:
        add     si, BLOCK_W+1; setup cords
        dec     cx
        test    cx, 0000'0000'0000'0011b
        jnz     @F
        sub     si, (BLOCK_W+1)*4
        add     di, (BLOCK_W+1)
@@:
        inc     cx
        loop    .DrawLoop

        ret
endp

;#############DRAW FIELD####################
proc    View.DrawField uses cx bx dx

        mov     cx, FIELD_H*(BLOCK_W+1)
        mov     bx, FIELD_H*FIELD_W-1

DrawLoopW:
        mov     dx, FIELD_W*(BLOCK_W+1)
; innnr start
.DrawLoopH:
        movzx   ax, [blocksArr + bx]
        ;test    al, al
        ;jz      @F
        stdcall Screen.DrawRect, dx, cx, BLOCK_W, BLOCK_W, ax
;@@:
        dec     bx
        sub     dx, BLOCK_W+1
        test    dx, dx
        jnz     .DrawLoopH
; inner end
        sub     cx, BLOCK_W+1
        test    cx, cx
        jnz     DrawLoopW

        ret
endp


;#############GET HIGH SCORE####################
; high score in ax
proc Settings.GetHigh uses dx cx bx

        ; readfile
        ; load file
        mov     dx, Settings.strFilename
        mov     ax, 3d'02h; readwrite mode
        int     21h
        jc      .EndProc

        ; save file handler
        ;mov     [Settings.wFileHandler], ax
        mov     bx, ax; bx - file handle: readwrite mode

        mov     ah, 3fh
        mov     cx, 2; 2 bytes
        mov     dx, Settings.strHighScore
        int     21h
        jc      .EndProc

        mov     ah, 3eh ; close file
        int     21h
        jc      .EndProc

        mov     ax, [Settings.strHighScore]
        jmp     @F ; skip reset score
.EndProc:
        xor     ax, ax
@@:
        ret
endp

;#############SET HIGH SCORE####################
; high score in ax
proc Settings.SetHigh uses dx cx bx

        ; load file
        mov     dx, Settings.strFilename
        mov     ax, 3d'02h; readwrite mode
        int     21h
        jnc     @F
        ; create file
        mov     dx, Settings.strFilename
        mov     ah, 3ch
        xor     cx, cx
        int     21h
        jc      .EndProc
@@:

        ; get file handler
        mov      bx, ax
        ;mov     bx, [Settings.wFileHandler]; bx - file handle: readwrite mode

        ; write to file
        mov     ah, 40h
        mov     cx, 2; 2 bytes
        mov     dx, Settings.strHighScore
        int     21h

        mov     ah, 3eh ; close file
        int     21h
        jc      .EndProc
.EndProc:
        ret
endp

Settings.strFilename    db      'setup.txt',0
Settings.strHighScore   dw      ?
;Settings.wFileHandler   dw      ?


blocksArr:      times (FIELD_H-1) db $1A, (FIELD_W-2) dup $00, $1A
                db    FIELD_W dup $1A

; timed copy
blocksArrCopy:  times (FIELD_H-1) db $1A, (FIELD_W-2) dup $00, $1A
                db    FIELD_W dup $1A


figArr          dw      0000'0110_0110'0000b, 0000'0110_0110'0000b, 0000'0110_0110'0000b, 0000'0110_0110'0000b,\
                        0100'0100_0100'0100b, 0000'1111_0000'0000b, 0100'0100_0100'0100b, 0000'1111_0000'0000b,\
                        0100'0100_0110'0000b, 0010'1110_0000'0000b, 1100'0100_0100'0000b, 0000'1110_1000'0000b,\
                        0100'0100_1100'0000b, 0000'1110_0010'0000b, 0110'0100_0100'0000b, 1000'1110_0000'0000b,\
                        0100'1110_0000'0000b, 0100'0110_0100'0000b, 0000'1110_0100'0000b, 0100'1100_0100'0000b,\
                        1000'1100_0100'0000b, 0000'0110_1100'0000b, 1000'1100_0100'0000b, 0000'0110_1100'0000b,\
                        0100'1100_1000'0000b, 0000'1100_0110'0000b, 0100'1100_1000'0000b, 0000'1100_0110'0000b
                        ;0100'1110_0100'0000b, 0100'1110_0100'0000b, 0100'1110_0100'0000b, 0100'1110_0100'0000b,\
                        ;0000'1110_1010'0000b, 0110'0100_0110'0000b, 1010'1110_0000'0000b, 1100'0100_1100'0000b,\;
figNum          dw      ($ - figArr)/8 - 1


bVideoMode              db      ?
bVideoPage              db      ?

timerCounter            dw      ?

        ; uses
        ; - Screen.DrawRect
        ; - Screen.DrawLine.Mode13h
        ; - Keyboard - full
        ; - Random.  - full
        ; - Decimalwrite.WriteExt.Mem
        ; - tetrissound - full

        include 'units\keyboard.h'
        include 'units\random.h'
        include 'units\decimalwrite.h'
        include 'units\bufscreen.h'
        ;include 'units\interrupt.h'
        include 'units\tetrissound.h'