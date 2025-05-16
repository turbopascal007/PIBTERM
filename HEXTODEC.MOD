(*----------------------------------------------------------------------*)
(*         Hex_To_Dec --- Convert hex string to decimal number          *)
(*----------------------------------------------------------------------*)

FUNCTION Hex_To_Dec( S : AnyStr; Default : INTEGER ) : INTEGER;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Hex_To_Dec                                           *)
(*                                                                      *)
(*     Purpose:    Convert hex string to decimal number                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Integ := Hex_To_Dec( S: AnyStr; Default: INTEGER ) : INTEGER; *)
(*                                                                      *)
(*           S       --- the hex string                                 *)
(*           Default --- value to return if S not hex string            *)
(*           Integ   --- corresponding decimal integer (0 if bad)       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I  : INTEGER;
   Sum: INTEGER;

BEGIN (* Hex_To_Dec *)

   Sum        := 0;
   Hex_To_Dec := Default;

   FOR I := 1 TO LENGTH( S ) DO
      CASE S[I] OF
         '0'..'9':  Sum := Sum * 16 + ( ORD(S[I]) - ORD('0') );
         'A'..'F':  Sum := Sum * 16 + ( ORD(S[I]) - ORD('A') + 10 );
         ELSE       EXIT;
      END;

   Hex_To_Dec := Sum;

END   (* Hex_To_Dec *);
