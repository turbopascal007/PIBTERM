(*----------------------------------------------------------------------*)
(*  Video_Interrupt_Handler --- Replaces int $10 video handler          *)
(*----------------------------------------------------------------------*)

PROCEDURE Video_Interrupt_Handler(
          Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP : WORD );
   (* Interrupt; *)

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Video_Interrupt_Handler                              *)
(*                                                                      *)
(*     Purpose:    Replaces standard interrupt $10 video driver         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*                 -- Called by system only!                            *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine replaces the standard interrupt $10 video        *)
(*        driver so that non-flickering scrolls can be performed.       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   ClrMaxVert  = 420         (* Max chars cleared during vertical retrace *);
   MaxVert     = 210         (* Max chars moved during vertical retrace   *);
   MaxHoriz    = 196;
   VRetrace    = $08;
   HRetrace    = $01;

BEGIN (* Video_Interrupt_Handler *)

INLINE(
  $FB/                         {         STI                             ; Enable interrupts}
                               {;}
  $8B/$46/$10/                 {         MOV     AX,[BP+16]              ; Pick up arguments for INT $ 10}
  $8B/$5E/$0E/                 {         MOV     BX,[BP+14]}
  $8B/$4E/$0C/                 {         MOV     CX,[BP+12]}
  $8B/$56/$0A/                 {         MOV     DX,[BP+10]}
                               {;}
  $80/$FC/$00/                 {         CMP     AH,0                    ; Check for mode switch}
  $75/$05/                     {         JNE     ChkMode}
                               {;}
  $A2/>VIDEO_MODE/             {         MOV     [<Video_Mode],AL        ; Remember new mode}
  $EB/$2E/                     {         JMP     SHORT NotOurs           ; and let bios change the mode}
                               {;}
                               {ChkMode:}
  $80/$3E/>VIDEO_MODE/$03/     {         CMP     BYTE [<Video_Mode],3    ; We don't scroll graphics modes}
  $7F/$27/                     {         JG      NotOurs}
                               {;}
                               {Chk5:}
  $80/$FC/$05/                 {         CMP     AH,5                    ; Check for page switch}
  $7C/$22/                     {         JL      NotOurs}
  $75/$05/                     {         JNE     Chk6}
                               {;}
  $A2/>VIDEO_PAGE/             {         MOV     BYTE [<Video_Page],AL   ; Remember new page number}
  $EB/$1B/                     {         JMP     SHORT NotOurs           ; and let bios change the page}
                               {;}
                               {Chk6:}
  $80/$FC/$06/                 {         CMP     AH,6                    ; Check for scroll request}
  $75/$11/                     {         JNE     Chk7}
                               {;}
                               {Chk6a:}
  $80/$F9/$00/                 {         CMP     CL,0                    ; We do it only for complete lines}
  $75/$11/                     {         JNE     NotOurs}
  $50/                         {         PUSH    AX}
  $A1/>MAX_SCREEN_COL/         {         MOV     AX,[>Max_Screen_Col]}
  $48/                         {         DEC     AX}
  $38/$C2/                     {         CMP     DL,AL}
  $58/                         {         POP     AX}
  $75/$07/                     {         JNE     NotOurs}
  $EB/$1F/                     {         JMP     SHORT Scroll}
                               {;}
                               {Chk7:}
  $80/$FC/$07/                 {         CMP     AH,7                    ; Check for scroll request}
  $74/$EA/                     {         JE      Chk6a}
                               {;}
  $FF/$36/>VIDEO_SAVE_IADDR+2/ {NotOurs: PUSH    [>Video_Save_IAddr+2] ;Push address of old ISR onto stack}
  $FF/$36/>VIDEO_SAVE_IADDR/   {         PUSH    [>Video_Save_IAddr]   ;Need to do this before DS restored!}
  $5B/                         {         POP     BX                    ;BX = OFS(Old_Video_Interrupt)}
  $58/                         {         POP     AX                    ;AX = SEG(Old_Video_Interrupt)}
  $87/$5E/$0E/                 {         XCHG    BX,[BP+14]            ;Swap old BX and Ofs(Old_Video...)}
  $87/$46/$10/                 {         XCHG    AX,[BP+16]            ;Swap old AX and Seg(Old_Video...)}
  $89/$EC/                     {         MOV     SP,BP                 ;Restore other registers}
  $5D/                         {         POP     BP}
  $07/                         {         POP     ES}
  $1F/                         {         POP     DS}
  $5F/                         {         POP     DI}
  $5E/                         {         POP     SI}
  $5A/                         {         POP     DX}
  $59/                         {         POP     CX}
                               {;                                       ;BX and AX restored earlier.}
                               {;                                       ;Their places on stack now have}
                               {;                                       ;old video interrupt address,}
                               {;                                       ;which is where return will go.}
                               {;}
  $CB/                         {         RETF                           ;Chain to Old_Video_Interrupt}
                               {;}
                               {Scroll:}
  $A3/>VIDEO_REQUEST/          {         MOV     [>Video_Request],AX     ; Save request}
                               {;}
  $89/$1E/>VIDEO_FILL/         {         MOV     [>Video_Fill],BX        ; Save fill attribute for much later}
                               {;}
  $52/                         {         PUSH    DX                      ; Because MUL uses it}
                               {;}
  $80/$FD/$00/                 {         CMP     CH,0                    ; Check starting, ending Y for legality}
  $7D/$04/                     {         JGE     ChkCH}
                               {;}
  $B5/$00/                     {         MOV     CH,0                    ; CH has starting Y}
  $EB/$0C/                     {         JMP     SHORT ChkDH}
                               {;}
  $3A/$2E/>MAX_SCREEN_LINE/    {ChkCH:   CMP     CH,[>Max_Screen_Line]}
  $7C/$06/                     {         JL      ChkDH}
                               {;}
  $8A/$2E/>MAX_SCREEN_LINE/    {         MOV     CH,[>Max_Screen_Line]}
  $FE/$CD/                     {         DEC     CH}
                               {;}
                               {ChkDH:}
  $80/$FE/$00/                 {         CMP     DH,0                    ; DH has ending Y}
  $7D/$04/                     {         JGE     ChkDH2}
                               {;}
  $B6/$00/                     {         MOV     DH,0}
  $EB/$0C/                     {         JMP     SHORT ChkAL}
                               {;}
  $3A/$36/>MAX_SCREEN_LINE/    {ChkDH2:  CMP     DH,[>Max_Screen_Line]}
  $7C/$06/                     {         JL      ChkAL}
                               {;}
  $8A/$36/>MAX_SCREEN_LINE/    {         MOV     DH,[>Max_Screen_Line]}
  $FE/$CE/                     {         DEC     DH}
                               {;}
                               {ChkAL:}
  $A1/>VIDEO_REQUEST/          {         MOV     AX,[>Video_Request]     ; Check # of lines to scroll/clear}
  $3C/$00/                     {         CMP     AL,0}
  $7D/$05/                     {         JGE     ChkAL2}
                               {;}
  $A0/>MAX_SCREEN_LINE/        {         MOV     AL,[>Max_Screen_Line]}
  $EB/$09/                     {         JMP     SHORT RegsOK}
                               {;}
  $3A/$06/>MAX_SCREEN_LINE/    {ChkAL2:  CMP     AL,[>Max_Screen_Line]}
  $7E/$03/                     {         JLE     RegsOK}
                               {;}
  $A0/>MAX_SCREEN_LINE/        {         MOV     AL,[>Max_Screen_Line]}
                               {;}
                               {RegsOK:}
  $A3/>VIDEO_REQUEST/          {         MOV     [>Video_Request],AX     ; In case we fixed it}
  $30/$FF/                     {         XOR     BH,BH}
  $8A/$1E/>VIDEO_PAGE/         {         MOV     BL,[<Video_Page]        ; Get the current page number}
  $B8/$00/$10/                 {         MOV     AX,4096                 ; The size of a a page}
  $F7/$E3/                     {         MUL     BX                      ; Multiply by the page number to}
  $89/$C7/                     {         MOV     DI,AX                   ; and put it in the destination index}
                               {                                         ; Now calculate the offset of th}
  $88/$EB/                     {         MOV     BL,CH                   ; by getting the starting row}
  $30/$FF/                     {         XOR     BH,BH}
  $A1/>MAX_SCREEN_COL/         {         MOV     AX,[>Max_Screen_Col]    ; We only handle full rows}
  $D1/$E0/                     {         SHL     AX,1                    ; # of chars per row}
  $F7/$E3/                     {         MUL     BX                      ; Multiply by chars/row to get offset}
  $01/$C7/                     {         ADD     DI,AX                   ; and adding to di to get address}
  $89/$F8/                     {         MOV     AX,DI}
  $89/$C6/                     {         MOV     SI,AX                   ; and put it in the source index as well}
  $5A/                         {         POP     DX}
  $A1/>VIDEO_REQUEST/          {         MOV     AX,[>Video_Request]     ; Get the original request}
  $88/$F7/                     {         MOV     BH,DH                   ; Move bottom line to BH}
  $28/$EF/                     {         SUB     BH,CH                   ; Subtract top line}
  $FE/$C7/                     {         INC     BH                      ; BH now has number of lines in}
  $FC/                         {         CLD                             ; We'll move forward unless scroll back}
  $8E/$06/>VIDEO_SCREEN_ADDR/  {         MOV     ES,[>Video_Screen_Addr]}
  $3C/$00/                     {         CMP     AL,0                    ; Clear the area?}
  $76/$06/                     {         JBE     M1                      ; Yes}
  $38/$F8/                     {         CMP     AL,BH}
  $74/$07/                     {         JE      M1b                     ; We are clearing all the lines}
  $72/$08/                     {         JB      M2                      ; We are clearing some of the lines}
                               {M1:                                      ; We are clearing more than all the line}
  $88/$F8/                     {         MOV     AL,BH                   ; Move number of lines in window to AL}
  $A3/>VIDEO_REQUEST/          {         MOV     [>Video_Request],AX}
                               {M1b:}
  $E9/$9D/$00/                 {         JMP     ClrArea}
                               {M2:                                      ; BH has lines in window, AL has lines}
                               {                                         ; to scroll}
  $80/$FC/$06/                 {         CMP     AH,6                    ; Up or down?}
  $74/$25/                     {         JE      UP}
                               {;}
                               {Down:                                    ; We are scrolling down}
  $FD/                         {         STD                             ; so we move backwards}
                               {;}
  $28/$F8/                     {         SUB     AL,BH                   ; The source is BH-AL lines below SI}
  $F6/$D8/                     {         NEG     AL                      ; Correct the sign}
  $98/                         {         CBW                             ; Convert to a word}
  $8B/$0E/>MAX_SCREEN_COL/     {         MOV     CX,[>Max_Screen_Col]}
  $D1/$E1/                     {         SHL     CX,1}
  $F7/$E1/                     {         MUL     CX                      ; Multiply by chars/row}
  $2D/$02/$00/                 {         SUB     AX,2                    ; Subtract a word to get end of}
  $01/$C6/                     {         ADD     SI,AX                   ; and ADD to si, the address of the up l}
                               {;}
                               {; The destination is the lower right which is BH lines}
                               {; below current di => di = di + BH*2*Max_Screen_Col - 2}
                               {;}
  $88/$F8/                     {         MOV     AL,BH                   ; Get lines in window into al}
  $98/                         {         CBW}
  $8B/$0E/>MAX_SCREEN_COL/     {         MOV     CX,[>Max_Screen_Col]}
  $D1/$E1/                     {         SHL     CX,1}
  $F7/$E1/                     {         MUL     CX}
  $2D/$02/$00/                 {         SUB     AX,2                    ; Subtract a word to get end of}
  $01/$C7/                     {         ADD     DI,AX                   ; DI now has address of destination}
                               {;}
  $EB/$0B/                     {         JMP     SHORT MoveM}
                               {Up:                                      ; we are scrolling up}
                               {;}
                               {; The source is al lines below si which is al*160 chars below current SI}
                               {;}
  $98/                         {         CBW                             ; Gets number of lines into AX}
  $8B/$0E/>MAX_SCREEN_COL/     {         MOV     CX,[>Max_Screen_Col]}
  $D1/$E1/                     {         SHL     CX,1}
  $F7/$E1/                     {         MUL     CX}
  $01/$C6/                     {         ADD     SI,AX                   ; SI now has address of source}
                               {;}
                               {; The initial destination is correct, we don't need to change it}
                               {;}
                               {MoveM:                                   ; Now start to move words}
                               {;}
                               {; Fix BX such that it is number of words to move}
                               {; = (number of lines in window minus number of lines to scroll)*80}
                               {;}
  $A1/>VIDEO_REQUEST/          {         MOV     AX,[>Video_Request]     ; Get number of lines to scroll}
  $98/                         {         CBW                             ; Slightly faster than XOR ah,ah}
  $28/$F8/                     {         SUB     AL,BH                   ; Subtract lines in window from lines to}
                               {                                         ; to scroll}
  $F6/$D8/                     {         NEG     AL                      ; after correcting the sign, AX}
  $8B/$0E/>MAX_SCREEN_COL/     {         MOV     CX,[>Max_Screen_Col]    ; words/line}
  $F7/$E1/                     {         MUL     CX                      ; multiply to get words to move}
  $89/$C3/                     {         MOV     BX,AX                   ; BX now has number of words to move}
                               {;}
  $1E/                         {         PUSH    DS                      ; We're about to change it to di}
  $BA/>CRT_STATUS/             {         MOV     DX,>CRT_Status          ; The video status register}
  $8E/$1E/>VIDEO_SCREEN_ADDR/  {         MOV     DS,[>Video_Screen_Addr] ; Load address of display segment}
                               {;}
                               {MvMVert:                                 ; First wait for a vertical refresh}
  $89/$D9/                     {         MOV     CX,BX                   ; Move words remaining to CX}
  $81/$F9/>MAXVERT/            {         CMP     CX,>MaxVert             ; Too  many?}
  $7E/$03/                     {         JLE     MvMMany                 ; No, go move them}
  $B9/>MAXVERT/                {         MOV     CX,>MaxVert             ; Yes, move MaxVert more}
                               {;}
                               {MvMMany:}
  $29/$CB/                     {         SUB     BX,CX                   ; That many remain when rep movsw ends}
                               {;}
                               {MvMVRefresh:}
  $EC/                         {         IN      AL,DX}
  $A8/<VRETRACE/               {         TEST    AL,<VRetrace}
  $75/$FB/                     {         JNZ     MvMVRefresh             ; Wait for a non retrace period}
                               {;}
                               {MvMVWait:}
  $EC/                         {         IN      AL,DX                   ; Get the retrace status}
  $A8/<VRETRACE/               {         TEST    AL,<VRetrace            ; Check for retrace in progress}
  $74/$FB/                     {         JZ      MvMVWait                ; Wait until retrace}
                               {;}
                               {; During a vertical retrace, we can move many}
                               {;}
  $F2/$A5/                     {         REP     MOVSW}
  $81/$FB/$00/$00/             {         CMP     BX,0}
  $74/$30/                     {         JE      MvMEnd}
                               {;}
  $B9/>MAXHORIZ/               {         MOV     CX,>MaxHoriz}
  $D1/$E3/                     {         SHL     BX,1                    ; To convert words to bytes}
                               {;}
                               {MvM1:}
  $4B/                         {         DEC     BX}
                               {;}
                               {MvMHRefresh:}
  $EC/                         {         IN      AL,DX}
  $A8/<HRETRACE/               {         TEST    AL,<HRetrace}
  $75/$FB/                     {         JNZ     MvMHRefresh             ; Wait for a non retrace period}
                               {;}
                               {;        CLI                             ; Disable interrupts while waiting}
                               {;}
                               {MvMHWait:}
  $EC/                         {         IN      AL,DX                   ; Get the retrace status}
  $A8/<HRETRACE/               {         TEST    AL,<HRetrace            ; Check for retrace in progress}
  $74/$FB/                     {         JZ      MvMHWait                ; Wait until retrace}
                               {;}
  $A4/                         {         MOVSB                           ; Now move one byte}
                               {;        STI                             ; Enable interrupts again}
                               {;}
  $81/$FB/$00/$00/             {         CMP     BX,0                    ; Are we finished?}
  $74/$19/                     {         JE      MvMEnd}
  $E2/$EC/                     {         LOOP    MvM1                    ; Only if CX not 0}
  $81/$FB/$00/$00/             {         CMP     BX,0}
  $74/$11/                     {         JE      MvMEnd}
                               {;}
                               {MvMDoCXAgain:}
  $D1/$EB/                     {         SHR     BX,1                    ; Convert back to words}
  $89/$D9/                     {         MOV     CX,BX                   ; Move words remaining to CX}
  $81/$F9/>MAXVERT/            {         CMP     CX,>MaxVert             ; Too many?}
  $7E/$03/                     {         JLE     MvMhMany                ; No, go move them.}
  $B9/>MAXVERT/                {         MOV     CX,>MaxVert             ; Yes, move MaxVert more}
                               {;}
                               {MvMhMany:}
  $29/$CB/                     {         SUB     BX,CX                   ; That many remain when movsw ends}
  $EB/$C3/                     {         JMP     MvMVWait}
                               {;}
                               {MvMEnd:                                  ; We've finished moving}
  $1F/                         {         POP     DS                      ; Restore the data segment}
                               {;}
                               {ClrArea:}
                               {;}
                               {;       We're now ready to blank the number of lines that were scrolled.}
                               {;       The direction flag and di and es are set correctly, given}
                               {;       what we've done so far.  All we need to do is calculate number of}
                               {;       words to blank.}
                               {;}
  $A1/>VIDEO_REQUEST/          {         MOV     AX,[>Video_Request]     ; To get number lines to scroll}
  $98/                         {         CBW}
  $8B/$0E/>MAX_SCREEN_COL/     {         MOV     CX,[>Max_Screen_Col]    ; Words/line}
  $F7/$E1/                     {         MUL     CX                      ; AX now has words to blank}
  $89/$C3/                     {         MOV     BX,AX                   ; Put it in BX}
                               {;}
  $8B/$16/>VIDEO_FILL/         {         MOV     DX,[>Video_Fill]        ; DH now has the fill attribute}
  $B2/$20/                     {         MOV     DL,' '                  ; Move a space to DL}
                               {;}
  $89/$D6/                     {         MOV     SI,DX                   ; Move clear char to si}
  $BA/>CRT_STATUS/             {         MOV     DX,>CRT_Status          ; Get video status register}
                               {;}
                               {ClrVert:                                 ; First wait for a vertical refresh}
  $89/$D9/                     {         MOV     CX,BX                   ; Move words remaining to CX}
  $81/$F9/>CLRMAXVERT/         {         CMP     CX,>ClrMaxVert          ; Too many?}
  $7E/$03/                     {         JLE     ClrMany                 ; No, go move them.}
  $B9/>CLRMAXVERT/             {         MOV     CX,>ClrMaxVert          ; Yes, move ClrMaxVert more}
                               {;}
                               {ClrMany:}
  $29/$CB/                     {         SUB     BX,CX                   ; That many remain when stosw ends}
                               {;}
                               {ClrVRefresh:}
  $EC/                         {         IN      AL,DX}
  $A8/<VRETRACE/               {         TEST    AL,<VRetrace}
  $75/$FB/                     {         JNZ     ClrVRefresh             ; Wait for a non retrace period}
                               {;}
                               {ClrVWait:}
  $EC/                         {         IN      AL,DX                   ; Get the retrace status}
  $A8/<VRETRACE/               {         TEST    AL,<VRetrace            ; Check for retrace in progress}
  $74/$FB/                     {         JZ      ClrVWait                ; Wait until retrace}
  $96/                         {         XCHG    AX,SI}
  $F2/$AB/                     {         REP     STOSW}
  $96/                         {         XCHG    AX,SI}
  $81/$FB/$00/$00/             {         CMP     BX,0}
  $74/$2E/                     {         JE      ClrEnd}
                               {;}
  $B9/>MAXHORIZ/               {         MOV     CX,>MaxHoriz}
                               {;}
                               {Clr1:}
  $4B/                         {         DEC     BX}
                               {;}
                               {ClrHRefresh:}
  $EC/                         {         IN      AL,DX}
  $A8/<HRETRACE/               {         TEST    AL,<HRetrace}
  $75/$FB/                     {         JNZ     ClrHRefresh             ; Wait for a non retrace period}
                               {;}
                               {;        CLI                             ; Disable interrupts while waiting}
                               {;}
                               {ClrHWait:}
  $EC/                         {         IN      AL,DX                   ; Get the retrace status}
  $A8/<HRETRACE/               {         TEST    AL,<HRetrace            ; Check for retrace in progress}
  $74/$FB/                     {         JZ      ClrHWait                ; Wait until retrace}
  $96/                         {         XCHG    AX,SI}
  $AB/                         {         STOSW                           ; Now move one word}
                               {;        STI                             ; Enable interrupts again}
  $96/                         {         XCHG    AX,SI}
  $81/$FB/$00/$00/             {         CMP     BX,0                    ; Are we finished?}
  $74/$17/                     {         JE      ClrEnd}
  $E2/$EA/                     {         LOOP    Clr1}
  $81/$FB/$00/$00/             {         CMP     BX,0}
  $74/$0F/                     {         JE      ClrEnd}
                               {;}
                               {ClrDoCXAgain:}
  $89/$D9/                     {         MOV     CX,BX                   ; Move words remaining to CX}
  $81/$F9/>CLRMAXVERT/         {         CMP     CX,>ClrMaxVert          ; Too many?}
  $7E/$03/                     {         JLE     ClrhMany                ; No, go move'm}
  $B9/>CLRMAXVERT/             {         MOV     CX,>ClrMaxVert          ; Yes, move ClrMaxVert more, Maximum}
                               {;}
                               {ClrHMany:}
  $29/$CB/                     {         SUB     BX,CX                   ; That many will remain when rep movsw e}
  $EB/$C3);                    {         JMP     ClrVWait}
                               {;}
                               {ClrEnd:                                  ; We've finished moving}
                               {;}

END   (* Video_Interrupt_Handler *);

(*----------------------------------------------------------------------*)
(* Install_Video_Handler --- Installs new interrupt $10 video driver    *)
(*----------------------------------------------------------------------*)

PROCEDURE Install_Video_Handler;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Install_Video_Handler                                *)
(*                                                                      *)
(*     Purpose:    Replaces standard interrupt $10 video driver         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Install_Video_Handler;                                        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Install_Video_Handler *)

                                   (* Initialize video variables    *)
   Video_Request     := 0;
   Video_Fill        := 0;
   Video_Page        := 0;
   Video_Mode        := Current_Video_Mode;
   Video_Screen_Addr := SEG( DesqView_Screen^ );

                                   (* Set interrupt routine address,  *)
                                   (* but only if software scrolling. *)
   IF Software_Scroll THEN
      BEGIN
         SetIntVec( Video_Interrupt , @Video_Interrupt_Handler );
         Video_Handler_Installed := TRUE;
      END;

END   (* Install_Video_Handler *);

(*----------------------------------------------------------------------*)
(*  Remove_Video_Handler --- Removes installed interrupt $10 driver     *)
(*----------------------------------------------------------------------*)

PROCEDURE Remove_Video_Handler;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Remove_Video_Handler                                 *)
(*                                                                      *)
(*     Purpose:    Restores standard interrupt $10 video driver         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Remove_Video_Handler;                                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Remove_Video_Handler *)

                     (* Restore the previous interrupt pointers *)

   SetIntVec( Video_Interrupt , Video_Save_Iaddr );

   Video_Handler_Installed := FALSE;

END   (* Remove_Video_Handler *);
