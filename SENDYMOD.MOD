(*----------------------------------------------------------------------*)
(*        Send_Ymodem_File --- Uploads file with Ymodem or Sealink      *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Ymodem_File( Batch_Mode : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Send_Ymodem_File                                     *)
(*                                                                      *)
(*     Purpose:    Uploads files using Ymodem or SeaLink                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Send_Ymodem_File( Batch_Mode : BOOLEAN );                     *)
(*                                                                      *)
(*           Batch_Mode --- TRUE to send files using Ymodem batch,      *)
(*                          Else just one file using ordinary Ymodem.   *)
(*                                                                      *)
(*     Calls:   PibTerm_KeyPressed                                              *)
(*              Async_Send                                              *)
(*              Async_Receive_With_TimeOut                              *)
(*              RvsVideoOn                                              *)
(*              RvsVideoOff                                             *)
(*              Wait_For_Nak                                            *)
(*              Perform_Upload                                          *)
(*                                                                      *)
(*      Remarks:                                                        *)
(*                                                                      *)
(*         This routine performs wildcard directory searches and        *)
(*         implements the Ymodem batch file transfer protocol.          *)
(*                                                                      *)
(*         Note that the header constructed here contains the           *)
(*         file name, file size, and file creation time.                *)
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
(*          Make_Ymodem_Header --- Send special YMODEM header block     *)
(*----------------------------------------------------------------------*)

PROCEDURE Make_Ymodem_Header;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*       Procedure:  Make_Ymodem_Header                                 *)
(*                                                                      *)
(*       Purpose:    Makes special Ymodem header block                  *)
(*                                                                      *)
(*       Calling sequence:                                              *)
(*                                                                      *)
(*          Make_Ymodem_Header;                                         *)
(*                                                                      *)
(*       Calls:  None                                                   *)
(*                                                                      *)
(*       Remarks:                                                       *)
(*                                                                      *)
(*          This version of PibTerm DOES send the file creation time.   *)
(*                                                                      *)
(*          Format of Ymodem block:                                     *)
(*                                                                      *)
(*             Bytes         Contents                                   *)
(*             -----       ---------------------------------------      *)
(*                                                                      *)
(*               1           SOH                                        *)
(*               2             0                                        *)
(*               3           255                                        *)
(*              4-j          File name in lower case                    *)
(*            j+1-k          File size in bytes                         *)
(*            k+1-l          File creation time/date in Unix format     *)
(*            132-133        CRC of block                               *)
(*                                                                      *)
(*          The first three bytes are added later by the Xmodem send    *)
(*          routine.                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I            : INTEGER;
   J            : INTEGER;
   K            : INTEGER;
   L            : INTEGER;
   CRC          : INTEGER;
   ACK_Ok       : BOOLEAN;
   Int_Ch       : INTEGER;
   Fs1          : LONGINT;
   Fs2          : LONGINT;
   S_File_Size  : LONGINT;
   C_File_Size  : STRING[10];
   OK_File      : BOOLEAN;

   DTRec        : DateTime;

   Date         : LONGINT;
   OctD         : STRING[20];
   RemO         : LONGINT;
   Quot         : LONGINT;

   FullName     : AnyStr;

(*----------------------------------------------------------------------*)
(*              LowerCase --- convert character to lower case           *)
(*----------------------------------------------------------------------*)

FUNCTION LowerCase( C: CHAR ): CHAR;

BEGIN (* LowerCase *)

   IF ( C IN ['A'..'Z'] ) THEN
      LowerCase := CHR( ORD( C ) + 32 )
   ELSE
      LowerCase := C;

END   (* LowerCase *);

(*----------------------------------------------------------------------*)

BEGIN (* Make_Ymodem_Header *)
                                   (* Zero out block *)
   FOR I := 1 TO 130 DO
      Sector_Data[I] := 0;
                                   (* File name      *)
   CASE Use_Full_Path_Name OF
      TRUE : Add_Path( FileName, Upload_Dir_Path, FullName );
      FALSE: FullName := FileName;
   END (* CASE *);

   L := LENGTH( FullName );

   FOR I := 1 TO L DO
      Sector_Data[I] := ORD( LowerCase(FullName[I]) );

                                   (* File size in Ascii *)

   STR( File_Entry.Size , C_File_Size );

                                   (* Insert file size in block *)
   I      := L + 2;

   FOR K := 1 TO LENGTH( C_File_Size ) DO
     BEGIN
        Sector_Data[I] := ORD( C_File_Size[K] );
        I              := I + 1;
     END;
                                   (* Get file date and time *)

   UnPackTime( File_Entry.Time , DTRec );

                                   (* Convert DOS time and date to *)
                                   (* number of seconds since      *)
                                   (* January 1, 1970.             *)

   WITH DTRec DO
      Set_Unix_Style_Date( Date, Year, Month, Day, Hour, Min, Sec );

                                   (* Convert date to octal string *)
   OctD := '';

   REPEAT

      Quot := Date DIV 8;
      Remo := Date - 8 * Quot;

      OctD := CHR( TRUNC( Remo ) + ORD( '0' ) ) + OctD;

      Date := Quot;

   UNTIL( Date <= 0 );
                                   (* Insert octal date into Ymodem block *)
   Sector_Data[I] := ORD(' ');

   FOR K := 1 TO LENGTH( OctD ) DO
      BEGIN
         I              := I + 1;
         Sector_Data[I] := ORD(OctD[K]);
      END;

END   (* Make_Ymodem_Header *);

{====================
(*----------------------------------------------------------------------*)
(*          Make_SEALink_Header --- Make special SEALink header block   *)
(*----------------------------------------------------------------------*)

PROCEDURE Make_SEALink_Header( File_Entry : SearchRec );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*       Procedure:  Make_SEALink_Header                                *)
(*                                                                      *)
(*       Purpose:    Makes special SEALink header block                 *)
(*                                                                      *)
(*       Calling sequence:                                              *)
(*                                                                      *)
(*          Make_SEALink_Header( File_Entry : SearchRec );              *)
(*                                                                      *)
(*       Calls:  None                                                   *)
(*                                                                      *)
(*          Format of SEALink block 0:                                  *)
(*                                                                      *)
(*             Bytes         Contents                                   *)
(*             -----       ---------------------------------------      *)
(*                                                                      *)
(*               1           SOH                                        *)
(*               2             0                                        *)
(*               3           255                                        *)
(*              4-7          File size in bytes (4-byte integer)        *)
(*              8-11         Creation time/date in seconds since        *)
(*                           January 1, 1970 (4-byte integer)           *)
(*             12-27         Name of file in 'name.ext' form            *)
(*              28           Version number (always zero here)          *)
(*             29-43         PIBTERM  -- sending program's name         *)
(*              44           Overdrive flag.                            *)
(*             45-131        All zeroes                                 *)
(*            132-133        CRC of block                               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I            : INTEGER;
   J            : INTEGER;
   L            : INTEGER;
   CheckSum     : INTEGER;
   ACK_Ok       : BOOLEAN;
   Int_Ch       : INTEGER;
   DTRec        : DateTime;
   C            : STRING[1];

   Date         : LONGINT;

BEGIN (* Make_SEALink_Header *)
                                   (* Zero out block *)

   FillChar( Sector_Data[1], 130, 0 );

                                   (* File size in 32-bit MS DOS form *)

   MOVE( File_Entry.Size , Sector_Data[1], 4 );

                                   (* Creation time/date in UNIX form *)

   UnPackTime( File_Entry.Time , DTRec );

                                   (* Convert DOS time and date to *)
                                   (* number of seconds since      *)
                                   (* January 1, 1970.             *)

   WITH DTRec DO
      Set_Unix_Style_Date( Date, Year, Month, Day, Hour, Min, Sec );

                                   (* Insert date into sector data *)

   MOVE( Date, Sector_Data[5], 4 );

                                   (* File name *)
   J := 1;

   FOR I := 1 TO LENGTH( File_Entry.Name ) DO
      BEGIN
         Sector_Data[J+8] := ORD( File_Entry.Name[J] );
         J                := SUCC( J );
      END;

   FOR I := J TO 16 DO
      Sector_Data[I+8] := ORD(' ');

                                   (* Sending program's name *)
   FOR I := 1 TO 15 DO
      BEGIN
         C                 := COPY( 'PIBTERM        ', I, 1 );
         Sector_Data[I+25] := ORD( C[1] );
      END;

END   (* Make_SEALink_Header *);
===========}

(*----------------------------------------------------------------------*)
(*          Get_Ymodem_File_Name  --- get file name for upload          *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Ymodem_File_Name( VAR OK_File : BOOLEAN );

VAR
   I : INTEGER;

BEGIN (* Get_Ymodem_File_Name *)

   FileName := File_Entry.Name;

   OK_File := ( File_Entry.Attr AND
                ( VolumeID + Directory ) = 0 );

                                   (* If host mode, make sure file *)
                                   (* is on xferlist!              *)
   IF Host_Mode THEN
      IF ( Privilege <> 'S' ) THEN
         OK_File := OK_File AND ( Scan_Xfer_List( FileName ) > 0 );

END   (* Get_Ymodem_File_Name *);

(*----------------------------------------------------------------------*)
(*                Perform_Upload --- Do the upload                      *)
(*----------------------------------------------------------------------*)

PROCEDURE Perform_Upload;

BEGIN (* Perform_Upload *)

   IF Batch_Mode THEN
      BEGIN
         IF Display_Status THEN
            WRITELN('  Uploading: ' + FileName);
         Write_Log('  Uploading: ' + FileName , FALSE, FALSE );
      END;

   Send_Xmodem_File( TRUE );

   IF Batch_Mode THEN
      BEGIN
         TextColor( Menu_Text_Color );
         TextBackGround( BLACK );
      END;

END   (* Perform_Upload *);

(*----------------------------------------------------------------------*)
(*  Send_Null_File_Name --- Send null file name to stop batch transfer  *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Null_File_Name;

VAR
   I: INTEGER;

BEGIN (* Send_Null_File_Name *)
                                   (* Purge reception *)
   REPEAT
      Async_Receive_With_Timeout( One_Second , Int_Ch );
   UNTIL ( Int_Ch = TimeOut );

                                   (* Send null file name block 0 *)
   Async_Send( CHR( SOH ) );
   Async_Send( CHR(   0 ) );
   Async_Send( CHR( 255 ) );

   FOR I := 1 TO 130 DO
      Async_Send( CHR( 0 ) );

   IF ( NOT Display_Status ) THEN
      Display_Batch_Window;

   TextColor( Menu_Text_Color );
   TextBackGround( BLACK );

   WRITELN(' ');
   WRITELN('  Sending null file name to terminate batch transfer ...');
   Write_Log('Sending null file name to terminate batch transfer.', FALSE, FALSE);

                                   (* Wait for ACK                    *)

   Async_Receive_With_TimeOut( Ten_Seconds , Int_Ch );

   IF ( Int_Ch = ACK ) THEN
      BEGIN
         WRITELN;
         WRITELN('  Host system ACKnowledged end of batch.');
         Write_Log('Host system ACKnowledged end of batch.', TRUE, FALSE);
      END;

END   (* Send_Null_File_Name *);

(*----------------------------------------------------------------------*)

BEGIN (* Send_Ymodem_File *)
                                   (* Open batch transfer window    *)
   IF ( Batch_Mode ) THEN
      Display_Batch_Window;
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
      IF Batch_Mode THEN
         BEGIN
            WRITELN('  No files found to send.');
            Write_Log('No files found to send.' , FALSE, FALSE );
         END;

                                   (* Loop over file names         *)
   WHILE( NOT Stop_Send ) DO
      BEGIN
                                   (* Get file name *)

         Get_Ymodem_File_Name( OK_File );

                                   (* Get Ymodem header block       *)
         IF OK_File THEN
            BEGIN

               IF ( NOT Stop_Send ) THEN
{
                  IF ( Transfer_Protocol = SeaLink ) THEN
                     Make_SEAlink_Header( File_Entry )
                  ELSE
}
                     IF ( Batch_Mode OR Use_Ymodem_Header ) THEN
                        Make_Ymodem_Header;

                                   (* Send the file itself          *)

               IF ( NOT Stop_Send ) THEN
                  Perform_Upload;

            END;
                                  (* See if more files to transfer *)

         FindNext( File_Entry );

         Stop_Send := Stop_Send OR ( NOT Batch_Mode ) OR
                      ( DosError <> 0 );

      END (* WHILE *);
                                   (* Send null file name to indicate *)
                                   (* no more files                   *)
   IF Batch_Mode THEN
      BEGIN
                                   (* Send null file name to stop transfer *)
         Send_Null_File_Name;

         End_Batch_Transfer;

      END;
                                   (* Restore colors *)
   Reset_Global_Colors;

END   (* Send_Ymodem_File *);
