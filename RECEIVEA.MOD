(*----------------------------------------------------------------------*)
(*                Receive_Ascii_File --- Download ASCII file            *)
(*----------------------------------------------------------------------*)

PROCEDURE Receive_Ascii_File;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Receive_Ascii_File                                   *)
(*                                                                      *)
(*     Purpose:    Downloads ASCII file to PC                           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Receive_Ascii_File;                                           *)
(*                                                                      *)
(*     Calls:   PibTerm_KeyPressed                                      *)
(*              Async_Send                                              *)
(*              Async_Receive                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Ch            : CHAR;
   Fin           : BOOLEAN;
   X             : INTEGER;
   Y             : INTEGER;
   Line_Count    : LONGINT;
   Byte_Count    : LONGINT;
   Full_Name     : AnyStr;
   Ascii_Display : BOOLEAN;
   Use_Ch        : BOOLEAN;
   I             : INTEGER;
   Max_DLine     : INTEGER;
   R_Error       : BOOLEAN;
   AFile         : TEXT;
   Divider_Line  : INTEGER;
   Mess_Text     : AnyStr;
   Ascii_Title   : AnyStr;
   Alt_R_Hit     : BOOLEAN;
   SBSize        : STRING[20];
   SLSize        : STRING[20];
   OK_Disp_Size  : BOOLEAN;

(*----------------------------------------------------------------------*)
(* Initialize_Ascii_Receive_Display --- Start up transfer status window *)
(*----------------------------------------------------------------------*)

PROCEDURE Initialize_Ascii_Receive_Display;

VAR
   I: INTEGER;

BEGIN (* Initialize_Ascii_Receive_Display *)

                                   (* Figure display size              *)
   IF Do_Status_Line THEN
      Max_DLine := PRED( Max_Screen_Line )
   ELSE
      Max_DLine := Max_Screen_Line;

   Divider_Line := 13;

                                   (* Save current screen contents     *)
   Save_Screen( Saved_Screen );
                                   (* Open display window for received *)
                                   (* text lines.                      *)
   IF Ascii_Display THEN
      BEGIN

         TextColor( Menu_Text_Color );

         PibTerm_Window( 1, 1, Max_Screen_Col, Max_DLine );
         GoToXY( 1 , Divider_Line );

         FOR I := 1 TO 25 DO WRITE('=');

         TextColor( Menu_Text_Color_2 );
         WRITE('Received text displayed below');

         TextColor( Menu_Text_Color );
         FOR I := 1 TO 25 DO WRITE('=');

      END;
                                   (* Open display window for transfer  *)

   Draw_Menu_Frame( 15, 4, 78, 11, Menu_Frame_Color, Menu_Title_Color,
                    Menu_Text_Color, Ascii_Title );

                                   (* Headings for status information *)
   TextColor( Menu_Text_Color_2 );
   PibTerm_Window( 16, 5, 77, 10 );
   GoToXY( 1 , 1 );
   WRITELN(' Lines received: ');
   WRITELN(' Bytes received: ');
   WRITELN(' ');

   IF Ascii_Display THEN
      BEGIN
         PibTerm_Window( 1, SUCC( Divider_Line ), Max_Screen_Col, Max_DLine );
         GoToXY( 1 , 1 );
         Clear_Window;
      END;

END   (* Initialize_Ascii_Receive_Display *);

(*----------------------------------------------------------------------*)
(*        Flip_Display_Status --- turn status display on/off            *)
(*----------------------------------------------------------------------*)

PROCEDURE Flip_Display_Status;

BEGIN (* Flip_Display_Status *)

   CASE Display_Status OF

      TRUE:   BEGIN
                                   (* Indicate no display   *)

                 Display_Status := FALSE;

                                   (* Remove Ascii window  *)

                 Restore_Screen_And_Colors( Saved_Screen );

              END;

      FALSE:  BEGIN
                                   (* Indicate display will be done *)

                 Display_Status := TRUE;
                 Ascii_Display  := Ascii_Show_Text;

                                   (* Set up transfer status window *)

                 Initialize_Ascii_Receive_Display;

              END;

   END (* CASE *);

END   (* Flip_Display_Status *);

(*----------------------------------------------------------------------*)
(*      Activate_Status_Window --- switch to status display window      *)
(*----------------------------------------------------------------------*)

PROCEDURE Activate_Status_Window;

BEGIN (* Activate_Status_Window *)

   IF Ascii_Display THEN
      BEGIN
         X := WhereX;
         Y := WhereY;
         PibTerm_Window( 16, 5, 77, 10 );
      END;

END   (* Activate_Status_Window *);

(*----------------------------------------------------------------------*)
(*         Activate_Text_Window --- switch to text display window       *)
(*----------------------------------------------------------------------*)

PROCEDURE Activate_Text_Window;

BEGIN (* Activate_Text_Window *)

   IF Ascii_Display THEN
      BEGIN
         PibTerm_Window( 1, SUCC( Divider_Line ), Max_Screen_Col, Max_DLine );
         GoToXY( X , Y );
      END;

END   (* Activate_Text_Window *);

(*----------------------------------------------------------------------*)
(*  Update_Ascii_Receive_Display --- Update display of Xmodem reception *)
(*----------------------------------------------------------------------*)

PROCEDURE  Update_Ascii_Receive_Display;

BEGIN (* Update_Ascii_Receive_Display *)

   Activate_Status_Window;

   TextColor( Menu_Text_Color );

   GoToXY( 17 , 1 );
   WRITE( Line_Count:8 );
   GoToXY( 17 , 2 );
   WRITE( Byte_Count:8 );

   Activate_Text_Window;

   TextColor( Menu_Text_Color_2 );

END   (* Update_Ascii_Receive_Display *);

(*----------------------------------------------------------------------*)

BEGIN (* Receive_Ascii_File *)
                                   (* Initialize *)
   Fin           := FALSE;
   Line_Count    := 0;
   Byte_Count    := 0;
   X             := 1;
   Y             := 1;
   Ascii_Display := Ascii_Show_Text;
   Use_Ch        := TRUE;
   R_Error       := FALSE;
   Alt_R_Hit     := FALSE;
                                   (* Remove cursor                    *)
   CursorOff;
                                   (* Initialize transfer display      *)

   Ascii_Title := 'Receive file ' + FileName + ' using ASCII';

   Initialize_Ascii_Receive_Display;

   Write_Log( Ascii_Title, FALSE, FALSE );

                                   (* Open reception file *)

   Add_Path( FileName, Download_Dir_Path, Full_Name );

   ASSIGN    ( Afile, Full_Name );
   SetTextBuf( AFile , Sector_Data );
   REWRITE   ( AFile );

   R_Error := ( INT24Result <> 0 );

   REPEAT
                                   (* Check for Alt_R -- ends transfer; *)
                                   (* Shift_Tab flips display status    *)
      WHILE PibTerm_KeyPressed DO
         BEGIN
            Read_Kbd( Ch );
            IF ( Ch = CHR( ESC ) ) AND PibTerm_KeyPressed THEN
               BEGIN
                  Read_Kbd( Ch );
                  IF ORD( Ch ) = Alt_R THEN
                     BEGIN
                        Fin       := TRUE;
                        Alt_R_Hit := TRUE;
                     END
                  ELSE IF ORD( Ch ) = Shift_Tab THEN
                     Flip_Display_Status
                  ELSE
                     Handle_Function_Key( Ch );
               END
            ELSE
               Async_Send( Ch );
         END;

      IF Async_Receive( Ch ) THEN
         BEGIN

            IF Auto_Strip_High_Bit THEN
               Ch := CHR( ORD( Ch ) AND $7F );

            IF Ascii_Translate THEN
               BEGIN
                  Ch     := TrTab[ Ch ];
                  Use_Ch := ( ORD( Ch ) <> NUL );
               END;

            IF Use_Ch THEN
               BEGIN

                  WRITE( AFile , Ch );
                  R_Error := R_Error OR ( INT24Result <> 0 );

                  IF Ascii_Display THEN
                     WRITE( Ch );

                  INC( Byte_Count );

                  IF ( Ch = CHR( CR ) ) THEN
                     BEGIN

                        INC( Line_Count );

                        IF Display_Status THEN
                           Update_Ascii_Receive_Display;

                        IF Add_LF THEN
                           BEGIN

                              WRITE( AFile , CHR( LF ) );
                              R_Error := R_Error OR ( INT24Result <> 0 );

                              IF Ascii_Display THEN
                                 WRITE( CHR( LF ) );

                              INC( Byte_Count );

                           END;

                     END
                  ELSE IF Ascii_Use_CtrlZ THEN
                     IF ( Ch = ^Z ) THEN
                        Fin := TRUE;

               END;

         END;

      Fin := Fin OR Async_Carrier_Drop OR R_Error;

                                   (* Print character from spooled file *)
      IF Print_Spooling THEN
         Print_Spooled_File;

   UNTIL ( Fin );
                                   (* Ensure status window is up *)
   IF ( NOT Display_Status ) THEN
      Flip_Display_Status;

   Activate_Status_Window;
                                   (* Get termination status message *)
   OK_Disp_Size := FALSE;

   IF Async_Carrier_Drop THEN
      Mess_Text := 'Carrier dropped, receive cancelled.'
   ELSE IF Alt_R_Hit THEN
      Mess_Text := 'Alt-R hit, receive stopped.'
   ELSE IF ( NOT R_Error ) THEN
      BEGIN
         Mess_Text    := 'Receive completed.';
         OK_Disp_Size := TRUE;
      END
   ELSE
      Mess_Text := 'Error in receive.';

                                   (* Display termination status message *)
   IF OK_Disp_Size THEN
      BEGIN

         STR( Byte_Count , SBSize );
         STR( Line_Count , SLSize );

         Write_Log('Size of file received was ' + SBSize + ' bytes, ' +
                   SLSize + ' lines', TRUE, FALSE );

      END;

   GoToXY( 1 , 4 );
   Write_Log( Mess_Text , TRUE , TRUE );

   Window_Delay;

   CLOSE( AFile );

   R_Error := ( INT24Result <> 0 );

                                   (* Remove this window            *)

   Restore_Screen_And_Colors( Saved_Screen );
                                   (* Reset cursor                  *)
   CursorOn;

END   (* Receive_Ascii_File *);
