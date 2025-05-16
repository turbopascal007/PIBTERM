(*----------------------------------------------------------------------*)
(*                Display_Help --- Display Command List                 *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Help( FirstTime : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Display_Help                                         *)
(*                                                                      *)
(*     Purpose:    Displays Command List                                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Display_Help( FirstTime : BOOLEAN );                          *)
(*                                                                      *)
(*           FirstTime --- TRUE for first call, else FALSE              *)
(*                                                                      *)
(*     Calls:    PibTerm_KeyPressed                                             *)
(*               Async_Send                                             *)
(*               Restore_Screen                                         *)
(*               Save_Screen                                            *)
(*               Draw_Menu_Frame                                        *)
(*               Read_Kbd                                               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Ch: CHAR;

(*----------------------------------------------------------------------*)

PROCEDURE Write_Help( Command_Ch : CHAR;
                      Help_Text  : AnyStr;
                      XPos       : INTEGER;
                      YPos       : INTEGER );

BEGIN (* Write_Help *)

   WriteSXY( ' <ALT>' + Command_Ch + ':  ', XPos + 2, YPos + 6, Menu_Text_Color_2 );
   WriteSXY( Help_Text, XPos + 12, YPos + 6, Menu_Text_Color );

END   (* Write_Help *);

(*----------------------------------------------------------------------*)

BEGIN (* Display_Help *)
                                   (* Tell host to stop sending *)
   IF Do_Xon_Xoff_Checks THEN
      Async_Send( CHR( XOFF ) );
                                   (* Save current screen image *)
   Save_Screen( Saved_Screen );
                                   (* Display help information  *)

   Draw_Menu_Frame( 2, 1, 78, 24, Menu_Frame_Color, Menu_Title_Color,
                    Menu_Text_Color, ' Available Commands ' );

   TextColor( Menu_Text_Color_2 );

   WRITELN;
   WRITELN( '  PibTerm Version ', PibTerm_Version);
   WRITELN( '  ' , PibTerm_Date);
   WRITELN( '  ' , CopyRight_Notice);

   Write_Help( 'A', 'Edit line on screen', 1 , 1 );
   Write_Help( 'B', 'Send Break',          38, 1 );

   Write_Help( 'C', 'Clear Screen',        1,  2 );
   Write_Help( 'D', 'Dial a number',       38, 2 );

   IF Local_Echo THEN
      Write_Help( 'E', 'Toggle local echo (now ON)' , 1, 3 )
   ELSE
      Write_Help( 'E', 'Toggle local echo (now OFF)', 1, 3 );
   Write_Help( 'F', 'File manipulation', 38, 3 );

   Write_Help( 'G', 'Execute script',    1,  4 );
   Write_Help( 'H', 'Hang up the phone', 38, 4 );

   Write_Help( 'I', 'Produce this command list', 1,  5 );
   Write_Help( 'J', 'Jump to DOS',               38, 5 );

   Write_Help( 'K', 'Set function keys',         1,  6 );

   IF Printer_On THEN
      Write_Help( 'L', 'Log to printer (now ON)',  38, 6 )
   ELSE
      Write_Help( 'L', 'Log to printer (now OFF)', 38, 6 );

   IF Silent_Mode THEN
      Write_Help( 'M', 'Toggle Mute Mode (now ON)',  1,  7  )
   ELSE
      Write_Help( 'M', 'Toggle Mute Mode (now OFF)', 1,  7  );
   Write_Help( 'N', 'New comm. parameters',         38, 7  );

   IF Capture_On THEN
      Write_Help( 'O', 'Capture session (now ON)',  1,  8  )
   ELSE
      Write_Help( 'O', 'Capture session (now OFF)', 1,  8  );

   Write_Help( 'P', 'Set parameters',               38, 8  );

   Write_Help( 'Q', 'Redial last number dialed',    1,  9  );
   Write_Help( 'R', 'Receive file from remote',     38, 9  );

   Write_Help( 'S', 'Send file to remote',          1,  10 );
   Write_Help( 'T', 'Get translate table',          38, 10 );

   Write_Help( 'U', 'Screen dump to file',          1,  11 );
   Write_Help( 'V', 'View captured text',           38, 11 );

   Write_Help( 'W', 'Enter host mode',              1,  12 );
   Write_Help( 'X', 'Exit PibTerm',                 38, 12 );

   Write_Help( 'Y', 'Display session information',  1,  13 );
   Write_Help( 'Z', 'Get area code',                38, 13 );

   GoToXY( 3 , 20 );
   TextColor( Menu_Text_Color_2 );

   WRITE('Hit ESC to continue, or Alt-letter to execute command.');
   TextColor( Menu_Text_Color );

                                   (* Wait for key to be hit        *)

   Read_Kbd( Ch );                 (* Read 2 chars if 1st was ESC   *)

   IF ( ( Ch = CHR( ESC ) ) AND PibTerm_KeyPressed ) THEN
      BEGIN
         Read_Kbd( Ch );
         IF ORD( Ch ) IN Alt_Let_Set THEN
            Keyboard_Buffer := Keyboard_Buffer + #$E0 + #$E0 + Ch;
      END;
                                   (* Tell host to continue sending *)
   IF Do_Xon_Xoff_Checks THEN
      Async_Send( CHR( XON ) );
                                   (* Restore previous screen image *)

   Restore_Screen_And_Colors( Saved_Screen );

END   (* Display_Help *);
