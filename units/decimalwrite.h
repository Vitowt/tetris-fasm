;=============================================================================================
;===============pack of algorithms to write numbers in decimal form ==========================
;=============================================================================================
;===================made by  Artiom Drankevich================================================
;===================artem.drankevich@gmail.com================================================
;=============================================================================================
;============================2021=============================================================
;=============================================================================================

;       Procedure Write in decimal to mem
;                 uses ax, dx, bp
;                 1st arg -- higher 2 bytes
;                 2st arg -- lower  2 bytes
;                 3st arg -- mem adress (number placed to the left of it)
;                 max - 655359 (9FFFF)
DecimalWrite.ExtMem:
        push    bp
        mov     bp, sp
        push    ax
        push    dx
        push    cx
        push    bx

        mov     dx, [bp + 8] ; why? load initial value (higher)
        mov     ax, [bp + 6] ; why? load initial value (lower)
        mov     bx, [bp + 4]
.Count:
        mov     cx, 10
        div     cx

        add     dx, '0'

        ; write cur number
        mov     [bx], dl
        sub     bx, 1

        mov     dx, 0
        cmp     ax, 0
        jne     .Count

.Exit:
        pop     bx
        pop     cx
        pop     dx
        pop     ax
        pop     bp
        ret     6


;       Procedure Write in decimal on screen (text mode)
;                 uses ax, dx, bp
;                 1st arg -- higher 2 bytes
;                 2st arg -- lower  2 bytes
;                 max - 655359 (9FFFF)
DecimalWrite.Ext:
        push    bp
        mov     bp, sp
        push    ax
        push    dx
        push    cx

        push    '0$'; at bp (move symbol to determine end of str)

        mov     dx, [bp + 6] ; why? load initial value (higher)
        mov     ax, [bp + 4] ; why? load initial value (lower)
.Count:
        mov     cx, 10
        div     cx

        add     dx, '0'

        push    dx ; push cur number

        mov     dx, 0
        cmp     ax, 0
        jne     .Count

        pop     dx
.writeout:
        mov     ah, 02h
        int     21h

        pop     dx

        cmp     dh, '$'
        jne     .writeout

.Exit:
        pop     cx
        pop     dx
        pop     ax
        pop     bp
        ret     4


;       Procedure Write in decimal (with negatives) (text mode)
;                 uses ax, dx, bp
;                 1st arg -- higher 2 bytes
;                 2st arg -- lower  2 bytes
;                 max - 327679 (4FFFF)
DecimalWrite.NegExt:
        push    bp
        mov     bp, sp
        push    ax
        push    dx
        push    cx

        push    '0$'; at bp (move symbol to determine end of str)

        mov     dx, [bp + 6] ; why? load initial value (higher)
        mov     ax, [bp + 4] ; why? load initial value (lower)

        cmp     dx, 0; if negative
        jge     .Count

        push    ax
        push    dx
        mov     ah, 02h; write'-' sign
        mov     dl, '-'
        int     21h
        pop     dx
        pop     ax

        not     dx
        not     ax; CF handle
        add     ax, 1
        adc     dx, 0

.Count:
        mov     cx, 10
        div     cx

        add     dx, '0'

        push    dx ; push cur number

        mov     dx, 0
        cmp     ax, 0
        jne     .Count

        pop     dx
.writeout:
        mov     ah, 02h
        int     21h

        pop     dx

        cmp     dh, '$'
        jne     .writeout

.Exit:
        pop     cx
        pop     dx
        pop     ax
        pop     bp
        ret     4

;       Procedure Write in decimal (text mode)
;                 uses ax, dx, bp
;                 1st arg -- number to write (max 2559)

DecimalWrite.Sml:
        push    bp
        mov     bp, sp
        push    ax
        push    dx

        push    '0$'; at bp (move symbol to determine end of str)

        mov     ax, [bp + 4] ; why? load initial value
.Count:
        mov     dl, 10
        div     dl

        movzx   dx, ah
        add     dx, '0'

        push    dx ; push cur number

        movzx   ax, al
        cmp     ax, 0
        jne     .Count

        pop     dx
.writeout:
        mov     ah, 02h
        int     21h

        pop     dx

        cmp     dh, '$'
        jne     .writeout

.Exit:
        pop     dx
        pop     ax
        pop     bp
        ret     2
