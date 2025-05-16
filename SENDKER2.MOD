(*----------------------------------------------------------------------*)
(*              Kermit_Send_File --- send file data itself              *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Send_File;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Kermit_Send_File                                     *)
(*                                                                      *)
(*     Purpose:    Sends file data packets to remote Kermit.            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Kermit_Send_File;                                             *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Build_And_Send_Packet_With_Retry                              *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

(*----------------------------------------------------------------------*)
(*              Send_Normal --- Send file without windowing             *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Normal;

VAR
   Prev_Packet_Num : INTEGER;

BEGIN (* Send_Normal *)
                                   (* Set address to build packets    *)

   Send_Packet_Ptr := ADDR( Sector_Data[Send_Offset] );

                                   (* Loop over file contents         *)

   IF ( NOT Kermit_Abort ) THEN
      REPEAT
                                   (* Increment packet number         *)

         Prev_Packet_Num      := Packet_Num;
         Packet_Num           := SUCC( Packet_Num ) MOD 64;
         Kermit_Window_Top    := Packet_Num;
         Kermit_Window_Bottom := Packet_Num;

                                    (* Get next block of data from file *)
         Get_File_Data;
                                    (* Construct and send data packet   *)

         IF ( Send_Packet_Length > 0 ) THEN
            Build_And_Send_Packet_With_Retry
         ELSE
            Packet_Num := Prev_Packet_Num;

      UNTIL File_Done OR Kermit_Abort;

END   (* Send_Normal *);

(*----------------------------------------------------------------------*)
(*              Send_Windowing --- Send file with windowing             *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Windowing;

VAR
   Data_Place  : INTEGER;
   Save_Retry  : INTEGER;
   Slow_Count  : INTEGER;

BEGIN  (* Send_Windowing *)
                                   (* Set window size                  *)

   Window_Size_Used := MAX( His_Kermit_Window_Size , 1 );

                                   (* Slow count is used to send the   *)
                                   (* first few data blocks slowly,    *)
                                   (* so that PCKermit and other       *)
                                   (* programs won't be unhappy.       *)

   Slow_Count       := MIN( Window_Size_Used , 3 );

                                   (* Need more retries with windows   *)
   Save_Retry    := Kermit_MaxTry;
   Kermit_MaxTry := Kermit_MaxTry + Window_Size_Used;

                                   (* Empty window at this point       *)
   Kermit_Window_Used   := 0;
   Kermit_Window_Top    := Packet_Num;
   Kermit_Window_Bottom := SUCC( Kermit_Window_Top ) MOD 64;
   Data_Place           := Send_Offset;
   Kermit_Window_Errors := 0;
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
                                   (* Loop over file contents          *)
   IF ( NOT Kermit_Abort ) THEN
      REPEAT
                                   (* If window full, wait for ACK/NAK *)

         IF ( Kermit_Window_Used >= Window_Size_Used ) THEN
            Check_Sliding_ACK( TRUE )

         ELSE                      (* Window not full -- construct and *)
                                   (* send next packet.                *)
            BEGIN
                                   (* Increment packet number          *)

               Packet_Num := SUCC( Kermit_Window_Top ) MOD 64;

                                   (* Increment window used count      *)

               INC( Kermit_Window_Used );
               Kermit_Window_Top  := Packet_Num;

                                   (* Set window data                  *)

               Data_Place      := Data_Place + 96;
               IF ( ( Data_Place + 96 ) > MaxSectorLength ) THEN
                  Data_Place := Send_Offset;

               Send_Packet_Ptr := ADDR( Sector_Data[Data_Place] );
{
               IF Kermit_Debug THEN
                  Write_Log( 'Data_Place = ' + IToS( Data_Place          ) , FALSE, FALSE );
}
               WITH Kermit_Queue[Kermit_Window_Top] DO
                  BEGIN
                     Data_Slot       := Data_Place;
{
                     IF Kermit_Debug THEN
                        Write_Log( 'Data_Slot = ' + IToS( Data_Slot          ) , FALSE, FALSE );
}
                     ACK_Flag        := FALSE;
                     Retry_Count     := 0;
                  END;
{
   IF Kermit_Debug THEN
      BEGIN
         Write_Log( '---------------', FALSE, FALSE );
         Write_Log( 'Window_Used   = ' + IToS( Kermit_Window_Used ) , FALSE, FALSE );
         Write_Log( 'Packet_Num    = ' + IToS( Packet_Num         ) , FALSE, FALSE );
         Write_Log( 'Window_Top    = ' + IToS( Kermit_Window_Top  ) , FALSE, FALSE );
         Write_Log( 'Window_Bottom = ' + IToS( Kermit_Window_Bottom ) , FALSE, FALSE );
      END;
}
                                   (* Get next block of data from file *)
               Get_File_Data;
                                   (* Construct and send data packet   *)
{
               IF Kermit_Debug THEN
                  Write_Log( 'Found length  = ' + IToS( Send_Packet_Length   ) , FALSE, FALSE );
}
               IF ( Send_Packet_Length > 0 ) THEN
                  BEGIN
                     Build_Packet;
                     Kermit_Queue[Kermit_Window_Top].Data_Length :=
                        Send_Packet_Length;
                     Send_Packet;
                     IF ( Slow_Count > 0 ) THEN
                        BEGIN
                           DEC( Slow_Count );
                           Async_Drain_Output_Buffer( Five_Seconds );
                        END;
                  END
                                   (* Nothing left to send -- back up *)
                                   (* window pointers.                *)
               ELSE
                  BEGIN
                     DEC( Kermit_Window_Used );
                     Kermit_Window_Top  := PRED( Kermit_Window_Top ) MOD 64;
                  END;
                                   (* Check if any ACK/NAKs have arrived *)
{
               Check_Sliding_ACK( FALSE );
}
            END;

      UNTIL File_Done OR Kermit_Abort;

{
   IF Kermit_Debug THEN
      BEGIN
         Write_Log( '---File Done---', FALSE, FALSE );
         Write_Log( 'Window_Used   = ' + IToS( Kermit_Window_Used ) , FALSE, FALSE );
         Write_Log( 'Window_Top    = ' + IToS( Kermit_Window_Top  ) , FALSE, FALSE );
         Write_Log( 'Window_Bottom = ' + IToS( Kermit_Window_Bottom ) , FALSE, FALSE );
         Write_Log( 'Packet_Num    = ' + IToS( Packet_Num           ) , FALSE, FALSE );
      END;
}
   IF ( NOT Kermit_Abort ) THEN
      BEGIN
                                   (* If entire file done and windowing,   *)
                                   (* wait for ACK of all outstanding      *)
                                   (* packets.                             *)

         IF ( Kermit_Window_Used > 0 ) THEN
            REPEAT
               Check_Sliding_Ack( TRUE )
            UNTIL ( Kermit_Abort OR ( Kermit_Window_Used = 0 ) );

                                   (* Make sure current packet number is   *)
                                   (* correct.                             *)

         Packet_Num    := Kermit_Window_Top;

      END;
                                   (* Restore old MaxTry *)
   Kermit_MaxTry := Save_Retry;

END    (* Send_Windowing *);

(*----------------------------------------------------------------------*)

BEGIN  (* Kermit_Send_File *)
                                   (* Send file packets until entire  *)
                                   (* file is sent OR transfer aborts *)

   Display_Kermit_Message('Sending ' + FileName);

                                   (* Send attribute packet if remote *)
                                   (* Kermit understands it.          *)
   IF Kermit_Attributes THEN
      BEGIN
         Kermit_Send_Attributes;
         IF ( NOT ACK_OK ) THEN
            BEGIN
               Kermit_State          := Send_Break;
               Kermit_Abort          := TRUE;
               Kermit_Abort_Level    := One_File;
               Kermit_Doing_Transfer := FALSE;
               EXIT;
            END;
      END;
                                   (* Choose transfer routine based upon *)
                                   (* windowing/no windowing             *)
   Kermit_Doing_Transfer := TRUE;

   IF Kermit_Do_Sliding_Win THEN
      Send_Windowing
   ELSE
      Send_Normal;
                                   (* If entire file done, prepare to send *)
                                   (* EOF packet.                          *)

   Kermit_Doing_Transfer := FALSE;

   IF ( File_Done OR Kermit_Abort ) THEN
      Kermit_State := Send_EOF;

END   (* Kermit_Send_File *);

(*----------------------------------------------------------------------*)
(*              Kermit_Send_EOF --- send end of file packet             *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Send_EOF;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Kermit_Send_EOF                                      *)
(*                                                                      *)
(*     Purpose:    Sends end of file packet to remote Kermit marking    *)
(*                 no more data in current file being transferred.      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Kermit_Send_EOF;                                              *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Build_And_Send_Packet_With_Retry                              *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Kermit_Send_EOF *)

                                   (* Prepare EOF packet *)

   Packet_Num          := SUCC( Packet_Num ) MOD 64;
   Send_Packet_Ptr^[4] := EOF_Packet;
   Send_Packet_Length  := 4;
                                   (* Add discard indicator if needed *)
   IF ( Kermit_Abort ) THEN
      BEGIN
         Send_Packet_Ptr^[5] := 'D';
         Send_Packet_Length  := 5;
      END;
                                   (* Send EOF Packet *)

   Build_And_Send_Packet_With_Retry;

                                   (* If OK then prepare to try *)
                                   (* for another file, if any  *)
   Kermit_State := Send_Break;

   Kermit_Abort := Kermit_Abort OR ( NOT ACK_OK );

END   (* Kermit_Send_EOF *);

(*----------------------------------------------------------------------*)
(*                 Kermit_Send_Break --- send break packet              *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Send_Break;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Kermit_Send_Break                                    *)
(*                                                                      *)
(*     Purpose:    Sends break packet to remote Kermit.                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Kermit_Send_Break;                                            *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Build_And_Send_Packet_With_Retry                              *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Kermit_Send_Break *)
                                   (* Construct break packet *)

   Kermit_State        := Send_Break;
   Packet_Num          := SUCC( Packet_Num ) MOD 64;
   Send_Packet_Ptr^[4] := Break_Packet;
   Send_Packet_Length  := 4;
                                   (* Send the break packet *)

   Build_And_Send_Packet_With_Retry;

                                   (* If OK, then sending of file complete *)
   IF ACK_OK THEN
      Send_Done := TRUE
   ELSE
      Kermit_Abort := TRUE;

END    (* Kermit_Send_Break *);

(*----------------------------------------------------------------------*)
(*       Kermit_Send_One_File --- Controls sending of a single file     *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Send_One_File;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Kermit_Send_One_File                                 *)
(*                                                                      *)
(*     Purpose:    Sends a single file to remote Kermit.                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Kermit_Send_One_File;                                         *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Draw_Menu_Frame                                               *)
(*        Initialize_Display                                            *)
(*        Open_File                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN  (* Kermit_Send_One_File *)
                                   (* Open file transfer display window *)

   Kermit_Menu_Title := 'Send file ' + FileName + ' using Kermit';

   Initialize_Display;
                                   (* Display init packet parameters   *)
   Display_Kermit_Init_Params;
                                   (* Try opening file to be sent      *)

   Open_File( Read_Open, FileName , Full_Name );

                                   (* If open went OK, then do transfer. *)
   IF ( Open_OK ) THEN
      BEGIN
                                   (* Ensure record read first time by *)
                                   (* pointing buffer pointer past end *)
                                   (* of file buffer.                  *)

         Buffer_Pos := Buffer_Size + 1;

                                   (* Loop over states in transfer until     *)
                                   (* transfer aborted OR file is completely *)
                                   (* sent.                                  *)

         Kermit_Transfer_Start := TimeOfDay;

         REPEAT

            CASE Kermit_State OF
               Send_Init        : Kermit_Send_Init;
               Send_File_Header : Kermit_Send_Header;
               Send_File        : BEGIN
                                     Kermit_Transfer_Start := TimeOfDay;
                                     Kermit_Send_File;
                                  END;
               Send_EOF         : Kermit_Send_EOF;
               Send_Break       : Send_Done := TRUE;
            END  (* CASE *);

         UNTIL Send_Done;
                                   (* Accumulate time for this transfer *)

         Kermit_Transfer_End  := TimeOfDay;
         Total_Time           := Total_Time + TimeDiff( Kermit_Transfer_Start,
                                                        Kermit_Transfer_End    );

      END  (* IF Open_OK *);

END    (* Kermit_Send_One_File *);

(*----------------------------------------------------------------------*)
(*   Do_Kermit_Send --- Controls sending of list of files in Kermit     *)
(*----------------------------------------------------------------------*)

PROCEDURE Do_Kermit_Send;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Do_Kermit_Send                                       *)
(*                                                                      *)
(*     Purpose:    Controls sending of list of files in Kermit          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Do_Kermit_Send;                                               *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Save_Screen                                                   *)
(*        Restore_Screen                                                *)
(*        Initialize_Display                                            *)
(*        Display_Kermit_Message                                        *)
(*        FindFirst                                                     *)
(*        FindNext                                                      *)
(*        Get_Kermit_File_Name                                          *)
(*        Kermit_Send_One_File                                          *)
(*        Reset_Global_Colors                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   S_Baud_Rate    : STRING[5];
   W_Str          : STRING[3];
   Send_Str       : AnyStr;
   Save_Close     : BOOLEAN;
   C_Trans_Rate_E : ShortStr;
   C_Trans_Rate_A : ShortStr;
   I              : INTEGER;

BEGIN  (* Do_Kermit_Send *)
                                   (* Hide cursor *)
   CursorOff;
                                   (* Save current screen             *)

   Save_Screen( Kermit_Local_Save );

                                   (* Open display window for transfer  *)
                                   (* Initialize status display information *)
   Packets_Sent      := 0;
   Packets_Received  := 0;
   Packets_Bad       := 0;
   Buffer_Num        := 0;
   Buffer_Num_Actual := 0;
   Buffer_Total      := 0;
   Kermit_MaxTry     := 5;
   Total_Time        := 0;
                                   (* Prepare Kermit to send initialization *)
                                   (* packet.                               *)
   Kermit_State := Send_Init;
                                   (* Not transferring file data yet *)
   Kermit_Doing_Transfer := FALSE;

                                   (* Display transfer headings      *)

   Kermit_Menu_Title := 'Send file using Kermit';

   Write_Log( Kermit_Menu_Title, FALSE, FALSE );

   Initialize_Display;
                                   (* See if we can find anything to *)
                                   (* be sent.                       *)

   FindFirst( File_Pattern, AnyFile, File_Entry );

   Stop_Send  := ( DosError <> 0 );

   IF Stop_Send THEN
      BEGIN
         Display_Kermit_Message('  No files found to send.');
         Window_Delay;
         Restore_Screen_And_Colors( Kermit_Local_Save );
         CursorOn;
         EXIT;
      END
   ELSE                            (* Wait for delay time to expire in *)
                                   (* host mode.                       *)
      IF Host_Mode THEN
         DELAY( 1000 * Kermit_Delay_Time );

                                   (* Allocate buffer for file       *)

   Buffer_Length  := Max_Write_Buffer;
   GetMem( Read_Buffer , Buffer_Length );

   IF ( Read_Buffer = NIL ) THEN
      BEGIN
         Display_Kermit_Message('  Not enough memory to perform send.');
         Press_Any;
         Restore_Screen_And_Colors( Kermit_Local_Save );
         CursorOn;
         EXIT;
      END;
                                   (* Loop over file names         *)
   WHILE( NOT Stop_Send ) DO
      BEGIN
                                   (* Initialize    *)

         Send_Done          := FALSE;
         File_Done          := FALSE;
         Kermit_Abort       := FALSE;
         Kermit_Retry       := FALSE;
         Buffer_Size        := Buffer_Length;
         Kermit_Abort_Level := No_Abort;

         Kermit_Clear_Message_Lines;

                                   (* Get file name *)

         Get_Kermit_File_Name( OK_File );

                                   (* If file can be sent, do it   *)
         IF OK_File THEN
            BEGIN
               Kermit_Send_One_File;
               Kermit_State := Send_File_Header;
            END;
                                   (* See if transfer loop should be *)
                                   (* stopped.                       *)

         Stop_Send := Stop_Send OR
                      ( Kermit_Abort_Level IN [All_Files, Entire_Protocol] );

                                   (* See if more files to transfer  *)

         FindNext( File_Entry );

         Stop_Send := Stop_Send OR ( DosError <> 0 );

                                   (* Send break packet if no more files *)

         IF ( Stop_Send AND ( NOT Kermit_Abort ) ) THEN
            Kermit_Send_Break;

      END (* WHILE *);
                                   (* Display transfer time *)

      IF ( Send_Done AND ( NOT Kermit_Abort ) ) THEN
         BEGIN

            Display_Kermit_Message('Send completed.');

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

         END
      ELSE
         BEGIN
            Display_Kermit_Message('Send Cancelled.');
         END;
                                   (* Ensure entire protocol aborted   *)
                                   (* if requested.                    *)

   Kermit_Done := ( Kermit_Abort_Level = Entire_Protocol );

   Window_Delay;
                                   (* Remove download buffer           *)

   IF ( Read_Buffer <> NIL ) THEN
      MyFreeMem( Read_Buffer , Buffer_Length );

                                   (* Remove Kermit window             *)

   Restore_Screen_And_Colors( Kermit_Local_Save );

                                   (* Restore cursor *)
   CursorOn;
                                   (* Signal transfer done *)
   IF ( NOT Silent_Mode ) THEN
      FOR I := 1 TO Transfer_Bells DO
         Menu_Beep;

END    (* Do_Kermit_Send *);

(*----------------------------------------------------------------------*)
(*   Get_File_Pattern --- get wildcard specification for files to send  *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_File_Pattern;

VAR
   I    : INTEGER;
   Done : BOOLEAN;

BEGIN (* Get_File_Pattern *)
                                   (* Get file name from kbd/screen *)

   IF ( LENGTH( FileName ) = 0 ) THEN
      IF Auto_Find_FileNames THEN
         Get_Auto_File_Name( Saved_Kbd_File_Name , FileName );

   Draw_Titled_Box( Local_Save, 10, 5, 78, 8, '' );

   PibTerm_Window( 11, 6, 77, 7 );

   GoToXY( 2 , 1 );

   WRITE('File to send: ');
                                   (* Read in wildcard spec *)

   IF ( ( NOT ( Host_Mode OR Script_Transfer ) ) OR ( LENGTH( FileName ) = 0 ) ) THEN
      BEGIN
         File_Pattern := FileName;
         Read_Edited_String( File_Pattern );
         IF ( File_Pattern = CHR( ESC ) ) THEN
            File_Pattern := '';
      END
   ELSE
      BEGIN
         WRITE( FileName );
         File_Pattern := FileName;
      END;
                                   (* Exit if no file name specified *)

   IF ( LENGTH( File_Pattern ) = 0 ) THEN
      BEGIN
         Restore_Screen_And_Colors( Local_Save );
         EXIT;
      END;
                                   (* Get upload directory spec *)
   IF ( NOT Host_Mode ) THEN
      BEGIN

         I    := LENGTH( File_Pattern ) + 1;
         Done := FALSE;

         WHILE ( NOT Done ) DO
            BEGIN
               I    := I - 1;
               Done := ( File_Pattern[I] = ':' ) OR
                       ( File_Pattern[I] = '\' ) OR
                       ( I = 1 );
            END;

         IF ( I > 1 ) THEN
            Upload_Dir_Path := COPY( File_Pattern, 1, I )
         ELSE
            Upload_Dir_Path := '';

         IF ( POS( '\', Upload_Dir_Path ) <> 0 ) THEN
            IF ( Upload_Dir_Path[LENGTH( Upload_Dir_Path )] <> '\' ) THEN
               Upload_Dir_Path := Upload_Dir_Path + '\';

      END;

   Restore_Screen_And_Colors( Local_Save );

END   (* Get_File_Pattern *);

(*----------------------------------------------------------------------*)

BEGIN (* Send_Kermit_File *)
                                   (* Get Kermit menu *)

   Make_A_Menu( Kermit_Menu, Send_Quit_Item, 6, 20, 40, 6, Send_Quit_Item,
                'Choose Kermit function: ',
                'a) Send Text File;b) Send Binary file;' +
                'f) Finish Remote Server;l) Logout Remote Server;' +
                't) Transfer to Receive File Menu;' +
                'q) Quit Kermit',
                FALSE );

   Kermit_Screen_Write    := FALSE;
   Kermit_Done            := FALSE;
   Sending_File           := TRUE;
   Host_Count             := 0;
   FileName               := UpperCase( FileName );
   Send_Packet_Ptr        := ADDR( Sector_Data[Send_Offset] );
   Send_Packet_Ptr^[2]    := CHR( 0 );
   Send_Packet_Ptr^[3]    := CHR( 0 );
   Send_Packet_Ptr^[4]    := CHR( 0 );

                                   (* Begin loop over send choices *)
   REPEAT
                                   (* Reinitialize global Kermit variables *)
      Kermit_Init;
                                   (* Display send menu *)

      IF ( NOT ( Host_Mode OR Script_Transfer ) ) THEN
         BEGIN
            Menu_Display_Choices( Kermit_Menu );
            Menu_Choice := Menu_Get_Choice( Kermit_Menu , Erase_Menu );
         END
      ELSE
         BEGIN
            INC( Host_Count );
            IF ( Host_Count = 1 ) THEN
               BEGIN

                  IF Kermit_File_Type_Var <> Kermit_Binary THEN
                     Menu_Choice := 1
                  ELSE
                     Menu_Choice := 2;

                  IF ( LENGTH( FileName ) > 0 ) THEN
                     IF ( FileName = '/FINISH' ) THEN
                        Menu_Choice := 3
                     ELSE IF ( FileName = '/LOGOUT' ) THEN
                        Menu_Choice := 4;

               END
            ELSE
               Menu_Choice := Send_Quit_Item;
         END;
                                   (* Choose function to perform *)
      CASE Menu_Choice OF

         1: BEGIN (* Send Ascii text file *)
               Kermit_File_Type_Var := Kermit_Ascii;
               Get_File_Pattern;
               IF LENGTH( File_Pattern ) > 0 THEN
                  Do_Kermit_Send;
            END;

         2: BEGIN (* Send binary file *)
               Kermit_File_Type_Var := Kermit_Binary;
               Get_File_Pattern;
               IF LENGTH( File_Pattern ) > 0 THEN
                  Do_Kermit_Send;
            END;
                                   (* Finish remote Kermit server *)
         3: BEGIN
               Kermit_Finish_Server('F');
            END;
                                   (* Logout remote Kermit server *)
         4: BEGIN
               Kermit_Finish_Server('L');
            END;
                                   (* Set up transfer to receive menu *)
         5: BEGIN
               Kermit_Done := TRUE;
               Sending_File := FALSE;
            END;
                                   (* Stop sends *)
         ELSE
            BEGIN
               Kermit_Done := TRUE;
            END;

      END (* CASE *);

   UNTIL Kermit_Done;
                                   (* Ensure status window restored *)
   IF Do_Status_Line THEN
      PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line - 1 );

                                   (* Ensure switch to receive if needed *)

   Kermit_Really_Done := Sending_File;
   FileName           := '';

END   (* Send_Kermit_File *);
