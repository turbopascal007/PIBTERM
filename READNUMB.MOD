(*----------------------------------------------------------------------*)
(*              Read_Number --- Read in a number                        *)
(*----------------------------------------------------------------------*)

FUNCTION Read_Number(      Old_Number: LongInt;
                           Use_Old   : BOOLEAN;
                       VAR Number    : LongInt ) : BOOLEAN;

VAR
   S     : AnyStr;
   I     : INTEGER;
   Ch    : CHAR;
   X     : INTEGER;
   Y     : INTEGER;
   LIval : LONGINT;

BEGIN (* Read_Number *)

   IF Use_Old THEN
      STR( Old_Number , S )
   ELSE
      S := '';

   X  := WhereX;
   Y  := WhereY;

   Ch := Edit_String( S, 255, X, X, Y, 20, FALSE, 0 );

   IF ( Ch <> CHR( ESC ) ) THEN
      BEGIN
         S := LTrim( Trim( S ) );
         VAL( S, LIval, I );
      END
   ELSE
     I := 1;

   IF ( I = 0 ) THEN
      BEGIN
         Number      := LIval;
         Read_Number := TRUE;
      END
   ELSE
      BEGIN
         Number      := Old_Number;
         Read_Number := FALSE;
      END;

END   (* Read_Number *);
