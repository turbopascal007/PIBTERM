(*----------------------------------------------------------------------*)
(*       Receive_Modem7_File --- Download file with Modem7/Telink       *)
(*----------------------------------------------------------------------*)

PROCEDURE Receive_Modem7_File( Use_CRC: BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Receive_Modem7_File                                  *)
(*                                                                      *)
(*     Purpose:    Downloads file to PC using Modem7/Telink batch       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Receive_Modem7_File( Use_CRC : BOOLEAN);                      *)
(*                                                                      *)
(*           Use_CRC --- TRUE to use CRC checking;                      *)
(*                       FALSE to use checksum checking.                *)
(*                                                                      *)
(*     Calls:   PibTerm_KeyPressed                                              *)
(*              Async_Send                                              *)
(*              Async_Receive                                           *)
(*              Receive_Xmodem_File                                     *)
(*                                                                      *)
(*      Remarks:                                                        *)
(*                                                                      *)
(*         This routine performs the "echo file name" function of       *)
(*         Modem7, required by batch Modem7 and Telink.                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   MaxTry     = 10;
   MaxNoise   = 5;

VAR
   RFileName   : AnyStr;
   Int_Ch      : INTEGER;
   Int_Ch_Save : INTEGER;
   Ch          : CHAR;
   CheckSum    : INTEGER;
   EndFName    : BOOLEAN;
   I           : INTEGER;
   Tries       : INTEGER;
   NTries      : INTEGER;
   J           : INTEGER;

(*----------------------------------------------------------------------*)
(*              Check_The_KeyBoard --- Check for keyboard input         *)
(*----------------------------------------------------------------------*)

PROCEDURE Check_The_KeyBoard;

BEGIN (* Check_The_KeyBoard *)

   Check_KeyBoard;

   IF Stop_Receive THEN
      BEGIN
         IF ( NOT Display_Status ) THEN
            Display_Batch_Window;
         WRITELN('  Alt_R pressed, transfer cancelled.');
      END;

END   (* Check_The_KeyBoard *);

(*----------------------------------------------------------------------*)

BEGIN (* Receive_Modem7_File *)
                                   (* Open display window for transfers  *)
   Display_Batch_Window;
                                   (* CRC except Modem7 Checksum *)

   Use_CRC     := Use_CRC AND ( Transfer_Protocol <> Modem7_Chk );

                                   (* Flag if keyboard halt or EOT *)
                                   (* encountered                  *)
   Stop_Receive := FALSE;
                                   (* Purge reception to remove noise  *)
   Async_Purge_Buffer;
                                   (* Counts initial attempts to get stuff *)
   Tries := 0;
                                   (* Loop over file names         *)
   REPEAT
                                   (* Initialize checksum          *)
      CheckSum := 0;
                                   (* Initialize file name         *)
      RFileName := '';
                                   (* Try up to MaxTry times to    *)
                                   (* send NAK to say we're ready  *)
                                   (* for the file name.           *)
      REPEAT
                                   (* Send NAK                         *)
         Async_Send( CHR( NAK ) );

                                   (* Get response -- should be ACK    *)
                                   (* NOTE:  skip up to MaxNoise chars *)
                                   (*        that are clearly garbage  *)
                                   (*        in effort to get ACK      *)
         NTries := 0;

         REPEAT
            Async_Receive_With_TimeOut( One_Second , Int_Ch );
            NTries := NTries + 1;
            Check_Keyboard;
         UNTIL ( Ntries > MaxNoise ) OR
               ( Int_Ch <= 127     ) OR
               Stop_Receive;

         Tries := Tries + 1;

      UNTIL( Int_Ch = ACK ) OR
           ( Int_Ch = CAN ) OR
           ( Int_Ch = EOT ) OR
           ( Tries >= MaxTry ) OR
           Stop_Receive;
                                   (* Only continue if ACK found      *)

      Stop_Receive := ( Int_Ch <> ACK ) OR Stop_Receive;
      Int_Ch_Save  := Int_Ch;

                                   (* Pick up characters of file name *)
      IF ( NOT Stop_Receive ) THEN
         REPEAT

            NTries    := 0;

            REPEAT
               Async_Receive_With_TimeOut( One_Second , Int_Ch );
               Check_The_KeyBoard;
               NTries := NTries + 1;
            UNTIL ( Int_Ch <> TimeOut ) OR
                  ( NTries >= MaxTry  ) OR
                  Stop_Receive;

            EndFName := ( Int_Ch = CAN     ) OR
                        ( Int_Ch = EOT     ) OR
                        ( Int_Ch = TimeOut ) OR
                        ( Int_Ch = SUB     ) OR
                        Stop_Receive;

            IF ( NOT EndFname ) THEN
               BEGIN
                  Async_Send( CHR( ACK ) );       (* echo 1 char at a time *)
                  RFileName := RFileName + CHR( Int_Ch );
                  Checksum  := ( Checksum + Int_Ch ) AND 255;
               END;

         UNTIL EndFname
      ELSE
         Int_Ch  := TimeOut;

                                   (* Finished getting filename. *)
      IF ( Int_Ch = SUB ) THEN
         BEGIN  (* Filename received *)

                                   (* Send checksum *)

            CheckSum := ( CheckSum + Int_Ch ) AND 255;
            Async_Send( CHR( CheckSum ) );

                                   (* Get response to checksum *)
            NTries := 0;

            REPEAT
               Async_Receive_With_TimeOut( One_Second , Int_Ch );
               Check_The_KeyBoard;
               NTries := NTries + 1;
            UNTIL ( Int_Ch = ACK ) OR ( NTries >= MaxTry );

                                   (* If checksum OK, do transfer *)

            IF ( Int_Ch = ACK ) AND ( NOT Stop_Receive ) THEN
               BEGIN

                  FOR  I := LENGTH( RFileName ) TO 11 DO
                     RFileName := RFileName + ' ';

                  FileName := Trim( COPY( RFileName, 1, 8 ) );

                  IF COPY( RfileName, 9, 3 ) <> '   ' THEN
                     FileName := FileName + '.' + COPY( RFileName, 9, 3 );

                                   (* Prevent overwrite of host mode *)
                                   (* files.                         *)

                  IF Host_Mode THEN
                     IF ( Privilege <> 'S' ) THEN
                        Stop_Receive := Stop_Receive OR
                                        Check_If_File_Exists( FileName ,
                                                              Download_Dir_Path );

                                    (* Get the file. *)

                  IF ( NOT Stop_Receive ) THEN
                     BEGIN

                        IF Display_Status THEN
                           WRITELN('   Downloading: ' + FileName );

                        Write_Log( 'Downloading: ' + FileName , FALSE , FALSE );

                        Receive_Xmodem_File( Use_CRC );

                        TextColor     ( Menu_Text_Color );
                        TextBackGround( BLACK );

                     END;

               END
            ELSE
               Stop_Receive := TRUE;

         END  (* Filename received *)
      ELSE
         Stop_Receive := TRUE;

   UNTIL Stop_Receive;
                                   (* Restore batch window if needed *)
   IF ( NOT Display_Status ) THEN
      Display_Batch_Window;

   TextColor     ( Menu_Text_Color );
   TextBackGround( BLACK );
                                   (* Acknowledge EOT if received *)
   IF ( Int_Ch_Save = EOT ) THEN
      BEGIN

         Async_Send( CHR( ACK ) );

         Write_Log( 'Received EOT from host.' , FALSE , FALSE );

         WRITELN( ' ' );
         WRITELN( '  Received EOT from host.' );

      END
   ELSE
      BEGIN

         Write_Log( 'Transfer cancelled.' , FALSE , FALSE );

         WRITELN( ' ' );
         WRITELN( '  Transfer cancelled.' );

      END;

   End_Batch_Transfer;

END   (* Receive_Modem7_File *);
