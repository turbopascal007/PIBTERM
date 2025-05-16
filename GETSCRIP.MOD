(*----------------------------------------------------------------------*)
(*        Get_Script_Command --- Get command from script buffer         *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Script_Command( VAR Command : PibTerm_Command_Type );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*       Procedure:   Get_Script_Command                                *)
(*                                                                      *)
(*       Purpose:     Get command from script buffer                    *)
(*                                                                      *)
(*       Calling Sequence:                                              *)
(*                                                                      *)
(*          Get_Script_Command( VAR Command : PibTerm_Command_Type );   *)
(*                                                                      *)
(*             Command --- command extracted from buffer                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I          : INTEGER;
   L          : INTEGER;
   Ch         : CHAR;
   IBogus     : LONGINT;
   LBogus     : LONGINT;
   Key_Offset : INTEGER;
   Section_No : INTEGER;
   IVal       : LONGINT;
   VPtrs      : Script_Variable_List_Ptr;

(*----------------------------------------------------------------------*)
(*   Copy_Script_String --- Copy a string from the script buffer        *)
(*----------------------------------------------------------------------*)

PROCEDURE Copy_Script_String( VAR S: AnyStr; VAR V: LONGINT );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        Each string is stored in the form:                            *)
(*                                                                      *)
(*           String_Type    1 byte                                      *)
(*           String_Length  1 byte                                      *)
(*           Text           String_Length bytes                         *)
(*                                                                      *)
(*       The values for String_Type are:                                *)
(*                                                                      *)
(*           0  --- ordinary string, text follows                       *)
(*           1  --- use 'localreply' text                               *)
(*           2  --- use 'remotereply' text                              *)
(*           3  --- use 'set' variable -- String_length is index        *)
(*                                                                      *)
(*       String_Length and Text are stored when String_Type = 0.        *)
(*       Neither is stored for types 1 and 2.  String_Length =          *)
(*       variable index is stored for type 3.                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
  L : INTEGER;

BEGIN (* Copy_Script_String *)
                                   (* Pick up string type *)

   INC( Script_Buffer_Pos );
   V := Script_Buffer^[Script_Buffer_Pos];

                                   (* Get string value based upon type *)
   CASE V OF

      0:  BEGIN (* Text string *)

             INC( Script_Buffer_Pos );

             L := Script_Buffer^[Script_Buffer_Pos];

                                   (* Watch out -- direct move here! *)

             MOVE( Script_Buffer^[Script_Buffer_Pos + 1], S[1], L );

             S[0] := CHR( L );

             Script_Buffer_Pos := Script_Buffer_Pos + L;
{
             IF Debug_Mode THEN
                WRITELN('---> String length = ',L,', string = <',S,'>');
}
          END;

      1:  BEGIN (* Local reply string *)
             S := Script_Reply;
          END;

      2:  BEGIN (* Remote reply string *)
             S := Script_Remote_Reply;
          END;

      3:  BEGIN (* Script variable *)
             INC( Script_Buffer_Pos );
             V := Script_Buffer^[Script_Buffer_Pos];
             S := Script_Variables^[V].Var_Value^;
{
             IF Debug_Mode THEN
                WRITELN('---> Script variable ',V,' has value <',S,'>');
}
          END   (* Script variable *);

      ELSE
          S    := '';
          V    := 4;
{
          IF Debug_Mode THEN
             WRITELN('---> BOGUS STRING MODE = ',V,' in Copy_Script_String.');
}
   END (* CASE *);

END   (* Copy_Script_String *);

(*----------------------------------------------------------------------*)
(*   Copy_Script_Integer --- Copy an integer from the script buffer     *)
(*----------------------------------------------------------------------*)

PROCEDURE Copy_Script_Integer( VAR IntVal: LONGINT;
                               VAR V     : LONGINT );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        Each integer is stored in the form:                           *)
(*                                                                      *)
(*           Integer_Type    1 byte                                     *)
(*           Integer_Value   4 bytes (if Integer_Type=0)                *)
(*                                                                      *)
(*       The values for Integer_Type are:                               *)
(*                                                                      *)
(*           0  --- integer constant (four bytes) follows               *)
(*           n  --- use variable "n"                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Copy_Script_Integer *)

   INC( Script_Buffer_Pos );
   V := Script_Buffer^[Script_Buffer_Pos];

   IF ( V = 0 ) THEN
      BEGIN
         MOVE( Script_Buffer^[Script_Buffer_Pos + 1 ], IntVal, SIZEOF( LONGINT ) );
         INC( Script_Buffer_Pos , SIZEOF( LONGINT ) );
      END
   ELSE
      MOVE( Script_Variables^[V].Var_Value^[1], IntVal, SIZEOF( LONGINT ) );

END   (* Copy_Script_Integer *);

(*----------------------------------------------------------------------*)
(*   Copy_Script_Integer_Constant --- Copy integer cosntant from script *)
(*----------------------------------------------------------------------*)

PROCEDURE Copy_Script_Integer_Constant( VAR IntVal: LONGINT );

BEGIN (* Copy_Script_Integer_Constant *)

   MOVE( Script_Buffer^[Script_Buffer_Pos + 1 ], IntVal, SIZEOF( LONGINT ) );

   INC( Script_Buffer_Pos , 4 );

END   (* Copy_Script_Integer_Constant *);

(*----------------------------------------------------------------------*)
(*   Get_Transfer_Protocol --- Get file transfer protocol               *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Transfer_Protocol;

VAR
   I     : INTEGER;
   Found : BOOLEAN;
   TName : Char_2;
   TType : Transfer_Type;

BEGIN (* Get_Transfer_Protocol *)

   Found := FALSE;
                                   (* Pick up transfer type name *)
   TName := '  ';
   TType := None;

   FOR I := 1 TO MIN( 2 , LENGTH( Script_String_2 ) ) DO
      TName[I] := UpCase( Script_String_2[I] );

                                   (* Look up transfer name *)

   FOR I := 1 TO ( Max_Transfer_Types - 1 ) DO
      IF ( TName = Trans_Type_Name[Transfers[I]] ) THEN
         BEGIN
            TType := Transfers[I];
            Found := TRUE;
         END;
                                   (* Didn't find it -- check special *)
                                   (* Kermit names.                   *)
   IF ( NOT Found ) THEN
      IF ( TName = 'K ' ) THEN
         TType := Kermit
      ELSE IF ( TName = 'KA' ) THEN
         BEGIN
            TType := Kermit;
            Kermit_File_Type_Var := Kermit_Ascii;
         END
      ELSE IF ( TName = 'KB' ) THEN
         BEGIN
            TType := Kermit;
            Kermit_File_Type_Var := Kermit_Binary;
         END;
                                   (* Assume default type if none given *)
   IF ( TType = None ) THEN
      TType := Default_Transfer_Type;

                                   (* Record transfer type *)

   Script_Integer_1 := ORD( TType ) + 1;

END   (* Get_Transfer_Protocol *);

(*----------------------------------------------------------------------*)
(*          Fix_Wait_Time --- Fix up time to wait for WAIT* commands    *)
(*----------------------------------------------------------------------*)

PROCEDURE Fix_Wait_Time;

BEGIN (* Fix_Wait_Time *)

   IF ( Script_Wait_Time <= 0 ) THEN
      Script_Wait_Time := Script_Default_Wait_Time;

   IF ( Script_Wait_Time <= 0 ) THEN
      Script_Wait_Time := 30;

   Really_Wait_String := TRUE;

   Script_Wait_Start  := TimeOfDay;
   Script_Wait_Found  := FALSE;

   Command            := Null_Command;

END   (* Fix_Wait_Time *);

(*----------------------------------------------------------------------*)
(*          Get_WaitList --- Get stuff for WaitList command execution   *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_WaitList;

VAR
   I     : INTEGER;
   QDoit : BOOLEAN;

CONST
   LongIntZero : STRING[4] = ^@^@^@^@;

BEGIN (* Get_WaitList *)
                                   (* Get result variable index *)

   Copy_Script_Integer( LBogus , Script_Wait_Result_Index );

                                   (* Zero out result index *)

   Script_Variables^[Script_Wait_Result_Index].Var_Value^ := LongIntZero;

                                   (* Get # of strings *)

   INC( Script_Buffer_Pos );
   Script_Wait_Count        := Script_Buffer^[Script_Buffer_Pos];
   Script_Wait_Check_Length := 0;
   QDoit                    := TRUE;

                                   (* Set up vector of wait strings *)

   FOR I := 1 TO Script_Wait_Count DO
      WITH Script_Wait_List[I] DO
         BEGIN
            NEW( Wait_Text );
            IF ( Wait_Text <> NIL ) THEN
               BEGIN
                  Copy_Script_String( Wait_Text^ , IBogus );
                  Wait_Text^ := Read_Ctrls( Wait_Text^ );
               END
            ELSE
               BEGIN
                  QDoit := FALSE;
                  Copy_Script_String( Script_String , IBogus );
               END;
            IF QDoit THEN
               BEGIN
                  NEW( Wait_Reply );
                  IF ( Wait_Reply <> NIL ) THEN
                     BEGIN
                        Wait_Reply^  := '';
                        Script_Wait_Check_Length := MAX( Script_Wait_Check_Length ,
                                                         LENGTH( Wait_Text^ ) );
                     END
                  ELSE
                     QDoit := FALSE;
               END;
         END;

   Copy_Script_Integer_Constant( Script_Wait_Failure );

   IF QDoit THEN
      BEGIN

         WaitString_Mode := ( ( Script_Wait_Count > 0 ) AND
                              ( Script_Wait_Check_Length > 0 ) );

                                   (* Get wait time *)

         Script_Wait_Time := Script_Default_Wait_Time;

         Fix_Wait_Time;

      END
   ELSE
      BEGIN
         WaitString_Mode := FALSE;
         Command         := Null_Command;
      END;

END   (* Get_WaitList *);

(*----------------------------------------------------------------------*)
(*     Get_WaitString --- Get stuff for WaitString command execution    *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_WaitString;

VAR
   QDoit : BOOLEAN;

BEGIN (* Get_WaitString *)

   Copy_Script_String ( Script_String    , IBogus );
   Copy_Script_String ( Script_String_2  , IBogus );
   Copy_Script_Integer( Script_Wait_Time , IBogus );

                                   (* No result index *)
   Script_Wait_Result_Index := 0;
   QDoit                    := TRUE;

                                   (* If waitstring null, skip this guy *)

   IF ( LENGTH( Script_String ) = 0 ) THEN
      BEGIN
         WaitString_Mode   := FALSE;
         Script_Wait_Count := 0;
      END
   ELSE
      BEGIN
                                   (* One waitstring *)
         Script_Wait_Count := 1;
         WaitString_Mode   := TRUE;

         WITH Script_Wait_List[1] DO
            BEGIN
               NEW( Wait_Text );
               IF ( Wait_Text <> NIL ) THEN
                  Wait_Text^ := Read_Ctrls( Script_String )
               ELSE
                  QDoit := FALSE;
               IF QDoit THEN
                  BEGIN
                     NEW( Wait_Reply );
                     IF ( Wait_Reply <> NIL ) THEN
                        BEGIN
                           Wait_Reply^ := Read_Ctrls( Script_String_2 );
                           Script_Wait_Check_Length := LENGTH( Script_String );
                        END
                     ELSE
                        QDoit := FALSE;
                  END;
            END;
                                   (* Fix up wait time *)
         IF QDoit THEN
            Fix_Wait_Time;

      END;

   Copy_Script_Integer_Constant( Script_Wait_Failure );

   IF ( NOT QDoit ) THEN
      BEGIN
         WaitString_Mode   := FALSE;
         Script_Wait_Count := 0;
      END;

END   (* Get_WaitString *);

(*----------------------------------------------------------------------*)
(*                Get_Menu --- Get stuff for MENU command               *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Menu;

VAR
   Default : INTEGER;
   Row     : INTEGER;
   Col     : INTEGER;
   LRow    : LONGINT;
   LCol    : LONGINT;
   LDefault: LONGINT;
   NItems  : INTEGER;
   Items   : INTEGER;

BEGIN (* Get_Menu *)
                                   (* Result variable index *)

   Copy_Script_Integer( LBogus , Script_Integer_1 );

                                   (* Display position *)

   Copy_Script_Integer( LCol   , IBogus );
   Copy_Script_Integer( LRow   , IBogus );

   Row := LRow;
   Col := LCol;
                                   (* Default *)

   Copy_Script_Integer( LDefault , IBogus );

   Default := LDefault;
                                   (* Get menu title *)

   Copy_Script_String( Script_String , IBogus );

                                   (* Get # of items *)

   INC( Script_Buffer_Pos );
   NItems := Script_Buffer^[Script_Buffer_Pos];

                                   (* Generate the menu *)
   NEW( Script_Menu_Holder );

   IF ( Script_Menu_Holder <> NIL ) THEN
      BEGIN

         Make_A_Menu( Script_Menu_Holder^, NItems, Row, Col, 0, 0, Default,
                      Script_String, '', FALSE );

                                   (* Get and store item strings *)
         FOR Items := 1 TO NItems DO
            Copy_Script_String( Script_Menu_Holder^.Menu_Entries[Items].Menu_Item_Text ,
                                IBogus );

      END
   ELSE
      BEGIN
         FOR Items := 1 TO NItems DO
            Copy_Script_String( Script_String , IBogus );
         Command := Null_Command;
      END;

END   (* Get_Menu *);

(*----------------------------------------------------------------------*)
(*                Locate_Var --- Locate variable                        *)
(*----------------------------------------------------------------------*)

FUNCTION Locate_Var(     VPtrs  : Script_Variable_List_Ptr;
                         VCount : INTEGER;
                         VName  : AnyStr;
                     VAR VType  : ShortStr;
                     VAR Value  : AnyStr     ) : INTEGER;

VAR
   I    : INTEGER;
   IVal : LONGINT;

BEGIN (* Locate_Var *)

   VType      := 'UNDEFINED';
   Value      := '';
   Locate_Var := 0;
   VName      := UpperCase( VName );

   FOR I := VCount DOWNTO 2 DO
      IF ( VName = VPtrs^[I].Var_Name ) THEN
         BEGIN
            CASE VPtrs^[I].Var_Type OF
               Integer_Variable_Type : BEGIN
                                          VType := 'INTEGER';
                                          MOVE( VPtrs^[I].Var_Value^[1],
                                                IVal, SIZEOF( LONGINT ) );
                                          STR( IVal , Value );
                                       END;
               String_Variable_Type  : BEGIN
                                          VType := 'STRING';
                                          Value := VPtrs^[I].Var_Value^;
                                       END;
            END (* CASE *);
            Locate_Var := I;
            EXIT;
         END;

END   (* Locate_Var *);

(*----------------------------------------------------------------------*)

BEGIN (* Get_Script_Command *)
                                   (* Check for suspended script      *)
                                   (* and exit if suspension still    *)
                                   (* in progress.                    *)

   IF ( Script_Suspend_Time > 0 ) THEN
      IF ( TimeDiffH( Script_Suspend_Start, TimeOfDayH ) <=
         Script_Suspend_Time ) THEN
            BEGIN
               Command := Null_Command;
               EXIT;
            END
      ELSE
         Script_Suspend_Time := 0;

                                   (* Set script strings to null      *)
   Script_String    := '';
   Script_String_2  := '';
   Script_Integer_1 := 0;
                                   (* Point to next command in buffer *)

   INC( Script_Buffer_Pos );

                                   (* Pick up command type            *)

   Command   := PibTerm_Command_Table_2[ Script_Buffer^[Script_Buffer_Pos] ];

                                   (* For commands with arguments,     *)
                                   (* get the arguments.               *)

   CASE Command Of

       DelaySy    : BEGIN
                       Copy_Script_Integer( Script_Integer_1 , IBogus );
                       Delay_Time := Script_Integer_1 * 100;
                    END;

       SuspendSy  : BEGIN
                       Copy_Script_Integer( Script_Integer_1 , IBogus );
                       Script_Suspend_Time  := Script_Integer_1;
                       Script_Suspend_Time  := Script_Suspend_Time * 10;
                       Script_Suspend_Start := TimeOfDayH;
                       Command              := Null_Command;
                    END;

       QuitSy     : Copy_Script_Integer_Constant( Script_Integer_1 );

       ChdirSy    : BEGIN
                       Copy_Script_String( Script_String , IBogus );
                       IVal := POS( ':' , Script_String );
                       IF ( IVal > 0 ) THEN
                          BEGIN
                             Script_String_2 := Script_String[1];
                             Script_String   := COPY( Script_String,
                                                        SUCC( IVal ),
                                                        255 );
                          END
                       ELSE
                          BEGIN
                             GetDir( 0 , Script_String_2 );
                             Script_String_2 := Script_String_2[1];
                          END;
                    END;

       DosSy      ,
       EditFileSy ,
       EraseFileSy,
       KeySy      ,
       MessageSy  ,
       PrintFileSy,
       RedialSy   ,
       STextSy    ,
       TextSy     ,
       TranslateSy,
       ViewFileSy,
       WaitSy     ,
       WriteLogSy : Copy_Script_String( Script_String , IBogus );

       DialSy     : BEGIN
                       Copy_Script_String          ( Script_String , IBogus );
                       Copy_Script_Integer_Constant( Script_Integer_1 );
                    END;

       ExecuteSy  : BEGIN
                       Copy_Script_String( Script_String_2 , IBogus );
                       INC( Script_Buffer_Pos );
                       Script_Parameter_Count := Script_Buffer^[Script_Buffer_Pos];
                       IF( Script_Parameter_Count > 0 ) THEN
                          BEGIN
                             NEW( Script_Parameters );
                             IF ( Script_Parameters <> NIL ) THEN
                                FOR I := 1 TO Script_Parameter_Count DO
                                   BEGIN
                                      INC( Script_Buffer_Pos );
                                      Script_Parameters^[I] :=
                                         Script_Buffer^[Script_Buffer_Pos];
                                   END
                             ELSE
                                BEGIN
                                   Command := Null_Command;
                                   INC( Script_Buffer_Pos , Script_Parameter_Count );
                                   Script_Parameter_Count := 0;
                                   EXIT;
                                END;
                          END
                       ELSE
                          Script_Parameters := NIL;
                       Script_String := 'E';
                    END;

       ExeNewSy   : BEGIN
                       Copy_Script_String( Script_String_2 , IBogus );
                       Copy_Script_String( Script_String   , IBogus );
                       Script_String := Script_String + CHR( CR );
                       MOVE( Script_String[0], Mem[PrefixSeg:$80],
                             SUCC( LENGTH( Script_String ) ) );
                       Script_String := 'E';
                    END;

       FileSy     : BEGIN
                       Copy_Script_String ( Script_String    , IBogus );
                       Copy_Script_String ( Script_String_2  , IBogus );
                       Copy_Script_String ( Script_String_3  , IBogus );
                    END;

       RInputSy   : BEGIN
                       Copy_Script_String          ( Script_String , IBogus );
                       Copy_Script_Integer_Constant( Script_Integer_1 );
                       Copy_Script_String          ( Script_String_2 ,
                                                     Script_Integer_2 );
                    END;

       GoToXYSy   : BEGIN
                       Copy_Script_Integer( Script_Integer_1 , IBogus );
                       Copy_Script_Integer( Script_Integer_2 , IBogus );
                    END;

       PImportSy  ,
       ImportSy   ,
       DeclareSy  : BEGIN
                       Copy_Script_String          ( Script_String   , IBogus );
                       Copy_Script_Integer_Constant( Script_Integer_1 );
                       Copy_Script_Integer_Constant( Script_Integer_2 );
                       Copy_Script_String          ( Script_String_2 , IBogus );
                    END;

       IfOKSy     ,
       IfOpSy     ,
       IfConSy    ,
       IfDialSy   ,
       IfFoundSy  : BEGIN
                       Copy_Script_Integer_Constant( Script_Integer_1 );
                       Copy_Script_Integer_Constant( Script_Integer_2 );
                       Copy_Script_Integer_Constant( Script_Integer_3 );
                    END;

       IfRemStrSy ,
       IfExistsSy ,
       IfLocStrSy : BEGIN
                       Copy_Script_Integer_Constant( Script_Integer_1 );
                       Copy_Script_Integer_Constant( Script_Integer_2 );
                       Copy_Script_Integer_Constant( Script_Integer_3 );
                       Copy_Script_String ( Script_String , IBogus );
                    END;

       KeySendSy  : BEGIN
                       Copy_Script_String( Script_String , IBogus );
                       Key_No := Get_Key_Index( Script_String );
                    END;


       ScriptSy   : BEGIN
                       INC( Script_Buffer_Pos );
                       Script_String     := CHR( Script_Buffer^[Script_Buffer_Pos] );
                       Copy_Script_String( Script_String_2 , IBogus );
                    END;

       SetSy      : BEGIN
                       Copy_Script_Integer_Constant( Script_Integer_1 );
                    END;

       CallSy     : BEGIN

                       INC( Script_Call_Depth );

                       WITH Script_Call_Stack[Script_Call_Depth] DO
                          BEGIN
                             Proc_Param  := Proc_Parameters;
                             Proc_Got    := Proc_Parameter_Got;
                             Proc_Count  := Proc_Parameter_Count;
                             Save_Vars   := NIL;
                          END;

                       Copy_Script_Integer_Constant( Script_Integer_1 );

                       INC( Script_Buffer_Pos );

                       Proc_Parameter_Count := Script_Buffer^[Script_Buffer_Pos];

                       IF( Proc_Parameter_Count > 0 ) THEN
                          BEGIN
                             NEW( Proc_Parameters );
                             IF ( Proc_Parameters <> NIL ) THEN
                                FOR I := 1 TO Proc_Parameter_Count DO
                                   BEGIN
                                      INC( Script_Buffer_Pos );
                                      Proc_Parameters^[I] :=
                                         Script_Buffer^[Script_Buffer_Pos];
                                   END
                             ELSE
                                BEGIN
                                   DEC( Script_Call_Depth );
                                   Command := Null_Command;
                                   EXIT;
                                END
                          END
                       ELSE
                          Proc_Parameters := NIL;

                       Script_Call_Stack[Script_Call_Depth].Return_Addr :=
                          Script_Buffer_Pos;

                       Proc_Parameter_Got    := 0;
                       Proc_Parameter_Count  := 0;

                       Script_Buffer_Pos     := PRED( Script_Integer_1 );
                       Command               := Null_Command;

                    END;

       GoToSy     : Copy_Script_Integer_Constant( Script_Integer_1 );

       WaitStrSy  : Get_WaitString;

       CaptureSy  ,
       CopyFileSy ,
       KeyDefSy   : BEGIN
                       Copy_Script_String( Script_String   , IBogus );
                       Copy_Script_String( Script_String_2 , IBogus );
                    END;

       WhenSy     : BEGIN
                       Copy_Script_String( Script_When_Text       , IBogus );
                       Copy_Script_String( Script_When_Reply_Text , IBogus );
                       When_Mode := ( LENGTH( Script_When_Text ) > 0 );
                       Command   := Null_Command;
                    END;

       FreeSpaceSy,
       InputSy    : BEGIN
                       Copy_Script_String( Script_String , IBogus );
                       Copy_Script_String( Script_String_2 , Script_Integer_1 );
                    END;

       ReceiveSy  ,
       SendSy     : BEGIN
                       Copy_Script_String( Script_String   , IBogus );
                       Copy_Script_String( Script_String_2 , IBogus );
                       Get_Transfer_Protocol;
                    END;

       CloseSy    : Copy_Script_Integer( Script_Integer_1 , IBogus );

       OpenSy     : BEGIN
                       Copy_Script_Integer( Script_Integer_1 , IBogus );
                       Copy_Script_String ( Script_String    , IBogus );
                       Copy_Script_Integer( Script_Integer_2 , IBogus );
                    END;

       ReadSy     : BEGIN
                       Copy_Script_Integer( Script_Integer_1 , IBogus );
                       Copy_Script_String ( Script_String    , Script_Integer_2 );
                       Copy_Script_Integer( Script_Integer_3 , IBogus );
                    END;

       ReadLnSy   ,
       WriteSy    ,
       WriteLnSy  : BEGIN
                      Copy_Script_Integer( Script_Integer_1 , IBogus );
                      Copy_Script_String ( Script_String , Script_Integer_2 );
                   END;

       WhereXYSy  : BEGIN
                       Copy_Script_Integer( IBogus , Script_Integer_1 );
                       Copy_Script_Integer( IBogus , Script_Integer_2 );
                    END;

       WaitCountSy: BEGIN
                       Copy_Script_Integer( LBogus , IBogus );
                       Script_Wait_Check_Length := LBogus;
                       Script_Wait_Char_Count   := 0;
                       Script_Wait_Time         := Script_Default_Wait_Time;
                       Fix_Wait_Time;
                    END;

       WaitQuietSy: BEGIN
                       Copy_Script_Integer( Script_Integer_1 , IBogus );
                       IF ( Script_Integer_1 > 0 ) THEN
                          BEGIN
                             Script_WaitQuiet_Time := Script_Integer_1;
                             Script_WaitQuiet_Time := Script_WaitQuiet_Time * 10;
                             Script_Wait_Start     := TimeOfDayH;
                             Really_Wait_String    := TRUE;
                             WaitQuiet_Mode        := TRUE;
                          END;
                       Command := Null_Command;
                    END;

       WaitTimeSy : BEGIN
                       Copy_Script_Integer( Script_Integer_1 , IBogus );
                       Script_Default_Wait_Time := Script_Integer_1;
                       Command := Null_Command;
                    END;

       WaitListSy : Get_WaitList;

       WhenDropSy : BEGIN
                       Copy_Script_String( Script_When_Drop_Text , IBogus );
                       When_Drop_Mode := ( LENGTH( Script_When_Drop_Text ) > 0 );
                       Command        := Null_Command;
                    END;

       ZapVarSy   : BEGIN
                       Copy_Script_Integer( Script_Integer_1 , IBogus );
                       Copy_Script_Integer( Script_Integer_2 , IBogus );
                    END;

       MenuSy     : Get_Menu;

       GetVarSy   : BEGIN
                       Copy_Script_String ( Script_String    , Script_Integer_1 );
                       Copy_Script_String ( Script_String_2  , Script_Integer_2 );
                       Copy_Script_String ( Script_String_3  , Script_Integer_3 );
                       I := Locate_Var( Script_Variables,
                                        Script_Variable_Count,
                                        Script_String,
                                        Script_Variables^[Script_Integer_2].Var_Value^,
                                        Script_Variables^[Script_Integer_3].Var_Value^ );
                       IF ( ( I = 0 ) AND ( Script_Stack_Depth > 0 ) ) THEN
                          I := Locate_Var( Prev_Script_Variables,
                                           Script_Stack_Position[Script_Stack_Depth].Vars_Count,
                                           Script_String,
                                           Script_Variables^[Script_Integer_2].Var_Value^,
                                           Script_Variables^[Script_Integer_3].Var_Value^ );
                       Command := Null_Command;
                    END;

       SetVarSy   : BEGIN
                       Copy_Script_String ( Script_String    , Script_Integer_1 );
                       Copy_Script_String ( Script_String_4  , Script_Integer_4 );
                       VPtrs := Script_Variables;
                       I     := Locate_Var( Script_Variables,
                                            Script_Variable_Count,
                                            Script_String,
                                            Script_String_2,
                                            Script_String_3 );
                       IF ( ( I = 0 ) AND ( Script_Stack_Depth > 0 ) ) THEN
                          BEGIN
                             VPtrs := Prev_Script_Variables;
                             I     := Locate_Var( Prev_Script_Variables,
                                                  Script_Stack_Position[Script_Stack_Depth].Vars_Count,
                                                  Script_String,
                                                  Script_String_2,
                                                  Script_String_3 );
                          END;
                       IF ( I > 0 ) THEN
                          BEGIN
                             IF ( Script_String_2 = 'INTEGER' ) THEN
                                BEGIN
                                   Script_String_4 := LTrim( Trim( Script_String_4 ) );
                                   VAL( Script_String_4, IVal, L );
                                   IF ( L = 0 ) THEN
                                      BEGIN
                                         Script_String_4[0] := CHR( 2 );
                                         MOVE( IVal, Script_String_4[1],
                                               SIZEOF( LONGINT ) );
                                      END
                                   ELSE
                                      Script_String_4 := '' + '';
                                END;
                             VPtrs^[I].Var_Value^ := Script_String_4;
                          END;
                       Command := Null_Command;
                    END;

       GetDirSy:    BEGIN
                       Copy_Script_String ( Script_String    , Script_Integer_1 );
                       Copy_Script_String ( Script_String_2  , Script_Integer_2 );
                    END;

       DirFirstSy ,
       DirNextSy  : BEGIN
                       IF ( Command = DirFirstSy ) THEN
                          BEGIN
                             Copy_Script_String ( Script_String    , IBogus );
                             Copy_Script_String ( Script_String_2  , IBogus );
                          END;
                       Copy_Script_String ( Script_String_3  , Script_Integer_1 );
                       Copy_Script_String ( Script_String_3  , Script_Integer_2 );
                       Copy_Script_String ( Script_String_3  , Script_Integer_3 );
                       Copy_Script_String ( Script_String_3  , Script_Integer_4 );
                       Copy_Script_String ( Script_String_3  , Script_Integer_5 );
                    END;

       CommFlushSy,
       CommDrainSy: Copy_Script_Integer( Script_Integer_1 , IBogus );

   END (* CASE *);

END   (* Get_Script_Command *);
