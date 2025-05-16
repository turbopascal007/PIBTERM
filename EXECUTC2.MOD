(*----------------------------------------------------------------------*)

BEGIN (* Execute_Command *)
                                   (* Save current state of important params *)

   Alter_Status        := FALSE;
   Save_Do_Status_Line := Do_Status_Line;

                                   (* Don't get confused by previous *)
                                   (* script strings if manual entry *)

   IF ( NOT ( Use_Script OR Script_Learn_Mode ) ) THEN
      BEGIN
         Script_String       := '';
         Script_String_2     := '';
         Script_Integer_1    := 0;
      END;
                                   (* Execute chosen command *)

   CASE Command Of

       AddLFSy    :  BEGIN
                        Toggle_Option( 'Add line feeds', Add_LF );
                        Alter_Status := TRUE;
                     END;

       AlarmSy    :  FOR I := 1 TO 5 DO
                        BEGIN
                           Menu_Beep;
                           DELAY( 3 * Tenth_Of_A_Second_Delay );
                        END;

       AreaCodeSy :  GetAreaCode;

       BreakSy    :  BEGIN
                        Async_Send_Break;
                        IF Script_Learn_Mode THEN
                           BEGIN
                              IF ( LENGTH( Script_String ) > 0 ) THEN
                                 WRITELN( Script_File , 'SText "', Script_String, '"' );
                              Script_String           := '';
                              Script_Learn_Line_Count := 0;
                              Script_Wait_Generated   := FALSE;
                              WRITELN( Script_File , 'Break' );
                           END;
                     END;

       CaptureSy  :  BEGIN
                        Get_Capture_File( Script_String , Script_String_2 );
                        Alter_Status := TRUE;
                     END;

       ChDirSy    :  BEGIN
                        ChDir( Script_String_2[1] + ':' );
                        Script_IO_Error := Int24Result;
                        ChDir( Script_String );
                        Script_IO_Error := Int24Result;
                     END;

       ClearSy    :  Clear_Window;

       CloseSy    :  BEGIN

                        IF ( ( Script_Integer_1 < 1 ) OR
                             ( Script_Integer_1 > MaxScriptOpenFiles ) ) THEN
                           BEGIN
                              Script_IO_Error := 999;
                           END;

                        IF Script_File_Used[Script_Integer_1] THEN
                           BEGIN
                              IF Script_File_List[Script_Integer_1]^.Opened THEN
                                 BEGIN
                                       (*!I-*)
                                    CLOSE( Script_File_List[Script_Integer_1]^.F );
                                       (*!I+*)
                                    Script_IO_Error := INT24Result;
                                 END;
                              DISPOSE( Script_File_List[Script_Integer_1] );
                              Script_File_Used[Script_Integer_1] := FALSE;
                           END;


                     END;

       ClrEolSy   :  ClrEol;

       CommDrainSy:  Async_Drain_Output_Buffer( Script_Integer_1 );

       CommFlushSy:  BEGIN
                                   (* 1 = flush input only  *)
                                   (* 2 = flush output only *)
                                   (* 3 = flush both        *)

                        IF ( Script_Integer_1 <> 1 ) THEN
                           Async_Flush_Output_Buffer;

                        IF ( Script_Integer_1 <> 2 ) THEN
                           Async_Purge_Buffer;

                     END;

       CopyFileSy :  CopyFile( Script_String , Script_String_2, Free_Size );

       PImportSy  ,
       ImportSy   ,
       DeclareSy  :  Allocate_Variable;

       DelaySy    :  DELAY( Delay_Time );

       DelLineSy  :  DelLine;

       DialSy     ,
       ReDialSy   :  BEGIN
                        T_Type := Terminal_To_Emulate;
                        PibDialer( ( Command = ReDialSy ) , Script_String ,
                                   ( Script_Integer_1 = 0 ) );
                        Script_String    := '';
                        Done             := ( Terminal_To_Emulate <> T_Type );
                        IF Read_In_Script THEN
                           BEGIN
                              Read_In_Script   := FALSE;
                              Process_Script( Script_File_Name , 'E');
                           END;
                        Alter_Status := TRUE;
                     END;

       DirFirstSy :  BEGIN
                        Search_Attr := 0;
                        IF ( LENGTH( Script_String_2 ) > 0 ) THEN
                           FOR I := 1 TO LENGTH( Script_String_2 ) DO
                              CASE Script_String_2[I] OF
                                 'R': Search_Attr := Search_Attr OR ReadOnly;
                                 'H': Search_Attr := Search_Attr OR Hidden;
                                 'S': Search_Attr := Search_Attr OR SysFile;
                                 'V': Search_Attr := Search_Attr OR VolumeID;
                                 'D': Search_Attr := Search_Attr OR Directory;
                                 'A': Search_Attr := Search_Attr OR Archive;
                                 ELSE;
                              END (* CASE *)
                        ELSE
                           Search_Attr := AnyFile;
                        FindFirst( Script_String, Search_Attr, Script_Search_Rec );
                        Store_Find_Info;
                     END;

       DirNextSy  :  BEGIN
                        FindNext( Script_Search_Rec );
                        Store_Find_Info;
                     END;

       DosSy      :  BEGIN
                        DosJump( Script_String );
                        Script_String := '';
                     END;

       EchoSy     :  BEGIN
                        Toggle_Option( 'Local Echo', Local_Echo );
                        Alter_Status := TRUE;
                     END;

       EditSy     :  Edit_A_Line;

       EditFileSy :  Do_File_Editing;

       EraseFileSy:  BEGIN
                        ASSIGN( F , Script_String );
                        ERASE ( F );
                        Script_IO_Error := Int24Result;
                     END;

       ExitSy     :  IF Script_File_Mode THEN
                        BEGIN

                           Alter_Status := TRUE;
                           Com_Line_Scr := ( Scripts[Current_Script_Num].Script_Name[1] = '!' );

                           IF ( Script_Stack_Depth <= 0 ) THEN
                              BEGIN
                                 IF ( Auto_Unload_Scripts OR Com_Line_Scr ) THEN
                                    Unload_This_Script;
                                 IF ( NOT Com_Line_Scr ) THEN
                                    Toggle_Option( 'Script Mode', Script_File_Mode );
                                 Clear_Script_Variables;
                                 Script_File_Mode        := FALSE;
                                 Script_Command_Key_Mode := FALSE;
                              END
                           ELSE
                              BEGIN

                                 IF ( Auto_Unload_Scripts OR Com_Line_Scr ) THEN
                                    Unload_This_Script;

                                   (* Free space for variable values *)

                                 Zap_Script_Variables( 0 ,
                                                       Script_Variable_Count );

                                   (* Free space for variable pointers *)

                                 MyFreeMem( Script_Variables ,
                                          ( Script_Variable_Count + 3 ) * SizeOf( Script_Variables^[1] ) );

                                   (* Free space for any parameters *)

                                 IF ( Script_Parameter_Count > 0 ) THEN
                                    IF ( Script_Parameters <> NIL ) THEN
                                       BEGIN
                                          DISPOSE( Script_Parameters );
                                          Script_Parameters := NIL;
                                       END;

                                 WITH Script_Stack_Position[Script_Stack_Depth] DO
                                    BEGIN
                                       Script_Buffer           := Buffer_Ptr;
                                       Script_Buffer_Pos       := Buffer_Pos;
                                       Current_Script_Num      := Script_Num;
                                       Script_Variables        := Vars_Ptr;
                                       Script_Variable_Count   := Vars_Count;
                                       Script_Parameters       := Params_Ptr;
                                       Script_Parameter_Count  := Params_Count;
                                       Script_Parameter_Got    := Params_Got;
                                       Prev_Script_Variables   := Prev_Ptr;
                                    END;
                                 DEC( Script_Stack_Depth );

                              END;

                        END;

       ExitAllSy  :  BEGIN
                        Exit_All_Scripts;
                        Alter_Status := TRUE;
                     END;

       FastCSy    :  Fast_Change_Params;

       FileSy     :  REPEAT

                        PibFileManipulation( File_Done  ,
                                             Do_Editing ,
                                             Do_Viewing );
                        IF Do_Editing THEN
                           Do_File_Editing
                        ELSE IF Do_Viewing THEN
                           Do_File_Viewing;

                     UNTIL( File_Done );

       FreeSpaceSy:  BEGIN
                        IF ( LENGTH( Script_String ) = 0 ) THEN
                           Drive_Word := 0
                        ELSE
                           Drive_Word := SUCC( ORD( Script_String[1] ) - ORD('A') );
                        Free_Size := DiskFree( Drive_Word );
                        STR( Free_Size , Script_Variables^[Script_Integer_1].Var_Value^ );
                     END;

       GetDirSy   :  BEGIN
                        GetDir( 0 , Script_String );
                        Script_IO_Error := Int24Result;
                        Script_Variables^[Script_Integer_1].Var_Value^ := Script_String[1];
                        IF ( Script_IO_Error <> 0 ) THEN
                           Script_String_2 := ''
                        ELSE
                           Script_String_2 := COPY( Script_String, 3, 
                                                    LENGTH( Script_String ) - 2 );
                        Script_Variables^[Script_Integer_2].Var_Value^ := Script_String_2;
                     END;


       GossipSy   :  BEGIN
                        Toggle_Option( 'Gossip mode', Gossip_Mode_On );
                        Done := TRUE;
                        IF Gossip_Mode_On THEN
                           BEGIN
                              Saved_Gossip_Term   := Terminal_To_Emulate;
                              Terminal_To_Emulate := Gossip;
                           END
                        ELSE
                           BEGIN
                              Terminal_To_Emulate := Saved_Gossip_Term;
                           END;
                     END;

       GoToSy     :  Script_Buffer_Pos := PRED( Script_Integer_1 );

       GoToXYSy   :  GoToXY( Script_Integer_1, Script_Integer_2 );

       HangUpSy   :  BEGIN (* Hang-up Phone *)

                        Draw_Titled_Box( Saved_Screen, 10, 10, 60, 15, '' );

                        WRITELN;
                        WRITELN('*** Hanging up the phone ***');

                                   (* Hang up the phone *)

                        HangUpPhone;

                        IF Async_Carrier_Detect THEN
                           WRITELN('*** Phone not hung up, try again ***')
                        ELSE
                           BEGIN
                              WRITELN('*** Phone hung up ***');
                              Write_Log('Phone hung up', FALSE , FALSE );
                           END;

                        Window_Delay;

                        Restore_Screen_And_Colors( Saved_Screen );

                     END   (* Hang-up Phone *);

       HostSy     :  BEGIN (* Set host mode *)
                        Done                := TRUE;
                        Saved_Gossip_Term   := Terminal_To_Emulate;
                        Terminal_To_Emulate := HostMode;
                     END   (* Set host mode *);


       IfConSy    :  Do_Simple_If( Async_Carrier_Detect );

       IfDialSy   :  Do_Simple_If( Script_Dialed );


       IfExistsSy :  BEGIN
                             (*!I-*)
                        ASSIGN( F , Script_String );
                        RESET ( F );
                             (*!I+*)
                        I := Int24Result;
                             (*!I-*)
                        CLOSE ( F );
                             (*!I+*)
                        J := Int24Result;

                        Do_Simple_If( ( I = 0 ) );

                     END;

       IfFoundSy  :  Do_Simple_If( Script_Wait_Found );

       IfLocStrSy :  BEGIN

                        IF ( LENGTH( Script_Reply  ) > 0 ) AND
                           ( LENGTH( Script_String ) > 0 ) THEN
                           Script_Reply_Found :=
                              ( POS( Script_Reply , Script_String ) > 0 );

                        Do_Simple_If( Script_Reply_Found );

                     END;

       IfOKSy     :  Do_Simple_If( Script_IO_Error <> 0 );

       IfOpSy     :  BEGIN
                        Execute_Stack( 0 );
                        I := ( ORD( Script_Variables^[0].Var_Value^[2] ) SHL 8 ) OR
                               ORD( Script_Variables^[0].Var_Value^[1] );
{
                        IF Debug_Mode THEN
                           Debug_Write('---> IF returns ' + ITOS( I ) );
}
                        IF ( ( I AND 1 ) = 1 ) THEN
                           Script_Buffer_Pos := PRED( Script_Integer_2 )
                        ELSE
                           Script_Buffer_Pos := PRED( Script_Integer_3 );
                     END;

       IfRemStrSy :  BEGIN

                        IF ( LENGTH( Script_Remote_Reply ) > 0 ) AND
                           ( LENGTH( Script_String       ) > 0 ) THEN
                           Script_Remote_Reply_OK :=
                              ( POS( Script_Remote_Reply , Script_String ) > 0 );

                        Do_Simple_If( Script_Remote_Reply_OK );

                     END;

       InfoSy     :  Display_Help( FALSE );

       InputSy    :  BEGIN
                        WRITE( Script_String );
                        Script_Reply := '';
                        Read_Edited_String( Script_Reply );
                        Script_Reply_Found := FALSE;
                        IF ( Script_Integer_1 > 2 ) THEN
                           BEGIN
                              Script_Variables^[Script_Integer_1].Var_Value^ :=
                                 Script_Reply;
{
                              IF Debug_Mode THEN
                                 Debug_Write('   --> Variable read into is #' +
                                       ITOS( Script_Integer_1 ) + ' = ' +
                                       Script_Variables^[Script_Integer_1].Var_Name );
}
                           END;
                     END;

       InsLineSy  :  InsLine;

       KeyDefSy   :  Define_Key( Script_String , Script_String_2 );

       KeyFlushSy :  WHILE ( PibTerm_KeyPressed ) DO
                        Read_Kbd( Ch );

       KeySendSy  :  IF ( Key_No <> Command_Key ) THEN
                        Handle_Function_Key( CHR( Key_No ) )
                     ELSE
                        Process_Script( '' , 'K' );

       KeySy      :  Set_Input_Keys( Script_String , TRUE );

       LogSy      :  BEGIN
                        Toggle_Option('List session on printer', Printer_On );
                        Alter_Status := TRUE;
                     END;

       MessageSy  :  BEGIN
                        Script_String := Read_Ctrls( Script_String ) +
                                         CHR( CR ) + CHR( LF );
                        FOR I := 1 TO LENGTH( Script_String ) DO
                           IF Use_Dos_Con_Output THEN
                              Display_Character_Through_DOS( Script_String[I] )
                           ELSE
                              Display_Character( Script_String[I] );
                     END;

       MenuSy     :  BEGIN
                                   (* Display menu *)

                        Menu_Display_Choices( Script_Menu_Holder^ );

                                   (* Get choice *)

                        I     := Menu_Get_Choice( Script_Menu_Holder^ , Erase_Menu );
                        LongI := I;

                        MOVE( LongI , Script_Variables^[Script_Integer_1].Var_Value^[1],
                              SIZEOF( LongI ) );

                        DISPOSE( Script_Menu_Holder );

                     END;

       MuteSy     :  BEGIN
                        Toggle_Option('Silent Mode', Silent_Mode );
                        Menu_Set_Beep( NOT Silent_Mode );
                     END;

       OpenSy     :  BEGIN

                        IF ( ( Script_Integer_1 < 1 ) OR
                             ( Script_Integer_1 > MaxScriptOpenFiles ) ) THEN
                              Script_IO_Error := 999
                        ELSE
                           BEGIN

                              IF Script_File_Used[Script_Integer_1] THEN
                                 BEGIN
                                       (*!I-*)
                                    CLOSE( Script_File_List[Script_Integer_1]^.F );
                                       (*!I+*)
                                    DISPOSE( Script_File_List[Script_Integer_1] );
                                 END;

                              NEW( Script_File_List[Script_Integer_1] );

                              IF ( Script_File_List[Script_Integer_1] = NIL ) THEN
                                 Script_IO_Error := 999
                              ELSE
                                 BEGIN

                                    Script_File_Used[Script_Integer_1] := TRUE;

                                    WITH Script_File_List[Script_Integer_1]^ DO
                                       BEGIN

                                          ReadOnly  := ( Script_Integer_2 = 0 );
                                          EOF_Seen  := FALSE;

                                             (*!I-*)
                                          ASSIGN( F , Script_String );

                                          CASE Script_Integer_2 OF
                                             0: BEGIN
                                                   ASSIGN( F , Script_String );
                                                   RESET  ( F );
                                                   Script_IO_Error := INT24Result;
                                                END;
                                             1: BEGIN
                                                   ASSIGN( F , Script_String );
                                                   REWRITE( F );
                                                   Script_IO_Error := INT24Result;
                                                END;
                                             2: Flag := Open_For_Append( F,
                                                                         Script_String,
                                                                         Script_IO_Error );
                                          END (* CASE *);

                                             (*!I+*)

                                          Opened := ( Script_IO_Error = 0 );

                                       END;

                                 END;

                           END;

                     END;

       GetParamSy ,
       SetParamSy ,
       ParamSy    :  BEGIN
                        T_Type        := Terminal_To_Emulate;
                        Flag          := Set_Params( FALSE , Use_Script );
                        Done          := ( Terminal_To_Emulate <> T_Type );
                        Alter_Status  := TRUE;
                     END;

       PrintFileSy:  Print_A_File( Script_String );

       QuitSy     :  BEGIN (* Quit *)

                        Draw_Titled_Box( Saved_Screen, 10, 10, 55, 13, '' );

                        IF Script_File_Mode THEN
                           BEGIN
                              IF Script_Integer_1 = 0 THEN
                                 Script_File_Mode :=
                                    NOT YesNo('Stop running current script (Y/N) ? ')
                              ELSE
                                 BEGIN
                                    Script_File_Mode    := FALSE;
                                    Script_File_Name    := '';
                                    Done                := TRUE;
                                 END;
                              IF ( NOT Script_File_Mode ) THEN
                                 Clear_Script_Variables;
                              Alter_Status := TRUE;
                           END
                        ELSE IF ( When_Mode OR When_Drop_Mode ) THEN
                           BEGIN
                              When_Mode :=
                                 NOT YesNo('Stop WHEN and WHENDROP processing (Y/N) ? ');
                              When_Drop_Mode := When_Mode;
                              IF ( NOT When_Mode ) THEN
                                 BEGIN
                                    Script_When_Text       := '';
                                    Script_When_Reply_Text := '';
                                    Script_When_Drop_Text  := '';
                                 END;
                           END
                        ELSE
                           Done := YesNo('Are you sure you want to quit (Y/N) ? ');

                        Restore_Screen_And_Colors( Saved_Screen );

                        PibTerm_Done := Done;

                     END;

       QuitAllSy  :  BEGIN (* Stop PibTerm execution from script *)
                        Done         := TRUE;
                        PibTerm_Done := TRUE;
                     END;

       ReadLnSy   :  IF ( Script_Integer_1 = 0 ) THEN
                        BEGIN
                           READLN( Script_Variables^[Script_Integer_2].Var_Value^ );
                           Script_IO_Error := INT24Result;
                        END
                     ELSE IF Script_File_Used[Script_Integer_1] THEN
                        WITH Script_File_List[Script_Integer_1]^ DO
                           BEGIN
                              IF ( Opened AND ReadOnly AND ( NOT EOF_Seen ) ) THEN
                                 BEGIN
                                       (*!I-*)
                                    READLN( F ,
                                          Script_Variables^[Script_Integer_2].Var_Value^ );
                                       (*!I+*)
                                    Script_IO_Error := INT24Result;
                                    IF ( NOT EOF_Seen ) THEN
                                       EOF_Seen := EOF( F );
                                 END
                              ELSE
                                 Script_IO_Error := 999;
                           END;

       ReadSy     :  BEGIN
{
                    Write_Log('U='+CHR( ORD('0') + Script_Integer_1 ), FALSE,
                              FALSE);
                    Write_Log('N='+CHR( ORD('0') + Script_Integer_3 ), FALSE,
                              FALSE);
}
                     IF Script_File_Used[Script_Integer_1] THEN
                        WITH Script_File_List[Script_Integer_1]^ DO
                           BEGIN
                              Flag := ( Script_Integer_1 = 0 );
                              IF ( Opened AND ( Flag OR ReadOnly ) ) THEN
                                 Read_Chars( F,
                                             Script_Variables^[Script_Integer_2].Var_Value^,
                                             Script_Integer_3,
                                             EOF_Seen,
                                             Flag )
                              ELSE
                                 Script_IO_Error := 999;
                           END;
                     END;

       ReceiveSy  :  BEGIN

                        IF LENGTH( Script_String ) > 0 THEN
                           FileName        := Script_String;

                        IF ( Script_Integer_1 > 0 ) THEN
                           BEGIN
                              Trans_Type      := Transfers[ Script_Integer_1 ];
                              Script_Transfer := TRUE;
                           END
                        ELSE
                           Trans_Type := None;

                        PibDownLoad( Trans_Type );

                        Script_Transfer := FALSE;


                     END;

       ResetSy    :  Script_Buffer_Pos := 0;

       ReturnSy   :  IF ( Script_Call_Depth > 0 ) THEN
                        WITH Script_Call_Stack[Script_Call_Depth] DO
                           BEGIN
                              IF ( Proc_Parameter_Count > 0 ) THEN
                                 DISPOSE( Proc_Parameters );
                              Script_Buffer_Pos    := Return_Addr;
                              Proc_Parameters      := Proc_Param;
                              Proc_Parameter_Got   := Proc_Got;
                              Proc_Parameter_Count := Proc_Count;
                              DEC( Script_Call_Depth );
{
                           IF Debug_Mode THEN
                              Debug_Write('---> Ret from proc to location ' +
                                          ITOS( Script_Buffer_Pos ) );
}
                           END;

       RInputSy   :  Remote_Input;

       ExecuteSy  ,
       ExeNewSy   ,
       ScriptSy   :  BEGIN
                        IF ( LENGTH( Script_String ) > 0 ) THEN
                           Ch := Script_String[1]
                        ELSE
                           Ch := ' ';
                        Process_Script( Script_String_2 , Ch );
                        Alter_Status := TRUE;
                     END;

       SDumpSy    :  Do_Screen_Dump;

       SendSy     :  BEGIN

                        IF LENGTH( Script_String ) > 0 THEN
                           FileName        := Script_String;

                        IF ( Script_Integer_1 > 0 ) THEN
                           BEGIN
                              Trans_Type      := Transfers[ Script_Integer_1 ];
                              Script_Transfer := TRUE;
                           END
                        ELSE
                           Trans_Type := None;

                        PibUpLoad( Trans_Type );

                        Script_Transfer := FALSE;


                     END;

       SetSy      :  BEGIN
{
                        IF Debug_Mode THEN
                           Debug_Write('---> Setting variable # ' +
                                   ITOS( Script_Integer_1 ) + ', is ' +
                                   Script_Variables^[Script_Integer_1].Var_Name );
}
                        Execute_Stack( Script_Integer_1 );

                     END;


       STextSy    :  BEGIN
                        Send_Function_Key( Read_Ctrls( Script_String ) );
                        Script_String := '';
                     END;

       TextSy     :  BEGIN
                        Async_Send_String( Script_String );
                        Script_String := '';
                     END;

       TimersSy   :  Display_Timers;

       TranslateSy:  Set_Translate_Table( Script_String );

       ViewSy     :  IF Review_On THEN

                        IF ( Review_Head > 0 ) THEN
                           Review_Captured_Text
                        ELSE
                           BEGIN

                              Draw_Titled_Box( Saved_Screen, 10, 10, 60, 14, '' );

                              WRITE('Review buffer empty.');

                              Window_Delay;

                              Restore_Screen_And_Colors( Saved_Screen );

                           END
                        ELSE
                     BEGIN

                        Draw_Titled_Box( Saved_Screen, 10, 10, 60, 14, '' );

                        WRITE('Review buffer not active.');

                        Window_Delay;

                        Restore_Screen_And_Colors( Saved_Screen );

                     END;

       ViewFileSy : Do_File_Viewing;

       WaitSy     : BEGIN

                       TimeW := COPY( Script_String, 1, 8 );

                       Draw_Titled_Box( Local_Save, 10, 10, 60, 14,
                                        'Wait For Specified Time' );

                       WRITELN('Waiting for:  ',TimeW);
                       WRITE  ('Current time: ');

                       I         := WhereY;
                       TimeN     := '';
                       ESC_Found := FALSE;

                       REPEAT
                          TimeO := TimeN;
                          TimeN := TimeString( TimeOfDay , Military_Time );
                          IF ( TimeN <> TimeO ) THEN
                             BEGIN
                                GoToXY( 15 , I );
                                WRITE( TimeN );
                             END;
                          IF PibTerm_KeyPressed THEN
                             BEGIN
                                Read_Kbd( Ch );
                                IF ORD( Ch ) = ESC THEN
                                   BEGIN
                                      ESC_Found := TRUE;
                                      IF PibTerm_KeyPressed THEN
                                         Read_Kbd( Ch );
                                   END;
                             END;
                       UNTIL( TimeN = TimeW ) OR ESC_Found;

                       Restore_Screen_And_Colors( Local_Save );

                    END;

       WhereXYSy  : BEGIN
                       LongI := WhereX;
                       LongJ := WhereY;
                       MOVE( LongI ,
                             Script_Variables^[Script_Integer_1].Var_Value^[1],
                             SIZEOF( LongI ) );
                       MOVE( LongJ ,
                             Script_Variables^[Script_Integer_2].Var_Value^[1],
                             SIZEOF( LongJ ) );
                    END;

       WriteLnSy  : IF ( Script_Integer_1 = 0 ) THEN
                       WRITELN( Script_String )
                    ELSE IF Script_File_Used[Script_Integer_1] THEN
                       WITH Script_File_List[Script_Integer_1]^ DO
                          BEGIN
                             IF ( Opened AND ( NOT ReadOnly ) ) THEN
                                BEGIN
                                      (*!I-*)
                                   WRITELN( F , Script_String );
                                      (*!I+*)
                                   Script_IO_Error := INT24Result;
                                END
                             ELSE
                                Script_IO_Error := 999;
                          END;

       WriteSy    : IF ( Script_Integer_1 = 0 ) THEN
                       WRITE( Script_String )
                    ELSE IF Script_File_Used[Script_Integer_1] THEN
                       WITH Script_File_List[Script_Integer_1]^ DO
                          BEGIN
                             IF ( Opened AND ( NOT ReadOnly ) ) THEN
                                BEGIN
                                      (*!I-*)
                                   WRITE( F , Script_String );
                                      (*!I+*)
                                   Script_IO_Error := INT24Result;
                                END
                             ELSE
                                Script_IO_Error := 999;
                          END;

       WriteLogSy : Write_Log( Script_String , FALSE , FALSE );

       ZapVarSy   : Zap_Script_Variables( Script_Integer_1 , Script_Integer_2 );

      ELSE        ;

   END (* CASE *);
                                   (* Update status display if parameters  *)
                                   (* changed.                             *)

   Do_Script_Tests := Waitstring_Mode OR When_Mode OR
                      WaitCount_Mode  OR WaitQuiet_Mode OR
                      Script_Learn_Mode;

   IF Reverse_Status_Colors THEN
      Status_Line_Attr := ( ForeGround_Color AND 7 ) SHL 4 + BackGround_Color
   ELSE
      Status_Line_Attr := ( Status_BackGround_Color AND 7 ) SHL 4 + Status_ForeGround_Color;

   Ansi_Term          := ( Terminal_To_Emulate = Ansi  ) OR
                         ( Terminal_To_Emulate = VT100 );

   Do_Status_Line     := Show_Status_Line AND
                         ( NOT Graphics_Terminal_Mode );

   IF ( NOT Ansi_Term ) THEN
      Do_Status_Line := Do_Status_Line AND ( NOT Use_Dos_Con_Output );

   Do_Status_Time     := Do_Status_Line AND Show_Status_Time;

                                   (* If any status stuff changed, *)
                                   (* rewrite the status line      *)
   IF Do_Status_Line THEN
      IF ( Alter_Status OR Reset_Comm_Port ) THEN
         BEGIN
            IF ( WhereY = Max_Screen_Line ) THEN
               BEGIN
                  MoveToXY( WhereX , PRED( Max_Screen_Line ) );
                  Do_Status_Line := FALSE;
                  Scroll( 1, Max_Screen_Line, 1, Max_Screen_Col, 1,
                          ForeGround_Color, BackGround_Color );
                  Do_Status_Line := TRUE;
               END;
            Set_Status_Line_Name( Short_Terminal_Name );
            Write_To_Status_Line( Status_Line_Name, 1 );
         END
      ELSE (* Leave status line as is *)
   ELSE
      IF( Save_Do_Status_Line ) THEN
         BEGIN (* Remove status line that was there before *)

            Status_Line_Attr   := ( BackGround_Color AND 7 ) SHL 4 +
                                  ForeGround_Color;

            Do_Status_Line := TRUE;

            Write_To_Status_Line( DUPL( ' ' , Max_Screen_Col ), 1 );

            Do_Status_Line := FALSE;

         END;

   Reset_Comm_Port := FALSE;

END   (* Execute_Command *);
