
(*----------------------------------------------------------------------*)

BEGIN  (* Receive_Xmodem_File *)
                                   (* Remember CRC checking *)
   CRC_Used      := Use_CRC;
                                   (* Pick up file name for title *)
   XFile_Name    := FileName;
                                   (* Get title for transfer *)
   Get_Xmodem_Titles;
                                   (* Initialize status display information *)
   SOH_Errors     := 0;
   BlockL_Errors  := 0;
   BlockN_Errors  := 0;
   Comple_Errors  := 0;
   TimeOut_Errors := 0;
   Resend_Errors  := 0;
   CRC_Errors     := 0;
   Display_Time   := FALSE;
   Dup_Block      := FALSE;
   G_Failure      := FALSE;

   Initialize_Receive_Display;
                                   (* Current sector = 0 *)
   Sector_Number  := 0;
   Sector_Count   := 0;
   Sector_Prev    := 0;
   Sector_Length  := 128;
                                   (* Overall error count = 0 *)
   Error_Count    := 0;
                                   (* CRC, WXModem tries *)
   CRC_Tries      := 0;
   WXM_Tries      := 0;
                                   (* How long to wait for SOH *)

   SOH_Time       := Xmodem_Block_Wait;

                                   (* Assume file size not sent *)
   Truncate_File  := FALSE;
                                   (* Assume file size, date not sent *)
   RFile_Size     := 0;
   RFile_Size_2   := 0;
   RFile_Date     := 0;
   File_Date      := 0;
   File_Time      := 0;
                                   (* Figure if ACKs to be handled *)

   Do_ACKs        := ( Transfer_Protocol <> Ymodem_G   ) AND
                     ( Transfer_Protocol <> Xmodem_1KG );

                                   (* Note if WXModem or SeaLink used *)
{
   Do_WXmodem     := ( Transfer_Protocol = WXModem );
   Do_SeaLink     := ( Transfer_Protocol = SeaLink );
}
   Do_WXmodem     := FALSE;
   Do_SeaLink     := FALSE;
                                   (* Assume file name not sent *)
   RFile_Name     := '';
                                   (* Assume transfer fails *)
   OK_Transfer    := FALSE;
                                   (* Assume block 0 not found *)
   Block_Zero     := FALSE;
                                   (* Starting time  *)
   Start_Time     := TimeOfDay;
                                   (* User intervention flag *)
   Alt_R_Pressed  := FALSE;
                                   (* Serious error flag     *)
   Stop_Receive   := FALSE;
                                   (* Not null file name   *)
   Null_File_Name := FALSE;
                                   (* Allocate buffer if requested   *)
                                   (* otherwise use sector data area *)
                                   (* directly.                      *)

   IF ( Max_Write_Buffer > 1024 ) AND
      ( Max_Write_Buffer < MaxAvail ) THEN
      BEGIN
         Buffer_Length  := ( ( MIN( Max_Write_Buffer , 31744 ) +
                               1023 ) SHR 10 ) SHL 10;
         Long_Buffer    := TRUE;
         GetMem( Write_Buffer , Buffer_Length );
         IF ( Write_Buffer = NIL ) THEN
            BEGIN
               Long_Buffer   := FALSE;
               Buffer_Length := 1024;
               Write_Buffer  := ADDR( Sector_Data );
            END;
      END
   ELSE
      BEGIN
         Long_Buffer   := FALSE;
         Buffer_Length := 1024;
         Write_Buffer  := ADDR( Sector_Data );
      END;
                                   (* Determine block starter characters *)

   Block_Start_Set := [ ^A, ^B, ^D, ^V, ^X ];

                                   (* No blocks being flushed currently  *)
   Flush_Count    := 0;
                                   (* Empty write buffer   *)
   Buffer_Pos     := 0;
                                   (* Open reception file now if possible *)
   RFile_Open     := FALSE;

   IF FileName <> '' THEN
      BEGIN
         Open_Receiving_File;
         IF Stop_Receive THEN
            BEGIN
               Cancel_Transfer;
               Window_Delay;
               Restore_Screen_And_Colors( Saved_Screen );
               EXIT;
            END;
      END;
                                   (* Save Xon/Xoff status *)

   Save_XonXoff     := Async_Do_XonXoff;
   Async_Do_XonXoff := Do_WXModem;

   Save_XonOV       := Async_OV_XonXoff;
   Async_OV_XonXoff := Do_WXModem OR ( NOT Do_Acks );

                                   (* Begin XMODEM loop    *)
   REPEAT
                                   (* Reset error flag *)
      Error_Flag := FALSE;
      Dup_Block  := FALSE;
                                   (* Look for SOH     *)
      REPEAT

         IF ( ( Sector_Count = 0 ) AND ( WXM_Tries = 0 ) ) THEN
            BEGIN  (* Initial handshake *)

               CRC_Used   := CRC_Used   AND ( CRC_Tries < 4 );
               Do_WXModem := Do_WXModem AND ( WXM_Tries < 4 );

                                   (* Purge reception      *)
               Async_Purge_Buffer;

                                   (* Indicate XMODEM type *)
               IF Do_WXModem THEN
                  BEGIN
                     Async_Send( 'W' );
                     INC( WXM_Tries );
                  END
               ELSE
                  BEGIN
                     IF ( NOT Do_ACKs ) THEN
                        Async_Send( 'G' )
                     ELSE
                        IF CRC_Used THEN
                           BEGIN
                              Async_Send( 'C' );
                           END
                        ELSE
                           BEGIN
                              Async_Send( CHR( NAK ) );
                           END;
                     INC( CRC_Tries );
                     IF Do_Sealink THEN
                        BEGIN
                           Async_Send( CHR( 1   ) );
                           Async_Send( CHR( 254 ) );
                        END;
                  END;

               IF Display_Status THEN
                  BEGIN

                     GoToXY( 1 , 8 );

                     TextColor( Menu_Text_Color_2 );

                     IF ( NOT CRC_Used ) THEN
                        WRITELN(' Checksum errors      :')
                     ELSE
                        WRITELN(' CRC errors           :');

                     TextColor( Menu_Text_Color );

                  END;

            END   (* Initial handshake *);

         Wait_For_SOH( SOH_Time, Initial_Ch , Stop_Receive );

                                   (* If CAN found, insist on    *)
                                   (* at least two CANs in a row *)
                                   (* before cancelling transfer *)

         IF ( Initial_Ch = CAN ) THEN
            Wait_For_SOH( SOH_Time, Initial_Ch , Stop_Receive )

                                   (* If EOT and windowing, insist *)
                                   (* on at least two EOTs in a    *)
                                   (* row before halting.          *)

         ELSE IF ( ( Initial_Ch = EOT ) AND
                   ( Do_WXModem OR
                     ( Do_SeaLink AND ( Sector_Count > 0 ) ) ) ) THEN
            BEGIN
               Async_Send( CHR( NAK ) );
               Wait_For_SOH( SOH_Time, Initial_Ch , Stop_Receive )
            END
         ELSE IF ( Initial_Ch = TimeOut ) THEN
            BEGIN
               IF ( Sector_Count > 0 ) THEN
                  Async_Send( CHR( NAK ) );
               Display_Receive_Error( 'Time out, no SOH');
               INC( TimeOut_Errors );
            END;
                                   (* If WXmodem, leave Xon/Xoff on *)

         Async_Do_XonXoff := Do_WXModem;

                                   (* Update status display       *)
         IF Display_Status THEN
            Update_Xmodem_Receive_Display;

                                   (* Update status line *)
         IF Do_Status_Line THEN
            BEGIN
               Set_Status_Line_Name( Short_Terminal_Name );
               Write_To_Status_Line( Status_Line_Name, 1 );
            END;

      UNTIL ( Initial_Ch = SOH                ) OR
            ( Initial_Ch = EOT                ) OR
            ( Initial_Ch = CAN                ) OR
            ( Initial_Ch = SYN                ) OR
            ( Initial_Ch = STX                ) OR
            ( Error_Count > Xmodem_Max_Errors ) OR
            ( Stop_Receive                    );

                                   (* Something wrong already -- *)
                                   (* cancel the transfer.       *)
      IF Stop_Receive THEN
         BEGIN
            IF NOT Async_Carrier_Detect THEN
               BEGIN
                  Display_Receive_Error('Carrier dropped');
                  Window_Delay;
               END;
         END
                                   (* Timed out -- no SOH found *)

      ELSE IF Initial_Ch = TimeOut THEN
         BEGIN
            Display_Receive_Error( 'Time out, no SOH');
            INC( TimeOut_Errors );
         END
                                   (* SYN found -- possible Telink block *)
                                   (*              or WXModem start      *)

      ELSE IF ( ( Initial_Ch = SYN ) AND Do_WXModem ) THEN
         (* Do nothing and skip SYN *)

                                   (* SOH found -- start of XMODEM block *)
                                   (* STX found -- start of Ymodem block *)
                                   (* SYN found -- start of Telink block *)

      ELSE IF ( Initial_Ch = SOH ) OR
              ( Initial_Ch = SYN ) OR
              ( Initial_Ch = STX ) THEN
         BEGIN (* SOH found *)
                                   (* Pick up sector number *)

            IF Initial_Ch = STX THEN
               Sector_Length := 1024
            ELSE
               Sector_Length := 128;

            IF Do_WXModem THEN
               WXModem_Receive_With_TimeOut( Ch )
            ELSE
               Async_Receive_With_TimeOut( Xmodem_Char_Wait , Ch );

            IF Ch = TimeOut THEN
               BEGIN
                  INC( BlockL_Errors );
                  Display_Receive_Error('Short block');
               END;

            Sector_Number := Ch;

                                   (* Complement of sector number *)

            IF Do_WXModem THEN
               WXModem_Receive_With_TimeOut( Ch )
            ELSE
               Async_Receive_With_TimeOut( Xmodem_Char_Wait , Ch );

            IF Ch = TimeOut THEN
               BEGIN
                  INC( BlockL_Errors );
                  Display_Receive_Error('Short block');
               END;

            Sector_Comp := Ch;

                                   (* See if they add up properly     *)

            IF ( ( Sector_Number + Sector_Comp ) = 255 ) THEN

               BEGIN  (* Sector number and complement match *)

                  Sector_Prev1 := SUCC( Sector_Prev );

                  Block_Zero   := ( Sector_Count  = 0 ) AND
                                  ( Sector_Number = 0 ) AND
                                  ( ( Initial_Ch  = SYN ) OR
                                    ( Transfer_Protocol IN [Xmodem_1K,
                                                            Xmodem_1KG,
                                                            Ymodem_G,
                                                            Ymodem_Batch
                                                            {,SeaLink}] ) );

                  CRC_Used_2 := CRC_Used AND
                               ( NOT ( Block_Zero AND
                                       ( Transfer_Protocol = Telink ) ) );

                  IF ( Sector_Number = Sector_Prev1 ) OR Block_Zero THEN
                     BEGIN  (* Correct sector found *)

                        IF Receive_Xmodem_Sector( CRC_Used_2 ) THEN
                           IF ( NOT Block_Zero ) THEN
                              BEGIN (* Checksum/CRC OK *)

                                 Write_File_Data;

                                 IF ( NOT Stop_Receive ) THEN
                                    BEGIN

                                       Error_Count  := 0;

                                       Sector_Count := Sector_Count +
                                                       ( Sector_Length SHR 7 );

                                       Sector_Prev := Sector_Number;

                                       IF Do_ACKs THEN
                                          BEGIN
                                             Async_Send( CHR( ACK ) );
                                             IF Do_WXModem THEN
                                                Async_Send( CHR( Sector_Number AND 3 ) )
                                             ELSE IF Do_SeaLink THEN
                                                BEGIN
                                                   Async_Send( CHR( Sector_Number ) );
                                                   Async_Send( CHR( Sector_Comp   ) );
                                                END;
                                          END;

                                    END

                              END   (* Checksum/CRC OK *)
                           ELSE (* Telink/Ymodem/SeaLink block 0 *)
                              BEGIN

                                 IF ( Initial_Ch = SYN ) { OR
                                    ( Transfer_Protocol = SeaLink ) } THEN
                                    Receive_Telink_Header
                                 ELSE IF ( Transfer_Protocol IN [Xmodem_1K,
                                                                 Xmodem_1KG,
                                                                 Ymodem_G,
                                                                 Ymodem_Batch] ) THEN
                                    Receive_Ymodem_Header;

                                 IF ( NOT Stop_Receive ) THEN
                                    BEGIN
                                       IF ( NOT Do_ACKs ) THEN
                                          Async_Send( 'G' )
                                       ELSE
                                          Async_Send( CHR( ACK ) );
                                       IF Do_WXModem THEN
                                          Async_Send( CHR( Sector_Number AND 3 ) )
                                       ELSE IF Do_SeaLink THEN
                                          BEGIN
                                             Async_Send( CHR( Sector_Number ) );
                                             Async_Send( CHR( Sector_Comp   ) );
                                          END;
                                       Error_Count := 0;
                                    END;

                              END
                        ELSE
                           BEGIN  (* Checksum/CRC error *)
                              INC( CRC_Errors );
                              IF CRC_Used THEN
                                 Display_Receive_Error('CRC error')
                              ELSE
                                 Display_Receive_Error('Checksum error');
                           END    (* Checksum/CRC error *)

                     END  (* Correct sector found *)

                  ELSE
                     IF ( Sector_Number = Sector_Prev ) THEN
                        BEGIN  (* Duplicate sector *)

                           BS_Flag := Receive_Xmodem_Sector( CRC_Used_2 );

                           IF Do_ACKs THEN
                              BEGIN
                                 Async_Send( CHR( ACK ) );
                                 IF Do_WXModem THEN
                                    Async_Send( CHR( Sector_Number AND 3 ) )
                                 ELSE IF Do_SeaLink THEN
                                    BEGIN
                                       Async_Send( CHR( Sector_Number ) );
                                       Async_Send( CHR( Sector_Comp   ) );
                                    END;
                              END;

                           Display_Receive_Error('Duplicate block');

                           INC( Resend_Errors );

                           Error_Flag := FALSE;
                           Dup_Block  := TRUE;

                        END   (* Duplicate sector *)
                     ELSE
                        BEGIN (* Out of sequence sector *)
                           BS_Flag := Receive_Xmodem_Sector( CRC_Used_2 );
                           IF ( Flush_Count > 0 ) THEN
                              BEGIN
                                 DEC( Flush_Count );
                                 Display_Receive_Error('Re-synchronizing ... ');
                                 Error_Flag  := FALSE;
                              END
                           ELSE
                              BEGIN
                                 Display_Receive_Error('Synchronization error');
                                 INC( BlockN_Errors );
                              END;
                        END   (* Out of sequence sector *);

               END   (* Sector # and complement match *)

            ELSE
               BEGIN (* Sector # and complement do not match *)
                  Display_Receive_Error('Sector number error');
                  INC( Comple_Errors );
               END   (* Sector # and complement do not match *);

         END (* SOH Found *)
      ELSE IF ( Initial_Ch = EOT ) THEN
         BEGIN
            IF ( Do_SeaLink AND ( Sector_Count = 0 ) ) THEN
               Null_File_Name := TRUE;
         END
      ELSE
         BEGIN
            Display_Receive_Error('SOH not found');
            INC( SOH_Errors );
         END;
                                   (* Process bad blocks here *)
      IF Error_Flag THEN
         BEGIN
                                   (* Increment error count *)
            INC( Error_Count );
                                   (* If not windowing, flush buffer. *)

            IF Do_Acks THEN
               IF ( NOT ( Do_WXmodem OR Do_SeaLink ) ) THEN
                     Async_Purge_Buffer;

                                   (* Send negative acknowledge to reject *)
                                   (* bad sector.                         *)

            Async_Send( CHR( NAK ) );

                                   (* If windowing, skip remainder of this *)
                                   (* sector, and set up to skip any left  *)
                                   (* in this window.                      *)
            IF Do_WXModem THEN
               BEGIN
                  Async_Send( CHR( Sector_Number AND 3 ) );
                  Block_Start_Set := [ ^V ];
                  Wait_For_SOH( SOH_Time, Initial_Ch , Stop_Receive );
                  Block_Start_Set := [ ^A, ^B, ^D, ^V, ^X ];
                  Flush_Count := WXmodem_Flush;
               END
            ELSE IF Do_SeaLink THEN
               BEGIN
                  Async_Send( CHR( Sector_Number ) );
                  Async_Send( CHR( 255 - Sector_Number ) );
                  Flush_Count := SEALink_Flush;
               END;
                                   (* Cancel transfer for G-protocol guys *)

            IF ( NOT Do_ACKs ) THEN
               BEGIN
                  Stop_Receive := TRUE;
                  G_Failure    := TRUE;
               END;

         END;

      IF Display_Time THEN
         BEGIN

            IF ( NOT ( Error_Flag OR Dup_Block ) ) THEN
               BEGIN

                  Time_To_Send := ROUND( Saved_Time_To_Send *
                                         ( 1.0 -
                                           Sector_Count / Blocks_To_Send ) );

                  IF Time_To_Send < 0 THEN
                     Time_To_Send := 0;

               END;

         END;
                                   (* Check for keyboard entry    *)
      Check_Keyboard;
                                   (* Update status display       *)
      IF Display_Status THEN
         Update_Xmodem_Receive_Display;

   UNTIL ( Initial_Ch = EOT     ) OR
         ( Initial_Ch = CAN     ) OR
         ( Stop_Receive         ) OR
         ( Null_File_Name       ) OR
         ( Error_Count > Xmodem_Max_Errors );
{
IF Debug_Mode THEN
   BEGIN
      Write_Log('Receive_Xmodem', FALSE, FALSE );
      IF Stop_Receive THEN
         Write_Log('   Stop_Receive   = TRUE', FALSE, FALSE )
      ELSE
         Write_Log('   Stop_Receive   = FALSE', FALSE, FALSE );
      IF Null_File_Name THEN
         Write_Log('   Null_File_Name = TRUE', FALSE, FALSE )
      ELSE
         Write_Log('   Null_File_Name = FALSE', FALSE, FALSE );
      IF Alt_R_Pressed THEN
         Write_Log('   Alt_R_Pressed  = TRUE', FALSE, FALSE )
      ELSE
         Write_Log('   Alt_R_Pressed  = FALSE', FALSE, FALSE );
      IF G_Failure THEN
         Write_Log('   G_Failure      = TRUE', FALSE, FALSE )
      ELSE
         Write_Log('   G_Failure      = FALSE', FALSE, FALSE );
      Write_Log('   Error_Count = ' + IToS( Error_Count ), FALSE, FALSE );
      Write_Log('   Xmodem_Max  = ' + IToS( Xmodem_Max_Errors ), FALSE, FALSE );
      Write_Log('   Initial_Ch  = ' + IToS( Initial_Ch ), FALSE, FALSE );
   END;
}
                                   (* If serious error or Alt_R hit, *)
                                   (* stop download.                 *)
   IF ( Stop_Receive ) THEN
      BEGIN

         Cancel_Transfer;

         IF Alt_R_Pressed THEN
            BEGIN
               IF ( NOT Display_Status ) THEN
                  Flip_Display_Status;
               GoToXY( 25 , 10 );
               WRITE('Alt-R hit, receive cancelled.');
               Write_Log('ALT-R hit, receive cancelled.', TRUE, FALSE);
               ClrEol;
            END
         ELSE IF G_Failure THEN
            BEGIN
               IF ( NOT Display_Status ) THEN
                  Flip_Display_Status;
               GoToXY( 25 , 10 );
               WRITE('Error during G protocol, receive cancelled.');
               Write_Log('Error during G protocol, receive cancelled.', TRUE, FALSE);
               ClrEol;
            END;

      END
                                   (* Null file name -- end of batch *)
   ELSE IF Null_File_Name THEN
      BEGIN
         IF ( NOT Display_Status ) THEN
            Flip_Display_Status;
         GoToXY( 25 , 10 );
         WRITE('Null file name received.');
         Write_Log('Null file name received.', TRUE, FALSE);
         ClrEol;
         OK_Transfer := TRUE;
      END
                                   (* EOT received, error count OK *)

   ELSE IF ( ( Initial_Ch = EOT ) AND ( Error_Count <= Xmodem_Max_Errors ) ) THEN
      BEGIN
                                   (* Acknowledge EOT  *)
         Async_Send( CHR( ACK ) );

                                   (* Write any remaining data in buffer *)
         IF Buffer_Pos > 0 THEN
            BEGIN

               Write_Count := Buffer_Pos;

               IF ( ( RFile_Size_2 + Write_Count ) > RFile_Size ) AND
                   Truncate_File THEN
                      Write_Count := TRUNC( RFile_Size - Rfile_Size_2 );

               W_Count := Write_Count;

               BlockWrite( XFile, Write_Buffer^, W_Count, Write_Count );

               IF ( Int24Result <> 0 ) OR
                  ( W_Count <> Write_Count ) THEN
                  BEGIN
                     IF ( NOT Display_Status ) THEN
                        Flip_Display_Status;
                     GoToXY( 25 , 10 );
                     WRITE('Error in writing to disk, file may be bad.');
                     ClrEol;
                     Window_Delay;
                  END;

               RFile_Size_2 := RFile_Size_2 + Write_Count;

            END;

         End_Time       := TimeOfDay;

         IF ( NOT Display_Status ) THEN
            Flip_Display_Status;

         OK_Transfer := TRUE;

         GoToXY( 2 , 10 );

         IF RFile_Size > 0 THEN
            IF RFile_Size <= RFile_Size_2 THEN
               BEGIN
                  RFile_Size_2 := RFile_Size;
                  WRITE('Reception complete; ');
               END
            ELSE
               BEGIN
                  WRITE('Reception appears incomplete; ');
                  OK_Transfer := FALSE;
               END
         ELSE
            WRITE('Reception complete; ');

                                   (* Fix possible wrap around midnight *)

         IF End_Time < Start_Time THEN
            End_Time := End_Time + 86400;

         Effective_Rate := End_Time - Start_Time;

         IF ( Effective_Rate = 0.0 ) THEN
            Effective_Rate := 1.0;

         Effective_Rate := RFile_Size_2 / Effective_Rate;

         WRITE('transfer rate ',Effective_Rate:6:1,' CPS');
         ClrEol;

         IF OK_Transfer THEN
            Write_Log('Received file ' + FileName , TRUE , FALSE )
         ELSE
            Write_Log('Received file ' + FileName + ' (appears incomplete)',
                      TRUE , FALSE );

         OK_Transfer := TRUE;

         STR( RFile_Size_2 , SCps );
         Write_Log('Size of file received was ' + SCps + ' bytes' , TRUE, FALSE );

         STR( Effective_Rate:6:1 , SCps );
         Write_Log('Transfer rate was ' + SCps + ' CPS' , TRUE, FALSE );

      END
   ELSE IF ( Initial_Ch = CAN ) THEN
      BEGIN
         IF ( NOT Display_Status ) THEN
            Flip_Display_Status;
         GoToXY( 25 , 10 );
         WRITE('Transmitter cancelled file transfer.');
         Write_Log('Transmitter cancelled file transfer.', TRUE, FALSE);
         ClrEol;
         Stop_Receive := TRUE;
      END
   ELSE
      BEGIN  (* Too many errors -- cancel transfer *)

         Cancel_Transfer;

         IF ( NOT Display_Status ) THEN
            Flip_Display_Status;
         GoToXY( 25 , 10 );
         WRITE('Receive cancelled -- too many errors');
         Write_Log('Receive cancelled -- too many errors', TRUE, FALSE);
         ClrEol;
      END;
                                   (* Set file time and date if Telink *)
                                   (* or Ymodem                        *)

   IF ( File_Date <> 0 ) AND Use_Time_Sent THEN
      Set_File_Date_And_Time;

                                   (* Close transferred file *)
   CLOSE( XFile );
   I := Int24Result;
                                   (* Delete file if bad               *)

   IF ( Evict_Partial_Trans AND ( NOT OK_Transfer ) ) THEN
      BEGIN
         ASSIGN( XFile , Full_File_Name );
            (*!I-*)
         ERASE( XFile );
            (*!I+*)
         I := INT24Result;
      END;

   Window_Delay;
                                   (* Remove download buffer           *)
   IF Long_Buffer THEN
      MyFreeMem( Write_Buffer , Buffer_Length );

                                   (* Remove XMODEM window             *)

   Restore_Screen_And_Colors( Saved_Screen );

                                   (* Cursor back on *)
   CursorOn;
                                   (* Restore XON/XOFF status *)

   Async_Do_XonXoff := Save_XonXoff;
   Async_OV_XonXoff := Save_XonOV;

                                   (* Restore status line *)
   IF Do_Status_Line THEN
      BEGIN
         Set_Status_Line_Name( Short_Terminal_Name );
         Write_To_Status_Line( Status_Line_Name, 1 );
      END;

END    (* Receive_Xmodem_File *) ;
