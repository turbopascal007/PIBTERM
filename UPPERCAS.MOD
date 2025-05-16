(*--------------------------------------------------------------------------*)
(*               UpperCase --- Convert string to upper case                 *)
(*--------------------------------------------------------------------------*)

FUNCTION UpperCase( S: AnyStr ): AnyStr;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*    Function: UpperCase                                                   *)
(*                                                                          *)
(*    Purpose:  Convert string to upper case                                *)
(*                                                                          *)
(*    Calling Sequence:                                                     *)
(*                                                                          *)
(*       Upper_String := UpperCase( S : AnyStr ): AnyStr;                   *)
(*                                                                          *)
(*          S            --- String to be converted to upper case           *)
(*          Upper_String --- Resultant uppercase string                     *)
(*                                                                          *)
(*    Calls:  UpCase                                                        *)
(*                                                                          *)
(*    Remarks:                                                              *)
(*                                                                          *)
(*       This routine could be coded directly in Turbo as:                  *)
(*                                                                          *)
(*          VAR                                                             *)
(*              I    : INTEGER;                                             *)
(*              L    : INTEGER;                                             *)
(*              T    : AnyStr;                                              *)
(*                                                                          *)
(*          BEGIN                                                           *)
(*                                                                          *)
(*             L := ORD( S[0] );                                            *)
(*                                                                          *)
(*             FOR I := 1 TO L DO                                           *)
(*                T[I] := UpCase( S[I] );                                   *)
(*                                                                          *)
(*             T[0]      := CHR( L );                                       *)
(*             UpperCase := T;                                              *)
(*                                                                          *)
(*         END;                                                             *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

BEGIN (* UpperCase *)

INLINE(
  $1E/                   {         PUSH    DS                ; Save DS}
  $C5/$76/$06/           {         LDS     SI,[BP+6]         ; Get source string address}
  $C4/$7E/$0A/           {         LES     DI,[BP+10]        ; Get result string address}
  $FC/                   {         CLD                       ; Forward direction for strings}
  $AC/                   {         LODSB                     ; Get length of source string}
  $AA/                   {         STOSB                     ; Copy to result string}
  $30/$ED/               {         XOR     CH,CH}
  $88/$C1/               {         MOV     CL,AL             ; Move string length to CL}
  $E3/$0E/               {         JCXZ    Exit              ; Skip if null string}
                         {;}
  $AC/                   {UpCase1: LODSB                     ; Get next source character}
  $3C/$61/               {         CMP     AL,'a'            ; Check if lower-case letter}
  $72/$06/               {         JB      UpCase2}
  $3C/$7A/               {         CMP     AL,'z'}
  $77/$02/               {         JA      UpCase2}
  $2C/$20/               {         SUB     AL,'a'-'A'        ; Convert to uppercase}
                         {;}
  $AA/                   {UpCase2: STOSB                     ; Store in result}
  $E2/$F2/               {         LOOP    UpCase1}
                         {;}
  $1F);                  {Exit:    POP     DS                ; Restore DS}


END   (* UpperCase *);
