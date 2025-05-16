(*----------------------------------------------------------------------*)
(*            Do_Host --- Controls execution of host mode               *)
(*----------------------------------------------------------------------*)

PROCEDURE Do_Host;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Do_Host                                              *)
(*                                                                      *)
(*     Purpose:    Controls host mode                                   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Do_Host;                                                      *)
(*                                                                      *)
(*      Calls:   Async_Send                                             *)
(*               Async_Receive                                          *)
(*               PibTerm_KeyPressed                                     *)
(*               Clear_Window                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Done    : BOOLEAN               (* TRUE to exit host mode            *);
   Found   : BOOLEAN               (* TRUE if user name found           *);
   Ch      : CHAR                  (* Character read/written            *);
   S_Ch    : CHAR                  (* Parity_stripped character         *);
   MyPass  : AnyStr                (* Password                          *);
   Try     : INTEGER               (* Number of login attempts          *);
   Back    : BOOLEAN               (* Back from file transfers          *);
   Ierr    : INTEGER               (* I/O error code                    *);
   Keyed_In: BOOLEAN               (* TRUE if character entered at Kbd  *);

BEGIN (* Do_Host *)
                                   (* Clear comm line of garbage *)
   Async_Purge_Buffer;
                                   (* Expert mode OFF by default *)
   Expert_On       := FALSE;
                                   (* Assume line feeds not needed *)
   CR_LF_Host      := CHR( CR );
                                   (* Welcome and linefeed check *)
   Done            := FALSE;
                                   (* Current host status *)
   Cur_Host_Status := '';

   Host_Send_String_With_CR('PibTerm Version ' + PibTerm_Version);
   Host_Send_String_With_CR(PibTerm_Date);
   Host_Send_String_With_CR('Beginning Remote Communications');
   Host_Send_String_With_CR(' ');
   Host_Send_String_With_CR('Test if line feeds required ...');

   REPEAT

      Async_Purge_Buffer;

      Host_Send_String_With_CR(' ');
      Host_Send_String_And_Echo('Are these lines O V E R P R I N T I N G ?');

      Keyed_In := FALSE;

      REPEAT
      UNTIL Async_Receive( Ch ) OR PibTerm_KeyPressed OR ( NOT Host_Carrier_Detect );

      S_Ch := CHR( ORD( Ch ) AND $7F );

                                   (* Look for keyboard input if any *)
      IF PibTerm_KeyPressed THEN
         BEGIN
            Keyed_In := TRUE;
            Read_Kbd( S_Ch );
            IF ( S_Ch = CHR( ESC ) ) THEN
               IF ( NOT PibTerm_KeyPressed ) THEN
                  BEGIN
                     Done        := TRUE;
                     Really_Done := TRUE;
                  END
               ELSE
                  BEGIN
                     Done := TRUE;
                     WHILE PibTerm_KeyPressed DO
                        Read_Kbd( S_Ch );
                  END;
         END;
                                   (* Alter parity if required *)

      IF ( ( S_Ch <> Ch ) AND ( NOT Done ) AND ( NOT Keyed_In ) ) THEN
         BEGIN

            IF Parity = 'N' THEN
               BEGIN
                  Parity    := 'E';
                  Data_Bits := 7;
               END
            ELSE
               BEGIN
                  Parity    := 'N';
                  Data_Bits := 8;
               END;

            Async_Reset_Port( Comm_Port, Baud_Rate, Parity,
                              Data_Bits, Stop_Bits );

            Set_Status_Line_Name( Short_Terminal_Name );
            Write_To_Status_Line( Status_Line_Name, 1 );

            WRITELN;
            WRITELN('Communication re-adjusted to parity = ',Parity,
                    ' and data bits = ',Data_Bits);
            WRITELN;

         END;
                                   (* Echo character *)
      IF ( NOT Done ) THEN
         BEGIN

            S_Ch := UpCase( S_Ch );

            Host_Send( S_Ch );

            IF Printer_On THEN
               Write_Prt( S_Ch );

            IF Capture_On THEN
               WRITE( Capture_File , S_Ch );

         END;

      Done := Done OR ( NOT Host_Carrier_Detect );

   UNTIL ( S_Ch IN ['Y','N'] ) OR Done;

   IF Done THEN Exit;

   IF S_Ch = 'Y' THEN
      CR_LF_Host := CHR( CR ) + CHR( LF )
   ELSE
      CR_LF_Host := CHR( CR );
                                   (* Get user's ID and password *)
   Try := 0;

   REPEAT
       INC( Try );
       Get_UserInfo( Found );
   UNTIL( ( Try > Max_Login_Try ) OR Found );

                                   (* Check for bad logon or carrier drop *)

   Done := Done OR ( NOT Found ) OR ( NOT Host_Carrier_Detect );

                                   (* Continue to main menu if OK *)
   IF ( NOT Done ) THEN
      BEGIN
                                   (* Mark this as first entry here  *)
         Host_Section := 'I';
                                   (* Loop over main menu until done *)
         REPEAT

            CASE Host_Section OF
               'G':  Gossip_Mode;
               'F':  REPEAT
                        Process_File_Transfer_Commands( Done, Back );
                     UNTIL( Done OR Back );
               'D':  IF ( Privilege = 'S' ) THEN
                        BEGIN
                           IF ( NOT Local_Host ) THEN
                              Jump_To_Dos
                           ELSE
                              BEGIN
                                 DosJump('');
                                 Host_Section := Last_Host_Sect;
                              END;
                        END;
               ELSE
                     Process_Host_Commands( Done );
            END (* CASE *);

            Done := Done OR ( NOT Host_Carrier_Detect );

         UNTIL ( Done );

      END;
                                   (* Update status line *)
   Host_Status( 'Wait for call' );

                                   (* Record this logout *)

   Write_Log( 'Logged off.', FALSE, FALSE );

   Host_Status('Logged off');

   Write_Log( 'Waiting for call.', FALSE, FALSE );

END   (* Do_Host *);

(*----------------------------------------------------------------------*)
(*          Initialize_Host_Mode --- Initializes host mode              *)
(*----------------------------------------------------------------------*)

PROCEDURE Initialize_Host_Mode;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Initialize_Host_Mode                                 *)
(*                                                                      *)
(*     Purpose:    Initializes host mode.                               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Initialize_Host_Mode;                                         *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*       This routine reads the user file into memory and scans the     *)
(*       message file as well.  The asynchronous communications port    *)
(*       is also initialized.                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Qerr           : BOOLEAN;
   User_File      : Text_File;
   User_Line      : AnyStr;
   I              : INTEGER;
   Done_Flag      : BOOLEAN;
   Xfer_List_File : Text_File   (* File transfer list file    *);

(*----------------------------------------------------------------------*)
(*            Get_A_String --- get string up to specified delimeter     *)
(*----------------------------------------------------------------------*)

FUNCTION Get_A_String( S : AnyStr; VAR IS: INTEGER; Delim: CHAR ) : AnyStr;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Get_A_String                                         *)
(*                                                                      *)
(*     Purpose:    Gets string up to specified delimeter.               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        D_String := Get_A_String( S : AnyStr; VAR IS: INTEGER;        *)
(*                                  Delim: CHAR ) : AnyStr;             *)
(*                                                                      *)
(*           S        --- string to be scanned                          *)
(*           IS       --- first position in S to be scanned             *)
(*           Delim    --- delimeter character to mark end of string     *)
(*                                                                      *)
(*           D_String --- returns substring of S beginning at IS and    *)
(*                        proceeding up to (but not including) Delim,   *)
(*                        or end of string.                             *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   T: AnyStr;

BEGIN (* Get_A_String *)

   T := '';

   WHILE ( IS <= LENGTH( S ) ) AND ( S[IS] <> Delim ) DO
      BEGIN
         T  := T + S[IS];
         INC( IS );
      END;

   Get_A_String := T;

END   (* Get_A_String *);

(*----------------------------------------------------------------------*)
(*      Get_Kbd_String --- get string from keyboard with ESC check      *)
(*----------------------------------------------------------------------*)

FUNCTION Get_Kbd_String(     Prompt  : AnyStr;
                             ForceUp : BOOLEAN;
                         VAR S       : AnyStr  ) : BOOLEAN;

BEGIN (* Get_Kbd_String *)
                                   (* Issue prompt *)
   WRITE( Prompt );
                                   (* Read string *)
   S := '';
   Read_Edited_String( S );
   WRITELN;
                                   (* Trim trailing blanks *)
   S := Trim( S );
                                   (* Convert to upper case *)
   IF ForceUp THEN
      S := UpperCase( S );
                                   (* Check for null or ESC *)

   Get_Kbd_String := ( S <> '' ) AND ( S <> CHR( ESC ) );

END   (* Get_Kbd_String *);

(*----------------------------------------------------------------------*)
(*      Create_XferList_File --- Create file listing downloadable files *)
(*----------------------------------------------------------------------*)

PROCEDURE Create_XferList_File;

VAR
   File_Entry          : SearchRec;
   S_File_Name         : STRING[14];
   S_File_Time         : STRING[8];
   S_File_Date         : STRING[8];
   Done                : BOOLEAN;
   Dir_Spec            : AnyStr;
   Dir_Skip_Entry      : BYTE;

BEGIN (* Create_XferList_File *)

                                   (* XFer_List_File already assigned. *)
            (*!I-*)
   REWRITE( XFer_List_File );
            (*!I+*)

   IF ( INT24Result <> 0 ) THEN
      BEGIN
         Write_Log('Cannot create PIBTERM.XFR.', FALSE, TRUE);
         WRITELN;
         EXIT;
      END
   ELSE
      IF ( LENGTH( Host_Mode_Download ) = 0 ) THEN
         BEGIN
            Write_Log('Creating empty PIBTERM.XFR.', FALSE, TRUE);
            WRITELN;
            WRITELN( Xfer_List_File , 'No files available for downloading.' );
            EXIT;
         END;

   Write_Log('Creating PIBTERM.XFR from directory ' + Host_Mode_Download + '.',
             FALSE, TRUE);
                                   (* Construct directory specification *)

   Dir_Spec := Host_Mode_Download + '*.*';

   WRITELN( Xfer_List_File ,
            '====================== Files available for downloading =======================');

                                   (* Attributes of files to be skipped.  *)

   Dir_Skip_Entry := Hidden OR Directory OR VolumeID OR SysFile;

                                   (* Get the download directory contents *)

   FindFirst( Dir_Spec, AnyFile, File_Entry );

   Done  := ( DosError <> 0 );

   WHILE( NOT Done ) DO
      WITH File_Entry DO
         BEGIN
                                   (* Skip next directory entry if *)
                                   (* hidden or subdirectory.      *)

            IF ( ( Attr AND Dir_Skip_Entry ) = 0 ) THEN
               BEGIN
                                   (* Pick up file name *)

                  S_File_Name := Name + DUPL( ' ' , 14 - LENGTH( Name ) );

                                   (* Pick up creation date and time *)

                  Dir_Convert_File_Date_And_Time( Time , S_File_Date , S_File_Time );

                                   (* Write entry to xferlist file *)

                  WRITELN( Xfer_List_File,
                           S_File_Name,     ' ',
                           Size:8  , ' ',
                           S_File_Date,     ' ',
                           S_File_Time );

               END;

         FindNext( File_Entry );

         Done := Done OR ( DosError <> 0 );

   END;

END    (* Create_XferList_File *);

(*----------------------------------------------------------------------*)

BEGIN (* Initialize_Host_Mode *)
                                   (* Set termination flags *)
   Host_Mode      := TRUE;
   Done           := FALSE;
   Really_Done    := FALSE;
   First_Time     := TRUE;
   User_File_Size := 0;
                                   (* Save file paths      *)

   Save_Upload       := Upload_Dir_Path;
   Save_Download     := Download_Dir_Path;
   Download_Dir_Path := Host_Mode_Upload;
   Upload_Dir_Path   := Host_Mode_Download;
   Save_Review       := Review_On;
   Review_On         := FALSE;
   Save_Logging      := Logging_On;
   Logging_On        := TRUE;

                                   (* Open log file *)

   Log_File_Open     := Open_For_Append( Log_File,
                                         Log_File_Name, Ierr );

                                   (* Clear screen to start     *)

   PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line );
   Clear_Window;
                                   (* Display status lines      *)

   Status_Line_Attr    := 16 * ( ForeGround_Color AND 7 ) +
                          BackGround_Color;
   Do_Status_Line      := TRUE;
   Do_Status_Time      := TRUE;
   Current_Status_Time := -1;

   User_Line := ' ESC=quit  F1=chat  F2=logout  F3=DOS  F4=undim  F5=caller  CR=start local';
   User_Line := User_Line + DUPL( ' ' , Max_Screen_Col - LENGTH( User_Line ) );
   WriteSXY( User_Line, 1, PRED( Max_Screen_Line ), Status_Line_Attr );

   Short_Terminal_Name := 'Host Mode';
   Set_Status_Line_Name( Short_Terminal_Name );
   Write_To_Status_Line( Status_Line_Name, 1 );

   PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line - 2 );
   GoToXY( 1 , 1 );

   Write_Log('Host mode started.', FALSE, FALSE );

                                   (* Read in the user file *)

   ASSIGN( User_File, Home_Dir + 'PIBTERM.USF' );
      (*!I-*)
   RESET ( User_File );
      (*!I+*)
                                   (* User file not present --- prompt *)
                                   (* for single name, password, and   *)
                                   (* privilege level.                 *)

   IF ( Int24Result <> 0 ) THEN
      BEGIN

         WRITELN(' ');

         Write_Log('No user file present, single user mode assumed.',
                   FALSE, TRUE );

         User_List := @One_User;

         WITH User_List^[1] DO
            BEGIN
               IF ( NOT Get_Kbd_String('Enter first name: ', TRUE, First_Name ) ) THEN
                  BEGIN
                     Really_Done := TRUE;
                     EXIT;
                  END;
               IF ( NOT Get_Kbd_String('Enter last name:  ', TRUE, Last_Name  ) ) THEN
                  BEGIN
                     Really_Done := TRUE;
                     EXIT;
                  END;
               IF ( NOT Get_Kbd_String('Enter password:   ', FALSE, PassWord  ) ) THEN
                  BEGIN
                     Really_Done := TRUE;
                     EXIT;
                  END;
               IF YesNo('Allow superuser privileges (Y/N)? ') THEN
                  Privilege := 'S'
               ELSE
                  Privilege := 'N';
            END;

         WRITELN(' ');

         NUsers := 1;

      END
   ELSE
      BEGIN
                                   (* Scan user file to find # entries      *)
         User_File_Size := 0;

         REPEAT
            READLN( User_File , User_Line );
            INC   ( User_File_Size );
         UNTIL ( EOF( User_File ) OR ( User_File_Size > MaxUsers ) );

                                   (* Allocate space for user file entries. *)

         GETMEM( User_List , User_File_Size * SIZEOF( User_Record ) );

                                   (* Make sure we got the space *)

         IF ( User_List = NIL ) THEN
            BEGIN

               Really_Done := TRUE;

               WRITELN(' ');

               Write_Log('Not enough memory to store user entries.',
                         FALSE, TRUE );

               CLOSE( User_File );
               I := Int24Result;

               User_File_Size := 0;

               EXIT;

            END;
                                   (* Reposition user file for reread *)
         RESET( User_File );
                                   (* Set number of users to 0        *)
         NUsers := 0;

         REPEAT

            INC( NUsers );

            READLN( User_File , User_Line );

            WITH User_List^[NUsers] DO
               BEGIN
                  I          := 1;
                  First_Name := Trim( UpperCase( Get_A_String( User_Line, I, ';') ) );
                  INC( I );
                  Last_Name  := Trim( UpperCase( Get_A_String( User_Line, I, ';') ) );
                  INC( I );
                  PassWord   := Trim( Get_A_String( User_Line, I, ';') );
                  INC( I );
                  Privilege  := Trim( UpperCase( Get_A_String( User_Line, I, ';') ) );
                  IF ( Privilege <> 'S' ) THEN
                     Privilege := 'N';
               END;

            IF ( User_List^[NUsers].First_Name = '' ) THEN
               DEC( NUsers );

         UNTIL ( EOF( User_File ) OR ( NUsers >= MaxUsers ) );

         IF ( NUsers = 1 ) THEN
            Write_Log( 'There is 1 user recorded in user file.',
                       FALSE, TRUE)
         ELSE
            Write_Log( 'There are ' + IToS( NUsers ) + ' users recorded in user file.',
                       FALSE, TRUE);
         WRITELN;

         IF Debug_Mode THEN
            IF YesNo('Display users (Y/N)? ') THEN
               BEGIN

                  WRITELN(' ');

                  FOR I := 1 TO NUsers DO
                     WITH User_List^[I] DO
                        BEGIN
                           WRITE( First_Name, ' ', Last_Name, ' ', PassWord );
                           IF Privilege = 'S' THEN
                              WRITE( '*** SuperUser ***' );
                           WRITELN;
                        END;

               END
            ELSE
               WRITELN(' ');

      END;
                                   (* Close user file              *)
      (*!I-*)
   CLOSE( User_File );
      (*!I+*)

   I := INT24Result;
                                   (* Scan message file to see how *)
                                   (* many messages there are      *)
   NMessages := 0;

   ASSIGN( Message_File , Home_Dir + 'PIBTERM.MSG' );
      (*!I-*)
   RESET( Message_File );
      (*!I+*)

   IF Int24Result <> 0 THEN
      BEGIN
         Write_Log('No messages in message base.', FALSE, TRUE);
         WRITELN;
      END
   ELSE
      REPEAT

         READLN( Message_File , Message_Line );

         IF COPY( Message_Line, 1, 6 ) = '== End' THEN
            INC( NMessages );

      UNTIL ( EOF( Message_File ) );

   IF ( NMessages > 0 ) THEN
      IF ( NMessages = 1 ) THEN
         BEGIN
            Write_Log('There is 1 message in message base.',
                      FALSE, TRUE);
            WRITELN;
         END
      ELSE
         BEGIN
            Write_Log('There are ' + IToS( NMessages ) + ' messages in message base.',
                      FALSE, TRUE);
            WRITELN;
         END;

      (*!I-*)
   CLOSE( Message_File );
      (*!I+*)

   I := INT24Result;
                                   (* Create PIBTERM.XFR if needed *)

   ASSIGN( XFer_List_File , Home_Dir + 'PIBTERM.XFR' );
      (*!I-*)
   RESET( XFer_List_File );
      (*!I+*)

   IF ( Int24Result <> 0 ) THEN
      Create_XferList_File;

      (*!I-*)
   CLOSE( Xfer_List_File );
      (*!I+*)

   I := INT24Result;

END   (* Initialize_Host_Mode *);

(*----------------------------------------------------------------------*)
(*             Terminate_Host_Mode --- Terminate host mode              *)
(*----------------------------------------------------------------------*)

PROCEDURE Terminate_Host_Mode;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Terminate_Host_Mode                                  *)
(*                                                                      *)
(*     Purpose:    Terminates host mode.                                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Terminate_Host_Mode;                                          *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*       This routine hangs up the phone.                               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Save_Baud : WORD;

BEGIN (* Terminate_Host_Mode *)
                                   (* Wait a second for output to drain *)

   Cur_Host_Status := 'End host session';

   Async_Drain_Output_Buffer( One_Second ) ;

   IF ( NOT Hard_Wired ) THEN
      BEGIN
                                   (* Reset the port *)
         Reset_The_Port;

         Save_Baud := New_Baud;
         Baud_Rate := New_Baud;
                                   (* Hang up the phone *)
         HangUpPhone;
                                   (* Reset the modem   *)

         Send_Modem_Command( Modem_Host_UnSet );

         Async_Drain_Output_Buffer( Five_Seconds );

         Baud_Rate := Save_Baud;

         Async_Reset_Port( Comm_Port, Baud_Rate, Parity, Data_Bits, Stop_Bits );

         Async_Purge_Buffer;

         Set_Status_Line_Name( Short_Terminal_Name );
         Write_To_Status_Line( Status_Line_Name, 1 );

      END;

   WRITELN;
   WRITELN('Host session ended.');

   IF Hard_Wired THEN
      Really_Done := Really_Done OR YesNo('Return to terminal emulation mode (Y/N)? ');

END   (* Terminate_Host_Mode *);

(*----------------------------------------------------------------------*)
(*        Wait_For_Ring --- Wait for phone to ring and answer it        *)
(*----------------------------------------------------------------------*)

PROCEDURE Wait_For_Ring( VAR Done: BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Wait_For_Ring                                        *)
(*                                                                      *)
(*     Purpose:    Answers the phone in host mode.                      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Wait_For_Ring( VAR Done : BOOLEAN );                          *)
(*                                                                      *)
(*           Done -- set TRUE if carrier drops or Sysop requests        *)
(*                   host mode termination.                             *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*       This routine answers the phone and analyzes the modem response *)
(*       in order to set the proper baud rate for communications.       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Qerr       : BOOLEAN;
   Modem_Ans  : AnyStr;
   Ch         : CHAR;
   I          : INTEGER;
   J          : INTEGER;
   MTimeOut   : BOOLEAN;
   Int_Ch     : INTEGER;
   Blanked    : BOOLEAN;
   Local_Save : Saved_Screen_Ptr;

(*----------------------------------------------------------------------*)
(*         Host_Baud_Detect --- Detect caller's baud rate from CRs      *)
(*----------------------------------------------------------------------*)

PROCEDURE Host_Baud_Detect;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Host_Baud_Detect                                     *)
(*                                                                      *)
(*     Purpose:    Detects caller's baud rate from CR entries           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Host_Baud_Detect;                                             *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Async_Receive_With_TimeOut                                    *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The initial baud rate is set to 2400 baud.  Then, as the      *)
(*        enters characters, we look at each and alter the baud rate    *)
(*        until something recognizable emerges.                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   Wait_Ch_Time = 10                (* Seconds to wait for a character *);

                                   (* Supported host mode baud rates *)
   N_Of_Host_Baud_Rates = 5;

   Host_Baud_Rates : ARRAY[1..N_Of_Host_Baud_Rates] OF WORD
                     = ( 2400, 1200, 9600, 19200, 300 );

VAR
   Found_Speed : BOOLEAN;
   IBaud       : INTEGER;

(*----------------------------------------------------------------------*)
(*               Try_Baud_Rate --- Try a specified baud rate            *)
(*----------------------------------------------------------------------*)

FUNCTION Try_Baud_Rate( Test_Baud_Rate: WORD ) : BOOLEAN;

VAR
   Stripped_Ch : INTEGER;
   Timed_Out   : BOOLEAN;
   Ch          : INTEGER;

BEGIN (* Try_Baud_Rate *)
                                   (* Assume this baud rate fails *)
   Try_Baud_Rate := FALSE;
                                   (* Set port to given baud rate *)
   Baud_Rate     := Test_Baud_Rate;

   Async_Reset_Port( Comm_Port, Baud_Rate, Parity, Data_Bits, Stop_Bits );

   Set_Status_Line_Name( Short_Terminal_Name );
   Write_To_Status_Line( Status_Line_Name, 1 );

                                   (* Wait for a character              *)

   Async_Receive_With_TimeOut( Wait_Ch_Time , Ch );
   Timed_Out := ( Ch = TimeOut );
   Async_Clear_Errors;
                                   (* Strip parity bit                 *)
   Stripped_Ch := ( Ch AND $7F );
                                   (* See if it's recognizable as CR   *)
                                   (* or space.  If so, then check     *)
                                   (* the parity.                      *)
   IF ( NOT Timed_Out ) THEN
      IF ( Stripped_Ch = CR     )   OR
         ( Stripped_Ch = ORD(' ') ) THEN
         BEGIN
            Try_Baud_Rate := TRUE;
            IF ( Stripped_Ch <> Ch ) THEN
               BEGIN

                  IF Parity = 'N' THEN
                     BEGIN
                        Parity    := 'E';
                        Data_Bits := 7;
                     END
                  ELSE
                     BEGIN
                        Parity    := 'N';
                        Data_Bits := 8;
                     END;

                  Async_Reset_Port( Comm_Port, Baud_Rate, Parity,
                                    Data_Bits, Stop_Bits );

                  Set_Status_Line_Name( Short_Terminal_Name );
                  Write_To_Status_Line( Status_Line_Name, 1 );

               END;
         END;

END   (* Try_Baud_Rate *);

(*----------------------------------------------------------------------*)

BEGIN (* Host_Baud_Detect *)
                                   (* Indicates if speed detected       *)
   Found_Speed := FALSE;
                                   (* Wait for modem messages to appear *)

   DELAY( 2 * Tenth_Of_A_Second_Delay );

                                   (* Purge the receive buffer          *)
   Async_Purge_Buffer;
                                   (* Loop until speed found            *)

   WHILE ( NOT Found_Speed ) AND ( Async_Carrier_Detect ) DO
      BEGIN

         IBaud := 0;
                                   (* Try each baud rate in turn        *)
         REPEAT

            INC( IBaud );
            Parity      := 'N';
            Data_Bits   := 8;
            Found_Speed := Try_Baud_Rate( Host_Baud_Rates[IBaud] );

         UNTIL ( Found_Speed ) OR ( IBaud >= N_Of_Host_Baud_Rates );

                                   (* If we found the speed, try   *)
                                   (* getting a second character.  *)
                                   (* If it's not recognizable,    *)
                                   (* then it didn't work.         *)
         IF Found_Speed THEN
            Found_Speed := Try_Baud_Rate( Host_Baud_Rates[IBaud] );

                                   (* If we didn't get the speed,  *)
                                   (* flush the buffer before next *)
                                   (* try.                         *)

         IF ( NOT Found_Speed ) THEN
            BEGIN
               DELAY( 5 );
               Async_Purge_Buffer;
            END;

      END  (* WHILE *);
                                   (* Flush the buffer once more *)
   DELAY( Tenth_Of_A_Second_Delay );

   Async_Purge_Buffer;

   WRITELN('Communications adjusted to ',Baud_Rate,' baud and parity = ',
           Parity );

END    (* Host_Baud_Detect *);

(*----------------------------------------------------------------------*)
(*     Host_AutoBaud_Detect --- Detect caller's baud rate from modem    *)
(*----------------------------------------------------------------------*)

PROCEDURE Host_AutoBaud_Detect;

VAR
   New_Baud: WORD;
   I       : INTEGER;
   J       : INTEGER;

BEGIN (* Host_AutoBaud_Detect *)

   New_Baud := 0;
   J        := POS( Modem_Connect, Modem_Ans ) + LENGTH( Modem_Connect );

   FOR I := J TO LENGTH( Modem_Ans ) DO
      IF Modem_Ans[I] IN ['0'..'9'] THEN
         New_Baud := New_Baud * 10 + ORD( Modem_Ans[I] ) - ORD('0');

   IF New_Baud = 0 THEN New_Baud := 300;

   IF New_Baud > 0 THEN
      BEGIN

         Baud_Rate := New_Baud;

         Async_Reset_Port( Comm_Port, Baud_Rate, Parity, Data_Bits, Stop_Bits );

         Set_Status_Line_Name( Short_Terminal_Name );
         Write_To_Status_Line( Status_Line_Name, 1 );

         WRITELN('Communications adjusted to ',Baud_Rate,' baud.');

      END;

END   (* Host_AutoBaud_Detect *);

(*----------------------------------------------------------------------*)

BEGIN (* Wait_For_Ring *)
                                   (* Always 8,n,1 to start in host mode *)
   Parity    := 'N';
   Data_Bits := 8;
   Stop_Bits := 1;
   Baud_Rate := Save_H_Baud_Rate;

   Async_Reset_Port( Comm_Port, Baud_Rate, Parity, Data_Bits, Stop_Bits );

   Set_Status_Line_Name( Short_Terminal_Name );
   Write_To_Status_Line( Status_Line_Name, 1 );

                                   (* Set the modem *)
   IF ( NOT Hard_Wired ) THEN
      Send_Modem_Command( Modem_Host_Set );

   Async_Drain_Output_Buffer( Five_Seconds );

   Async_Purge_Buffer;
                                   (* Indicate wait for call *)

   Host_Status( 'Wait for call' );

                                   (* Nothing from modem yet *)
   Modem_Ans  := '';
                                   (* Assume remote session  *)
   Local_Host := FALSE;
                                   (* Raise terminal ready   *)
   Async_Term_Ready( TRUE );
                                   (* Not done yet           *)
   Done := FALSE;
                                   (* Display intro blurb    *)

   WRITELN('Waiting for phone to ring.');
   WRITELN('Hit ESC key to return to terminal mode.');
   WRITELN('F1 starts/stops chat mode.');
   WRITELN('F2 immediately logs out remote user.');
   WRITELN('F3 jumps to DOS.');
   WRITELN('F4 undims screen afters it has been dimmed.');
   WRITELN('F5 gives name of current caller.');
   WRITELN('Hit any other key to start local host session.');

                                   (* Remove any pending input     *)
   Async_Purge_Buffer;
                                   (* Track time in between sessions *)
   Blank_Time := TimeOfDay;
   Blanked    := FALSE;

   REPEAT                          (* Wait for ring/carrier detect *)

      IF PibTerm_KeyPressed THEN
         BEGIN
            Read_Kbd( Ch );
            IF Ch = CHR( ESC ) THEN
               BEGIN
                  IF PibTerm_KeyPressed THEN
                     BEGIN
                        Read_Kbd( Ch );
                        CASE ORD( Ch ) OF
                           F3: DosJump('');
                           F4: IF Blanked THEN
                                  BEGIN
                                     Blank_Time          := TimeOfDay;
                                     Restore_Screen( Local_Save );
                                     Current_Status_Time := -1;
                                     Do_Status_Time      := TRUE;
                                     Update_Status_Line;
                                     Blanked             := FALSE;
                                  END;
                           ELSE
                              Local_Host := TRUE;
                        END (* CASE *)
                     END  (* PibTerm_KeyPressed *)
                  ELSE
                     Done := TRUE;
               END
            ELSE
               Local_Host := TRUE;
         END
      ELSE
         GiveAwayTime( 2 );

      IF ( NOT Blanked ) THEN
         IF ( TimeDiff( Blank_Time , TimeOfDay ) > Host_Mode_Blank_Time ) THEN
            BEGIN
               WRITELN('Blanking the screen ... ');
               DELAY( Three_Second_Delay );
               Save_Screen( Local_Save );
               PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line );
               Clear_Window;
               Blanked := TRUE;
               Do_Status_Time := FALSE;
            END;

   UNTIL ( Host_Carrier_Detect ) OR Done OR Local_Host;

   IF Blanked THEN
      BEGIN
         Restore_Screen( Local_Save );
         Current_Status_Time := -1;
         Do_Status_Time      := TRUE;
         Update_Status_Line;
      END;

   IF Done THEN Really_Done := TRUE;

                                   (* If local host session,   *)
                                   (* turn off terminal ready  *)
                                   (* so phone isn't answered. *)
   IF Local_Host THEN
      BEGIN
         WRITELN('Local host session begins ... ');
         Async_Term_Ready( FALSE );
         EXIT;
      END;

   IF NOT Done THEN
      BEGIN                        (* Answer the phone *)

         WRITELN('Answered phone ... ');

         Host_Status( 'Answered phone' );

(*---------------------------------------------------------------*)
(*                                                               *)
(*       ----- Let the modem answer the phone -----              *)
(*                                                               *)
(*       Send_Modem_Command( Modem_Answer );                     *)
(*                                                               *)
(*---------------------------------------------------------------*)

         DELAY( One_Second_Delay );

                                   (* Collect modem response for *)
                                   (* later analysis.            *)
         MTimeOut := FALSE;

         REPEAT

            Async_Receive_With_TimeOut( 1 , Int_Ch );

            IF Int_Ch <> TimeOut THEN
               BEGIN
                  Ch := CHR( Int_Ch );
                  IF Ch IN ['A'..'Z',' ','0'..'9'] THEN
                     Modem_Ans := Modem_Ans + Ch;
                  WRITE( Ch );
                  IF Printer_On THEN
                     Write_Prt( Ch );
                  IF Capture_On THEN
                     WRITE( Capture_File , Ch );
               END
            ELSE
               MTimeOut := TRUE;

         UNTIL ( MTimeOut OR Done );

                                   (* Find speed for caller's modem. *)
         IF ( NOT Done ) THEN
            IF ( NOT Hard_Wired ) THEN
               IF Host_Auto_Baud THEN
                  Host_AutoBaud_Detect
               ELSE
                  Host_Baud_Detect;

      END  (* NOT Done *);

   Done := Done OR ( NOT Host_Carrier_Detect );

END   (* Wait_For_Ring *);

(*----------------------------------------------------------------------*)
(*            Emulate_Host_Mode --- main routine for host mode          *)
(*----------------------------------------------------------------------*)

BEGIN (* Emulate_Host_Mode *)
                                   (* Make sure we want to enter host mode *)
                                   (* if session in progress.              *)
   IF Async_Carrier_Detect THEN
      IF Attended_Mode THEN
         BEGIN
            WRITELN;
            IF ( NOT YesNo('Are you sure you want to enter host mode (Y/N)? ') ) THEN
               BEGIN
                  Terminal_To_Emulate := Saved_Gossip_Term;
                  Host_Mode           := FALSE;
                  EXIT;
               END;
         END;
                                   (* Save current port settings *)
   Save_H_Parity     := Parity;
   Save_H_Data_Bits  := Data_Bits;
   Save_H_Stop_Bits  := Stop_Bits;
   Save_H_Baud_Rate  := Baud_Rate;

                                   (* Initialize host mode *)
   Initialize_Host_Mode;

   IF ( NOT Really_Done ) THEN
      REPEAT
                                   (* Wait for call *)
         Wait_For_Ring( Done );
                                   (* Do a host session *)
         IF NOT Done THEN Do_Host;
                                   (* End host session *)
         Terminate_Host_Mode;

      UNTIL Really_Done;

   IF ( User_File_Size > 0 ) THEN
      MyFreeMem( User_List , User_File_Size * SIZEOF( User_Record ) );

   WRITELN(' ');
   WRITELN('Host mode communications closed down, ');
   WRITELN('returning to terminal emulation mode. ');

   Write_Log('Host mode ended.', FALSE, FALSE );

            (*!I-*)
   IF Log_File_Open THEN
      IF ( NOT Save_Logging ) THEN
         BEGIN
            CLOSE( Log_File );
            Log_File_Open := FALSE;
         END;
            (*!I+*)

   Ierr := Int24Result;
                                   (* Remove status line display *)

   PibTerm_Window( 1 , 1 , Max_Screen_Col , Max_Screen_Line );

   GoToXY( 1 , PRED( Max_Screen_Line ) );
   ClrEol;
   GoToXY( 1 , Max_Screen_Line );
   ClrEol;

   GoToXY( 1 , PRED( Max_Screen_Line ) );
   PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line );

                                   (* Restore previous file paths    *)

   Upload_Dir_Path   := Save_Upload;
   Download_Dir_Path := Save_Download;

                                   (* Restore previous terminal type *)
                                   (* or dumb terminal mode if       *)
                                   (* previous also host mode.       *)

   IF ( Saved_Gossip_Term = HostMode ) THEN
      Terminal_To_Emulate := Dumb
   ELSE
      Terminal_To_Emulate := Saved_Gossip_Term;

   Host_Mode           := FALSE;
   Review_On           := Save_Review;
   Logging_On          := Save_Logging;

                                   (* Restore previous port settings *)
   Parity    := Save_H_Parity;
   Data_Bits := Save_H_Data_Bits;
   Stop_Bits := Save_H_Stop_Bits;
   Baud_Rate := Save_H_Baud_Rate;

   Async_Reset_Port( Comm_Port, Baud_Rate, Parity, Data_Bits, Stop_Bits );

   Set_Status_Line_Name( Short_Terminal_Name );
   Write_To_Status_Line( Status_Line_Name, 1 );

END   (* Emulate_Host_Mode *);
