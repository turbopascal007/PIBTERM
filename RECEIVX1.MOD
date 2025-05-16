(*----------------------------------------------------------------------*)
(*           Receive_Xmodem_File --- Download file using XMODEM         *)
(*----------------------------------------------------------------------*)

PROCEDURE Receive_Xmodem_File( Use_CRC : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Receive_Xmodem_File                                  *)
(*                                                                      *)
(*     Purpose:    Downloads file from remote host using XMODEM         *)
(*                 protocol.                                            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Receive_Xmodem_File( Use_CRC );                               *)
(*                                                                      *)
(*           Use_CRC --- TRUE to use Cyclic redundancy check version    *)
(*                       of XMODEM; FALSE to use Checksum version.      *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The transmission parameters are automatically set to:         *)
(*                                                                      *)
(*               Current baud rate, 8 bits, No parity, 1 stop           *)
(*                                                                      *)
(*        and then they are automatically restored to the previous      *)
(*        values when the transfer is complete.                         *)
(*                                                                      *)
(*        This code actually controls file reception using any of the   *)
(*        Xmodem-based protocols:  Xmodem, Modem7, Telink, and Ymodem.  *)
(*                                                                      *)
(*     Calls:   PibTerm_KeyPressed                                      *)
(*              Async_Send                                              *)
(*              Async_Receive                                           *)
(*              Async_Receive_With_TimeOut                              *)
(*              Async_Purge_Buffer                                      *)
(*              Update_Xmodem_Receive_Display                           *)
(*              Display_Receive_Error                                   *)
(*              Receive_Xmodem_Sector                                   *)
(*              Receive_Telink_Header                                   *)
(*              Receive_Ymodem_Header                                   *)
(*              Wait_For_SOH                                            *)
(*              Set_File_Date_And_Time                                  *)
(*              Draw_Menu_Frame                                         *)
(*              Open_Receiving_File                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   XOFF_Delay    = 250             (* WXModem XOFF delay time           *);
   WXmodem_Flush = 4               (* Blocks to flush when error        *);
   SEALink_Flush = 6               (* Blocks to flush when error        *);

VAR
   Sector_Count  : INTEGER         (* Sector count -- no wrap at 255    *);
   Sector_Comp   : BYTE            (* Complement of current sector #    *);
   Sector_Prev   : BYTE            (* Previous sector number            *);
   I             : INTEGER         (* Loop index                        *);
   Error_Count   : INTEGER         (* # of errors encountered           *);
   Ch            : INTEGER         (* Character read from COM port      *);
   Error_Flag    : BOOLEAN         (* IF an error is found              *);
   Initial_Ch    : INTEGER         (* Initial character                 *);
   Sector_Length : INTEGER         (* Sector Length                     *);
   Sector_Prev1  : BYTE            (* Previous sector + 1               *);
   BlockL_Errors : INTEGER         (* Counts block length errors        *);
   SOH_Errors    : INTEGER         (* Counts SOH errors                 *);
   BlockN_Errors : INTEGER         (* Counts block number errors        *);
   Comple_Errors : INTEGER         (* Counts complement errors          *);
   TimeOut_Errors: INTEGER         (* Counts timeout errors             *);
   Resend_Errors : INTEGER         (* Counts resend block errors        *);
   CRC_Errors    : INTEGER         (* Counts checksum/crc errors        *);
   Effective_Rate: REAL            (* Effective baud rate of transfer   *);
   CRC_Tries     : INTEGER         (* Initial CRC tries                 *);
   WXM_Tries     : INTEGER         (* Initial WXModem tries             *);
   SOH_Time      : INTEGER         (* Seconds to wait for SOH           *);
   RFile_Size    : LONGINT         (* Actual file size                  *);
   RFile_Date    : LONGINT         (* File date/time                    *);
   File_Date     : WORD            (* MS DOS encoded file date          *);
   File_Time     : WORD            (* MS DOS encoded file time          *);
   RFile_Name    : AnyStr          (* Received file name, Ymodem        *);
   Truncate_File : BOOLEAN         (* TRUE to trunc. file to exact size *);
   RFile_Open    : BOOLEAN         (* TRUE if receiving file opened     *);
   XFile_Byte    : FILE OF BYTE    (* For truncating received file      *);
   OK_Transfer   : BOOLEAN         (* If transfer OK                    *);
   Block_Zero    : BOOLEAN         (* If block 0 encountered            *);

   RFile_Size_2  : LONGINT         (* File size from totalling sectors  *);

   Write_Count   : INTEGER         (* Number of bytes to write          *);
   Err           : INTEGER         (* Error flag for handle I/O         *);

                                   (* Write buffer pointer              *)
   Write_Buffer  : File_Handle_Buffer_Ptr;
   Buffer_Pos    : INTEGER         (* Current buffer position           *);
   Buffer_Length : WORD            (* Buffer length                     *);
   CRC_Used_2    : BOOLEAN         (* TRUE to use CRC method            *);
   Long_Buffer   : BOOLEAN         (* TRUE if separate buffer used      *);
   Kbd_Ch        : CHAR            (* Character entered from keyboard   *);
   Full_File_Name: AnyStr          (* Full file name of file to receive *);
   Dup_Block     : BOOLEAN         (* TRUE if duplicate block error     *);
   BS_Flag       : BOOLEAN         (* Swallows up duplicate block       *);
   W_Count       : INTEGER         (* Count to write                    *);

   Block_Start_Set : SET OF ^A..^Z (* Set of legal block start chars    *);
   SVal            : STRING[10]    (* For debugging conversions         *);
   Flush_Count     : INTEGER       (* Count of blocks to flush if bad   *);
   Save_XonXoff    : BOOLEAN       (* Saves XON/XOFF status             *);
   Err_Mess        : AnyStr        (* Error message                     *);
   G_Failure       : BOOLEAN       (* TRUE if G-type protocol failed    *);
   Save_XonOv      : BOOLEAN       (* Saves Xon/Xoff buffer overflow    *);
   SCps            : STRING[20]    (* String form of CPS transfer rate  *);

(*----------------------------------------------------------------------*)
(*           Open_Receiving_File --- open file to receive download      *)
(*----------------------------------------------------------------------*)

PROCEDURE Open_Receiving_File;

VAR
   Err        : INTEGER;
   B          : BOOLEAN;
   Local_Save : Saved_Screen_Ptr;

BEGIN (* Open_Receiving_File *)
                                   (* Check if file name given yet. *)
                                   (* If not, prompt for it.        *)
   IF ( FileName = '' ) THEN
      IF Attended_Mode THEN
         BEGIN

            B              := Do_Status_Time;
            Do_Status_Time := FALSE;

            Save_Partial_Screen( Local_Save, 1, Max_Screen_Line,
                                 Max_Screen_Col, Max_Screen_Line );

            PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line );

            GoToXY( 1 , Max_Screen_Line );

            WRITE('Enter file name to receive download: ');
            ClrEol;

            CursorOn;

            Read_Edited_String( FileName );

            CursorOff;

            Restore_Screen( Local_Save );

            Do_Status_Time := B;

         END
      ELSE
                                   (* No file name is death in unattended mode *)
         BEGIN

            GoToXY( 25 , 10 );
            WRITE('No file name received from remote system, receive cancelled.');
            ClrEol;

            Write_Log('No file name received from remote system, receive cancelled.',
                      TRUE, FALSE);

            Window_Delay;

            Error_Flag   := TRUE;
            Stop_Receive := TRUE;

         END;
                                   (* Append download directory name *)
                                   (* if necessary.                  *)

   IF ( FileName <> '' ) THEN
      BEGIN

         Add_Path( FileName, Download_Dir_Path, Full_File_Name );

                                   (* Open reception file *)

         IF ( NOT RFile_Open ) THEN
            BEGIN

               ASSIGN ( XFile , Full_File_Name );
               REWRITE( XFile , 1 );

               IF ( Int24Result <> 0 ) THEN
                  BEGIN

                     GoToXY( 25 , 10 );
                     WRITE('Cannot open file, receive cancelled.');
                     ClrEol;

                     Write_Log('Cannot open file, receive cancelled.',
                               TRUE, FALSE);

                     Window_Delay;

                     Stop_Receive := TRUE;
                     Error_Flag   := TRUE;

                  END
               ELSE
                  RFile_Open := TRUE;

            END;

         IF Rfile_Open THEN
            Write_Log('Receiving file ' + Full_File_Name, TRUE, FALSE );

      END;

END   (* Open_Receiving_File *);

(*----------------------------------------------------------------------*)
(* Update_Xmodem_Receive_Display --- Update display of Xmodem reception *)
(*----------------------------------------------------------------------*)

PROCEDURE  Update_Xmodem_Receive_Display;

BEGIN (* Update_Xmodem_Receive_Display *)

   GoToXY( 25 , 1 );
   WRITE( Sector_Count );
   GoToXY( 35 , 1 );
   WRITE( Sector_Count SHR 3, 'K' );
   GoToXY( 25 , 2 );
   WRITE(BlockL_Errors);
   GoToXY( 25 , 3 );
   WRITE(SOH_Errors);
   GoToXY( 25 , 4 );
   WRITE(BlockN_Errors);
   GoToXY( 25 , 5 );
   WRITE(Comple_Errors);
   GoToXY( 25 , 6 );
   WRITE(TimeOut_Errors);
   GoToXY( 25 , 7 );
   WRITE(Resend_Errors);
   GoToXY( 25 , 8 );
   WRITE(CRC_Errors);

   IF Display_Time THEN
      BEGIN
         GoToXY( 25 , 9 );
         WRITE( TimeString( Time_To_Send , Military_Time ) );
      END;

END   (* Update_Xmodem_Receive_Display *);

(*----------------------------------------------------------------------*)
(*     Display_Receive_Error --- Display XMODEM reception error         *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Receive_Error( Err_Text: AnyStr );

VAR
   S: STRING[10];

BEGIN (* Display_Receive_Error *)

   IF ( NOT Display_Status ) THEN
      Flip_Display_Status;

   STR( Sector_Count , S );
   Err_Mess := Err_Text + ' around block ' + S;

   GoToXY( 25 , 10 );
   WRITE(Err_Mess);
   ClrEol;

   Write_Log( Err_Mess, TRUE, FALSE );

   Error_Flag := TRUE;

END   (* Display_Receive_Error *);

(*----------------------------------------------------------------------*)
(* WXModem_Receive_With_TimeOut --- Get character from port for WXModem *)
(*----------------------------------------------------------------------*)

PROCEDURE WXModem_Receive_With_TimeOut( VAR Ch : INTEGER );

(* STRUCTURED *) CONST
   Special_Chars : SET OF BYTE = [DLE,SYN,XON,XOFF];

BEGIN (* WXModem_Receive_With_TimeOut *)

   Async_Receive_With_TimeOut( Xmodem_Char_Wait , Ch );

   IF Do_WXModem THEN
      IF ( Ch = DLE ) THEN
         BEGIN
            IF ( Ch IN Special_Chars ) THEN
               BEGIN
                  Async_Receive_With_TimeOut( Xmodem_Char_Wait , Ch );
                  IF ( Ch <> TimeOut ) THEN
                     Ch := Ch XOR 64;
               END
         END
      ELSE
         IF ( Ch = SYN ) THEN
            Ch := TimeOut;

END   (* WXModem_Receive_With_TimeOut *);

(*----------------------------------------------------------------------*)
(*           Receive_Xmodem_Sector --- Get sector using XMODEM          *)
(*----------------------------------------------------------------------*)

FUNCTION Receive_Xmodem_Sector( CRC_Used : BOOLEAN ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Receive_Xmodem_Sector                                *)
(*                                                                      *)
(*     Purpose:    Gets one sector using XMODEM protocol.               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        OK_Get := Receive_Xmodem_Sector( CRC_Used : BOOLEAN )         *)
(*                                       : BOOLEAN;                     *)
(*                                                                      *)
(*           CRC_Used --- TRUE to use Cyclic redundancy check version   *)
(*                       of XMODEM; FALSE to use Checksum version.      *)
(*           OK_Get  --- TRUE if sector received correctly              *)
(*                                                                      *)
(*     Calls:   Async_Send                                              *)
(*              Async_Receive_With_TimeOut                              *)
(*              Display_Receive_Error                                   *)
(*              Print_Spooled_File                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   CRC        : INTEGER;
   Checksum   : INTEGER;
   I          : INTEGER;
   Error_Fl   : BYTE;
   Receive_OK : BOOLEAN;

   Debug_Sect : ARRAY[1..128] OF CHAR ABSOLUTE Sector_Data;

BEGIN (* Receive_Xmodem_Sector *)

                                   (* Clear async error flags        *)

   Receive_OK := Async_Line_Error( Error_Fl );

                                   (* Pick up sector data, calculate *)
                                   (* checksum or CRC                *)

   Receive_Xmodem_Sector := FALSE;
   Receive_OK            := FALSE;

   Checksum    := 0;
   CRC         := 0;
                                   (* Sector length is 128 for usual *)
                                   (* Xmodem or Telink; is 1024 for  *)
                                   (* Ymodem.                        *)

   FOR I := 1 TO Sector_Length DO
      BEGIN
                                   (* Get next char from comm port *)
{
         IF Do_WXModem THEN
            WXModem_Receive_With_TimeOut( Ch )
         ELSE
            Xmodem_Receive_With_TimeOut( Ch );
}
         Async_Receive_With_TimeOut( Xmodem_Char_Wait , Ch );

                                   (* Check for timeout  *)
         IF ( Ch = TimeOut ) THEN
            BEGIN
               Display_Receive_Error('Block length error');
               INC( BlockL_Errors );
               EXIT;
            END;
                                   (* Store received character *)
         Sector_Data[I] := Ch;
                                   (* Update CRC or Checksum   *)
         IF CRC_Used THEN
            BEGIN
               CRC := SWAP( CRC ) XOR ORD( Ch );
               CRC := CRC XOR ( LO( CRC ) SHR 4 );
               CRC := CRC XOR ( SWAP( LO( CRC ) ) SHL 4 )
                          XOR ( LO( CRC ) SHL 5 );
            END
         ELSE
            Checksum := ( Checksum + Ch ) AND 255;

      END;
                                   (* Now get trailing CRC or  *)
                                   (* checksum value.          *)
   IF CRC_Used THEN
      BEGIN   (* Receive CRC *)
                                   (* Get first byte of CRC    *)
{
         IF Do_WXModem THEN
            WXModem_Receive_With_TimeOut( Ch )
         ELSE
            Xmodem_Receive_With_TimeOut( Ch );
}
         Async_Receive_With_TimeOut( Xmodem_Char_Wait , Ch );

                                   (* Check for timeout        *)
         IF ( Ch <> TimeOut ) THEN
            BEGIN  (* Byte CRC OK *)

                                   (* Update CRC               *)

               CRC := SWAP( CRC ) XOR ORD( Ch );
               CRC := CRC XOR ( LO( CRC ) SHR 4 );
               CRC := CRC XOR ( SWAP( LO( CRC ) ) SHL 4 )
                          XOR ( LO( CRC ) SHL 5 );

                                   (* Get second byte of CRC   *)
{
               IF Do_WXModem THEN
                  WXModem_Receive_With_TimeOut( Ch )
               ELSE
                  Xmodem_Receive_With_TimeOut( Ch );
}
               Async_Receive_With_TimeOut( Xmodem_Char_Wait , Ch );

                                   (* If not timeout, update CRC *)
                                   (* and check if it is zero.   *)
                                   (* Zero CRC means OK sector.  *)

               IF ( Ch <> TimeOut ) THEN
                  BEGIN  (* Byte 2 CRC OK *)

                     CRC := SWAP( CRC ) XOR ORD( Ch );
                     CRC := CRC XOR ( LO( CRC ) SHR 4 );
                     CRC := CRC XOR ( SWAP( LO( CRC ) ) SHL 4 )
                                XOR ( LO( CRC ) SHL 5 );

                     Receive_OK := ( CRC = 0 );

                  END    (* Byte 2 CRC OK *)
               ELSE
                  BEGIN  (* Byte 2 CRC TimeOut *)

                     Display_Receive_Error('Block length error');
                     INC( BlockL_Errors );

                  END    (* Byte 2 CRC TimeOut *)

            END   (* Byte 1 CRC OK *)

         ELSE
            BEGIN (* Byte 1 CRC TimeOut *)

               Display_Receive_Error('Block length error');
               INC( BlockL_Errors );

            END   (* Byte 1 CRC TimeOut *);

      END     (* Compute CRC *)

   ELSE
      BEGIN   (* Receive Checksum *)

                                   (* Read sector checksum, see if it matches *)
                                   (* what we computed from sector read.      *)
{
         IF Do_WXModem THEN
            WXModem_Receive_With_TimeOut( Ch )
         ELSE
            Xmodem_Receive_With_TimeOut( Ch );
}
         Async_Receive_With_TimeOut( Xmodem_Char_Wait , Ch );

         Receive_OK := ( Checksum = Ch );

      END    (* Receive Checksum *);

   Receive_Xmodem_Sector := Receive_OK AND
                            ( NOT Async_Line_Error( Error_Fl ) );

                                   (* Print character from spooled file *)
   IF Print_Spooling THEN
      Print_Spooled_File;

END   (* Receive_Xmodem_Sector *);

(*----------------------------------------------------------------------*)
(*           Receive_Telink_Header --- Get Telink block 0 header        *)
(*----------------------------------------------------------------------*)

PROCEDURE Receive_Telink_Header;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Receive_Telink_Header                                *)
(*                                                                      *)
(*     Purpose:    Gets Telink header block 0 (filename+size+date)      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Receive_Telink_Header;                                        *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Trim                                                          *)
(*        Dir_Convert_Time                                              *)
(*        Dir_Convert_Date                                              *)
(*        Draw_Menu_Frame                                               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I      : INTEGER;
   CDate  : STRING[8];
   CTime  : STRING[8];
   Date   : LONGINT;
   DTRec  : DateTime;

   Debug_Sector_Data : PACKED ARRAY[1..44] OF CHAR ABSOLUTE Sector_Data;

BEGIN  (* Receive_Telink_Header *)

   RFile_Size := 0;
   RFile_Name := '';
                                   (* Get file size *)
   FOR I := 4 DOWNTO 1 DO
      RFile_Size := RFile_Size * 256 + Sector_Data[I];

   Blocks_To_Send := ROUND( RFile_Size / 128.0 + 0.49 );

                                   (* Get time/date *)

   IF ( Transfer_Protocol = Telink ) THEN
      BEGIN
         File_Time := Sector_Data[6] SHL 8 OR Sector_Data[5];
         File_Date := Sector_Data[8] SHL 8 OR Sector_Data[7];
      END
   ELSE
      BEGIN

         Date := ORD( Sector_Data[8] ) SHL 8 + ORD( Sector_Data[7] );
         Date := 65536 * Date + ORD( Sector_Data[6] ) SHL 8 + ORD( Sector_Data[5] );

         IF ( Date > 0 ) THEN
            WITH DTRec DO
               BEGIN

                  Get_Unix_Style_Date( Date, Year, Month, Day, Hour, Min, Sec );

                  File_Time := Hour SHL 11 OR Min SHL 5 OR ( Sec DIV 2 );
                  File_Date := MAX( Year - 1980 , 0 ) SHL 9 + Month SHL 5 + Day;

               END;

      END;
                                   (* Get file name *)
   FOR I := 9 TO 24 DO
      IF Sector_Data[I] <> 0 THEN
         RFile_Name := RFile_Name + CHR( Sector_Data[I] );

   RFile_Name := TRIM( RFile_Name );

   IF ( FileName = '' ) THEN
      IF ( RFile_Name <> '' ) THEN
         FileName := RFile_Name;

   Draw_Menu_Frame( 10, 10, 78, 23, Menu_Frame_Color, Menu_Title_Color,
                    Menu_Text_Color,
                    'Receive file ' + FileName );

   IF ( ( File_Date <> 0 ) AND ( File_Time <> 0 ) ) THEN
      BEGIN
         Dir_Convert_Time( File_Time, CTime );
         Dir_Convert_Date( File_Date, CDate );
      END
   ELSE
      BEGIN
         CTime := '';
         CDate := '';
      END;

   Draw_Menu_Frame( 10, 3, 78, 9, Menu_Frame_Color, Menu_Title_Color,
                    Menu_Text_Color, '' );

                                   (* Headings for Telink information *)
   PibTerm_Window( 11, 4, 77, 8 );

   GoToXY( 1 , 1 );
   TextColor( Menu_Text_Color_2 );
   WRITE(' File name            : ');
   TextColor( Menu_Text_Color );
   WRITE(FileName);
   GoToXY( 1 , 2 );
   TextColor( Menu_Text_Color_2 );
   WRITE(' File Size in bytes   : ');
   TextColor( Menu_Text_Color );
   WRITE(RFile_Size:8);
   GoToXY( 1 , 3 );
   TextColor( Menu_Text_Color_2 );
   WRITE(' File Size in blocks  : ');
   TextColor( Menu_Text_Color );
   WRITE(Blocks_To_Send:8);
   GoToXY( 1 , 4 );
   TextColor( Menu_Text_Color_2 );
   WRITE(' File creation time   : ');
   TextColor( Menu_Text_Color );
   WRITE( CTime );
   GoToXY( 1 , 5 );
   TextColor( Menu_Text_Color_2 );
   WRITE(' File creation date   : ');
   TextColor( Menu_Text_Color );
   WRITE( CDate );
                                   (* Restore previous window *)
   PibTerm_Window( 11, 11, 77, 21 );

   IF RFile_Size > 0 THEN
      BEGIN

         Display_Time       := TRUE;
         Time_To_Send       := ROUND( Blocks_To_Send * ( Trans_Time_Val / Baud_Rate ) );
         Saved_Time_To_Send := Time_To_Send;

         IF Display_Status THEN
            Initialize_Receive_Display;

         Truncate_File  := TRUE;

      END;
{
                                   (* Handle SEALink file name *)
   IF Do_SeaLink THEN
      BEGIN
                                   (* Prevent clobbers in host mode *)
         IF Host_Mode THEN
            IF ( Privilege <> 'S' ) THEN
               Stop_Receive := Stop_Receive OR
                               Check_If_File_Exists( FileName , Download_Dir_Path );

                                  (* If null file name, this means *)
                                  (* end of SEALink batch, so quit. *)

         IF LENGTH( RFile_Name ) = 0 THEN
            BEGIN
               Null_File_Name := TRUE;
               EXIT;
            END;
                                   (* Open reception file     *)

         IF ( NOT Stop_Receive ) THEN
            Open_Receiving_File;

      END;
}
END    (* Receive_Telink_Header *);

(*----------------------------------------------------------------------*)
(*           Receive_Ymodem_Header --- Get Ymodem block 0 header        *)
(*----------------------------------------------------------------------*)

PROCEDURE Receive_Ymodem_Header;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Receive_Ymodem_Header                                *)
(*                                                                      *)
(*     Purpose:    Gets Ymodem header block 0 (filename+size+date)      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Receive_Ymodem_Header                                         *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Draw_Menu_Frame                                               *)
(*        Dir_Convert_Time                                              *)
(*        Dir_Convert_Date                                              *)
(*        Open_Receiving_File                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I     : INTEGER;
   L     : INTEGER;
   CTime : STRING[10];
   CDate : STRING[10];
   DTRec : DateTime;

BEGIN  (* Receive_Ymodem_Header *)

   RFile_Size := 0;
   RFile_Date := 0;
   RFile_Name := '';
   File_Time  := 0;
   File_Date  := 0;
                                   (* Pick up file name *)
   I := 1;
   WHILE( Sector_Data[I] <> NUL ) AND ( Sector_Data[I] <> ORD(' ') ) DO
      BEGIN
         RFile_Name := RFile_Name + CHR( Sector_Data[I] );
         INC( I );
      END;
                                  (* If null file name, this means *)
                                  (* end of Ymodem batch, so quit. *)
   IF LENGTH( RFile_Name ) = 0 THEN
      BEGIN
         Null_File_Name := TRUE;
         EXIT;
      END;
                                  (* Pick up file size *)
   INC( I );

   WHILE( Sector_Data[I] <> NUL ) AND ( Sector_Data[I] <> ORD(' ') ) DO
      BEGIN
         RFile_Size := RFile_Size * 10 + ORD( Sector_Data[I] ) - ORD('0');
         INC( I );
      END;

   INC( I );

   WHILE( Sector_Data[I] <> NUL ) AND ( Sector_Data[I] <> ORD(' ') ) DO
      BEGIN
         RFile_Date := RFile_Date * 8 + ORD( Sector_Data[I] ) - ORD('0');
         INC( I );
      END;

   IF RFile_Date > 0 THEN
      WITH DTRec DO
         BEGIN

            Get_Unix_Style_Date( RFile_Date, Year, Month, Day, Hour, Min, Sec );

            File_Time := Hour SHL 11 OR Min SHL 5 OR ( Sec DIV 2 );
            File_Date := MAX( Year - 1980 , 0 ) SHL 9 + Month SHL 5 + Day;

            Dir_Convert_Time( File_Time, CTime );
            Dir_Convert_Date( File_Date, CDate );

      END;

   Draw_Menu_Frame( 10, 3, 78, 9, Menu_Frame_Color, Menu_Title_Color,
                    Menu_Text_Color,
                    'Receive file ' + RFile_Name );

                                   (* Headings for Ymodem information *)
   PibTerm_Window( 11, 4, 77, 8 );

   GoToXY( 1 , 1 );
   TextColor( Menu_Text_Color_2 );
   WRITE(' File name            : ');
   TextColor( Menu_Text_Color );
   WRITE(RFile_Name);

   Blocks_To_Send := ROUND( RFile_Size / 128.0 + 0.49 );

   IF RFile_Size > 0 THEN
      BEGIN
         GoToXY( 1 , 2 );
         TextColor( Menu_Text_Color_2 );
         WRITE(' File Size in bytes   : ');
         TextColor( Menu_Text_Color );
         WRITE(RFile_Size:8);
         GoToXY( 1 , 3 );
         TextColor( Menu_Text_Color_2 );
         WRITE(' File Size in blocks  : ');
         TextColor( Menu_Text_Color );
         WRITE(Blocks_To_Send:8);
      END;

   IF File_Date > 0 THEN
      BEGIN
         GoToXY( 1 , 4 );
         TextColor( Menu_Text_Color_2 );
         WRITE(' File creation time   : ');
         TextColor( Menu_Text_Color );
         WRITE( CTime );
         GoToXY( 1 , 5 );
         TextColor( Menu_Text_Color_2 );
         WRITE(' File creation date   : ');
         TextColor( Menu_Text_Color );
         WRITE( CDate );
      END;
                                   (* If path name sent along with *)
                                   (* file name, strip it unless   *)
                                   (* "Use_Full_Path_Name" option  *)
                                   (* is active.                   *)
   FileName := RFile_Name;

   IF ( ( POS( '\' , FileName ) <> 0 ) OR
        ( POS( ':' , FileName ) <> 0 ) ) THEN
      IF ( NOT Use_Full_Path_Name ) THEN
         BEGIN
            L := LENGTH( FileName );
            I := L;
            REPEAT
               DEC( I );
            UNTIL ( ( I = 1 )             OR
                    ( FileName[I] = '\' ) OR
                    ( FileName[I] = ':' )     );
            FileName := COPY( FileName, SUCC( I ), L - I );
         END;
                                   (* Restore previous window *)
   PibTerm_Window( 11, 11, 77, 21 );

   IF Rfile_Size > 0 THEN
      BEGIN

         Display_Time       := TRUE;
         Time_To_Send       := ROUND( Blocks_To_Send * ( Trans_Time_Val / Baud_Rate ) );
         Saved_Time_To_Send := Time_To_Send;

         IF Display_Status THEN
            Initialize_Receive_Display;

         Truncate_File  := ( RFile_Size > 0 );

      END;
                                   (* Prevent clobbers in host mode *)
   IF Host_Mode THEN
      IF ( Privilege <> 'S' ) THEN
         Stop_Receive := Stop_Receive OR
                         Check_If_File_Exists( FileName , Download_Dir_Path );

                                   (* Open reception file     *)
   IF ( NOT Stop_Receive ) THEN
      Open_Receiving_File;
                                   (* Post name in display window *)

   IF ( RFile_Name = '' ) THEN
      BEGIN
         PibTerm_Window( 11, 4, 77, 8 );
         GoToXY( 1 , 1 );
         TextColor( Menu_Text_Color_2 );
         WRITE(' File name            : ');
         TextColor( Menu_Text_Color );
         WRITE(FileName);
         PibTerm_Window( 11, 11, 77, 21 );
      END;
                                   (* Reset CRC counter       *)
   CRC_Tries := 0;
   CRC_Used  := TRUE;

END    (* Receive_Ymodem_Header *);

(*----------------------------------------------------------------------*)
(*        Wait_For_SOH --- Wait for start for start of XMODEM block     *)
(*----------------------------------------------------------------------*)

PROCEDURE Wait_For_SOH(     Wait_Time    : INTEGER;
                        VAR Initial_Ch   : INTEGER;
                        VAR Stop_Receive : BOOLEAN  );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Wait_For_SOH                                         *)
(*                                                                      *)
(*     Purpose:    Waits for SOH/STX/SYN initiating Xmodem block        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Wait_For_SOH(     Wait_Time    : INTEGER;                     *)
(*                      VAR Initial_Ch   : INTEGER;                     *)
(*                      VAR Stop_Receive : BOOLEAN );                   *)
(*                                                                      *)
(*           Wait_Time    --- time to wait for character in seconds     *)
(*           Initial_Ch   --- returned initial character                *)
(*           Stop_Receive --- TRUE if Alt-R hit to stop transfer        *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Async_Receive_With_TimeOut                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   ITime          : INTEGER;
   SOH_Start_Time : LONGINT;
   SOH_Char       : CHAR;

BEGIN  (* Wait_For_SOH *)
                                   (* If already cancelled transfer, *)
                                   (* don't look for more input!     *)
   Initial_Ch := TimeOut;

   IF Stop_Receive THEN EXIT;
                                   (* Look for start of Xmodem block *)
   ITime := 0;

   REPEAT

      INC( ITime );
      Initial_Ch     := TimeOut;
      SOH_Start_Time := TimeOfDayH;

      REPEAT
         IF Async_Receive( SOH_Char ) THEN
            BEGIN
               IF ( SOH_Char IN Block_Start_Set ) THEN
                  Initial_Ch := ORD( SOH_Char );
            END;
      UNTIL ( Initial_Ch <> TimeOut ) OR
            ( TimeDiffH( SOH_Start_Time , TimeOfDayH ) > 100 );

                                   (* Check for keyboard input -- Alt_R *)
                                   (* cancels transfer.                 *)
      Check_KeyBoard;
                                   (* Also stop transfer if carrier drops *)
      IF Async_Carrier_Drop THEN
         BEGIN
            Stop_Receive := TRUE;
            Initial_Ch   := TimeOut;
         END;
                                   (* Print character from spooled file *)
      IF Print_Spooling THEN
         Print_Spooled_File;

   UNTIL ( Stop_Receive          OR
           ( ITime > Wait_Time ) OR
           ( Initial_Ch <> TimeOut ) );

END    (* Wait_For_SOH *);

(*----------------------------------------------------------------------*)
(*       Set_File_Date_And_Time --- set file date and time stamp        *)
(*----------------------------------------------------------------------*)

PROCEDURE Set_File_Date_And_Time;

VAR
   Time : LONGINT;
   T    : ARRAY[1..2] OF WORD ABSOLUTE Time;

BEGIN (* Set_File_Date_And_Time *)

   T[1] := File_Time;
   T[2] := File_Date;

   SetFTime( XFile , Time );

   IF ( DosError <> 0 ) THEN
      BEGIN

         IF ( NOT Display_Status ) THEN
            Flip_Display_Status;

         GoToXY( 25 , 10 );
         WRITE('Could not set date/time for file.');
         ClrEol;

         Window_Delay;

         Write_Log('Cannot set date/time', TRUE, FALSE );

      END;

END   (* Set_File_Date_And_Time *);

(*----------------------------------------------------------------------*)
(*             Write_File_Data --- Write received data to file          *)
(*----------------------------------------------------------------------*)

PROCEDURE Write_File_Data;

PROCEDURE Do_Actual_Write( Write_Count: INTEGER );

BEGIN (* Do_Actual_Write *)
                                   (* Truncate file as necessary *)

   IF ( ( RFile_Size_2 + Write_Count ) > RFile_Size ) AND Truncate_File THEN
      Write_Count := TRUNC( RFile_Size - Rfile_Size_2 );

   W_Count := Write_Count;
                                   (* Stop data reception for WXModem *)
   IF Do_WXModem THEN
      BEGIN
         Async_Send( CHR( XOFF ) );
         DELAY( XOFF_Delay );
      END;

   BlockWrite( XFile, Write_Buffer^, W_Count, Write_Count );

   IF Do_WXModem THEN
      Async_Send( CHR( XON ) );

   IF ( Int24Result <> 0 ) OR ( Write_Count <> W_Count ) THEN
      BEGIN

         IF ( NOT Display_Status ) THEN
            Flip_Display_Status;

         GoToXY( 25 , 10 );
         WRITE('Error writing to disk, transfer cancelled.');
         Write_Log('Error writing to disk.' , TRUE, FALSE );
         ClrEol;
         Window_Delay;

         Error_Flag   := TRUE;
         Stop_Receive := TRUE;

      END;

   RFile_Size_2 := RFile_Size_2 + Write_Count;

END   (* Do_Actual_Write *);

(*----------------------------------------------------------------------*)

BEGIN (* Write_File_Data *)
                                   (* Make sure file is open *)
   IF ( NOT RFile_Open ) THEN
      BEGIN
         Open_Receiving_File;
         IF Stop_Receive THEN EXIT;
      END;
                                   (* Write directly from sector *)
                                   (* if not long buffer used    *)
   IF ( NOT Long_Buffer ) THEN
      Do_Actual_Write( Sector_Length )

                                   (* Store sector data in long  *)
                                   (* buffer and write file if   *)
                                   (* necessary.                 *)

   ELSE
      BEGIN

         IF ( Buffer_Pos + Sector_Length ) > Buffer_Length THEN
            BEGIN
               Do_Actual_Write( Buffer_Pos );
               Buffer_Pos   := 0;
            END;

         MOVE( Sector_Data, Write_Buffer^[ Buffer_Pos + 1 ], Sector_Length );

         Buffer_Pos := Buffer_Pos + Sector_Length;

      END;

END   (* Write_File_Data *);

