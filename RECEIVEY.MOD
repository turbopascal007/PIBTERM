(*----------------------------------------------------------------------*)
(*          Receive_Ymodem_File --- Download files with Ymodem/SeaLink  *)
(*----------------------------------------------------------------------*)

PROCEDURE Receive_Ymodem_File;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Receive_Ymodem_File                                  *)
(*                                                                      *)
(*     Purpose:    Downloads file to PC using Ymodem batch or SeaLink   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Receive_Ymodem_File;                                          *)
(*                                                                      *)
(*     Calls:   Receive_Xmodem_File                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Receive_Ymodem_File *)
                                   (* Open display window for transfers  *)
   Display_Batch_Window;
                                   (* Flags if keyboard halt or    *)
                                   (* null file name encountered   *)
   Stop_Receive   := FALSE;
   Null_File_Name := FALSE;
                                   (* Loop until null file name    *)

   WHILE ( ( NOT Stop_Receive ) AND ( NOT Null_File_Name ) ) DO
      BEGIN
         FileName := '';
         Receive_Xmodem_File( TRUE );
         TextColor     ( Menu_Text_Color );
         TextBackGround( BLACK );
         IF ( ( NOT Null_File_Name ) AND ( NOT Stop_Receive ) ) THEN
            BEGIN
               IF Display_Status THEN
                  WRITELN  ('  Received file: ' + FileName );
               Write_Log('Received file: ' + FileName , FALSE, FALSE );
            END;
      END;
                                   (* Restore batch window if needed *)
   TextColor     ( Menu_Text_Color );
   TextBackGround( BLACK );

   IF ( NOT Display_Status ) THEN
      Display_Batch_Window;
                                   (* Acknowledge null file name *)
                                   (* if received                *)
   IF Null_File_Name THEN
      BEGIN
         TextColor     ( Menu_Text_Color );
         TextBackGround( BLACK );
         Write_Log('Received null file name from host.', FALSE, FALSE);
         WRITELN( ' ' );
         WRITELN( '  Received null file name from host.' );
      END;

   End_Batch_Transfer;

END   (* Receive_Ymodem_File *);
