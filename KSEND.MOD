(*----------------------------------------------------------------------*)
(*         Check_Init  --- Check initialization packet from host        *)
(*----------------------------------------------------------------------*)

PROCEDURE Check_Init( VAR Check_OK : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Check_Init                                           *)
(*                                                                      *)
(*     Purpose:    Interprets initialization packet from host           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Check_Init( VAR Check_OK : BOOLEAN );                         *)
(*                                                                      *)
(*           Check_OK --- If initialization packet was OK               *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The initialization packet interpreted here has the following  *)
(*        entries:                                                      *)
(*                                                                      *)
(*        Byte        Contents                                          *)
(*        ----   ---------------------------------                      *)
(*          1     Maximum packet size in bytes                          *)
(*          2     Time out value in seconds                             *)
(*          3     Number of pad characters                              *)
(*          4     Padding character                                     *)
(*          5     End of line character                                 *)
(*          6     Control-quoting character                             *)
(*          7     8th bit quote character                               *)
(*          8     Block check type                                      *)
(*          9     Repeat quote character                                *)
(*         10     Facilities flag                                       *)
(*         11     Window size (sliding windows)                         *)
(*         12     Extended packet length                                *)
(*         13     Extended packet length                                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Packet_Length : INTEGER;
   Quote_8       : CHAR;
   Capabilities  : INTEGER;
   IPack         : INTEGER;

BEGIN (* Check_Init *)
                                   (* Check that packet number is OK *)

   IF Rec_Packet_Num = ( Packet_Num MOD 64 ) THEN
      Check_OK := TRUE;

                                   (* Check packet length *)
   IF Rec_Packet_Length >= 1 THEN
      IF ( Rec_Packet_Ptr^[1] <> ' ' ) THEN
         IF ( ORD( Rec_Packet_Ptr^[1] ) - 32 ) IN [4..94] THEN
            Kermit_Packet_Size := ORD( Rec_Packet_Ptr^[1] ) - 32
         ELSE
            Check_OK := FALSE;
                                   (* Determine what other Kermit *)
                                   (* wants.                      *)
   IF Check_OK THEN
      BEGIN (* Check_OK *)
                                   (* TimeOut value *)

         IF Rec_Packet_Length >= 2 THEN
            IF Rec_Packet_Ptr^[2] <> ' ' THEN
               His_TimeOut := ORD( Rec_Packet_Ptr^[2] ) - 32;

                                   (* Number of pad characters    *)

         IF Rec_Packet_Length >= 3 THEN
            IF Rec_Packet_Ptr^[3] <> ' ' THEN
               My_Pad_Num := ORD( Rec_Packet_Ptr^[3] ) - 32
            ELSE
               My_Pad_Num := Kermit_Npad;

                                   (* Padding character         *)

         IF Rec_Packet_Length >= 4 THEN
            IF Rec_Packet_Ptr^[4] <> ' ' THEN
               My_Pad_Char := CHR( ORD( Rec_Packet_Ptr^[4] ) XOR $40 )
            ELSE
               My_Pad_Char := Kermit_Pad_Char;

                                   (* End-of-line character     *)

         IF Rec_Packet_Length >= 5 THEN
            IF Rec_Packet_Ptr^[5] <> ' ' THEN
               Send_EOL := ORD( Rec_Packet_Ptr^[5] ) - 32
            ELSE
               Send_EOL := ORD( Kermit_EOL );

                                   (* Control-quoting character *)

         IF Rec_Packet_Length >= 6 THEN
            BEGIN
               IF ( Rec_Packet_Ptr^[6] = ' ' ) THEN
                  His_Quote_Char := Kermit_Quote_Char
               ELSE
                  His_Quote_Char := Rec_Packet_Ptr^[6];
            END
         ELSE
            His_Quote_Char := Kermit_Quote_Char;

                                   (* 8th-bit quoting character *)

         IF ( Rec_Packet_Length >= 7 ) THEN
            CASE Rec_Packet_Ptr^[7] OF
                                   (* Not quoting *)

               'N' : Quoting := FALSE;

                                   (* Willing to quote but won't *)

               'Y', ' ' : ;

                                   (* Use specified quoting character *)

               '!'..'>','`'..'~' : BEGIN
                                      Quoting := TRUE;
                                      His_Quote_8_Char := Rec_Packet_Ptr^[7];
                                   END;

                                   (* Valid quote char not received *)

               ELSE
                  Check_OK := FALSE;

            END (* CASE *)
                                   (* Remote system not acknowledging *)
                                   (* quoting.                        *)
         ELSE
            IF Quoting THEN
               Check_OK := FALSE;

                                   (* Block check type *)

         IF Rec_Packet_Length >= 8 THEN
            IF Rec_Packet_Ptr^[8] <> ' ' THEN
               IF ( Rec_Packet_Ptr^[8] IN ['1','2','3'] ) THEN
                  His_Chk_Type := Rec_Packet_Ptr^[8]
               ELSE
                  His_Chk_Type := '1'
            ELSE
               His_Chk_Type := '1';

                                   (* Repeat quote character *)

         IF Rec_Packet_Length >= 9 THEN
            IF Rec_Packet_Ptr^[9] <> ' ' THEN
               IF ( Kermit_Repeat_Char <> ' ' ) THEN
                  BEGIN
                     His_Repeat_Char := Rec_Packet_Ptr^[9];
                     Repeating := ( His_Repeat_Char <> ' ' );
                  END;
                                   (* Capabilities flags *)

         Capabilities           := 0;
         Kermit_Attributes      := FALSE;
         His_Kermit_Window_Size := 0;
         His_Kermit_MaxLX1      := 0;
         His_Kermit_MaxLX2      := 0;

         IF Rec_Packet_Length >= 10 THEN
            IF Rec_Packet_Ptr^[10] <> ' ' THEN
               BEGIN
                  Capabilities          := ORD( Rec_Packet_Ptr^[10] ) - 32;
                  Kermit_Attributes     := ( ( Capabilities AND 8 ) <> 0 );
                  Kermit_Do_Sliding_Win := ( ( Capabilities AND 4 ) <> 0 );
                  Kermit_Do_Long_Blocks := ( ( Capabilities AND 2 ) <> 0 );
               END;

         IF ( Capabilities <> 0 ) THEN
            BEGIN (* Capabilities <> 0 *)

                                            (* Skip unused capacity bytes *)
               IPack := 10;

               WHILE( ( Capabilities AND 1 ) <> 0 ) DO
                  BEGIN
                     IPack := SUCC( IPack );
                     IF ( IPack <= Rec_Packet_Length ) THEN
                        Capabilities := ORD( Rec_Packet_Ptr^[IPack] ) - 32
                     ELSE
                        Capabilities := 1;
                  END;
                                            (* Get sliding windows size *)
               IPack := SUCC( IPack );

               IF Rec_Packet_Length >= IPack THEN
                  IF Rec_Packet_Ptr^[IPack] <> ' ' THEN
                     His_Kermit_Window_Size := MIN( ORD( Rec_Packet_Ptr^[IPack] ) - 32 ,
                                                    Kermit_Window_Size );

                                            (* Get long packets length  *)
               IPack := SUCC( IPack );

               His_Kermit_MaxLX1 := Kermit_Extended_Block DIV 95;
               His_Kermit_MaxLX2 := Kermit_Extended_Block MOD 95;

               IF Rec_Packet_Length >= IPack THEN
                  IF Rec_Packet_Ptr^[IPack] <> ' ' THEN
                     His_Kermit_MaxLX1 := ORD( Rec_Packet_Ptr^[IPack] ) - 32
                  ELSE
                     His_Kermit_MaxLX1 := 0;

               IPack := SUCC( IPack );

               IF Rec_Packet_Length >= IPack THEN
                  IF Rec_Packet_Ptr^[IPack] <> ' ' THEN
                     His_Kermit_MaxLX2 := ORD( Rec_Packet_Ptr^[IPack] ) - 32
                  ELSE
                     His_Kermit_MaxLX2 := 0;

            END (* Capabilities <> 0 *);

                                   (* Turn on sliding windows *)

         Kermit_Do_Sliding_Win := Kermit_Do_Sliding_Win          AND
                                  ( His_Kermit_Window_Size > 0 ) AND
                                  ( Kermit_Window_Size     > 0 );

                                   (* Sliding windows takes precedence over *)
                                   (* long blocks.                          *)

         Packet_Length := 95 * His_Kermit_MaxLX1 + His_Kermit_MaxLX2;

         Kermit_Do_Long_Blocks := Kermit_Do_Long_Blocks          AND
                                  ( ( Packet_Length > 94 ) OR
                                    ( Packet_Length = 0  )     ) AND
                                  ( NOT Kermit_Do_Sliding_Win  ) AND
                                  ( Kermit_Extended_Block > 94 );

                                   (* Adjust long block size if necessary   *)
                                   (* to be less than our maximum           *)

         IF Kermit_Do_Long_Blocks THEN
            IF ( Packet_Length > MaxLongPacketLength ) THEN
               BEGIN
                  His_Kermit_MaxLX1 := MaxLongPacketLength DIV 95;
                  His_Kermit_MaxLX2 := MaxLongPacketLength MOD 95;
               END
            ELSE IF ( Packet_Length = 0 ) THEN
               BEGIN
                  His_Kermit_MaxLX1 := 500 DIV 95;
                  His_Kermit_MaxLX2 := 500 MOD 95;
               END;
                                   (* Display the parameter values *)

         Display_Kermit_Init_Params;

      END (* IF Check_OK *);
{
   IF Kermit_Debug THEN
      BEGIN
         Kermit_Debug_Write_String ('--- Check_Init Start ---', '' );
         Kermit_Debug_Write_Char   ('His_Quote_Char   = ',His_Quote_Char);
         Kermit_Debug_Write_Boolean('Quoting          = ',Quoting);
         Kermit_Debug_Write_Char   ('His_Quote_8_Char = ',His_Quote_8_Char);
         Kermit_Debug_Write_Boolean('Repeating        = ',Repeating);
         Kermit_Debug_Write_Char   ('His_Repeat_Char  = ',His_Repeat_Char);
         Kermit_Debug_Write_Boolean('Attributes       = ',Kermit_Attributes);
         Kermit_Debug_Write_Boolean('Sliding windows  = ',Kermit_Do_Sliding_Win);
         Kermit_Debug_Write_Boolean('Long blocks      = ',Kermit_Do_Long_Blocks);
         Kermit_Debug_Write_Integer('Packet length    = ',Packet_Length );
         Kermit_Debug_Write_Integer('MaxLx1           = ',His_Kermit_MaxLx1);
         Kermit_Debug_Write_Integer('MaxLx2           = ',His_Kermit_MaxLx2);
         Kermit_Debug_Write_String ('--- Check_Init End   ---', '' );
      END;
}
END    (* Check_Init *);

(*----------------------------------------------------------------------*)
(*           Check_ACK  --- Check ACK State for most packets            *)
(*----------------------------------------------------------------------*)

PROCEDURE Check_ACK;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Check_ACK                                            *)
(*                                                                      *)
(*     Purpose:    Checks ACK status for most packets                   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Check_ACK;                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   A_Ch: CHAR;

(*----------------------------------------------------------------------*)

PROCEDURE Handle_ACK;

BEGIN (* Handle_ACK *)
                                   (* Make sure ACK is for correct block. *)
                                   (* Also check for interruption flags   *)
                                   (* in data field:                      *)
                                   (* 'X' = quit sending current file;    *)
                                   (* 'Y' = quit batch of files.          *)

   IF ( Rec_Packet_Num = ( Packet_Num MOD 64 ) ) THEN
      BEGIN
         ACK_OK := TRUE;
         IF ( Rec_Packet_Length > 0 ) THEN
            CASE Rec_Packet_Ptr^[1] OF
               'X': BEGIN
                       Display_Kermit_Message_2('Cancelling transfer of current file.');
                       Kermit_Abort       := TRUE;
                       Kermit_Abort_Level := One_File;
                    END;
               'Y': BEGIN
                       Display_Kermit_Message_2('Cancelling transfer of all files.');
                       Kermit_Abort       := TRUE;
                       Kermit_Abort_Level := All_Files;
                    END;
               ELSE;
            END (* CASE *);
      END;

END   (* Handle_ACK *);

(*----------------------------------------------------------------------*)

PROCEDURE Handle_NAK;

BEGIN (* Handle_NAK *)

   IF ( Rec_Packet_Num = 0 ) THEN
      Rec_Packet_Num := 63
   ELSE
      Rec_Packet_Num := PRED( Rec_Packet_Num );

                                   (* NAK for next is ACK for present *)

   IF ( Rec_Packet_Num = ( Packet_Num MOD 64 ) ) THEN
      ACK_OK := TRUE;

   Display_Kermit_Message('NAK for packet ' + IToS( Rec_Packet_Num ) +
                          ' received.');

END   (* Handle_NAK *);

(*----------------------------------------------------------------------*)

PROCEDURE Handle_Error;

BEGIN (* Handle_Error *)

   Display_Kermit_Message  ('Error from remote Kermit:');
   Display_Kermit_Message_2( COPY( Rec_Packet_Ptr^, 1, Rec_Packet_Length ) );

   Kermit_Abort := TRUE;

   IF ( Attended_Mode AND ( NOT Script_File_Mode ) ) THEN
      BEGIN
         GoToXY( 2 , Kermit_Mess3_Line );
         WRITE('Hit any key to continue ... ');
         Read_Kbd( A_Ch );
         IF ( ORD( A_Ch ) = ESC ) AND PibTerm_KeyPressed THEN
            Read_Kbd( A_Ch );
      END;

END   (* Handle_Error *);

(*----------------------------------------------------------------------*)

BEGIN (* Check_ACK *)
                                   (* Assume bad packet to start *)
   ACK_OK := FALSE;
                                   (* Pick up a packet           *)
   IF Kermit_Abort THEN
      EXIT;

   Receive_Packet;
{
   IF Kermit_Debug THEN
      BEGIN

         Write_Log('---Check-Ack---', FALSE, FALSE);

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
   IF Packet_OK AND ( NOT Kermit_Abort ) THEN
      BEGIN
                                   (* Check if ACK or NAK packet received. *)
                                   (* May also be error packet.            *)

         CASE Kermit_Packet_Type OF


            ACK_Pack  : Handle_ACK;
            NAK_Pack  : Handle_NAK;
            Error_Pack: Handle_Error;

                                   (* Something else -- don't ACK it *)
            ELSE        BEGIN
                           ACK_OK := FALSE;
                           Display_Kermit_Message('Garbage packet received.');
                        END;

         END (* CASE *)

      END
   ELSE
      ACK_OK := FALSE;

   IF ( NOT ACK_OK ) THEN
      BEGIN
         Packets_Bad := Packets_Bad + 1;
         Update_Kermit_Display;
      END;

END    (* Check_ACK *);

(*----------------------------------------------------------------------*)
(*                   Send_Packet --- send a packet                      *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Packet;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Send_Packet                                          *)
(*                                                                      *)
(*     Purpose:    Sends a Kermit packet to remote host                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Send_Packet;                                                  *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The packet to be sent is in Send_Packet_Ptr^.                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Count : INTEGER;
   Ch    : CHAR;
   StrNum: STRING[3];
   H_Char: INTEGER;

BEGIN (* Send_Packet *)
                                   (* Wait for handshake character   *)
                                   (* if necessary                   *)

   IF ( ( Kermit_Handshake_Char <> ' ' ) AND ( Local_Echo ) ) THEN
      BEGIN
         REPEAT  (* get handshake character *)
            Get_Char( H_Char );
         UNTIL ( ( H_Char = ORD( Kermit_Handshake_Char ) ) OR
                   Kermit_Abort OR Kermit_Retry );
         IF ( Kermit_Abort OR Kermit_Retry ) THEN
            EXIT;
      END;
                                   (* Purge buffer before send unless *)
                                   (* sliding windows being used.     *)

   IF ( NOT ( Kermit_Do_Sliding_Win AND Kermit_Doing_Transfer ) ) THEN
      Async_Purge_Buffer;
                                   (* Make sure carrier still there   *)

   IF ( NOT Async_Carrier_Detect ) THEN
      BEGIN
         Kermit_Abort       := TRUE;
         Kermit_Abort_Level := Entire_Protocol;
         EXIT;
      END;
                                   (* Send requested padding         *)
   IF ( My_Pad_Num > 0 ) THEN
      FOR Count := 1 TO My_Pad_Num DO
         Async_Send( My_Pad_Char );

                                   (* Make sure carrier still there  *)

   IF ( NOT Async_Carrier_Detect ) THEN
      BEGIN
         Kermit_Abort       := TRUE;
         Kermit_Abort_Level := Entire_Protocol;
         EXIT;
      END;
                                   (* Send the packet data           *)

   FOR Count := 1 TO Send_Packet_Length DO
      Async_Send( Send_Packet_Ptr^[Count] );

                                   (* Send the end of line marker    *)
   Async_Send( CHR( Send_EOL ) );

                                   (* Purge input buffer after send,  *)
                                   (* and wait for output buffer to   *)
                                   (* drain to avoid false timeouts.  *)
   Ch := ' ';

   IF ( NOT Kermit_Do_Sliding_Win ) THEN
      BEGIN
         WHILE ( Async_Receive( Ch )      AND
                 ( Ch <> CHR( Send_EOL ) ) AND
                 ( NOT PibTerm_KeyPressed )             ) DO;
         Async_Drain_Output_Buffer( Five_Seconds );
      END;
                                   (* Update packets sent count      *)

   Packets_Sent := Packets_Sent + 1;

   Update_Kermit_Display;
{
   IF Kermit_Debug THEN
      BEGIN
         Write_Log('>>>>> Send_Packet: sent packet number ' +
                   IToS( ORD( Send_Packet_Ptr^[3] ) - 32 ),
                   FALSE, FALSE );
         Write_Log('                   length = ' + IToS( Send_Packet_Length ),
                   FALSE, FALSE );
      END;
}
END   (* Send_Packet *);

(*----------------------------------------------------------------------*)
(*                 Build_Packet --- Build a packet                      *)
(*----------------------------------------------------------------------*)

PROCEDURE Build_Packet;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Build_Packet                                         *)
(*                                                                      *)
(*     Purpose:    Builds a Kermit packet                               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Build_Packet;                                                 *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine add the block number and checksum to the data in *)
(*        Send_Packet_Ptr^_Data.                                        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   CheckSum        : INTEGER;
   Count           : INTEGER;
   Check_Type      : INTEGER;
   Long_Length     : INTEGER;
   Send_Packet_Ptr2: Kermit_Packet_Ptr;

BEGIN (* Build_Packet *)
                                   (* Add block header, length, packet *)
                                   (* number to front of packet data.  *)
                                   (* This is done differently for     *)
                                   (* short and long blocks.           *)

   Check_Type          := ORD( His_Chk_Type ) - ORD('0');

   Send_Packet_Ptr^[1] := Kermit_Header_Char;
   Send_Packet_Ptr^[3] := CHR( Packet_Num MOD 64 + 32 );

   IF ( Kermit_Do_Long_Blocks AND ( Send_Packet_Ptr^[4] = 'D' ) ) THEN
      BEGIN
         Long_Length         := Send_Packet_Length + Check_Type - 7;
         Send_Packet_Ptr^[2] := ' ';
         Send_Packet_Ptr^[5] := CHR( Long_Length DIV 95 + 32 );
         Send_Packet_Ptr^[6] := CHR( Long_Length MOD 95 + 32 );
         CheckSum            := 32 + ORD( Send_Packet_Ptr^[3] ) +
                                     ORD( Send_Packet_Ptr^[4] ) +
                                     ORD( Send_Packet_Ptr^[5] ) +
                                     ORD( Send_Packet_Ptr^[6] );
         CheckSum            := ( ( CheckSum + ( ( CheckSum AND 192 ) SHR 6 ) )
                                AND 63 );
         Send_Packet_Ptr^[7] := CHR( CheckSum + 32 );
      END
   ELSE
      Send_Packet_Ptr^[2] := CHR( Send_Packet_Length + Check_Type + 30 );

                                   (* Calculate checksum/crc *)

   Send_Packet_Ptr2 := ADDR( Send_Packet_Ptr^[2] );
   Count            := Send_Packet_Length - 1;

   CASE His_Chk_Type OF

      '1': BEGIN

              Kermit_Chk8( Send_Packet_Ptr2^, Count, CheckSum );
              CheckSum := ( ( CheckSum + ( ( CheckSum AND 192 ) SHR 6 ) ) AND 63 );

              Send_Packet_Length                   := SUCC( Send_Packet_Length );
              Send_Packet_Ptr^[Send_Packet_Length] := CHR( CheckSum + 32 );

           END;

      '2': BEGIN

              Kermit_Chk12( Send_Packet_Ptr2^, Count, CheckSum );

              Send_Packet_Length                   := SUCC( Send_Packet_Length );
              Send_Packet_Ptr^[Send_Packet_Length] := CHR( CheckSum SHR 6 + 32 );

              Send_Packet_Length                   := SUCC( Send_Packet_Length );
              Send_Packet_Ptr^[Send_Packet_Length] := CHR( CheckSum AND 63 + 32 );

           END;

      '3': BEGIN

              Kermit_CRC( Send_Packet_Ptr2^, Count, CheckSum );

              Send_Packet_Length                   := SUCC( Send_Packet_Length );
              Send_Packet_Ptr^[Send_Packet_Length] := CHR( ( CheckSum SHR 12 ) AND 63 + 32 );

              Send_Packet_Length                   := SUCC( Send_Packet_Length );
              Send_Packet_Ptr^[Send_Packet_Length] := CHR( ( CheckSum SHR 6  ) AND 63 + 32 );

              Send_Packet_Length                   := SUCC( Send_Packet_Length );
              Send_Packet_Ptr^[Send_Packet_Length] := CHR( CheckSum AND 63            + 32 );

           END;

   END (* CASE *);

END    (* Build_Packet *);

(*----------------------------------------------------------------------*)
(*               Send_ACK  --- Send acknowledge for a packet            *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_ACK;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Send_ACK                                             *)
(*                                                                      *)
(*     Purpose:    Sends acknowledge for packet to host                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Send_ACK;                                                     *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Build_Packet;                                                 *)
(*        Send_Packet;                                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Save_CHK      : CHAR;
   Quote_8       : CHAR;
   My_Attributes : CHAR;
   Window_Size   : STRING[1];
   LX1           : CHAR;
   LX2           : CHAR;

BEGIN (* Send_ACK *)

   IF ( Kermit_State = Receive_Init ) OR
      ( Kermit_State = Get_File     ) THEN
      BEGIN

         IF Quoting THEN
            Quote_8 := His_Quote_8_Char
         ELSE
            Quote_8 := 'N';

         My_Attributes := CHR( 8 + 32 );
         Window_Size   := ' ';

         IF Kermit_Do_Sliding_Win THEN
            BEGIN
               My_Attributes := CHR( 8 + 4 + 32 );
               Window_Size   := CHR( His_Kermit_Window_Size + 32 );
            END;

         IF Kermit_Do_Long_Blocks THEN
            BEGIN
               My_Attributes := CHR( 8 + 2 + 32 );
               LX1           := CHR( His_Kermit_MaxLX1 + 32 );
               LX2           := CHR( His_Kermit_MaxLX2 + 32 );
               Window_Size   := ' ';
            END;

         Send_Packet_Ptr^[ 4] := 'Y';
         Send_Packet_Ptr^[ 5] := CHR( Kermit_Packet_Size + 32    );
         Send_Packet_Ptr^[ 6] := CHR( Kermit_TimeOut     + 32    );
         Send_Packet_Ptr^[ 7] := CHR( My_Pad_Num         + 32    );
         Send_Packet_Ptr^[ 8] := CHR( ORD( My_Pad_Char ) XOR $40 );
         Send_Packet_Ptr^[ 9] := CHR( Send_EOL           + 32    );
         Send_Packet_Ptr^[10] := His_Quote_Char;
         Send_Packet_Ptr^[11] := Quote_8;
         Send_Packet_Ptr^[12] := His_Chk_Type;
         Send_Packet_Ptr^[13] := His_Repeat_Char;
         Send_Packet_Ptr^[14] := My_Attributes;

         Send_Packet_Length   := 14;

         IF ( Kermit_Do_Sliding_Win OR Kermit_Do_Long_Blocks ) THEN
            BEGIN
               Send_Packet_Ptr^[15] := Window_Size[1];
               Send_Packet_Length   := 15;
            END;

         IF Kermit_Do_Long_Blocks THEN
            BEGIN
               Send_Packet_Ptr^[16] := LX1;
               Send_Packet_Ptr^[17] := LX2;
               Send_Packet_Length   := 17;
            END;

         Save_CHK     := His_Chk_Type;
         His_Chk_Type := '1';

         Build_Packet;
         Send_Packet;

         His_Chk_Type := Save_CHK;

      END
   ELSE
      BEGIN

         Send_Packet_Ptr^[4] := 'Y';
         Send_Packet_Length  := 4;

         Build_Packet;
         Send_Packet;

      END;

END   (* Send_ACK *);

(*----------------------------------------------------------------------*)
(*         Send_NAK  --- Send negative acknowledge for a packet         *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_NAK;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Send_NAK                                             *)
(*                                                                      *)
(*     Purpose:    Sends negative acknowledge for packet to host        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Send_NAK;                                                     *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Build_Packet;                                                 *)
(*        Send_Packet;                                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Send_NAK *)

   Send_Packet_Ptr^[4] := 'N';
   Send_Packet_Length  := 4;

   Build_Packet;
   Send_Packet;

   Display_Kermit_Message('Sending NAK for packet ' + IToS( Packet_Num ));

END   (* Send_NAK *);

(*----------------------------------------------------------------------*)
(*         PacketInWindow --- Check if packet is in current window      *)
(*----------------------------------------------------------------------*)

FUNCTION PacketInWindow : BOOLEAN;

VAR
   Inside : BOOLEAN;

BEGIN (* PacketInWindow *)

    IF ( Kermit_Window_Top > Kermit_Window_Bottom ) THEN
       Inside := ( Rec_Packet_Num >= Kermit_Window_Bottom ) AND
                 ( Rec_Packet_Num <= Kermit_Window_Top    )
    ELSE
       Inside := ( Rec_Packet_Num <= Kermit_Window_Top    ) OR
                 ( Rec_Packet_Num >= Kermit_Window_Bottom );

    PacketInWindow := Inside;

END   (* PacketInWindow *);
