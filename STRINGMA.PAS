UNIT StringMan;

INTERFACE

USES
   Dos, Crt, GlobType;

FUNCTION Min( A, B: INTEGER ) : INTEGER;

FUNCTION Max( A, B: INTEGER ) : INTEGER;

FUNCTION Hex_To_Dec( S : AnyStr; Default : INTEGER ) : INTEGER;

FUNCTION Dec_To_Hex( Integr : WORD ) : ShortStr;

FUNCTION IToS( Integr : INTEGER ) : ShortStr;

FUNCTION Dupl( Dup_char : Char; Dup_Count: INTEGER ) : AnyStr;

FUNCTION Trim( S : AnyStr ) : AnyStr;

FUNCTION LTrim( S : AnyStr ) : AnyStr;

FUNCTION UpperCase( S: AnyStr ): AnyStr;

PROCEDURE CopyStoA( S : AnyStr; VAR A ; Length_A : INTEGER );

PROCEDURE CopyS2AR( S : AnyStr; VAR A ; Length_A : INTEGER );

FUNCTION Read_Ctrls( S : AnyStr ) : AnyStr;

FUNCTION Write_Ctrls( S : AnyStr ) : AnyStr;

IMPLEMENTATION
                                   (* Find minimum/maximum of numbers   *)
{$I MINMAX.MOD   }
                                   (* Convert hex string to decimal #   *)
{$I HEXTODEC.MOD }
                                   (* Convert decimal # to hex string   *)
{$I DECTOHEX.MOD }
                                   (* Convert integer to string         *)
{$I ITOS.MOD     }
                                   (* Duplicate a character into string *)
{$I DUPL.MOD     }
                                   (* Trim blanks from end of string    *)
{$I TRIM.MOD     }
                                   (* Trim blanks from front of string  *)
{$I LTRIM.MOD    }
                                   (* Convert string to uppercase       *)
{$I UPPERCAS.MOD }
                                   (* Copy string to array of char      *)
{$I COPYSTOA.MOD }
                                   (* Read string with control chars    *)
{$I READCTRL.MOD }
                                   (* Write string with control chars   *)
{$I WRITCTRL.MOD }
END   (* StringMan *).
