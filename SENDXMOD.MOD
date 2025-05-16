(*----------------------------------------------------------------------*)
(*                Send_Xmodem_File --- Upload file using XMODEM         *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Xmodem_File( Use_CRC : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Send_Xmodem_File                                     *)
(*                                                                      *)
(*     Purpose:    Uploads file to remote host using XMODEM protocol.   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Send_Xmodem_File( Use_CRC );                                  *)
(*                                                                      *)
(*           Use_CRC --- TRUE to use Cyclic redundancy check version    *)
(*                       of XMODEM; FALSE to use Checksum version.      *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The file's existence should have been already checked         *)
(*        prior to calling this routine.                                *)
(*                                                                      *)
(*        The transmission parameters are automatically set to:         *)
(*                                                                      *)
(*               Current baud rate, 8 bits, No parity, 1 stop           *)
(*                                                                      *)
(*        and then they are automatically restored to the previous      *)
(*        values when the transfer is complete.                         *)
(*                                                                      *)
(*     Calls:    PibTerm_KeyPressed                                             *)
(*               Async_Send                                             *)
(*               Async_Receive                                          *)
(*               Compute_Crc                                            *)
(*               Draw_Menu_Frame                                        *)
(*               Save_Screen                                            *)
(*               Restore_Screen                                         *)
(*               Async_Open                                             *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

                                   (* If this threshhold value x number *)
                                   (* of bad blocks > number of good    *)
                                   (* blocks, reduce block size to 128  *)
CONST
   Bad_Threshhold  = 6;
   SOH_Tries       = 5;
   NAK_Ch          = ^U;
   WXmodem_Window  = 4;
   SeaLink_Window  = 6;

VAR
   I               : INTEGER       (* Loop index                        *);
   L               : INTEGER       (* General length                    *);
   Tries           : INTEGER       (* # of tries sending current sector *);
   Checksum        : INTEGER       (* Sector checksum                   *);
   Crc             : INTEGER       (* Cyclic redundancy check           *);
   Ch              : INTEGER       (* Character received from COM port  *);
   Kbd_Ch          : CHAR          (* Absorbs keyboard characters       *);
   Send_Errors     : INTEGER       (* Counts transfer errors            *);
   Sector_Count    : INTEGER       (* Sector count -- no wrap at 255    *);
   Transfer_Time   : INTEGER       (* Transfer time in seconds          *);
   Effective_Rate  : REAL          (* Effective baud rate of transfer   *);
   NRead           : INTEGER       (* Records actually read from file   *);
   EOF_XFile       : BOOLEAN       (* EOF encountered on file to send   *);
   SCps            : STRING[20]    (* String form of CPS transfer rate  *);
   Max_Tries       : INTEGER       (* Max. number of retries            *);
   R_File_Size     : LONGINT       (* File size                         *);
   Header_Ch       : CHAR          (* Block header character            *);
   New_Header_Ch   : CHAR          (* Revised block header if downshift *);
   Bad_Sectors     : INTEGER       (* Count of bad sectors              *);
   Good_Sectors    : INTEGER       (* Count of good sectors             *);
   ITime           : INTEGER       (* Counter for wait loops            *);
   XFile_Size      : LONGINT       (* File size in characters           *);
   Save_XonXoff    : BOOLEAN       (* Saves XON/XOFF status             *);
   ACK_Window      : INTEGER       (* ACK window size for WXModem       *);
   ACK_Sector      : INTEGER       (* Sector # ACK'd or NAK'd           *);
   Max_ACK_Window  : INTEGER       (* Max # of sectors in window        *);
   Max_Window_Size : INTEGER       (* Max window size                   *);
   Max_Window_Size1: INTEGER       (* Max window size + 1               *);
   Sending_Title   : AnyStr        (* Title for send                    *);
   Err_Mess        : AnyStr        (* Error message text                *);

CONST
   Ymodem_Family   : SET OF Transfer_Type =
                     [ Xmodem_1K, Xmodem_1KG, Ymodem_Batch, Ymodem_G];

LABEL 1;

(*----------------------------------------------------------------------*)
(*   Update_Xmodem_Send_Display --- Update display of Xmodem sending    *)
(*----------------------------------------------------------------------*)

PROCEDURE Update_Xmodem_Send_Display;

BEGIN (* Update_Xmodem_Send_Display *)

   GoToXY( 26 , 4 );
   WRITE( Sector_Count );
   GoToXY( 35 , 4 );
   WRITE( Sector_Count SHR 3, 'K' );
   GoToXY( 26 , 5 );
   WRITE( Send_Errors  );

END   (* Update_Xmodem_Send_Display *);

(*----------------------------------------------------------------------*)
(*         Display_Send_Error --- Display XMODEM sending error          *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Send_Error( Err_Text: AnyStr; Display_Block: BOOLEAN );

VAR
   S: STRING[10];
   I: INTEGER;

BEGIN (* Display_Send_Error *)

   IF ( NOT Display_Status ) THEN
      Flip_Display_Status;

   Err_Mess := Err_Text;

   IF Display_Block THEN
      BEGIN
         I := MAX( Sector_Count - 1 , 0 );
         STR( I , S );
         Err_Mess := Err_Mess + ' at/before block ' + S;
      END;

   GoToXY( 26 , 8 );
   WRITE(Err_Mess);
   ClrEol;

   Write_Log( Err_Mess, TRUE, FALSE );

END   (* Display_Send_Error *);

(*----------------------------------------------------------------------*)
(*        Xmodem_Wait_For_Ch --- wait for character to appear           *)
(*----------------------------------------------------------------------*)

PROCEDURE Xmodem_Wait_For_Ch(     Wait_Time: INTEGER;
                              VAR Ch       : INTEGER );

VAR
   ITime : INTEGER;

BEGIN (* Xmodem_Wait_For_Ch *)

   ITime := 0;

   REPEAT
      INC( ITime );
      Async_Receive_With_Timeout( One_Second , Ch );
      Check_KeyBoard;
   UNTIL ( Ch <> TimeOut ) OR ( ITime >= Wait_Time ) OR Stop_Send;

END   (* Xmodem_Wait_For_Ch *);

(*----------------------------------------------------------------------*)
(*           Do_Initial_Handshake --- Do initial C/G/NAK handshaking    *)
(*----------------------------------------------------------------------*)

PROCEDURE Do_Initial_Handshake;

BEGIN (* Do_Initial_Handshake *)
                                   (* Get initial character             *)
   GoToXY( 26 , 8 );
   WRITE('Wait for NAK/C/G/W --- ');
   ClrEol;
                                   (* Set window size *)
   Max_Window_Size  := 0;
   Max_Window_Size1 := 1;
                                   (* Look for NAK/C/G/W *)
   REPEAT

      Xmodem_Wait_For_Ch( Xmodem_Block_Wait , Ch );

                                   (* If CAN, insist on another *)
      IF Ch = CAN THEN
         Xmodem_Wait_For_Ch( Xmodem_ACK_Wait , Ch );

      INC( Tries );

      Stop_Send := Stop_Send OR ( NOT Async_Carrier_Detect );

   UNTIL ( Tries > SOH_Tries  ) OR
         ( Ch    = NAK        ) OR
         ( Ch    = ORD( 'C' ) ) OR
         ( Ch    = ORD( 'G' ) ) OR
         ( Ch    = ORD( 'W' ) ) OR
         ( Ch    = CAN        ) OR
         Stop_Send;

   IF ( Ch    = TimeOut   ) OR
      ( Tries > SOH_Tries ) OR
      ( Ch    = CAN       ) THEN
      BEGIN
         IF ( NOT Display_Status ) THEN
            Flip_Display_Status;
         GoToXY( 26 , 51 );
         WRITE('Not Received ');
         ClrEol;
         Stop_Send := TRUE;
      END
   ELSE IF ( Ch = NAK ) THEN
      Use_Crc := FALSE
   ELSE IF ( Ch = ORD( 'C' ) ) THEN
      Use_Crc := TRUE
   ELSE IF ( Ch = ORD( 'G' ) ) THEN
      BEGIN
         Use_Crc          := TRUE;
         Do_ACKs          := FALSE;
         Async_Do_XonXoff := TRUE;
      END
   ELSE IF ( Ch = ORD( 'W' ) ) THEN
      BEGIN
         Use_Crc          := TRUE;
         Do_WXModem       := TRUE;
         Async_Do_XonXoff := TRUE;
         Max_ACK_Window   := WXmodem_Window;
         Max_Window_Size  := WXmodem_Window;
         Max_Window_Size1 := SUCC( Max_Window_Size );
      END;
                                   (* Indicate OK reception             *)
   IF ( NOT Stop_Send ) THEN
      BEGIN

         IF ( NOT Display_Status ) THEN
            Flip_Display_Status;

         GoToXY( 26 , 51 );

         WRITE('Received ');

         CASE CHR( Ch ) OF
            'C','G','W' : WRITE( CHR( Ch ) );
            NAK_Ch      : WRITE('NAK');
            ELSE;
         END (* CASE *);

         ClrEol;

      END;
                                   (* Reset status line *)
   IF Do_Status_Line THEN
      BEGIN
         Set_Status_Line_Name( Short_Terminal_Name );
         Write_To_Status_Line( Status_Line_Name, 1 );
      END;

END   (* Do_Initial_Handshake *);

(*----------------------------------------------------------------------*)
(*      Async_Send_DLE_Char --- Send possibly DLE-quoted character      *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Send_DLE_Char( C: CHAR );

(* STRUCTURED *) CONST
   DLE_Chars : SET OF CHAR = [ ^P, ^Q, ^S, ^V ];

BEGIN (* Async_Send_DLE_Char *)

   IF ( NOT Do_WXModem ) THEN
      Async_Send( C )
   ELSE
      BEGIN
         IF ( C IN DLE_Chars ) THEN
            BEGIN
               Async_Send( CHR( DLE ) );
               C := CHR( ORD( C ) XOR 64 );
            END;
         Async_Send( C );
      END;

END   (* Async_Send_DLE_Char *);

(*----------------------------------------------------------------------*)
(*               Handle_Sector_ACK --- Handle ACK/NAK for sectors       *)
(*----------------------------------------------------------------------*)

PROCEDURE Handle_Sector_ACKNAK( VAR Ch: INTEGER );

VAR
   ACK_Ch     : INTEGER;
   Comp_Ch    : CHAR;

BEGIN (* Handle_Sector_ACKNAK *)

                                   (* Assume an ACK by default.            *)
   Ch := ACK;
                                   (* If sliding windows, we don't need to *)
                                   (* wait here until send window is full. *)

   IF ( Do_WXModem OR Do_SeaLink ) THEN
      IF ( ACK_Window < Max_ACK_Window ) THEN
         IF ( Async_Buffer_Head = Async_Buffer_Tail ) THEN
            EXIT;
                                   (* Pick up a character -- should be ACK *)

   Xmodem_Wait_For_Ch( Xmodem_Ack_Wait , Ch );

                                   (* If CAN, insist on another *)
   IF ( Ch = CAN ) THEN
      BEGIN
         Xmodem_Wait_For_Ch( Xmodem_Ack_Wait , Ch );
         IF ( Ch = CAN ) THEN EXIT;
      END;
                                   (* If sliding windows, pick up sector   *)
                                   (* for which ACK/NAK applies.  Adjust   *)
                                   (* ACK_Window to reflect sectors not    *)
                                   (* ACK'd yet.                           *)

   ACK_Sector := Sector_Number;

   IF ( Do_WXModem OR Do_SeaLink ) THEN
      BEGIN
         IF ( ( Ch = ACK ) OR ( Ch = NAK ) ) THEN
            BEGIN

               XModem_Wait_For_Ch( XModem_Ack_Wait , ACK_Ch );

               IF Do_WXModem THEN
                  IF ( ACK_Ch > PRED( Max_Window_Size ) ) THEN
                     Ch := ACK
                  ELSE
                     BEGIN
                        ACK_Sector := ( ACK_Ch AND 3 );
                        ACK_Window := ( Sector_Number AND 3 ) - ACK_Sector;
                        IF ( ACK_Window < 0 ) THEN
                           ACK_Window := ACK_Window + Max_Window_Size;
                     END

               ELSE IF Do_SeaLink THEN
                  BEGIN
                     IF Async_Receive( Comp_Ch ) THEN
                        IF ( ( ORD( Comp_Ch ) + ACK_Ch ) = 255 ) THEN
                           BEGIN
                              ACK_Sector := ( ACK_Ch MOD Max_Window_Size1 );
                              ACK_Window := ( Sector_Number MOD Max_Window_Size1 ) - ACK_Sector;
                              IF ( ACK_Window < 0 ) THEN
                                 ACK_Window := ACK_Window + Max_Window_Size;
                           END
                        ELSE
                           Max_ACK_Window := 0
                     ELSE
                        Max_ACK_Window := 0;
                  END  (* IF SeaLink *);

            END (* IF Ach = ACK or BAK *);

      END (* IF sliding windows *);

                                   (* Display message about NAK *)
   IF ( Ch <> ACK ) THEN
      BEGIN
         Display_Send_Error('No ACK', TRUE);
         INC( Send_Errors );
      END;

END   (* Handle_Sector_ACKNAK *);

(*----------------------------------------------------------------------*)
(*               Send_Xmodem_Block --- send out Xmodem block            *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Xmodem_Block;

VAR
   I          : INTEGER;
   Send_State : INTEGER;

BEGIN (* Send_Xmodem_Block *)
                                   (* Reset error count to zero *)
   Tries := 0;
                                   (* Set sending state.  States depend on: *)
                                   (*                                       *)
                                   (*    CRC vs CheckSum                    *)
                                   (*    If Spooling on/off                 *)
                                   (*    If resending or not                *)
   IF CRC_Used THEN
      Send_State := 1
   ELSE
      Send_State := 0;

   IF Print_Spooling THEN
      Send_State := Send_State + 2;

   REPEAT
                                   (* Send SYN if doing WXModem *)
      IF Do_WXModem THEN
         Async_Send( CHR( SYN ) );

                                   (* Send 1st char of block *)

      Async_Send_DLE_Char( Header_Ch );

                                   (* Send block number and complement *)

      Async_Send_DLE_Char( CHR(       Sector_Number ) );
      Async_Send_DLE_Char( CHR( 255 - Sector_Number ) );

                                   (* Transmit Sector Data *)
      CASE Send_State OF

         0:  BEGIN
                CheckSum := 0;
                FOR I := 1 TO Sector_Size DO
                   BEGIN
                      Async_Send_DLE_Char( CHR( Sector_Data[ I ] ) );
                      CheckSum := ( CheckSum + Sector_Data[ I ] ) AND $FF;
                   END;
                Async_Send_DLE_Char( CHR( CheckSum ) );
             END;

         1:  BEGIN
                Crc := 0;
                FOR I := 1 TO Sector_Size DO
                   BEGIN
                      Async_Send_DLE_Char( CHR( Sector_Data[ I ] ) );
                      Crc := SWAP( Crc ) XOR Sector_Data[I];
                      Crc := Crc XOR ( LO( Crc ) SHR 4 );
                      Crc := Crc XOR ( SWAP( LO( Crc ) ) SHL 4 ) XOR
                              ( LO( Crc ) SHL 5 );
                   END;
                Async_Send_DLE_Char( CHR( HI( CRC ) ) );
                Async_Send_DLE_Char( CHR( LO( CRC ) ) );
             END;

         2:  BEGIN
                CheckSum := 0;
                FOR I := 1 TO Sector_Size DO
                   BEGIN
                      Async_Send_DLE_Char( CHR( Sector_Data[ I ] ) );
                      CheckSum := ( CheckSum + Sector_Data[ I ] ) AND $FF;
                      IF Print_Spooling THEN
                         Print_Spooled_File;
                   END;
                Async_Send_DLE_Char( CHR( CheckSum ) );
             END;

         3:  BEGIN
                Crc := 0;
                FOR I := 1 TO Sector_Size DO
                   BEGIN
                      Async_Send_DLE_Char( CHR( Sector_Data[ I ] ) );
                      Crc := SWAP( Crc ) XOR Sector_Data[I];
                      Crc := Crc XOR ( LO( Crc ) SHR 4 );
                      Crc := Crc XOR ( SWAP( LO( Crc ) ) SHL 4 ) XOR
                              ( LO( Crc ) SHL 5 );
                      IF Print_Spooling THEN
                         Print_Spooled_File;
                   END;
                Async_Send_DLE_Char( CHR( HI( CRC ) ) );
                Async_Send_DLE_Char( CHR( LO( CRC ) ) );
             END;

         4:  BEGIN
                FOR I := 1 TO Sector_Size DO
                   Async_Send_DLE_Char( CHR( Sector_Data[ I ] ) );
                Async_Send_DLE_Char( CHR( CheckSum ) );
             END;

         5:  BEGIN
                FOR I := 1 TO Sector_Size DO
                   Async_Send_DLE_Char( CHR( Sector_Data[ I ] ) );
                Async_Send_DLE_Char( CHR( HI( CRC ) ) );
                Async_Send_DLE_Char( CHR( LO( CRC ) ) );
             END;

         6:  BEGIN
                FOR I := 1 TO Sector_Size DO
                   BEGIN
                      Async_Send_DLE_Char( CHR( Sector_Data[ I ] ) );
                      IF Print_Spooling THEN
                         Print_Spooled_File;
                   END;
                Async_Send_DLE_Char( CHR( CheckSum ) );
             END;

         7:  BEGIN
                FOR I := 1 TO Sector_Size DO
                   BEGIN
                      Async_Send_DLE_Char( CHR( Sector_Data[ I ] ) );
                      IF Print_Spooling THEN
                         Print_Spooled_File;
                   END;
                Async_Send_DLE_Char( CHR( HI( CRC ) ) );
                Async_Send_DLE_Char( CHR( LO( CRC ) ) );
             END;

      END (* CASE *);
                                   (* Purge receive buffer *)

      IF ( NOT ( Do_WXModem OR Do_SEALink OR ( NOT Do_Acks ) ) ) THEN
         Async_Purge_Buffer;
                                   (* Not first time through anymore *)

      Send_State := Send_State OR 4;

                                   (* Increment count of tries to send  *)
                                   (* for this sector.                  *)
      INC( Tries );
                                   (* Handle sector ACK/NAK             *)
      IF Do_Acks THEN
         Handle_Sector_ACKNAK( Ch )
      ELSE
         Ch := ACK;
                                   (* Update display *)
      IF Display_Status THEN
         Update_Xmodem_Send_Display;

   UNTIL ( Ch = ACK           ) OR
         ( Ch = CAN           ) OR
         ( Tries > Max_Tries  ) OR
         ( Stop_Send          ) OR
         ( Async_Carrier_Drop ) OR
         ( Do_WXModem         ) OR
         ( Do_SEALink         );
                                   (* Inc WXModem un-ACKd sector count *)

   INC( ACK_Window );

                                   (* Ensure Stop_Send TRUE if carrier *)
                                   (* dropped.                         *)

   Stop_Send := Stop_Send OR Async_Carrier_Drop;

END   (* Send_Xmodem_Block *);

(*----------------------------------------------------------------------*)
(*      Send_Telink_Header --- send out special block 0 for Telink      *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Telink_Header;

VAR
   Save_Size: INTEGER;
   Save_CRC : BOOLEAN;

BEGIN (* Send_Telink_Header *)
                                   (* Always send TELINK in Checksum mode *)
   Max_Tries     := 3;
   Save_Size     := Sector_Size;
   Save_CRC      := CRC_Used;
   Sector_Size   := 128;
   CRC_Used       := FALSE;
   Header_Ch     := CHR( SYN );

   Send_Xmodem_Block;

   Sector_Size   := Save_Size;
   CRC_Used       := Save_CRC;
   Max_Tries     := Xmodem_Max_Errors;

   IF Display_Status THEN
      IF ( Ch = ACK ) THEN
         Display_Send_Error( 'Telink header accepted.' , FALSE )
      ELSE
         Display_Send_Error( 'Telink header not accepted.' , FALSE );

END   (* Send_Telink_Header *);

{
(*----------------------------------------------------------------------*)
(*      Send_SEAlink_Header --- send out special block 0 for SEAlink    *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_SEAlink_Header;

VAR
   Save_Size: INTEGER;

BEGIN (* Send_SEAlink_Header *)

   Max_Tries     := 3;
   Save_Size     := Sector_Size;
   Sector_Size   := 128;
   Header_Ch     := CHR( SOH );
   CRC_Used      := TRUE;
   Do_SEALink    := FALSE;

   Send_Xmodem_Block;

   Sector_Size   := Save_Size;
   Max_Tries     := Xmodem_Max_Errors;
   Do_SEALink    := TRUE;

   IF Display_Status THEN
      IF ( Ch = ACK ) THEN
         Display_Send_Error( 'SEAlink header accepted.' , FALSE )
      ELSE
         Display_Send_Error( 'SEAlink header not accepted.' , FALSE );

END   (* Send_SEAlink_Header *);
}

(*----------------------------------------------------------------------*)
(*      Send_Ymodem_Header --- send out special block 0 for Ymodem      *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Ymodem_Header;

VAR
   Save_Size: INTEGER;
   Save_ACK : BOOLEAN;

BEGIN (* Send_Ymodem_Header *)
                                   (* Always send short block 0 *)
   Max_Tries     := 3;
   Save_Size     := Sector_Size;
   Sector_Size   := 128;
   Header_Ch     := CHR( SOH );
   Save_ACK      := Do_ACKs;
   Do_ACKs       := TRUE;

   Send_Xmodem_Block;

   Sector_Size := Save_Size;
   Do_ACKs     := Save_ACK;
   Max_Tries   := Xmodem_Max_Errors;

   IF Display_Status THEN
      IF ( Ch = ACK ) THEN
         Display_Send_Error( 'Ymodem header accepted.' , FALSE )
      ELSE
         Display_Send_Error( 'Ymodem header not accepted.' , FALSE );

END   (* Send_Ymodem_Header *);

(*----------------------------------------------------------------------*)

BEGIN (* Send_Xmodem_File *)
                                   (* Remember CRC checking *)
   CRC_Used := Use_CRC;
                                   (* Get file name for transfer *)

   Add_Path( FileName, Upload_Dir_Path, XFile_Name );

                                   (* Get Xmodem transfer display *)
   Get_Xmodem_Titles;

   FileMode := 0;

   ASSIGN( XFile , XFile_Name );
      (*!I-*)
   RESET ( XFile , 1 );
      (*!I+*)

   FileMode := 2;

   IF ( Int24Result <> 0 ) THEN
      BEGIN
         WRITE('Cannot open file to send, transfer cancelled.');
         Cancel_Transfer;
         Window_Delay;
         Restore_Screen_And_Colors( Saved_Screen );
         EXIT;
      END;
                                   (* Get file size in characters.      *)

   XFile_Size  := FileSize( XFile );
   R_File_Size := XFile_Size;
                                   (* Number of retries of bad block *)

   Max_Tries   := Xmodem_Max_Errors;

                                   (* Figure approx. time for upload *)

   Blocks_To_Send     := ROUND( ( XFile_Size / 128 ) + 0.49 );
   Saved_Time_To_Send := ROUND( Blocks_To_Send * ( Trans_Time_Val / Baud_Rate ) );
   Time_To_Send       := Saved_Time_To_Send;

                                   (* Hide cursor *)
   CursorOff;
                                   (* Headings for status information *)
   Initialize_Send_Display;

   STR( R_File_Size , SCps );
   Write_Log('Size of file to send is ' + SCps + ' bytes', TRUE, FALSE );

                                   (* Determine sector size             *)
                                   (* Note:  If Ymodem and downsizing   *)
                                   (*        allowed, and file is < 1K, *)
                                   (*        use short sectors.         *)
                                   (* Also set header character.        *)
   Header_Ch := CHR( SOH );

   IF ( Transfer_Protocol IN [Xmodem_1K, Xmodem_1KG, Ymodem_Batch, Ymodem_G] ) THEN
      BEGIN
         IF ( DownSize_Ymodem AND ( XFile_Size < 1024 ) ) THEN
            BEGIN
               Sector_Size := 128;
               Display_Send_Error('Switching to 128 byte blocks', FALSE);
            END
         ELSE
            BEGIN
               Sector_Size := 1024;
               Header_Ch := CHR( STX );
            END
      END
   ELSE
      Sector_Size := 128;

   New_Header_Ch := Header_Ch;

                                   (* Sector #s start at 1, wrap at 255 *)
   Sector_Number := 0;
   Sector_Count  := 0;
                                   (* No errors yet                     *)
   Send_Errors   := 0;
                                   (* Set TRUE if errors halt transfer  *)
   Stop_Send     := FALSE;
                                   (* Starting time for transfer        *)
   Start_Time    := TimeOfDay;
                                   (* Set EOF on XFile to FALSE         *)
   EOF_XFile     := FALSE;
                                   (* Set Alt_S encountered off         *)
   Alt_S_Pressed   := FALSE;
                                   (* No retries yet                    *)
   Tries         := 0;
                                   (* Assume ACKs                       *)
   Do_ACKs       := TRUE;
                                   (* Assume no windowing to be done    *)
   Do_WXModem    := FALSE;
   Do_SeaLink    := FALSE;
   ACK_Window    := 0;
   Max_ACK_Window:= 0;
                                   (* Set up for SeaLink                *)
{
   IF ( Transfer_Protocol = SeaLink ) THEN
      BEGIN
         Do_SeaLink       := TRUE;
         Max_Window_Size  := 6;
         Max_Window_Size1 := 7;
         Max_ACK_Window   := Max_Window_Size;
      END;
}
                                   (* Purge receive buffer              *)
   Async_Purge_Buffer;
                                   (* Save Xon/Xoff status              *)

   Save_XonXoff     := Async_Do_XonXoff;
   Async_Do_XonXoff := Honor_Xoff_Ymodem AND
                       ( Transfer_Protocol IN Ymodem_Family );

                                   (* Do initial handshaking          *)
   Do_Initial_Handshake;
                                   (* If Telink or Ymodem, send the   *)
                                   (* special initial sector, already *)
                                   (* prepared in Send_Modem7_File or *)
                                   (* Send_Ymodem_File                *)
   IF ( NOT Stop_Send ) THEN
      IF ( Transfer_Protocol IN [Ymodem_Batch, Ymodem_G] ) OR
         ( ( Transfer_Protocol IN [Xmodem_1K, Xmodem_1KG] ) AND Use_Ymodem_Header ) THEN
         BEGIN
            Send_Ymodem_Header;
            CRC_Used := TRUE;
            Do_Initial_Handshake;
         END
      ELSE IF ( Transfer_Protocol = Telink ) THEN
         BEGIN
            Send_Telink_Header;
            CRC_Used := TRUE;
         END
{
      ELSE IF ( Transfer_Protocol = SEALink ) THEN
         Send_SEALink_Header };

                                   (* Begin loop over blocks in file    *)
   REPEAT
                                   (* See if Alt-S hit, ending transfer *)
      Check_Keyboard;

      Stop_Send := Stop_Send OR ( NOT Async_Carrier_Detect );

      IF ( NOT Stop_Send ) THEN
         BEGIN (* Send the next sector *)

                                   (* Set block header character        *)

            Header_Ch := New_Header_Ch;

                                   (* Read Sector_size chars from file  *)
                                   (* to be sent.                       *)

            BlockRead( XFile, Sector_Data, Sector_Size, NRead );

                                   (* Check for error *)

            IF ( Int24Result <> 0 ) THEN
               BEGIN
                  Display_Send_Error('Cannot read data from file', TRUE);
                  Stop_Send := TRUE;
               END
                                   (* If no chars. read, then EOF      *)

            ELSE IF ( NRead <= 0 ) THEN
               EOF_XFile := TRUE
            ELSE
               BEGIN   (* NOT Eof *)

                                   (* Fill out short sector with 0s     *)

                  IF ( NRead < Sector_Size ) THEN
                     FILLCHAR( Sector_Data[NRead+1], Sector_Size - NRead + 1,
                               0 );

                                   (* Increment sector number           *)

                  INC( Sector_Number );
                  Sector_Count := Sector_Count + ( Sector_Size SHR 7 );

                                   (* Send the block *)

                  Send_Xmodem_Block;

                                   (* If Windowing, check if ACK.  If *)
                                   (* not, backup to offending sector *)
                                   (* and try again.                  *)

                  IF ( Do_WXModem OR Do_SeaLink ) THEN
                     IF ( Ch = NAK ) THEN
                        BEGIN
                           Sector_Number := Sector_Number - ACK_Window;
                           L             := ( ACK_Window + 1 ) * Sector_Size;
{
                           I := Relative_Position_File_Handle( XFile_Handle, -L );
}
                           SEEK( XFile , FilePos( XFile ) - L );
                           EOF_XFile  := FALSE;
                           XFile_Size := XFile_Size + L;
                           GOTO 1;
                        END;
                                   (* Update transmit time and counts *)
                                   (* of good/bad sectors; also shift *)
                                   (* to 128 byte sectors in Ymodem   *)
                                   (* if ratio of bad/good > 1/6 or   *)
                                   (* less than 1024 bytes left.      *)

                  IF Ch = ACK THEN
                     BEGIN
                        Time_To_Send := ROUND( Saved_Time_To_Send *
                                         ( 1.0 -
                                           Sector_Count / Blocks_To_Send ) );
                        IF Time_To_Send < 0 THEN Time_To_Send := 0;
                        INC( Good_Sectors );
                     END
                  ELSE
                     BEGIN
                        INC( Bad_Sectors );
                        IF ( Bad_Threshhold * Bad_Sectors > Good_Sectors ) AND
                           ( Downsize_Ymodem ) AND ( Sector_Size = 1024 ) THEN
                           BEGIN
                              New_Header_Ch := CHR( SOH );
                              Sector_Size   := 128;
                              Display_Send_Error('Switching to 128 byte blocks',
                                                 FALSE);
                           END;
                     END;
                                   (* Alter sector size if Ymodem and *)
                                   (* less than a Ymodem block left,  *)
                                   (* and downsizing allowed.         *)

                  XFile_Size := XFile_Size - NRead;

                  IF ( ( XFile_Size < 1024 ) AND DownSize_Ymodem AND
                       ( Sector_Size = 1024 ) ) THEN
                     BEGIN
                        New_Header_Ch := CHR( SOH );
                        Sector_Size   := 128;
                        Display_Send_Error('Switching to 128 byte blocks',
                                           FALSE);
                     END;

               END (* Not EOF *)

         END (* Send Next Sector *);

                                   (* Update display *)
1:       IF Display_Status THEN
            BEGIN
               GoToXY( 26 , 6 );
               WRITE( TimeString( Time_To_Send , Military_Time ) );
            END;

   UNTIL ( EOF_XFile ) OR ( Tries = Max_Tries ) OR ( Ch = CAN ) OR
         ( Stop_Send );
                                   (* If Windowing, wait for final  *)
                                   (* ACKs to show up.              *)

   IF ( Do_WXModem OR Do_SeaLink ) THEN
      BEGIN
         Max_ACK_Window := 0;
         WHILE( ( ACK_Window > 0 ) AND ( Ch <> CAN ) AND ( Ch <> TimeOut ) ) DO
            Handle_Sector_ACKNAK( Ch );
      END;

                                   (* Send CANs to host to cancel *)
                                   (* transfer                    *)
   IF Stop_Send THEN
      IF Async_Carrier_Detect THEN
         Cancel_Transfer;

   IF Tries >= Max_Tries THEN   (* We failed to send a sector correctly *)
      Display_Send_Error('No ACK ever received.' , FALSE)
   ELSE IF ( Ch = CAN ) THEN   (* Receiver cancelled transmission *)
      Display_Send_Error('Receiver cancelled transmission.',FALSE)
   ELSE IF Alt_S_Pressed  THEN (* User cancelled transmission *)
      Display_Send_Error('Alt-S hit, send cancelled.',FALSE)
   ELSE IF ( NOT Stop_Send ) THEN  (* We sent everything, try sending EOT *)
      BEGIN

         IF ( NOT Display_Status ) THEN
            Flip_Display_Status;
                                   (* Wait for output buffer to drain *)
                                   (* if not doing ACKs               *)
         IF ( NOT Do_Acks ) THEN
            BEGIN
               GoToXY( 26 , 8 );
               WRITE('Waiting for output buffer to drain');
               ClrEol;
               WHILE ( ( Async_OBuffer_Used > 128 ) AND ( NOT Stop_Send ) ) DO
                  BEGIN
                     Check_Keyboard;
                     Stop_Send := Stop_Send OR ( NOT Async_Carrier_Detect );
                     GiveAwayTime( 1 );
                  END;
            END;
                                   (* Now indicate we're waiting for *)
                                   (* ACK for EOT                    *)
         GoToXY( 26 , 8 );
         WRITE('Waiting for ACK of EOT');
         ClrEol;

         Tries   := 0;
         Do_ACKs := TRUE;

         REPEAT

            Async_Send( CHR( EOT ) );

            INC( Tries );

            Xmodem_Wait_For_Ch( Xmodem_Ack_Wait , Ch );

            IF Ch = CAN THEN
               Xmodem_Wait_For_Ch( Xmodem_Ack_Wait , Ch );

            IF Display_Status THEN
               BEGIN
                  IF ( Tries > 1 ) THEN
                     INC( Send_Errors );
                  Update_Xmodem_Send_Display;
                  GoToXY( 26 , 6 );
                  WRITE( TimeString( Time_To_Send , Military_Time ) );
               END;

            Check_Keyboard;

         UNTIL ( Ch    = ACK       ) OR
               ( Tries = Max_Tries ) OR
               ( Ch    = CAN       ) OR
               Stop_Send;

         IF ( NOT Display_Status ) THEN
            Flip_Display_Status;

         IF Tries = Max_Tries THEN
            Display_Send_Error('No ACK on EOT (end of transmission)', FALSE)
         ELSE IF ( Ch = CAN ) THEN
            Display_Send_Error('Receiver cancelled transmission.' , FALSE)
         ELSE IF ( Alt_S_Pressed OR Stop_Send ) THEN
            Display_Send_Error('Alt-S key hit, send cancelled.',FALSE)
         ELSE
            BEGIN

               GoToXY( 26 , 8 );
               WRITE('EOT acknowledged, send complete.');
               ClrEol;

               End_Time       := TimeOfDay;

               IF End_Time < Start_Time THEN
                  End_Time := End_Time + 86400;

               Effective_Rate := End_Time - Start_Time;

               IF ( Effective_Rate = 0.0 ) THEN
                  Effective_Rate := 1.0;

               Effective_Rate := R_File_Size / Effective_Rate;

               Window_Delay;

               GoToXY( 26 , 8 );
               WRITE('Transfer rate was ',Effective_Rate:6:1,' CPS');
               ClrEol;

               Write_Log( 'Send completed.', TRUE, FALSE );

               STR( Effective_Rate:6:1 , SCps );
               Write_Log('Transfer rate was ' + SCps + ' CPS', TRUE, FALSE );

            END;

      END;

   IF ( NOT Display_Status ) THEN
      Flip_Display_Status;

   IF Stop_Send THEN
      IF Async_Carrier_Drop THEN
         Display_Send_Error('Carrier dropped.' , FALSE );

                                      (* Close transferred file           *)
   CLOSE( XFile );
   I := Int24Result;

   Window_Delay;
                                   (* Remove XMODEM window             *)

   Restore_Screen_And_Colors( Saved_Screen );

                                   (* Turn cursor back on *)
   CursorOn;
                                   (* Restore XON/XOFF status *)

   Async_Do_XonXoff := Save_XonXoff;

                                   (* Restore status line *)
   IF Do_Status_Line THEN
      BEGIN
         Set_Status_Line_Name( Short_Terminal_Name );
         Write_To_Status_Line( Status_Line_Name, 1 );
      END;

END   (* Send_Xmodem_File *);
