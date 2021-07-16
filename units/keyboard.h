;------------------------------------------------
; result in ax reg
;  ax - 00CC - symbol
;  ax - KK00 - code
Keyboard.ReadKey:
        xor     dx, dx
        mov     ax, 0C08h
        int     21h

        mov     dl, al; save first entered key

        test    al, al
        jnz     @F

        mov     ah, 08h
        int     21h

        mov     dh, al; if key is special
@@:
        mov     ax, dx; return with ax reg

        ret

KEY_ESCAPE      = $001B
KEY_UP          = $4800
KEY_DOWN        = $5000
KEY_LEFT        = $4B00
KEY_RIGHT       = $4D00
