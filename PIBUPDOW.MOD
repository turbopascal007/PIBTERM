(*----------------------------------------------------------------------*)
(*           PibUpDown --- Control routine for uploads/downloads        *)
(*----------------------------------------------------------------------*)

PROCEDURE PibUpDown( Transfer_Protocol  : Transfer_Type;
                     Transfer_Direction : CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  PibUpDown                                            *)
(*                                                                      *)
(*     Purpose:    Controls uploading of files to remote hosts.         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        PibUpDown( Transfer_Protocol  : Transfer_Type;                *)
(*                   Transfer_Direction : CHAR );                       *)
(*                                                                      *)
(*           Transfer_Protocol  --- type of transfer to do              *)
(*           Transfer_Direction --- direction of transfer               *)
(*                                  'R' = receive                       *)
(*                                  'S' = send                          *)
(*                                                                      *)
(*      Calls:   MyLoadOverLay                                          *)
(*               Get_Upload_Protocol                                    *)
(*               Get_Download_Protocol                                  *)
(*               Send_Ascii_File                                        *)
(*               Do_Xmodem_Upload                                       *)
(*               Do_Kermit                                              *)
(*               Receive_Ascii_File                                     *)
(*               Receive_Xmodem_File                                    *)
(*               Transfer_Through_Batch_File                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Save_Close : BOOLEAN;
   I          : INTEGER;
   TName      : String12;

BEGIN (* PibUpDown *)
                                   (* Use file time provided by sender *)
                                   (* by default.                      *)
   Use_Time_Sent   := TRUE;
                                   (* Get protocol for transfer   *)

   IF ( Transfer_Protocol = None ) THEN
      CASE Transfer_Direction OF
         'R': Transfer_Protocol := Get_Download_Protocol;
         'S': Transfer_Protocol := Get_Upload_Protocol;
      END (* CASE *);
                                   (* Reset default transfer type *)

   IF ( Transfer_Protocol <> None ) THEN
      Default_Transfer_Type := Transfer_Protocol;

                                   (* No batch window to start  *)
   Batch_Screen_Ptr := NIL;
                                   (* Display transfer status   *)
   Display_Status := TRUE;
                                   (* No upload path yet        *)
   IF ( NOT Host_Mode ) THEN
      Upload_Dir_Path := '';
                                   (* Get script name for transfer if any *)
   CASE Transfer_Direction OF
      'R': TName := Receive_Script_Names[Transfer_Protocol];
      'S': TName := Send_Script_Names[Transfer_Protocol];
   END (* CASE *);
                                   (* If script defined, then ... *)
   IF ( LENGTH( TName ) > 0 ) THEN
      IF ( POS( '.BAT', TName ) = 0 ) THEN

         BEGIN                     (* ... do transfer via script, else *)
            Save_Close         := Close_Comm_For_Dos;
            Close_Comm_For_Dos := TRUE;
            Process_Script( TName , 'E' );
            Close_Comm_For_Dos := Save_Close;
         END
      ELSE
                                   (* ... if .BAT in script name, then *)
                                   (* transfer via batch file          *)

         Transfer_Through_Batch_File( Transfer_Protocol ,
                                      TName , Transfer_Direction )

   ELSE
      BEGIN                        (* Else do transfer via built-in code *)

         CASE Transfer_Protocol OF

            Ascii        : CASE Transfer_Direction OF
                              'R': Receive_Ascii_File;
                              'S': Send_Ascii_File;
                           END (* CASE *);

            Ymodem_Batch,
            Ymodem_G,
            Xmodem_1K,
            Xmodem_1KG,
            Xmodem_Crc,
            Xmodem_Chk,
            Modem7_CRC,
            Telink,
            Modem7_Chk:    CASE Transfer_Direction OF
                              'R': Do_Xmodem_Download( Transfer_Protocol );
                              'S': Do_Xmodem_Upload  ( Transfer_Protocol );
                           END (* CASE *);

            Kermit:        Do_Kermit( Transfer_Direction );

            ELSE ;

         END  (* CASE *);
                                   (* Indicate end of transfer *)

         Signal_End_Of_Transfer( Transfer_Protocol );

      END;

END   (* PibUpDown *);
