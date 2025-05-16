(*--------------------------------------------------------------------------*)
(*               LTrim --- LTrim leading blanks from a string               *)
(*--------------------------------------------------------------------------*)

FUNCTION LTrim( S : AnyStr ) : AnyStr;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Function:   LTrim                                                    *)
(*                                                                          *)
(*     Purpose:    Trims leading blanks from a string                       *)
(*                                                                          *)
(*     Calling sequence:                                                    *)
(*                                                                          *)
(*         LTrimmed_S := TRIM( S );                                         *)
(*                                                                          *)
(*            S           --- the string to be trimmed                      *)
(*            LTrimmed_S  --- the trimmed version of S                      *)
(*                                                                          *)
(*     Calls:  None                                                         *)
(*                                                                          *)
(*     Remarks:                                                             *)
(*                                                                          *)
(*        Note that the original string itself is left untrimmed.           *)
(*                                                                          *)
(*     A Pascal version of this routine could be written as:                *)
(*                                                                          *)
(*        VAR                                                               *)
(*           I:       INTEGER;                                              *)
(*           L:       INTEGER;                                              *)
(*                                                                          *)
(*        BEGIN                                                             *)
(*                                                                          *)
(*           I := 1;                                                        *)
(*           L := ORD( S[0] );                                              *)
(*                                                                          *)
(*           WHILE ( ( I <= L ) AND ( S[I] = ' ' ) ) DO                     *)
(*              I := SUCC( I );                                             *)
(*                                                                          *)
(*           S[0]  := CHR( MAX( L - I + 1 , 0 ) );                          *)
(*                                                                          *)
(*           MOVE( S[I], S[1], ORD( S[0] ) );                               *)
(*                                                                          *)
(*           LTrim := S;                                                    *)
(*                                                                          *)
(*        END;                                                              *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

BEGIN (* LTrim *)

INLINE(
  $1E/                   {         PUSH    DS                ; Save DS}
                         {;}
  $C5/$76/$06/           {         LDS     SI,[BP+6]         ; Get address of S}
  $FC/                   {         CLD                       ; Forward search}
  $AC/                   {         LODSB                     ; Get length of S}
  $3C/$00/               {         CMP     AL,0              ; See if length 0}
  $74/$20/               {         JE      LTrim2            ; If so, no trimming required}
                         {;}
  $31/$C9/               {         XOR     CX,CX}
  $88/$C1/               {         MOV     CL,AL             ; Remember length for search loop}
                         {;}
  $B0/$20/               {         MOV     AL,' '            ; Blank to AL}
                         {;}
  $C4/$7E/$06/           {         LES     DI,[BP+6]         ; Get address of S}
  $47/                   {         INC     DI                ; Skip length}
  $F3/$AE/               {         REPE    SCASB             ; Scan over blanks}
  $74/$01/               {         JE      LTrim1            ; If CX=0, entire string is blank.}
  $41/                   {         INC     CX}
                         {;}
  $88/$C8/               {LTrim1:  MOV     AL,CL             ; Length to copy}
  $89/$FE/               {         MOV     SI,DI             ; Offset of first non-blank}
  $4E/                   {         DEC     SI}
  $8E/$5E/$08/           {         MOV     DS,[BP+8]         ; Segment for S}
  $C4/$7E/$0A/           {         LES     DI,[BP+10]        ; Result string address}
  $AA/                   {         STOSB                     ; Set length in result}
  $F2/$A4/               {         REP     MOVSB             ; Move trimmed result}
  $E9/$04/$00/           {         JMP     Exit}
                         {;}
  $C4/$7E/$0A/           {LTrim2:  LES     DI,[BP+10]        ; Result string address}
  $AA/                   {         STOSB                     ; Set length=0 in result}
                         {;}
  $1F);                  {Exit:    POP     DS                ; Restore DS}

END   (* LTrim *);
