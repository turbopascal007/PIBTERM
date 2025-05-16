(*----------------------------------------------------------------------*)
(*  Process_File_Transfer_Commands --- Process file transfer commands   *)
(*----------------------------------------------------------------------*)

PROCEDURE Process_File_Transfer_Commands( VAR Done: BOOLEAN;
                                          VAR Back: BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Process_File_Transfer_Commands                       *)
(*                                                                      *)
(*     Purpose:    Controls processing of file transfer commands.       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Process_File_Transfer_Commands( VAR Done: BOOLEAN;            *)
(*                                        VAR Back: BOOLEAN );          *)
(*                                                                      *)
(*           Done --- set TRUE if quit command entered or carrier       *)
(*                    dropped.                                          *)
(*           Back --- set TRUE if return to main menu requested.        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Ch       : CHAR;
   Found_Ch : BOOLEAN;
   Dont_Echo: BOOLEAN;

LABEL
   ReadChar;

(*----------------------------------------------------------------------*)
(*      Display_Xfer_Commands --- Display file transfer commands        *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Xfer_Commands;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Display_Xfer_Commands                                 *)
(*                                                                      *)
(*     Purpose:   Displays menu of PibTerm file transfer commands and   *)
(*                prompts for command entry.                            *)
(*                                                                      *)
(*     Calling sequence:                                                *)
(*                                                                      *)
(*        Display_Xfer_Commands;                                        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Display_Xfer_Commands *)

   IF ( NOT Expert_On ) THEN
      BEGIN
         Host_Send_String_With_CR(' ');
         Host_Send_String_With_CR('======================================================');
         Host_Send_String_With_CR('=        PibTerm Host Mode File Transfer Menu        =');
         Host_Send_String_With_CR('======================================================');
         Host_Send_String_With_CR(' ');
         Host_Send_String_With_CR('     U=Upload file');
         Host_Send_String_With_CR('     D=Download file');
         Host_Send_String_With_CR('     L=List files for transfer');
         IF ( Privilege = 'S' ) THEN
            Host_Send_String_With_CR('     J=Jump to DOS');
         Host_Send_String_With_CR('     M=Return to main menu');
         Host_Send_String_With_CR('     Q=Quit and logoff');
         Host_Send_String_With_CR('     X=Expert mode');
         Host_Send_String_With_CR(' ');
         Host_Send_String_With_CR('======================================================');
         Host_Send_String_With_CR(' ');
         Host_Send_String_And_Echo('Enter command ? ');
      END
   ELSE
      BEGIN
         Host_Send_String_With_CR(' ');
         IF ( Privilege = 'S' ) THEN
            Host_Send_String_And_Echo('Xfer (U,D,J,L,M,Q,X) ? ')
         ELSE
            Host_Send_String_And_Echo('Xfer (U,D,L,M,Q,X) ? ');
      END;

   IF ( NOT Local_Host ) THEN
      Async_Purge_Buffer;

END   (* Display_Xfer_Commands *);

(*----------------------------------------------------------------------*)
(*    List_Files_For_Transfer --- List files available for transfer     *)
(*----------------------------------------------------------------------*)

PROCEDURE List_Files_For_Transfer;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: List_Files_For_Transfer                               *)
(*                                                                      *)
(*     Purpose:   Displays files available for transfer.                *)
(*                                                                      *)
(*     Calling sequence:                                                *)
(*                                                                      *)
(*        List_Files_For_Transfer;                                      *)
(*                                                                      *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This procedure sends the contents of the PIBTERM.XFR file to  *)
(*        the remote user.                                              *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   LCount            : INTEGER;
   LDone             : BOOLEAN;
   XFer_Line         : AnyStr;
   Xfer_List_File    : Text_File   (* File transfer list file    *);

BEGIN (* List_Files_For_Transfer *)

                                   (* Open xferlist file *)
   Host_Status('List files');

   ASSIGN( Xfer_List_File , Home_Dir + 'PIBTERM.XFR' );
      (*!I-*)
   RESET( Xfer_List_File );
      (*!I+*)
                                   (* If not there, no transfer possible *)
   IF Int24Result <> 0 THEN
      BEGIN
         Host_Send_String( CR_LF_Host );
         Host_Send_String_With_CR('No files available for transfer.');
      END
   ELSE                            (* If there, list it *)
      BEGIN

         LCount := 2;
         LDone  := FALSE;

         Host_Send_String( CR_LF_Host );
         Host_Send_String_With_CR('List of files available for transfer: ');
         Host_Send_String_With_CR(' ');

         List_Prompt( LCount , LDone );

         REPEAT

            READLN( Xfer_List_File , Xfer_Line );

            Host_Send_String_With_CR( Xfer_Line );

            List_Prompt( LCount , LDone );

         UNTIL ( EOF( Xfer_List_File ) OR LDone );

      END;

      (*!I-*)
   CLOSE( Xfer_List_File );
      (*!I+*)
   Host_IO_Error := Int24Result;

   Host_Send_String_With_CR(' ');
   Host_Prompt_And_Read_String('Finished listing files, hit <CR> to continue: ',
                               Xfer_Line, TRUE );
   Host_Send_String_With_CR(' ');

   Write_Log('List files for transfer.', FALSE, FALSE );

   Host_Status( Cur_Host_Status );

END   (* List_Files_For_Transfer *);

(*----------------------------------------------------------------------*)
(*        Display_Xfer_Protocols --- Display file xfer protocols        *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Xfer_Protocols;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Display_Xfer_Protocols;                               *)
(*                                                                      *)
(*     Purpose:   Displays available file transfer protocols.           *)
(*                                                                      *)
(*     Calling sequence:                                                *)
(*                                                                      *)
(*        Display_Xfer_Protocols;                                       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   T : Transfer_Type;
   I : INTEGER;
   S : AnyStr;

BEGIN (* Display_Xfer_Protocols *)

   Host_Send_String( CR_LF_Host );
   Host_Send_String_With_CR('Available transfer protocols are: ');
   Host_Send_String_With_CR(' ');
{
   Host_Send_String_With_CR('   A         Ascii');
   Host_Send_String_With_CR('   X         Xmodem CheckSum');
   Host_Send_String_With_CR('   XC        Xmodem CRC');
   Host_Send_String_With_CR('   XK        Xmodem 1K');
   Host_Send_String_With_CR('   XG        Xmodem 1K G');
   Host_Send_String_With_CR('   YB        Ymodem Batch');
   Host_Send_String_With_CR('   YG        Ymodem G Batch');
   Host_Send_String_With_CR('   T         Telink');
   Host_Send_String_With_CR('   M         Modem7 Batch Checksum');
   Host_Send_String_With_CR('   MC        Modem7 Batch CRC');
   Host_Send_String_With_CR('   K         Kermit (Text file)');
   Host_Send_String_With_CR('   KB        Kermit (Binary file)');
   Host_Send_String_With_CR('   SL        SEALink');
   Host_Send_String_With_CR('   RL        RLink');
   Host_Send_String_With_CR('   WX        Windowed Xmodem');
}
   FOR I := 1 TO Max_Transfer_Types DO
      BEGIN
         T := Transfers[I];
         IF ( ( Trans_Type_Name[T]  <> '  ' ) AND
              ( Trans_OK_In_Host[T] OR ( Privilege = 'S' ) ) ) THEN
            BEGIN
               S := '   ' + COPY( Trans_Type_Name[T], 1, 2 ) + '        ' +
                    Transfer_Name_List[I];
               Host_Send_String_With_CR( S );
            END;
      END;

   Host_Send_String_With_CR('   Q or ^X  Quit transfer');

END   (* Display_Xfer_Protocols *);

(*----------------------------------------------------------------------*)
(*              Get_Xfer_Protocol --- Get file xfer protocol            *)
(*----------------------------------------------------------------------*)

FUNCTION Get_Xfer_Protocol : Transfer_Type;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:  Get_Xfer_Protocol;                                    *)
(*                                                                      *)
(*     Purpose:   Prompts remote user for, and reads, selected file     *)
(*                transfer protocol.                                    *)
(*                                                                      *)
(*     Calling sequence:                                                *)
(*                                                                      *)
(*        Trans_Type := Get_Xfer_Protocol : Transfer_Type;              *)
(*                                                                      *)
(*           Trans_Type --- Protocol chosen by remote user.             *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Trans_Mode        : ShortStr;
   Transfer_Protocol : Transfer_Type;
   I                 : INTEGER;
   Trans_Mode_Char2  : Char_2;
   T                 : Transfer_Type;

BEGIN (* Get_Xfer_Protocol *)

   REPEAT

      Host_Send_String( CR_LF_Host );
      Host_Prompt_And_Read_String('Enter transfer protocol (? for list, ^X to quit): ',
                                   Trans_Mode, TRUE );

      Trans_Mode_Char2[1] := ' ';
      Trans_Mode_Char2[2] := ' ';

      Trans_Mode := Uppercase( TRIM( Trans_Mode ) );

      FOR I := 1 TO MIN( LENGTH( Trans_Mode ) , 2 ) DO
         Trans_Mode_Char2[I] := Trans_Mode[I];

      Transfer_Protocol := None;

      IF ( Trans_Mode = '?' ) THEN
         Display_Xfer_Protocols
      ELSE IF ( ( Trans_Mode <> ^X ) AND ( Trans_Mode <> 'Q' ) ) THEN
         FOR I := 1 TO Max_Transfer_Types DO
            BEGIN
               T := Transfers[I];
               IF ( ( Trans_Mode_Char2 = Trans_Type_Name[T] ) AND
                    ( Trans_OK_In_Host[T] OR ( Privilege = 'S' ) ) ) THEN
                  Transfer_Protocol := T;
            END;
{
      ELSE IF Trans_Mode = 'A'  THEN
         Transfer_Protocol := Ascii
      ELSE IF Trans_Mode = 'X'  THEN
         Transfer_Protocol := Xmodem_Chk
      ELSE IF Trans_Mode = 'XC' THEN
         Transfer_Protocol := Xmodem_CRC
      ELSE IF Trans_Mode = 'XG'  THEN
         Transfer_Protocol := Xmodem_1KG
      ELSE IF Trans_Mode = 'XK'  THEN
         Transfer_Protocol := Xmodem_1K
      ELSE IF Trans_Mode = 'YB' THEN
         Transfer_Protocol := Ymodem_Batch
      ELSE IF Trans_Mode = 'YG' THEN
         Transfer_Protocol := Ymodem_G
      ELSE IF Trans_Mode = 'T'  THEN
         Transfer_Protocol := Telink
      ELSE IF Trans_Mode = 'TC' THEN
         Transfer_Protocol := Telink
      ELSE IF Trans_Mode = 'M'  THEN
         Transfer_Protocol := Modem7_Chk
      ELSE IF Trans_Mode = 'MC'  THEN
         Transfer_Protocol := Modem7_CRC
      ELSE IF Trans_Mode = 'M7' THEN
         Transfer_Protocol := Modem7_CRC
      ELSE IF Trans_Mode = 'K' THEN
         BEGIN
            Transfer_Protocol    := Kermit;
            Kermit_File_Type_Var := Kermit_Ascii;
         END
      ELSE IF Trans_Mode = 'KB' THEN
         BEGIN
            Transfer_Protocol    := Kermit;
            Kermit_File_Type_Var := Kermit_Binary;
         END
      ELSE IF Trans_Mode = 'RL'  THEN
         Transfer_Protocol := RLink
      ELSE IF Trans_Mode = 'SL'  THEN
         Transfer_Protocol := SEALink
      ELSE IF Trans_Mode = 'WX' THEN
         Transfer_Protocol := WXModem;
}
   UNTIL ( Transfer_Protocol <> None ) OR ( Trans_Mode = 'Q' ) OR
         ( Trans_Mode = ^X );

   Get_Xfer_Protocol := Transfer_Protocol;

   IF ( Transfer_Protocol = Kermit ) THEN
      Kermit_File_Type_Var := Kermit_Binary;

END   (* Get_Xfer_Protocol *);

(*----------------------------------------------------------------------*)
(*               Upload_A_File  --- Receive file from remote user       *)
(*----------------------------------------------------------------------*)

PROCEDURE Upload_A_File;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Upload_A_File;                                       *)
(*                                                                      *)
(*     Purpose:   Prompts remote user for, and receives, selected file. *)
(*                                                                      *)
(*     Calling sequence:                                                *)
(*                                                                      *)
(*        Upload_A_File;                                                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   File_Name         : AnyStr;
   Trans_Mode        : AnyStr;
   Transfer_Protocol : Transfer_Type;
   OK_To_Upload      : BOOLEAN;
   Save_Attended     : BOOLEAN;
   SDone             : BOOLEAN;
   Single_FP         : BOOLEAN;
   
BEGIN (* Upload_A_File *)
                                   (* Get transfer protocol *)

   Transfer_Protocol := Get_Xfer_Protocol;

   IF Transfer_Protocol = None THEN EXIT;

                                   (* Get file name to transfer if not *)
                                   (* batch protocol.                  *)
   File_Name    := '';
   
   Single_FP    := Single_File_Protocol[Transfer_Protocol];
   OK_To_Upload := TRUE;
   
   IF Single_FP THEN
      BEGIN

         Host_Send_String( CR_LF_Host );
         Host_Prompt_And_Read_String('Enter file name to upload: ',
                                      File_Name, TRUE );

         IF ( File_Name = '' ) THEN EXIT;

         IF ( POS( ^X , File_Name ) > 0 ) THEN EXIT;

         IF ( ( POS( '*', File_Name ) = 0 ) AND
            ( ( POS( '?', File_Name ) = 0 ) ) ) THEN
            OK_To_Upload := NOT Check_If_File_Exists( File_Name, Host_Mode_Upload )
         ELSE 
            BEGIN
               OK_To_Upload := FALSE;
               Host_Send_String( CR_LF_Host );
               Host_Send_String('Wildcards are not allowed for this protocol.');
               EXIT;
            END;

      END;
                                   (* Any file is OK for superuser *)
   IF ( Privilege = 'S' ) THEN
      OK_To_Upload := TRUE;

   IF Ok_To_Upload THEN
      BEGIN                        (* FileName is global for transfers *)

         FileName := File_Name;

         Host_Send_String( CR_LF_Host );
         Host_Send_String_With_CR('Ready to receive, begin your send procedure.');

         Async_Drain_Output_Buffer( Five_Seconds );

         Save_Attended := Attended_Mode;

         Attended_Mode := FALSE;

         Host_Status('Receiving file');

                                   (* Start transfer *)

         PibDownLoad( Transfer_Protocol );

                                   (* Make sure script if any is executed *)

         WHILE Script_File_Mode DO
            BEGIN
               Get_Script_Command( PibTerm_Command );
               Execute_Command   ( PibTerm_Command , SDone , TRUE );
            END;

         Host_Status(Cur_Host_Status);

         Attended_Mode := Save_Attended;

                                   (* Reset window *)

         PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line - 2 );

      END
   ELSE
      BEGIN
         Host_Send_String( CR_LF_Host );
         Host_Send_String_With_CR('File already exists, upload cancelled.');
         OK_To_Upload := FALSE;
      END;

END   (* Upload_A_File *);

(*----------------------------------------------------------------------*)
(*             Get_Transfer_Time --- Get transfer time for files        *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Transfer_Time( VAR File_Spec             : AnyStr;
                             VAR N_Files               : INTEGER;
                             VAR Transfer_Time_Message : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_Transfer_Time                                    *)
(*                                                                      *)
(*     Purpose:    Gets transfer time for download                      *)
(*                                                                      *)
(*     Calling sequence:                                                *)
(*                                                                      *)
(*        Get_Transfer_Time(     File_Spec             : AnyStr;        *)
(*                           VAR N_Files               : INTEGER;       *)
(*                           VAR Transfer_Time_Message : AnyStr );      *)
(*                                                                      *)
(*           File_Spec             --- File spec for files to get       *)
(*           N_Files               --- # of files to be transferred     *)
(*           Transfer_Time_Message --- Message about transfer time      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Total_File_Size: LONGINT;
   File_Size      : LONGINT;
   File_Entry     : SearchRec;
   Last_Found     : BOOLEAN;
   SN_Files       : STRING[8];
   S_File_Size    : STRING[8];
   OK_File        : BOOLEAN;
   Info_Line      : AnyStr;
   Transfer_Time  : LONGINT;

BEGIN (* Get_Transfer_Time *)

   Host_Send_String( CR_LF_Host );

   Host_Send_String_With_CR('Scanning file list ... ');

                                   (* No files = 0 total file size at start *)
   Total_File_Size := 0;
   N_Files         := 0;
                                   (* Append download directory name *)
                                   (* if necessary.                  *)

   Add_Path( File_Spec, Host_Mode_Download, File_Spec );

                                   (* See if any files at all *)

   FindFirst( File_Spec, AnyFile, File_Entry );
   Last_Found := ( DosError <> 0 );

   WHILE ( NOT Last_Found ) DO
      WITH File_Entry DO
         BEGIN (* WHILE *)
                                   (* Pick up file name, check if it *)
                                   (* is on Xferlist.                *)

            OK_File          := FALSE;

            IF ( Privilege = 'S' ) THEN
               OK_File := TRUE
            ELSE
               OK_File := ( Scan_Xfer_List( Name ) > 0 );

                                   (* If OK to download, add its length *)
                                   (* into current running total.       *)
            IF OK_File THEN
               BEGIN (* OK_File *)
                                   (* Increment file count *)

                  INC( N_Files );

                                   (* Display message if first file *)

                  IF ( N_Files = 1 ) THEN
                     BEGIN
                        Host_Send_String_With_CR(' File name      Size     Trans. time');
                        Host_Send_String_With_CR('============  ========   ===========');
                     END;
                                   (* Pick up file size    *)

                  Total_File_Size := Total_File_Size + Size;

                                   (* Display information           *)

                  STR( Size:8 , S_File_Size );

                  Transfer_Time := ROUND( ROUND( ( Size / 128.0 ) + 0.49 ) *
                                                 ( Trans_Time_Val * 1.0 ) /
                                                 ( Baud_Rate      * 1.0 ) );

                  Info_Line := Name +
                               DUPL( ' ' , 14 - LENGTH( Name ) ) +
                               S_File_Size + '     ' +
                               TimeString( Transfer_Time , Military_Time );

                  Host_Send_String_With_CR( Info_Line );

               END   (* OK_File *);
                                         (* See if more files to transfer *)

            FindNext( File_Entry );
            Last_Found := Last_Found OR ( DosError <> 0 );

         END  (* WHILE *);
                                   (* Pick up transfer time *)

      Transfer_Time_Message := 'Approximate transfer time for ';

      IF ( N_Files <= 1 ) THEN
         Transfer_Time_Message := Transfer_Time_Message + '1 file is '
      ELSE
         BEGIN
            STR( N_Files , SN_Files );
            Transfer_Time_Message := Transfer_Time_Message + SN_Files
                                     + ' files is ';
         END;

      Transfer_Time_Message := Transfer_Time_Message +
                               TimeString( ROUND( ( Total_File_Size / 128.0 ) + 0.49 ) *
                                           ROUND( ( Trans_Time_Val * 1.0 ) / Baud_Rate ),
                                           Military_Time );

END   (* Get_Transfer_Time *);

(*----------------------------------------------------------------------*)
(*             Download_A_File  --- Send file to remote user            *)
(*----------------------------------------------------------------------*)

PROCEDURE Download_A_File;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Download_A_File;                                     *)
(*                                                                      *)
(*     Purpose:   Prompts remote user for, and sends, selected file.    *)
(*                                                                      *)
(*     Calling sequence:                                                *)
(*                                                                      *)
(*        Download_A_File;                                              *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   File_Name         : AnyStr;
   Trans_Mode        : AnyStr;
   Transfer_Protocol : Transfer_Type;
   N_Files           : INTEGER;
   Save_Attended     : BOOLEAN;
   SDone             : BOOLEAN;

BEGIN (* Download_A_File *)
                                   (* Get transfer protocol *)

   Transfer_Protocol := Get_Xfer_Protocol;
   IF Transfer_Protocol = NONE THEN EXIT;

                                   (* Get file spec for files to get *)

   Host_Send_String( CR_LF_Host );
   Host_Prompt_And_Read_String('Enter file name to download: ',
                                File_Name, TRUE );

   IF ( File_Name = '' ) THEN EXIT;

   IF ( POS( ^X , File_Name ) > 0 ) THEN EXIT;

                                   (* Check that file name is proper form *)
   IF ( Privilege <> 'S' ) THEN
      IF ( POS( '\' , File_Name ) <> 0 ) OR
         ( POS( ':' , File_Name ) <> 0 ) THEN
         BEGIN
            Host_Send_String( CR_LF_Host );
            Host_Send_String('That is not a valid file specification.');
            EXIT;
         END;
                                   (* Check wildcards on wrong protocols *)

   IF ( ( POS( '*', File_Name ) <> 0 ) OR
        ( POS( '?', File_Name ) <> 0 ) ) THEN
      IF ( Single_File_Protocol[Transfer_Protocol] ) THEN
         BEGIN
            Host_Send_String( CR_LF_Host );
            Host_Send_String('Wildcards are not allowed for this protocol.');
            EXIT;
         END;
                                   (* Get file names and sizes *)

   Get_Transfer_Time( File_Name , N_Files , Trans_Mode );

   IF ( N_Files <= 0 ) THEN
      BEGIN
         Host_Send_String( CR_LF_Host );
         Host_Send_String_With_CR('No files found to send, transfer cancelled.');
         EXIT;
      END;
                                   (* FileName is global for transfers *)
   FileName := File_Name;

   Host_Send_String( CR_LF_Host );
   Host_Send_String_With_CR( Trans_Mode );
   Host_Send_String_With_CR('Ready to send, begin your receive procedure.');

                                   (* Get the file(s) ! *)

   Async_Drain_Output_Buffer( Five_Seconds );

   Save_Attended := Attended_Mode;

   Attended_Mode := FALSE;

   Host_Status('Sending file');
                                   (* Start transfer *)
   PibUpLoad( Transfer_Protocol );
                                   (* Make sure script if any is executed *)

   WHILE Script_File_Mode DO
      BEGIN
         Get_Script_Command( PibTerm_Command );
         Execute_Command   ( PibTerm_Command , SDone , TRUE );
      END;

   Host_Status(Cur_Host_Status);

   Attended_Mode := Save_Attended;

                                   (* Reset window *)

   PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line - 2 );

END   (* Download_A_File *);

(*----------------------------------------------------------------------*)

BEGIN (* Process_File_Transfer_Commands *)

                                   (* Indicate we're in file transfer *)

   Cur_Host_Status := 'File section';

   Host_Status(Cur_Host_Status);
                                   (* Stay in files section for a while *)
   Back := FALSE;
                                   (* Prompt for commands *)
   Display_Xfer_Commands;
                                   (* Wait for command to be entered *)
ReadChar:
                                   (* No keyboard input yet *)
   Kbd_Input := FALSE;

   REPEAT
      Found_Ch := Async_Receive( Ch ) OR PibTerm_KeyPressed;
      Done     := Done OR ( NOT Host_Carrier_Detect );
      IF ( NOT Found_Ch ) THEN
         GiveAwayTime( 2 );
   UNTIL Done OR Found_Ch;
                                   (* Process input from keyboard *)
   Dont_Echo := FALSE;

   IF PibTerm_KeyPressed THEN
      BEGIN
         Read_Kbd( Ch );
         Kbd_Input := TRUE;
         IF ( ORD( Ch ) = ESC ) AND PibTerm_KeyPressed THEN
            BEGIN
               Dont_Echo := TRUE;
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
                                   (* Echo command character *)
      IF( NOT Dont_Echo ) THEN
         BEGIN
            IF Printer_On THEN
               Write_Prt_Str( Ch + CRLF_String );
            IF Capture_On THEN
               WRITELN( Capture_File, Ch );
            Host_Send_String( Ch + CR_LF_Host );
         END;
                                   (* Process command request *)
      CASE UpCase( Ch ) OF

         'U':  Upload_A_File;
         'D':  Download_A_File;
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
         'L':  List_Files_For_Transfer;
         'X':  Expert_On := NOT Expert_On;
         'M':  BEGIN
                  Back         := TRUE;
                  Host_Section := 'M';
               END;
         'G':  IF Kbd_Input THEN
                  BEGIN
                     Host_Send_String_With_CR(' ... System operator wishes' +
                                               ' to chat, please wait ...');
                     Host_Send_String_With_CR(' ');
                     Back           := TRUE;
                     Last_Host_Sect := 'F';
                     Host_Section   := 'G';
                  END;

         'J':  IF ( Privilege = 'S' ) THEN
                  BEGIN
                     Host_Section   := 'D';
                     Last_Host_Sect := 'F';
                     Back           := TRUE;
                  END
               ELSE
                  Host_Send_String( ^G );

         'Z':  IF Kbd_Input THEN
                  DosJump('');

         ELSE  Host_Send_String( ^G );

      END (* CASE *)

END   (* Process_File_Transfer_Commands *);

