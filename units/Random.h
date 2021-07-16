;=============================================================================================
;=================2 byte pseudo random generator==============================================
;=============================================================================================
;===================made by  Artiom Drankevich================================================
;===================artem.drankevich@gmail.com================================================
;=============================================================================================
;============================2021=============================================================
;=============================================================================================

;------------------------------------------------
; initialize random using cur time
Random.Initialize:
        mov     ah, 2Ch; get sys time
        int     21h    ; got seed in dx  (s and ms*10)
        mov     [Random.wPrewNumber], dx

        ret

proc Random.Get uses cx dx,\; not nessesary to save cx dx
        wMin, wMax

        ; pseudo random generator (A*x + B) mod N
        mov     ax, [Random.wPrewNumber]

        mov     cx, 29
        mul     cx
        add     ax, 47
        xor     dx, dx

        mov  [Random.wPrewNumber], ax

        mov     cx, [wMax]
        sub     cx, [wMin]
        inc     cx
        xor     dx, dx
        div     cx

        mov     ax, dx
        add     ax, [wMin]

        ret
endp


;============other data=============
Random.wPrewNumber      dw      ?