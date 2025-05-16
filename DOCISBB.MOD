(*----------------------------------------------------------------------*)
(*   CISB_DLE_Seen --- Handle DLE character seen -- Main CISB B routine *)
(*----------------------------------------------------------------------*)

PROCEDURE CISB_DLE_Seen;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  CISB_DLE_Seen is called from the main program when the character    *)
(*  <DLE> is received from the host.                                    *)
(*                                                                      *)
(*  This routine calls Read_Packet and dispatches to the appropriate    *)
(*  handler for the incoming packet.                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   Max_Buf_Size  = 1032            (* Largest data block we can handle  *);
   Max_SA        = 2               (* Maximum number of waiting packets *);

   Def_Buf_Size  = 511             (* Default data block                *);
   Def_WS        = 1               (* I can send 2 packets ahead        *);
   Def_WR        = 1               (* I can receive single send-ahead   *);
   Def_BS        = 8               (* I can handle 1024 bytes           *);
   Def_CM        = 1               (* I can handle CRC                  *);
   Def_DQ        = 1               (* I can handle non-quoted NUL       *);

   Max_Errors    =  10             (* Maximum errors allowed per block *);

                   (* Receive States *)

   R_Get_DLE      = 0;
   R_Get_B        = 1;
   R_Get_Seq      = 2;
   R_Get_Data     = 3;
   R_Get_CheckSum = 4;
   R_Send_ACK     = 5;
   R_Timed_Out    = 6;
   R_Success      = 7;

                   (* Send States *)

   S_Get_DLE      = 1;
   S_Get_Num      = 2;
   S_Get_Packet   = 3;
   S_Timed_Out    = 4;
   S_Send_NAK     = 5;
   S_Send_Data    = 6;

                   (* Table of control characters that need to be masked *)

   Mask_Table : ARRAY[ 0..31 ] OF BYTE = (
                0, 0, 0, 1, 0, 1, 0, 0,   { NUL SOH SOB ETX EOT ENQ SYN BEL }
                0, 0, 0, 0, 0, 0, 0, 0,   { BS  HT  LF  VT  FF  CR  SO  SI  }
                1, 1, 0, 1, 0, 1, 0, 0,   { DLE DC1 DC2 DC3 DC4 NAK ^V  ^W  }
                0, 0, 0, 0, 0, 0, 0, 0    { CAN ^Y  ^Z  ESC ?   ?   ?   ?   }
                                         );

TYPE
   BufferType = ARRAY[ 0..Max_Buf_Size ] OF BYTE;

   Buf_Type   = RECORD
                   Seq : INTEGER    (* Packet's sequence number  *);
                   Num : INTEGER    (* Number of bytes in packet *);
                   Buf : BufferType (* Actual packet data        *);
                END;

VAR
   Timer           : INTEGER       (* Wait time for character to appear *);
   R_Size          : INTEGER       (* Size of receiver buffer *);
   Ch              : INTEGER       (* Current character *);
   Save_Xon_Xoff   : BOOLEAN       (* Save current XON/XOFF status *);

   Timed_Out       : BOOLEAN       (* We timed out before receiving character *);
   Masked          : BOOLEAN       (* TRUE if ctrl character was 'masked' *);

                                   (* Send-ahead buffers *)

   SA_Buf          : ARRAY[ 0..Max_SA ] OF Buf_Type ABSOLUTE Sector_Data;

   SA_Next_to_ACK  : INTEGER       (* Which SA_Buf is waiting for an ACK *);
   SA_Next_to_Fill : INTEGER       (* Which SA_Buf is ready for new data *);
   SA_Waiting      : INTEGER       (* Number of SA_Buf's waiting for ACK *);

                                   (* File buffer *)

   R_Buffer        : BufferType;

   FileName        : AnyStr        (* Name of file sent/received *);

   I               : INTEGER;
   N               : INTEGER;
   Dummy           : BOOLEAN;

LABEL
   Error_Exit;

(*----------------------------------------------------------------------*)
(*   Send_Masked_Byte -- Send character with possible <DLE> masking     *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Masked_Byte( Ch : INTEGER );

BEGIN (* Send_Masked_Byte *)

   Ch := Ch AND $FF;
                                   (* If character is control character,   *)
                                   (* and is in table of characters to     *)
                                   (* mask, then send <DLE><Ch+31> instead *)
                                   (* of character itself.                 *)

   IF ( Ch < 32 ) THEN
      IF ( Mask_Table[Ch] <> 0 ) THEN
         BEGIN
            Async_Send( CHR( DLE ) );
            Async_Send( CHR( Ch + ORD('@') ) );
         END
      ELSE
         Async_Send( CHR( Ch ) )
   ELSE
      Async_Send( CHR( Ch ) );

END   (* Send_Masked_Byte *);

(*----------------------------------------------------------------------*)
(*                Send_ACK -- Send acknowledgement to host              *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_ACK;

BEGIN (* Send_ACK *)

   Async_Send( CHR( DLE ) );
   Async_Send( CHR( Seq_Num + ORD('0') ) );

   Update_B_Display;

END   (* Send_ACK *);

(*----------------------------------------------------------------------*)
(*       Send_NAK --- Send negative acknowledge for block to host       *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_NAK;

BEGIN (* Send_NAK *)

   Display_Message_With_Number( 'Sending NAK for block ', Total_Blocks );

   Async_Send( CHR( NAK ) );

   Update_B_Display;

END   (* Send_NAK *);

(*----------------------------------------------------------------------*)
(*                 Send_ENQ --- Send ENQ to host                        *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_ENQ;

BEGIN (* Send_ENQ *)

   Async_Send( CHR( ENQ ) );

END   (* Send_ENQ *);

(*----------------------------------------------------------------------*)
(*     Read_Byte --- Read one character from serial port with timer     *)
(*----------------------------------------------------------------------*)

FUNCTION Read_Byte : BOOLEAN;

VAR
   I: INTEGER;

BEGIN (* Read_Byte *)

   I := 0;

   REPEAT
      INC( I );
      Async_Receive_With_Timeout( 1 , Ch );
      Check_Keyboard;
   UNTIL ( I > Timer ) OR ( Ch <> TimeOut ) OR Halt_Transfer;

   Timed_Out := ( Ch = TimeOut ) OR ( I > Timer );

   Read_Byte := ( NOT Timed_Out     ) AND
                ( NOT Halt_Transfer );

END   (* Read_Byte *);

(*----------------------------------------------------------------------*)
(*     Read_Masked_Byte --- Read possibly masked character from port    *)
(*----------------------------------------------------------------------*)

FUNCTION Read_Masked_Byte : BOOLEAN;

BEGIN (* Read_Masked_Byte *)

   Masked := FALSE;

   IF ( NOT Read_Byte ) THEN
      BEGIN
         Read_Masked_Byte := FALSE;
         EXIT;
      END;
                                   (* Check for <DLE> -- indicates   *)
                                   (* following character is masked. *)
   IF ( Ch = DLE ) THEN
     BEGIN

         IF ( NOT Read_Byte ) THEN
            BEGIN
               Read_Masked_Byte := FALSE;
               EXIT;
            END;

         Ch := Ch AND $1F;

         Masked := TRUE;

      END;

   Read_Masked_Byte := TRUE;

END   (* Read_Masked_Byte *);

(*----------------------------------------------------------------------*)
(*                 Incr_Seq --- Increment block sequence number         *)
(*----------------------------------------------------------------------*)

FUNCTION Incr_Seq( Value : INTEGER ) : INTEGER;

BEGIN (* Incr_Seq *)

   IF ( Value = 9 ) THEN
      Incr_Seq := 0
   ELSE
      Incr_Seq := SUCC( Value );

END   (* Incr_Seq *);

(*----------------------------------------------------------------------*)
(*              Send_Failure -- Send failure code to host               *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Failure( Code : CHAR );
   FORWARD;

(*----------------------------------------------------------------------*)
(*               Read_Packet --- Read packet from host                  *)
(*----------------------------------------------------------------------*)

FUNCTION Read_Packet( Lead_In_Seen     : BOOLEAN;
                      From_Send_Packet : BOOLEAN ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Lead_In_Seen is TRUE if the <DLE><B> has been seen already.        *)
(*                                                                      *)
(*   From_Send_Packet is TRUE if called from Send_Packet                *)
(*   (causes exit on first error detected)                              *)
(*                                                                      *)
(*   Returns True if packet is available from host.                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   State      : INTEGER;
   Next_Seq   : INTEGER;
   Block_Num  : INTEGER;
   Errors     : INTEGER;
   New_Cks    : INTEGER;
   I          : INTEGER;

   NAK_Sent   : BOOLEAN;
   Do_Exit    : BOOLEAN;
   Got_Packet : BOOLEAN;

(*----------------------------------------------------------------------*)

PROCEDURE Do_R_Get_DLE;

BEGIN (* Do_R_Get_DLE *)

   IF Halt_Transfer THEN
      BEGIN
         Display_Message('Transfer terminated by keyboard request.',
                         Err_Mess_Line);
         Send_Failure( 'A' );
         Got_Packet := FALSE;
         Do_Exit    := TRUE;
      END
   ELSE
      IF ( NOT Read_Byte ) THEN
         State := R_Timed_Out
      ELSE IF ( ( Ch AND $7F ) = DLE ) THEN
         State := R_Get_B
      ELSE IF ( ( Ch AND $7F ) = ENQ ) THEN
         State := R_Send_ACK;

END   (* Do_R_Get_DLE *);

(*----------------------------------------------------------------------*)

PROCEDURE Do_R_Get_B;

BEGIN (* Do_R_Get_B *)

{
IF Debug_Mode THEN
   Write_Log('   R_Get_B State', FALSE, FALSE );
}
   IF ( NOT Read_Byte ) THEN
      State := R_Timed_Out
   ELSE IF ( ( Ch AND $7F ) = ORD('B') ) THEN
      State := R_Get_Seq
   ELSE IF ( Ch = ENQ ) THEN
      State := R_Send_ACK
   ELSE
      State := R_Get_DLE;

END   (* Do_R_Get_B *);

(*----------------------------------------------------------------------*)

PROCEDURE Do_R_Get_Seq;

BEGIN (* Do_R_Get_Seq *)
{
IF Debug_Mode THEN
   Write_Log('   R_Get_Seq State', FALSE, FALSE );
}
   IF ( NOT Read_Byte ) THEN
      State := R_Timed_Out
   ELSE IF ( Ch = ENQ ) THEN
      State := R_Send_ACK
   ELSE
      BEGIN

         IF ( Quick_B AND Use_CRC ) THEN
            CheckSum := -1
         ELSE
            CheckSum := 0;

         Block_Num := Ch - ORD('0');

         Do_CheckSum( Ch );

         I     := 0;
         State := R_Get_Data;

      END;

END   (* Do_R_Get_Seq *);

(*----------------------------------------------------------------------*)

PROCEDURE Do_R_Get_Data;

BEGIN (* Do_R_Get_Data *)
{
IF Debug_Mode THEN
   Write_Log('   R_Get_Data State', FALSE, FALSE );
}
   IF ( NOT Read_Masked_Byte ) THEN
      State := R_Timed_Out
   ELSE IF ( ( Ch = ETX ) AND ( NOT Masked ) ) THEN
      BEGIN
         Do_CheckSum( ETX );
         State := R_Get_CheckSum;
      END
   ELSE
      BEGIN
         R_Buffer[ I ] := Ch;
         INC( I );
         Do_CheckSum( Ch );
      END;

END   (* Do_R_Get_Data *);

(*----------------------------------------------------------------------*)

PROCEDURE Do_R_Get_CheckSum;

BEGIN (* Do_R_Get_CheckSum *)
{
IF Debug_Mode THEN
   Write_Log('   R_Get_CheckSum State', FALSE, FALSE );
}
   IF ( NOT Read_Masked_Byte ) THEN
      State := R_Timed_Out
   ELSE
      BEGIN

         IF ( Quick_B AND Use_CRC ) THEN
            BEGIN

               CheckSum := SWAP( CheckSum ) XOR Ch;
               CheckSum := CheckSum XOR ( LO( CheckSum ) SHR 4 );
               CheckSum := CheckSum XOR ( SWAP( LO( CheckSum ) ) SHL 4 ) XOR
                                        ( LO( CheckSum ) SHL 5 );

               IF ( NOT Read_Masked_Byte ) THEN
                  New_Cks := CheckSum XOR $FF
               ELSE
                  BEGIN
                     CheckSum := SWAP( CheckSum ) XOR Ch;
                     CheckSum := CheckSum XOR ( LO( CheckSum ) SHR 4 );
                     CheckSum := CheckSum XOR ( SWAP( LO( CheckSum ) ) SHL 4 ) XOR
                                              ( LO( CheckSum ) SHL 5 );
                     New_Cks  := 0;
                  END;

            END
         ELSE
            New_Cks := Ch;

         IF ( New_Cks <> CheckSum ) THEN
            State := R_Timed_Out
                                   (* Watch for failure packet *)
                                   (* which is always accepted *)

         ELSE IF ( R_Buffer[0] = ORD('F') ) THEN
            State := R_Success
                                   (* Watch for duplicate block *)

         ELSE IF ( Block_Num = Seq_Num ) THEN
            State := R_Success

                                   (* Watch for bad sequence number *)

         ELSE IF ( Block_Num <> Next_Seq ) THEN
            State := R_Timed_Out

         ELSE
            State := R_Success;

      END;

END   (* Do_R_Get_CheckSum *);

(*----------------------------------------------------------------------*)

PROCEDURE Do_R_Timed_Out;

BEGIN (* Do_R_Timed_Out *)
{
IF Debug_Mode THEN
   Write_Log('   R_Timed_Out State', FALSE, FALSE );
}
   INC( Errors );

   IF ( ( Errors > Max_Errors ) OR From_Send_Packet ) THEN
      BEGIN
         Got_Packet  := FALSE;
         Do_Exit     := TRUE;
      END
   ELSE
      BEGIN

         IF ( NOT NAK_Sent ) THEN
            BEGIN
               NAK_Sent := TRUE;
               Send_NAK;
            END;

         IF From_Send_Packet THEN
            BEGIN
               Got_Packet := FALSE;
               Do_Exit    := TRUE;
            END
         ELSE
            State := R_Get_DLE;

      END;

END   (* Do_R_Timed_Out *);

(*----------------------------------------------------------------------*)

PROCEDURE Do_R_Send_ACK;

BEGIN (* Do_R_Send_ACK *)
{
IF Debug_Mode THEN
   Write_Log('   R_Send_ACK State', FALSE, FALSE );
}
   Send_ACK;

   NAK_Sent := FALSE;              (* Start with clean slate  *)
   State    := R_Get_DLE;          (* wait for the next block *)

END   (* Do_R_Send_ACK *);

(*----------------------------------------------------------------------*)

PROCEDURE Do_R_Success;

BEGIN (* Do_R_Success *)
{
IF Debug_Mode THEN
   Write_Log('   R_Success State', FALSE, FALSE );
}
   Seq_Num     := Block_Num;
   R_Size      := I;
   Got_Packet  := TRUE;

END   (* Do_R_Success *);

(*----------------------------------------------------------------------*)

BEGIN (* Read_Packet *)
                                   (* No packet received yet *)
   Got_Packet := FALSE;
                                   (* Fill received packet with 0s *)

   FillChar( R_Buffer, Buffer_Size, 0 );

                                   (* Get sequence number of next packet *)

   Next_Seq := SUCC( Seq_Num ) MOD 10;

                                   (* No errors yet *)
   Errors   := 0;
                                   (* No NAK sent yet *)
   NAK_Sent := FALSE;
                                   (* Increment packets received count *)
   INC( Total_Packets );
                                   (* Get starting state *)
   IF Lead_In_Seen THEN
      State := R_Get_Seq
   ELSE
      State := R_Get_DLE;
                                   (* Get the packet! *)
   Do_Exit := FALSE;

   WHILE ( NOT ( Halt_Transfer OR Got_Packet OR Do_Exit ) )  DO
      BEGIN
                                   (* Set long timer *)
         Timer := 300;
                                   (* Check keyboard input *)
         Check_KeyBoard;

         CASE State OF

            R_Get_DLE      : Do_R_Get_DLE      (* Look for leading DLE     *);
            R_Get_B        : Do_R_Get_B        (* Look for 'B' packet type *);
            R_Get_Seq      : Do_R_Get_Seq      (* Get sequence number      *);
            R_Get_Data     : Do_R_Get_Data     (* Get data                 *);
            R_Get_CheckSum : Do_R_Get_CheckSum (* Get checksum/CRC         *);
            R_Timed_Out    : Do_R_Timed_Out    (* Handle time out          *);
            R_Send_ACK     : Do_R_Send_ACK     (* Send ACK                 *);
            R_Success      : Do_R_Success      (* Handle received OK       *);

         END (* CASE *);

      END (* WHILE *);

   Read_Packet := Got_Packet AND ( NOT Halt_Transfer );

END   (* Read_Packet *);

(*----------------------------------------------------------------------*)
(*           Send_Data --- Send buffer-full of data to host             *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Data( Buffer_Number : INTEGER );

VAR
   I : INTEGER;

BEGIN (* Send_Data *)
                                   (* Choose send-ahead buffer *)

   WITH SA_Buf[ Buffer_Number ] DO
      BEGIN
                                   (* Initialize checksum *)

         IF ( Quick_B AND Use_CRC ) THEN
            CheckSum := -1
         ELSE
            CheckSum := 0;
                                   (* Send <DLE>B to start packet *)

         Async_Send( CHR( DLE ) );
         Async_Send( 'B' );
                                   (* Send sequence number of packet *)

         Async_Send( CHR( Seq + ORD('0') ) );

         Do_CheckSum( Seq + ORD('0') );

                                   (* Send data and get checksum/CRC *)
         FOR I := 0 TO Num DO
            BEGIN
               Send_Masked_Byte( Buf[ I ] );
               Do_CheckSum( Buf[ I ] );
            END;
                                   (* Send ETX to mark end of data *)

         Async_Send ( CHR( ETX ) );

         Do_CheckSum( ETX );
                                   (* Send Checksum or CRC *)

         IF ( Quick_B AND Use_CRC ) THEN
            Send_Masked_Byte( CheckSum SHR 8 );

         Send_Masked_Byte( CheckSum );

      END;

END   (* Send_Data *);

(*----------------------------------------------------------------------*)
(*           Incr_SA --- Increment send ahead slot number               *)
(*----------------------------------------------------------------------*)

FUNCTION Incr_SA( Old_Value : INTEGER ) : INTEGER;

BEGIN (* Incr_SA *)

   IF ( Old_Value = Max_SA ) THEN
      Incr_SA := 0
   ELSE
      Incr_SA := SUCC( Old_Value );

END   (* Incr_SA *);

(*----------------------------------------------------------------------*)
(*           Get_ACK --- Wait for ACK of packet from host               *)
(*----------------------------------------------------------------------*)

FUNCTION Get_ACK : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  Get_ACK is called to wait until the SA_Buf indicated by             *)
(*  SA_Next_to_ACK has been ACKed by the host.                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   State      : INTEGER;
   Errors     : INTEGER;
   Block_Num  : INTEGER;
   New_Cks    : INTEGER;
   Sent_ENQ   : BOOLEAN;
   Sent_NAK   : BOOLEAN;
   SA_Index   : INTEGER;
   Do_Exit    : BOOLEAN;
   Got_An_Ack : BOOLEAN;

(*----------------------------------------------------------------------*)

PROCEDURE Do_S_Get_DLE;

BEGIN (* Do_S_Get_DLE *)

   Timer := 300;

   IF Halt_Transfer THEN
      BEGIN

         Display_Message('Transfer terminated by keyboard request.',
                         Err_Mess_Line);

         Send_Failure('A');

         Do_Exit := TRUE;

      END
   ELSE
      IF ( NOT Read_Byte ) THEN
         State := S_Timed_Out
      ELSE IF ( Ch = DLE ) THEN
         State := S_Get_Num
      ELSE IF ( Ch = NAK ) THEN
         BEGIN
            INC( Errors );
            IF ( Errors > Max_Errors ) THEN
               Do_Exit := TRUE
            ELSE
               State := S_Send_Data;
         END
      ELSE IF ( Ch = ETX ) THEN
         State := S_Send_NAK;

END   (* Do_S_Get_DLE *);

(*----------------------------------------------------------------------*)

PROCEDURE Do_S_Get_Num;

BEGIN (* Do_S_Get_Num *)

   IF ( NOT Read_Byte ) THEN
      State := S_Timed_Out
   ELSE IF ( ( Ch >= ORD('0') ) AND ( Ch <= ORD('9') ) ) THEN
      BEGIN (* Received ACK *)

         Sent_ENQ  := FALSE;
         Sent_NAK  := FALSE;
         Block_Num := Ch - ORD('0');

         IF ( SA_Buf[SA_Next_to_ACK].Seq = Block_Num ) THEN
            BEGIN (* This is the one we're waiting for *)
               SA_Next_to_ACK := Incr_SA( SA_Next_to_ACK );
               DEC( SA_Waiting );
               Got_An_ACK := TRUE;
               Do_Exit    := TRUE;
            END
         ELSE IF ( SA_Buf[ Incr_SA( SA_Next_to_ACK ) ].Seq = Block_Num ) THEN
            BEGIN (* Must have missed an ACK *)
               SA_Next_to_ACK := Incr_SA (SA_Next_to_ACK);
               SA_Next_to_ACK := Incr_SA (SA_Next_to_ACK);
               DEC( SA_Waiting , 2 );
               Got_An_ACK := TRUE;
               Do_Exit    := TRUE;
            END
         ELSE IF ( SA_Buf[ SA_Next_to_ACK ].Seq = Incr_Seq( Block_Num ) ) THEN
            State := S_Get_DLE    (* Duplicate ACK *)
         ELSE
            State := S_Timed_Out;
      END (* Received ACK *)
   ELSE IF ( Ch = ORD('B') ) THEN
      State := S_Get_Packet        (* Try to receive a packet *)
   ELSE IF ( Ch = NAK ) THEN
      BEGIN
         INC( Errors );
         IF ( Errors > Max_Errors ) THEN
            Do_Exit := TRUE
         ELSE
            State := S_Send_Data
      END
   ELSE
      State := S_Timed_Out;

END   (* Do_S_Get_Num *);

(*----------------------------------------------------------------------*)

PROCEDURE Do_S_Get_Packet;

BEGIN (* Do_S_Get_Packet *)
                                   (* Read a packet *)

   IF Read_Packet( TRUE , TRUE ) THEN
      BEGIN
                                   (* If failure packet, send ACK *)
                                   (* but indicate we didn't get  *)
                                   (* ACK packet.                 *)

         IF ( R_Buffer[0] = ORD('F') ) THEN
            Send_ACK
         ELSE
            Got_An_ACK := TRUE;

         Do_Exit := TRUE;

      END
                                   (* On a bad receive, try again. *)
   ELSE
      State := S_Timed_Out;

END   (* Do_S_Get_Packet *);

(*----------------------------------------------------------------------*)

PROCEDURE Do_S_Timed_Out;

BEGIN (* Do_S_Timed_Out *)
                                   (* Increment error count *)
   INC( Errors );
                                   (* If too many time outs, quit *)
   IF ( Errors > 4 ) THEN
      Do_Exit := TRUE
                                   (* Send ENQ to wake up host if  *)
                                   (* we haven't already sent one. *)
   ELSE
      BEGIN

         IF ( NOT Sent_ENQ ) THEN
            BEGIN
               Send_ENQ;
               Sent_ENQ := TRUE;
            END;

         State := S_Get_DLE;

      END;

END   (* Do_S_Timed_Out *);

(*----------------------------------------------------------------------*)

PROCEDURE Do_S_Send_NAK;

BEGIN (* Do_S_Send_NAK *)
                                   (* Increment error count *)
   INC( Errors );
                                   (* If too many, quit. *)
   IF ( Errors > Max_Errors ) THEN
      Do_Exit    := TRUE
                                   (* If we didn't send NAK yet, *)
                                   (* send one.                  *)
   ELSE
      BEGIN

         IF ( NOT Sent_NAK ) THEN
            BEGIN
               Send_NAK;
               Sent_NAK := TRUE;
            END;

         State := S_Get_DLE;

      END;

END   (* Do_S_Send_NAK *);

(*----------------------------------------------------------------------*)

PROCEDURE Do_S_Send_Data;

VAR
   I : INTEGER;

BEGIN (* Do_S_Send_Data *)
                                   (* Get slot of data to send *)
   SA_Index := SA_Next_to_ACK;
                                   (* Send data *)
   FOR I := 1 TO SA_Waiting DO
      BEGIN
         Send_Data( SA_Index );
         SA_Index := Incr_SA( SA_Index );
      END;

   State    := S_Get_DLE;

   Sent_ENQ := FALSE;
   Sent_NAK := FALSE;

END   (* Do_S_Send_Data *);

(*----------------------------------------------------------------------*)

BEGIN (* Get_ACK *)

   Errors          := 0;
   Sent_ENQ        := FALSE;
   Sent_NAK        := FALSE;
   State           := S_Get_DLE;
                                   (* Increment packet count *)
   INC( Total_Packets );
                                   (* No ACK found yet *)
   Do_Exit    := FALSE;
   Got_An_ACK := FALSE;
                                   (* Loop looking for ACK *)

   WHILE ( NOT ( Halt_Transfer OR Do_Exit OR Got_An_ACK ) ) DO
      BEGIN
                                   (* Check keyboard input *)
         Check_Keyboard;
                                   (* Handle current ACK state *)
         CASE State OF

            S_Get_DLE    : Do_S_Get_DLE     (* Get initial <DLE> *);
            S_Get_Num    : Do_S_Get_Num     (* Get packet number *);
            S_Get_Packet : Do_S_Get_Packet  (* Get packet itself *);
            S_Timed_Out  : Do_S_Timed_Out   (* Handle time out   *);
            S_Send_NAK   : Do_S_Send_NAK    (* Send NAK to host  *);
            S_Send_Data  : Do_S_Send_Data   (* Send data to host *);

         END (* CASE *);

      END (* WHILE *);

   Get_ACK := Got_An_ACK;

END   (* Get_ACK *);

(*----------------------------------------------------------------------*)
(*           Send_Packet --- Send packet to host                        *)
(*----------------------------------------------------------------------*)

FUNCTION Send_Packet( Size : INTEGER ) : BOOLEAN;

BEGIN (* Send_Packet *)
                                   (* If window full, look for ACK *)
                                   (* to open slot.  If not found, *)
                                   (* don't send this packet.      *)

   IF ( SA_Waiting = SA_Max ) THEN
      IF ( NOT Get_ACK ) THEN
         BEGIN
            Send_Packet := FALSE;
            EXIT;
         END;
                                   (* Get next slot and fill in size, *)
                                   (* sequence number of packet.      *)

   Seq_Num                     := Incr_Seq( Seq_Num );
   SA_Buf[SA_Next_to_Fill].Seq := Seq_Num;
   SA_Buf[SA_Next_to_Fill].Num := Size;

                                   (* Send the data. *)
   Send_Data( SA_Next_to_Fill );
                                   (* Get slot to be filled next. *)

   SA_Next_to_Fill := Incr_SA( SA_Next_to_Fill );

                                   (* Increment count of packets *)
                                   (* waiting for ACK            *)
   INC( SA_Waiting );

   Send_Packet     := TRUE;

END   (* Send_Packet *);

(*----------------------------------------------------------------------*)
(*           SA_Flush --- Synchronize last packet with host             *)
(*----------------------------------------------------------------------*)

FUNCTION SA_Flush : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  SA_Flush is called after sending the last packet to get host's      *)
(*  ACKs on outstanding packets.                                        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* SA_Flush *)

   WHILE( SA_Waiting <> 0 ) DO
      IF ( NOT Get_ACK ) THEN
         BEGIN
            SA_Flush := FALSE;
            EXIT;
         END;

   SA_Flush := TRUE;

END   (* SA_Flush *);

(*----------------------------------------------------------------------*)
(*           Send_Failure --- Send failure code to host                 *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Failure (* Code : CHAR *);

VAR
   Dummy : BOOLEAN;

BEGIN (* Send_Failure *)
                                   (* Reinitialize send-ahead variables *)
   SA_Next_to_ACK  := 0;
   SA_Next_to_Fill := 0;
   SA_Waiting      := 0;
                                   (* Prepare failure packet *)
   WITH SA_Buf[0] DO
      BEGIN
         Buf[0] := ORD( 'F'  );
         Buf[1] := ORD( Code );
      END;
                                   (* Send failure packet and wait *)
                                   (* for host to ACK it           *)
   IF Send_Packet( 1 ) THEN
      Dummy := SA_Flush;

END   (* Send_Failure *);

(*----------------------------------------------------------------------*)
(*           Read_File --- Read data from file being sent out           *)
(*----------------------------------------------------------------------*)

FUNCTION Read_File( VAR Data_File : FILE;
                    VAR S_Buffer  : BufferType;
                    N             : INTEGER;
                    Xmt_Size      : INTEGER ) : INTEGER;

VAR
   L : INTEGER;

BEGIN (* Read_File *)

   BlockRead( Data_File, S_Buffer[N], Xmt_Size, L );

   Read_File := L;

END    (* Read_File *);

(*----------------------------------------------------------------------*)
(*           Send_File --- Handle file sending using CISB B             *)
(*----------------------------------------------------------------------*)

FUNCTION Send_File( Name : AnyStr ) : BOOLEAN;

VAR
   N         : INTEGER;
   Data_File : FILE;
   IO_Error  : INTEGER;
   Cps_S     : STRING[10];
   CPS       : INTEGER;
   Send_Mess : AnyStr;
   Open_OK   : BOOLEAN;

LABEL Error;

BEGIN (* Send_File *)
                                   (* Assume send fails        *)
   Send_File := FALSE;

   FileMode := 0;

   ASSIGN( Data_File , Name );
   RESET ( Data_File , 1    );

   FileMode := 2;

   IO_Error := Int24Result;
                                   (* If file can't be opened, halt *)
                                   (* transfer.                     *)

   IF ( IO_Error <> 0 ) THEN
      BEGIN
         Send_Failure('E');
         Display_Message('Can''t open file to be sent, transfer stopped.',
                         Err_Mess_Line);
         TFile_Size := 0;
         GOTO Error;
      END;
                                   (* Remember file size *)

   TFile_Size := FileSize( Data_File );

   STR( TFile_Size , Cps_S );
   Write_Log('Size of file to send is ' + Cps_S + ' bytes' , TRUE, FALSE );

                                   (* Remember starting time for transfer *)
   Starting_Time := TimeOfDay;

   REPEAT
                                   (* Read next sector of data *)

      WITH SA_Buf[ SA_Next_to_Fill ] DO
         BEGIN
            Buf[0] := ORD('N');
            N      := Read_File( Data_File, Buf, 1, Buffer_Size );
         END;

     IF ( Int24Result <> 0 ) THEN
        BEGIN
           N             := -1;
           Halt_Transfer := TRUE;
        END;
                                   (* Send data packet if anything *)
                                   (* to send.                     *)
      IF ( N > 0 ) THEN
         BEGIN
                                   (* If packet not sent, report *)
                                   (* failure.                   *)
            INC( Total_Blocks    );
            INC( Total_Bytes , N );

            IF ( NOT Send_Packet( N ) ) THEN
               BEGIN
                  Display_Message('Can''t send packet, transfer stopped.',
                                  Err_Mess_Line);
                  Halt_Transfer := TRUE;
               END;

         END;
                                   (* Check for keyboard input halting *)
                                   (* transfer.                        *)

      IF ( NOT Halt_Transfer ) THEN
         BEGIN

            Check_Keyboard;

            IF Halt_Transfer THEN
               BEGIN
                  Send_Failure('E');
                  Display_Message('Transfer terminated by keyboard request.',
                                  Err_Mess_Line);
               END;

         END;

      Update_B_Display;

   UNTIL ( N <= 0 ) OR Halt_Transfer;

   IF ( N < 0 ) THEN
      BEGIN (* Read failure *)
         Send_Failure('E');
         Display_Message('Error reading file, transfer stopped.',
                         Err_Mess_Line);
      END   (* Read failure *);

                                   (* Close file *)
   Ending_Time := TimeOfDay;

   CLOSE( Data_File );

   IO_Error := Int24Result;

   IF ( NOT Halt_Transfer ) THEN
      BEGIN
                                   (* Send end of file packet. *)

         WITH SA_Buf[ SA_Next_to_Fill ] DO
            BEGIN
               Buf[0] := ORD('T');
               Buf[1] := ORD('C');
            END;

         IF ( NOT Send_Packet( 2 ) ) THEN
            Display_Message('Can''t send end of file packet, transfer stopped.',
                            Err_Mess_Line )
         ELSE
            BEGIN
               IF SA_Flush THEN
                  BEGIN
                     Send_File  := TRUE;
                     Total_Time := TimeDiff( Starting_Time , Ending_Time );
                     Send_Mess  := 'Send complete.';
                     IF ( Total_Time > 0 ) THEN
                        BEGIN
                           CPS := TRUNC( Total_Bytes / Total_Time );
                           STR( CPS , Cps_S );
                           Send_Mess := Send_Mess + ' Transfer rate: ' + Cps_S +
                                        ' CPS.';
                        END;
                     Display_Message( Send_Mess , Err_Mess_Line );
                 END;
            END;

      END;
                                   (* Reset serial port if necessary *)
Error:
   IF Reset_Port THEN
      Async_Reset_Port( Comm_Port, Baud_Rate,
                        Xmodem_Parity_Save,
                        Xmodem_Bits_Save,
                        Xmodem_Stop_Save );

   Reset_Port := FALSE;

   Window_Delay;

END    (* Send_File *);

(*----------------------------------------------------------------------*)
(*   Do_Transport_Parameters --- Handle '+' packet for Quick B settings *)
(*----------------------------------------------------------------------*)

PROCEDURE Do_Transport_Parameters;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  Do_Transport_Parameters is called when a Packet type of + is        *)
(*  received.  It sends a packet of our local Quick B parameters and    *)
(*  sets the Our_xx parameters to the minimum of the sender's and our   *)
(*  own parameters.                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Do_Transport_Parameters *)

                                   (* Pick out sender's parameters *)
   His_WS := R_Buffer[1];
   His_WR := R_Buffer[2];
   His_BS := R_Buffer[3];
   His_CM := R_Buffer[4];
                                   (* Prepare to return our own parameters *)
   WITH SA_Buf[SA_Next_to_Fill] DO
      BEGIN
         Buf[0] := ORD('+');
         Buf[1] := Def_WS;
         Buf[2] := Def_WR;
         Buf[3] := Def_BS;
         Buf[4] := Def_CM;
         Buf[5] := Def_DQ;
      END;

   IF ( NOT Send_Packet( 5 ) ) THEN
      EXIT;

   IF SA_Flush THEN                 (* Wait for host's ACK on our packet *)
      BEGIN
                                    (* ** Take minimal subset of Transport Params. **  *)

                                    (* If he can send ahead, we can receive it. *)

         Our_WR := MIN( His_WS , Def_WR );

                                    (* If he can receive send ahead, we can send it. *)

         Our_WS := MIN( His_WR , Def_WS );
         Our_BS := MIN( His_BS , Def_BS );
         Our_CM := MIN( His_CM , Def_CM );

                                    (* Set Our_BS = 4 as default if not given *)
         IF ( Our_BS = 0 ) THEN
            Our_BS := 4;
                                    (* Set buffer size *)

         Buffer_Size := Our_BS * 128;

                                   (* Quick B protocol is available *)
         Quick_B := TRUE;
                                   (* Set CRC mode *)
         Use_CRC := ( Our_CM = 1 );

         IF ( Our_WS <> 0 ) THEN
            BEGIN
               SA_Enabled := TRUE;
               SA_Max     := Max_SA;
            END;

      END;
                                   (* Reinitialize display with new params *)
   Initialize_Transfer_Display;

END   (* Do_Transport_Parameters *);

(*----------------------------------------------------------------------*)
(*   Do_Application_Parameters --- Handle '?' packet                    *)
(*----------------------------------------------------------------------*)

PROCEDURE Do_Application_Parameters;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  Do_Application_Parameters is called when a ? packet is received.    *)
(*  This version ignores the host's packet and returns a ? packet       *)
(*  saying that normal B Protocol File Transfer is supported.           *)
(*  (Well, actually it says that no extended application packets are    *)
(*  supported.  The T packet is assumed to be standard.)                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Dummy : BOOLEAN;

BEGIN (* Do_Application_Parameters *)

   WITH SA_Buf[ SA_Next_to_Fill ] DO
      BEGIN
         Buf[0] := ORD('?');       (* Build the ? packet *)
         Buf[1] := 1;              (* The T packet flag  *)
      END;

   IF Send_Packet( 1 ) THEN              (* Send the packet *)
      Dummy := SA_Flush;

END   (* Do_Application_Parameters *);

(*----------------------------------------------------------------------*)
(*            Write_File --- Write received data to PC file             *)
(*----------------------------------------------------------------------*)

FUNCTION Write_File( VAR Data_File : FILE;
                         R_Buffer  : BufferType;
                         N         : INTEGER;
                         Size      : INTEGER) : INTEGER;

VAR
   Size_Written : INTEGER;

BEGIN (* Write_File *)

   BlockWrite( Data_File, R_Buffer[ N ], Size, Size_Written );
   Write_File := Size_Written;

END   (* Write_File *);

(*----------------------------------------------------------------------*)
(*            Receive_File --- Handle file reception using CIS B        *)
(*----------------------------------------------------------------------*)

FUNCTION Receive_File( Name : AnyStr ) : BOOLEAN;

VAR
   Data_File : FILE;
   Status    : INTEGER;
   R_File    : BOOLEAN;
   Cps_S     : STRING[10];
   CPS       : INTEGER;
   Rec_Mess  : AnyStr;

LABEL  Error;

BEGIN (* Receive_File *)
                                   (* Assume transfer fails   *)
   R_File := FALSE;
                                   (* Open file to be created *)

   Add_Path( Name, Download_Dir_Path, Name );

   ASSIGN ( Data_File , Name );
   REWRITE( Data_File , 1  );
                                   (* Halt transfer if file can't be *)
                                   (* opened.                        *)
   Status := Int24Result;

   IF ( Status <> 0 ) THEN
      BEGIN
         Send_Failure('E');
         Display_Message('Can''t open output file, transfer stoppped.',
                         Err_Mess_Line);
         Receive_File := FALSE;
         GOTO Error;
      END;
                                   (* Send ACK to start transfer  *)
   Send_ACK;
                                   (* Remember starting time for transfer *)
   Starting_Time := TimeOfDay;
                                   (* Begin loop over packets *)

   WHILE ( NOT ( Halt_Transfer OR R_File  ) ) DO
      BEGIN
                                   (* Get next packet *)

         IF Read_Packet( FALSE , FALSE ) THEN
            BEGIN
                                   (* Select Action based upon packet type *)

               CASE CHR( R_Buffer[0] ) OF

                                   (* Data for file -- write it and *)
                                   (* acknowledge it.               *)
                  'N': BEGIN
                          Status := Write_File( Data_File, R_Buffer, 1,
                                                PRED( R_Size ) );

                          IF ( Int24Result <> 0 ) THEN
                             BEGIN
                                Display_Message('** Write failure...aborting',
                                                Err_Mess_Line);
                                ClrEol;
                                Send_Failure ('E');
                                Halt_Transfer := TRUE;
                             END
                          ELSE
                             BEGIN
                                Send_ACK;
                                Total_Blocks := Total_Blocks + 1;
                                Total_Bytes  := Total_Bytes  + R_Size - 1;
                             END;
                       END;

                                   (* End of transfer -- close file *)
                                   (* and acknowledge end of file   *)
                  'T': BEGIN

                          IF ( R_Buffer[1] = ORD('C') ) THEN
                             BEGIN
                                Ending_Time  := TimeOfDay;
                                CLOSE( Data_File );
                                Status := Int24Result;
                                IF ( Status <> 0 ) THEN
                                   BEGIN
                                      Display_Message('** Failure during close...aborting',
                                                      Err_Mess_Line);
                                      Send_Failure ('E');
                                      Halt_Transfer := TRUE;
                                   END
                                ELSE
                                   BEGIN
                                      Send_ACK;
                                      R_File  := TRUE;
                                      Total_Time := TimeDiff( Starting_Time ,
                                                              Ending_Time );
                                      Rec_Mess   := 'Receive complete.';
                                      STR( Total_Bytes , Cps_S );
                                      Write_Log('Size of file received was ' + Cps_S +
                                                ' bytes' , TRUE, FALSE );
                                      IF ( Total_Time > 0 ) THEN
                                         BEGIN
                                            CPS := TRUNC( Total_Bytes / Total_Time );
                                            STR( CPS , Cps_S );
                                            Rec_Mess := Rec_Mess + ' Transfer rate: ' + Cps_S +
                                                        ' CPS.';
                                         END;

                                      Display_Message( Rec_Mess , Err_Mess_Line );
                                   END;

                             END;

                       END;
                                   (* Stop transfer received -- halt *)
                                   (* transfer and acknowledge.      *)
                  'F': BEGIN
                          Send_ACK;
                          Halt_Transfer := TRUE;
                          Display_Message('Host cancelled transfer.', Err_Mess_Line);
                       END;

                END   (* CASE *);

            END  (* IF *)
         ELSE
            BEGIN (* No packet received *)
               Halt_Transfer := TRUE;
               Display_Message('Failed to received packet, transfer aborted.',
                               Err_Mess_Line);
               ClrEol;
            END   (* No packet received *);

                                   (* Check for keyboard input halting *)
                                   (* transfer.                        *)

         IF ( NOT Halt_Transfer ) THEN
            BEGIN

               Check_Keyboard;

               IF Halt_Transfer THEN
                  BEGIN
                     Send_Failure('E');
                     Display_Message('Transfer terminated by keyboard request.',
                                     Err_Mess_Line);
                     ClrEol;
                  END;

            END;

      END  (* WHILE *);

   Receive_File := R_File AND ( NOT Halt_Transfer );
   Ending_Time  := TimeOfDay;
                                   (* Close received file *)
   CLOSE( Data_File );

   Status := Int24Result;
                                   (* If we are to delete partially *)
                                   (* received files, do so.        *)

   IF ( ( NOT R_File ) AND Evict_Partial_Trans ) THEN
      ERASE( Data_File );

   Status := Int24Result;

Error:
   IF Reset_Port THEN
      Async_Reset_Port( Comm_Port, Baud_Rate,
                        Xmodem_Parity_Save,
                        Xmodem_Bits_Save,
                        Xmodem_Stop_Save );
   Reset_Port := FALSE;

   Window_Delay;

END   (* Receive_File *);

(*----------------------------------------------------------------------*)
(*            CISB_DLE_Seen --- M A I N   R O U T I N E                 *)
(*----------------------------------------------------------------------*)

BEGIN (* CISB_DLE_Seen *)
                                   (* Begin by getting the next character.  *)
                                   (* If it is <B> then enter the           *)
                                   (* B_Protocol State.  Otherwise simply   *)
                                   (* return.                               *)
   Timer         := 10;
   Halt_Transfer := FALSE;

   IF ( NOT Read_Byte ) THEN
      EXIT
   ELSE IF ( Ch <> ORD('B') ) THEN
      EXIT;
                                   (* Initialize send-ahead variables *)
   SA_Next_to_ACK  := 0;
   SA_Next_to_Fill := 0;
   SA_Waiting      := 0;
                                   (* Reset comm parms to 8,n,1 if we aren't *)
                                   (* set to that already.                   *)
   Xmodem_Bits_Save   := Data_Bits;
   Xmodem_Parity_Save := Parity;
   Xmodem_Stop_Save   := Stop_Bits;

   IF ( ( Data_Bits = 8 ) AND ( Parity = 'N' ) ) THEN
      Reset_Port := FALSE
   ELSE
      BEGIN
         Async_Reset_Port( Comm_Port, Baud_Rate, 'N', 8, 1 );
         Reset_Port := TRUE;
         IF Do_Status_Line THEN
            BEGIN
               Set_Status_Line_Name( Short_Terminal_Name );
               Write_To_Status_Line( Status_Line_Name, 1 );
            END;
      END;
                                   (* Announce protocol starts *)

   Save_Partial_Screen( Saved_Screen, 5, 10, 75, 20 );

   Comp_Title := 'CompuServe B Protocol';

   Receiving_File := TRUE;

   Initialize_Transfer_Display;

   Halt_Transfer  := FALSE;
   Receiving_File := TRUE;
   Display_Status := TRUE;
   Comp_Title     := 'CIS B -- ';
   Total_Blocks   := 0;
   Total_Packets  := 0;
   Total_Errors   := 0;
   Total_Bytes    := 0;
                                   (* Read initial packet *)

   IF Read_Packet( TRUE , FALSE ) THEN
      BEGIN
                                   (* Select Action based upon packet type *)

         CASE CHR( R_Buffer[0] ) OF

                                   (* Upload or download *)
            'T': BEGIN

                    CASE CHR( R_Buffer[1] ) OF
                       'D' : BEGIN
                                Comp_Title := 'Receiving ';
                                Receiving_File := TRUE;
                             END;
                       'U' : BEGIN
                                Comp_Title := 'Sending ';
                                Receiving_File := FALSE;
                             END;
                       ELSE
                             BEGIN
                                Send_Failure('N');
                                GOTO Error_Exit;
                             END;
                    END  (* CASE *);

                                   (* Get file name *)

                    CASE CHR( R_Buffer[2] ) OF
                       'A': Comp_Title := Comp_Title + 'ASCII file "';
                       'B': Comp_Title := Comp_Title + 'Binary file "';
                       ELSE
                          BEGIN
                             Send_Failure('N');        (* Not implemented *)
                             GOTO Error_Exit;
                          END;
                    END   (* CASE *);

                    I        := 2;
                    FileName := '';

                    WHILE ( R_Buffer[I] <> 0 ) AND ( I < R_Size ) DO
                       BEGIN
                          INC( I );
                          FileName := FileName + CHR( R_Buffer[I] );
                       END;

                    Comp_Title := Comp_Title + FileName + '"';

                                   (* Display file transfer header *)

                    Initialize_Transfer_Display;

                                   (* Perform transfer *)

                    IF ( R_Buffer[1] = ORD('U') ) THEN
                       Dummy := Send_File( FileName )
                    ELSE
                       Dummy := Receive_File( FileName );

                 END;
                                   (* Received Transport Parameters Packet *)

            '+': Do_Transport_Parameters;

                                   (* Received Application Parameters Packet *)

            '?': Do_Application_Parameters;

                                   (* Unknown packet; tell the host we don't know *)
            ELSE Send_Failure ('N');

         END (* CASE *);

      END (* BEGIN *)
                                   (* No initial packet -- quit *)
    ELSE
       BEGIN
          Display_Message('Can''t get first packet, transfer cancelled',
                          Err_Mess_Line);
          IF Reset_Port THEN
             Async_Reset_Port( Comm_Port, Baud_Rate, Xmodem_Parity_Save,
                               Xmodem_Bits_Save, Xmodem_Stop_Save );
          Reset_Port := FALSE;
          Window_Delay;
       END;

Error_Exit:
                                   (* Reset comm parms back *)
   IF Reset_Port THEN
      Async_Reset_Port( Comm_Port, Baud_Rate, Xmodem_Parity_Save,
                        Xmodem_Bits_Save, Xmodem_Stop_Save );

   IF Do_Status_Line THEN
      BEGIN
         Set_Status_Line_Name( Short_Terminal_Name );
         Write_To_Status_Line( Status_Line_Name, 1 );
      END;
                                   (* Restore previous screen *)

   Restore_Screen_And_Colors( Saved_Screen );

                                   (* Restore cursor *)
   CursorOn;

END   (* CISB_DLE_Seen *);
