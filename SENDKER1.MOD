(*----------------------------------------------------------------------*)
(*              Send_Kermit_File --- Upload file using Kermit           *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Kermit_File;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Send_Kermit_File                                     *)
(*                                                                      *)
(*     Purpose:    Uploads file to remote using Kermit protocol         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Send_Kermit_File;                                             *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   EOF_Packet   = 'Z';
   Break_Packet = 'B';

CONST
   Send_Quit_Item = 6;

VAR
   Buffer_Pos    : INTEGER;
   Buffer_Size   : INTEGER;
   Write_Count   : INTEGER;
   Err           : INTEGER;
   Local_Save    : Saved_Screen_Ptr;
   Local_Save_2  : Saved_Screen_Ptr;
   File_Pattern  : AnyStr;
   Stop_Send     : BOOLEAN;
   File_Entry    : SearchRec;
   OK_File       : BOOLEAN;
   Try           : INTEGER;
   Send_Done     : BOOLEAN;
   Kermit_Menu   : Menu_Type;
   I             : INTEGER;
   J             : INTEGER;
   Kermit_Done   : BOOLEAN;
   Host_Count    : INTEGER;
   Menu_Choice   : INTEGER;
   Long_Buffer   : BOOLEAN;
   Buffer_Length : INTEGER;
   Read_Buffer   : File_Handle_Buffer_Ptr;
   No_More_Chars : BOOLEAN;
   Buffer_Total  : REAL;
   Full_Name     : AnyStr;
   Buffer_Num_Actual : REAL;
   Total_Time    : REAL;

(*----------------------------------------------------------------------*)
(*       Get_Kermit_File_Name --- Construct file name to Kermit form    *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Kermit_File_Name( VAR OK_File : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_Kermit_File_Name                                 *)
(*                                                                      *)
(*     Purpose:    Gets name of next file to be transferred             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_Kermit_File_Name( VAR OK_File : BOOLEAN );                *)
(*                                                                      *)
(*           OK_File --- TRUE if file is OK to be transferred           *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Scan_Xfer_List                                                *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The global variable 'FileName' gets the file name.            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I: INTEGER;

BEGIN (* Get_Kermit_File_Name *)

   FileName := File_Entry.Name;

   OK_File := ( File_Entry.Attr AND
                ( VolumeID + Directory ) = 0 );

                                   (* If host mode, make sure file *)
                                   (* is on xferlist!              *)
   IF Host_Mode THEN
      IF ( Privilege <> 'S' ) THEN
         OK_File := OK_File AND ( Scan_Xfer_List( FileName ) > 0 );

END   (* Get_Kermit_File_Name *);

(*----------------------------------------------------------------------*)
(*                 Get_File_Data --- get data from file                 *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_File_Data;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_File_Data                                        *)
(*                                                                      *)
(*     Purpose:    Gets next buffer of data from file being uploaded    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_File_Data;                                                *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The global variable 'Send_Packet_Ptr^' gets the next batch    *)
(*        of data.  'Read_Buffer^' holds the current 'Buffer_Size'      *)
(*        characters read in.                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Char_Count   : INTEGER;
   Save_Char    : Byte;
   Temp_Data    : STRING[120];
   End_Of_File  : BOOLEAN;
   Err          : INTEGER;
   NRead        : INTEGER;
   Ascii_File   : BOOLEAN;
   L            : INTEGER;
   MaxData      : INTEGER;
   Repeat_Count : INTEGER;
   Packet_Count : INTEGER;
   EChar_Count  : INTEGER;

(*----------------------------------------------------------------------*)

FUNCTION NextChar: BYTE;

BEGIN (* NextChar *)
                                   (* See if current buffer exhausted *)

   IF ( Buffer_Pos >= Buffer_Size ) AND ( NOT End_Of_File ) THEN
      BEGIN
                                   (* Read Sector_size chars from file  *)
                                   (* to be sent.                       *)

         BlockRead( XFile, Read_Buffer^, Buffer_Size, NRead );

         Err         := Int24Result;
         Buffer_Pos  := 0;
         Buffer_Size := NRead;
         End_Of_File := ( NRead <= 0 );

      END;
                                   (* See if anything to be sent *)

   IF ( Buffer_Pos < Buffer_Size ) THEN
      BEGIN
                                   (* Pick up next character *)

         INC( Buffer_Pos );
         NextChar := Read_Buffer^[ Buffer_Pos ];

         INC( Char_Count );
         No_More_Chars := FALSE;

      END
   ELSE
      BEGIN
         No_More_Chars := TRUE;
         NextChar      := ORD( ^Z );
      END;

END   (* NextChar *);

(*----------------------------------------------------------------------*)

FUNCTION PeekChar : BYTE;

BEGIN (* PeekChar *)

   IF ( Buffer_Pos < Buffer_Size ) THEN
      PeekChar := Read_Buffer^[Buffer_Pos + 1]
   ELSE
      PeekChar := ( Read_Buffer^[Buffer_Pos] + 1 ) AND $FF;

END   (* PeekChar *);

(*----------------------------------------------------------------------*)

PROCEDURE Encode_Kermit_Character( A: BYTE );

VAR
   A8: BYTE;
   A7: BYTE;

BEGIN (* Encode_Kermit_Character *)

                                   (* Separate 7 bits from high bit *)
   A7 := A AND $7F;
   A8 := A AND $80;
                                   (* Perform 8th bit quoting *)
   IF Quoting THEN
      IF ( A8 <> 0 ) THEN
         BEGIN
            INC( Packet_Count );
            Send_Packet_Ptr^[Packet_Count] := Kermit_Quote_8_Char;
            A                              := A7;
         END;
                                   (* Perform control quoting *)

   IF ( A7 < SP ) OR ( A7 = DEL ) THEN
      BEGIN
         INC( Packet_Count );
         Send_Packet_Ptr^[Packet_Count] := Kermit_Quote_Char;
         A                              := A XOR 64;
      END;
                                   (* Prefix the control prefix *)

   IF ( A7 = ORD( Kermit_Quote_Char ) ) THEN
      BEGIN
         INC( Packet_Count );
         Send_Packet_Ptr^[Packet_Count] := Kermit_Quote_Char;
      END;

   IF Repeating THEN
      IF ( A7 = ORD( His_Repeat_Char ) ) THEN
         BEGIN
            INC( Packet_Count );
            Send_Packet_Ptr^[Packet_Count] := Kermit_Quote_Char;
         END;
                                   (* Prefix the 8-bit quote char *)
   IF Quoting THEN
      IF ( A7 = ORD( Kermit_Quote_8_Char ) ) THEN
         BEGIN
            INC( Packet_Count );
            Send_Packet_Ptr^[Packet_Count] := Kermit_Quote_Char;
         END;
                                   (* Finally, insert either 8-bit or  *)
                                   (* 7-bit version of character into  *)
                                   (* packet.                          *)

   INC( Packet_Count );
   Send_Packet_Ptr^[Packet_Count] := CHR( A );

                                   (* Increment count of encoded chars *)
   INC( EChar_Count );

END   (* Encode_Kermit_Character *);

(*----------------------------------------------------------------------*)

BEGIN (* Get_File_Data *)
                                   (* Packet length        *)
   IF Kermit_Do_Long_Blocks THEN
      BEGIN
         Packet_Count       := 7;
         MaxData            := His_Kermit_MaxLX1 * 95 + His_Kermit_MaxLX2 - 3;
      END
   ELSE
      BEGIN
         Packet_Count       := 4;
         MaxData            := Kermit_Packet_Size;
      END;
                                   (* Maximum length allowed for data *)

   MaxData := MaxData - 3 - ( ORD( Kermit_Chk_Type ) - ORD('0') );

   IF Repeating THEN
      MaxData := MaxData - 2;
                                   (* Remember if ascii transfer *)

   Ascii_File          := ( Kermit_File_Type_Var = Kermit_Ascii );

                                   (* Set data type packet *)
   Send_Packet_Ptr^[4] := 'D';
                                   (* Characters from file *)
   Char_Count          := 0;
                                   (* Encoded characters this packet *)
   EChar_Count         := 0;
                                   (* Repeat count starts at 0 *)
   Repeat_Count        := 0;
                                   (* Not end of file yet *)
   End_Of_File         := FALSE;
                                   (* Get next batch of characters *)
                                   (* from file                    *)
   REPEAT
                                   (* See if anything to be sent *)
      Save_Char := NextChar;
                                   (* Make sure to stop at ^Z = EOF *)
                                   (* on text files.                *)

      IF Ascii_File AND ( Save_Char = ORD( ^Z ) ) THEN
         BEGIN
            End_Of_File        := TRUE;
            No_More_Chars      := TRUE;
{
            IF Kermit_Debug THEN
               Write_Log('Found Ctrl-Z for Ascii file.', TRUE, FALSE);
}
         END;
                                   (* Handle repeat quoting here *)
      IF ( NOT No_More_Chars ) THEN
         IF Repeating THEN
            BEGIN

               Repeat_Count := 1;

               WHILE ( ( PeekChar = Save_Char ) AND ( Repeat_Count < 94 ) ) DO
                  BEGIN
                     Save_Char    := NextChar;
                     INC( Repeat_Count );
                  END;

               CASE Repeat_Count OF
                  1:    Encode_Kermit_Character( Save_Char );
                  2:    BEGIN
                           Encode_Kermit_Character( Save_Char );
                           Encode_Kermit_Character( Save_Char );
                        END;
                  ELSE  BEGIN
                           INC( Packet_Count );
                           Send_Packet_Ptr^[Packet_Count]   := His_Repeat_Char;
                           INC( Packet_Count );
                           Send_Packet_Ptr^[Packet_Count]   := CHR( Repeat_Count + 32 );
                           Encode_Kermit_Character( Save_Char );
                        END;
               END (* CASE *);

            END
         ELSE                      (* Not a repeated character *)

            Encode_Kermit_Character( Save_Char );

   UNTIL ( End_Of_File AND No_More_Chars ) OR
         ( Packet_Count >= MaxData );

                                   (* Record encoded character count *)

   Buffer_Num        := Buffer_Num        + Char_Count;
   Buffer_Num_Actual := Buffer_Num_Actual + EChar_Count;

                                   (* Remember length of packet   *)

   IF ( Char_Count > 0 ) THEN
      Send_Packet_Length := Packet_Count
   ELSE
      Send_Packet_Length := 0;
                                   (* Remember if end of file AND *)
                                   (* buffer exhausted.           *)

   IF ( End_Of_File AND No_More_Chars ) THEN
      BEGIN
         File_Done    := TRUE;
         CLOSE( XFile );
         Err          := Int24Result;
         Buffer_Total := Buffer_Total + Buffer_Num;
      END
   ELSE
      File_Done := FALSE;

END    (* Get_File_Data *);

(*----------------------------------------------------------------------*)
(*          Kermit_Send_Init --- send initialization packet             *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Send_Init;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Kermit_Send_Init                                     *)
(*                                                                      *)
(*     Purpose:    Sends transfer initialization packet to host.        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Kermit_Send_Init;                                             *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Build_Packet                                                  *)
(*        Send_Packet                                                   *)
(*        Receive_Packet                                                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Quote_8       : CHAR;
   Repeat_Char   : CHAR;
   My_Attributes : CHAR;
   Window_Size   : STRING[1];
   LX1           : CHAR;
   LX2           : CHAR;
   Attributes    : BYTE;
   Do_Win        : BOOLEAN;
   Do_Long       : BOOLEAN;

BEGIN (* Kermit_Send_Init *)

   Packet_Num   := 0;
   Try          := 0;
   Quoting      := FALSE;
                                   (* Ensure type 1 block check here *)
   His_Chk_Type := '1';
                                   (* 8-bit quoting off for 8,n,1   *)
                                   (* and ascii file type transfers *)

   IF ( ( Parity <> 'N' ) OR ( Data_Bits <> 8 ) ) AND
      ( Kermit_File_Type_Var = Kermit_Binary ) THEN
      BEGIN
         Quote_8 := Kermit_Quote_8_Char;
         Quoting := TRUE;
      END
   ELSE                            (* Willing to quote if necessary *)
      Quote_8 := 'Y';
                                   (* If repeating data to be allowed *)

   Repeat_Char := Kermit_Repeat_Char;

                                   (* Capabilities                    *)
   Attributes  := 8;
                                   (* Set window size, long packets   *)
                                   (* size.                           *)

   His_Kermit_Window_Size := Kermit_Window_Size;
   His_Kermit_MaxLX1      := Kermit_Extended_Block DIV 95;
   His_Kermit_MaxLX2      := Kermit_Extended_Block MOD 95;

   Window_Size := ' ';
   Do_Win      := ( His_Kermit_Window_Size > 0 );
   Do_Long     := ( ( His_Kermit_MaxLX1 > 0 ) OR ( His_Kermit_MaxLX2 > 0 ) );

   IF Do_Win THEN
      BEGIN
         Attributes  := Attributes + 4;
         Window_Size := CHR( His_Kermit_Window_Size + 32 );
      END;

   IF Do_Long THEN
      BEGIN
         Attributes := Attributes + 2;
         LX1        := CHR( His_Kermit_MaxLX1 + 32 );
         LX2        := CHR( His_Kermit_MaxLX2 + 32 );
      END;

   My_Attributes    := CHR( Attributes + 32 );

                                   (* Construct initialization packet *)

   Send_Packet_Ptr^[ 4] := 'S';
   Send_Packet_Ptr^[ 5] := CHR( Kermit_Packet_Size + 32         );
   Send_Packet_Ptr^[ 6] := CHR( Kermit_TimeOut     + 32         );
   Send_Packet_Ptr^[ 7] := CHR( Kermit_Npad        + 32         );
   Send_Packet_Ptr^[ 8] := CHR( ORD( Kermit_Pad_Char ) XOR $40  );
   Send_Packet_Ptr^[ 9] := CHR( ORD( Kermit_EOL      ) + 32     );
   Send_Packet_Ptr^[10] := Kermit_Quote_Char;
   Send_Packet_Ptr^[11] := Quote_8;
   Send_Packet_Ptr^[12] := Kermit_Chk_Type;
   Send_Packet_Ptr^[13] := Repeat_Char;
   Send_Packet_Ptr^[14] := My_Attributes;

   Send_Packet_Length   := 14;

   IF ( Do_Win OR Do_Long ) THEN
      BEGIN
         Send_Packet_Ptr^[15] := Window_Size[1];
         Send_Packet_Length   := 15;
      END;

   IF Do_Long THEN
      BEGIN
         Send_Packet_Ptr^[16] := LX1;
         Send_Packet_Ptr^[17] := LX2;
         Send_Packet_Length   := 17;
      END;
{
   IF Kermit_Debug THEN
      Write_Log('My send-init packet = <' +
                COPY( Send_Packet_Ptr^, 1, Send_Packet_Length ) + '>',
                FALSE, FALSE );
}
   Build_Packet;

   REPEAT
                                   (* Ensure type 1 block check here *)
      His_Chk_Type := '1';
                                   (* Assume bad until proved otherwise *)
      ACK_OK := FALSE;
                                   (* Send initialization packet *)
      Send_Packet;
                                   (* Check response *)
      Receive_Packet;
                                   (* If right response then check *)
                                   (* if received packet jives     *)
                                   (* with what we sent.           *)
      IF ( Packet_OK AND
         ( Kermit_Packet_Type = ACK_Pack ) AND
         ( NOT Kermit_Abort ) ) THEN
         Check_Init( ACK_OK );
                                   (* Increment count of tries     *)
      INC( Try );

   UNTIL ACK_OK OR Kermit_Abort OR ( Try = Kermit_MaxTry );

                                   (* If OK, then get ready to send  *)
                                   (* file header packet, else abort *)
   IF ACK_OK THEN
      Kermit_State := Send_File_Header
   ELSE
      BEGIN
         Kermit_Abort := TRUE;
         Kermit_State := Send_Break;
      END;

END   (* Kermit_Send_Init *);

(*----------------------------------------------------------------------*)
(* Build_And_Send_Packet_With_Retry --- Build & send packet with retry  *)
(*----------------------------------------------------------------------*)

PROCEDURE Build_And_Send_Packet_With_Retry;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Build_And_Send_Packet_With_Retry                     *)
(*                                                                      *)
(*     Purpose:    Sends packet to remote Kermit and retries if         *)
(*                 packet not acknowledged.                             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Build_And_Send_Packet_With_Retry;                             *)
(*                                                                      *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Build_Packet                                                  *)
(*        Check_ACK                                                     *)
(*        Async_Flush_Output_Buffer                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Build_And_Send_Packet_With_Retry *)

                                   (* Build the packet *)
   Build_Packet;
                                   (* No tries yet *)
   Try := 0;
                                   (* Begin loop over sending tries *)
   REPEAT
                                   (* Send the packet *)
      Send_Packet;
                                   (* See if it was acknowledged *)
      Check_ACK;
                                   (* Increment count of send packet tries *)
      INC( Try );
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
               Clear_XOff_Received;
            END
         ELSE
            IF Async_Do_XonXoff THEN
               Async_Send_Now( CHR( XON ) );

                                   (* Stop if OK, abort requested, or too *)
                                   (* many tries.                         *)

   UNTIL ACK_OK OR Kermit_Abort OR ( Try = Kermit_MaxTry );

END   (* Build_And_Send_Packet_With_Retry *);

(*----------------------------------------------------------------------*)
(*      Kermit_Send_Header --- send file header (file name) packet      *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Send_Header;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Kermit_Send_Header                                   *)
(*                                                                      *)
(*     Purpose:    Sends file name packet to remote Kermit.             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Kermit_Send_Header;                                           *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Build_And_Send_Packet_With_Retry                              *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Kermit_Send_Header *)

                                   (* Construct file name packet *)

   Packet_Num          := SUCC( Packet_Num ) MOD 64;

   Send_Packet_Ptr^[4] := 'F';

   MOVE( FileName[1], Send_Packet_Ptr^[5], LENGTH( FileName ) );

   Send_Packet_Length := LENGTH( FileName ) + 4;

                                   (* Send the packet *)

   Build_And_Send_Packet_With_Retry;

                                   (* If it was ACKed, then *)
                                   (* prepare to send file. *)
   IF ACK_OK THEN
      Kermit_State := Send_File
   ELSE
      BEGIN
         Kermit_Abort := TRUE;
         Kermit_State := Send_Break;
      END;

END    (* Kermit_Send_Header *);

(*----------------------------------------------------------------------*)
(*         Kermit_Send_Attributes --- send file attributes              *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Send_Attributes;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Kermit_Send_Attributes                               *)
(*                                                                      *)
(*     Purpose:    Sends file attributes packet to remote Kermit.       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Kermit_Send_Attributes;                                       *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Build_And_Send_Packet_With_Retry                              *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   L1               : INTEGER;
   L2               : INTEGER;
   L3               : INTEGER;
   I                : INTEGER;
   Send_Packet_Ptr2 : Kermit_Packet_Ptr;
   Count            : INTEGER;
   CheckSum         : INTEGER;

BEGIN  (* Kermit_Send_Attributes *)

                                   (* Increment packet number          *)

   Packet_Num := SUCC( Packet_Num ) MOD 64;

                                   (* We are going to send the file    *)
                                   (* size in 8-bit characters and the *)
                                   (* time and date the file was       *)
                                   (* created.                         *)

   L1 := LENGTH( Kermit_CFile_Size );
   L2 := LENGTH( Kermit_CFile_Date );
   L3 := LENGTH( Kermit_CFile_Time );

   Send_Packet_Ptr^[ 4] := 'A';
   Send_Packet_Ptr^[ 5] := '1';
   Send_Packet_Ptr^[ 6] := CHR( 32 + L1 );

   MOVE( Kermit_CFile_Size[1] , Send_Packet_Ptr^[7] , L1 );
   Send_Packet_Length   := L1 + 7;

   Send_Packet_Ptr^[Send_Packet_Length] := '#';
   INC( Send_Packet_Length );
   Send_Packet_Ptr^[Send_Packet_Length] := CHR( 32 + L2 + L3 + 1 );

   INC( Send_Packet_Length );
   MOVE( Kermit_CFile_Date[1] , Send_Packet_Ptr^[Send_Packet_Length] , L2 );
   Send_Packet_Length   := Send_Packet_Length + L2;

   Send_Packet_Ptr^[Send_Packet_Length] := ' ';
   INC( Send_Packet_Length );

   MOVE( Kermit_CFile_Time[1] , Send_Packet_Ptr^[Send_Packet_Length] , L3 );
   Send_Packet_Length   := Send_Packet_Length + L3 - 1;

                                   (* Build packet and sent it         *)

   Build_And_Send_Packet_With_Retry;

END   (* Kermit_Send_Attributes *);

