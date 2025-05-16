(*----------------------------------------------------------------------*)
(*    Reset_General_Terminal --- Reset terminal to initial defaults     *)
(*----------------------------------------------------------------------*)

PROCEDURE Reset_General_Terminal( ClearScreen : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Routine:  Reset_General_Terminal                                 *)
(*                                                                      *)
(*     Purpose:  Resets general emulation                               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Reset_General_Terminal( ClearScreen : BOOLEAN );              *)
(*                                                                      *)
(*           ClearScreen --- TRUE to clear screen                       *)
(*                                                                      *)
(*     Called by:  Emulate_General                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Reset_General_Terminal *)
                                   (* Turn on the cursor            *)
   CursorOn;
                                   (* Initialize terminal state     *)
   Do_Status_Time      := OFF;
   Alt_Keypad_Mode     := OFF;
   Graphics_Mode       := OFF;
   Auto_Print_Mode     := OFF;
   Printer_Ctrl_Mode   := OFF;
   Auto_Wrap_Mode      := ON;
   Hold_Screen_Mode    := OFF;
   New_Line            := New_Line_Param;
   Insertion_Mode      := OFF;
   Double_Width_Mode   := OFF;
   Do_Script_Tests     := Waitstring_Mode OR When_Mode OR
                          WaitCount_Mode  OR WaitQuiet_Mode OR
                          Script_Learn_Mode;

                                   (* Set display actions *)
   Set_Display_Actions;
                                   (* Get terminal name *)

   Short_Terminal_Name := Terminal_Name_List[ ORD( Terminal_To_Emulate ) ];

                                   (* Set up status line *)

   IF Reverse_Status_Colors THEN
      Status_Line_Attr    := 16 * ( ForeGround_Color AND 7 ) + BackGround_Color
   ELSE
      Status_Line_Attr    := 16 * ( Status_BackGround_Color AND 7 ) + Status_ForeGround_Color;

   Do_Status_Line      := Show_Status_Line AND ( NOT Use_Dos_Con_Output );
   Do_Status_Time      := Do_Status_Line AND Show_Status_Time;
   Current_Status_Time := -1;

   IF Do_Status_Line THEN
      BEGIN
         Set_Status_Line_Name(Short_Terminal_Name);
         Write_To_Status_Line( Status_Line_Name, 1 );
         Ansi_Last_Line := PRED( Max_Screen_Line );
         PibTerm_Window( 1, 1, Max_Screen_Col, Ansi_Last_Line );
      END
   ELSE
      Ansi_Last_Line := Max_Screen_Line;

                                   (* Ensure proper screen length *)

   Wrap_Screen_Col := Max_Screen_Col;

                                   (* Reset escape mode      *)
   Escape_Mode           := FALSE;
   Escape_Str            := '';

                                   (* Reset scrolling region *)
   Top_Scroll            := 1;
   Bottom_Scroll         := Ansi_Last_Line;

                                   (* Clear screen if requested *)
   IF ClearScreen THEN
      BEGIN
         Scroll( 1, Ansi_Last_Line, 1, Max_Screen_Col, 0,
                 ForeGround_Color, BackGround_Color );
         NewX := 1;
         NewY := 1;
         GoToXY( 1 , 1 );
      END
   ELSE
      BEGIN
         NewX := WhereX;
         NewY := WhereY;
      END;
                                   (* Clear line attributes *)

   FillChar( Line_Attributes, 100, 0 );

END   (* Reset_General_Terminal *);
