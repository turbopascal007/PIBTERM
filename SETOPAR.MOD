(*----------------------------------------------------------------------*)
(*     Set_Other_Parameters --- Set other parameters at init. time      *)
(*----------------------------------------------------------------------*)

PROCEDURE Set_Other_Parameters;

VAR
   Regs : Registers;
   N    : INTEGER;

BEGIN (* Set_Other_Parameters *)
                                   (* Initialize text mode *)

   IF Text_Mode <> New_Text_Mode THEN
      BEGIN
         Text_Mode := New_Text_Mode;
         Set_Text_Mode( Text_Mode );
      END;
                                   (* Update wait-for-retrace option *)

   Wait_For_Retrace := Wait_For_Retrace_Par AND
                       ( NOT ( EGA_Present OR ( Current_Video_Mode = 7 ) ) );

                                   (* Set write to screen mode *)

   Write_Screen_Memory := Write_Screen_Memory_Par (* OR TimeSharingActive *);

                                   (* Get screen sizes *)

   Max_Screen_Col  := New_Max_Screen_Col;
   Max_Screen_Line := New_Max_Screen_Line;

                                   (* Fix up EGA/VGA display *)
   IF EGA_Installed THEN
      BEGIN
                                   (* Set screen width for ATI *)
         IF ATI_Ega_Wonder THEN
            BEGIN
               CASE Max_Screen_Col OF
                  132: BEGIN
                          Regs.AX := $23;
                          INTR( $10, Regs );
                       END;
                  ELSE BEGIN
                          Regs.AX := $03;
                          INTR( $10, Regs );
                       END;
               END (* CASE *);
            END (* BEGIN *);
                                   (* Set screen length *)
         N := Get_Rows_For_EGA;

         IF ( Max_Screen_Line <> N ) THEN
            Set_EGA_Text_Mode( Max_Screen_Line );

      END;
                                   (* Set window size *)

   PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line );

                                   (* Set colors *)

   ForeGround_Color  := New_ForeGround_Color;
   BackGround_Color  := New_BackGround_Color;
   Menu_Text_Color   := New_Menu_Text_Color;
   Menu_Text_Color_2 := New_Menu_Text_Color_2;
   Menu_Title_Color  := New_Menu_Title_Color;
   Menu_Frame_Color  := New_Menu_Frame_Color;
   Border_Color      := New_Border_Color;

   Set_Global_Colors( ForeGround_Color , BackGround_Color );
   Set_Border_Color ( Border_Color );

                                   (* Set screen attributes *)

   Set_Text_Attributes( 1, 1, Max_Screen_Col, Max_Screen_Line,
                        ForeGround_Color, BackGround_Color );

                                   (* Update software_scrolling option *)

   Software_Scroll := Software_Scroll_Par AND Wait_For_Retrace AND
                      Write_Screen_Memory AND ( NOT TimeSharingActive );

                                   (* Fixup keyboard handler if needed *)
   IF Extended_Keypad THEN
      Install_Keyboard_Handler;
                                   (* Fixup video handler if needed    *)
   IF Software_Scroll THEN
      Install_Video_Handler;
                                   (* Open the logging file *)

   Add_Path( Log_File_Name, Home_Dir, Log_File_Name );

   IF Logging_On THEN
      IF ( NOT Log_File_Open ) THEN
         Log_File_Open := Open_For_Append( Log_File,
                                           Log_File_Name, N );

                                   (* Set new line mode *)
   New_Line := New_Line_Param;

END   (* Set_Other_Parameters *);