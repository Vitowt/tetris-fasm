;=============================================================================================
;============ pack of procedures for doublebuffered draw on screen in 13h mode  ==============
;============== (circle and line draw excluded to decrease .com file size) ===================
;=============================================================================================
;===================made by  Artiom Drankevich================================================
;===================artem.drankevich@gmail.com================================================
;=============================================================================================
;============================2021=============================================================
;=============================================================================================

        alLeft   = 0
        alRight  = 1
        alCenter = 2
        alCustom = 3

        WIDTH_03h       = 80
        HEIGHT_03h      = 25

        WIDTH_13h       = 320
        HEIGHT_13h      = 200

        nil     = 0

;==========Procedures place======================
;------------------------------------------------
proc    Screen.Update uses es ds si di

        push    [Screen.Segment]
        pop     ds
        push    $A000
        pop     es

        xor     si, si
        xor     di, di
        mov     cx, WIDTH_13h*HEIGHT_13h
        rep movsb

        ret
endp


proc    Screen.WriteStr.Mode13h uses si di ax dx bx cx,\ ; !! bx is x cord
                 x, y: BYTE, strAdr, color: BYTE, hAlign: BYTE; str format is [0] - length; [1..length] - symbols in '('..'Z'\ ':'..'@'

        mov     si, [strAdr]
        movzx   cx, byte [si]; length
        inc     si

        cmp     [hAlign], alCustom
        jne     @F
        mov     bx, [x] ; bx is x arg
        jmp      .Done
@@:

        ; encount alignment
        mov     ax, cx; ax --  len
        mov     dl, 5; mul by width of char (now its len)
        mul     dl

        xor     bx, bx
        cmp     [hAlign], alLeft
        je      .Done
        mov     bx, WIDTH_13h
        sub     bx, ax

        cmp     [hAlign], alRight
        je      .Done
.Center:
        shr     bx, 1
.Done:
        movzx   dx, [y]
        movzx   di, [color]

.DrawLoop:
        lodsb; to al, from ds:si
        cmp    al, ' '
        jle     .Space

        cmp    al, '9' ; handle problem with ansi between '9' and 'A'
        jle    @F
        sub    al, 7

        cmp    al, 'a' - 7
        jl     @F ; upcase
        sub    al, 'a' - 'A'

@@:
        stdcall Screen.DrawChar, bx, dx, ax, di
.Space:
        add     bx, 5

        loop    .DrawLoop

        ret
endp


proc    Screen.DrawChar uses es si di ax dx cx,\
                 x, y: BYTE, char: BYTE, color: BYTE

        xor     ax, ax; ax, di
        mov     al, [y]
        mov     di, WIDTH_13h
        mul     di
        add     ax, [x]
        mov     di, ax; start offset


        movzx   ax, [char]
        sub     ax, '('
        mov     cx, 3
        mul     cl
        add     ax, LetterMatrixPlace; matrix
        mov     si, ax; start matrix offset

        push    [Screen.Segment]
        pop     es

        mov     cx, 3; matrix size 3 bytes

.PrintLoop:
        push    cx

        lodsb
        xchg    al, ah; from al to ah
        mov     al, [color]
        mov     cx, 4

        ; inner loop -- draw line of matrix
.InnerLoopA:
        shl     ah, 1
        jae     .elseA ; CF = 0 => exit

        stosb  ; draw
        jmp    .exitA
.elseA:
        inc     di
.exitA:
        loop    .InnerLoopA

        add     di, WIDTH_13h-4 ; new line
        mov     cx, 4
        ; inner loop -- draw line of matrix
.InnerLoopB:
        shl     ah, 1
        jae     .elseB ; CF = 0 => exit

        stosb    ; draw
        jmp     .exitB
.elseB:
        inc     di
.exitB:
        loop    .InnerLoopB

        add     di, WIDTH_13h-4 ; new line
        pop     cx
        loop    .PrintLoop

        ret
endp



LetterMatrixPlace     file 'fontmatrix_5x4.txt'


;======Draw rect=====
proc    Screen.DrawRect uses es di ax cx dx,\  ; ax dx cx saves automatically! ax - res
                 x, y, width, heigth, color: BYTE

        mov     ax, WIDTH_13h
        mul     [y]
        add     ax, [x]
        mov     di, ax


        push    [Screen.Segment];$A000
        pop     es

        mov     al, [color]
        mov     cx, [heigth]

.PrintLoop:
        push    cx
        mov     cx, [width]

        rep     stosb
        add     di, WIDTH_13h
        sub     di, [width]

        pop     cx
        loop    .PrintLoop

        ret
endp

;;================
proc Screen.Clear.Mode13h uses es di

        push    [Screen.Segment]
        pop     es
        xor     ax, ax
        xor     di, di
        mov     cx, WIDTH_13h*HEIGHT_13h
        rep stosb

        ret
endp


Screen.Segment  dw      ?
