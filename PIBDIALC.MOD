(*----------------------------------------------------------------------*)
(*  Signal_Connection -- indicate connection made for redial, list dial *)
(*----------------------------------------------------------------------*)

PROCEDURE Signal_Connection;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Signal_Connection                                    *)
(*                                                                      *)
(*     Purpose:    Indicates connection made                            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Signal_Connection;                                            *)
(*                                                                      *)
(*     Calls:   Save_Screen                                             *)
(*              Restore_Screen                                          *)
(*              Draw_Menu_Frame                                         *)
(*              Reset_Global_Colors                                     *)
(*              Dialer_Carrier_Detect                                   *)
(*              Read_Kbd                                                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Local_Save : Saved_Screen_Ptr;
   Ch         : CHAR;

BEGIN (* Signal_Connection *)

   Save_Partial_Screen( Local_Save, 10, 10, 60, 14 );
   Draw_Menu_Frame( 10, 10, 60, 14, Menu_Frame_Color,
                    Menu_Title_Color + Blink,
                    Menu_Text_Color, '' );

   TextColor( Menu_Text_Color + Blink );

   WRITELN('Connection established!!');
   WRITE  ('Hit ESC key to continue');

   REPEAT
      Menu_Beep;
      DELAY( 3 * Tenth_Of_A_Second_Delay );
   UNTIL ( PibTerm_KeyPressed  OR  ( NOT Dialer_Carrier_Detect ) );

   IF PibTerm_KeyPressed THEN
      BEGIN
         Read_Kbd( Ch );
         IF ( Ch = CHR( ESC ) ) AND PibTerm_KeyPressed THEN
            Read_Kbd( Ch );
      END;

   Restore_Screen_And_Colors( Local_Save );

END   (* Signal_Connection *);

(*----------------------------------------------------------------------*)
(*                  Dial_A_Number --- dial phone number                 *)
(*----------------------------------------------------------------------*)

PROCEDURE Dial_A_Number(     Re_Dial : BOOLEAN;
                         VAR Quit    : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Dial_A_Number                                        *)
(*                                                                      *)
(*     Purpose:    Dials phone number                                   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Dial_A_Number(     Re_Dial : BOOLEAN;                         *)
(*                       VAR Quit    : BOOLEAN );                       *)
(*                                                                      *)
(*           Re_Dial --- TRUE to re-dial last number                    *)
(*           Quit    --- TRUE if Esc key hit to stop dialing            *)
(*                                                                      *)
(*     Calls:   Send_Modem_Command                                      *)
(*              Save_Screen                                             *)
(*              Restore_Screen                                          *)
(*              Draw_Menu_Frame                                         *)
(*              Reset_Global_Colors                                     *)
(*              Dialer_Carrier_Detect                                   *)
(*              Display_Phone_Numbers                                   *)
(*              TimeOfDay                                               *)
(*              TimeDiff                                                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Dial_Title   : FileStr;
   OK_Redial    : BOOLEAN;
   Ch           : CHAR;
   Timed_Out    : BOOLEAN;
   STimer       : LONGINT;
   Modem_Mess   : AnyStr;
   New_Baud     : INTEGER;
   Ierr         : INTEGER;
   Qerr         : BOOLEAN;
   SNumber      : STRING[100];
   Inumber      : INTEGER;
   Modem_Buzy   : BOOLEAN;
   Modem_NoC    : BOOLEAN;
   Modem_Conn   : BOOLEAN;
   T            : LONGINT;
   TOD          : LONGINT;
   IY           : INTEGER;
   I            : INTEGER;
   J            : INTEGER;
   TS           : STRING[9];
   TSO          : STRING[9];
   ESC_Hit      : BOOLEAN;
   Local_Save_3 : Saved_Screen_Ptr;
   Local_Save_5 : Saved_Screen_Ptr;
   Got_Num      : BOOLEAN;
   CR_Str       : STRING[1];
   Do_Baud      : BOOLEAN;

(*----------------------------------------------------------------------*)
(*  Convert_Entry_To_Number --- convert dialing entry to phone number   *)
(*----------------------------------------------------------------------*)

PROCEDURE Convert_Entry_To_Number;

VAR
   I: INTEGER;
   
BEGIN (* Convert_Entry_To_Number *)

                                   (* Check for manual dial *)

   IF UpCase( SNumber[1] ) = 'M' THEN
      BEGIN
         Manual_Dial := TRUE;
         IF LENGTH( SNumber ) > 1 THEN
            SNumber     := COPY( SNumber, 2, LENGTH( SNumber ) - 1 )
         ELSE
            SNumber     := '';
      END;
                                   (* Check for prefix *)

   IF SNumber[1] IN ['+','-','!','@','#'] THEN
      BEGIN
         Prefix_Str := Phone_Prefix_Nos[ POS( SNumber[1], '+-!@#' ) ];
         IF LENGTH( SNumber ) > 1 THEN
            SNumber    := COPY( SNumber, 2, LENGTH( SNumber ) - 1 )
         ELSE
            SNumber     := '';
      END;

   IF SNumber[LENGTH(SNumber)] IN ['+','-','!','@','#'] THEN
      BEGIN
         Postfix_Str := Phone_Prefix_Nos[ POS( SNumber[LENGTH(SNumber)],
                                               '+-!@#' ) ];
         IF LENGTH( SNumber ) > 1 THEN
            SNumber    := COPY( SNumber, 1, ( LENGTH( SNumber ) - 1 ) )
         ELSE
            SNumber     := '';
      END;

   IF Manual_Dial THEN
      BEGIN
         Phone_Number       := SNumber;
         Phone_Entry_Number := -1;
         FOR I := 1 TO 25 DO
            Phone_Entry_Data.Phone_Name[I] := ' ';
         FOR I := 1 TO 15 DO
            Phone_Entry_Data.Phone_Number[I] := ' ';
         FOR I := 1 TO 9 DO
            Phone_Entry_Data.Phone_Script[I] := ' ';
         J := 0;
         FOR I := ( 16 - LENGTH( SNumber ) ) TO 15 DO
            BEGIN
               J := J + 1;
               Phone_Entry_Data.Phone_Number[I] := SNumber[J];
            END;
      END
   ELSE
      BEGIN
         Inumber := 2;
         VAL( SNumber, Inumber, Ierr );
         IF ( Ierr = 0 ) AND
            ( INumber >  0 ) AND
            ( INumber <= Dialing_Dir_Size) THEN
            BEGIN
               Phone_Entry_Data   := Dialing_Directory^[ INumber ];
               Phone_Number       := Phone_Entry_Data.Phone_Number;
               Phone_Entry_Number := INumber;
               IF ( NOT Dialer_Carrier_Detect ) THEN
                  Reset_Comm_Params( Phone_Entry_Data , INumber );
            END
         ELSE
            BEGIN
               WRITELN;
               WRITE('Bad phone number, dialing cancelled.');
               ClrEol;
               Window_Delay;
               Quit := TRUE;
               Phone_Entry_Number := -1;
            END;
      END;

END   (* Convert_Entry_To_Number *);

(*----------------------------------------------------------------------*)
(*            Perform_The_Dial --- perform actual dialing               *)
(*----------------------------------------------------------------------*)

PROCEDURE Perform_The_Dial;

VAR
   Int_Ch  : INTEGER;
   CNumber : AnyStr;
   I       : INTEGER;
   ConMess : AnyStr;

(*----------------------------------------------------------------------*)

PROCEDURE Append_A_Char(  VAR  S: AnyStr;
                              Ch: CHAR    );

VAR
   L: INTEGER;

BEGIN (* Append_A_Char *)

   L := ORD( S[0] );

   IF ( L < 255 ) THEN
      BEGIN
         L    := L + 1;
         S[L] := Ch;
         S[0] := CHR( L );
      END
   ELSE
      BEGIN
         MOVE( S[2], S[1], 254 );
         S[255] := Ch;
      END;

END   (* Append_A_Char *);

(*----------------------------------------------------------------------*)

PROCEDURE Do_Baud_Detection;

VAR
   I: INTEGER;

BEGIN (* Do_Baud_Detection *)

   STimer     := TimeOfDay;
   IY         := 0;
                                   (* Wait for connect message *)
   REPEAT

      Async_Receive_With_TimeOut( One_Second , Int_Ch );

      IF ( Int_Ch <> TimeOut ) THEN
         Append_A_Char( Modem_Mess , CHR( Int_Ch ) );

      Timed_Out := ( TimeDiff( Stimer , TimeOfDay ) > 5.0 ) OR
                   ( Int_Ch = TimeOut );

      IY     := POS( Modem_Connect , Modem_Mess );

   UNTIL( Timed_Out OR ( IY > 0 ) );

                                   (* If connect found, read chars *)
                                   (* up to next CR, if any.       *)
   IF ( IY > 0 ) THEN
      BEGIN

         DELETE( Modem_Mess, 1, IY - 1 );

         REPEAT

            Async_Receive_With_TimeOut( One_Second , Int_Ch );

            IF ( Int_Ch <> TimeOut ) THEN
               Append_A_Char( Modem_Mess , CHR( Int_Ch ) );

            Timed_Out := ( Int_Ch = TimeOut );

         UNTIL( Timed_Out OR ( Int_Ch = CR ) );

      END;

                                   (* If connect message found, look for *)
                                   (* any following digits, indicating   *)
                                   (* baud rate of connection.           *)

   IY     := POS( Modem_Connect , Modem_Mess );

   IF ( IY > 0 ) THEN
      BEGIN

         I             := IY + LENGTH( Modem_Connect );

         Append_A_Char( Modem_Mess , CHR( CR ) );

         New_Baud      := 0;
         Do_Baud       := TRUE;

         WHILE( Do_Baud ) DO
            BEGIN
               IF Modem_Mess[I] IN ['0'..'9'] THEN
                  New_Baud := New_Baud * 10 + ORD( Modem_Mess[I] ) -
                                              ORD('0')
               ELSE IF Modem_Mess[I] = CHR( CR ) THEN
                  Do_Baud := FALSE;
               I := I + 1;
               IF ( I > LENGTH( Modem_Mess ) ) THEN
                  Do_Baud := FALSE;
            END;

         FOR I := 1 TO N_Baud_Rates DO
            IF ( New_Baud = Baud_Rates[I] ) THEN
               BEGIN
                  IF ( New_Baud <> Baud_Rate ) THEN
                     BEGIN
                        Reset_Comm_Port := TRUE;
                        Baud_Rate       := New_Baud;
                        Async_Reset_Port( Comm_Port, Baud_Rate, Parity,
                                          Data_Bits, Stop_Bits );
                     END;
               END;

      END;

END   (* Do_Baud_Detection *);

(*----------------------------------------------------------------------*)

BEGIN (* Perform_The_Dial *)
                                   (* Nothing back from modem yet *)
   Modem_Mess  := '';

   IF ( LENGTH( Phone_Number ) > 0 ) AND ( NOT Quit ) THEN
      BEGIN  (* Phone number gotten *)

         IF ( NOT Manual_Dial ) THEN
            Dial_Title := TRIM( Dial_Title + ' ' +
                                Phone_Entry_Data.Phone_Name );

         Draw_Menu_Frame( 10, 10, 70, 17, Menu_Frame_Color, Menu_Title_Color,
                          Menu_Text_Color, Dial_Title );

         GoToXY( 1 , 1 );
                                   (* Purge receive to avoid *)
                                   (* false modem messages   *)
         Async_Purge_Buffer;
                                   (* Get number to dial     *)

         CNumber := Prefix_Str + Phone_Number + Postfix_Str;

         I := POS( ' ' , CNumber );

         WHILE( I > 0 ) DO
            BEGIN
               DELETE( CNumber, I, 1 );
               I := POS( ' ' , CNumber );
            END;
                                   (* Display if dialing/redialing *)
         IF OK_Redial THEN
            BEGIN
               TextColor( Menu_Text_Color_2 );
               WRITE('Re-dialing  : ');
               TextColor( Menu_Text_Color );
               WRITE( CNumber );
            END
         ELSE
            BEGIN
               TextColor( Menu_Text_Color_2 );
               WRITE('Dialing     : ');
               TextColor( Menu_Text_Color );
               WRITE( CNumber );
            END;

         ClrEol;
                                   (* Make sure serial output uncorked *)
         Clear_XOFF_Received;
                                   (* Issue complete dialing command *)

         Send_Modem_Command( Modem_Dial               +
                             Prefix_Str               +
                             Phone_Number             +
                             Postfix_Str              +
                             Modem_Dial_End );

         STimer          := TimeOfDay;
         Modem_Buzy      := FALSE;
         Modem_NoC       := FALSE;
         Modem_Conn      := FALSE;
         IY              := WhereY;
         TS              := '';
         Connection_Made := FALSE;

         GoToXY( 1 , 2 );
         TextColor( Menu_Text_Color_2 );
         WRITE('Begins at   : ');
         TextColor( Menu_Text_Color );
         WRITE(TimeString(TimeOfDay , Time_Format));
         ClrEol;

         GoToXY( 1 , 3 );
         TextColor( Menu_Text_Color_2 );
         WRITE('Time now    : ');
         TextColor( Menu_Text_Color );
         WRITE(TimeString(TimeOfDay , Time_Format));
         ClrEol;

         Write_Log( Dial_Title + ' (' + Phone_Number + ')' , FALSE, FALSE );

         GoToXY( 1 , 4 );
         TextColor( Menu_Text_Color_2 );
         WRITE('Elapsed time: ');
         ClrEol;
         TextColor( Menu_Text_Color );

         IF OK_Redial THEN
            BEGIN
               GoToXY( 1 , 5 );
               TextColor( Menu_Text_Color_2 );
               WRITE('Retry count : ');
               TextColor( Menu_Text_Color );
               WRITE(Redial_Count);
               ClrEol;
            END;

         CursorOff;

         REPEAT

            TOD       := TimeOfDay;
            T         := TimeDiff( STimer , TOD );
            TSO       := TS;
            TS        := TimeString( T , Military_Time );

            IF TS <> TSO THEN
               BEGIN
                  GoToXY( 15 , 3 );
                  WRITE( TimeString( TOD , Military_Time ) );
                  ClrEol;
                  GoToXY( 15 , 4 );
                  WRITE( TS );
                  ClrEol;
               END;

            Timed_Out := ( T > Modem_Time_Out );

            IF Async_Receive( Ch ) THEN
               Append_A_Char( Modem_Mess , Ch );

            Modem_Buzy := ( POS( Modem_Busy       , Modem_Mess ) > 0 ) AND
                          ( LENGTH( Modem_Busy       )  > 0 );
            Modem_NoC  := ( POS( Modem_No_Carrier , Modem_Mess ) > 0 ) AND
                          ( LENGTH( Modem_No_Carrier ) > 0 );
            Modem_Conn := ( POS( Modem_Connect    , Modem_Mess ) > 0 ) AND
                          ( LENGTH( Modem_Connect    ) > 0 );

            Esc_Hit := FALSE;

            IF PibTerm_KeyPressed THEN
               BEGIN

                  Read_Kbd( Ch );

                  Esc_Hit := ( Ch = CHR( ESC ) );

                  WHILE( PibTerm_KeyPressed ) DO
                     Read_Kbd( Ch );

               END
            ELSE
               GiveAwayTime( 2 );

         UNTIL ( Dialer_Carrier_Detect ) OR
               ( Timed_Out             ) OR
               ( Modem_Conn            ) OR
               ( Modem_Buzy            ) OR
               ( Modem_NoC             ) OR
               ( Esc_Hit               );

         CursorOn;

         TextColor( Menu_Text_Color_2 );

         IF ( Modem_Conn OR Dialer_Carrier_Detect ) THEN
            Connection_Made := TRUE
         ELSE IF Esc_Hit THEN
            BEGIN

               GoToXY( 1 , 6 );

               WRITE('*** ESC Pressed, Dialing Cancelled.');
               ClrEol;

               Write_Log('ESC Pressed, Dialing Cancelled.' , TRUE , FALSE );

               Quit := TRUE;
                                   (* Hang up the phone *)

               IF ( NOT Modem_Hold_Line ) THEN
                  HangUpPhone;

            END
         ELSE IF Timed_Out THEN
            BEGIN

               GoToXY( 1 , 6 );
               WRITE('*** Modem Timed Out, Dialing Cancelled.');
               ClrEol;

               Write_Log('Modem Timed Out, Dialing Cancelled.' , TRUE , FALSE );

               Window_Delay;

            END
         ELSE IF Modem_Buzy THEN
            BEGIN

               GoToXY( 1 , 6 );

               WRITE('*** Line Busy.');
               ClrEol;

               Write_Log('Line Busy.' , TRUE , FALSE );

                                   (* Hang up the phone *)
               IF ( NOT Modem_Hold_Line ) THEN
                  HangUpPhone;

               Window_Delay;

            END
         ELSE IF Modem_NoC THEN
            BEGIN

               GoToXY( 1 , 6 );

               WRITE('*** No Answer.');
               ClrEol;

               Write_Log('No Answer.' , TRUE , FALSE );

                                   (* Hang up the phone *)

               IF ( NOT Modem_Hold_Line ) THEN
                  HangUpPhone;

               Window_Delay;

            END;

      END  (* Phone number gotten *);

   TextColor( Menu_Text_Color );

   IF ( Connection_Made AND ( NOT Quit ) ) THEN
      BEGIN  (* Connection made *)

                                   (* Alter baud rate if modem signals it *)

         IF ( Alter_Baud_Rate AND ( LENGTH( Modem_Connect ) > 0 ) ) THEN
            Do_Baud_Detection;

         Restore_Screen_And_Colors( Local_Save_5 );

         ConMess := 'Connection established at ' + IToS( Baud_Rate ) +
                    ',' + Parity + ',' + IToS( Data_Bits ) + ',' +
                    IToS( Stop_Bits );

         WRITELN;
         Write_Log( ConMess, TRUE , TRUE );

                                   (* Remove this number from list, if any *)

         IF ( N_Dial_Nos > 0 ) THEN
            BEGIN
               FOR I := ( I_Dial_Nos + 1 ) TO N_Dial_Nos DO
                  Dial_Nos[I-1] := Dial_Nos[I];
               DEC( N_Dial_Nos );
            END;
                                   (* Reset other stuff like script, etc. *)

         IF ( Phone_Entry_Number > 0 ) THEN
            Reset_Other_Params( Phone_Entry_Data , Phone_Entry_Number );

      END (* Connection made *);

END   (* Perform_The_Dial *);

(*----------------------------------------------------------------------*)

BEGIN (* Dial_A_Number *)

   Manual_Dial := FALSE;
   Quit        := FALSE;
   Got_Num     := FALSE;

   OK_Redial := ( Re_Dial AND ( ( Phone_Number <> '' ) OR
                                ( N_Dial_Nos    > 0  ) ) );

   IF OK_Redial THEN
      Dial_Title := 'Redialing'
   ELSE
      Dial_Title := 'Dialing';

   Save_Partial_Screen( Local_Save_5, 1, 1, Max_Screen_Col, 24 );

   IF ( NOT OK_Redial ) (* AND ( N_Dial_Nos <= 0 ) *) THEN
      BEGIN  (* Not a redial *)

                                   (* No dialing string given -- display *)
                                   (* directory.                         *)

         IF LENGTH( Dialing_String ) = 0 THEN
            BEGIN

               Display_Phone_Numbers( Entry_String, Phone_Number,
                                      Prefix_Str, Postfix_Str, Quit );

               IF Dialer_Carrier_Detect OR Quit OR ReDial AND
                  ( ( LENGTH( Phone_Number ) = 0 ) AND
                    ( N_Dial_Nos = 0             )     ) THEN
                  BEGIN
                     Restore_Screen_And_Colors( Local_Save_5 );
                     EXIT;
                  END
               ELSE
                  Got_Num := TRUE;

            END
         ELSE                      (* Dialing string provided *)
            BEGIN
               SNumber     := Dialing_String;
               Prefix_Str  := '';
               Postfix_Str := '';
               FOR I := 1 TO 25 DO
                  Phone_Entry_Data.Phone_Name[I] := ' ';
            END;

         IF ( NOT Quit ) THEN
            IF ( NOT Got_Num ) THEN
               Convert_Entry_To_Number;

      END  (* Not a redial *);

{--------Removed the following check
   IF ( Dialer_Carrier_Detect AND ( NOT Quit ) ) THEN
      BEGIN
         Save_Partial_Screen( Local_Save_3, 10, 5, 60, 8 );
         Draw_Menu_Frame( 10, 5, 60, 8, Menu_Frame_Color, Menu_Title_Color,
                          Menu_Text_Color + Blink, '' );
         WRITE('Session already in progress, dialing cancelled.');
         Window_Delay;
         Restore_Screen_And_Colors( Local_Save_3 );
         Restore_Screen_And_Colors( Local_Save_5 );
         EXIT;
      END;
-----------}
                                   (* Do actual dialing *)

   IF ( N_Dial_Nos = 0 ) (* OR ( NOT OK_Redial ) *) THEN

                                   (* Single entry *)
      Perform_The_Dial
   ELSE
      REPEAT
                                   (* Get next # in dialing list *)

         IF ( I_Dial_Nos >= 0 ) THEN
            BEGIN
               INC( I_Dial_Nos );
               IF ( I_Dial_Nos > N_Dial_Nos ) THEN
                  I_Dial_Nos := 1;
            END
         ELSE
            I_Dial_Nos := (-I_Dial_Nos);

         SNumber      := Dial_Nos[I_Dial_Nos].Number;
         Redial_Count := Dial_Nos[I_Dial_Nos].Tries;
         OK_Redial    := ( Redial_Count > 0 );
         Manual_Dial  := FALSE;
         Dial_Title   := 'Dialing';
         Prefix_Str   := '';
         Postfix_Str  := '';
                                   (* Convert to dialable form *)
         Convert_Entry_To_Number;
                                   (* Evict any dialing return *)
         Async_Purge_Buffer;
                                   (* Do the dialing           *)
         Perform_The_Dial;
                                   (* Increment count of dialing attempts *)

         INC( Dial_Nos[I_Dial_Nos].Tries );

         IF ( NOT Connection_Made ) AND Script_File_Mode THEN
            Quit := TRUE;

      UNTIL ( Connection_Made OR Quit OR ESC_Hit );

                                   (* Restore previous screen *)
                                   (* if not connected        *)

   IF ( NOT Connection_Made ) THEN
      Restore_Screen_And_Colors( Local_Save_5 )
   ELSE
      IF ( N_Dial_Nos > 0 ) THEN
         Signal_Connection;
                                   (* Make sure phone hung up *)
                                   (* if unsuccessful dial    *)
   IF Quit THEN
      IF ( NOT Modem_Hold_Line ) THEN
         HangUpPhone;

END   (* Dial_A_Number *);

(*----------------------------------------------------------------------*)
(*          Handle_Redial --- Handle Redial after dialing attempt made  *)
(*----------------------------------------------------------------------*)

PROCEDURE Handle_Redial( VAR MDelay : LONGINT;
                         VAR Done   : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Handle_Redial                                        *)
(*                                                                      *)
(*     Purpose:    Handles redial after dialing attempt made.           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Handle_Redial( VAR MDelay : LONGINT; VAR Done : BOOLEAN );    *)
(*                                                                      *)
(*           MDelay --- Initial redial delay time                       *)
(*           Done   --- TRUE if redial attempt successful               *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        TimeOfDay                                                     *)
(*        TimeDiff                                                      *)
(*        Dialer_Carrier_Detect                                         *)
(*        Clear_Window                                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   RTimer       : LONGINT;
   DTimer       : LONGINT;
   PTimer       : LONGINT;
   OTimer       : LONGINT;
   Rchar        : CHAR;
   MDnew        : LONGINT;
   Ypos         : INTEGER;
   Local_Save_5 : Saved_Screen_Ptr;
   Redial_Name  : AnyStr;
   Ring_Detect  : BOOLEAN;

BEGIN (* Handle_Redial *)
                                   (* If connection established, done *)
   Done        := Connection_Made;
                                   (* Phone shouldn't be ringing now  *)
   Ring_Detect := FALSE;
                                   (* Otherwise, wait for specified   *)
                                   (* modem delay                     *)
   IF ( NOT Done ) THEN
      BEGIN

         Redial_Name := TRIM( 'Redialing ' + Phone_Entry_Data.Phone_Name );

         Draw_Titled_Box( Local_Save_5, 10, 10, 60, 16, Redial_Name );

         RTimer := TimeOfDay;

         Clear_Window;

         Ypos := WhereY;

         TextColor( Menu_Text_Color_2 );
         WRITE  (' Seconds to next redial: ');
         TextColor( Menu_Text_Color );
         WRITELN( TRUNC( MDelay ) );

         TextColor( Menu_Text_Color_2 );
         WRITE  (' R');
         TextColor( Menu_Text_Color );
         WRITE  (' = redial now   ');
         TextColor( Menu_Text_Color_2 );
         WRITE  ('Esc');
         TextColor( Menu_Text_Color );
         WRITE  (' = stop   ');
         TextColor( Menu_Text_Color_2 );
         WRITE  ('C');
         TextColor( Menu_Text_Color );
         WRITE  (' = change delay.');

         Rchar  := ' ';
         PTimer := MDelay;
         OTimer := PTimer;

         REPEAT

            IF PTimer <> OTimer THEN
               BEGIN
                  GoToXY( 26 , YPos );
                  WRITE( TRUNC( PTimer ) );
                  ClrEol;
                  OTimer := PTimer;
               END;

            IF PibTerm_KeyPressed THEN
               BEGIN

                  Read_Kbd( Rchar );

                  IF UpCase( Rchar ) = 'C' THEN
                     BEGIN
                        GotoXY( 1 , 3 );
                        TextColor( Menu_Text_Color_2 );
                        WRITE  (' Enter new delay: ');
                        ClrEol;
                        TextColor( Menu_Text_Color );
                        MDNew := TRUNC( MDelay );
                        IF Read_Number( MDNew , TRUE , MDNew ) THEN
                           MDelay := MDNew;
                        GoToXY( 1 , 3 );
                        ClrEol;
                     END
                  ELSE IF ( Rchar = CHR( ESC ) ) THEN
                     Rchar := 'X';

               END
            ELSE
               GiveAwayTime( 2 );

            DTimer := TimeDiff( RTimer , TimeOfDay );
            PTimer := MDelay - DTimer;

            IF PTimer <= 0 THEN
               PTimer := 0;

            Ring_Detect := Async_Ring_Detect;

         UNTIL ( DTimer > MDelay ) OR
               ( Ring_Detect     ) OR
               ( UpCase( Rchar ) IN ['R','X'] );

         Done := ( UpCase(Rchar) = 'X' ) OR Ring_Detect;

         IF Ring_Detect THEN
            BEGIN
               GoToXY( 1 , 4 );
               TextColor( Menu_Text_Color_2 );
               WRITE('Ring detected, redial stopped.');
               Window_Delay;
            END;

         Restore_Screen_And_Colors( Local_Save_5 );

      END (* NOT Done *)
   ELSE
      IF ( NOT ( Script_File_Mode OR Read_In_Script ) AND Attended_Mode ) THEN
         Signal_Connection;

END   (* Handle_Redial *);

(*----------------------------------------------------------------------*)
(*          Redial_A_Number --- Redial last phone number dialed         *)
(*----------------------------------------------------------------------*)

PROCEDURE Redial_A_Number;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Redial_A_Number                                      *)
(*                                                                      *)
(*     Purpose:    Redials last number dialed (if any).                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Redial_A_Number;                                              *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Dial_A_Number                                                 *)
(*        TimeOfDay                                                     *)
(*        TimeDiff                                                      *)
(*        Dialer_Carrier_Detect                                         *)
(*        Clear_Window                                                  *)
(*        Handle_Redial                                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Done         : BOOLEAN;
   Quit         : BOOLEAN;
   MDelay       : LONGINT;

BEGIN (* Redial_A_Number *)
                                   (* Only redial if no current session *)

   Done         := Dialer_Carrier_Detect OR ( Phone_Number = '' );
   MDelay       := Modem_Redial_Delay;
   Redial_Count := 0;

   WHILE( NOT ( Done OR Connection_Made ) ) DO
      BEGIN
                                   (* Increment redial  *)

         Redial_Count := Redial_Count + 1;

                                   (* Redial the number *)

         Dial_A_Number( TRUE , Quit );

                                   (* Handle connection if any *)

         Handle_Redial( MDelay , Done );

      END (* NOT ( Done OR Connection_Made ) *);

END   (* Redial_A_Number *);

(*------------------------- PIBDIALER --------------------------------*)

BEGIN (* PibDialer *)
                                   (* Choose prompt style            *)

   Use_Short_Prompt   := Use_Short_Dial_Menu;
   Dial_Search_String := '';
   Connection_Made    := FALSE;

                                   (* Choose regular dial or re-dial *)
   CASE ReDial OF

      FALSE:  REPEAT
                 Redial_Count        := 0;
                 First_Display_Time  := TRUE;
                 Dial_A_Number( FALSE , Quit );
                 Quit := Quit OR Script_File_Mode;
                 IF ( ReDial AND ( NOT Quit ) ) THEN
                    BEGIN
                       ReDial_A_Number;
                       Redial := FALSE;
                    END;
              UNTIL ( Connection_Made OR Quit );

      TRUE:   BEGIN
                 First_Display_Time  := TRUE;
                 IF ( N_Dial_Nos > 0 ) THEN
                    Dial_A_Number( TRUE , Quit )
                 ELSE
                    BEGIN
                       IF ( Phone_Number = '' ) THEN
                          Dial_A_Number( FALSE , Quit );
                       ReDial_A_Number;
                    END;
              END;

   END (* CASE *);
                                   (* Reset timer if connection made; *)
                                   (* also make sure no script exec   *)
                                   (* unless carrier detect.          *)
   IF Connection_Made THEN
      Dialing_Start_Time := TimeOfDay
   ELSE
      Read_In_Script := FALSE;

   Script_Dialed := Read_In_Script;

END   (* PibDialer *);
