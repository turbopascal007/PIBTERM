(*----------------------------------------------------------------------*)
(*         Do_VT52_LineFeeds --- Do special VT52 linefeed processing    *)
(*----------------------------------------------------------------------*)

PROCEDURE Do_VT52_LineFeeds( Ch : CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Do_VT52_LineFeeds                                    *)
(*                                                                      *)
(*     Purpose:    Handle line feeds for VT52 mode                      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Do_VT52_LineFeeds( Ch: CHAR );                                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   X          : INTEGER;
   Y          : INTEGER;
   Print_Line : AnyStr;

BEGIN (* Do_VT52_LineFeeds *)

   IF Capture_On THEN
      Capture_Char( Ch );

   X := WhereX;
   Y := SUCC( WhereY );

   IF ( Y < Max_Screen_Line ) THEN
      GoToXY( X , Y )
   ELSE
      Scroll( 1, PRED( Max_Screen_Line ), 1, Max_Screen_Col, 1,
              ForeGround_Color, BackGround_Color );

   IF Auto_Print_Mode THEN
      BEGIN
         Get_Screen_Text_Line( Print_Line, PRED( WhereY ), 1 );
         Write_Prt_Str( Print_Line  );
         Write_Prt_Str( CRLF_String );
      END;

   IF Printer_On THEN
      Write_Prt( Ch );

   IF Review_On THEN
      Update_Review_Pointers;

END   (* Do_VT52_LineFeeds *);
