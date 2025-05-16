(*----------------------------------------------------------------------*)
(*     Kermit_Receive_File --- get file data from remote Kermit         *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Receive_File;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Kermit_Receive_File                                  *)
(*                                                                      *)
(*     Purpose:    Gets file data from remote Kermit                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Kermit_Receive_File;                                          *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This procedure receives file data from the remote Kermit      *)
(*        until a Break packet, and End packet, or an Unknown packet    *)
(*        is received.  It will also abort if there are too many        *)
(*        retries.                                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Try               : INTEGER;
   Save_Retry        : INTEGER;
   Data_Place        : INTEGER;
   Windowing_Started : BOOLEAN;

(*----------------------------------------------------------------------*)
(*             Send_Abort_Packet --- Send abort transfer request        *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Abort_Packet;

BEGIN (* Send_Abort_Packet *)
                                   (* Send appropriate abort packet *)
   CASE Kermit_Abort_Level OF

      One_File:         BEGIN
                           Send_Packet_Ptr^[4] := 'Y';
                           Send_Packet_Ptr^[5] := 'X';
                           Send_Packet_Length  := 5;
                           Display_Kermit_Message_2('Cancelling transfer of current file.');
                        END;

      Entire_Protocol:  BEGIN
                           Receive_Done       := TRUE;
                           Abort_Done         := TRUE;
                           Display_Kermit_Message_2('Cancelling entire protocol.');
                        END;

      All_Files:        BEGIN
                           Send_Packet_Ptr^[4] := 'Y';
                           Send_Packet_Ptr^[5] := 'Z';
                           Send_Packet_Length  := 5;
                           Display_Kermit_Message_2('Cancelling transfer of all files.');
                        END;
      ELSE
                        BEGIN
                           Send_Packet_Ptr^[4] := 'N';
                           Send_Packet_Length  := 4;
                        END;
   END (* CASE *);
                                   (* Construct and send abort packet *)

   IF ( Kermit_Abort_Level <> Entire_Protocol ) THEN
      BEGIN
         Build_Packet;
         Send_Packet;
      END;
                                   (* Ensure file tossed out *)
   Toss_File := TRUE;

END   (* Send_Abort_Packet *);

(*----------------------------------------------------------------------*)
(*   Kermit_Set_File_Date_And_Time  -- Set date and time on Kermit file *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Set_File_Date_And_Time;

VAR
   KDate : LONGINT;
   KDateW: ARRAY[1..2] OF WORD ABSOLUTE KDate;

BEGIN (* Kermit_Set_File_Date_And_Time *)

   KDateW[1] := Kermit_File_Time;
   KDateW[2] := Kermit_File_Date;

   SetFTime( XFile , KDate );

END   (* Kermit_Set_File_Date_And_Time *);

(*----------------------------------------------------------------------*)
(*           Handle_Attrib_Pack --- handle one attribute packet         *)
(*----------------------------------------------------------------------*)

PROCEDURE Handle_Attrib_Pack;

VAR
   InPos            : INTEGER;
   I                : INTEGER;
   J                : INTEGER;
   Len_Packet       : INTEGER;
   Rejected_Attribs : FileStr;
   L_Attrib         : INTEGER;
   L_Attrib_Last    : INTEGER;
   Attrib           : CHAR;
   Date_String      : STRING[10];
   Time_String      : STRING[10];
   Year             : INTEGER;
   Month            : INTEGER;
   Day              : INTEGER;
   Hour             : INTEGER;
   Mins             : INTEGER;
   Secs             : INTEGER;
   Size_String      : STRING[10];

(*----------------------------------------------------------------------*)

FUNCTION Get_Number( S: AnyStr ) : INTEGER;

VAR
   J   : INTEGER;
   Sum : INTEGER;

BEGIN (* Get_Number *)

   Sum := 0;

   FOR J := 1 TO LENGTH( S ) DO
      Sum := Sum * 10 + ORD( S[J] ) - ORD('0');

   Get_Number := Sum;

END   (* Get_Number *);

(*----------------------------------------------------------------------*)

PROCEDURE Extract_File_Date;

BEGIN (* Extract_File_Date *)

   Date_String      := '';
   Kermit_File_Date := 0;
                                   (* Extract date string *)

   WHILE ( ( I <= L_Attrib_Last ) AND ( Rec_Packet_Ptr^[I] <> ' ' ) ) DO
      BEGIN
         Date_String := Date_String + Rec_Packet_Ptr^[I];
         INC( I );
      END;
                                   (* Pull apart date string.          *)
                                   (* Note:  year may be 2 or 4 digits *)

   IF ( LENGTH( Date_String ) = 6 ) THEN
      BEGIN
         Year  := Get_Number( Date_String[1] + Date_String[2] ) + 1900;
         Month := Get_Number( Date_String[3] + Date_String[4] );
         Day   := Get_Number( Date_String[5] + Date_String[6] );
      END
   ELSE IF ( LENGTH( Date_String ) = 8 ) THEN
      BEGIN
         Year  := Get_Number( COPY( Date_String, 1, 4 ) );
         Month := Get_Number( Date_String[5] + Date_String[6] );
         Day   := Get_Number( Date_String[7] + Date_String[8] );
      END
   ELSE
      BEGIN
         Year  := 0;
         Month := 0;
         Day   := 0;
      END;
                                   (* Convert date to DOS form *)

   Kermit_File_Date := MAX( Year - 1980 , 0 ) SHL 9 + Month SHL 5 + Day;

   Kermit_Do_File_Date := ( Kermit_File_Date <> 0 );
{
   IF Kermit_Debug THEN
      BEGIN
         Write_Log('Date_String = <' + Date_String + '>', FALSE, FALSE );
         IF Kermit_Do_File_Date THEN
            Write_Log( 'Do_Date = YES', FALSE, FALSE )
         ELSE
            Write_Log( 'Do_Date = NO', FALSE, FALSE );
         Write_Log('   I        = ' + IToS( I ), FALSE, FALSE );
         Write_Log('   L_Attrib_Last = ' + IToS( L_Attrib_Last ), FALSE, FALSE );
      END;
}
END   (* Extract_File_Date *);

(*----------------------------------------------------------------------*)

PROCEDURE Extract_File_Time;

BEGIN (* Extract_File_Time *)

   Time_String      := '';
   Kermit_File_Time := 0;
{
   IF Kermit_Debug THEN
      BEGIN
         Write_Log('Extract_File_Time', FALSE, FALSE );
         Write_Log('   I        = ' + IToS( I ), FALSE, FALSE );
         Write_Log('   L_Attrib_Last = ' + IToS( L_Attrib_Last ), FALSE, FALSE );
      END;
}
   IF ( I < L_Attrib_Last ) THEN
      BEGIN
         IF ( Rec_Packet_Ptr^[I] = ' ' ) THEN
            INC( I );
         WHILE ( I <= L_Attrib_Last ) DO
            BEGIN
               Time_String := Time_String + Rec_Packet_Ptr^[I];
               INC( I );
            END;
      END;
                                   (* Pull apart time string.  *)
   IF ( Time_String <> '' ) THEN
      BEGIN

         Hour  := Get_Number( Time_String[1] + Time_String[2] );
         Mins  := Get_Number( Time_String[4] + Time_String[5] );

         IF ( LENGTH( Time_String ) > 5 ) THEN
            Secs  := Get_Number( Time_String[7] + Time_String[8] )
         ELSE
            Secs  := 0;
                                   (* Convert time to DOS form *)

         Kermit_File_Time := Hour SHL 11 OR Mins SHL 5 OR ( Secs DIV 2 );

         Kermit_Do_File_Time := TRUE;

      END;
{
   IF Kermit_Debug THEN
      BEGIN
         Write_Log('Time_String = <' + Time_String + '>', FALSE, FALSE );
         IF Kermit_Do_File_Time THEN
            Write_Log( 'Do_Time = YES', FALSE, FALSE )
         ELSE
            Write_Log( 'Do_Time = NO', FALSE, FALSE );
      END;
}
END   (* Extract_File_Time *);

(*----------------------------------------------------------------------*)

BEGIN (* Handle_Attrib_Pack *)
                                   (* Start of received packet     *)
   InPos            := 1;
   Len_Packet       := Rec_Packet_Length;
   Rejected_Attribs := '';
{
   IF Kermit_Debug THEN
      Write_Log('Attribute packet = <' +
                COPY( Rec_Packet_Ptr^, 1, Rec_Packet_Length ) +
                '>', FALSE, FALSE );
}
                                   (* Pick up attributes           *)
   WHILE ( InPos < Len_Packet ) DO
      BEGIN

         Attrib        := Rec_Packet_Ptr^[InPos];
         L_Attrib      := ORD( Rec_Packet_Ptr^[InPos+1] ) - 32;
         I             := InPos + 2;
         L_Attrib_Last := L_Attrib + PRED( I );
{
         IF Kermit_Debug THEN
            BEGIN
               Write_Log('   Attribute = <' + Attrib + '>', FALSE, FALSE );
            END;
}
         IF Kermit_Attributes THEN

            CASE Attrib OF

               '!': BEGIN (* Get approximate file size *)

                       Kermit_File_Size := Get_Number( COPY( Rec_Packet_Ptr^, I, L_Attrib ) );

                       IF Display_Status THEN
                          BEGIN
                             GoToXY( 25 , 4 );
                             STR( Kermit_File_Size , Size_String );
                             WRITE( Size_String , 'K' );
                             ClrEol;
                          END;

                    END   (* Get approximate file size *);

               '#': BEGIN (* Get date/time of file creation *)
                       Extract_File_Date;
                       Extract_File_Time;
                    END;

               '1': BEGIN (* Get exact file size *)

                       Kermit_File_Size := 0;

                       FOR J := I TO ( I + L_Attrib - 1 ) DO
                          IF Rec_Packet_Ptr^[J] IN ['0'..'9'] THEN
                             Kermit_File_Size := Kermit_File_Size * 10 +
                                                 ( ORD( Rec_Packet_Ptr^[J] ) - ORD('0') );

                       IF Display_Status THEN
                          BEGIN
                             GoToXY( 25 , 4 );
                             STR( Kermit_File_Size , Size_String );
                             WRITE( Size_String );
                             ClrEol;
                          END;

                    END   (* Get exact file size *);

               ELSE
                  Rejected_Attribs := Rejected_Attribs + Attrib;

            END (* CASE *)

         ELSE
            Rejected_Attribs := Rejected_Attribs + Attrib;

         InPos := InPos + L_Attrib + 2;

      END;
                                   (* Acknowledge this packet *)
   IF Kermit_Abort THEN
      Send_Abort_Packet
   ELSE
      Send_ACK;

END   (* Handle_Attrib_Pack *);

(*----------------------------------------------------------------------*)
(*             Handle_Data_Pack --- handle one data packet              *)
(*----------------------------------------------------------------------*)

PROCEDURE Handle_Data_Pack;

BEGIN (* Handle_Data_Pack *)
                                   (* If abort pending, send abort  *)
                                   (* packet and don't expand data. *)
   IF Kermit_Abort THEN
      Send_Abort_Packet
   ELSE
      BEGIN
                                   (* Else, send ACK for the data *)
                                   (* packet ... *)
         Send_ACK;
                                   (* ... and expand data packet. *)

         IF ( NOT Expand_Packet( Rec_Packet_Ptr , Rec_Packet_Length ) ) THEN
            BEGIN
               Kermit_Abort       := TRUE;
               Kermit_Abort_Level := One_File;
            END;

      END;

END   (* Handle_Data_Pack *);

(*----------------------------------------------------------------------*)
(*             Handle_End_Pack --- handle end of file packet            *)
(*----------------------------------------------------------------------*)

PROCEDURE Handle_End_Pack;

VAR
   Write_Count   : INTEGER;
   Err           : INTEGER;
   Ctrl_Z_Written: BOOLEAN;
   F             : FILE;
   SSize         : STRING[20];

BEGIN (* Handle_End_Pack *)
                                   (* Write any remaining characters *)
                                   (* in file buffer to file and     *)
                                   (* close it.                      *)
   Err := 0;

   IF File_Open THEN
      BEGIN
                                   (* Add a Ctrl-Z to file if in     *)
                                   (* text mode to mark end of file. *)

         Ctrl_Z_Written := FALSE;

         IF ( Kermit_File_Type_Var = Kermit_Ascii ) THEN
            IF ( Write_Buffer^[Buffer_Pos] <> ORD( ^Z ) ) THEN
               IF ( Buffer_Pos < Buffer_Size ) THEN
                  BEGIN
                     INC( Buffer_Pos );
                     Write_Buffer^[Buffer_Pos] := ORD( ^Z );
                     Ctrl_Z_Written            := TRUE;
                     Buffer_Num                := Buffer_Num + 1;
                  END;
                                   (* Write any remaining characters in *)
                                   (* buffer.                           *)


         BlockWrite( XFile, Write_Buffer^, Buffer_Pos, Write_Count );

         Err := Int24Result;

         IF ( Write_Count <> Buffer_Pos ) THEN
            Err := 1;
                                   (* Write a Ctrl-Z to file if in     *)
                                   (* text mode and no room in buffer. *)

         IF ( Kermit_File_Type_Var = Kermit_Ascii ) AND
            ( NOT Ctrl_Z_Written ) THEN
            BEGIN
               Write_Buffer^[1] := ORD( ^Z );
               BlockWrite( XFile, Write_Buffer^, 1, Write_Count );
               Err              := Err + Int24Result;
               IF ( Write_Count <> 1 ) THEN
                  Err := 1;
               Buffer_Num       := Buffer_Num + 1;
            END;
                                   (* Set file date and time *)

         IF ( Kermit_Do_File_Date OR Kermit_Do_File_Time ) AND
            Use_Time_Sent THEN
               Kermit_Set_File_Date_And_Time;

                                   (* Close the file *)
         CLOSE( XFile );
         Err := Int24Result;
                                   (* Mark file as closed. *)
         File_Open   := FALSE;
                                   (* Add char count this file *)
                                   (* to running total         *)

         Buffer_Total := Buffer_Total + Buffer_Num;

                                   (* Display count received in log *)
         STR( Buffer_Num , SSize );
         Write_Log('Size of file received was ' + SSize + ' bytes' , TRUE, FALSE );

      END;

                                   (* Acknowledge last record  *)
   IF ( Err = 0 ) THEN
      Send_ACK
   ELSE
      BEGIN
         Kermit_Abort       := TRUE;
         Kermit_Abort_Level := One_File;
         Send_Abort_Packet;
                                   (* Allow reception of further packets *)

         Kermit_Abort       := FALSE;
         Kermit_Abort_Level := No_Abort;
      END;
                                   (* And go back to waiting for *)
                                   (* start of next file.        *)
   Kermit_State := Receive_Header;

                                   (* Toss this file if necessary *)

   IF ( Toss_File AND Evict_Partial_Trans ) THEN
      BEGIN
         ASSIGN( F , Full_Name );
         ERASE ( F );
         Err := INT24Result;
      END;

END   (* Handle_End_Pack *);

(*----------------------------------------------------------------------*)
(*             Handle_Break_Packet --- Handle break packet              *)
(*----------------------------------------------------------------------*)

PROCEDURE Handle_Break_Pack;

VAR
   Write_Count   : INTEGER;
   Err           : INTEGER;
   Ctrl_Z_Written: BOOLEAN;
   F             : FILE;
   SSize         : STRING[20];

BEGIN (* Handle_Break_Pack *)
                                   (* Write any remaining characters *)
                                   (* in file buffer to file and     *)
                                   (* close it.                      *)
   Err := 0;

   IF File_Open THEN
      BEGIN
                                   (* Add a Ctrl-Z to file if in     *)
                                   (* text mode to mark end of file. *)

         IF ( Kermit_File_Type_Var = Kermit_Ascii ) THEN
            IF ( Buffer_Pos < Buffer_Size ) THEN
               BEGIN
                  INC( Buffer_Num );
                  INC( Buffer_Pos );
                  Write_Buffer^[Buffer_Pos] := ORD( ^Z );
                  Ctrl_Z_Written            := TRUE;
               END
            ELSE
               Ctrl_Z_Written := FALSE;

                                   (* Write any remaining characters in *)
                                   (* buffer.                           *)

         BlockWrite( XFile, Write_Buffer^, Buffer_Pos, Write_Count );

         Err         := Int24Result;

         IF ( Write_Count <> Buffer_Pos ) THEN
            Err := 1;
                                   (* Write a Ctrl-Z to file if in     *)
                                   (* text mode and no room in buffer. *)

         IF ( Kermit_File_Type_Var = Kermit_Ascii ) AND
            ( NOT Ctrl_Z_Written ) THEN
            BEGIN
               Buffer_Num       := Buffer_Num + 1;
               Write_Buffer^[1] := ORD( ^Z );
               BlockWrite( XFile, Write_Buffer^, 1, Write_Count );
               Err := Int24Result;
               IF ( Write_Count <> 1 ) THEN
                  Err := 1;
            END;
                                   (* Set file date and time *)

         IF ( Kermit_Do_File_Date OR Kermit_Do_File_Time ) AND
            Use_Time_Sent THEN
               Kermit_Set_File_Date_And_Time;

                                   (* Close the file *)
         CLOSE( XFile );
         Err := Int24Result;
                                   (* Mark file as closed. *)
         File_Open   := FALSE;
                                   (* Add char count this file *)
                                   (* to running total         *)

         Buffer_Total := Buffer_Total + Buffer_Num;

                                   (* Display count received in log *)
         STR( Buffer_Num , SSize );
         Write_Log('Size of file received was ' + SSize + ' bytes' , TRUE, FALSE );

      END;
                                   (* Acknowledge this packet *)
   IF ( Err = 0 ) THEN
      Send_ACK
   ELSE
      BEGIN
         Kermit_Abort       := TRUE;
         Kermit_Abort_Level := One_File;
         Send_Abort_Packet;
                                   (* Allow reception of further packets *)
         Kermit_Abort       := FALSE;
         Kermit_Abort_Level := No_Abort;
      END;
                                   (* We're done with this batch of files. *)
   Receive_Done := TRUE;
                                   (* Toss this file if necessary *)

   IF ( Toss_File AND Evict_Partial_Trans ) THEN
      BEGIN
         ASSIGN( F , Full_Name );
         ERASE ( F );
         Err := INT24Result;
      END;

END   (* Handle_Break_Pack *);

(*----------------------------------------------------------------------*)
(*           Expand_Bottom_Packet --- Expand bottom packet in table     *)
(*----------------------------------------------------------------------*)

PROCEDURE Expand_Bottom_Packet;

VAR
   Data_Ptr : Kermit_Packet_Ptr;
   Data_Len : INTEGER;

BEGIN (* Expand_Bottom_Packet *)

   IF Kermit_Queue[Kermit_Window_Bottom].ACK_Flag THEN
      BEGIN
                                   (* Expand the bottom packet in the *)
                                   (* window and write it to disk.    *)

         WITH Kermit_Queue[Kermit_Window_Bottom] DO
            BEGIN
               Data_Ptr := ADDR( Sector_Data[ Data_Slot ] );
               Data_Len := Data_Length;
{
               IF Kermit_Debug THEN
                  BEGIN
                     Write_Log( 'Expand packet = ' + IToS( Kermit_Window_Bottom ) , FALSE, FALSE );
                     Write_Log( 'Data_Slot = ' + IToS( Data_Slot          ) , FALSE, FALSE );
                     Write_Log( 'Data_Len  = ' + IToS( Data_Len           ) , FALSE, FALSE );
                  END;
}
            END;


         IF ( NOT Expand_Packet( Data_Ptr , Data_Len ) ) THEN
            BEGIN
               Kermit_Abort       := TRUE;
               Kermit_Abort_Level := One_File;
            END;
                                   (* Move up bottom of the table. *)

         Kermit_Window_Bottom := SUCC( Kermit_Window_Bottom ) MOD 64;
         DEC( Kermit_Window_Used );

      END
   ELSE
      BEGIN
                                   (* If there's no room in the table for *)
                                   (* the new packet, abort the transfer. *)

         Kermit_Abort       := TRUE;
         Kermit_Abort_Level := One_File;

         Display_Kermit_Message_2('Apparent deadlock, transfer cancelled.');

      END;

END   (* Expand_Bottom_Packet *);

(*----------------------------------------------------------------------*)
(* Handle_Windowed_Data_Pack --- Handle data packet in windowed transfer*)
(*----------------------------------------------------------------------*)

PROCEDURE Handle_Windowed_Data_Pack;

VAR
   Data_Ptr : Kermit_Packet_Ptr;
   Data_Len : INTEGER;
   Pack_Num : INTEGER;
   Last_Num : INTEGER;
   Do_Insert: BOOLEAN;

(*----------------------------------------------------------------------*)
(*     Insert_Packet_In_Table --- Insert received packet into table     *)
(*----------------------------------------------------------------------*)

PROCEDURE Insert_Packet_In_Table;

BEGIN (* Insert_Packet_In_Table *)

                                   (* Get offset to store data. *)

   Data_Place           := Data_Place + 96;

   IF ( ( Data_Place + 96 ) > MaxSectorLength ) THEN
      Data_Place := Receive_Offset;

                                   (* Insert received packet data into table. *)

   WITH Kermit_Queue[Rec_Packet_Num] DO
      BEGIN
         Data_Slot       := Data_Place;
{
         IF Kermit_Debug THEN
            BEGIN
               Write_Log( '---Insert packet --- = ' + IToS( Rec_Packet_Num ) , FALSE, FALSE );
               Write_Log( 'Data_Slot = ' + IToS( Data_Slot          ) , TRUE, FALSE );
               Write_Log( 'Length    = ' + IToS( Rec_Packet_Length  ) , TRUE, FALSE );
               Write_Log( '---End Insert    --- ' , TRUE, FALSE );
            END;
}
         ACK_Flag        := TRUE;
         Retry_Count     := 0;
         Data_Length     := Rec_Packet_Length;
         MOVE( Rec_Packet_Ptr^[1], Sector_Data[Data_Slot],
               Rec_Packet_Length );
      END;

END   (* Insert_Packet_In_Table *);

(*----------------------------------------------------------------------*)
(*     PacketBeyondWindow  --- Test if packet beyond current window     *)
(*----------------------------------------------------------------------*)

FUNCTION PacketBeyondWindow : BOOLEAN;

VAR
   Low : INTEGER;
   High: INTEGER;

BEGIN (* PacketBeyondWindow *)

   Low  := ( Kermit_Window_Top + 2           ) MOD 64;
   High := ( Kermit_Window_Top + Window_Size_Used ) MOD 64;

   WHILE ( Low <> High ) AND ( Rec_Packet_Num <> Low ) DO
      Low := SUCC( Low ) MOD 64;

   PacketBeyondWindow := ( Low = Rec_Packet_Num );

END   (* PacketBeyondWindow *);

(*----------------------------------------------------------------------*)

BEGIN (* Handle_Windowed_Data_Pack *)

                                   (* Indicate windowing has started   *)

   IF ( NOT Windowing_Started ) THEN
      BEGIN
         Windowing_Started     := TRUE;
         Kermit_Window_Top     := PRED( Packet_Num ) MOD 64;
         Kermit_Window_Bottom  := Packet_Num;
         Kermit_Doing_Transfer := TRUE;
      END;
                                   (* ACKnowledge the received packet. *)
   Send_ACK;
                                   (* Assume we'll be inserting packet *)
                                   (* into table.                      *)
   Do_Insert := TRUE;
                                   (* Check the sequence number of the *)
                                   (* received data packet against the *)
                                   (* current table bounds.            *)

   IF ( Rec_Packet_Num = ( SUCC( Kermit_Window_Top ) MOD 64 ) ) THEN
      BEGIN (* Next packet in sequence *)
{
         IF Kermit_Debug THEN
            Write_Log( '--- Next packet in sequence --- = ' + IToS( Rec_Packet_Num ) , FALSE, FALSE );
}
                                   (* We got the next packet in sequence. *)
                                   (* See if we have to rotate the table  *)
                                   (* to insert this entry.               *)

         IF ( Kermit_Window_Used = Window_Size_Used ) THEN
            Expand_Bottom_Packet;

                                   (* If we didn't abort, put the new packet *)
                                   (* in the top window slot.                *)

         Kermit_Window_Top := SUCC( Kermit_Window_Top  ) MOD 64;
         INC( Kermit_Window_Used );

      END (* Next packet in sequence *)

                                   (* Handle packet which fits into body of *)
                                   (* table as simple insert.               *)
   ELSE IF PacketInWindow THEN
      (* Nothing to do here *)
{
      BEGIN
         IF Kermit_Debug THEN
            Write_Log('--- Packet was in window --- ', FALSE, FALSE);
      END
}
                                   (* Packet is beyond current window. *)
                                   (* Some packets were lost.          *)
   ELSE IF PacketBeyondWindow THEN

                                   (* Packet is beyond current window. *)
                                   (* Some packets were lost.          *)
      BEGIN
                                   (* NAK the missing packets.  Also,  *)
                                   (* rotate the table up to fit in    *)
                                   (* this new packet.  If we can't,   *)
                                   (* abort the transfer.              *)
{
         IF Kermit_Debug THEN
            Write_Log('--- Packet beyond window --- ', FALSE, FALSE);
}
         Pack_Num := SUCC( Kermit_Window_Top ) MOD 64;

         REPEAT
{
            IF Kermit_Debug THEN
               Write_Log('---    Pack_Num = ' + IToS( Pack_Num ), FALSE, FALSE);
}
            Packet_Num := Pack_Num;
            Send_NAK;

            IF ( Kermit_Window_Used = Window_Size_Used ) THEN
               Expand_Bottom_Packet;

            Kermit_Queue[Pack_Num].ACK_Flag := FALSE;

                                   (* Set up to insert the packet at the *)
                                   (* new top of the rotated table.      *)

            Pack_Num             := SUCC( Pack_Num ) MOD 64;
            Kermit_Window_Top    := SUCC( Kermit_Window_Top  ) MOD 64;

            INC( Kermit_Window_Used );

         UNTIL ( ( Pack_Num = Rec_Packet_Num ) OR Kermit_Abort );

                                   (* We may still need one more rotation *)

         IF ( Kermit_Window_Used = Window_Size_Used ) THEN
            Expand_Bottom_Packet;

                                   (* If we didn't abort, put the new packet *)
                                   (* in the top window slot.                *)

         Kermit_Window_Top := SUCC( Kermit_Window_Top  ) MOD 64;
         INC( Kermit_Window_Used );
{
         IF Kermit_Debug THEN
            BEGIN
               Write_Log('      New Window_Top    = ' + IToS( Kermit_Window_Top ),
                         FALSE, FALSE );
               Write_Log('      New Window_Bottom = ' + IToS( Kermit_Window_Bottom ),
                         FALSE, FALSE );
            END;
}
      END
                                   (* Packet is completely bogus -- ignore it. *)
   ELSE
      Do_Insert := FALSE;

                                   (* Insert packet into table.       *)
   IF ( NOT Kermit_Abort ) THEN
      BEGIN
         IF Do_Insert THEN
            Insert_Packet_In_Table;
      END
   ELSE                            (* Send abort packet if necessary. *)
      Send_Abort_Packet;

END   (* Handle_Windowed_Data_Pack *);

(*----------------------------------------------------------------------*)
(*              Receive_Normal --- Receive file without windowing       *)
(*----------------------------------------------------------------------*)

PROCEDURE Receive_Normal;

BEGIN (* Receive_Normal *)
                                   (* Indicate transfer has started.  *)
   Kermit_Doing_Transfer := TRUE;

                                   (* Loop over packets in file being *)
                                   (* received.                       *)
   REPEAT
                                   (* Number of tries for a good packet *)
      Try := 0;

      REPEAT
                                   (* Get next packet *)
         Receive_Packet;

         CASE Packet_OK OF
                                   (* If packet bad *)

            FALSE : IF ( NOT Kermit_Abort ) THEN
                       BEGIN
                          INC( Try );
                          IF ( Try = Kermit_MaxTry ) THEN
                             BEGIN
                                Kermit_Abort       := TRUE;
                                Kermit_Abort_Level := One_File;
                                Kermit_Construct_Message( 'EToo many retries.' );
                             END
                          ELSE
                             Send_NAK;
                       END
                    ELSE
                       BEGIN
                          Packet_Num           := SUCC( Packet_Num ) MOD 64;
                          Kermit_Window_Top    := Rec_Packet_Num;
                          Kermit_Window_Bottom := Rec_Packet_Num;
                          Send_Abort_Packet;
                       END;

                                   (* If packet OK *)
             TRUE : BEGIN
                                   (* Duplicate packet -- just ACK and *)
                                   (* continue.                        *)

                       IF ( Packet_Num = Rec_Packet_Num ) THEN
                          Send_ACK
                       ELSE
                          BEGIN

                             Packet_Num           := Rec_Packet_Num;
                             Kermit_Window_Top    := Rec_Packet_Num;
                             Kermit_Window_Bottom := Rec_Packet_Num;

                             CASE Kermit_Packet_Type OF
                                Data_Pack  : Handle_Data_Pack;
                                End_Pack   : Handle_End_Pack;
                                Break_Pack : Handle_Break_Pack;
                                Attrib_Pack: Handle_Attrib_Pack;
                                Header_Pack: ;
                                ELSE         Send_NAK;
                             END  (* CASE *);

                          END;
                    END;

         END (* CASE *);

      UNTIL ( Packet_OK OR Kermit_Abort );

   UNTIL ( Receive_Done OR Kermit_Abort OR
           ( Kermit_Packet_Type = Header_Pack ) );

END (* Receive_Normal *);

(*----------------------------------------------------------------------*)
(*              Receive_Windowing --- Receive file with windowing       *)
(*----------------------------------------------------------------------*)

PROCEDURE Receive_Windowing;

(*----------------------------------------------------------------------*)
(*   Send_NAK_For_Most_Desired --- Send NAK for most desired packet     *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_NAK_For_Most_Desired;

VAR
   L: INTEGER;

BEGIN (* Send_NAK_For_Most_Desired *)

                                   (* If windowing started -- i.e.,  *)
                                   (* a data packet has appeared --  *)
                                   (* then send NAK for most desired *)
                                   (* packet.  Else, send ordinary   *)
                                   (* NAK.                           *)
   IF Windowing_Started THEN
      BEGIN
                                   (* Send NAK for most wanted packet. *)
                                   (* This is the first unACKd packet  *)
                                   (* in the table, or, if all are     *)
                                   (* ACKd, the first packet beyond    *)
                                   (* the table.                       *)

         IF ( Kermit_Window_Used > 0 ) THEN
            BEGIN
               Packet_Num := Kermit_Window_Bottom;
               WHILE ( ( Packet_Num <> Kermit_Window_Top   ) AND
                       ( Kermit_Queue[Packet_Num].ACK_Flag ) ) DO
                  Packet_Num := SUCC( Packet_Num ) MOD 64;
               IF Kermit_Queue[Packet_Num].ACK_Flag THEN
                  Packet_Num := SUCC( Packet_Num ) MOD 64;
            END
         ELSE
            Packet_Num := SUCC( Kermit_Window_Top ) MOD 64;

                                   (* Clear possible bogus XOFF received *)
                                   (* by remote system.                  *)

         IF Async_Do_XonXoff THEN
            IF ( NOT Async_XOFF_Sent ) THEN
               Async_Send( CHR( XON ) );

                                   (* If we timed out, send NAK, else    *)
                                   (* ignore the bad packet.             *)

         IF Kermit_Retry THEN
            Send_NAK;

      END
   ELSE                            (* Send ordinary NAK if no windowing yet *)
      BEGIN
         Send_NAK;
      END;
{
   IF Kermit_Debug THEN
      BEGIN
         Write_Log( 'Send_NAK_For_Most_Desired = ' + IToS( Packet_Num ), FALSE,
                    FALSE );
         Write_Log('   Window_Top    = ' + IToS( Kermit_Window_Top ),
                   FALSE, FALSE );
         Write_Log('   Window_Bottom = ' + IToS( Kermit_Window_Bottom ),
                   FALSE, FALSE );
         IF Kermit_Retry THEN
            Write_Log('   Timed out', FALSE, FALSE )
         ELSE
            Write_Log('   Checksum bad', FALSE, FALSE );
         L := PRED( Kermit_Window_Bottom ) MOD 64;
         REPEAT
            L := SUCC( L ) MOD 64;
            IF Kermit_Queue[L].ACK_Flag THEN
               Write_Log('      Block ' + IToS( L ) + ' ACKED', FALSE, FALSE )
            ELSE
               Write_Log('      Block ' + IToS( L ) + ' NOT ACKED', FALSE, FALSE );
         UNTIL ( L = Kermit_Window_Top );
      END;
}

END   (* Send_NAK_For_Most_Desired *);

(*----------------------------------------------------------------------*)
(*          OK_Packet_Received --- Handle reception of good packet      *)
(*----------------------------------------------------------------------*)

PROCEDURE OK_Packet_Received;

BEGIN (* OK_Packet_Received *)

   Packet_Num := Rec_Packet_Num;

   CASE Kermit_Packet_Type OF

      Data_Pack  : Handle_Windowed_Data_Pack;

      End_Pack,
      Break_Pack : BEGIN
                                   (* Write any remaining packets to disk *)

                      IF ( NOT Kermit_Abort ) THEN
                         WHILE ( ( Kermit_Window_Used > 0 ) AND
                                 ( NOT Kermit_Abort       )     ) DO
                            BEGIN
                               Expand_Bottom_Packet;
                               Update_Kermit_Display;
                            END;

                      IF ( Kermit_Packet_Type = Break_Pack ) THEN
                         Handle_Break_Pack
                      ELSE
                         Handle_End_Pack;

                   END;

      Attrib_Pack: IF Kermit_Attributes THEN
                      Handle_Attrib_Pack
                   ELSE
                      Send_NAK_For_Most_Desired;

      Header_Pack: ;

      ELSE         Send_NAK_For_Most_Desired;

   END  (* CASE *);

END   (* OK_Packet_Received *);

(*----------------------------------------------------------------------*)
(*          Bad_Packet_Received --- Handle reception of bad packet      *)
(*----------------------------------------------------------------------*)

PROCEDURE Bad_Packet_Received;

BEGIN (* Bad_Packet_Received *)

   IF ( NOT Kermit_Abort ) THEN
      BEGIN
                                   (* Increment tries to get good packet *)
         INC( Try );
                                   (* Abort transfer if too many *)

         IF ( Try = Kermit_MaxTry ) THEN
            BEGIN
               Kermit_Abort       := TRUE;
               Kermit_Abort_Level := One_File;
               Kermit_Construct_Message( 'EToo many retries.' );
            END
         ELSE
            BEGIN
                                   (* If we're in a retry mode, and an    *)
                                   (* XOFF was received, the XOFF may be  *)
                                   (* spurious, so clear it before trying *)
                                   (* again.  We also need to flush the   *)
                                   (* comm output buffer at this point    *)
                                   (* as well.                            *)
                                   (*                                     *)
                                   (* If an XOFF wasn't received, perhaps *)
                                   (* the remote system got a spurious    *)
                                   (* XOFF, so we send an XON.            *)
                                   (*                                     *)

               IF ( Try > 2 ) THEN
                  IF Async_XOff_Received THEN
                     BEGIN
                        Async_Flush_Output_Buffer;
                        Clear_XOFF_Received;
                     END
                  ELSE
                     IF Async_Do_XonXoff THEN
                        IF ( NOT Async_XOFF_Sent ) THEN
                           Async_Send_Now( CHR( XON ) );

                                   (* Not too many retries yet --      *)
                                   (* send NAK for most wanted packet. *)

               Send_NAK_For_Most_Desired;

            END;

      END
   ELSE
      BEGIN (* Abort found *)

         Packet_Num := SUCC( Kermit_Window_Top ) MOD 64;

         Send_Abort_Packet;

      END   (* Abort found *);

END   (* Bad_Packet_Received *);

(*----------------------------------------------------------------------*)

BEGIN (* Receive_Windowing *)
                                   (* Set window size                 *)

   Window_Size_Used := MAX( His_Kermit_Window_Size , 1 );

                                   (* Allow more retries when windowing *)

   Save_Retry       := Kermit_MaxTry;
   Kermit_MaxTry    := Kermit_MaxTry + Window_Size_Used;

                                   (* Reset send packet address to free *)
                                   (* up remainder for packets of table *)
                                   (* entries.                          *)

   Send_Packet_Ptr  := ADDR( Sector_Data[100] );

                                   (* Empty window at this point       *)

   Kermit_Window_Used   := 0;
   Kermit_Window_Top    := 0;
   Kermit_Window_Bottom := 0;
   Data_Place           := Receive_Offset;
   Windowing_Started    := FALSE;
{
   IF Kermit_Debug THEN
      BEGIN
         Write_Log( 'Window_Size   = ' + IToS( Window_Size_Used ) , FALSE, FALSE );
         Write_Log( 'Window_Used   = ' + IToS( Kermit_Window_Used ) , FALSE, FALSE );
         Write_Log( 'Window_Top    = ' + IToS( Kermit_Window_Top  ) , FALSE, FALSE );
         Write_Log( 'Window_Bottom = ' + IToS( Kermit_Window_Bottom ) , FALSE, FALSE );
         Write_Log( 'Data_Place    = ' + IToS( Data_Place         ) , FALSE, FALSE );
      END;
}
                                   (* Loop over packets in file being *)
                                   (* received.                       *)
   REPEAT
                                   (* Number of tries for a good packet *)
      Try := 0;

      REPEAT
                                   (* Get next packet *)
         Receive_Packet;
{
         IF Kermit_Debug THEN
            IF Packet_OK THEN
               Write_Log( 'Receive packet done OK  = ' + IToS( Rec_Packet_Num ),
                          FALSE, FALSE)
            ELSE
               Write_Log( 'Receive packet done BAD = ' + IToS( Rec_Packet_Num ),
                          FALSE, FALSE);
}
                                   (* Handle received packet *)

         IF Packet_OK THEN
            OK_Packet_Received
         ELSE
            Bad_Packet_Received;

      UNTIL ( Packet_OK OR Kermit_Abort );

   UNTIL ( Receive_Done OR Kermit_Abort OR
           ( Kermit_Packet_Type = Header_Pack ) );

                                   (* Reset retry counter *)
   Kermit_MaxTry    := Save_Retry;

                                   (* Reset send packet pointer address *)

   Send_Packet_Ptr  := ADDR( Sector_Data[Send_Offset] );

                                   (* Reset packet number *)

   Packet_Num       := Rec_Packet_Num;

END (* Receive_Windowing *);

(*----------------------------------------------------------------------*)

BEGIN (* Kermit_Receive_File *)
                                   (* Assume date/time not received   *)
   Kermit_Do_File_Date := FALSE;
   Kermit_Do_File_Time := FALSE;
                                   (* Remember start time             *)

   Kermit_Transfer_Start := TimeOfDay;

                                   (* Perform actual transfer.        *)
   IF Kermit_Do_Sliding_Win THEN
      Receive_Windowing
   ELSE
      Receive_Normal;
                                   (* Calculate transfer time *)

   Kermit_Transfer_End  := TimeOfDay;
   Total_Time           := Total_Time +
                           TimeDiff( Kermit_Transfer_Start ,
                                     Kermit_Transfer_End );

                                   (* Indicate we're through with transfer *)
   Kermit_Doing_Transfer := FALSE;

                                   (* Clear message lines *)
   IF ( NOT Kermit_Abort ) THEN
      Kermit_Clear_Message_Lines;

END    (* Kermit_Receive_File *);

(*----------------------------------------------------------------------*)

PROCEDURE Do_Kermit_Receive;

VAR
   C_Trans_Rate_E : ShortStr;
   C_Trans_Rate_A : ShortStr;
   Rec_Str        : AnyStr;
   W_Str          : STRING[3];
   Err            : INTEGER;
   D_Path         : AnyStr;
   Save_Close     : BOOLEAN;
   Get_String     : AnyStr;
   I              : INTEGER;

BEGIN  (* Do_Kermit_Receive *)
                                   (* Hide cursor *)
   CursorOff;
                                   (* Save screen *)
   Save_Screen( Kermit_Local_Save );

                                   (* Initialize status display information *)
   Packets_Received   := 0;
   Packets_Sent       := 0;
   Packets_Bad        := 0;
   Buffer_Num         := 0;
   Buffer_Num_Actual  := 0;
   Buffer_Total       := 0;
   Receive_Done       := FALSE;
   Kermit_MaxTry      := 5;
   Kermit_Abort       := FALSE;
   Kermit_Retry       := FALSE;
   Quoting            := FALSE;
   Kermit_Abort_Level := No_Abort;
   Total_Time         := 0;

                                   (* Get title   *)
   IF FileName <> '' THEN
      Kermit_Menu_Title := 'Receive file ' + FileName + ' using Kermit'
   ELSE
      Kermit_Menu_Title := 'Receive file using Kermit';

                                   (* Initialize status display              *)
   Initialize_Display;

   Write_Log( Kermit_Menu_Title, FALSE, FALSE );

                                   (* Allocate buffer for file data  *)

   Buffer_Length  := Max_Write_Buffer;
   Buffer_Size    := Buffer_Length;

   GetMem( Write_Buffer , Buffer_Length );

   IF ( Write_Buffer = NIL ) THEN
      BEGIN
         Display_Kermit_Message('  Not enough memory to perform receive.');
         Press_Any;
         Restore_Screen_And_Colors( Kermit_Local_Save );
         CursorOn;
         EXIT;
      END;
                                   (* Choose reception method depending upon *)
                                   (* whether remote system in server mode   *)
                                   (* or not.                                *)

   IF Kermit_Remote_Server THEN
      Kermit_State := Get_File
   ELSE
      Kermit_State := Receive_Init;

                                   (* Transfer not aborted yet               *)
   Abort_Done := FALSE;
                                   (* Loop over received packets             *)
   REPEAT
                                   (* Take action depending upon current *)
                                   (* Kermit state.                      *)
      CASE Kermit_State OF

         Get_File        : Kermit_Get;
         Receive_Init    : Kermit_Receive_Init;
         Receive_Header  : Kermit_Receive_Header;
         Receive_File    : Kermit_Receive_File;

      END (* CASE *);

   UNTIL ( Kermit_Abort OR Receive_Done );

                                   (* Display transfer rate *)

   IF ( Receive_Done AND ( NOT Abort_Done ) ) THEN
      BEGIN

         Display_Kermit_Message('Receive completed.');

         IF ( Total_Time = 0 ) THEN
            Total_Time := 1;

         Kermit_Transfer_Rate := Buffer_Total / ( Total_Time * 1.0 );

         STR( Kermit_Transfer_Rate:10:0 , C_Trans_Rate_E );

         Display_Kermit_Message_2('Effective transfer rate was ' +
                                  LTrim( C_Trans_Rate_E ) + ' CPS.');

         Kermit_Transfer_Rate := Buffer_Num_Actual / ( Total_Time * 1.0 );

         STR( Kermit_Transfer_Rate:10:0 , C_Trans_Rate_A );

         Display_Kermit_Message_3('Actual transfer rate was ' +
                                  LTrim( C_Trans_Rate_A ) + ' CPS.');

      END;

   IF Abort_Done THEN
      Write_Log('Receive cancelled.' , TRUE , FALSE );

                                   (* Ensure entire protocol aborted   *)
                                   (* if requested.                    *)
   Kermit_Done := Abort_Done;

   Window_Delay;
                                   (* Remove download buffer           *)
   MyFreeMem( Write_Buffer , Buffer_Length );

                                   (* Remove Kermit window             *)

   IF ( Kermit_Local_Save <> NIL ) THEN
      Restore_Screen_And_Colors( Kermit_Local_Save );

                                   (* Display cursor again *)
   CursorOn;
                                   (* Signal transfer done *)
   IF ( NOT Silent_Mode ) THEN
      FOR I := 1 TO Transfer_Bells DO
         Menu_Beep;

END    (* Do_Kermit_Receive *);

(*----------------------------------------------------------------------*)

PROCEDURE Get_File_Pattern;

BEGIN (* Get_File_Pattern *)
                                   (* Get file name from kbd/screen *)

   IF ( LENGTH( FileName ) = 0 ) THEN
      IF Auto_Find_FileNames THEN
         Get_Auto_File_Name( Saved_Kbd_File_Name , FileName );

   Draw_Titled_Box( Local_Save, 10, 5, 78, 8, '' );

   PibTerm_Window( 11, 6, 77, 7 );

   GoToXY( 2 , 1 );

   WRITE('File to receive: ');

   IF ( ( NOT ( Host_Mode OR Script_Transfer ) ) OR ( LENGTH( FileName ) = 0 ) ) THEN
      BEGIN
         FileName := FileName;
         Read_Edited_String( FileName );
         IF ( FileName = CHR( ESC ) ) THEN
            FileName := '';
         WRITELN;
      END
   ELSE
      WRITELN( FileName );

   Restore_Screen_And_Colors( Local_Save );

END   (* Get_File_Pattern *);

(*----------------------------------------------------------------------*)

BEGIN (* Receive_Kermit_File *)
                                   (* Get Kermit menu *)

   Make_A_Menu( Kermit_Menu, Receive_Quit_Item, 6, 20, 40, 9, Receive_Quit_Item,
                'Choose Kermit function: ',
                'a) GET Text File;b) GET Binary file;c) RECEIVE Text File;' +
                'd) RECEIVE Binary File;' +
                'f) Finish Remote Server;l) Logout Remote Server;' +
                'r) Remote Server Commands;t) Transfer to Send File Menu;' +
                'q) Quit Kermit',
                FALSE );

   Kermit_Done            := FALSE;
   Sending_File           := FALSE;
   Host_Count             := 0;
   Send_Packet_Ptr        := ADDR( Sector_Data[Send_Offset] );
   Send_Packet_Ptr^[2]    := CHR( 0 );
   Send_Packet_Ptr^[3]    := CHR( 0 );
   Send_Packet_Ptr^[4]    := CHR( 0 );
   Initial_SOH_Received   := Doing_Kermit_Autodown;

   REPEAT
                                   (* Reinitialize Kermit variables *)
      Kermit_Init;
                                   (* No remote command yet         *)
      Remote_Comm := '';
                                   (* Display Kermit receive menu   *)

      IF ( NOT ( Host_Mode OR Script_Transfer OR Doing_Kermit_Autodown ) ) THEN
         BEGIN
            Menu_Display_Choices( Kermit_Menu );
            Menu_Choice := Menu_Get_Choice( Kermit_Menu , Erase_Menu );
         END
      ELSE
         BEGIN

            INC( Host_Count );

            IF ( Host_Count = 1 ) THEN
               IF ( Doing_Kermit_Autodown ) THEN
                  Menu_Choice := 4
               ELSE
                  BEGIN

                     IF ( Kermit_File_Type_Var <> Kermit_Binary ) THEN
                        IF ( LENGTH( FileName ) > 0 ) THEN
                           Menu_Choice := 1
                        ELSE
                           Menu_Choice := 3
                     ELSE
                        IF ( LENGTH( FileName ) > 0 ) THEN
                           Menu_Choice := 2
                        ELSE
                           Menu_Choice := 4;

                     IF ( LENGTH( FileName ) > 0 ) THEN
                        IF ( FileName[1] = '/' ) THEN
                           BEGIN
                              Menu_Choice := 7;
                              Remote_Comm := FileName;
                           END;

                  END
            ELSE
               Menu_Choice := Receive_Quit_Item;

         END;
                                   (* Perform desired Kermit function *)
      CASE Menu_Choice OF

         1: BEGIN
               Kermit_File_Type_Var := Kermit_Ascii;
               Get_File_Pattern;
               Kermit_Remote_Server := TRUE;
               IF ( LENGTH( FileName ) > 0 ) THEN
                  Do_Kermit_Receive;
            END;

         2: BEGIN
               Kermit_File_Type_Var := Kermit_Binary;
               Get_File_Pattern;
               Kermit_Remote_Server := TRUE;
               IF ( LENGTH( FileName ) > 0 ) THEN
                  Do_Kermit_Receive;
            END;

         3: BEGIN
               Kermit_File_Type_Var := Kermit_Ascii;
               FileName := '';
               Kermit_Remote_Server := FALSE;
               Do_Kermit_Receive;
            END;

         4: BEGIN
               Kermit_File_Type_Var := Kermit_Binary;
               FileName := '';
               Kermit_Remote_Server := FALSE;
               Do_Kermit_Receive;
            END;

         5: BEGIN
               Kermit_Finish_Server( 'F' );
            END;

         6: BEGIN
               Kermit_Finish_Server( 'L' );
            END;

         7: BEGIN
               Kermit_Remote_Commands( Remote_Comm , Do_A_Receive );
               FileName := '';
               Kermit_Remote_Server := FALSE;
               IF Do_A_Receive THEN
                  Do_Kermit_Receive;
            END;

         8: BEGIN
               Kermit_Done  := TRUE;
               Sending_File := TRUE;
            END;

         ELSE
            BEGIN
               Kermit_Done := TRUE;
            END;

      END (* CASE *);

   UNTIL Kermit_Done;
                                   (* Ensure status window restored        *)
   IF Do_Status_Line THEN
      PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line - 1 );

                                   (* Ensure switch to send code if needed *)

   Kermit_Really_Done := ( NOT Sending_File );
   FileName           := '';

                                   (* Turn off autodownload in progress *)
   Doing_Kermit_Autodown := FALSE;

END   (* Receive_Kermit_File *);
