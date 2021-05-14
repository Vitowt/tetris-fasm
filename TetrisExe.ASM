;=============================================================================================
;=============This is my variant of famous tetris game on fasm================================
;=============================================================================================
;===================made by Artiom Drankevich=================================================
;=============================================================================================
;=============================================================================================
;============================2021============================================================
;============================================================================================
;-- Note, that unit dependences is not presented here 
;============================================================================================
        include 'macro\proc16.inc'

        format  MZ

        entry   Main:EntryPoint

        FIELD_W = 12; 12
        FIELD_H = 18

        BLOCK_W = 9

        TRUE    = 1
        FALSE   = 0

segment Main

EntryPoint:
        ; set ds
        push    cs
        pop     ds

        ; save video mode
        mov     ah, 0Fh
        int     10h

        mov     [bVideoMode], al
        mov     [bVideoPage], bh

        ; set videomode
        mov     ax, 0013h; 03h; add переменная с смещением процедуры д/текущего граф режима
        int     10h

        call    Game.Initialize


        ; set IntVector for timer
        stdcall setIntVector, 1ch, cs, Game.Update
        mov     word [pOldISR], ax
        mov     word [pOldISR + 2], dx

        ;Game loop
GameLoop:
        cmp     [Game.Playing], TRUE
        je      Exit

        stdcall View.DrawField
        stdcall View.DrawFigure, [Game.CurFig], [Game.FigX], [Game.FigY], [Game.CurFigColor] ;fig, x, y, color

        call    Keyboard.ReadKey

        cmp     ax, KEY_ESCAPE
        je      Escape


        ;cmp     ax, 's' ; future new feature with usernames
        ;jne     @F
        ;xor     [Game.Pause], 1; PAUSE
        ;stdcall Settings.Setup
;@@:

        cmp     ax, 'p'
        jne     @F
        xor     [Game.Pause], 1; PAUSE
@@:
        cmp     [Game.Pause], 0
        jne     GameLoop

        ; mk moves
        mov     si, [Game.FigX]
        mov     bx, [Game.CurFigNumber]
        shl     bx, 2
        mov     dx, [Game.CurFigRotation]

        ; speed up on space
        cmp     ax, $0020  ; alt+1
        jne     @F
        mov     [Game.CurTick], 0; mov     [Game.CurSpeed], 0
@@:

        ; cheat codes
        cmp     ax, $7800  ; alt+1
        jne     @F
        mov     [Game.NextFigNumber], 0
@@:
        cmp     ax, $7900  ; alt+2
        jne     @F
        mov     [Game.NextFigNumber], 1
@@:
        cmp     ax, $7A00  ; alt+3
        jne     @F
        mov     [Game.NextFigNumber], 2
@@:
        cmp     ax, $7B00  ; alt+4
        jne     @F
        mov     [Game.NextFigNumber], 3
@@:
        cmp     ax, $7C00  ; alt+5
        jne     @F
        mov     [Game.NextFigNumber], 4
@@:
        cmp     ax, $7D00  ; alt+6
        jne     @F
        mov     [Game.NextFigNumber], 5
@@:
        cmp     ax, $7E00  ; alt+7
        jne     @F
        mov     [Game.NextFigNumber], 6
@@:
        ; end cheat codes
        cmp     ax, KEY_UP  ; rotation
        jne     @F
        inc     dx
        and     dx, 0000'0000'0000'0011b
@@:
        cmp     ax, KEY_DOWN
        jne     @F
        dec     dx
        and     dx, 0000'0000'0000'0011b
@@:
        cmp     ax, KEY_LEFT
        jne     @F
        dec     si
@@:
        cmp     ax, KEY_RIGHT
        jne     @F
        inc     si
@@:
        add     bx, dx
        shl     bx, 1
        mov     bx, [figArr + bx]

        push    dx
        stdcall Game.CollideFigure, bx, si, [Game.FigY]
        pop     dx
        test    ax, ax
        jnz     @F
        mov     [Game.FigX], si
        mov     [Game.CurFig], bx
        mov     [Game.CurFigRotation], dx
@@:
        ;stdcall Game.Update
        jmp     GameLoop
Escape:
        ; restore int vector
        stdcall setIntVector, 1ch, word [pOldISR + 2], word [pOldISR]
        mov     word [pOldISR], ax
        mov     word [pOldISR + 2], dx
Exit:
        stdcall Screen.WriteStr.Mode13h, FIELD_W * 5 - 5*5, BLOCK_W*2, Game.OverStr, $1F, alCustom

@@:
        call    Keyboard.ReadKey; wait for exit key
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

Game.OverStr            db      10, 'Game over!'
Game.NextStr            db      12, 'Next figure '
Game.ScoreStr           db      15, 'Your score ',?,?,?
Game.ScoreStrEnd        db      0
Game.HighStr            db      15, 'High score ',?,?,?
Game.HighStrEnd         db      0

Game.UserNameLen        db      20
Game.UserName           db      ?, 20 dup ?

Game.SpeedMul           dd      0___0111'1110___110'1000_0000'0000_0000'0000b; 0.90625


Game.Update:
        push    di bx ax ds dx; cx

        push    cs
        pop     ds


; TIMED TIMED
        cmp     [Game.Pause], 0
        jne     .ExitProc; full exit
        cmp     [Game.CurTick], 0
        jne     .EndProc; exit + dec cur tick

        mov     di, [Game.TickSpeed]
        mov     [Game.CurTick], di

        mov     bx, [Game.CurFig] ; load
        mov     di, [Game.FigY]

        ; mk changes
        inc     di

        ; check on collision
        stdcall Game.CollideFigure, bx, [Game.FigX], di
        test    ax, ax
        jz      .Regular
.Collided:
        stdcall Game.PlaceFigure, bx, [Game.FigX], [Game.FigY], [Game.CurFigColor]
        mov     bx, [Game.NextFig]
        mov     [Game.CurFig], bx

        mov     bx, [Game.NextFigNumber]
        mov     [Game.CurFigNumber], bx
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
        test    [Game.FigsPlaced], 0000'0000'0000'1111; 111
        jnz     @F
        fild    [Game.TickSpeed]
        fld     [Game.SpeedMul]
        fmul    st1, st0
        fistp   [Game.TickSpeed]
        fistp   [Game.TickSpeed]
@@:
        ; ---check game is valid---------------
        stdcall Game.CheckOnLine
        stdcall Game.CheckOnEnd; result in ax
        mov     [Game.Playing], ax
        test    ax, ax
        jz      .ExitWithViewUpdate
        ; stop game
        stdcall Screen.WriteStr.Mode13h, FIELD_W * 5 - 5*5, BLOCK_W * 2, Game.OverStr, $1F, alCustom
        ; restore int vector
        stdcall setIntVector, 1ch, word [pOldISR + 2], word [pOldISR]

        jmp     .ExitProc

.Regular:
        mov     [Game.FigY], di
.ExitWithViewUpdate:
        ; update View
        stdcall View.DrawField
        stdcall View.DrawFigure, [Game.CurFig], [Game.FigX], [Game.FigY], [Game.CurFigColor] ;fig, x, y, color

.EndProc:
        dec     [Game.CurTick]
 ; zRTIMED TIMED
.ExitProc:

        pop     dx ds ax bx di
        iret


proc Game.CheckOnEnd uses bx

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
        inc     ax

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
        stdcall Screen.DrawRect, FIELD_W*(BLOCK_W+1)+10, 90, 20*5, 5, $00
        stdcall Screen.WriteStr.Mode13h, FIELD_W*(BLOCK_W+1)+10, 90, Game.ScoreStr, $1F, alCustom


.EndProc:
        ret
endp


; == = = = ==  plaaceing
proc Game.PlaceFigure uses bx cx si,\
     fig, x, y, color

        mov     ax, FIELD_W
        mul     [y]
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
        test    cx, 0000'0000'0000'0011b
        jnz     @F
        add     bx, FIELD_W - 4
@@:
        inc     cx
        loop    .DrawLoop

        ret
endp
; = = = = collision
proc Game.CollideFigure uses bx cx si,\
     fig, x, y
        ; prep cords
        mov     ax, FIELD_W
        mul     [y]
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

proc Game.Initialize

        call    Random.Initialize

        ; write score
        push    0
        push    [Game.Score]
        push    Game.ScoreStrEnd
        call    DecimalWrite.ExtMem
        stdcall Screen.WriteStr.Mode13h, FIELD_W*(BLOCK_W+1)+30, 90, Game.ScoreStr, $1F, alCustom
        ; write high scoree
        stdcall Screen.WriteStr.Mode13h, FIELD_W*(BLOCK_W+1)+30, 100, Game.HighStr, $1F, alCustom
        ; write next fig str
        stdcall Screen.WriteStr.Mode13h, FIELD_W*(BLOCK_W+1)+30, 10, Game.NextStr, $1F, alCustom

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

        mov     [Game.CurTick], 13
        mov     [Game.TickSpeed], 13
        mov     [Game.Pause], 0
        mov     [Game.Playing], 0

        ;fldln2; set multiplier for speed booster
        fld     [Game.SpeedMul]

        ret
endp

; = = == = =
proc View.DrawFigure uses bx cx si di,\
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

;; update field
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

;=============SetupMode====================

proc Settings.Setup uses dx
        ; set videomode
        mov     ax, 0003h; 03h; add переменная с смещением процедуры д/текущего граф режима
        int     10h

        mov     ah, 0ah
        mov     dx, Game.UserNameLen
        int     21h

        ; set videomode
        mov     ax, 0013h; 03h; add переменная с смещением процедуры д/текущего граф режима
        int     10h

        stdcall Screen.WriteStr.Mode13h, 0, 100, Game.UserName, $2F, alCenter


        call    Keyboard.ReadKey

        ret
endp


proc Settings.UpdateHigh uses dx cx bx,\
        high

        ; readfile
        ; load parent com file
        mov     dx, Settings.strFilename
        mov     ax, 3d'02h; readwrite mode
        int     21h

        ; save file handler
        mov     [Settings.wFileHandler], ax
        mov     bx, ax; bx - file handle: readwrite mode

        mov     ah, 3fh; read mode
        mov     cx, 2; 2 bytes
        mov     dx, Settings.strFileread
        int     21h

        mov     ax, [high]
        cmp     ax, [Settings.strFileread]
        jle     @F
        mov     [Settings.strFileread], ax

        ; mov file ptr
        mov     ax, 4200h
        xor     cx, cx
        xor     dx, dx
        int     21h

        ; write to file
        mov     ah, 40h
        mov     cx, 2; 2 bytes
        mov     dx, Settings.strFileread
        int     21h

@@:

        jc     .EndProc


.EndProc:
        ret
endp

Settings.strFilename    db      'setup.txt'
Settings.strFileread    dw      ?
Settings.wFileHandler   dw      ?


blocksArr:      times (FIELD_H-1) db $1A, (FIELD_W-2) dup $00, $1A
                db    FIELD_W dup $1A

bVideoMode      db      ?
bVideoPage      db      ?

figArr          dw      0000'0110_0110'0000b, 0000'0110_0110'0000b, 0000'0110_0110'0000b, 0000'0110_0110'0000b,\
                        0100'0100_0100'0100b, 0000'1111_0000'0000b, 0100'0100_0100'0100b, 0000'1111_0000'0000b,\
                        0100'0100_0110'0000b, 0010'1110_0000'0000b, 1100'0100_0100'0000b, 0000'1110_1000'0000b,\
                        0100'0100_1100'0000b, 0000'1110_0010'0000b, 0110'0100_0100'0000b, 0010'1110_0000'0000b,\
                        0100'1110_0000'0000b, 0100'0110_0100'0000b, 0000'1110_0100'0000b, 0100'1100_0100'0000b,\
                        1000'1100_0100'0000b, 0000'0110_1100'0000b, 1000'1100_0100'0000b, 0000'0110_1100'0000b,\
                        0100'1100_1000'0000b, 0000'1100_0110'0000b, 0100'1100_1000'0000b, 0000'1100_0110'0000b
                        ;0100'1110_0100'0000b, 0100'1110_0100'0000b, 0100'1110_0100'0000b, 0100'1110_0100'0000b,\
                        ;0000'1110_1010'0000b, 0110'0100_0110'0000b, 1010'1110_0000'0000b, 1100'0100_1100'0000b,\;
figNum          dw      ($ - figArr)/8 - 1

        include 'units\screen.h'
        include 'units\keyboard.h'
        include 'units\random.h'
        include 'units\decimalwrite.h'
        include 'units\interrupt.h'