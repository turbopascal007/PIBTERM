(*----------------------------------------------------------------------*)
(*          YesNo --- Prompt for and read Yes/No question/answer        *)
(*----------------------------------------------------------------------*)

FUNCTION YesNo( YesNo_Question : AnyStr ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   YesNo                                                *)
(*                                                                      *)
(*     Purpose:    Prompt for and read Yes/No question/answer           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Yes_Answer := YesNo( YesNo_Question : AnyStr ) : BOOLEAN;     *)
(*                                                                      *)
(*           YesNo_Question --- Text of Yes/No question to be asked     *)
(*           Yes_Answer     --- Set TRUE if "Yes" answer given, else    *)
(*                              set FALSE.                              *)
(*                                                                      *)
(*      Calls:   Read_Kbd                                               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Ans_Ch: CHAR;
   X     : INTEGER;
   Y     : INTEGER;

BEGIN (* YesNo *)

   WRITELN;

   X      := WhereX;
   Y      := WhereY;

   Ans_Ch := ' ';

   TextColor( Menu_Text_Color_2 );

   REPEAT

      GoToXY( X , Y );
      ClrEol;
      WRITE( YesNo_Question );
      Read_Kbd( Ans_Ch );
      Ans_Ch := UpCase( Ans_Ch );

   UNTIL( Ans_Ch IN ['Y','N'] );

   TextColor( Menu_Text_Color );

   IF Ans_Ch = 'Y' THEN
      BEGIN
         YesNo := TRUE;
         WRITE('Yes');
      END
   ELSE
      BEGIN
         YesNo := FALSE;
         WRITE('No');
      END;

END   (* YesNo *);
