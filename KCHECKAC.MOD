(*----------------------------------------------------------------------*)
(*      Check_Sliding_ACK  --- Check ACK State for sliding windows      *)
(*----------------------------------------------------------------------*)

PROCEDURE Check_Sliding_ACK( Must_Get : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Check_Sliding_ACK                                    *)
(*                                                                      *)
(*     Purpose:    Checks ACK status for sliding windows                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Check_Sliding_ACK;                                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

(* STRUCTURED *) CONST
   Deadlock_Message : STRING[36] = 'Send cancelled -- apparent deadlock.';

VAR
   A_Ch: CHAR;

(*----------------------------------------------------------------------*)

PROCEDURE Handle_Resend;

BEGIN (* Handle_Resend *)

   WITH Kermit_Queue[Rec_Packet_Num] DO
      BEGIN

         INC( Retry_Count );
         Send_Packet_Ptr    := ADDR( Sector_Data[Data_Slot] );
         Send_Packet_Length := Data_Length;
{
         IF Kermit_Debug THEN
            BEGIN
               Write_Log('---Resending packet--- ' + IToS( Rec_Packet_Num ), FALSE, FALSE );
               Write_Log('   Retry_Count = ' + IToS( Retry_Count ), FALSE, FALSE );
               Write_Log('   Data_Length = ' + IToS( Data_Length ), FALSE, FALSE );
            END;
}
         IF ( Retry_Count > Kermit_MaxTry ) THEN
            BEGIN
               Kermit_State       := Send_Break;
               Kermit_Abort       := TRUE;
               Kermit_Abort_Level := One_File;
               Display_Kermit_Message('Too many retries for packet ' + IToS( Rec_Packet_Num ) );
               EXIT;
            END
         ELSE
            BEGIN
               Display_Kermit_Message('Resending packet ' + 
                                       IToS( Rec_Packet_Num ) + 
                                       ' (Try # ' + IToS( Retry_Count ) + ')' );
               Send_Packet;
            END;
      END;

END   (* Handle_Resend *);

(*----------------------------------------------------------------------*)

PROCEDURE Handle_ACK;

BEGIN (* Handle_ACK *)

   IF PacketInWindow THEN
      BEGIN
                                   (* Note that this packet has been ACKed. *)
                                   (* If it is the lowest packet in the     *)
                                   (* window, rotate the table.  We may     *)
                                   (* need to rotate up more than one       *)
                                   (* packet, depending upon how many of    *)
                                   (* the following blocks have been ACK'd. *)

         ACK_OK               := TRUE;
         Kermit_Window_Errors := 0;

         Kermit_Queue[Rec_Packet_Num].ACK_Flag := TRUE;

         IF ( Rec_Packet_Num = Kermit_Window_Bottom ) THEN
            BEGIN
               Kermit_Window_Bottom := SUCC( Kermit_Window_Bottom ) MOD 64;
               DEC( Kermit_Window_Used );
            END;

         WHILE ( ( Kermit_Window_Used > 0 ) AND
                 ( Kermit_Queue[Kermit_Window_Bottom].ACK_Flag ) ) DO
            BEGIN
               Kermit_Window_Bottom := SUCC( Kermit_Window_Bottom ) MOD 64;
               DEC( Kermit_Window_Used );
            END;
                                   (* Also check for interruption flags   *)
                                   (* in data field:                      *)
                                   (* 'X' = quit sending current file;    *)
                                   (* 'Y' = quit batch of files.          *)

         IF ( Rec_Packet_Length > 0 ) THEN
            CASE Rec_Packet_Ptr^[1] OF
               'X': BEGIN
                       Display_Kermit_Message_2('Receiver cancelled transfer of current file.');
                       Kermit_Abort       := TRUE;
                       Kermit_Abort_Level := One_File;
                    END;
               'Y': BEGIN
                       Display_Kermit_Message_2('Receiver cancelled transfer of all files.');
                       Kermit_Abort       := TRUE;
                       Kermit_Abort_Level := All_Files;
                    END;
               ELSE;
            END (* CASE *);

      END
   ELSE
      BEGIN
         ACK_OK := TRUE;
         INC( Kermit_Window_Errors );
         IF ( Kermit_Window_Errors > Kermit_MaxTry ) THEN
            BEGIN
               Display_Kermit_Message_2( Deadlock_Message );
               Kermit_Abort       := TRUE;
               Kermit_Abort_Level := One_File;
               Kermit_State       := Send_Break;
            END;
      END;

END   (* Handle_ACK *);

(*----------------------------------------------------------------------*)

PROCEDURE Handle_NAK;

BEGIN (* Handle_NAK *)
                                   (* Increment retry counter for this *)
                                   (* packet if legitimate and resend  *)
                                   (* it.                              *)
   IF Async_Do_XonXoff THEN
      BEGIN
         Async_Send_Now( CHR( XON ) );
         Clear_XOFF_Received;
      END;

   Display_Kermit_Message('NAK for packet ' + IToS( Rec_Packet_Num ) + ' received.');

                                   (* If packet in window, try to resend it. *)
                                   (* Else, increment overall error count.   *)
   IF PacketInWindow THEN
      BEGIN
         Kermit_Window_Errors := 0;
         Handle_Resend;
      END
   ELSE IF ( Rec_Packet_Num = ( SUCC( Kermit_Window_Top ) MOD 64 ) ) THEN
      BEGIN
         Rec_Packet_Num := Kermit_Window_Bottom;
         Handle_Resend;
      END
   ELSE
      BEGIN
         INC( Kermit_Window_Errors );
         IF ( Kermit_Window_Errors > Kermit_MaxTry ) THEN
            BEGIN
               Display_Kermit_Message_2( Deadlock_Message );
               Kermit_Abort       := TRUE;
               Kermit_Abort_Level := One_File;
               Kermit_State       := Send_Break;
            END;
      END;

END   (* Handle_NAK *);

(*----------------------------------------------------------------------*)

PROCEDURE Handle_Error;

BEGIN (* Handle_Error *)

   Display_Kermit_Message('>> Error from remote Kermit <<');

   Kermit_Abort         := TRUE;
   Kermit_Window_Errors := 0;

   GoToXY( 2 , Kermit_Mess2_Line );
   WRITE( COPY( Rec_Packet_Ptr^, 1, Rec_Packet_Length ) );
   ClrEol;

   Write_Log('Error from remote Kermit: ' +
             COPY( Rec_Packet_Ptr^, 1, Rec_Packet_Length ) , FALSE , FALSE );

   IF ( Attended_Mode AND ( NOT Script_File_Mode ) ) THEN
      BEGIN
         GoToXY( 2 , Kermit_Mess3_Line );
         WRITE('Hit any key to continue ... ');
         Read_Kbd( A_Ch );
         IF ( ORD( A_Ch ) = ESC ) AND Pibterm_keypressed THEN
            Read_Kbd( A_Ch );
      END;

END   (* Handle_Error *);

(*----------------------------------------------------------------------*)

BEGIN (* Check_Sliding_ACK *)
                                   (* Assume bad packet to start *)
   ACK_OK := FALSE;
                                   (* If already aborted, quit.  *)
   IF Kermit_Abort THEN
      EXIT;
                                   (* Pick up a packet           *)
   Receive_Packet;

   Packet_Num := Rec_Packet_Num;

{
   IF Kermit_Debug THEN
      BEGIN

         Write_Log('---Check-Sliding-Ack---', FALSE, FALSE);

         CASE Kermit_Packet_Type OF
            ACK_Pack  : Write_Log('ACK received', FALSE, FALSE);
            NAK_Pack  : Write_Log('NAK received', FALSE, FALSE);
            Error_Pack: Write_Log('Error received', FALSE, FALSE);
            ELSE        Write_Log('Unknown received', FALSE, FALSE);
         END (* CASE *);

         Write_Log('Rec_Packet_Num = ' + IToS( Rec_Packet_Num ), FALSE, FALSE);

         IF Packet_OK THEN
            Write_Log('Packet_OK = TRUE', FALSE, FALSE)
         ELSE
            Write_Log('Packet_OK = FALSE', FALSE, FALSE);

      END;
}
                                   (* If we have to get a packet but *)
                                   (* timed out instead, resend the  *)
                                   (* earliest outstanding packet.   *)
   IF Kermit_Abort THEN
      ACK_OK := FALSE
   ELSE IF ( ( NOT Packet_OK ) AND ( Must_Get ) ) THEN
      BEGIN
                                   (* Check XON/XOFF status here.  *)
                                   (* Clear a received XOFF, since *)
                                   (* it is probably bogus, and    *)
                                   (* send XON to remote in case   *)
                                   (* it received bogus XOFF.      *)

         IF Async_Do_XonXoff THEN
            BEGIN
               Async_Send_Now( CHR( XON ) );
               Clear_XOFF_Received;
            END;

         Rec_Packet_Num := Kermit_Window_Bottom;

         WHILE ( ( Rec_Packet_Num <> Kermit_Window_Top ) AND
                 ( Kermit_Queue[Rec_Packet_Num].ACK_Flag = TRUE ) ) DO
            Rec_Packet_Num := SUCC( Rec_Packet_Num ) MOD 64;

         IF ( NOT Kermit_Queue[Rec_Packet_Num].ACK_Flag ) THEN
            Handle_Resend;

         ACK_OK := FALSE;

         INC( Kermit_Window_Errors );
         IF ( Kermit_Window_Errors > Kermit_MaxTry ) THEN
            BEGIN
               Display_Kermit_Message_2( Deadlock_Message );
               Kermit_Abort       := TRUE;
               Kermit_Abort_Level := One_File;
               Kermit_State       := Send_Break;
            END;

      END
   ELSE                            (* We got a packet. *)
      BEGIN
                                   (* Check if ACK or NAK packet received. *)
                                   (* May also be error packet.            *)

         CASE Kermit_Packet_Type OF

                                   (* Make sure ACK is for legitimate block *)

            ACK_Pack   : Handle_ACK;
            NAK_Pack   : Handle_NAK;
            Error_Pack : Handle_Error;

                                   (* Something else -- don't ACK it *)
            ELSE         BEGIN
                            ACK_OK := FALSE;
                            Display_Kermit_Message('Garbage packet received.');
                            IF Async_Do_XonXoff THEN
                               BEGIN
                                  IF Async_XOff_Received THEN
                                     Clear_XOFF_Received;
                                  Async_Send_Now( CHR( XON ) );
                               END
                         END;

         END (* CASE *)

      END;
                                   (* Update count of bad packets *)
   IF ( NOT ACK_OK ) THEN
      Packets_Bad := Packets_Bad + 1;

                                   (* Update display *)
   Update_Kermit_Display;

END    (* Check_Sliding_ACK *);
