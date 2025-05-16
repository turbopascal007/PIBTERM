(*----------------------------------------------------------------------*)
(*        Do_Keyboard_Checks --- Check keyboard for activity            *)
(*----------------------------------------------------------------------*)

PROCEDURE Do_Keyboard_Checks;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Do_Keyboard_Checks                                   *)
(*                                                                      *)
(*     Purpose:    Check keyboard for activity                          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Do_Keyboard_Checks;                                           *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Async_Flush_Output_Buffer                                     *)
(*        Handle_Function_Key                                           *)
(*        Flip_Display_Status                                           *)
(*        Write_To_Status_Line                                          *)
(*        Print_Spooled_File                                            *)
(*        Async_Send                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   A_Ch : CHAR;

BEGIN (* Do_Keyboard_Checks *)
                                   (* Pick up keyboard entry, if any.     *)
   WHILE PibTerm_KeyPressed DO
      BEGIN

         Read_Kbd( A_Ch );
                                   (* If shift-tab, toggle transfer display *)

         IF ( ORD( A_Ch ) = ESC ) THEN
            IF PibTerm_KeyPressed THEN
               BEGIN

                  Read_Kbd( A_Ch );

                  IF ( ( ORD( A_Ch ) = ALT_R ) AND ( NOT Sending_File ) ) OR
                     ( ( ORD( A_Ch ) = ALT_S ) AND (     Sending_File ) ) THEN
                     A_Ch := ^K
                  ELSE IF ( ORD( A_Ch ) = Shift_Tab ) THEN
                     BEGIN
                        Flip_Display_Status;
                        A_Ch := CHR( 0 );
                     END
                  ELSE
                     Handle_Function_Key( A_Ch );

               END
            ELSE
               IF Async_XOff_Received THEN
                  BEGIN
                     IF ( NOT Kermit_Do_Sliding_Win ) THEN
                        Async_Flush_Output_Buffer;
                     Clear_XOFF_Received;
                  END;

         CASE A_Ch OF

            ^B:  BEGIN    (* Cancel current batch of files *)
                    Kermit_Abort       := TRUE;
                    Kermit_Abort_Level := All_Files;
                 END;

            ^F:  BEGIN    (* Cancel current file *)
                    Kermit_Abort       := TRUE;
                    Kermit_Abort_Level := One_File;
                 END;

            ^K:  BEGIN    (* Drop out of Kermit entirely *)
                    Kermit_Abort       := TRUE;
                    Kermit_Abort_Level := Entire_Protocol;
                 END;

            ^M,
            ^R:  BEGIN    (* Retry current packet *)
                    Kermit_Retry       := TRUE;
                    Async_Send( CHR( CR ) );
                 END;

            ELSE;

         END (* CASE *);

      END;
                                   (* Print character from spooled file *)
   IF Print_Spooling THEN
      Print_Spooled_File;
                                   (* If carrier dropped, quit *)

   IF ( NOT Async_Carrier_Detect ) THEN
      BEGIN
         Kermit_Abort       := TRUE;
         Kermit_Abort_Level := Entire_Protocol;
      END;

END   (* Do_Keyboard_Checks *);

(*----------------------------------------------------------------------*)
(*             Get_Char --- Get character for Kermit packet             *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Char( VAR Ch : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_Char                                             *)
(*                                                                      *)
(*     Purpose:    Gets character for Kermit packet                     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_Char( VAR Ch: INTEGER );                                  *)
(*                                                                      *)
(*           Ch --- returned character                                  *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Async_Receive_With_TimeOut                                    *)
(*        Async_Flush_Output_Buffer                                     *)
(*        Handle_Function_Key                                           *)
(*        Flip_Display_Status                                           *)
(*        Write_To_Status_Line                                          *)
(*        Print_Spooled_File                                            *)
(*        Async_Send                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Temp          : INTEGER;
   Rec_Stat_Flag : BOOLEAN;
   A_Ch          : CHAR;
   ITimer        : INTEGER;

BEGIN (* Get_Char *)

   Temp               := 0;
   Kermit_Abort       := FALSE;
   Kermit_Retry       := FALSE;
   Rec_Stat_Flag      := FALSE;
   Kermit_Abort_Level := No_Abort;

                                   (* Do fast check for character *)
                                   (* available before doing long *)
                                   (* check.                      *)

   IF ( Async_Buffer_Head <> Async_Buffer_Tail ) THEN
      BEGIN
         Rec_Stat_Flag := Async_Receive( A_Ch );
         Ch            := ORD( A_Ch );
         EXIT;
      END;
                                   (* Loop until char found from *)
                                   (* comm port or keyboard      *)
   REPEAT
                                   (* Pick up a character from comm port, *)
                                   (* if any.                             *)
      ITimer := 0;
                                   (* Break up timeout into 1-sec pieces  *)
      REPEAT
                                   (* Pick up a character                 *)
         INC( ITimer );

         Async_Receive_With_TimeOut( 1 , Ch );

                                   (* If we timed out, indicate retry *)
                                   (* should be done.                 *)
         IF ( Ch = TimeOut ) THEN
            BEGIN
               Kermit_Retry  := ( ITimer > His_TimeOut );
               Rec_Stat_Flag := FALSE;
               Ch            := 0;
            END
         ELSE
            Rec_Stat_Flag := TRUE;

      UNTIL( Rec_Stat_Flag OR Kermit_Retry );

   UNTIL ( Rec_Stat_Flag OR Kermit_Abort OR Kermit_Retry );

                                   (* Make sure to check for carrier *)
                                   (* drop if we timed out.          *)
   IF Kermit_Retry THEN
      Do_Keyboard_Checks;

END   (* Get_Char *);

(*----------------------------------------------------------------------*)
(*                Receive_Packet --- Receive Kermit packet              *)
(*----------------------------------------------------------------------*)

PROCEDURE Receive_Packet;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Receive_Packet                                       *)
(*                                                                      *)
(*     Purpose:    Gets Kermit packet                                   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Receive_Packet;                                               *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Get_Char                                                      *)
(*        Get_P_Length                                                  *)
(*        Kermit_Chk8                                                   *)
(*        Kermit_Chk12                                                  *)
(*        Kermit_CRC                                                    *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        A Kermit packet starts with an SOH character, followed by a   *)
(*        packet length, then the block number MOD 64, then the packet  *)
(*        data, and finally a checksum or crc.                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Rec_Char          : INTEGER;
   B_Rec_Char        : BYTE;
   Temp              : INTEGER;
   Check_Char        : CHAR;
   Check_OK          : BOOLEAN;
   CheckSum          : INTEGER;
   Count             : INTEGER;
   Index             : INTEGER;
   StrNum            : STRING[3];
   Chk1              : CHAR;
   Chk2              : CHAR;
   Chk3              : CHAR;
   Check_Type        : INTEGER;
   L_Packet          : INTEGER;
   Rec_Pos           : INTEGER;
   Echoed_Packet     : BOOLEAN;
   Long_Packet       : BOOLEAN;
   Long_Packet_Found : BOOLEAN;
   Packet_For_Debug  : AnyStr;

(*----------------------------------------------------------------------*)
(*             Get_P_Length --- Get length of Kermit packet             *)
(*----------------------------------------------------------------------*)

FUNCTION Get_P_Length : BOOLEAN;

BEGIN (* Get_P_Length *)

   Get_P_Length      := TRUE;
   Long_Packet       := FALSE;
   Long_Packet_Found := FALSE;
   L_Packet          := 0;
                                   (* If next char is not SOH, it must *)
                                   (* be length.  If 0, then this is a *)
                                   (* long packet.                     *)

   IF NOT ( Kermit_Abort OR Kermit_Retry ) THEN
      BEGIN
         Get_Char( Rec_Char );
         IF ( Rec_Char = ORD( Kermit_Header_Char ) ) THEN
            BEGIN
               Get_P_Length := FALSE;
               Count        := 2000;
            END
         ELSE
            BEGIN
                                   (* Get packet length *)

               Count    := Rec_Char - 32;
               L_Packet := Count;

                                   (* If length is zero, prepare to   *)
                                   (* process long (>94 chars) packet *)

               IF ( Count = 0 ) THEN
                  BEGIN
                     Long_Packet       := TRUE;
                     Long_Packet_Found := TRUE;
                     Count             := 5;
                  END;

            END
      END
   ELSE
      Count := 0;

   Do_Keyboard_Checks;

END (* Get_P_Length *);

(*----------------------------------------------------------------------*)
(*                Get_The_Packet --- Get Kermit packet                  *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_The_Packet;

VAR
   I: INTEGER;

BEGIN (* Get_The_Packet *)
                                   (* Wait for header character (SOH).  *)
                                   (* If autodownload, then SOH already *)
                                   (* found.                            *)
   IF Initial_SOH_Received THEN
      BEGIN
         Kermit_Abort         := FALSE;
         Kermit_Retry         := FALSE;
         Kermit_Abort_Level   := No_Abort;
         Rec_Char             := ORD( SOH );
      END
   ELSE
      REPEAT  (* get header character *)
         Get_Char( Rec_Char );
         Do_Keyboard_Checks;
      UNTIL ( ( Rec_Char = ORD( Kermit_Header_Char ) ) OR
               Kermit_Abort OR Kermit_Retry );

                                   (* Initialize packet *)

   Initial_SOH_Received := FALSE;
   Rec_Packet_Ptr       := ADDR( Sector_Data );
   Rec_Pos              := 1;
   Check_OK             := FALSE;
   Packet_OK            := FALSE;
   Echoed_Packet        := FALSE;
   Check_Type           := ORD( His_Chk_Type ) - ORD('0');
   CheckSum             := 0;
   Kermit_Packet_Type   := Unknown;

                                   (* Get packet length *)
   WHILE ( NOT Get_P_Length ) DO
      Rec_Pos := 1;
                                   (* Get rest of packet *)

   IF NOT ( Kermit_Abort OR Kermit_Retry ) THEN
      BEGIN (* NOT ( Abort OR Retry ) *)
         REPEAT
                                   (* Packet type and data *)
            Get_Char( Rec_Char );

            IF ( Rec_Char = ORD( Kermit_Header_Char ) ) THEN
               BEGIN  (* got new start of packet *)

                                   (* Packet is initially empty *)
                  REPEAT
                     Rec_Pos        := 1;

                  UNTIL Get_P_Length OR Kermit_Abort OR Kermit_Retry;

               END
            ELSE  (* must be a character *)
               BEGIN
                  INC( Rec_Pos );
                  Rec_Packet_Ptr^[Rec_Pos] := CHR( Rec_Char );
                  DEC( Count );
               END;

                                   (* If long packet and count is 0, *)
                                   (* process extended length and    *)
                                   (* keep on going.                 *)

            IF ( ( Count = 0 ) AND Long_Packet ) THEN
               BEGIN

                  CheckSum := 32 + ORD( Rec_Packet_Ptr^[2] ) +
                                   ORD( Rec_Packet_Ptr^[3] ) +
                                   ORD( Rec_Packet_Ptr^[4] ) +
                                   ORD( Rec_Packet_Ptr^[5] );

                  CheckSum := ( ( CheckSum + ( ( CheckSum AND 192 ) SHR 6 ) ) AND 63 );

                  Chk1     := CHR( CheckSum + 32 );

                  Check_OK := ( Chk1 = Rec_Packet_Ptr^[ 6 ] );

                                   (* If checksum on lengths bad,        *)
                                   (* set up to flush packet and return, *)
                                   (* else get extended length.          *)

                  IF ( NOT Check_OK ) THEN
                     BEGIN
                        Packet_OK          := FALSE;
                        Packets_Received   := Packets_Received + 1;
                        Update_Kermit_Display;
                        Kermit_Packet_Type := Unknown;
                        EXIT;
                     END
                  ELSE
                     BEGIN
                        Count       := 95 * ( ORD( Rec_Packet_Ptr^[4] ) - 32 ) +
                                            ( ORD( Rec_Packet_Ptr^[5] ) - 32 );
                        Long_Packet := FALSE;
                     END;

               END;

         UNTIL ( Kermit_Abort    OR
                 Kermit_Retry    OR
                 ( ( Count = 0 ) AND ( NOT Long_Packet ) ) );

                                   (* Check for keyboard input *)
      Do_Keyboard_Checks;
                                   (* Store length of packet  *)

      Rec_Packet_Length  := Rec_Pos;
      Rec_Packet_Ptr^[1] := CHR( L_Packet + 32 );

                                   (* Check if this looks like an *)
                                   (* echoed packet               *)

      IF ( ( Rec_Packet_Ptr^[2] = Send_Packet_Ptr^[3] ) AND
           ( Rec_Packet_Ptr^[3] = Send_Packet_Ptr^[4] ) ) THEN
         BEGIN
            Echoed_Packet := TRUE;
            EXIT;
         END;
                                   (* Update packets received *)

      Packets_Received := Packets_Received + 1;

                                   (* Update display *)
      Update_Kermit_Display;

      IF ( NOT Kermit_Abort ) THEN
         BEGIN  (* NOT Abort *)
                                   (* Compute and check checksum or crc *)

            CASE His_Chk_Type OF

               '1': BEGIN

                       Kermit_Chk8( Rec_Packet_Ptr^,
                                    Rec_Packet_Length - 1,
                                    CheckSum );

                       CheckSum := ( ( CheckSum + ( ( CheckSum AND 192 ) SHR 6 ) ) AND 63 );

                       Chk1     := CHR( CheckSum + 32 );

                       Check_OK := ( Chk1 = Rec_Packet_Ptr^[ Rec_Packet_Length ] );

                    END;

               '2': BEGIN

                       Kermit_Chk12( Rec_Packet_Ptr^,
                                     Rec_Packet_Length - 2,
                                     CheckSum );

                       Chk1 := CHR( CheckSum SHR 6  + 32 );
                       Chk2 := CHR( CheckSum AND 63 + 32 );

                       Check_OK := ( Chk1 = Rec_Packet_Ptr^[ Rec_Packet_Length - 1 ] ) AND
                                   ( Chk2 = Rec_Packet_Ptr^[ Rec_Packet_Length     ] );

                   END;

              '3': BEGIN

                      Kermit_CRC( Rec_Packet_Ptr^,
                                  Rec_Packet_Length - 3,
                                  CheckSum );

                      Chk1 := CHR( ( CheckSum SHR 12 ) AND 63  + 32 );
                      Chk2 := CHR( ( CheckSum SHR 6  ) AND 63  + 32 );
                      Chk3 := CHR( CheckSum AND 63             + 32 );

                      Check_OK := ( Chk1 = Rec_Packet_Ptr^[ Rec_Packet_Length - 2 ] ) AND
                                  ( Chk2 = Rec_Packet_Ptr^[ Rec_Packet_Length - 1 ] ) AND
                                  ( Chk3 = Rec_Packet_Ptr^[ Rec_Packet_Length     ] );

                  END;

            END (* CASE *);
                                   (* Get packet number *)

            Rec_Packet_Num := ORD( Rec_Packet_Ptr^[2] ) - 32;

                                   (* Set next state based upon packet type *)

            CASE Rec_Packet_Ptr^[3] OF
               'A' : Kermit_Packet_Type := Attrib_Pack;
               'B' : Kermit_Packet_Type := Break_Pack;
               'D' : Kermit_Packet_Type := Data_Pack;
               'E' : Kermit_Packet_Type := Error_Pack;
               'F' : Kermit_Packet_Type := Header_Pack;
               'G' : Kermit_Packet_Type := Generic_Pack;
               'H' : Kermit_Packet_Type := Host_Pack;
               'N' : Kermit_Packet_Type := NAK_Pack;
               'S' : Kermit_Packet_Type := Send_Pack;
               'T' : Kermit_Packet_Type := Reserved_Pack;
               'X' : Kermit_Packet_Type := Text_Pack;
               'Y' : Kermit_Packet_Type := ACK_Pack;
               'Z' : Kermit_Packet_Type := End_Pack;
               ELSE  Kermit_Packet_Type := Unknown;
            END (* CASE *);
                                   (* Strip type, #, checksum from packet *)

            IF Long_Packet_Found THEN
               Index := 6
            ELSE
               Index := 3;

            IF ( Rec_Packet_Length > ( Check_Type + Index ) ) THEN
               BEGIN
                  Rec_Packet_Ptr    := ADDR( Rec_Packet_Ptr^[Index + 1] );
                  Rec_Packet_Length := Rec_Packet_Length - Check_Type - Index;
               END;
                                    (* Set flag if packet OK *)

            IF ( Check_OK AND ( Kermit_Packet_Type <> Unknown ) ) THEN
               Packet_OK := TRUE;

         END  (* NOT Abort *);

      END  (* NOT ( Abort OR Retry ) *);
{
   IF Kermit_Debug THEN
      BEGIN
         Packet_For_Debug := '<';
         MOVE( Rec_Packet_Ptr^[1], Packet_For_Debug[2], Rec_Packet_Length );
         Packet_For_Debug[0] := CHR( Rec_Packet_Length + 1 );
         Packet_For_Debug := Packet_For_Debug + '>';
         Write_Log( '----- Get_The_Packet -----', FALSE, FALSE );
         Write_Log( Packet_For_Debug, TRUE, FALSE );
         Write_Log( 'Rec_Packet_Length = ' + IToS( Rec_Packet_Length ), TRUE, FALSE );
         Write_Log( 'Rec_Packet_Number = ' + IToS( Rec_Packet_Num    ), TRUE, FALSE );
         IF Echoed_Packet THEN
            Write_Log( 'Echoed packet', TRUE, FALSE )
         ELSE
            Write_Log( 'Not echoed packet', TRUE, FALSE );
         IF Kermit_Retry THEN
            Write_Log( 'Retry set', TRUE, FALSE )
         ELSE
            Write_Log( 'Retry not set', TRUE, FALSE );
         Write_Log( '------------------', FALSE, FALSE );
      END;
}

END   (* Get_The_Packet *);

(*----------------------------------------------------------------------*)

BEGIN (* Receive_Packet *)
                                   (* Get a packet *)
   Get_The_Packet;
                                   (* If this appears to be an echoed *)
                                   (* packet, try again.              *)

   IF Echoed_Packet AND ( NOT Kermit_Abort OR Kermit_Retry ) THEN
      Get_The_Packet;

END   (* Receive_Packet *);
