(*--------------------------------------------------------------------------*)
(*                     Dupl -- Duplicate a character n times                *)
(*--------------------------------------------------------------------------*)

FUNCTION Dupl( Dup_char : Char; Dup_Count: INTEGER ) : AnyStr;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*    Function: Dupl                                                        *)
(*                                                                          *)
(*    Purpose:  Duplicate a character n times                               *)
(*                                                                          *)
(*    Calling Sequence:                                                     *)
(*                                                                          *)
(*       Dup_String := Dupl( Dup_Char: Char; Dup_Count: INTEGER ): AnyStr;  *)
(*                                                                          *)
(*          Dup_Char   --- Character to be duplicated                       *)
(*          Dup_Count  --- Number of times to duplicate character           *)
(*          Dup_String --- Resultant duplicated string                      *)
(*                                                                          *)
(*          Note:  If Dup_Count <= 0, a null string is returned.            *)
(*                                                                          *)
(*    Calls:  None                                                          *)
(*                                                                          *)
(*                                                                          *)
(*    Remarks:                                                              *)
(*                                                                          *)
(*       This routine could be programmed directly in Turbo as:             *)
(*                                                                          *)
(*          VAR                                                             *)
(*             S    : AnyStr;                                               *)
(*                                                                          *)
(*          BEGIN                                                           *)
(*                                                                          *)
(*             FillChar( S[1], Dup_Count, Dup_Char );                       *)
(*             S[0] := CHR( Dup_Count );                                    *)
(*                                                                          *)
(*             Dupl := S;                                                   *)
(*                                                                          *)
(*          END;                                                            *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

BEGIN (* Dupl *)

INLINE(
  $8B/$4E/$06/           {         MOV       CX,[BP+6]  ; Pick up dup count}
  $C4/$7E/$0A/           {         LES       DI,[BP+10] ; Result address}
  $FC/                   {         CLD                  ; Set direction flag}
  $88/$C8/               {         MOV       AL,CL      ; Get result length}
  $AA/                   {         STOSB                ; Store result length}
  $8B/$46/$08/           {         MOV       AX,[BP+8]  ; Get char to duplicate}
  $F2/$AA);              {         REP       STOSB      ; Perform duplication}

END   (* Dupl *);
