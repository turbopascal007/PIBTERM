(*----------------------------------------------------------------------*)
(*         FastTime --- Get time of day in hours/min as integer         *)
(*----------------------------------------------------------------------*)

PROCEDURE FastTime( VAR HourMin: INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  FastTime                                             *)
(*                                                                      *)
(*     Purpose:    Get time of day in hours/min as integer              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        FastTime( VAR HourMin: INTEGER );                             *)
(*                                                                      *)
(*           HourMin --- Resultant time of day;                         *)
(*                       HI( HourMin ) = Hour;                          *)
(*                       LO( HourMin ) = Minutes.                       *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine is based upon one by Robert Tolz.                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* FastTime *)

   INLINE(
          {ON:}
           $B8/$00/$00 {          MOV    AX,$0000             ;READ TIME FUNCTION}
          /$CD/$1A {             INT    $1A                  ;CALL BIOS FOR TIME}
          /$89/$C8 {             MOV    AX,CX                ;PUT HI PORTION IN AX}
          /$89/$D3 {             MOV    BX,DX                ;AND LOW PORTION IN BX}
          /$D1/$E2 {             SHL    DX,1                 ;CALCULATE TIME}
          /$D1/$D1 {             RCL    CX,1                 ;I DONT KNOW HOW THIS}
          /$D1/$E2 {             SHL    DX,1                 ;WORKS, I LIFTED IT FROM}
          /$D1/$D1 {             RCL    CX,1                 ;THE ORIGINAL CLOCK.COM}
          /$01/$DA {             ADD    DX,BX                ;THAT I FOUND A LONG TIME}
          /$11/$C8 {             ADC    AX,CX                ;AGO. THANK YOU, WHOEVER YOU ARE!}
          /$92 {                 XCHG   DX,AX}
          /$B9/$0B/$E9 {         MOV    CX,$E90B}
          /$F7/$F1 {             DIV    CX}
          /$89/$C3 {             MOV    BX,AX}
          /$31/$C0 {             XOR    AX,AX}
          /$F7/$F1 {             DIV    CX}
          /$89/$DA {             MOV    DX,BX}
          /$B9/$C8/$00 {         MOV    CX,$00C8}
          /$F7/$F1 {             DIV    CX}
          /$80/$FA/$64 {         CMP    DL,$64               ;IS IT 100}
          /$72/$03 {             JB     UNDER}
          /$80/$EA/$64 {         SUB    DL,$64               ;SUBTRACT 100 IF > 100}
          /$F5 {    UNDER:       CMC}
          /$88/$D3 {             MOV    BL,DL}
          /$D1/$D0 {             RCL    AX,1}
          /$B2/$00 {             MOV    DL,00}
          /$D1/$D2 {             RCL    DX,1}
          /$B9/$3C/$00 {         MOV    CX,$003C}
          /$F7/$F1 {             DIV    CX}
          /$88/$D7 {             MOV    BH,DL}
          /$F6/$F1 {             DIV    CL}
          /$86/$E0 {             XCHG   AL,AH}
          /$89/$DA {             MOV    DX,BX                ;IN THE END, DX HOLDS SECONDS}

        /$91 (*                XCHG   CX,AX                ;AND CX HAS THE HOURS,MINUTES *)
        /$C4/$BE/HourMin   {   LES    DI,HourMin[BP]       ;Get address of HourMin }
        /$26/$89/$0D       {   MOV    ES:[DI],CX           ;Move hours/minutes to result }
        );

END   (* FastTime *);
