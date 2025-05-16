(*----------------------------------------------------------------------*)
(*                Send_Ascii_File --- Upload ASCII file                 *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Ascii_File;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Send_Ascii_File                                      *)
(*                                                                      *)
(*     Purpose:    Uploads ASCII file to remote host                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Send_Ascii_File;                                              *)
(*                                                                      *)
(*     Calls:   PibTerm_KeyPressed                                      *)
(*              Send_String_With_Delays_And_Echo                        *)
(*              Async_Receive                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   Pacing_Delay  = 0.10            (* Approx. time added per line for pacing *);
   Modem_Fudge   = 0.85            (* Approx. fudge factor for timing        *);
   Max_Wait_Time = 60              (* Maximum wait time for output drain     *);

VAR
   Ch           : CHAR;
   A_Ch         : CHAR;
   Fin          : BOOLEAN;
   TextLine     : AnyStr;
   Esc_Found    : BOOLEAN;
   B            : BOOLEAN;
   Pace_Found   : BOOLEAN;
   Line_Count   : LONGINT;
   Line_Kount   : LONGINT;
   Byte_Count   : LONGINT;
   Time_To_Send : LONGINT;
   Length_Line  : LONGINT;
   R_Baud_Rate  : REAL;
   Start_Time   : LONGINT;
   Pacing       : BOOLEAN;
   Pace_Time    : BOOLEAN;
   I            : INTEGER;
   X            : INTEGER;
   Y            : INTEGER;
   Ascii_Display: BOOLEAN;
   EOF_AFile    : BOOLEAN;
   Do_Send_Blank: BOOLEAN;
   CR_LF_String : ShortStr;
   SBSize       : STRING[20];
   SLSize       : STRING[20];

                                   (* Read buffer pointer               *)

   Read_Buffer  : File_Handle_Buffer_Ptr;

   Buffer_Pos   : INTEGER          (* Current buffer position           *);
   Buffer_Length: INTEGER          (* Buffer length                     *);
   Buffer_Size  : INTEGER          (* Buffer size as read               *);
   AFile        : FILE             (* File for read                     *);
   Max_DLine    : INTEGER          (* Maximum display line for transfer *);
   Long_Buffer  : BOOLEAN          (* TRUE if long buffer being used    *);
   R_Char_Delay : REAL             (* Character delay in seconds        *);
   R_Line_Delay : REAL             (* Line delay in seconds             *);
   Ascii_Title  : AnyStr           (* Title for transfer                *);
   Alt_S_Hit    : BOOLEAN          (* TRUE if Alt-S hit.                *);
   T1           : LONGINT          (* Starting time for end-of-send     *);

LABEL 1;

(*----------------------------------------------------------------------*)
(*     Initialize_Send_Window --- initialize send status window area    *)
(*----------------------------------------------------------------------*)

PROCEDURE Initialize_Send_Window;

BEGIN (* Initialize_Send_Window *)

   Save_Screen( Saved_Screen );

   Draw_Menu_Frame( 15, 3, 78, 14, Menu_Frame_Color, Menu_Title_Color,
                    Menu_Text_Color, Ascii_Title );

   PibTerm_Window( 16, 4, 77, 13 );

END   (* Initialize_Send_Window *);

(*----------------------------------------------------------------------*)
(*   Initialize_Status_Display --- initialize transfer status display   *)
(*----------------------------------------------------------------------*)

PROCEDURE Initialize_Status_Display;

VAR
   I: INTEGER;

BEGIN (* Initialize_Status_Display *)

                                   (* Figure last line in display *)
   IF ( NOT Do_Status_Line ) THEN
      Max_DLine := Max_Screen_Line
   ELSE
      Max_DLine := PRED( Max_Screen_Line );

                                   (* Transfer statistics  *)

   TextColor( Menu_Text_Color_2 );
   WRITE  (' Characters to send    : ');
   TextColor( Menu_Text_Color );
   WRITELN( Byte_Count:8 );
   TextColor( Menu_Text_Color_2 );
   WRITE  (' Lines to send         : ');
   TextColor( Menu_Text_Color );
   WRITELN( Line_Count:8 );
   TextColor( Menu_Text_Color_2 );
   WRITE  (' Approx. transfer time : ');
   TextColor( Menu_Text_Color );
   WRITELN( TimeString( Time_To_Send , Military_Time ) );
   WRITELN(' ');
   TextColor( Menu_Text_Color_2 );
   WRITELN(' Sending line          : ');
   WRITELN(' Bytes left to send    : ');
   WRITE  (' Approx. time left     : ');
   TextColor( Menu_Text_Color );
   WRITELN( TimeString( Time_To_Send , Military_Time ) );

                                   (* Open display window for received *)
                                   (* text lines.                      *)
   IF Ascii_Display THEN
      BEGIN

         PibTerm_Window( 1, 1, Max_Screen_Col, Max_DLine );
         GoToXY( 1 , 15 );

         TextColor( Menu_Text_Color );

         FOR I := 1 TO 24 DO WRITE('=');

         TextColor( Menu_Text_Color_2 );

         WRITE('Output from remote system below');

         TextColor( Menu_Text_Color );

         FOR I := 1 TO 25 DO WRITE('=');

         PibTerm_Window( 1, 16, Max_Screen_Col, Max_DLine );
         GoToXY( 1 , 1 );
         Clear_Window;

      END;

END   (* Initialize_Status_Display *);

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

                 Restore_Screen_And_Colors( Saved_Screen );

              END;

      FALSE:  BEGIN
                                   (* Indicate display will be done *)

                 Display_Status := TRUE;
                 Ascii_Display  := Ascii_Show_Text;

                                   (* Save screen image *)

                 Save_Screen( Saved_Screen );

                                   (* Initialize Ascii display window   *)

                 Initialize_Send_Window;
                 Initialize_Status_Display;

              END;

   END (* CASE *);

END   (* Flip_Display_Status *);

(*----------------------------------------------------------------------*)
(*      Activate_Status_Window --- Activate the display status window   *)
(*----------------------------------------------------------------------*)

PROCEDURE Activate_Status_Window;

BEGIN (* Activate_Status_Window *)

   IF Ascii_Display THEN
      BEGIN
         X := WhereX;
         Y := WhereY;
         PibTerm_Window( 16, 4, 77, 13 );
      END;

END   (* Activate_Status_Window *);

(*----------------------------------------------------------------------*)
(*         Activate_Text_Window --- switch to text display window       *)
(*----------------------------------------------------------------------*)

PROCEDURE Activate_Text_Window;

BEGIN (* Activate_Text_Window *)

   IF Ascii_Display THEN
      BEGIN
         PibTerm_Window( 1, 16, Max_Screen_Col, Max_DLine );
         GoToXY( X , Y );
      END;

END   (* Activate_Text_Window *);

(*----------------------------------------------------------------------*)
(*      Ascii_Receive --- Interface to receive character from port      *)
(*----------------------------------------------------------------------*)

FUNCTION Ascii_Receive( VAR Ch: CHAR ) : BOOLEAN;

VAR
   KeyC: CHAR;

BEGIN (* Ascii_Receive *)

   IF Async_Receive( Ch ) THEN
      BEGIN

         Ascii_Receive := TRUE;

         CASE ORD( Ch ) OF

            NUL  : Ascii_Receive := FALSE;  (* Strip Nulls   *)
            DEL  : Ascii_Receive := FALSE;  (* Strip Deletes *)
            BELL : Menu_Beep;
            ELSE
                   IF Ascii_Display THEN
                      WRITE( Ch );

         END (* CASE *);
      END
   ELSE
      Ascii_Receive := FALSE;

END   (* Ascii_Receive *);

(*----------------------------------------------------------------------*)
(*      Ascii_Send --- Interface to send character out over serial port *)
(*----------------------------------------------------------------------*)

PROCEDURE Ascii_Send( Ch : CHAR );

BEGIN (* Ascii_Send *)

   IF Ascii_Display THEN
      Async_Send_Now( Ch )
   ELSE
      Async_Send( Ch );

END   (* Ascii_Send *);

(*----------------------------------------------------------------------*)
(*     Update_Ascii_Send_Display --- Update display of Ascii upload     *)
(*----------------------------------------------------------------------*)

PROCEDURE Update_Ascii_Send_Display;

BEGIN (* Update_Ascii_Send_Display *)

   Activate_Status_Window;

   TextColor( Menu_Text_Color );

   GoToXY( 26 , 5 );
   WRITE( Line_Count:8 );
   GoToXY( 26 , 6 );
   WRITE( Byte_Count:8 );
   GoToXY( 26 , 7 );
   WRITE( TimeString( Time_To_Send , Military_Time ) );

   Activate_Text_Window;

END   (* Update_Ascii_Send_Display *);

(*----------------------------------------------------------------------*)
(*         Send_Ascii_Line --- send one line of text from file          *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Ascii_Line;

VAR
   B: BOOLEAN;
   I: INTEGER;

BEGIN (* Send_Ascii_Line *)

   FOR I := 1 TO LENGTH( TextLine ) DO
      BEGIN
                                   (* Send a character *)
         Ascii_Send( TextLine[I] );

                                   (* Intercharacter delay *)

         IF ( Ascii_Char_Delay > 0 ) THEN
            DELAY( Ascii_Char_Delay );

                                   (* Print a character from spooled file *)
         IF Print_Spooling THEN
            Print_Spooled_File;
                                   (* Process any received character *)
         B := Ascii_Receive( Ch );

      END;
                                   (* Interline delay *)
   IF ( NOT Pacing ) THEN
      BEGIN

         IF ( Ascii_Line_Delay > 0 ) THEN
            DELAY( Ascii_Line_Delay );

                                   (* Drain the buffer *)

         WHILE Ascii_Receive( Ch ) DO;

      END;
                                   (* Display text if local echo *)
   TextColor( Menu_Text_Color );

   IF Local_Echo THEN
      WRITELN( TextLine );

END   (* Send_Ascii_Line *);

(*----------------------------------------------------------------------*)

PROCEDURE Read_A_Line( VAR S: AnyStr );

VAR
   I        : INTEGER;
   Eol      : BOOLEAN;
   Ierr     : INTEGER;

BEGIN (* Read_A_Line *)

   I           := 0;
   Eol         := FALSE;
   S           := '';

   WHILE( NOT ( Eol OR EOF_AFile ) ) DO
      BEGIN

         INC( Buffer_Pos );

         IF ( Buffer_Pos > Buffer_Size ) THEN
            BEGIN
                                   (* Read Buffer_Length chars from file  *)
                                   (* to be sent.                         *)

               BlockRead( AFile, Read_Buffer^, Buffer_Length, Buffer_Size );

               Ierr       := Int24Result;
               Buffer_Pos := 1;
                                   (* If no chars. read, then EOF      *)

               IF ( ( Buffer_Size <= 0 ) OR ( Ierr <> 0 ) ) THEN
                  BEGIN
                     Eol         := TRUE;
                     EOF_AFile   := TRUE;
                  END;

            END;
                                   (* Place char into send string *)

         IF ( NOT EOF_AFile ) THEN
            IF ( NOT Ascii_Send_Asis ) THEN
               CASE Read_Buffer^[Buffer_Pos] OF
                  CR:  ;
                  LF:  Eol  := TRUE;
                  ELSE BEGIN
                          INC( I );
                          S[I] := CHR(Read_Buffer^[Buffer_Pos]);
                          Eol  := Eol OR ( I > 252 );
                       END;
               END (* CASE *)
            ELSE
               BEGIN
                  INC( I );
                  S[I] := CHR(Read_Buffer^[Buffer_Pos]);
                  Eol  := Eol OR ( I > Ascii_Line_Size );
               END;

      END;
                                   (* Remove trailing Ctrl-Z *)
   IF ( I > 0 ) THEN
      IF ( S[I] = ^Z ) THEN
         DEC( I );

   S[0] := CHR( I );

END   (* Read_A_Line *);

(*----------------------------------------------------------------------*)

BEGIN (* Send_Ascii_File *)
                                   (* Disable cursor                    *)
   CursorOff;
                                   (* Open display window for transfer  *)

   Ascii_Title := 'Send file ' + FileName + ' using ASCII';

   Write_Log( Ascii_Title, FALSE, FALSE );

   Initialize_Send_Window;
                                   (* Figure transfer time *)

   Byte_Count     := Get_File_Size( FileName , Open_OK );
   R_Baud_Rate    := ( Baud_Rate * Modem_Fudge ) / 10.0;
   Line_Count     := 0;
   Alt_S_Hit      := FALSE;
                                   (* Read file and find # of lines *)
   TextColor( Menu_Text_Color_2 );
   WRITELN;
   WRITE  (' Scanning ');

   TextColor( Menu_Text_Color );
   WRITE  ( FileName   );

   TextColor( Menu_Text_Color_2 );
   WRITELN(' for file size');

                                   (* Allocate buffer if requested   *)
                                   (* otherwise use sector data area *)
                                   (* directly.                      *)

   IF ( Max_Write_Buffer > MaxSectorLength ) AND
      ( Max_Write_Buffer < MaxAvail        ) THEN
      BEGIN
         Buffer_Length  := Max_Write_Buffer;
         Long_Buffer    := TRUE;
         GetMem( Read_Buffer , Buffer_Length );
         IF ( Read_Buffer = NIL ) THEN
            BEGIN
               Long_Buffer   := FALSE;
               Buffer_Length := MaxSectorLength;
               Read_Buffer   := ADDR( Sector_Data );
            END;
      END
   ELSE
      BEGIN
         Long_Buffer   := FALSE;
         Buffer_Length := MaxSectorLength;
         Read_Buffer   := ADDR( Sector_Data );
      END;
                                   (* Open file to send *)
   FileMode := 0;

   ASSIGN( AFile , FileName );
   RESET ( AFile , 1 );

   FileMode := 2;

   IF ( Int24Result <> 0 ) THEN
      BEGIN
         Write_Log( 'Cannot open file to send, transfer cancelled.',
                    TRUE, TRUE );
         Window_Delay;
         Restore_Screen_And_Colors( Saved_Screen );
         CursorOn;
         EXIT;
      END;
                                   (* Empty read buffer   *)

   Buffer_Pos     := Buffer_Length + 1;
   Buffer_Size    := 0;
   EOF_AFile      := FALSE;
                                   (* Get number of lines in file *)
   REPEAT
      Read_A_Line( TextLine );
      INC( Line_Count );
   UNTIL( EOF_AFile );

   CLOSE( AFile );

   FileMode := 0;

   RESET ( AFile , 1 );

   FileMode := 2;

   I := Int24Result;

   Buffer_Pos  := Buffer_Length + 1;
   Buffer_Size := 0;
   EOF_AFile   := FALSE;
                                   (* Display size in log              *)

   STR( Byte_Count , SBSize );
   STR( Line_Count , SLSize );

   Write_Log('Size of file to send is ' + SBSize + ' bytes, ' +
             SLSize + ' lines', TRUE, FALSE );

                                   (* Figure approximate transfer time *)

   R_Char_Delay   := Ascii_Char_Delay / 1000.0;
   R_Line_Delay   := Ascii_Line_Delay / 1000.0;

   Time_To_Send   := ROUND( Byte_Count / R_Baud_Rate +
                            R_Char_Delay * Byte_Count +
                            R_Line_Delay * Line_Count );

   Pace_Time := ( Ascii_Char_Delay   = 0 ) AND
                ( Ascii_Line_Delay   = 0 ) AND
                ( Ascii_Pacing_Char <> CHR( NUL ) ) AND
                ( Ascii_Pacing_Char <> ' '        );

   IF Pace_Time THEN
      Time_To_Send := ROUND( Time_To_Send + Line_Count *
                             ( Pacing_Delay + R_Line_Delay ) );

                                   (* Get parameters for Ascii transfer *)

   Do_Send_Blank := Ascii_Send_Blank;
   CR_LF_String  := Ascii_CR_LF_String;

   IF Ascii_Send_Asis THEN
      BEGIN
         Do_Send_Blank := FALSE;
         CR_LF_String  := '';
      END;
                                   (* FIN is true when upload complete *)
   Fin            := FALSE;
                                   (* Remember starting time           *)
   Start_Time     := TimeOfDay;
                                   (* Flag if pacing char found:       *)
                                   (* assumed TRUE to start things off *)
   Pace_Found     := TRUE;
   Pacing         := FALSE;
                                   (* Assume display to start with     *)

   Ascii_Display  := Ascii_Show_Text;

                                   (* Initialize status display        *)
   Clear_Window;
   Initialize_Status_Display;
                                   (* Reset line count                 *)
   Line_Kount     := Line_Count;
   Line_Count     := 0;
                                   (* Loop over lines in file          *)

   REPEAT
                                   (* Read a line                      *)
         Read_A_Line( TextLine );
                                   (* Don't send bogus last line!      *)

         IF ( EOF_AFile AND ( LENGTH( TextLine ) = 0 ) ) THEN GOTO 1;

                                   (* Turn empty line into 1 blank if desired *)

         IF Do_Send_Blank THEN
           IF ( LENGTH( TextLine ) = 0 ) THEN
               TextLine := ' ';
                                   (* Append cr or cr+lf as needed        *)

         TextLine    := TextLine + CR_LF_String;
         Length_Line := LENGTH( TextLine ) + LENGTH( CR_LF_String );

                                   (* If pacing character specified, wait *)
                                   (* for it to show up from com port     *)
         Esc_Found  := FALSE;

         IF ( Pacing AND ( NOT Fin ) ) THEN
            REPEAT
               IF PibTerm_KeyPressed THEN
                  BEGIN
                     Read_Kbd( Ch );
                     IF Ch = CHR( ESC ) THEN
                        Esc_Found := TRUE
                     ELSE
                        BEGIN
                           B := Ascii_Receive( A_Ch );
                           Ascii_Send( Ch );
                        END;
                  END;
               IF Ascii_Receive( Ch ) THEN
                  BEGIN
                     Pace_Found := ( Ch = Ascii_Pacing_Char );
                     IF Pace_Found THEN
                        DELAY( Ascii_Line_Delay );
                  END;
            UNTIL ( Pace_Found OR Esc_Found )
         ELSE
            REPEAT
               IF PibTerm_KeyPressed THEN
                  BEGIN
                     Read_Kbd( Ch );
                     IF Ch = CHR( ESC ) THEN
                        Esc_Found := TRUE
                     ELSE
                        BEGIN
                           B := Ascii_Receive( A_Ch );
                           Ascii_Send( Ch );
                        END;
                  END;
               B := Ascii_Receive( Ch );
            UNTIL ( Pace_Found OR Esc_Found );

                                   (* Check if Alt-S hit again --  *)
                                   (* end transfer if so.          *)

         IF ( Esc_Found AND PibTerm_KeyPressed ) THEN
            BEGIN
               Read_Kbd( Ch );
               IF ORD( Ch ) = Alt_S THEN
                  BEGIN
                     Fin       := TRUE;
                     Alt_S_Hit := TRUE;
                  END
               ELSE IF ORD( Ch ) = Shift_Tab THEN
                  Flip_Display_Status
               ELSE
                  Handle_Function_Key( A_Ch );
            END
         ELSE
            WHILE PibTerm_KeyPressed DO
               BEGIN
                  Read_Kbd( Ch );
                  B := Ascii_Receive( A_Ch );
                  Ascii_Send( Ch );
               END;
                                   (* Send the next line to the host *)
         IF ( NOT Fin ) THEN
            Send_Ascii_Line;
                                   (* Update status display *)

         INC( Line_Count );
         DEC( Line_Kount );

         Byte_Count   := Byte_Count   - Length_Line;
         IF ( Byte_Count < 0 ) THEN
            Byte_Count := 0;

         Time_To_Send   := ROUND( Byte_Count / R_Baud_Rate +
                                  R_Char_Delay * Byte_Count +
                                  R_Line_Delay * Line_Kount );

         IF Pace_Time THEN
            Time_To_Send := ROUND( Time_To_Send + Line_Kount *
                                   ( Pacing_Delay + R_Line_Delay ) );

         IF ( Time_To_Send <= 0 ) THEN
            Time_To_Send := 0;

         IF Display_Status THEN
            Update_Ascii_Send_Display;

                                   (* Ensure pacing if needed after *)
                                   (* first block                   *)

         Pacing := ( Ascii_Pacing_Char <> CHR( NUL ) ) AND
                   ( Ascii_Pacing_Char <> ' '        );

                                   (* Look if carrier dropped          *)

         Fin := Fin OR Async_Carrier_Drop;

1:
   UNTIL ( Fin OR EOF_AFile );

                                   (* Send CtrlZ marker if needed *)
   IF Ascii_Use_CtrlZ THEN
      BEGIN
         B := Ascii_Receive( Ch );
         Ascii_Send( ^Z );
      END;
                                   (* Display any remaining characters while *)
                                   (* waiting for serial output buffer to drain *)
   T1 := TimeOfDay;

   WHILE( ( Async_OBuffer_Head <> Async_OBuffer_Tail    ) AND
          ( TimeDiff( T1 , TimeOfDay ) <= Max_Wait_Time ) AND
          ( NOT PibTerm_KeyPressed )                    ) DO
      IF Ascii_Receive( Ch ) THEN
         IF Print_Spooling THEN
            Print_Spooled_File;

   DELAY( Two_Second_Delay );

                                   (* Ensure status window is up  *)
   IF ( NOT Display_Status ) THEN
      Initialize_Send_Window;
                                   (* Display final transfer time *)
   Activate_Status_Window;

   GoToXY( 2 , 9 );

   IF ( NOT Fin ) THEN
      BEGIN

         Write_Log('Send completed.', TRUE, TRUE );
         GoToXY( 2 , 10 );

         TextColor( Menu_Text_Color_2 );
         WRITE (' Actual transfer time was ');

         TextColor( Menu_Text_Color );
         WRITE ( TimeString( TimeDiff( Start_Time, TimeOfDay ),
                             Military_Time ) );
      END
   ELSE IF Alt_S_Hit THEN
      Write_Log('Alt-S hit, send stopped.' , TRUE, TRUE )
   ELSE
      Write_Log('Send cancelled.' , TRUE, TRUE );

                                   (* Close transferred file           *)
   CLOSE( AFile );
   I := Int24Result;
                                   (* Delay after transfer done.       *)
   Window_Delay;
                                   (* Turn cursor back on *)
   CursorOn;
                                   (* Remove upload buffer           *)
   IF Long_Buffer THEN
      MyFreeMem( Read_Buffer , Buffer_Length );

                                   (* Remove this window            *)

   Restore_Screen_And_Colors( Saved_Screen );

END   (* Send_Ascii_File *);
