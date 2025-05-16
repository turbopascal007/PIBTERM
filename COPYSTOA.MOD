(*--------------------------------------------------------------------------*)
(*                 CopyStoA -- Copy string to character array               *)
(*--------------------------------------------------------------------------*)

PROCEDURE CopyStoA( S : AnyStr; VAR A ; Length_A : INTEGER );

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*    Procedure: CopyStoA                                                   *)
(*                                                                          *)
(*    Purpose:   Copies string to character array, blank fill               *)
(*                                                                          *)
(*    Calling Sequence:                                                     *)
(*                                                                          *)
(*       CopyStoA( S : AnyStr; VAR A ; Length_A: INTEGER );                 *)
(*                                                                          *)
(*          S        --- String to be copied                                *)
(*          A        --- Character array to be copied into                  *)
(*          Length_A --- No. of characters in A                             *)
(*                                                                          *)
(*    Calls:  None                                                          *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   I    : INTEGER;
   AA   : PACKED ARRAY[ 1 .. 1 ] OF CHAR ABSOLUTE A;

BEGIN (* CopyStoA *)

   FillChar( AA[1], Length_A, ' ' );
   MOVE    ( S [1], AA[1],    MIN( Length_A , LENGTH( S ) ) );

END   (* CopyStoA *);

(*--------------------------------------------------------------------------*)
(*       CopyS2AR -- Copy string to character array, right adjust           *)
(*--------------------------------------------------------------------------*)

PROCEDURE CopyS2AR( S : AnyStr; VAR A ; Length_A : INTEGER );

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*    Procedure: CopyS2AR                                                   *)
(*                                                                          *)
(*    Purpose:   Copies string to character array, blank fill on left       *)
(*                                                                          *)
(*    Calling Sequence:                                                     *)
(*                                                                          *)
(*       CopyS2AR( S : AnyStr; VAR A ; Length_A: INTEGER );                 *)
(*                                                                          *)
(*          S        --- String to be copied                                *)
(*          A        --- Character array to be copied into                  *)
(*          Length_A --- No. of characters in A                             *)
(*                                                                          *)
(*    Calls:  None                                                          *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   I        : INTEGER;
   Len_S    : INTEGER;
   Len_A    : INTEGER;
   L        : INTEGER;
   AA       : PACKED ARRAY[ 1 .. 1 ] OF CHAR ABSOLUTE A;

BEGIN (* CopyS2AR *)

   Len_S  := LENGTH( S );
   Len_A  := Length_A;
   L      := MIN( Len_A , Len_S );

   FOR I := 1 TO L DO
      BEGIN
         AA[Len_A] := S[Len_S];
         DEC( Len_A );
         DEC( Len_S );
      END;

   FOR I := Len_A DOWNTO 1 DO
      AA[I] := ' ';

END   (* CopyS2AR *);
