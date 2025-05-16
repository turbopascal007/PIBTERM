(*----------------------------------------------------------------------*)
(*       Write_To_Status_Line --- Write text to status line             *)
(*----------------------------------------------------------------------*)

PROCEDURE Write_To_Status_Line( S: AnyStr; X: INTEGER );

BEGIN (* Write_To_Status_Line *)

   IF ( ( NOT Graphics_Terminal_Mode ) AND Do_Status_Line ) THEN
      WriteSXY( S, X, Max_Screen_Line, Status_Line_Attr );

END   (* Write_To_Status_Line *);
