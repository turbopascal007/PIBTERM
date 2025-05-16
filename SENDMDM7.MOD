(*----------------------------------------------------------------------*)
(*        Send_Modem7_File --- Upload file with Modem7/Telink           *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Modem7_File( Use_CRC: BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Send_Modem7_File                                     *)
(*                                                                      *)
(*     Purpose:    Uploads file using Modem7/Telink batch               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Send_Modem7_File( Use_CRC: BOOLEAN);                          *)
(*                                                                      *)
(*           Use_CRC --- TRUE to use CRC checking;                      *)
(*                       FALSE to use Checksum checking.                *)
(*                                                                      *)
(*     Calls:   PibTerm_KeyPressed                                      *)
(*              Async_Send                                              *)
(*              Async_Receive_With_TimeOut                              *)
(*              Get_Modem7_File_Name                                    *)
(*              Check_The_KeyBoard                                      *)
(*              RvsVideoOn                                              *)
(*              RvsVideoOff                                             *)
(*              Wait_For_Nak                                            *)
(*              Send_File_Name                                          *)
(*              Perform_Upload                                          *)
(*                                                                      *)
(*      Remarks:                                                        *)
(*                                                                      *)
(*         This routine performs wildcard directory searches and        *)
(*         implements the Modem7 and Telink batch file transfer         *)
(*         protocols.                                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   File_Pattern : AnyStr;
   SFileName    : PACKED ARRAY[1..11] OF CHAR;
   Int_Ch       : INTEGER;
   Ch           : CHAR;
   CheckSum     : INTEGER;
   EndFName     : BOOLEAN;
   I            : INTEGER;
   J            : INTEGER;
   File_Entry   : SearchRec;
   Ack_OK       : BOOLEAN;
   OK_File      : BOOLEAN;

(*----------------------------------------------------------------------*)
(*          Check_The_KeyBoard --- Check for keyboard input             *)
(*----------------------------------------------------------------------*)

PROCEDURE Check_The_KeyBoard;

BEGIN (* Check_The_KeyBoard *)

   Check_KeyBoard;

   IF Stop_Send THEN
      BEGIN
         IF ( NOT Display_Status ) THEN
            Display_Batch_Window;
         WRITELN('  Alt_S pressed, transfer cancelled.');
      END;

END   (* Check_The_KeyBoard *);

(*----------------------------------------------------------------------*)
(*       Get_Modem7_File_Name --- Construct file name to MODEM7 form    *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Modem7_File_Name( VAR OK_File : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The filename for Modem7 is 11 characters long.  The filename  *)
(*        is left-justified and blank-filled in the first 8 characters. *)
(*        The extension appears left-justified and blank-filled in      *)
(*        positions 9 through 11.                                       *)
(*                                                                      *)
(*        Examples:                                                     *)
(*                                 12345678901                          *)
(*           'root.dat'  becomes:  root    dat                          *)
(*           'root'      becomes:  root                                 *)
(*                                                                      *)
(*        Note that the checksum INCLUDES the terminating Ctrl-z (SUB)  *)
(*        character of the file name.                                   *)
(*                                                                      *)
(*        In host mode, a check is made to ensure that the file to be   *)
(*        sent is on the transfer list.  If not, it is not sent.        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I: INTEGER;
   J: INTEGER;

BEGIN (* Get_Modem7_File_Name *)

   I             := 1;
   J             := 0;
   SFileName     := '           ';
   FileName      := '';

   WHILE( I <= LENGTH( File_Entry.Name ) ) DO
      BEGIN

         Ch := File_Entry.Name[I];

         IF Ch = '.' THEN
            J := 8
         ELSE
            BEGIN
               J            := J + 1;
               SFileName[J] := Ch;
            END;

         FileName := FileName + Ch;

         I  := I + 1;

      END;
                                   (* Get checksum *)
   CheckSum := 0;

   FOR I := 1 TO 11 DO
      CheckSum := ( CheckSum + ORD( SFileName[I] ) ) AND 255;

   CheckSum := ( CheckSum + SUB ) AND 255;

   OK_File := ( File_Entry.Attr AND
                ( VolumeID + Directory ) = 0 );

                                   (* If host mode, make sure file *)
                                   (* is on xferlist!              *)
   IF Host_Mode THEN
      IF ( Privilege <> 'S' ) THEN
         OK_File := OK_File AND ( Scan_Xfer_List( FileName ) > 0 );

END   (* Get_Modem7_File_Name *);

(*----------------------------------------------------------------------*)
(*             Wait_For_Nak --- Wait for NAK at start of file name      *)
(*----------------------------------------------------------------------*)

PROCEDURE Wait_For_Nak;

BEGIN (* Wait_For_Nak *)

   I := 0;
                                   (* Wait up to minute for NAK *)
   REPEAT
      Async_Receive_With_Timeout( One_Second , Int_Ch );
      Check_The_KeyBoard;
      I := I + 1;
   UNTIL ( Int_Ch  = NAK ) OR
         ( I      >= 60  ) OR
         Stop_Send;

   IF ( Int_Ch <> NAK ) THEN
      BEGIN
         Stop_Send := TRUE;
         WRITELN('   NAK for start of file name not received;');
         WRITELN('   Received Ascii ',Int_Ch,' instead.');
      END
   ELSE                            (* If NAK found, ACK it *)
      BEGIN
         Async_Send( CHR( ACK ) );
      END;
                                   (* Wait for com line to clear *)
   Async_Purge_Buffer;

END   (* Wait_For_Nak *);

(*----------------------------------------------------------------------*)
(*             Send_File_Name --- Send file name characters             *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_File_Name;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The file name characters are sent one at a time.  After       *)
(*        each is sent, we wait for an ACK.  To end the file name       *)
(*        we send an SUB (ctrl-z) character.                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I: INTEGER;
   J: INTEGER;

BEGIN (* Send_File_Name *)

   I := 0;

   WHILE( NOT Stop_Send ) AND ( I < 11 ) DO
      BEGIN

         I := I + 1;

         Async_Send( SFileName[I] );

         J := 0;

         REPEAT
            Async_Receive_With_Timeout( One_Second , Int_Ch );
            Check_The_KeyBoard;
            J := J + 1;
         UNTIL ( Int_Ch  = ACK ) OR
               ( J      >= 10  );

         Ack_OK := ( Int_Ch = ACK );

         Stop_Send := Stop_Send OR ( NOT Ack_OK );

      END;
                                   (* Send End of file name character *)
                                   (* and await receiver to send      *)
                                   (* checksum.                       *)
   IF NOT Stop_Send THEN
      BEGIN

         Async_Send( CHR( SUB ) );

         J := 0;

         REPEAT
            Async_Receive_With_Timeout( One_Second , Int_Ch );
            Check_The_KeyBoard;
            J := J + 1;
         UNTIL ( Int_Ch  = CheckSum ) OR
               ( J      >= 10  );

         IF ( Int_Ch <> CheckSum ) THEN
            BEGIN
               Stop_Send := TRUE;
               WRITELN('   Received checksum for filename not correct;');
               WRITELN('   Correct checksum = ',CheckSum,', received ',Int_Ch);
            END
         ELSE
            Async_Send( CHR( ACK ) );

      END;

END   (* Send_File_Name *);

(*----------------------------------------------------------------------*)
(*                Perform_Upload --- Do the upload                      *)
(*----------------------------------------------------------------------*)

PROCEDURE Perform_Upload;

BEGIN (* Perform_Upload *)

   IF Display_Status THEN
      WRITELN('  Uploading: ' + FileName );
   Write_Log('Uploading: ' + FileName , FALSE, FALSE );

   IF Transfer_Protocol = Telink THEN
      Make_Telink_Header( File_Entry );

   IF ( NOT Stop_Send ) THEN
      Send_Xmodem_File( Use_CRC );

   TextColor( Menu_Text_Color );
   TextBackGround( BLACK );

END   (* Perform_Upload *);

(*----------------------------------------------------------------------*)

BEGIN (* Send_Modem7_File *)
                                   (* Open batch transfer window    *)
   Display_Batch_Window;
                                   (* CRC except Modem7 Checksum *)

   Use_CRC     := Use_CRC AND ( Transfer_Protocol <> Modem7_Chk );

                                   (* Get file name pattern to send *)
   File_Pattern  := FileName;
                                   (* Pick up drive and path name    *)
   IF ( NOT Host_Mode ) THEN
      Extract_Upload_Path_Name( File_Pattern , Upload_Dir_Path );

                                   (* See if we can find anything to *)
                                   (* be sent.                       *)

   FindFirst( File_Pattern, AnyFile, File_Entry );

   Stop_Send    := ( DosError <> 0 );

   IF Stop_Send THEN
      WRITELN('  No files found to send.');

                                   (* Loop over file names         *)
   WHILE( NOT Stop_Send ) DO
      BEGIN
                                   (* Get file name *)

         Get_Modem7_File_Name( OK_File );

                                   (* If file can be sent, do it   *)
         IF OK_File THEN
            BEGIN
                                   (* Wait for NAK indicating host *)
                                   (* is ready for the file name.  *)
               IF NOT Stop_Send THEN
                  Wait_For_Nak;
                                   (* Send file name characters     *)
               IF NOT Stop_Send THEN
                  Send_File_Name;
                                   (* Send the file itself          *)
               IF NOT Stop_Send THEN
                  Perform_Upload;

            END;
                                   (* See if more files to transfer *)

         FindNext( File_Entry );

         Stop_Send := Stop_Send OR ( DosError <> 0 );

      END (* WHILE *);
                                   (* Send EOT to indicate no more files *)
   Async_Send( CHR( EOT ) );
                                   (* Wait for ACK                       *)

   Async_Receive_With_TimeOut( Five_Seconds , Int_Ch );

   TextColor( Menu_Text_Color );
   TextBackGround( BLACK );

   IF ( NOT Display_Status ) THEN
      Display_Batch_Window;

   IF ( Int_Ch = ACK ) THEN
      BEGIN
         WRITELN(' ');
         WRITELN('  Host system ACKnowledged EOT.');
         Write_Log('  Host system ACKnowledged EOT.', FALSE, FALSE);
      END;

   End_Batch_Transfer;

END   (* Send_Modem7_File *);
