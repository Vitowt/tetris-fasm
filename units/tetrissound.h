;=============================================================================================
;===============soundplayer for tetris========================================================
;=======(requires special midi file (.amid) to play sound correctly)  ========================
;=======================(its created by me on delphi)  =======================================
;=============================================================================================
;===================made by  Artiom Drankevich================================================
;===================artem.drankevich@gmail.com================================================
;=============================================================================================
;============================2021=============================================================
;=============================================================================================

; soundplayer for tetris

NOTES_PACK_BYTES        = 12; 9

proc SoundPlayer.Initialize uses dx
        ;jmp     .EndProc ; temp
        ; setup sound
        mov     dx, 0331h
        mov     al, $FF
        out     dx, al
        mov     al, $3F
        out     dx, al

        dec     dx

        mov     al, 1100'0000b or 0; formatt 1100'nnnn n - channel no
        out     dx, al
        mov     al, 32 ; formatt 0ppp'pppp p - instrument no
        out     dx, al

        mov     al, 1100'0000b or 1; formatt 1100'nnnn n - channel no
        out     dx, al
        mov     al, 25 ; formatt 0ppp'pppp p - instrument no
        out     dx, al

        mov     al, 1100'0000b or 2; formatt 1100'nnnn n - channel no
        out     dx, al
        mov     al, 25 ; formatt 0ppp'pppp p - instrument no
        out     dx, al
.EndProc:
        ret
endp


proc SoundPlayer.Stop uses dx si
        ;jmp     .EndProc ; temp

        mov     dx, 0331h
        mov     si, Player.NotesNum + $2 - NOTES_PACK_BYTES ; $4 - offset (temp); from what start play
        add     si, word [Player.NextSound]

        mov     al, 1000'0000b or 0; formatt 1100'nnnn n - channel no
        out     dx, al
        mov     al, byte [si + 1];0111'1111b ;
        out     dx, al
        mov     al, 0111'1111b ;
        out     dx, al

        mov     al, 1000'0000b or 1; formatt 1100'nnnn n - channel no
        out     dx, al
        mov     al, byte [si + 4];0111'1111b ;
        out     dx, al
        mov     al, 0111'1111b ;
        out     dx, al

        mov     al, 1000'0000b or 2; formatt 1100'nnnn n - channel no
        out     dx, al
        mov     al, byte [si + 7]; 0111'1111b ;
        out     dx, al
        mov     al, 0111'1111b ;
        out     dx, al

        mov     al, 1000'0000b or 9; formatt 1100'nnnn n - channel no
        out     dx, al
        mov     al, byte [si + 9];0111'1111b ;
        out     dx, al
        mov     al, 0111'1111b ;
        out     dx, al
.EndProc:
        ret
endp

proc SoundPlayer.PlayNext uses si cx dx ax

        ; sound here
        mov     dx, 0330h; port
        mov     si, Player.NotesNum + $2 ; $4 - offset (temp); from what start play
        mov     ax, word [Player.NextSound]; counter

        cmp     ax, word [Player.NotesNum]
        jl      @F
        xor     ax, ax
@@:
        add     si, ax
        mov     cx, NOTES_PACK_BYTES
        rep     outsb

        add     ax, NOTES_PACK_BYTES
        mov     [Player.NextSound], ax

        ret
endp


Player.NextSound        dw      0
                        ; 1001 -- play; 1000 - stop; kkk - note num, vvv - volume
                        ;format 1001'nnnn   kk  0vvvvvvvv

Player.NotesNum         file    'dest-1.amid'