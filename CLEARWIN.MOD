(*----------------------------------------------------------------------*)
(*               Clear_Window --- Clear out lines in window             *)
(*----------------------------------------------------------------------*)

PROCEDURE Clear_Window;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Clear_Window                                         *)
(*                                                                      *)
(*     Purpose:    Clears screen for current window                     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Clear_Window                                                  *)
(*                                                                      *)
(*     Calls:   Upper_Left                                              *)
(*              GoToXY                                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Ytop: INTEGER;
   Xtop: INTEGER;
   Ybot: INTEGER;
   I   : INTEGER;

BEGIN (* Clear_Window *)

{
   Upper_Left( Xtop, Ytop );
   Ybot := Lower_Right_Row;

   FOR I := 1 TO ( Ybot - Ytop + 1 ) DO
      BEGIN
         GoToXY( 1 , I );
         ClrEol;
      END;
}
{
   Scroll( YTop, YBot, 1, Max_Screen_Col, 0, Global_ForeGround_Color,
           Global_BackGround_Color );
}
   ClrScr;
   MoveToXY( 1 , 1 );

END   (* Clear_Window *);
