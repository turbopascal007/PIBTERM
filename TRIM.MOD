(*--------------------------------------------------------------------------*)
(*               Trim --- Trim trailing blanks from a string                *)
(*--------------------------------------------------------------------------*)

FUNCTION Trim( S : AnyStr ) : AnyStr;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Function:   Trim                                                     *)
(*                                                                          *)
(*     Purpose:    Trims trailing blanks from a string                      *)
(*                                                                          *)
(*     Calling sequence:                                                    *)
(*                                                                          *)
(*         Trimmed_S := TRIM( S );                                          *)
(*                                                                          *)
(*            S          --- the string to be trimmed                       *)
(*            Trimmed_S  --- the trimmed version of S                       *)
(*                                                                          *)
(*     Calls:  None                                                         *)
(*                                                                          *)
(*     Remarks:                                                             *)
(*                                                                          *)
(*        Note that the original string itself is left untrimmed.           *)
(*                                                                          *)
(*     Pascal version might be written as:                                  *)
(*                                                                          *)
(*        VAR                                                               *)
(*           I:       INTEGER;                                              *)
(*                                                                          *)
(*        BEGIN                                                             *)
(*                                                                          *)
(*           I := ORD( S[0] );                                              *)
(*                                                                          *)
(*           WHILE ( I > 0 ) AND ( S[I] = ' ' ) DO                          *)
(*              I := PRED( I );                                             *)
(*                                                                          *)
(*           S[0] := CHR( I );                                              *)
(*           Trim := S;                                                     *)
(*                                                                          *)
(*        END;                                                              *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

BEGIN (* Trim *)

INLINE(
  $1E/                   {         PUSH    DS                ; Save DS}
                         {;}
  $C5/$76/$06/           {         LDS     SI,[BP+6]         ; Get address of S}
  $FC/                   {         CLD                       ; Forward search}
  $AC/                   {         LODSB                     ; Get length of S}
  $3C/$00/               {         CMP     AL,0              ; See if length 0}
  $74/$21/               {         JE      Trim2             ; If so, no trimming required}
                         {;}
  $30/$ED/               {         XOR     CH,CH}
  $88/$C1/               {         MOV     CL,AL             ; Remember length for search loop}
                         {;}
  $B0/$20/               {         MOV     AL,' '            ; Blank to AL}
                         {;}
  $C4/$7E/$06/           {         LES     DI,[BP+6]         ; Get address of S}
  $01/$CF/               {         ADD     DI,CX             ; Point to end of source string}
                         {;}
  $FD/                   {         STD                       ; Backwards search}
  $F3/$AE/               {         REPE    SCASB             ; Scan over blanks}
  $74/$01/               {         JE      Trim1             ; If CX=0, entire string is blank.}
  $41/                   {         INC     CX}
                         {;}
  $88/$C8/               {Trim1:   MOV     AL,CL             ; Length to copy}
  $C5/$76/$06/           {         LDS     SI,[BP+6]         ; Source string address}
  $46/                   {         INC     SI                ; Skip length}
  $C4/$7E/$0A/           {         LES     DI,[BP+10]        ; Result string address}
  $FC/                   {         CLD                       ; Forward move}
  $AA/                   {         STOSB                     ; Set length in result}
  $F2/$A4/               {         REP     MOVSB             ; Move trimmed result}
  $E9/$04/$00/           {         JMP     Exit}
                         {;}
  $C4/$7E/$0A/           {Trim2:   LES     DI,[BP+10]        ; Result string address}
  $AA/                   {         STOSB                     ; Set length=0 in result}
                         {;}
  $1F);                  {Exit:    POP     DS                ; Restore DS}

END   (* Trim *);
