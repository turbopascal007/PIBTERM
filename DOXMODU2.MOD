BEGIN (* Do_Xmodem_Upload *)
                                   (* Remember protocol type    *)

   Transfer_Protocol := Trans_Protocol;

                                   (* Save comm parms and reset *)
                                   (* for Xmodem                *)
   Save_Comm_For_Xmodem;
                                   (* Indicate file being sent *)
   Sending_Files := TRUE;
                                   (* Perform transfer *)
   CASE Transfer_Protocol OF

      Xmodem_Chk   : Send_Xmodem_File( FALSE );

{     WXmodem, }
      Xmodem_CRC   : Send_Xmodem_File( TRUE  );

      Telink,
      Modem7_CRC   : Send_Modem7_File( TRUE  );

      Modem7_Chk   : Send_Modem7_File( FALSE );

{     SeaLink, }
      Ymodem_G,
      Ymodem_Batch : Send_Ymodem_File( TRUE  );

      Xmodem_1K,
      Xmodem_1KG   : Send_Ymodem_File( FALSE );

      ELSE ;

   END  (* Case *);
                                   (* Reset comm parms to saved values *)
   Restore_Comm_For_Xmodem;

END   (* Do_Xmodem_Upload *);
