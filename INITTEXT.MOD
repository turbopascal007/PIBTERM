(*----------------------------------------------------------------------*)
(*         Init_Text_Terminal --- Initialize text mode terminals        *)
(*----------------------------------------------------------------------*)

PROCEDURE Init_Text_Terminal;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Init_Text_Terminal                                   *)
(*                                                                      *)
(*     Purpose:    Initializes text mode terminal emulations.           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Init_Text_Terminal;                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Cur_Video : INTEGER;

BEGIN (* Init_Text_Terminal *)
                                   (* Ensure we're in text mode *)
   Do_Status_Time := FALSE;

                                   (* Pick up terminal name     *)

   Short_Terminal_Name := Terminal_Name_List[ ORD( Terminal_To_Emulate ) ];

   Cur_Video := Current_Video_Mode;

   IF ( ( Cur_Video = HiRes_GraphMode ) OR
        ( Cur_Video = EGA_GraphMode   )    ) THEN
      BEGIN
         Set_Text_Mode( Text_Mode );
         IF EGA_Present THEN
            Set_EGA_Text_Mode( Max_Screen_Line );
         Reset_Global_Colors;
      END;

   PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line );

   Draw_Titled_Box( Saved_Screen, 10, 10, 55, 15, '' );

   WRITELN('Beginning ',
           Long_Terminal_Names[ ORD( Terminal_To_Emulate ) ], ' Emulation');

   Window_Delay;

   Restore_Screen_And_Colors( Saved_Screen );

                                   (* Load function keys             *)
   IF Auto_Load_FunKeys THEN
      Load_Function_Keys( Short_Terminal_Name + '.FNC' );

                                   (* Scroll screen up if on last line *)

   IF ( WhereY = Max_Screen_Line ) THEN
      BEGIN
         GoToXY( WhereX , PRED( Max_Screen_Line ) );
         Scroll( 1, Max_Screen_Line, 1, Max_Screen_Col, 1,
                 ForeGround_Color, BackGround_Color );
      END;

END   (* Init_Text_Terminal *);
