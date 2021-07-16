;=============================================================================================
;============ pack of procedures for draw on screen ==========================================
;=============================================================================================
;===================made by  Artiom Drankevich================================================
;===================artem.drankevich@gmail.com================================================
;=============================================================================================
;============================2021=============================================================
;=============================================================================================
; includes
; - string write in 03h and 13h modes
; - rect, line, circle elements (13h mode)
; - clear (03, 13h mode)


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
proc Screen.WriteStr uses bx ; This proc is incomplete. Check WriteStr proc manually.
        mov     ah, $0F
        int     10h; get videomode

        movzx   bx, al; bx = 13h
        cmp     bx, Screen.WriteStr.Impl.Count; if mode to big
        ja      .EndProc

        add     bx, bx

        mov     ax, [Screen.WriteStr.Impl + bx]

        test    ax, ax
        jz      .EndProc
        stdcall ax


.EndProc:
        ret
endp

; «амена дл€ кейса!!!! -- таблица переходов
Screen.WriteStr.Impl       dw      nil, nil, nil, Screen.WriteStr.Mode03h,\
                                nil, nil, nil, nil,\
                                nil, nil, nil, nil,\
                                nil, nil, nil, nil,\
                                nil, nil, nil, Screen.WriteStr.Mode13h
Screen.WriteStr.Impl.Count  = ($ - Screen.Clear.Impl)/2

; writes str on screen (mode 03h)
proc     Screen.WriteStr.Mode03h uses es si di,\
        ofsStr, nLine, hAlign, bAttr: BYTE; ofsStr - pointer(only ofset) to pascal string

        mov     ax, WIDTH_03h ; num of symbols in line
        mul     [nLine]
        mov     di, ax

        mov     si, [ofsStr]
        xor     ax, ax
        lodsb ; read length

        cmp     [hAlign], alLeft
        je      .Done
        mov     cx, WIDTH_03h
        sub     cx, ax

        cmp     [hAlign], alRight
        je      .Right
.Center:
        shr     cx, 1
.Right:
        add     di, cx
.Done:
        shl     di, 1; bc every symbol takes 2 bytes

        push    $B800; mov segment of videomem
        pop     es
        mov     cx, ax; copy len
        mov     ah, [bAttr] ; color
.PrintLoop:
        lodsb
        stosw

        loop    .PrintLoop


        ret; подставл€етс€ автоматически колво параметров
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

        push    $A000
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


        push    $A000
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


;============ Dran line===========
proc    Screen.DrawLine uses es si di bx cx dx,\
                 x1, y1, x2, y2, color: BYTE
        ; save x2 - x1
        ; save y2 - y1

        push    $A000
        pop     es

        ; do for x cord
        mov     ax, [x2]
        sub     ax, [x1]; dx

        cmp     ax, 0
        jge     @F
        neg     byte [.SXinstr + 2];??? INSTR SIZE = 2 BYTES
@@:
        cwd ; fills dx with sign (abs)
        xor     ax, dx
        sub     ax, dx

        mov     cx, ax; save

        ; do for y cord
        mov     ax, [y2]
        sub     ax, [y1]; dy

        cmp     ax, 0
        jge     @F
        neg     word [.SYinstr + 2];???
@@:
        cwd ; fills dx with sign -(abs)
        not     dx
        xor     ax, dx
        sub     ax, dx
        mov     bx, ax

        ; count di
        mov     ax, [y1]
        mov     si, WIDTH_13h
        mul     si
        mov     di, ax
        add     di, [x1]
        ; count control sum
        mov     ax, [y2]
        mul     si
        add     ax, [x2]
        mov     [.BreakCond + 2], ax; mov it on its place

        ; count err
        mov     si, bx
        add     si, cx

        mov     al, [color]
        ; now main loop (err = si, bx - (deltay), cx - (deltax), di - place, ax - attr
.MainLoop:
        mov     [es:di], al; draw pixel

        ; break cond
.BreakCond:
        cmp     di, $FF
        je      .EndProc

        ; line cond
        mov     dx, si
        shl     dx, 1
        cmp     dx, bx
        jl      @F; move x axis
        add     si, bx
.SXinstr:
        add     di, $0001
@@:
        cmp     dx, cx
        jg      @F; move y axis
        add     si, cx
.SYinstr:
        add     di, WIDTH_13h
@@:
        jmp     .MainLoop

.EndProc:

        ret
endp

SubInst:
        sub     di, WIDTH_13h


;;==========Circle=================
proc    Screen.DrawCircle uses es si di ax dx cx,\
                   x, y, radius, color: BYTE

        push    $A000
        pop     es

        mov     ax, [y]
        mov     dx, WIDTH_13h
        mul     dx
        mov     di, ax
        add     di, [x]


        xor     bx, bx
        mov     cx, [radius]
        mov     si, cx;
        shl     si, 1
        sub     si, 3
        neg     si

.MainLoop:; (bx is x, cx is y, si is d)
        ; draw pixels
        push    si

        mov     ax, cx
        mov     dx, WIDTH_13h
        mul     dx
        mov     si, ax

        mov     al, [color]

        add     di, si
        mov     [es:di + bx], al
        sub     di, si
        sub     di, si
        mov     [es:di + bx], al
        sub     di, bx
        mov     [es:di], al
        add     di, si
        add     di, si
        mov     [es:di], al
        sub     di, si
        add     di, bx

        push    bx

        mov     ax, bx
        mov     bx, cx

        mov     dx, WIDTH_13h
        mul     dx
        mov     si, ax

        mov     al, [color]

        add     di, si
        mov     [es:di + bx], al
        sub     di, si
        sub     di, si
        mov     [es:di + bx], al
        sub     di, bx
        mov     [es:di], al
        add     di, si
        add     di, si
        mov     [es:di], al
        sub     di, si
        add     di, bx

        pop     bx
        pop     si

        inc     bx
        cmp     si, 0
        jle     .less
.greater:
        dec     cx
        ;d = d + 4 * (x - y) + 10;
        mov     ax, bx
        sub     ax, cx
        shl     ax, 2
        add     ax, 10
        add     si, ax

        jmp     .continue
.less:
        ;d = d + 4 * x + 6;
        mov     ax, bx
        shl     ax, 2
        add     ax, 6
        add     si, ax

.continue:
        cmp     cx, bx
        jge     .MainLoop

        ret
endp

;========================================
;==============clear screen universal========
;====================================
proc Screen.Clear uses bx
        mov     ah, $0F
        int     10h; get videomode

        movzx   bx, al; bx = 13h
        cmp     bx, Screen.Clear.Impl.Count; if mode to big
        ja      .EndProc

        add     bx, bx

        mov     ax, [Screen.Clear.Impl + bx]

        test    ax, ax
        jz      .EndProc
        stdcall ax


.EndProc:
        ret
endp

; «амена дл€ кейса!!!! -- таблица переходов
Screen.Clear.Impl       dw      nil, nil, nil, Screen.Clear.Mode03h,\
                                nil, nil, nil, nil,\
                                nil, nil, nil, nil,\
                                nil, nil, nil, nil,\
                                nil, nil, nil, Screen.Clear.Mode13h
Screen.Clear.Impl.Count  = ($ - Screen.Clear.Impl)/2

proc Screen.Clear.Mode03h uses es di

        push    $B800
        pop     es
        xor     ax, ax
        xor     di, di
        mov     cx, WIDTH_03h*HEIGHT_03h
        rep stosw

        ret
endp

proc Screen.Clear.Mode13h uses es di

        push    $A000
        pop     es
        xor     ax, ax
        xor     di, di
        mov     cx, WIDTH_13h*HEIGHT_13h
        rep stosb

        ret
endp
