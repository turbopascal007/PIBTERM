(*----------------------------------------------------------------------*)
(*         Dec_To_Hex --- Convert decimal number to hex string          *)
(*----------------------------------------------------------------------*)

FUNCTION Dec_To_Hex( Integr : WORD ) : ShortStr;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Dec_To_Hex                                           *)
(*                                                                      *)
(*     Purpose:    Convert decimal integer to hex string                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        HexString := Dec_To_Hex( Integr : WORD ) : ShortStr;          *)
(*                                                                      *)
(*           Integr     --- decimal integer to convert to hex           *)
(*           HexString  --- resultant hex string                        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   L : INTEGER;
   H : INTEGER;

CONST
   Digits : ARRAY[0..15] OF CHAR = ('0','1','2','3','4','5','6','7','8','9',
                                    'A','B','C','D','E','F');

BEGIN (* Dec_To_Hex *)

   L          := LO( Integr );
   H          := HI( Integr );

   Dec_To_Hex := Digits[ H SHR 4 ] + Digits[ H AND $F ] +
                 Digits[ L SHR 4 ] + Digits[ L AND $F ];

END   (* Dec_To_Hex *);
