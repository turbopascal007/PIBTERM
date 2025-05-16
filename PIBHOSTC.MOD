(*----------------------------------------------------------------------*)
(*      Reset_The_Port --- Reset serial port to issue modem commands    *)
(*----------------------------------------------------------------------*)

PROCEDURE Reset_The_Port;

BEGIN (* Reset_The_Port *)

   IF ( Baud_Rate <> 300 ) THEN
      New_Baud := 300
   ELSE
      New_Baud := 150;

   Async_Reset_Port( Comm_Port, New_Baud, Parity, Data_Bits, Stop_Bits );

   Set_Status_Line_Name( Short_Terminal_Name );
   Write_To_Status_Line( Status_Line_Name, 1 );

   Host_Status( Cur_Host_Status );

END   (* Reset_The_Port *);

(*----------------------------------------------------------------------*)
(*      Jump_To_Dos --- allow privileged users to access DOS directly   *)
(*----------------------------------------------------------------------*)

PROCEDURE Jump_To_Dos;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Jump_To_Dos                                          *)
(*                                                                      *)
(*     Purpose:    Allows use of DOS remotely.                          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Jump_To_Dos;                                                  *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*         A batch file is constructed which executes the CTTY command. *)
(*         This batch file is executed using the Dos EXEC function.     *)
(*         When the remote user types EXIT, control is returned here.   *)
(*         Note:  A user must have a privilege level of "S" (Special)   *)
(*                to use this function.                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Batch_File : Text_File;
   Save_Close : BOOLEAN;
   I          : INTEGER;
   CTTY_Device: STRING[8];

BEGIN (* Jump_To_Dos *)

   Host_Status('Jump to DOS');

   Write_Log( 'Jump to DOS.' , FALSE, FALSE );

                                   (* Open batch file *)

   ASSIGN( Batch_File , 'PIBTCTTY.BAT' );
      (*!I-*)
   REWRITE( Batch_File );
      (*!I+*)

   IF ( Int24Result <> 0 ) THEN
      BEGIN
         Host_Send_String_With_CR('Can''t jump to DOS.');
         Host_Section := Last_Host_Sect;
         EXIT;
      END;
                                   (* Construct MODE and CTTY statements *)

   IF ( LENGTH( Host_CTTY_Device ) > 0 ) THEN
      CTTY_Device := Host_CTTY_Device
   ELSE
      CTTY_Device := 'COM';

   WRITELN( Batch_File , 'ECHO OFF');
   WRITELN( Batch_File , 'MODE COM', Comm_Port,':',Baud_Rate,',',
                         Parity,',',Data_Bits,',',Stop_Bits );
   WRITELN( Batch_File , 'CTTY ', CTTY_Device, Comm_Port );
   WRITELN( Batch_File , 'COMMAND' );

      (*!I-*)
   CLOSE( Batch_File );
      (*!I+*)

   IF ( Int24Result <> 0 ) THEN
      BEGIN
         Host_Send_String_With_CR('Can''t jump to DOS.');
         Host_Section := Last_Host_Sect;
         EXIT;
      END;
                                   (* Make sure async interrupts closed down *)

   Save_Close         := Close_Comm_For_Dos;
   Close_Comm_For_Dos := TRUE;
                                   (* Reset modem in case of line drop *)

   IF ( NOT ( Hard_Wired OR Local_Host ) ) THEN
      BEGIN

         Host_Send_String_With_CR(' ');
         Host_Send_String_With_CR('Resetting modem.  Ignore any garbage that appears.');
         Host_Send_String_With_CR(' ');

                                   (* Wait for remote to get message *)

         Async_Drain_Output_Buffer( Five_Seconds );

                                   (* Reset comm parameters so that *)
                                   (* modem commands don't go to    *)
                                   (* remote.                       *)
         Reset_The_Port;
                                   (* Restore startup mode on modem *)

         Send_Modem_Command( Modem_Host_UnSet );

                                   (* Wait for remote to get message *)

         Async_Drain_Output_Buffer( Five_Seconds );

                                   (* Reset port *)

         Async_Reset_Port( Comm_Port, Baud_Rate, Parity, Data_Bits, Stop_Bits );

         Set_Status_Line_Name( Short_Terminal_Name );
         Write_To_Status_Line( Status_Line_Name, 1 );

      END;
                                   (* Send message message indicating *)
                                   (* attempt to jump to DOS          *)

   Host_Send_String_With_CR(' ');
   Host_Send_String_With_CR('Jumping to DOS.');
   Host_Send_String_With_Cr('Type EXIT to return to PibTerm.');
   Host_Send_String_With_CR(' ');
                                   (* Wait for remote to get message *)

   Async_Drain_Output_Buffer( Five_Seconds );

                                   (* Execute batch file *)
   DosJump( 'PIBTCTTY' );
                                   (* Erase batch file *)
      (*!I-*)
   ERASE( Batch_File );
      (*!I+*)

   I := Int24Result;
                                   (* Reinitialize modem for host mode *)

   IF ( NOT ( Hard_Wired OR Local_Host ) ) THEN
      BEGIN
         Reset_The_Port;
         Send_Modem_Command( Modem_Host_Set );
         Async_Drain_Output_Buffer( Five_Seconds );
         Async_Reset_Port( Comm_Port, Baud_Rate, Parity, Data_Bits, Stop_Bits );
         Set_Status_Line_Name( Short_Terminal_Name );
         Write_To_Status_Line( Status_Line_Name, 1 );
         DELAY( Two_Second_Delay );
      END;
                                   (* Restore previous close_comm flag *)

   Close_Comm_For_Dos := Save_Close;

                                   (* Return to last section used *)
   Host_Section := Last_Host_Sect;

   Host_Status(Cur_Host_Status);

END   (* Jump_To_Dos *);

(*----------------------------------------------------------------------*)
(*         Process_Host_Commands --- Process main menu commands         *)
(*----------------------------------------------------------------------*)

PROCEDURE Process_Host_Commands( VAR Done: BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Process_Host_Commands                                *)
(*                                                                      *)
(*     Purpose:    Controls processing of main menu commands.           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Process_Host_Commands( VAR Done: BOOLEAN );                   *)
(*                                                                      *)
(*           Done --- set TRUE if quit command entered or carrier       *)
(*                    dropped.                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Back        : BOOLEAN;
   Ch          : CHAR;
   Sysop_Found : BOOLEAN;
   Found_Ch    : BOOLEAN;

LABEL
   ReadChar;

(*----------------------------------------------------------------------*)
(*   Display_Host_Commands --- Display command list for remote user     *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Host_Commands;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Display_Host_Commands                                 *)
(*                                                                      *)
(*     Purpose:   Displays menu of PibTerm host commands and prompts    *)
(*                for command entry.                                    *)
(*                                                                      *)
(*     Calling sequence:                                                *)
(*                                                                      *)
(*        Display_Host_Commands;                                        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Display_Host_Commands *)

   IF ( NOT Expert_On ) THEN
      BEGIN
         Host_Send_String_With_CR(' ');
         Host_Send_String_With_CR('======================================================');
         Host_Send_String_With_CR('=             PibTerm Host Mode Main Menu            =');
         Host_Send_String_With_CR('======================================================');
         Host_Send_String_With_CR(' ');
         Host_Send_String_With_CR('     E=Enter message');
         Host_Send_String_With_CR('     R=Read message');
         Host_Send_String_With_CR('     S=Scan messages');
         Host_Send_String_With_CR('     P=Personal message scan');
         Host_Send_String_With_CR('     Q=Quit and logoff');
         Host_Send_String_With_CR('     F=File transfers');
         Host_Send_String_With_CR('     G=Gossip mode');
         Host_Send_String_With_CR('     X=Expert mode');
         Host_Send_String_With_CR('     C=Send comments');
         Host_Send_String_With_CR('     W=Read welcome message');
         IF ( Privilege = 'S' ) THEN
            Host_Send_String_With_CR('     J=Jump to DOS');
         Host_Send_String_With_CR(' ');
         Host_Send_String_With_CR('======================================================');
         Host_Send_String_And_Echo('Enter command ? ');
      END
   ELSE
      BEGIN
         Host_Send_String_With_CR(' ');
         IF ( Privilege = 'S' ) THEN
            Host_Send_String_And_Echo('Main (E,R,S,P,Q,F,G,X,C,W,J) ? ')
         ELSE
            Host_Send_String_And_Echo('Main (E,R,S,P,Q,F,G,X,C,W) ? ');
      END;

   IF ( NOT Local_Host ) THEN
      Async_Purge_Buffer;

END   (* Display_Host_Commands *);

(*----------------------------------------------------------------------*)
(*            Page_Sysop --- Page sysop to enter gossip mode            *)
(*----------------------------------------------------------------------*)

PROCEDURE Page_Sysop( VAR Sysop_Found : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Page_Sysop                                           *)
(*                                                                      *)
(*     Purpose:    Pages Sysop to enter gossip mode.                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Page_Sysop( VAR Sysop_Found : BOOLEAN );                      *)
(*                                                                      *)
(*           Sysop_Found --- TRUE if sysop responds.                    *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        If silent mode is on (Alt_M) then this page is not performed. *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Timer: LONGINT;
   I    : INTEGER;
   Ch   : CHAR;

BEGIN (* Page_Sysop *)

   Write_Log('Page SYSOP.', FALSE, FALSE );

   Host_Status('Paging SYSOP');

   Host_Send_String_With_CR(' ');

   Sysop_Found := FALSE;

   IF ( NOT Silent_Mode ) THEN
      BEGIN

         Host_Send_String_With_CR('Summoning Sysop (^X cancels) ...');

         Timer := 30;

         REPEAT

            FOR I := 1 TO 5 DO
               WRITE( CHR( BELL ) );

            IF Async_Receive( Ch ) THEN
               IF ( Ch = ^X ) THEN
                  Timer := 0;

            IF PibTerm_KeyPressed THEN
               BEGIN
                  Read_Kbd( Ch );
                  IF ( Ch = CHR( ESC ) ) AND PibTerm_KeyPressed THEN
                     Read_Kbd( Ch );
                  IF ( Ch <> ^X ) THEN
                     Sysop_Found := TRUE
                  ELSE
                     Timer := 0;
               END;

            DELAY( One_Second_Delay );

            DEC( Timer );

         UNTIL ( Timer <= 0 ) OR ( Sysop_Found );

      END
   ELSE
      Host_Send_String_With_CR('Sysop not available, gossip cancelled.');

   Host_Status(Cur_Host_Status);

END   (* Page_Sysop *);

(*----------------------------------------------------------------------*)
(*           Get_A_Message  --- Get text of message from user           *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_A_Message( VAR F: Text_File );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_A_Message                                        *)
(*                                                                      *)
(*     Purpose:    Prompts for line by line message entry.              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_A_Message( VAR F: Text_File );                            *)
(*                                                                      *)
(*           F --- file to write message to.                            *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine handles text entry for both regular messages and *)
(*        comments.                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Get_A_Message *)

   WITH User_List^[Cur_User] DO
      WRITELN( F, '== From:    ', Fname, ' ', Lname );
   WRITELN( F, '== To:      ',Recipient_Name );
   WRITELN( F, '== Date:    ',DateString );
   WRITELN( F, '== Time:    ',TimeString( TimeOfDay , Military_Time ) );
   WRITELN( F, '== Subject: ',Message_Subject );

   Host_Send_String( CR_LF_Host );
   Host_Send_String_With_CR('Enter message.   Empty line terminates.');

   REPEAT
      Host_Send_String( CR_LF_Host );
      Host_Prompt_And_Read_String('> ', Message_Line, TRUE );
      IF LENGTH( Message_Line ) > 0 THEN
         WRITELN( F, ' ', Message_Line );
   UNTIL ( LENGTH( Message_Line ) = 0 );

   WRITELN( F, '== End');

   Host_Send_String( CR_LF_Host );
   Host_Send_String_With_CR('Message entered.');

END   (* Get_A_Message *);

(*----------------------------------------------------------------------*)
(*           Enter_Message  --- Enter a message into message base       *)
(*----------------------------------------------------------------------*)

PROCEDURE Enter_Message;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Enter_Message                                        *)
(*                                                                      *)
(*     Purpose:    Enters message into message base.                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Enter_Message;                                                *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Open_For_Append                                               *)
(*        Get_A_Message                                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Quit: BOOLEAN;
   Ierr: INTEGER;

BEGIN (* Enter_Message *)

   Host_Status('Enter message');

   Quit := FALSE;
                                   (* Open message file *)

   ASSIGN( Message_File, Home_Dir + 'PIBTERM.MSG' );
      (*!I-*)
   RESET ( Message_File );
      (*!I+*)
                                   (* If it exists, open for append.       *)
                                   (* If it doesn't exist, open for write. *)
   IF Int24Result <> 0 THEN
      BEGIN
         WRITELN('Creating message file PIBTERM.MSG');
            (*!I-*)
         REWRITE( Message_File );
            (*!I+*)
         IF Int24Result <> 0 THEN
            BEGIN
               Host_Send_String_With_CR('Sorry, no more room for messages');
               Quit := TRUE;
            END;
      END
   ELSE
      BEGIN

            (*!I-*)
         CLOSE( Message_File );
            (*!I+*)

         Host_IO_Error := Int24Result;

         IF ( NOT Open_For_Append( Message_File , Home_Dir + 'PIBTERM.MSG' , Ierr ) ) THEN
            BEGIN
               Host_Send_String( CR_LF_Host );
               Host_Send_String_With_CR('Sorry, no more room for messages');
               Quit := TRUE;
            END;

      END;

   Host_Send_String( CR_LF_Host );
   Host_Prompt_And_Read_String('Enter recipient''s name or ALL: ',
                                  Recipient_Name, TRUE );

   Recipient_Name := UpperCase( TRIM( Recipient_Name ) );

   IF Recipient_Name = '' THEN
      Recipient_Name := 'ALL';

   Host_Send_String( CR_LF_Host );
   Host_Prompt_And_Read_String('Enter title for message: ',
                               Message_Subject, TRUE );

   IF ( NOT Quit ) THEN
      Get_A_Message( Message_File );

      (*!I-*)
   CLOSE ( Message_File );
      (*!I+*)

   Host_IO_Error := Int24Result;
                                   (* Increment message count *)
   INC( NMessages );

   Write_Log('Enter message.', FALSE, FALSE );

   Host_Status(Cur_Host_Status);

END   (* Enter_Message *);

(*----------------------------------------------------------------------*)
(*    Skip_To_Message  --- Skip to specified message in message base    *)
(*----------------------------------------------------------------------*)

PROCEDURE Skip_To_Message( Msg_No : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Skip_To_Message                                      *)
(*                                                                      *)
(*     Purpose:    Skip to specified message in message base.           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Skip_To_Message( Msg_No : INTEGER );                          *)
(*                                                                      *)
(*           Msg_No --- Message to skip to.                             *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The message file must be opened before this routine is        *)
(*        called.                                                       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Msg_Count : INTEGER;

BEGIN (* Skip_To_Message *)

   Msg_Count := 0;

   REPEAT

      READLN( Message_File , Message_Line );

      IF COPY( Message_Line, 1, 6 ) = '== End' THEN
         INC( Msg_Count );

   UNTIL ( Msg_Count = PRED( Msg_No ) );

END   (* Skip_To_Message *);

(*----------------------------------------------------------------------*)
(*             Read_Messages  --- Read messages from message base       *)
(*----------------------------------------------------------------------*)

PROCEDURE Read_Messages;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Read_Messages                                        *)
(*                                                                      *)
(*     Purpose:    Reads messages currently in message base.            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Read_Messages;                                                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Message_No   : INTEGER;
   CMessage_No  : STRING[5];
   I            : INTEGER;
   Line_Count   : INTEGER;
   Read_Done    : BOOLEAN;
   Start_Msg    : INTEGER;
   Start_M_Str  : AnyStr;
   OK_Number    : BOOLEAN;

LABEL
   Reading_Done;

BEGIN (* Read_Messages *)

   Host_Status('Read message');
                                   (* Open message file *)

   ASSIGN( Message_File , Home_Dir + 'PIBTERM.MSG' );
      (*!I-*)
   RESET( Message_File );
      (*!I+*)
                                   (* Not there -- no messages *)
   IF Int24Result <> 0 THEN
      BEGIN
         Host_Send_String( CR_LF_Host );
         Host_Send_String_With_CR('No messages in message file.');
         EXIT;
      END;
                                   (* Find where to start *)
   REPEAT

      OK_Number := TRUE;

      Host_Send_String_With_CR(' ');

      STR( NMessages , Start_M_Str );

      IF ( NMessages = 1 ) THEN
         Start_M_Str := 'There is 1 message in message base.'
      ELSE
         Start_M_Str := 'There are ' + Start_M_Str + ' messages in message base.';

      Host_Send_String_With_CR(Start_M_Str);

      Host_Prompt_And_Read_String('Enter message to start at or <CR> for all: ',
                                   Start_M_Str, TRUE );
      Start_Msg := 0;
      FOR I := 1 TO LENGTH( Start_M_Str ) DO
         IF ( Start_M_Str[I] IN ['0'..'9'] ) THEN
            Start_Msg := Start_Msg * 10 + ORD( Start_M_Str[I] ) - ORD('0')
         ELSE
            OK_Number := FALSE;

      IF Start_Msg = 0 THEN Start_Msg := 1;
      IF Start_Msg > NMessages THEN Start_Msg := NMessages;

   UNTIL ( NOT Host_Carrier_Detect ) OR ( OK_Number );

   IF ( NOT Host_Carrier_Detect ) THEN GOTO Reading_Done;

                                   (* Skip to desired message *)
   Skip_To_Message( Start_Msg );

                                   (* Messages always start at one *)
   Message_No := PRED( Start_Msg );
   Read_Done  := FALSE;
   Line_Count := 0;
                                   (* Loop over messages *)
   REPEAT
                                   (* Increment message number *)

      INC( Message_No );

      STR( Message_No : 5 , CMessage_No );

      Host_Send_String( CR_LF_Host );
      List_Prompt( Line_Count , Read_Done );
      IF Read_Done THEN GOTO Reading_Done;

      Host_Send_String_With_CR('Message #' + CMessage_No);
      List_Prompt( Line_Count , Read_Done );
      IF Read_Done THEN GOTO Reading_Done;

                                   (* Display message # and header info *)
      FOR I := 1 TO 5 DO
         BEGIN
            READLN( Message_File , Message_Line );
            Message_Line := COPY( Message_Line, 4,
                                  LENGTH( Message_Line ) - 3 );
            Host_Send_String_With_CR( Message_Line );
            List_Prompt( Line_Count , Read_Done );
            IF Read_Done THEN GOTO Reading_Done;
         END;

      Host_Send_String_With_CR(' ');
      List_Prompt( Line_Count , Read_Done );
      IF Read_Done THEN GOTO Reading_Done;

                                   (* Display body of message *)
      REPEAT

         READLN( Message_File , Message_Line );

         IF ( COPY( Message_Line, 1, 6 ) <> '== End' ) THEN
            BEGIN
               Host_Send_String_With_CR( COPY( Message_Line, 2,
                                                PRED( LENGTH( Message_Line ) ) ) );
               List_Prompt( Line_Count , Read_Done );
            END;

      UNTIL ( COPY( Message_Line, 1, 6 ) = '== End' ) OR ( Read_Done );

   UNTIL ( Message_No >= NMessages ) OR Read_Done;

Reading_Done:

   Host_Send_String_With_CR(' ');
   Host_Prompt_And_Read_String('Finished reading messages, hit <CR> to continue: ',
                               Start_M_Str, TRUE );
   Host_Send_String_With_CR(' ');

      (*!I-*)
   CLOSE( Message_File );
      (*!I+*)

   Host_IO_Error := Int24Result;

   Write_Log('Read messages.', FALSE, FALSE );

   Host_Status(Cur_Host_Status);

END   (* Read_Messages *);

(*----------------------------------------------------------------------*)
(*             Scan_Messages  --- Scan messages from message base       *)
(*----------------------------------------------------------------------*)

PROCEDURE Scan_Messages( Personal_Only : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Scan_Messages                                        *)
(*                                                                      *)
(*     Purpose:    Scans message headers currently in message base.     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Scan_Messages( Personal_Only : BOOLEAN );                     *)
(*                                                                      *)
(*           Personal_Only --- Return messages addressed to current     *)
(*                             user only.                               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Message_Title: AnyStr;
   Message_No   : INTEGER;
   CMessage_No  : STRING[5];
   I            : INTEGER;
   Line_Count   : INTEGER;
   Scan_Done    : BOOLEAN;
   OK_Number    : BOOLEAN;
   Start_Msg    : INTEGER;
   Start_M_Str  : AnyStr;
   Message_L1   : AnyStr;
   Message_L2   : AnyStr;
   Msg_Count    : INTEGER;

LABEL
   Scanning_Done;

BEGIN (* Scan_Messages *)

   Host_Status('Scan messages');
                                   (* Open message file *)

   ASSIGN( Message_File , Home_Dir + 'PIBTERM.MSG' );
      (*!I-*)
   RESET( Message_File );
      (*!I+*)
                                   (* Not there -- no messages *)
   IF Int24Result <> 0 THEN
      BEGIN
         Host_Send_String( CR_LF_Host );
         Host_Send_String_With_CR('No messages in message file.');
         GOTO Scanning_Done;
      END;
                                   (* Find where to start -- if only *)
                                   (* personal messages, always scan *)
                                   (* entire message base.           *)
   Start_Msg := 1;

   IF ( NOT Personal_Only ) THEN
      REPEAT
                                   (* Request starting message number *)
         OK_Number := TRUE;

         Host_Send_String_With_CR(' ');

         STR( NMessages , Start_M_Str );
         IF ( NMessages = 1 ) THEN
            Start_M_Str := 'There is 1 message in message base.'
         ELSE
            Start_M_Str := 'There are ' + Start_M_Str + ' messages in message base.';
         Host_Send_String_With_CR(Start_M_Str);

         Host_Prompt_And_Read_String('Enter message to start at or <CR> for all: ',
                                      Start_M_Str, TRUE );

                                   (* Convert response to message number *)
         Start_Msg := 0;

         FOR I := 1 TO LENGTH( Start_M_Str ) DO
            IF ( Start_M_Str[I] IN ['0'..'9'] ) THEN
               Start_Msg := Start_Msg * 10 + ORD( Start_M_Str[I] ) - ORD('0')
            ELSE
               OK_Number := FALSE;
                                   (* Ensure message is in range *)

         IF Start_Msg = 0 THEN Start_Msg := 1;
         IF Start_Msg > NMessages THEN Start_Msg := NMessages;

      UNTIL ( NOT Host_Carrier_Detect ) OR ( OK_Number );

   IF ( NOT Host_Carrier_Detect ) THEN GOTO Scanning_Done;

                                   (* Skip to desired message *)
   Skip_To_Message( Start_Msg );
                                   (* Messages always start at one *)
   Message_No := PRED( Start_Msg );
   Line_Count := 0;
   Scan_Done  := FALSE;
   Msg_Count  := 0;
                                   (* Loop over messages *)
   REPEAT
                                   (* Increment message number *)
      INC( Message_No );

                                   (* Read 1st two lines of message *)

      READLN( Message_File , Message_L1 );
      READLN( Message_File , Message_L2 );

                                   (* Check if recipient is current user *)

      IF ( COPY( Message_L2, 13, LENGTH( Message_L2 ) - 12 ) =
           UpperCase( Cur_User_Name ) ) OR ( NOT Personal_Only ) THEN

         BEGIN (* Display this message *)

                                   (* Increment personal messages count *)

            INC( Msg_Count );

            STR( Message_No : 5 , CMessage_No );

            Host_Send_String( CR_LF_Host );
            List_Prompt( Line_Count , Scan_Done );
            IF Scan_Done THEN GOTO Scanning_Done;

                                   (* Display message number *)

            Host_Send_String_With_CR('Message #' + CMessage_No );
            List_Prompt( Line_Count , Scan_Done );
            IF Scan_Done THEN GOTO Scanning_Done;

                                   (* Display 1st 2 header lines *)

            Host_Send_String_With_CR( COPY( Message_L1, 4,
                                       LENGTH( Message_L1 ) - 3 ) );
            List_Prompt( Line_Count , Scan_Done );
            IF Scan_Done THEN GOTO Scanning_Done;

            Host_Send_String_With_CR( COPY( Message_L2, 4,
                                       LENGTH( Message_L2 ) - 3 ) );
            List_Prompt( Line_Count , Scan_Done );
            IF Scan_Done THEN GOTO Scanning_Done;

                                   (* Display remaining header info *)
            FOR I := 3 TO 5 DO
               BEGIN
                  READLN( Message_File , Message_Line );
                  Message_Line := COPY( Message_Line, 4,
                                        LENGTH( Message_Line ) - 3 );
                  Host_Send_String_With_CR( Message_Line );
                  List_Prompt( Line_Count , Scan_Done );
                  IF Scan_Done THEN GOTO Scanning_Done;
               END;

            Host_Send_String_With_CR(' ');
            List_Prompt( Line_Count , Scan_Done );

         END (* Display this message *);

                                   (* Scan for end of message *)
      IF ( NOT Scan_Done ) THEN
         REPEAT
            READLN( Message_File , Message_Line );
         UNTIL ( COPY( Message_Line, 1, 6 ) = '== End' );

   UNTIL ( Message_No >= NMessages ) OR ( Scan_Done );

Scanning_Done:

      (*!I-*)
   CLOSE( Message_File );
      (*!I+*)

   Host_IO_Error := Int24Result;

                                   (* Notify user if no personal messages *)
   IF Personal_Only THEN
      IF Msg_Count = 0 THEN
         BEGIN
            Host_Send_String_With_CR(' ');
            Host_Send_String_With_CR('You have no personal messages waiting.');
         END;

   Host_Send_String_With_CR(' ');
   Host_Prompt_And_Read_String('Finished scanning messages, hit <CR> to continue: ',
                               Start_M_Str, TRUE );
   Host_Send_String_With_CR(' ');

   Write_Log('Scan messages.', FALSE, FALSE );

   Host_Status(Cur_Host_Status);

END   (* Scan_Messages *);

(*----------------------------------------------------------------------*)
(*                   Enter_Comment  --- Enter a comment                 *)
(*----------------------------------------------------------------------*)

PROCEDURE Enter_Comment;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Enter_Comment                                        *)
(*                                                                      *)
(*     Purpose:    Enters comment into comment file.                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Enter_Comment;                                                *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Open_For_Append                                               *)
(*        Get_A_Message                                                 *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The comments file is PIBTERM.CMT.                             *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Quit          : BOOLEAN;
   Ierr          : INTEGER;
   Comments_File : Text_File;

BEGIN (* Enter_Comment *)

   Host_Status('Enter comment');

   Quit := FALSE;
                                   (* Open comments file *)

   ASSIGN( Comments_File, Home_Dir + 'PIBTERM.CMT' );
      (*!I-*)
   RESET ( Comments_File );
      (*!I+*)
                                   (* If it exists, open for append.       *)
                                   (* If it doesn't exist, open for write. *)
   IF Int24Result <> 0 THEN
      BEGIN
         WRITELN('Creating comments file PIBTERM.CMT');
            (*!I-*)
         REWRITE( Comments_File );
            (*!I+*)
         IF Int24Result <> 0 THEN
            BEGIN
               Host_Send_String( CR_LF_Host );
               Host_Send_String_With_CR('Sorry, can''t accept comments now.');
               Quit := TRUE;
            END;
      END
   ELSE
      BEGIN
            (*!I-*)
         CLOSE( Comments_File );
            (*!I+*)

         Host_IO_Error := Int24Result;

         IF ( NOT Open_For_Append( Comments_File ,
                                   Home_Dir + 'PIBTERM.CMT', Ierr ) ) THEN
            BEGIN
               Host_Send_String( CR_LF_Host );
               Host_Send_String_With_CR('Sorry, can''t accept comments now.');
               Quit := TRUE;
            END;

      END;

   Recipient_Name  := 'SYSOP';
   Message_Subject := ' ';

   IF ( NOT Quit ) THEN
      Get_A_Message( Comments_File );

      (*!I-*)
   CLOSE ( Comments_File );
      (*!I+*)

   Host_IO_Error := Int24Result;

   Write_Log('Enter comment to SYSOP.', FALSE, FALSE );

   Host_Status(Cur_Host_Status);

END   (* Enter_Comment *);

(*----------------------------------------------------------------------*)
(*   Display_Welcome_Message --- Display welcome message after login    *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Welcome_Message;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Display_Welcome_Message                              *)
(*                                                                      *)
(*     Purpose:    Displays welcome message after successful login      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Display_Welcome_Message;                                      *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Open_For_Append                                               *)
(*        Get_A_Message                                                 *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The welcome text is in file PIBTERM.WEL.                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Welcome_File : Text_File;
   Welcome_Line : AnyStr;
   Line_Count   : INTEGER;
   List_Done    : BOOLEAN;

BEGIN (* Display_Welcome_Message *)

   ASSIGN( Welcome_File , Home_Dir + 'PIBTERM.WEL' );
      (*!I-*)
   RESET( Welcome_File );
      (*!I+*)

   IF ( INT24Result = 0 ) THEN
      BEGIN

         Line_Count  := 0;
         List_Done   := FALSE;

         REPEAT
            READLN( Welcome_File , Welcome_Line );
            Host_Send_String_With_Cr( Welcome_Line );
            List_Prompt( Line_Count , List_Done );
         UNTIL ( EOF( Welcome_File ) OR List_Done );

            (*!I-*)
         CLOSE( Welcome_File );
            (*!I+*)

         Host_IO_Error := Int24Result;

         End_Prompt('End of welcome, hit <CR> to continue: ');

      END;

END   (* Display_Welcome_Message *);

(*----------------------------------------------------------------------*)

BEGIN (* Process_Host_Commands *)

                                   (* Scan for personal mail on *)
                                   (* first entry here.         *)
   IF Host_Section = 'I' THEN
      BEGIN

         Display_Welcome_Message;
         Host_Send_String_With_CR(' ');

         Host_Send_String_With_CR(' ');
         Host_Send_String_With_CR('Scanning for personal messages ... ');

         Scan_Messages( TRUE );

         Host_Section := 'M';

      END;

   Cur_Host_Status := 'Message section';
   Host_Status( Cur_Host_Status );

                                   (* Prompt for commands *)
   Display_Host_Commands;
                                   (* Assume input from remote *)

ReadChar:

   Kbd_Input := FALSE;
                                   (* Wait for command to be entered *)
   REPEAT
      Done     := Done OR ( NOT Host_Carrier_Detect );
      Found_Ch := Async_Receive( Ch ) OR PibTerm_KeyPressed;
      IF ( NOT Found_Ch ) THEN
         GiveAwayTime( 2 );
   UNTIL Done OR Found_Ch;

                                   (* Process input from keyboard *)
   IF PibTerm_KeyPressed THEN
      BEGIN
         Read_Kbd( Ch );
         Kbd_Input := TRUE;
         IF ( ORD( Ch ) = ESC ) AND PibTerm_KeyPressed THEN
            BEGIN
               Read_Kbd( Ch );
               CASE ORD( Ch ) OF
                  F1 : Ch := 'G';
                  F2 : Ch := 'Q';
                  F3 : BEGIN
                          DosJump('');
                          Ch := ' ';
                       END;
                  F5 : BEGIN
                          WRITELN;
                          WRITELN('Current caller is ',Cur_User_Name);
                          Ch := ' ';
                       END;
               END (* CASE *);
            END;
      END;

   IF ( Ch = ' ' ) THEN GOTO ReadChar;

   IF ( Not DONE ) THEN
                                   (* Echo command *)

      Host_Send_String( Ch + CR_LF_Host );
      WRITELN;
      IF Printer_On THEN
         Write_Prt_Str( Ch + CRLF_String );
      IF Capture_On THEN
         WRITELN( Capture_File, Ch );

                                   (* Process command request *)
      CASE UpCase( Ch ) OF

         'E':  Enter_Message;
         'R':  Read_Messages;
         'Q':  BEGIN
                  IF Kbd_Input THEN
                     BEGIN
                        Host_Send_String_With_CR('System operator shutting ' +
                                                  'down system.');
                        Host_Send_String_With_CR('Thanks for calling.');
                        Done := TRUE;
                     END
                  ELSE
                     BEGIN
                        Host_Send_String_With_CR('Quit and logoff');
                        Done := TRUE;
                     END;
               END;
         'F':  Host_Section := 'F';
         'G':  BEGIN
                  IF Kbd_Input THEN
                     BEGIN
                        Host_Send_String_With_CR(' ... System operator wishes' +
                                                  ' to chat, please wait ...');
                        Host_Send_String_With_CR(' ');
                        Host_Section   := 'G';
                        Last_Host_Sect := 'M';
                     END
                  ELSE
                     BEGIN
                        Page_Sysop( Sysop_Found );
                        IF Sysop_Found THEN
                           BEGIN
                              Host_Section   := 'G';
                              Last_Host_Sect := 'M';
                           END;
                     END;
               END;
         'C':  Enter_Comment;
         'P':  Scan_Messages( TRUE );
         'X':  Expert_On := NOT Expert_On;
         'S':  Scan_Messages( FALSE );
         'J':  IF ( Privilege = 'S' ) THEN
                  BEGIN
                     Host_Section   := 'D';
                     Last_Host_Sect := 'M';
                  END
               ELSE
                  Host_Send_String( ^G );

         'W':  Display_Welcome_Message;

         ELSE  Host_Send_String( ^G );

      END (* CASE *)

END   (* Process_Host_Commands *);

(*----------------------------------------------------------------------*)
(*           Get_UserInfo --- Read in user name and password            *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_UserInfo( VAR Found: BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_UserInfo                                         *)
(*                                                                      *)
(*     Purpose:    Gets user name and password from remote user.        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_UserInfo( VAR Found: BOOLEAN );                           *)
(*                                                                      *)
(*           Done --- set TRUE if user name found and carrier not       *)
(*                    dropped.                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   MyPass   : AnyStr;
   CallLine : AnyStr;
   Ierr     : INTEGER;

BEGIN (* Get_UserInfo *)

   Host_Status('Get user info');

                                   (* Prompt for first name *)

   Host_Send_String_With_CR(' ');
   Host_Prompt_And_Read_String('Enter first name: ', Fname, TRUE );
   Fname := TRIM( UpperCase( Fname ) );

                                   (* Prompt for second name *)

   Host_Send_String_With_CR(' ');
   Host_Prompt_And_Read_String('Enter last name:  ', Lname, TRUE );
   Lname := TRIM( UpperCase( Lname ) );

                                   (* See if valid user name *)
   Cur_User      := 0;
   Found         := FALSE;
   Privilege     := 'N';
   Cur_User_Name := '';

   IF ( LENGTH( Fname ) > 0 ) AND ( LENGTH( Lname ) > 0 ) THEN
      REPEAT
         INC( Cur_User );
         WITH User_List^[Cur_User] DO
            Found := ( Fname = First_Name ) AND ( Lname = Last_Name );
      UNTIL ( Found OR ( Cur_User >= NUsers ) );

                                   (* Remember name for message scans *)

   Cur_User_Name := Fname + ' ' + Lname;

                                   (* Error if name not in user file *)
   IF ( NOT Found ) THEN
      BEGIN
         Host_Send_String_With_CR(' ');
         Host_Send_String_With_CR('Not a valid user name.');
      END;
                                   (* Prompt for password *)

   IF ( Found AND Host_Carrier_Detect ) THEN
      BEGIN

         Host_Send_String_With_CR(' ');
         Host_Prompt_And_Read_String('Enter Password:   ', MyPass, FALSE );
         Host_Send_String_With_CR(' ');

                                   (* Check if password valid *)

         IF MyPass = User_List^[Cur_User].PassWord THEN
            BEGIN

               Host_Send_String_With_CR('Password OK');

               Found := TRUE;

               Write_Log( Fname + ' ' + Lname + ' logged in.', FALSE, FALSE );

                                   (* Pick up privilege of user *)

               Privilege := User_List^[Cur_User].Privilege[1];

            END
         ELSE
            BEGIN

               Host_Send_String_With_CR('Password wrong');

               Found := FALSE;

               Write_Log( Fname + ' ' + Lname +
                          ' logon try with bad password = ' + MyPass,
                          FALSE, FALSE );

            END;

   END;
                                   (* Update status line *)
   IF Found THEN
      BEGIN
         Cur_Host_Status := Cur_User_Name;
         Host_Status( Cur_Host_Status );
      END;

END   (* Get_UserInfo *);
