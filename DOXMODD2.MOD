
BEGIN (* Do_Xmodem_Download *)
                                   (* Remember protocol type    *)

   Transfer_Protocol := Trans_Protocol;

                                   (* Save current comm parms and *)
                                   (* reset for Xmodem            *)
   Save_Comm_For_Xmodem;
                                   (* Indicate files being received *)
   Sending_Files := FALSE;
                                   (* Perform transfer          *)
   CASE Transfer_Protocol Of

      Xmodem_Chk:     Receive_Xmodem_File( FALSE );

      Modem7_CRC,
      Telink:         Receive_Modem7_File( TRUE );

      Modem7_Chk:     Receive_Modem7_File( FALSE );

{     SeaLink, }
      Ymodem_G,
      Ymodem_Batch:   Receive_Ymodem_File;

      Xmodem_1K,
      Xmodem_1KG,
{     WXmodem, }
      Xmodem_Crc:     Receive_Xmodem_File( TRUE );

      ELSE ;

   END  (* CASE *);
                                   (* Reset comm parms back *)
   Restore_Comm_For_Xmodem;

END   (* Do_Xmodem_DownLoad *);
