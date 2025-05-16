VAR
   Alt_S_Pressed     : BOOLEAN     (* TRUE if Alt_S entered             *);
   Alt_R_Pressed     : BOOLEAN     (* TRUE if Alt_R entered             *);
   Sending_Files     : BOOLEAN     (* TRUE if sending file(s)           *);
   Menu_Title        : AnyStr      (* Title for transfer                *);
   Menu_Length       : INTEGER     (* # of rows in transfer display     *);
   XFile_Name        : AnyStr      (* Full file name including path     *);
   Blocks_To_Send    : LONGINT     (* Number of blocks to send          *);
   Time_To_Send      : LONGINT     (* Time in seconds to transfer file  *);
   Saved_Time_To_Send: LONGINT     (* Time in seconds to transfer file  *);
   Start_Time        : LONGINT     (* Starting time of transfer         *);
   End_Time          : LONGINT     (* Ending time of transfer           *);
   Time_Per_Block    : LONGINT     (* Time for one block                *);
   CRC_Used          : BOOLEAN     (* TRUE if CRC used                  *);
   Display_Time      : BOOLEAN     (* Display time remaining for trans. *);
   Transfer_Protocol : Transfer_Type   (* Protocol for transfer         *);
   Do_Acks           : BOOLEAN     (* TRUE to send ACKs for blocks      *);

(* STRUCTURED *) CONST
   Days_Per_Month : ARRAY[1..12] OF BYTE
                    = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

(*----------------------------------------------------------------------*)
(*             Cancel_Transfer --- Cancel transfer                      *)
(*----------------------------------------------------------------------*)

PROCEDURE Cancel_Transfer;

BEGIN (* Cancel_Transfer *)
                                   (* Purge reception unless G protocol *)
   IF Do_Acks THEN
      Async_Purge_Buffer;
                                   (* Send five cancels, then five *)
                                   (* backspaces.                  *)
   Async_Send( CHR( CAN ) );
   Async_Send( CHR( CAN ) );
   Async_Send( CHR( CAN ) );
   Async_Send( CHR( CAN ) );
   Async_Send( CHR( CAN ) );

   Async_Send( CHR( BS  ) );
   Async_Send( CHR( BS  ) );
   Async_Send( CHR( BS  ) );
   Async_Send( CHR( BS  ) );
   Async_Send( CHR( BS  ) );

   Write_Log('Transfer cancelled.' , TRUE, FALSE );

END   (* Cancel_Transfer *);

(*----------------------------------------------------------------------*)
(*   Initialize_Receive_Display --- Set up display of Xmodem reception  *)
(*----------------------------------------------------------------------*)

PROCEDURE Initialize_Receive_Display;

BEGIN (* Initialize_Receive_Display *)

   TextColor( Menu_Text_Color_2 );

   GoToXY( 1 , 1 );
   WRITE(' Blocks received      :');
   ClrEol;

   GoToXY( 1 , 2 );
   WRITE(' Block length errors  :');
   ClrEol;

   GoToXY( 1 , 3 );
   WRITE(' SOH errors           :');
   ClrEol;

   GoToXY( 1 , 4 );
   WRITE(' Block number errors  :');
   ClrEol;

   GoToXY( 1 , 5 );
   WRITE(' Complement errors    :');
   ClrEol;

   GoToXY( 1 , 6 );
   WRITE(' Timeout errors       :');
   ClrEol;

   GoToXY( 1 , 7 );
   WRITE(' Resend block errors  :');
   ClrEol;

   GoToXY( 1 , 8 );

   IF ( NOT CRC_Used ) THEN
      WRITE(' Checksum errors      :')
   ELSE
      WRITE(' CRC errors           :');

   ClrEol;

   GoToXY( 1 , 9 );

   IF Display_Time THEN
      WRITE(' Approx. time left    :')
   ELSE
      WRITE(' ');

   ClrEol;

   GoToXY( 1 , 10 );
   WRITE  (' Last status message  :');
   ClrEol;

   TextColor( Menu_Text_Color );

END   (* Initialize_Receive_Display *);

(*----------------------------------------------------------------------*)
(*        Initialize_Send_Display --- initialize send status display    *)
(*----------------------------------------------------------------------*)

PROCEDURE Initialize_Send_Display;

BEGIN (* Initialize_Send_Display *)

   TextColor( Menu_Text_Color_2 );
   WRITE  (' Blocks to send        : ');
   TextColor( Menu_Text_Color   );
   WRITE  ( Blocks_To_Send );
   GoToXY( 35 , WhereY );
   WRITE  ( Blocks_To_Send SHR 3, 'K' );
   WRITELN;

   TextColor( Menu_Text_Color_2 );
   WRITE  (' Approx. transfer time : ');
   TextColor( Menu_Text_Color );
   WRITELN( TimeString( Time_To_Send , Military_Time ) );
   WRITELN(' ');

   TextColor( Menu_Text_Color_2 );
   WRITELN(' Sending block         : ');
   WRITELN(' Errors                : ');
   WRITE  (' Time remaining        : ');

   TextColor( Menu_Text_Color );
   WRITELN(TimeString( Time_To_Send , Military_Time ) );
   WRITELN(' ');

   TextColor( Menu_Text_Color_2 );
   WRITE  (' Last status message   : ');

   TextColor( Menu_Text_Color );

END   (* Initialize_Send_Display *);

(*----------------------------------------------------------------------*)
(*   Get_Transfer_Name  --- Get transfer name for display window        *)
(*----------------------------------------------------------------------*)

FUNCTION Get_Transfer_Name( Transfer_Protocol : Transfer_Type ) : ShortStr;

VAR
   TName : ShortStr;

BEGIN (* Get_Transfer_Name *)

   CASE Transfer_Protocol OF
      Xmodem_Chk   : TName := 'Xmodem (Checksum)';
      Xmodem_Crc   : TName := 'Xmodem (CRC)';
      Telink       : TName := 'Telink';
      Modem7_Chk   : TName := 'Modem7 (Checksum)';
      Modem7_CRC   : TName := 'Modem7 (CRC)';
      Xmodem_1K    : TName := 'Xmodem 1K';
      Xmodem_1KG   : TName := 'Xmodem 1K G';
      Ymodem_Batch : TName := 'Ymodem Batch';
      Ymodem_G     : TName := 'Ymodem G Batch';
   END (* CASE *);

   Get_Transfer_Name := TName;

END   (* Get_Transfer_Name *);

(*----------------------------------------------------------------------*)
(*   Display_Batch_Transfer_Window --- Display batch transfer window    *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Batch_Window;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Display_Batch_Window;                                *)
(*                                                                      *)
(*     Purpose:    Initializes display for batch transfer window        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Display_Batch_Window                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   TName       : ShortStr;
   Batch_Title : AnyStr;
   Direction   : ShortStr;

BEGIN (* Display_Batch_Window *)
                                   (* Save current screen image *)
   Save_Screen( Batch_Screen_Ptr );
                                   (* Construct title based upon *)
                                   (* transfer type              *)

   TName := Get_Transfer_Name( Transfer_Protocol );

                                   (* Draw menu frame            *)

   IF Sending_Files THEN
      Direction := 'send'
   ELSE
      Direction := 'receive';

   Batch_Title := 'Batch file ' + Direction + ' using ' + TName;

   Draw_Menu_Frame( 2, 2, 79, 24, Menu_Frame_Color, Menu_Title_Color,
                    Menu_Text_Color, Batch_Title );

   Write_Log( Batch_Title , FALSE , FALSE );

   PibTerm_Window( 3, 3, 78, 23 );

END   (* Display_Batch_Window *);

(*----------------------------------------------------------------------*)
(*        Flip_Display_Status --- turn status display on/off            *)
(*----------------------------------------------------------------------*)

PROCEDURE Flip_Display_Status;

BEGIN (* Flip_Display_Status *)

   CASE Display_Status OF

      TRUE:   BEGIN
                                   (* Indicate no display   *)

                 Display_Status := FALSE;

                                   (* Remove XMODEM window  *)

                 Restore_Screen( Saved_Screen );

                                   (* Remove batch transfer window *)

                 Restore_Screen( Batch_Screen_Ptr );

                                   (* Turn cursor back on *)
                 CursorOn;

              END;

      FALSE:  BEGIN
                                   (* Indicate display will be done *)

                 Display_Status := TRUE;

                                   (* Turn cursor off *)
                 CursorOff;

                                   (* Initialize batch transfer display *)
                                   (* if needed.                        *)

                 IF ( NOT Single_File_Protocol[Transfer_Protocol] ) THEN
                    Display_Batch_Window;

                                   (* Save screen image *)

                 Save_Screen( Saved_Screen );

                                   (* Set up transfer display box *)

                 Draw_Menu_Frame( 10, 10, 78, Menu_Length,
                                  Menu_Frame_Color,
                                  Menu_Title_Color,
                                  Menu_Text_Color,
                                  Menu_Title );

                 PibTerm_Window( 11, 11, 77, PRED( Menu_Length ) );

                                   (* Set up titles *)

                 CASE Sending_Files OF
                    TRUE:   Initialize_Send_Display;
                    FALSE:  Initialize_Receive_Display;
                 END (* CASE *);

              END;

   END (* CASE *);

END   (* Flip_Display_Status *);

(*----------------------------------------------------------------------*)
(*         Check_Keyboard_Input --- Check for keyboard input            *)
(*----------------------------------------------------------------------*)

PROCEDURE Check_Keyboard;

VAR
   Kbd_Ch : CHAR;

BEGIN (* Check_Keyboard *)
                                   (* Check for keyboard input *)
   WHILE PibTerm_KeyPressed DO
      BEGIN

         Read_Kbd( Kbd_Ch );

         IF ( Kbd_Ch = CHR( ESC ) ) THEN
            IF PibTerm_KeyPressed THEN
               BEGIN
                  Read_Kbd( Kbd_Ch );
                  CASE ORD( Kbd_Ch ) OF
                     Alt_R     : Alt_R_Pressed := TRUE;
                     Alt_S     : Alt_S_Pressed := TRUE;
                     Shift_Tab : Flip_Display_Status;
                     ELSE        Handle_Function_Key( Kbd_Ch );
                  END (* CASE *);
                  Stop_Receive   := Stop_Receive OR Alt_R_Pressed;
                  Stop_Send      := Stop_Send    OR Alt_S_Pressed;
               END
           ELSE
               IF Async_XOff_Received THEN
                  Clear_XOFF_Received;

      END;

END   (* Check_Keyboard *);

(*----------------------------------------------------------------------*)
(*         Get_Xmodem_Titles --- Get title for Xmodem transfer          *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Xmodem_Titles;

VAR
   Direction : ShortStr;
   TName     : ShortStr;

BEGIN (* Get_Xmodem_Titles *)
                                   (* Open display window for transfer  *)
   Save_Screen( Saved_Screen );
                                   (* Hide cursor *)
   CursorOff;
                                   (* Get protocol name *)

   TName := Get_Transfer_Name( Transfer_Protocol );

   IF Sending_Files THEN
      BEGIN
         Direction   := 'Send ';
         Menu_Length := 19;
      END
   ELSE
      BEGIN
         Direction   := 'Receive ';
         Menu_Length := 22;
      END;

   IF FileName = '' THEN
      Menu_Title := Direction + 'file using ' + TName
   ELSE
      Menu_Title := Direction + 'file ' + XFile_Name + ' using ' + TName;

   Draw_Menu_Frame( 10, 10, 78, Menu_Length, Menu_Frame_Color,
                    Menu_Title_Color,
                    Menu_Text_Color, Menu_Title );

   Write_Log( Menu_Title, FALSE, FALSE );

   PibTerm_Window( 11, 11, 77, PRED( Menu_Length ) );

END   (* Get_Xmodem_Titles *);

(*----------------------------------------------------------------------*)
(*      Save_Comm_For_Xmodem --- Save and reset comm parms for Xmodem   *)
(*----------------------------------------------------------------------*)

PROCEDURE Save_Comm_For_Xmodem;

BEGIN (* Save_Comm_For_Xmodem *)
                                   (* Set comm. parms to 8,n,1 *)

   Xmodem_Bits_Save   := Data_Bits;
   Xmodem_Parity_Save := Parity;

   IF ( Data_Bits <>  8  ) OR
      ( Parity    <> 'N' ) THEN
         BEGIN
            Parity    := 'N';
            Data_Bits := 8;
            Async_Reset_Port( Comm_Port, Baud_Rate, Parity, Data_Bits, Stop_Bits );
         END;

                                   (* Reset status line *)
   IF Do_Status_Line THEN
      BEGIN
         Set_Status_Line_Name( Short_Terminal_Name );
         Write_To_Status_Line( Status_Line_Name, 1 );
      END;

END   (* Save_Comm_For_Xmodem *);

(*----------------------------------------------------------------------*)
(*      Restore_Comm_For_Xmodem --- Restore comm parms after Xmodem     *)
(*----------------------------------------------------------------------*)

PROCEDURE Restore_Comm_For_Xmodem;

BEGIN (* Restore_Comm_For_Xmodem *)

                                   (* Reset comm parms to saved values *)

   IF ( Xmodem_Bits_Save   <>  8  ) OR
      ( Xmodem_Parity_Save <> 'N' ) THEN
         BEGIN
            Parity    := Xmodem_Parity_Save;
            Data_Bits := Xmodem_Bits_Save;
            Async_Reset_Port( Comm_Port, Baud_Rate, Parity,
                              Data_Bits, Stop_Bits );
         END;

                                   (* Reset status line *)
   IF Do_Status_Line THEN
      BEGIN
         Set_Status_Line_Name( Short_Terminal_Name );
         Write_To_Status_Line( Status_Line_Name, 1 );
      END;

END   (* Restore_Comm_For_Xmodem *);

(*----------------------------------------------------------------------*)
(*           Get_Unix_Style_Date --- Get date in Unix style             *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Unix_Style_Date(     Date  : LONGINT;
                               VAR Year  : WORD;
                               VAR Month : WORD;
                               VAR Day   : WORD;
                               VAR Hour  : WORD;
                               VAR Mins  : WORD;
                               VAR Secs  : WORD );

CONST
   Secs_Per_Year      = 31536000;
   Secs_Per_Leap_Year = 31622400;
   Secs_Per_Day       = 86400;
   Secs_Per_Hour      = 3600;
   Secs_Per_Minute    = 60;

VAR
   RDate     : LONGINT;
   T         : LONGINT;

BEGIN (* Get_Unix_Style_Date *)

   Year  := 1970;
   Month := 1;
{
   IF ( Transfer_Protocol <> SEALink ) THEN
      RDate := Date - GMT_Difference * Secs_Per_Hour
   ELSE
      RDate := Date;
}
   RDate := Date - GMT_Difference * Secs_Per_Hour;

   WHILE( RDate > 0 ) DO
      BEGIN

         IF ( Year MOD 4 ) = 0 THEN
            T := Secs_Per_Leap_Year
         ELSE
            T := Secs_Per_Year;

         RDate := RDate - T;

         INC( Year );

      END;

   RDate := RDate + T;

   DEC( Year );

   IF ( Year MOD 4 ) = 0 THEN
      Days_Per_Month[2] := 29
   ELSE
      Days_Per_Month[2] := 28;

   WHILE( RDate > 0 ) DO
      BEGIN

         T     := Days_Per_Month[Month] * Secs_Per_Day;

         RDate := RDate - T;

         INC( Month );

      END;

   RDate := RDate + T;

   DEC( Month );

   Day   := TRUNC( INT( ( RDate + PRED( Secs_Per_Day ) ) / Secs_Per_Day  ) );
   RDate := RDate - LONGINT( PRED( Day ) ) * Secs_Per_Day;

   Hour  := TRUNC( INT( RDate / Secs_Per_Hour ) );
   RDate := RDate - LONGINT( Hour ) * Secs_Per_Hour;

   Mins  := TRUNC( INT( RDate / Secs_Per_Minute ) );
   Secs  := TRUNC( RDate - LONGINT( Mins ) * Secs_Per_Minute );

END   (* Get_Unix_Style_Date *);

(*----------------------------------------------------------------------*)
(*          Set_Unix_Style_Date --- Set UNIX style date                 *)
(*----------------------------------------------------------------------*)

PROCEDURE Set_Unix_Style_Date( VAR Date  : LONGINT;
                                   Year  : WORD;
                                   Month : WORD;
                                   Day   : WORD;
                                   Hour  : WORD;
                                   Mins  : WORD;
                                   Secs  : WORD );

CONST
   Secs_Per_Year      = 31536000;
   Secs_Per_Leap_Year = 31622400;
   Secs_Per_Day       = 86400;
   Secs_Per_Hour      = 3600;
   Secs_Per_Minute    = 60;

VAR
   RDate     : LONGINT;
   T         : LONGINT;
   Leap_Year : BOOLEAN;
   I         : INTEGER;

BEGIN (* Set_Unix_Style_Date *)
{
   IF ( Transfer_Protocol = SEALink ) THEN
      Date := 0
   ELSE
      Date := GMT_Difference * Secs_Per_Hour;
}

   Date := GMT_Difference * Secs_Per_Hour;

   FOR I := 1970 TO PRED( Year ) DO
      BEGIN

         IF ( I MOD 4 ) = 0 THEN
            T := Secs_Per_Leap_Year
         ELSE
            T := Secs_Per_Year;

         Date := Date + T;

      END;

   IF ( Year MOD 4 ) = 0 THEN
      Days_Per_Month[2] := 29
   ELSE
      Days_Per_Month[2] := 28;

   FOR I := 1 TO PRED( Month ) DO
      Date := Date + LONGINT( Days_Per_Month[I] ) * Secs_Per_Day;

   Date  := Date + LONGINT( PRED( Day ) ) * Secs_Per_Day    +
                   LONGINT( Hour        ) * Secs_Per_Hour   +
                   LONGINT( Mins        ) * Secs_Per_Minute +
                   Secs;

END   (* Set_Unix_Style_Date *);

(*----------------------------------------------------------------------*)
(*    Extract_Upload_Path_Name --- Extract the upload path name         *)
(*----------------------------------------------------------------------*)

PROCEDURE Extract_Upload_Path_Name( VAR File_Pattern    : AnyStr;
                                    VAR Upload_Dir_Path : AnyStr );

VAR
   I   : INTEGER;
   Done: BOOLEAN;

BEGIN (* Extract_Upload_Path_Name *)

   I    := LENGTH( File_Pattern ) + 1;
   Done := FALSE;

   WHILE ( NOT Done ) DO
      BEGIN
         DEC( I );
         Done := ( File_Pattern[I] = ':' ) OR
                 ( File_Pattern[I] = '\' ) OR
                 ( I = 1 );
      END;

   IF ( I > 1 ) THEN
      Upload_Dir_Path := COPY( File_Pattern, 1, I )
   ELSE
      BEGIN
         GetDir( 0 , Upload_Dir_Path );
         IF ( Int24Result <> 0 ) THEN
            Upload_Dir_Path := '';
      END;

   IF ( POS( '\', Upload_Dir_Path ) <> 0 ) THEN
      IF ( Upload_Dir_Path[LENGTH( Upload_Dir_Path )] <> '\' ) THEN
         Upload_Dir_Path := Upload_Dir_Path + '\';

END   (* Extract_Upload_Path_Name *);

(*----------------------------------------------------------------------*)
(*    End_Batch_Transfer --- Display messages at end of batch transfer  *)
(*----------------------------------------------------------------------*)

PROCEDURE End_Batch_Transfer;

BEGIN (* End_Batch_Transfer *)
                                   (* Indicate end of transfer    *)
   WRITELN(' ');
   RvsVideoOn ( Menu_Text_Color, BLACK );

   WRITELN('  Batch transfer complete.');
   Write_Log('Batch transfer complete.', FALSE, FALSE );

   RvsVideoOff( Menu_Text_Color, BLACK );

   Window_Delay;
                                   (* Remove batch transfer window *)

   Restore_Screen_And_Colors( Batch_Screen_Ptr );

END   (* End_Batch_Transfer *);
