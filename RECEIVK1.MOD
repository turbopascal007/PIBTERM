(*----------------------------------------------------------------------*)
(*          Receive_Kermit_File --- Download file using Kermit          *)
(*----------------------------------------------------------------------*)

PROCEDURE Receive_Kermit_File;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Receive_Kermit_File                                  *)
(*                                                                      *)
(*     Purpose:    Downloads file to PC using Kermit protocol           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Receive_Kermit_File;                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   Receive_Quit_Item = 9;

VAR
   Buffer_Pos     : INTEGER;
   Buffer_Size    : INTEGER;
   Write_Count    : INTEGER;
   Err            : INTEGER;
   Local_Save     : Saved_Screen_Ptr;
   Local_Save_2   : Saved_Screen_Ptr;
   Kermit_Menu    : Menu_Type;
   I              : INTEGER;
   J              : INTEGER;
   Kermit_Done    : BOOLEAN;
   Menu_Choice    : INTEGER;
   Host_Count     : INTEGER;
   Long_Buffer    : BOOLEAN;
   Buffer_Length  : INTEGER;
   Write_Buffer   : File_Handle_Buffer_Ptr;
   Receiving_File : BOOLEAN;
   Cur_Drive      : CHAR;
   Cur_Path       : AnyStr;
   Buffer_Total   : LONGINT;
   Abort_Done     : BOOLEAN;
   Toss_File      : BOOLEAN;
   Full_Name      : AnyStr;
   Do_A_Receive   : BOOLEAN;
   Remote_Comm    : AnyStr;
   Buffer_Num_Actual : LONGINT;
   Total_Time        : LONGINT;

(*----------------------------------------------------------------------*)
(*    Kermit_Construct_Message --- Construct message packet             *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Construct_Message( S: AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Kermit_Construct_Message                             *)
(*                                                                      *)
(*     Purpose:    Constructs message packet                            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Kermit_Construct_Message( S: AnyStr );                        *)
(*                                                                      *)
(*           S --- Message to be constructed                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   LS : INTEGER;

BEGIN (* Kermit_Construct_Message *)

   LS := LENGTH( S );

   MOVE( S[1], Send_Packet_Ptr^[4], LS );

   Send_Packet_Length := LS + 3;

   Build_Packet;
   Send_Packet;

END   (* Kermit_Construct_Message *);

(*----------------------------------------------------------------------*)
(*  Expand_Packet_To_String --- Expand data in Kermit packet to string  *)
(*----------------------------------------------------------------------*)

FUNCTION Expand_Packet_To_String( Rec_Packet_Ptr    : Kermit_Packet_Ptr;
                                  Rec_Packet_Length : INTEGER ) : AnyStr;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Expand_Packet_To_String                              *)
(*                                                                      *)
(*     Purpose:    Expands data in Kermit packet to a string            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Rec_Str := Expand_Packet_To_String(     Rec_Packet_Ptr    :   *)
(*                                              Kermit_Packet_Ptr;      *)
(*                                           Rec_Packet_Length :        *)
(*                                              INTEGER;                *)
(*                                          ) : AnyStr;                 *)
(*                                                                      *)
(*           Rec_Packet_Ptr    --- points to unexpanded packet data     *)
(*           Rec_Packet_Length --- length of unexpanded data            *)
(*           Rec_Str           --- resultant expanded data as string    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   InPos             : INTEGER;
   OutPos            : INTEGER;
   Q8Bit             : BOOLEAN;
   Temp              : CHAR;
   B_Temp            : BYTE ABSOLUTE Temp;
   Temp2             : CHAR;
   Repeat_Count      : INTEGER;
   I                 : INTEGER;
   Rec_Packet_String : AnyStr;

BEGIN (* Expand_Packet_To_String *)

                                   (* Initialize *)
   InPos                   := 1;
   OutPos                  := 0;

   WHILE ( ( InPos <= Rec_Packet_Length ) AND ( OutPos < 256 ) ) DO
      BEGIN
                                   (* Repeat count 1 by default    *)
         Repeat_Count := 1;
                                   (* Get next character in packet *)

         Temp   := Rec_Packet_Ptr^[ InPos ];

                                   (* Check for repeat data character *)
         IF Repeating THEN
            IF ( Temp = His_Repeat_Char ) THEN
               BEGIN
                  InPos        := SUCC( InPos );
                  Repeat_Count := ORD( Rec_Packet_Ptr^[ InPos ] ) - 32;
                  InPos        := SUCC( InPos );
                  Temp         := Rec_Packet_Ptr^[ InPos ];
               END;
                                   (* Check for 8-bit quote character *)

         IF ( Temp = His_Quote_8_Char ) AND Quoting THEN
            BEGIN
               Q8Bit := TRUE;
               InPos := SUCC( InPos );
               Temp  := Rec_Packet_Ptr^[ InPos ];
            END
         ELSE
            Q8Bit := FALSE;
                                   (* Check for control quote character *)

         IF ( Temp = His_Quote_Char ) THEN
            BEGIN

               InPos := SUCC( InPos );
               Temp  := Rec_Packet_Ptr^[ InPos ];

                                   (* Convert to control character EXCEPT  *)
                                   (* for quoting characters.              *)

               Temp2 := CHR( B_Temp AND $7F );

               IF ( Temp2 <> His_Quote_Char )                             AND
                  ( NOT ( Repeating AND ( Temp2 = His_Repeat_Char   ) ) ) AND
                  ( NOT ( Quoting   AND ( Temp2 = His_Quote_8_Char  ) ) ) THEN
                     B_Temp := B_Temp XOR 64;

            END;
                                   (* Turn on 8th bit if required *)
         IF Q8Bit THEN
            B_Temp := B_Temp OR $80;

                                   (* Append character to output string. *)
                                   (* If repeat count, add it in given   *)
                                   (* number of times.                   *)

         FOR I := 1 TO Repeat_Count DO
            BEGIN
               OutPos := SUCC( OutPos );
               IF ( OutPos < 256 ) THEN
                  Rec_Packet_String[ OutPos ] := Temp;
            END;
                                   (* Point to next input character  *)
         InPos := SUCC( InPos );

      END (* WHILE *);

   Rec_Packet_String[0]    := CHR( MIN( OutPos , 255 ) );
   Expand_Packet_To_String := Rec_Packet_String;

END    (* Expand_Packet_To_String *);

(*----------------------------------------------------------------------*)
(*             Expand_Packet --- Expand data in Kermit packet           *)
(*----------------------------------------------------------------------*)

FUNCTION Expand_Packet( Rec_Packet_Ptr    : Kermit_Packet_Ptr;
                        Rec_Packet_Length : INTEGER            ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Expand_Packet                                        *)
(*                                                                      *)
(*     Purpose:    Expands data in Kermit packet                        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        OK := Expand_Packet : BOOLEAN;                                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   InPos        : INTEGER;
   Q8Bit        : BOOLEAN;
   Temp         : CHAR;
   B_Temp       : BYTE ABSOLUTE Temp;
   Temp2        : CHAR;
   Repeat_Count : INTEGER;
   I            : INTEGER;
   L            : INTEGER;
   Err          : INTEGER;
   Write_Count  : INTEGER;
   Len_Packet   : INTEGER;

BEGIN (* Expand_Packet *)
                                   (* Start of received packet     *)
   InPos         := 1;
   Len_Packet    := Rec_Packet_Length;
   Expand_Packet := TRUE;
   Err           := 0;

   WHILE ( InPos <= Len_Packet ) DO
      BEGIN
                                   (* Repeat count 1 by default    *)
         Repeat_Count := 1;
                                   (* Get next character in packet *)

         Temp   := Rec_Packet_Ptr^[ InPos ];

                                   (* Check for repeat data character *)
         IF Repeating THEN
            IF ( Temp = His_Repeat_Char ) THEN
               BEGIN
                  InPos        := SUCC( InPos );
                  Repeat_Count := ORD( Rec_Packet_Ptr^[ InPos ] ) - 32;
                  InPos        := SUCC( InPos );
                  Temp         := Rec_Packet_Ptr^[ InPos ];
               END;
                                   (* Check for 8-bit quote character *)

         IF ( Temp = His_Quote_8_Char ) AND Quoting THEN
            BEGIN
               Q8Bit := TRUE;
               InPos := SUCC( InPos );
               Temp  := Rec_Packet_Ptr^[ InPos ];
            END
         ELSE
            Q8Bit := FALSE;
                                   (* Check for control quote character *)

         IF ( Temp = His_Quote_Char ) THEN
            BEGIN

               InPos := SUCC( InPos );
               Temp  := Rec_Packet_Ptr^[ InPos ];

                                   (* Convert to control character EXCEPT  *)
                                   (* for quoting characters.              *)

               Temp2 := CHR( B_Temp AND $7F );

               IF ( Temp2 <> His_Quote_Char )                             AND
                  ( NOT ( Repeating AND ( Temp2 = His_Repeat_Char   ) ) ) AND
                  ( NOT ( Quoting   AND ( Temp2 = His_Quote_8_Char  ) ) ) THEN
                     B_Temp := B_Temp XOR 64;

            END;
                                   (* Turn on 8th bit if required *)
         IF Q8Bit THEN
            B_Temp := B_Temp OR $80;

                                   (* Append character to output buffer. *)
                                   (* If repeat count, add it in given   *)
                                   (* number of times.                   *)

         IF ( NOT Kermit_Screen_Write ) THEN
            FOR I := 1 TO Repeat_Count DO
               BEGIN

                  IF ( Buffer_Pos >= Buffer_Size ) THEN
                     BEGIN

                        BlockWrite( XFile, Write_Buffer^, Buffer_Size, Write_Count );

                        Err           := Int24Result;
                        Buffer_Pos    := 0;
                        Expand_Packet := ( Err = 0 ) AND
                                         ( Write_Count = Buffer_Size );

                     END;

                  Buffer_Pos                := SUCC( Buffer_Pos );
                  Write_Buffer^[Buffer_Pos] := B_Temp;

               END
         ELSE
            FOR I := 1 TO Repeat_Count DO
               Display_Character( Temp );

                                   (* Increment received bytes count *)

         Buffer_Num        := Buffer_Num        + Repeat_Count;
         Buffer_Num_Actual := Buffer_Num_Actual + 1;

                                   (* Point to next input character  *)
         InPos := SUCC( InPos );

      END (* WHILE *);

END    (* Expand_Packet *);

(*----------------------------------------------------------------------*)
(*    Kermit_Receive_Header --- get file header packet for Kermit       *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Receive_Header;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Kermit_Receive_Header                                *)
(*                                                                      *)
(*     Purpose:    Get file header packet for Kermit                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Kermit_Receive_Header;                                        *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This procedure receives packets and looks for the file header *)
(*        packet.  If a good file header packet is found, this routine  *)
(*        tries to open the file.  If the file opens successfully, the  *)
(*        state changes to 'Receive_File'.  If the file cannot be       *)
(*        opened (the file open procedure attempts to create a unique   *)
(*        filename if the specified file already exists) an error       *)
(*        packet is returned to the requesting kermit.  This procedure  *)
(*        also handles 'Send Init' and 'Break' packets as specified in  *)
(*        the Kermit Protocol Manual.                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Try               : INTEGER;
   Get_Pack          : BOOLEAN;
   Rec_Packet_String : AnyStr;

BEGIN (* Kermit_Receive_Header *)

                                   (* If we already have header, use it *)

   Get_Pack := ( Kermit_Packet_Type <> Header_Pack ) AND
               ( Kermit_Packet_Type <> Text_Pack   );

   REPEAT                          (* Get a packet *)

      IF Get_Pack THEN
         Receive_Packet;

      Get_Pack := TRUE;
                                   (* If recognized, perform required *)
                                   (* function based upon packet type *)
      IF Packet_OK THEN

         CASE Kermit_Packet_Type OF

            Header_Pack : BEGIN
                                    (* Try opening file *)

                             Kermit_Screen_Write := FALSE;
                             Rec_Packet_String   := Expand_Packet_To_String(
                                                             Rec_Packet_Ptr ,
                                                             Rec_Packet_Length );

                             Open_File( Write_Open,
                                        Rec_Packet_String,
                                        Full_Name );

                                    (* If OK, then shift to receive state *)

                             IF Open_OK THEN
                                BEGIN
                                   Buffer_Pos           := 0;
                                   Toss_File            := FALSE;
                                   Packet_Num           := Rec_Packet_Num;
                                   Display_Kermit_Message('Receiving ' +
                                                          Rec_Packet_String );
                                   Send_ACK;
                                   Kermit_State := Receive_File;
                                END

                                   (* Not ok open -- send error packet *)
                                   (* to remote Kermit.                *)
                             ELSE
                                BEGIN
                                   Kermit_Construct_Message( 'ECannot open file' );
                                   Kermit_Abort := TRUE;
                                   IF ( Kermit_Abort_Level = No_Abort ) THEN
                                      Kermit_Abort_Level := One_File;
                                   Display_Kermit_Message( 'Cannot open file: '
                                                           + Rec_Packet_String );
                               END;

                          END;

            Text_Pack   : BEGIN
                             Kermit_Screen_Write  := TRUE;
                             Buffer_Pos           := 0;
                             File_Open            := FALSE;
                             Toss_File            := FALSE;
                             Packet_Num           := Rec_Packet_Num;
                             Send_ACK;
                             Kermit_State := Receive_File;
                             IF Display_Status THEN
                                BEGIN
                                    Display_Status := FALSE;
                                    Restore_Screen_And_Colors( Kermit_Local_Save );
                                END;
                             PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line - 1 );
                             Clear_Window;
                             GoToXY( 1 , 1 );
                          END;

            Send_Pack   : BEGIN
                             Packet_Num           := Rec_Packet_Num;
                             Send_ACK;
                          END;

            Break_Pack  : BEGIN
                             Packet_Num           := Rec_Packet_Num;
                             Send_ACK;
                             Receive_Done := TRUE;
                             Display_Kermit_Message('Completed.');
                          END;

            End_Pack    : BEGIN
                             Packet_Num           := Rec_Packet_Num;
                             Send_ACK;
                          END;

            ELSE          BEGIN
                             Kermit_Abort         := TRUE;
                             IF ( Kermit_Abort_Level = No_Abort ) THEN
                                Kermit_Abort_Level := One_File;
                             Packet_Num           := Rec_Packet_Num;
                             Kermit_Construct_Message( 'EUnknown packet type.' );
                             Display_Kermit_Message('Error - Unknown packet type.');
                          END;

         END (* CASE *);

      IF ( Kermit_Abort_Level = Entire_Protocol ) THEN
         Display_Kermit_Message('Cancelling Kermit protocol.')
      ELSE IF ( Kermit_Abort_Level = All_Files ) THEN
         BEGIN
            Packet_Num           := ( Packet_Num + 1 ) MOD 64;
            Send_Packet_Ptr^[4]  := 'B';
            Send_Packet_Length   := 4;
            Build_Packet;
            Send_Packet;
            Display_Kermit_Message('Cancelling transfer of current batch of files.');
         END
      ELSE
         IF ( NOT Packet_OK ) THEN
            BEGIN
               Try         := SUCC( Try );
               Packets_Bad := Packets_Bad + 1;
               Send_NAK;
               IF ( Try = Kermit_MaxTry ) THEN
                  BEGIN
                     Kermit_Abort       := TRUE;
                     IF ( Kermit_Abort_Level = No_Abort ) THEN
                        Kermit_Abort_Level := One_File;
                     Packet_Num           := 0;
                     Kermit_Construct_Message( 'ECannot get file header.' );
                     Display_Kermit_Message('Cannot get file header.');
                  END;
            END;

   UNTIL Kermit_Abort OR ( Kermit_State = Receive_File ) OR Receive_Done;

END   (* Kermit_Receive_Header *);

(*----------------------------------------------------------------------*)
(*      Kermit_Get --- Initiate server mode receive for Kermit          *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Get;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Kermit_Get                                           *)
(*                                                                      *)
(*     Purpose:    Initiate server mode receive for Kermit              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Kermit_Get;                                                   *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This procedure attempts to initiate a server receive.         *)
(*        First, Kermit_Get sends an 'R' packet with the selected       *)
(*        file name.  If a valid 'Send Init' packet is received, then   *)
(*        the Kermit state is changed to Receive_Header.  If a valid    *)
(*        'Send Init' is NOT received, then an error packet is sent to  *)
(*        the other Kermit after the specified number of retries.       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Try     : INTEGER;
   Init_OK : BOOLEAN;

BEGIN (* Kermit_Get *)
                                   (* Send 'Get File' packet *)
   Packet_Num           := 0;
   Try                  := LENGTH( FileName );
   His_Chk_Type         := '1';

   Send_Packet_Ptr^[4] := 'R';

   MOVE( FileName[1], Send_Packet_Ptr^[5], Try );
   Send_Packet_Length  := Try + 4;

   Build_Packet;

   Try := 0;

   REPEAT

      Send_Packet;
      Receive_Packet;

      IF Packet_OK AND ( Kermit_Packet_Type = Send_Pack ) THEN
         BEGIN

            Packet_Num           := Rec_Packet_Num;

            Check_Init( Init_OK );

            IF Init_OK THEN
               BEGIN
                  Send_ACK;
                  Kermit_State := Receive_Header;
               END;

         END;

      IF ( Kermit_Packet_Type = Error_Pack ) THEN
         BEGIN
            Display_Kermit_Message( Expand_Packet_To_String( Rec_Packet_Ptr,
                                                             Rec_Packet_Length ) );
            Kermit_Abort       := TRUE;
            IF ( Kermit_Abort_Level = No_Abort ) THEN
               Kermit_Abort_Level := One_File;
         END;

      IF NOT ( Init_OK OR Kermit_Abort ) THEN
         BEGIN
            Packets_Bad := Packets_Bad + 1;
            Try         := SUCC( Try );
            Send_NAK;
         END;

      IF ( ( Try = Kermit_MaxTry ) OR Kermit_Abort ) THEN
         BEGIN
            Kermit_Abort       := TRUE;
            IF ( Kermit_Abort_Level = No_Abort ) THEN
               Kermit_Abort_Level := One_File;
            Kermit_Construct_Message( 'ECannot get send init packet.' );
            Display_Kermit_Message('Cannot get send_init packet.');
         END;

   UNTIL Kermit_Abort OR ( Kermit_State = Receive_Header );

END    (* Kermit_Get *);

(*----------------------------------------------------------------------*)
(*   Kermit_Receive_Init --- get Send Init packet for Kermit receives   *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Receive_Init;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Kermit_Receive_Init                                  *)
(*                                                                      *)
(*     Purpose:    get 'Send Init' for Kermit receives                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Kermit_Receive_Init;                                          *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This procedure waits for a 'Send Init' packet; it will hang   *)
(*        here until a valid 'Send Init' packet is received, or an      *)
(*        Alt-R is entered at the keyboard to abort the transfer.       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Try     : INTEGER;
   Init_OK : BOOLEAN;
   Save_CHK: CHAR;
   Get_Pack: BOOLEAN;

BEGIN (* Kermit_Receive_Init *)
                                   (* Initialize display *)
   Initialize_Display;

   Try := 0;

   Get_Pack := ( Kermit_Packet_Type <> Send_Pack );

   REPEAT
                                   (* Init packet always has block *)
                                   (* check type one.              *)
      IF Get_Pack THEN
         BEGIN

            Save_CHK     := His_Chk_Type;
            His_Chk_Type := '1';

            Receive_Packet;

            His_Chk_Type := Save_CHK;

         END;

      Get_Pack := TRUE;

      IF Packet_OK AND ( Kermit_Packet_Type = Send_Pack ) THEN
         BEGIN

            Packet_Num           := Rec_Packet_Num;

            Check_Init( Init_OK );

            IF Init_OK THEN
               BEGIN
                  Send_ACK;
                  Kermit_State := Receive_Header;
               END
            ELSE
               BEGIN

                  Packets_Bad := Packets_Bad + 1;

                  IF ( NOT Kermit_Retry ) THEN
                     Send_NAK;

                  Try := SUCC( Try );

                  IF ( Try = Kermit_MaxTry ) THEN
                     BEGIN
                        Kermit_Abort       := TRUE;
                        IF ( Kermit_Abort_Level = No_Abort ) THEN
                           Kermit_Abort_Level := One_File;
                        Kermit_Construct_Message( 'ECannot get send init packet.' );
                        Display_Kermit_Message('Cannot get send_init packet.');
                     END;

               END;

         END;

   UNTIL Kermit_Abort OR ( Kermit_State = Receive_Header );

END    (* Kermit_Receive_Init *);
