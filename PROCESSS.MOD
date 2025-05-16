(*----------------------------------------------------------------------*)
(*   Process_Script --- Convert PibTerm script file to in-core code.    *)
(*----------------------------------------------------------------------*)

PROCEDURE Process_Script( Script_FName  : AnyStr;
                          Script_ComLet : CHAR     );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Process_Script                                       *)
(*                                                                      *)
(*     Purpose:    Convert PibTerm script file to in-core instructions. *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*         Process_Script( Script_FName  : AnyStr;                      *)
(*                         Script_ComLet : CHAR     );                  *)
(*                                                                      *)
(*            Script_FName  --- Script name                             *)
(*            Script_ComLet --- Script command to execute               *)
(*                                                                      *)
(*                                                                      *)
(*      Remarks:                                                        *)
(*                                                                      *)
(*         The entire script file is read and converted to an in-core   *)
(*         representation which can be executed.                        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   Max_Script_Labels = 20          (* Maximum # of labels allowed *);
   Max_Script_Stack  = 128         (* Maximum script stack depth  *);
   MaxStack          = 64          (* Maximum expression stack    *);
   Max_Script_Procs  = 64          (* Maximum procedures here     *);

   IntegerMissing    = 0           (* No integer at all           *);
   IntegerVariable   = 1           (* Convenient synonym          *);
   IntegerConstant   = 2           (* "" ""                       *);
   IntegerConsOnly   = 3           (* "" ""                       *);

   False_Offset      = 9           (* Offset for FALSE in IFs     *);

CONST
   LongZero : LONGINT = 0          (* Long integer constant zero  *);

TYPE
                                   (* Argument types for internal procedures *)

   Proc_Arg_Type_Vector = ARRAY[1..MaxScriptArgs] OF OperandType;
   Proc_Arg_Type_Ptr    = ^Proc_Arg_Type_Vector;

                                   (* Records procedure reference *)
   Script_Proc_Type = RECORD
                         Name       : ShortStr  (* Name                   *);
                         Buffer_Pos : INTEGER   (* Offset in code         *);
                         NArgs      : INTEGER   (* # of arguments         *);
                         Type_Ptr   : Proc_Arg_Type_Ptr (* Argument types *);
                      END;

                                   (* Records procedure nesting information *)
   Script_Proc_Stack_Type = RECORD
                               Old_VCount : INTEGER   (* Var count before proc  *);
                               Old_PCount : INTEGER   (* Proc count before proc *);
                               GOTO_Pos   : INTEGER   (* Where GOTO is located  *);
                            END;

   Script_Var_Record   = RECORD
                            Var_Name   : STRING[10]    (* Name *);
                            Var_Type   : OperandType   (* Type *);
                         END;

VAR
                                   (* Script procedure definition vector *)

   Script_Procs           : ARRAY[1..Max_Script_Procs] OF Script_Proc_Type;

                                   (* Number of procedures currently defined *)

   Script_Proc_Count      : INTEGER;

                                   (* Where current procedure starts *)

   Script_Proc_Start      : INTEGER;

                                   (* Current stack levels, conditional     *)
                                   (* script commands.                      *)

   Script_Repeat_Level    : INTEGER;
   Script_If_Level        : INTEGER;
   Script_While_Level     : INTEGER;
   Script_Case_Level      : INTEGER;
   Script_For_Level       : INTEGER;
   Script_Proc_Level      : INTEGER;

                                   (* Stacks for conditional commands       *)

   Script_Repeat_Stack    : ARRAY[1..Max_Script_Stack] OF INTEGER;
   Script_If_Stack        : ARRAY[1..Max_Script_Stack] OF INTEGER;
   Script_ElseIf_Stack    : ARRAY[1..Max_Script_Stack] OF INTEGER;
   Script_While_Stack     : ARRAY[1..Max_Script_Stack] OF INTEGER;
   Script_Case_Var_Stack  : ARRAY[1..Max_Script_Stack] OF INTEGER;
   Script_Case_Cnt_Stack  : ARRAY[1..Max_Script_Stack] OF INTEGER;
   Script_For_Stack       : ARRAY[1..Max_Script_Stack] OF INTEGER;
   Script_Proc_Stack      : ARRAY[1..Max_Script_Stack] OF Script_Proc_Stack_Type;

   L                      : INTEGER;
   I                      : INTEGER;
   K                      : INTEGER;
   IS                     : INTEGER;
   Local_Save             : Saved_Screen_Ptr;
   Ch                     : CHAR;
   Text_Line              : AnyStr;
   Spill_File             : FILE;
   OK_Script_Command      : BOOLEAN;
   Script_Command_Token   : AnyStr;
   Script_Line            : AnyStr;
   Saved_Script_Line      : AnyStr;
   Length_Script_Line     : INTEGER;
   Script_Line_Number     : INTEGER;
   Current_Script_Command : PibTerm_Command_Type;
   NextP                  : LONGINT;
   NextP_Bytes            : ARRAY[1..4] OF BYTE ABSOLUTE NextP;

   Script_Debug_File      : TEXT;
   Script_Debug_Mode      : BOOLEAN;

   Use_Script_Library     : BOOLEAN;
   Script_Short_Name      : AnyStr;
   Script_File_Name_Given : BOOLEAN;
   Script_EOF             : BOOLEAN;
   Script_Buffer_Hold     : Script_Buffer_Ptr;
   Script_Memory_Avail    : LONGINT;
   Got_Script             : BOOLEAN;
   Script_File_OK         : BOOLEAN;
   Save_BPos              : INTEGER;
   ICode                  : INTEGER;
   LCode                  : INTEGER;
   Result_Index           : LONGINT;
   Save_Script_File_Mode  : BOOLEAN;

                                   (* Script variables *)

   Script_Vars              : ARRAY[0..MaxScriptVariables] OF Script_Var_Record;
   Script_Variable_Kount    : INTEGER;
   Script_Variable_MaxKount : INTEGER;

                                   (* Indices of script arguments *)

   Arg_Index                : ARRAY[1..MaxScriptArgs] OF INTEGER;

   Import_Count             : INTEGER (* Number of variables imported *);

(* STRUCTURED *) CONST

   OperNames    : ARRAY[0..MaxOperNames1] OF String12 =
                  ('**NOOP**', '+','-','*','/','=','<','<=','>','>=','<>',
                   'AND','NOT','OR','XOR',
                   'SUBSTR','INDEX','LENGTH','CONCAT','CONNECTED','WAITFOUND',
                   'STRING','NUMBER','ATTENDED','FILEEXISTS','EOF','IORESULT',
                   'DUPL'  , 'UPPERCASE', 'TRIM', 'PARAMCOUNT', 'PARAMSTR',
                   'PARAMLINE','DIALED','LTRIM', 'DATE', 'TIME', 'DIALENTRY',
                   'ORD', 'CHR', 'READCTRL', 'WRITECTRL', 'ENHKEYBD',
                   'KEYSTRING');

   OperNames2   : ARRAY[OperType] OF String12 =
                  ('**NOOP**', '+','-','*','/','=','<','<=','>','>=','<>',
                   '=','<','<=','>','>=','<>',
                   'AND','NOT','OR','XOR',
                   'SUBSTR','INDEX','LENGTH','CONCAT','CONNECTED','WAITFOUND',
                   'STRING','NUMBER','ATTENDED','FILEEXISTS','EOF','IORESULT',
                   'DUPL'  , 'UPPERCASE', 'TRIM', 'PARAMCOUNT', 'PARAMSTR',
                   'PARAMLINE', 'DIALED', 'LTRIM','DATE','TIME','DIALENTRY',
                   'ORD', 'CHR', 'READCTRL', 'WRITECTRL', 'ENHKEYBD',
                   'KEYSTRING' );

   OperPrecs    : ARRAY[OperType] OF BYTE
                = ( 0, 4, 4, 5, 5, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
                    3, 6, 3, 3, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
                    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7 );

   OperSyms     : ARRAY[0..MaxOperNames1] OF OperType
                = ( NoOpSy, AddSy, SubtractSy, MultSy, DivideSy,
                    EqualISy, LessISy, LessEqualISy, GreaterISy, GreaterEqualISy,
                    NotEqualISy,
                    AndSy, NotSy, OrSy, XorSy,
                    SubStrSy, IndexSy, LengthSy, ConcatSy, ConnectedSy,
                    WaitFoundSy, StringSy, NumberSy, AttendedSy,
                    FileExistsSy, EofSy, IOResultSy, DuplSy, UpperCaseSy,
                    TrimSy, ParamCountSy, ParamStrSy, ParamLineSy, DialedSy,
                    LTrimSy, DateSy, TimeSy, DialEntrySy,
                    OrdSy, ChrSy, ReadCtrlSy, WriteCtrlSy, EnhKeybdSy,
                    KeyStringSy );

   Number_Args : ARRAY[OperType] OF BYTE =
                 ( 0,
                   2, 2, 2, 2,
                   2, 2, 2, 2, 2, 2,
                   2, 2, 2, 2, 2, 2,
                   2, 1, 2, 2,
                   3, 2, 1, 2, 0, 0,
                   1, 1, 0, 1, 1, 0, 2,
                   1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 2, 1, 1, 1, 0, 1 );

                                   (* Valid command names for scripts *)

   Script_File_Command_Names : ARRAY[1..Max_Script_File_Commands] OF STRING[8]
                             = ( 'ADDCOMMA',
                                 'ADDLF',     'ALARM',    'BREAK',     'CALL',
                                 'CAPTURE',   'CASE',     'CHDIR',     'CLEAR',
                                 'CLOSE',     'CLREOL',   'COMDRAIN',
                                 'COMFLUSH',  'COPYFILE',
                                 'DECLARE',   'DELAY',    'DELLINE',   'DIAL',
                                 'DIRFIRST',  'DIRNEXT',  'DOCASE',    'DOS',
                                 'ECHO',      'EDITFILE', 'ELSE',      'ELSEIF',
                                 'ENDCASE',   'ENDDOCAS', 'ENDFOR',    'ENDIF',
                                 'ENDPROC',   'ENDWHILE', 'ERASEFIL',  'EXECUTE',
                                 'EXIT',      'EXITALL',  'FILE',      'FOR',
                                 'FREESPAC',  'GETDIR',   'GETPARAM',  'GETVAR',
                                 'GOTOXY',    'HANGUP',   'HOST',      'IF',
                                 'IMPORT',    'INPUT',    'INSLINE',   'KEY',
                                 'KEYDEF',    'KEYFLUSH', 'KEYSEND',   'LABEL',
                                 'LOG',       'MENU',     'MESSAGE',   'MUTE',
                                 'OPEN',      'PARAM',    'PRINTFIL',  'PROCEDUR',
                                 'QUIT',      'READ',     'READLN',    'RECEIVE',
                                 'REDIAL',    'REPEAT',   'RESET',     'RETURN',
                                 'RINPUT',    'SCRIPT',   'SCREENDU',  'SEND' ,
                                 'SET',       'SETPARAM', 'SETVAR',    'STEXT',
                                 'SUSPEND',   'TEXT',     'TRANSLAT',  'UNTIL',
                                 'VIEWFILE',  'WAIT',     'WAITCOUNT', 'WAITLIST',
                                 'WAITQUIET', 'WAITSTRI', 'WAITTIME',  'WHEN',
                                 'WHENDROP',  'WHENLIST', 'WHEREXY',   'WHILE',
                                 'WRITE',     'WRITELN',  'WRITELOG'
                                );

                                   (* Corresponding command types *)

   Script_File_Commands      : ARRAY[1..Max_Script_File_Commands] OF
                               PibTerm_Command_Type =
      ( AddCommandSy,
        AddLFSy,     AlarmSy,      BreakSy,      CallSy,
        CaptureSy,   CaseSy,       ChDirSy,      ClearSy,
        CloseSy,     ClrEolSy,     CommDrainSy,
        CommFlushSy, CopyFileSy,
        DeclareSy,   DelaySy,      DelLineSy,    DialSy,
        DirFirstSy,  DirNextSy,    DoCaseSy,     DosSy,
        EchoSy,      EditFileSy,   ElseSy,       ElseIfSy,
        EndCaseSy,   EndDoCaseSy,  EndForSy,     EndIfSy,
        EndProcSy,   EndWhileSy,   EraseFileSy,  ExecuteSy,
        ExitSy,      ExitAllSy,    FileSy,       ForSy,
        FreeSpaceSy, GetDirSy,     GetParamSy,   GetVarSy,
        GoToXYSy,    HangUpSy,     HostSy,       IfOpSy,
        ImportSy,    InputSy,      InsLineSy,    KeySy,
        KeyDefSy,    KeyFlushSy,   KeySendSy,    LabelSy,
        LogSy,       MenuSy,       MessageSy,    MuteSy,
        OpenSy,      ParamSy,      PrintFileSy,  ProcedureSy,
        QuitAllSy,   ReadSy,       ReadLnSy,     ReceiveSy,
        RedialSy,    RepeatSy,     ResetSy,      ReturnSy,
        RInputSy,    ScriptSy,     SDumpSy,      SendSy,
        SetSy,       SetParamSy,   SetVarSy,     STextSy,
        SuspendSy,   TextSy,       TranslateSy,  UntilSy,
        ViewFileSy,  WaitSy,       WaitCountSy,  WaitListSy,
        WaitQuietSy, WaitStrSy,    WaitTimeSy,   WhenSy,
        WhenDropSy,  WhenListSy,   WhereXYSy,    WhileSy,
        WriteSy,     WriteLnSy,    WriteLogSy
      );

(* STRUCTURED *) CONST
   S1         : STRING[36] = 'Expected integer variable but found ';
   S2         : STRING[48] = 'Expected integer variable or constant but found ';
   S3         : STRING[ 9] = ' instead.';
   S4         : STRING[ 9] = 'Variable ';
   S5         : STRING[14] = ' not declared.';
   S6         : STRING[24] = ' should be integer type.';
   S7         : STRING[23] = ' should be string type.';
   S8         : STRING[16] = 'Result variable ';
   S9         : STRING[12] = ' is missing.';
   S10        : STRING[ 8] = 'Missing ';
   S11        : STRING[18] = 'Bad variable name.';
   S12        : STRING[ 9] = 'Bad type.';
   S13        : STRING[15] = ' is wrong type.';
   S14        : STRING[23] = 'Bad boolean expression.';
   S15        : STRING[11] = 'Unattached ';
   S16        : STRING[35] = 'Expected string variable but found ';
   S17        : STRING[47] = 'Expected string variable or constant but found ';
   S18        : STRING[28] = 'Expected variable but found ';
   S19        : STRING[16] = 'Bad script name.';
   S20        : STRING[13] = 'Bad argument.';
   S21        : STRING[10] = 'Procedure ';
   S22        : STRING[40] = ' must precede all PROCEDURE definitions.';
   S23        : STRING[38] = 'IMPORT cannot appear inside procedure.';
   S24        : STRING[35] = 'Wrong number of arguments in CALL.';
   S25        : STRING[18] = 'Bad initial value.';

   Blank_Set              : SET OF CHAR = [' ', ','];
   Letters_Set            : SET OF CHAR = ['A'..'Z', 'a'..'z'];

(*----------------------------------------------------------------------*)
(*             Parse_Error --- Report error in parsing expression       *)
(*----------------------------------------------------------------------*)

PROCEDURE Parse_Error( Error_Mess : AnyStr );

BEGIN (* Parse_Error *)

   WRITELN;
   WRITELN('>>Error>> ',Error_Mess);
   WRITELN;

   OK_Script_Command := FALSE;

END   (* Parse_Error *);

(*----------------------------------------------------------------------*)
(*             Skip_Blanks --- Skip blanks anb commas in script text    *)
(*----------------------------------------------------------------------*)

PROCEDURE Skip_Blanks;

BEGIN (* Skip_Blanks *)

   WHILE ( IS <= Length_Script_Line ) AND
         ( Script_Line[IS] IN Blank_Set ) DO
      INC( IS );

END   (* Skip_Blanks *);

(*----------------------------------------------------------------------*)
(*              LookUpVarName  ---   Look up variable name              *)
(*----------------------------------------------------------------------*)

FUNCTION LookUpVarName(     Var_Name : AnyStr;
                        VAR Var_Type : OperandType ) : INTEGER;

VAR
   I: INTEGER;

BEGIN (* LookUpVarName *)
{
   IF Script_Debug_Mode THEN
      BEGIN
         WRITELN( Script_Debug_File ,
                  '>>> Entered LookUpVarName:  Var_Name              = <',
                       Var_Name, '>' );
         WRITELN( Script_Debug_File ,
                  '                            Script_Variable_Kount = ',
                       Script_Variable_Kount );
      END;
}
   LookUpVarName := 0;
   Var_Type      := Bad_Operand_Type;
   Var_Name      := UpperCase( Var_Name );

   FOR I := Script_Variable_Kount DOWNTO 1 DO
      BEGIN
         IF Var_Name = Script_Vars[I].Var_Name THEN
            BEGIN
               LookUpVarName := I;
               Var_Type      := Script_Vars[I].Var_Type;
               EXIT;
            END;
      END;

END   (* LookUpVarName *);

(*----------------------------------------------------------------------*)
(*        Get_Next_Token  ---  Get next token from script command       *)
(*----------------------------------------------------------------------*)

FUNCTION Get_Next_Token( VAR Token      : AnyStr;
                         VAR Token_Type : OperandType;
                         VAR Oper_Type  : OperType;
                         VAR Index      : LONGINT   ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Get_Next_Token                                       *)
(*                                                                      *)
(*     Purpose:    Extracts next element from script line.              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_Next_Token( VAR Token      : AnyStr;                      *)
(*                        VAR Token_Type : OperandType;                 *)
(*                        VAR Oper_Type  : OperType;                    *)
(*                        VAR Index      : LONGINT  ) : BOOLEAN;        *)
(*                                                                      *)
(*            Token       --- Token extracted from script line          *)
(*            Token_Type  --- Type of token                             *)
(*            Oper_Type   --- Type of operator if token is operator     *)
(*            Index       --- Variable index if token is variable or    *)
(*                            value of integer constant                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Ch         : CHAR;
   Quote      : CHAR;
   UToken     : AnyStr;
   End_String : BOOLEAN;
   I          : INTEGER;

BEGIN (* Get_Next_Token *)
                                   (* Set defaults *)
   Token      := '';
   Oper_Type  := NoOpSy;
   Token_Type := Bad_Operand_Type;
   INC( IS );
   Index      := 0;
                                   (* Skip leading blanks *)
   Skip_Blanks;
                                   (* If we ran off end of line, *)
                                   (* no more tokens to extract. *)

   IF IS > Length_Script_Line THEN
      Get_Next_Token := FALSE
   ELSE
      BEGIN
                                   (* Otherwise, pick up first char     *)
                                   (* and figure out token type from it *)
         Get_Next_Token := TRUE;

         Ch := Script_Line[IS];

         IF ( Ch = ',' ) THEN
            BEGIN
               Token      := Script_Line[IS];
               Token_Type := Comma_Type;
            END
         ELSE IF Ch IN ['+','-','/','*','=','<','>'] THEN
            BEGIN
               Token      := Script_Line[IS];
               Token_Type := Operator_Type;
               CASE Ch OF
                  '<':  BEGIN
                           INC( IS );
                           CASE Script_Line[IS] OF
                              '=': Token := '<=';
                              '>': Token := '<>';
                              ELSE
                                   DEC( IS );
                           END (* CASE *);
                        END;
                  '>':  BEGIN
                           INC( IS );
                           IF ( Script_Line[IS] = '=' ) THEN
                              Token := '>='
                           ELSE
                              DEC( IS );
                           END (* CASE *);
                        END;

            END
         ELSE IF ( Ch = '(' ) THEN
            BEGIN
               Token      := Script_Line[IS];
               Token_Type := Left_Paren_Type;
            END
         ELSE IF ( Ch = ')' ) THEN
            BEGIN
               Token      := Script_Line[IS];
               Token_Type := Right_Paren_Type;
            END
         ELSE IF ( Ch IN ['0'..'9'] ) THEN
            BEGIN
               WHILE ( Ch IN ['0'..'9'] ) DO
                  BEGIN
                     Token    := Token + Ch;
                     Index    := Index * 10 + ( ORD( Ch ) - ORD('0') );
                     INC( IS );
                     Ch       := Script_Line[IS];
                  END;
               DEC( IS );
               Token_Type := Integer_Constant_Type;
            END
         ELSE IF ( Ch IN ['''','"'] ) THEN
            BEGIN                  (* Quoted string constant *)

               Token_Type := String_Constant_Type;
               Quote      := Ch;
               End_String := FALSE;

               REPEAT

                  INC( IS );

                                   (* Note:  two quotes in a row used   *)
                                   (*        to indicate single quote   *)
                                   (*        to be inserted into string *)

                  IF ( IS <= Length_Script_Line ) THEN
                     IF ( Script_Line[IS] <> Quote ) THEN
                        Token := Token + Script_Line[IS]
                     ELSE
                        BEGIN
                           IF ( SUCC( IS ) <= Length_Script_Line ) THEN
                              IF ( Script_Line[ SUCC( IS ) ] = Quote ) THEN
                                 BEGIN
                                    Token := Token + Quote;
                                    INC( IS );
                                 END
                              ELSE
                                 End_String := TRUE
                           ELSE
                              End_String := TRUE;
                        END
                  ELSE
                     End_String := TRUE;

               UNTIL End_String;

            END
         ELSE
            BEGIN                  (* Pick up variable/keyword/function name *)

               WHILE ( Ch IN ['a'..'z', 'A'..'Z', '0'..'9'] ) DO
                  BEGIN
                     Token    := Token + Ch;
                     INC( IS );
                     Ch       := Script_Line[IS];
                  END;

               DEC( IS );

                                   (* Look up name and see if it is a *)
                                   (* variable or not.                *)

               Index      := LookUpVarName( Token , Token_Type );

                                   (* If not there, assume it's a string *)
                                   (* variable = keyword.                *)

               IF ( Index = 0 ) THEN
                  Token_Type := String_Variable_Type;

            END;
                                   (* Check if variable is possibly *)
                                   (* a function.                   *)

            IF ( ( Token_Type IN [Operator_Type, String_Variable_Type] ) AND
                 ( Index = 0 ) ) THEN
               BEGIN
                  UToken := UpperCase( Token );
                  FOR I := 1 TO MaxOperNames DO
                     BEGIN
                        IF ( UToken = OperNames[I] ) THEN
                           BEGIN
                              Oper_Type  := OperSyms[I];
                              Token_Type := Operator_Type;
                              Index      := ORD( Operator_Type );
                           END;
                     END;
               END;

      END;

END   (* Get_Next_Token *);

(*----------------------------------------------------------------------*)
(*        Get_Integer --- pick up integer constant or variable          *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Integer( VAR QNum      : BOOLEAN;
                       VAR IntVal    : LONGINT;
                       VAR IntType   : INTEGER;
                           MustBeVar : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_Integer                                          *)
(*                                                                      *)
(*     Purpose:    Extracts integer from a string.                      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_Integer(  VAR QNum      : BOOLEAN;                        *)
(*                      VAR IntVal    : LONGINT;                        *)
(*                      VAR IntType   : BOOLEAN;                        *)
(*                          MustBeVar : BOOLEAN );                      *)
(*                                                                      *)
(*            QNum      --- TRUE if a number extracted                  *)
(*            IntVal    --- integer extracted or 0 if none              *)
(*            IntType   --- Type of constant found                      *)
(*            MustBeVar --- TRUE if integer variable required rather    *)
(*                          than just constant.                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Token      : AnyStr;
   Token_Type : OperandType;
   Index      : LONGINT;
   Oper_Type  : OperType;

BEGIN (* Get_Integer *)
                                   (* Initialize.          *)
   IntType := IntegerMissing;
   IntVal  := 0;
   QNum    := FALSE;
                                   (* Pick up next token.  *)

   IF ( Get_Next_Token( Token, Token_Type, Oper_Type, Index ) ) THEN
      BEGIN                        (* Got token -- check if integer *)

         CASE Token_Type OF

            Integer_Variable_Type : BEGIN
                                       QNum    := TRUE;
                                       IntVal  := Index;
                                       IntType := IntegerVariable;
                                    END;

            Integer_Constant_Type : IF MustBeVar THEN
                                       Parse_Error( S1 + Token + S3 )
                                    ELSE
                                       BEGIN
                                          QNum    := TRUE;
                                          IntVal  := Index;
                                          IntType := IntegerConstant;
                                       END;

            String_Variable_Type  : IF ( Index = 0 ) THEN
                                       Parse_Error( S4 + Token + S5 )
                                    ELSE
                                       Parse_Error( S4 + Token + S6 );

            ELSE                    IF MustBeVar THEN
                                       Parse_Error( S1 + Token + S3 )
                                    ELSE
                                       Parse_Error( S2 + Token + S3 );
         END (* CASE *);

      END;

END   (* Get_Integer *);

(*----------------------------------------------------------------------*)
(*    Copy_String_To_Buffer --- Copy string from script line to buffer  *)
(*----------------------------------------------------------------------*)

PROCEDURE Copy_String_To_Buffer( S     : AnyStr;
                                 SType : OperandType;
                                 SIndex: LONGINT );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Copy_String_To_Buffer                                *)
(*                                                                      *)
(*     Purpose:    Copies string from script line to buffer             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Copy_String_To_Buffer( S     : AnyStr;                        *)
(*                               SType : OperandType;                   *)
(*                               SIndex: LONGINT );                     *)
(*                                                                      *)
(*           S      --- String to insert                                *)
(*           SType  --- Type of string                                  *)
(*           SIndex --- Variable index if Stype = String_Variable       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   L     : INTEGER;
   I     : INTEGER;
   IType : INTEGER;

BEGIN (* Copy_String_To_Buffer *)
                                   (* Mark string type *)
   CASE SType OF
      String_Variable_Type : BEGIN
                                IF ( S = '$LOC' ) THEN
                                   IType := 1
                                ELSE IF ( S = '$REM' ) THEN
                                   IType := 2
                                ELSE
                                   IType := 3;
                             END;
      String_Constant_Type : IType := 0;
   END (* CASE *);

   INC( Script_Buffer_Pos );

   Script_Buffer^[Script_Buffer_Pos] := IType;
{--IMP
   IF Script_Debug_Mode THEN
      WRITELN( Script_Debug_File , Script_Buffer_Pos:4 , 'string type = ', IType:4 );
}
                                   (* Insert length, string if *)
                                   (* quoted string type       *)
   IF ( IType = 0 ) THEN
      BEGIN

         L                                 := LENGTH( S );
         INC( Script_Buffer_Pos );
         Script_Buffer^[Script_Buffer_Pos] := L;
{--IMP
         IF Script_Debug_Mode THEN
             WRITE( Script_Debug_File , Script_Buffer_Pos:4 , ' ', L:4 );
}
         FOR I := 1 TO L DO
            BEGIN

               INC( Script_Buffer_Pos );
               Script_Buffer^[Script_Buffer_Pos] := ORD( S[I] );
            END;
{--IMP
         IF Script_Debug_Mode THEN
            BEGIN
               WRITE  ( Script_Debug_File , ' ', S );
               WRITELN( Script_Debug_File );
            END;
}
      END
                                   (* Insert variable index *)
   ELSE IF ( IType = 3 ) THEN
      BEGIN
         INC( Script_Buffer_Pos );
         Script_Buffer^[Script_Buffer_Pos] := SIndex;
{--IMP
         IF Script_Debug_Mode THEN
            WRITELN( Script_Debug_File , Script_Buffer_Pos:4 ,
                     'Variable index = ', SIndex:3 );
}
      END;

END   (* Copy_String_To_Buffer *);

(*----------------------------------------------------------------------*)
(*           Get_String --- Get script line string                      *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_String(     MustBeVar  : BOOLEAN;
                      VAR Token      : AnyStr;
                      VAR Token_Type : OperandType;
                      VAR Oper_Type  : OperType;
                      VAR Index      : LONGINT;
                      VAR Got_String : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_String                                           *)
(*                                                                      *)
(*     Purpose:    Get script line string                               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_String(     MustBeVar  : BOOLEAN;                         *)
(*                    VAR Token      : AnyStr;                          *)
(*                    VAR Token_Type : OperandType;                     *)
(*                    VAR Oper_Type  : OperType;                        *)
(*                    VAR Index      : LONGINT;                         *)
(*                    VAR Got_String : BOOLEAN );                       *)
(*                                                                      *)
(*           MustBeVar   --- TRUE if string must be variable rather than*)
(*                           constant.                                  *)
(*           Token       --- Token extracted from script line           *)
(*           Token_Type  --- Type of token                              *)
(*           Oper_Type   --- Type of operator if token is operator      *)
(*           Index       --- Variable index if token is variable or     *)
(*                           value of integer constant                  *)
(*           Got_String  --- TRUE if string found and stored.           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Get_String *)
                                   (* Get string if possible *)
   Got_String := FALSE;

   IF ( Get_Next_Token( Token, Token_Type, Oper_Type, Index ) ) THEN
      BEGIN                        (* Got token -- check if string *)

         CASE Token_Type OF

            Integer_Variable_Type : IF ( ( Index = 0 ) AND MustBeVar ) THEN
                                       Parse_Error( S4 + Token + S5 )
                                    ELSE
                                       Parse_Error( S4 + Token + S7 );

            String_Variable_Type  : IF ( Index = 0 ) THEN
                                       Parse_Error( S4 + Token + S5 )
                                    ELSE
                                       Got_String := TRUE;

            String_Constant_Type  : IF MustBeVar THEN
                                       Parse_Error( S16 + Token + S3 )
                                    ELSE
                                       Got_String := TRUE;

            ELSE                    IF MustBeVar THEN
                                       Parse_Error( S16 + Token + S3 )
                                    ELSE
                                       Parse_Error( S17 + Token + S3 );
         END (* CASE *);

      END;

END   (* Get_String *);

(*----------------------------------------------------------------------*)
(*  Get_And_Copy_String_To_Buffer --- Copy script line string to buffer *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_And_Copy_String_To_Buffer(     MustBeVar : BOOLEAN;
                                             CopyEmpty : BOOLEAN;
                                         VAR GotString : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_And_Copy_String_To_Buffer                        *)
(*                                                                      *)
(*     Purpose:    Copies quoted string from script line to buffer      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_And_Copy_String_To_Buffer(     MustBeVar : BOOLEAN;       *)
(*                                           CopyEmpty : BOOLEAN );     *)
(*                                       VAR GotString : BOOLEAN );     *)
(*                                                                      *)
(*           MustBeVar --- TRUE if string must be variable rather than  *)
(*                         constant.                                    *)
(*           CopyEmpty --- Copy empty string if none found.             *)
(*           GotString --- TRUE if string found and stored.             *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Token      : AnyStr;
   Token_Type : OperandType;
   Index      : LONGINT;
   Oper_Type  : OperType;

BEGIN (* Get_And_Copy_String_To_Buffer *)

   Get_String( MustBeVar, Token, Token_Type, Oper_Type, Index, GotString );

                                   (* If we got a string, copy it *)
                                   (* to script buffer.           *)

   IF ( ( NOT GotString ) AND CopyEmpty ) THEN
      BEGIN
         Token_Type := String_Constant_Type;
         GotString  := TRUE;
      END;

   IF GotString THEN
      Copy_String_To_Buffer( Token, Token_Type, Index );

END   (* Get_And_Copy_String_To_Buffer *);

(*----------------------------------------------------------------------*)
(*     Copy_Integer_To_Buffer --- Copy integer to script line buffer    *)
(*----------------------------------------------------------------------*)

PROCEDURE Copy_Integer_To_Buffer( IntVal   : LONGINT;
                                  Variable : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Copy_Integer_To_Buffer                               *)
(*                                                                      *)
(*     Purpose:    Copies integer to script line buffer                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Copy_Integer_To_Buffer( IntVal   : INTEGER;                   *)
(*                                Variable : INTEGER  );                *)
(*                                                                      *)
(*           IntVal   --- Value to place in script buffer               *)
(*           Variable --- Type of constant to store                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Copy_Integer_To_Buffer *)

   CASE Variable OF

      IntegerVariable : BEGIN

                           INC( Script_Buffer_Pos );
                           Script_Buffer^[Script_Buffer_Pos] := IntVal;

                        END;

      IntegerConstant : BEGIN

                           INC( Script_Buffer_Pos );
                           Script_Buffer^[Script_Buffer_Pos] := 0;

                           MOVE( IntVal,
                                 Script_Buffer^[ Script_Buffer_Pos + 1 ],
                                 SIZEOF( LONGINT ) );

                           INC( Script_Buffer_Pos , 4 );

                        END;

      IntegerConsOnly : BEGIN

                           MOVE( IntVal,
                                 Script_Buffer^[ Script_Buffer_Pos + 1 ],
                                 SIZEOF( LONGINT ) );

                           INC( Script_Buffer_Pos , 4 );

                        END;

      ELSE;

   END (* CASE *);

END   (* Copy_Integer_To_Buffer *);

(*----------------------------------------------------------------------*)
(*        Copy_Byte_To_Buffer --- Copy byte to script line buffer       *)
(*----------------------------------------------------------------------*)

PROCEDURE Copy_Byte_To_Buffer( ByteVal : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Copy_Byte_To_Buffer                                  *)
(*                                                                      *)
(*     Purpose:    Copies byte to script line buffer                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Copy_Byte_To_Buffer( IntVal : INTEGER );                      *)
(*                                                                      *)
(*           ByteVal --- Value to place in script buffer                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Copy_Byte_To_Buffer *)

   INC( Script_Buffer_Pos );
   Script_Buffer^[Script_Buffer_Pos] := ByteVal;
{--IMP
   IF Script_Debug_Mode THEN
       BEGIN
          WRITE( Script_Debug_File , Script_Buffer_Pos:4 , ' ', ByteVal,
                 ' (Byte)' );
          IF ( ByteVal > 32 ) AND ( ByteVal < 127 ) THEN
             WRITE( Script_Debug_File , ' (',CHR( ByteVal ),')' );
          WRITELN( Script_Debug_File );
       END;
}
END   (* Copy_Byte_To_Buffer *);

(*----------------------------------------------------------------------*)
(*        Parse_Expression --- Parse variable in script command         *)
(*----------------------------------------------------------------------*)

FUNCTION Parse_Expression ( Stop_Token : AnyStr ) : BOOLEAN;

CONST
   MaxOperatorStack = 10;

VAR
   PC             : INTEGER;
   Token          : AnyStr;
   Token_Type     : OperandType;
   Operator_Stack : ARRAY[0..MaxOperatorStack] OF OperType;
   Prec_Stack     : ARRAY[0..MaxOperatorStack] OF BYTE;
   Paren_Stack    : ARRAY[0..MaxOperatorStack] OF INTEGER;
   Stack_Size     : INTEGER;
   Num            : INTEGER;
   Op             : INTEGER;
   Ierr           : INTEGER;
   Polish         : AnyStr;
   I              : LONGINT;
   Oper_Type      : OperType;
   Found_Stop     : BOOLEAN;
   Found_Token    : BOOLEAN;

LABEL
   Parsing_Error;

(*----------------------------------------------------------------------*)

PROCEDURE Dump_Paren_Stack;

BEGIN (* Dump_Paren_Stack *)

   WHILE ( ( Stack_Size > 0 ) AND ( Paren_Stack[Stack_Size] >= PC ) ) DO
      BEGIN
         Copy_Byte_To_Buffer( ORD( Operator_Type ) );
         Copy_Byte_To_Buffer( ORD(Operator_Stack[Stack_Size]) );
         Polish      := Polish + OperNames2[Operator_Stack[Stack_Size]] + ';';
         DEC( Stack_Size );
      END;

END   (* Do_Right_Parens *);

(*----------------------------------------------------------------------*)

BEGIN (* Parse_Expression *)

   PC             := 0;
   Stack_Size     := 0;
   Polish         := '';
   Save_BPos      := Script_Buffer_Pos;

   Prec_Stack[0]  := 0;
   Paren_Stack[0] := 0;
   Found_Stop     := FALSE;

   Blank_Set      := [' '];
   Found_Token    := Get_Next_Token( Token , Token_Type , Oper_Type, I );

   WHILE ( Found_Token AND ( NOT Found_Stop ) ) DO
      BEGIN
{--IMP
         IF Script_Debug_Mode THEN
            WRITELN( Script_Debug_File , 'Next token: ',Token,
                     ', type is: ',ORD(Token_Type), ' oper is ',
                     ORD( Oper_Type ) );
}
         CASE Token_Type OF
            Left_Paren_Type       : PC := PC + MaxPrec;
            Comma_Type            : Dump_Paren_Stack;
            Right_Paren_Type      : BEGIN
                                       PC := PC - MaxPrec;
                                       Dump_Paren_Stack;
                                    END;
            Integer_Constant_Type : BEGIN
                                       Copy_Byte_To_Buffer   ( ORD( Integer_Constant_Type ) );
                                       Copy_Integer_To_Buffer( I , IntegerConsOnly);
                                       Polish      := Polish + Token + ';';
                                    END;
            String_Constant_Type  : BEGIN
                                       Copy_Byte_To_Buffer( ORD( String_Constant_Type ) );
                                       Copy_Byte_To_Buffer( LENGTH( Token ) );
                                       FOR I := 1 TO LENGTH( Token ) DO
                                          Copy_Byte_To_Buffer( ORD( Token[I] ) );
                                       Polish      := Polish + Token + ';';
                                    END;
            String_Variable_Type,
            Integer_Variable_Type : BEGIN
                                       IF ( UpperCase( Token ) = Stop_Token ) THEN
                                          Found_Stop := TRUE
                                       ELSE
                                          BEGIN
                                             IF ( I = 0 ) THEN
                                                BEGIN
                                                   PC := 99;
                                                   GOTO Parsing_Error;
                                                END
                                             ELSE
                                                BEGIN
                                                   Copy_Byte_To_Buffer( ORD( Script_Vars[I].Var_Type ) );
                                                   Copy_Byte_To_Buffer( I );
                                                   Polish      := Polish + Token + ';';
                                                END;
                                          END;
                                    END;
            Operator_Type         : BEGIN
                                       Op := OperPrecs[ Oper_Type ] + PC;
                                       WHILE ( ( Stack_Size > 0 ) AND
                                               ( Prec_Stack[Stack_Size] >= OP ) ) DO
                                           BEGIN
                                              Copy_Byte_To_Buffer( ORD( Operator_Type ) );
                                              Copy_Byte_To_Buffer( ORD( Operator_Stack[Stack_Size] ) );
                                              Polish      := Polish +
                                                             OperNames2[Operator_Stack[Stack_Size]] + ';';
                                              DEC( Stack_Size );
                                           END;
                                       INC( Stack_Size );
                                       Operator_Stack[Stack_Size] := Oper_Type;
                                       Prec_Stack    [Stack_Size] := Op;
                                       Paren_Stack   [Stack_Size] := PC;
                                    END;
            ELSE;
         END (* CASE *);

         IF ( NOT Found_Stop ) THEN
            Found_Token    := Get_Next_Token( Token , Token_Type , Oper_Type, I );

      END;

   WHILE( Stack_Size > 0 ) DO
      BEGIN
         Copy_Byte_To_Buffer( ORD( Operator_Type ) );
         Copy_Byte_To_Buffer( ORD( Operator_Stack[Stack_Size] ) );
         Polish      := Polish + OperNames2[ Operator_Stack[Stack_Size] ] + ';';
         DEC( Stack_Size );
      END;

Parsing_Error:
   Copy_Byte_To_Buffer( ORD( StackEnd_Type ) );
   Parse_Expression := ( PC = 0 );

   IF ( PC <> 0 ) THEN
      WRITELN('Parentheses don''t balance.');
{--IMP
   IF Script_Debug_Mode THEN
      BEGIN
         WRITELN( Script_Debug_File , 'PC      = ',PC );
         WRITELN( Script_Debug_File , 'Postfix = ',Polish );
      END;
}
{
   IF Debug_Mode THEN
      Write_Log('Polish = ' + Polish, FALSE, FALSE );
}
   LCode := Script_Buffer_Pos;
   ICode := Save_BPos;

   Blank_Set      := [' ', ','];

END   (* Parse_Expression *);

(*----------------------------------------------------------------------*)
(*    Check_Types --- Check argument and result types in emitted code   *)
(*----------------------------------------------------------------------*)

FUNCTION Check_Types( VAR Result_Type : OperandType ) : BOOLEAN;

VAR
   Stack         : ARRAY[1..MaxStack] OF OperandType;
   End_Of_Stack  : BOOLEAN;
   Stack_Index   : INTEGER;
   Operand_Type  : OperandType;
   Index         : LONGINT;
   Bad_Operands  : BOOLEAN;

VAR
   Operand_Type_Names : ARRAY[OperandType] OF STRING[12];

(*----------------------------------------------------------------------*)
(*                 Push_Type --- Push type onto stack                   *)
(*----------------------------------------------------------------------*)

PROCEDURE Push_Type( Operand : OperandType );

BEGIN (* Push_Type *)

   INC( Stack_Index );
   Stack[Stack_Index] := Operand;

END   (* Push_Type *);

(*----------------------------------------------------------------------*)
(*                 Pop_Type --- Pop type off stack                      *)
(*----------------------------------------------------------------------*)

PROCEDURE Pop_Type( VAR Operand : OperandType );

BEGIN (* Pop_Type *)

   IF ( Stack_Index > 0 ) THEN
      BEGIN
         Operand     := Stack[Stack_Index];
         DEC( Stack_Index );
      END
   ELSE
      Operand := Bad_Operand_Type;

END   (* Pop_Type *);

(*----------------------------------------------------------------------*)
(*    Pseudo_Perform_Operator --- Check arguments and result types      *)
(*----------------------------------------------------------------------*)

PROCEDURE Pseudo_Perform_Operator(     Operator     : OperType;
                                   VAR Bad_Operands : BOOLEAN  );

VAR
   Op1_Type : OperandType;
   Op2_Type : OperandType;
   Op3_Type : OperandType;
   NArgs    : INTEGER;

BEGIN (* Pseudo_Perform_Operator *)

   Bad_Operands := FALSE;

   NArgs        := Number_Args[Operator];

   Op1_Type     := Bad_Operand_Type;
   Op2_Type     := Bad_Operand_Type;
   Op3_Type     := Bad_Operand_Type;

   IF Nargs > 0 THEN
      BEGIN
         Pop_Type( Op1_Type );
         IF Nargs > 1 THEN
            BEGIN
               Pop_Type( Op2_Type );
               IF Nargs > 2 THEN
                  Pop_Type( Op3_Type );
            END;
      END;
{
   IF Debug_Mode THEN
      BEGIN
         Write_Log('     Op1_Type = ' + IToS( ORD(Op1_Type) ), FALSE, FALSE );
         Write_Log('     Op2_Type = ' + IToS( ORD(Op2_Type) ), FALSE, FALSE );
         Write_Log('     Op3_Type = ' + IToS( ORD(Op3_Type) ), FALSE, FALSE );
         Write_Log('     Operator = ' + IToS( ORD(Operator) ), FALSE, FALSE );
      END;
}
   CASE Operator OF

      NoOpSy         : ;

      AndSy,
      OrSy,
      XorSy,
      AddSy,
      SubtractSy,
      MultSy,
      DivideSy       : BEGIN
                          IF ( Op1_Type = Integer_Variable_Type ) AND
                             ( Op2_Type = Integer_Variable_Type ) THEN
                             Push_Type( Integer_Variable_Type )
                          ELSE
                             Bad_Operands := TRUE;
                        END;

      SubStrSy       :  BEGIN
                           IF ( Op1_Type = Integer_Variable_Type ) AND
                              ( Op2_Type = Integer_Variable_Type ) AND
                              ( Op3_Type = String_Variable_Type  ) THEN
                              Push_Type( String_Variable_Type )
                           ELSE
                              Bad_Operands := TRUE;
                        END;

      OrdSy          :  BEGIN
                           IF ( Op1_Type = Integer_Variable_Type ) AND
                              ( Op2_Type = String_Variable_Type  ) THEN
                              Push_Type( Integer_Variable_Type )
                           ELSE
                              Bad_Operands := TRUE;
                        END;

      ConcatSy       :  BEGIN
                           IF ( Op1_Type = String_Variable_Type ) AND
                              ( Op2_Type = String_Variable_Type ) THEN
                              Push_Type( String_Variable_Type )
                           ELSE
                              Bad_Operands := TRUE;
                        END;

      IndexSy        :  BEGIN
                           IF ( Op1_Type = String_Variable_Type ) AND
                              ( Op2_Type = String_Variable_Type ) THEN
                              Push_Type( Integer_Variable_Type )
                           ELSE
                              Bad_Operands := TRUE;
                        END;

      FileExistsSy,
      LengthSy       :  BEGIN
                           IF ( Op1_Type = String_Variable_Type ) THEN
                              Push_Type( Integer_Variable_Type )
                           ELSE
                              Bad_Operands := TRUE;
                        END;

      EqualISy,
      LessEqualISy,
      LessISy,
      GreaterISy,
      GreaterEqualISy,
      NotEqualISy    :  IF ( Op1_Type <> Op2_Type ) THEN
                           Bad_Operands := TRUE
                        ELSE
                           BEGIN
                              IF ( Op1_Type = String_Variable_Type ) THEN
                                 Script_Buffer^[ICode] := Script_Buffer^[ICode] + 6;
                              Push_Type( Integer_Variable_Type );
                           END;

      NotSy          :  IF ( Op1_Type = Integer_Variable_Type ) THEN
                           Push_Type( Integer_Variable_Type )
                        ELSE
                           Bad_Operands := TRUE;

      AttendedSy,
      ConnectedSy,
      DialedSy,
      EnhKeybdSy,
      WaitFoundSy,
      IOResultSy,
      ParamCountSy   : Push_Type( Integer_Variable_Type );

      DateSy,
      TimeSy,
      ParamLineSy    : Push_Type( String_Variable_Type );


      ChrSy,
      DialEntrySy,
      ParamStrSy,
      StringSy       : IF ( Op1_Type = Integer_Variable_Type ) THEN
                          Push_Type( String_Variable_Type )
                       ELSE
                          Bad_Operands := TRUE;

      NumberSy       : IF ( Op1_Type = String_Variable_Type ) THEN
                          Push_Type( Integer_Variable_Type )
                       ELSE
                          Bad_Operands := TRUE;

      EofSy          : IF ( Op1_Type = Integer_Variable_Type ) THEN
                          Push_Type( Integer_Variable_Type )
                       ELSE
                          Bad_Operands := TRUE;

      ReadCtrlSy,
      WriteCtrlSy,
      UpperCaseSy,
      TrimSy,
      LTrimSy,
      KeyStringSy    : IF ( Op1_Type = String_Variable_Type ) THEN
                          Push_Type( String_Variable_Type )
                       ELSE
                          Bad_Operands := TRUE;

      DuplSy         : IF ( Op2_Type = String_Variable_Type ) AND
                          ( Op1_Type = Integer_Variable_Type ) THEN
                          Push_Type( String_Variable_Type )
                       ELSE
                          Bad_Operands := TRUE;
      ELSE;

   END (* CASE *);

END   (* Pseudo_Perform_Operator *);

(*----------------------------------------------------------------------*)
(*    Get_Next_Operand_Type --- Get type of next operand                *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Next_Operand_Type( VAR Operand_Type : OperandType;
                                 VAR Index        : LONGINT );

BEGIN (* Get_Next_Operand_Type *)

   INC( ICode );

   IF ( ICode > LCode ) THEN
      BEGIN
         Operand_Type := StackEnd_Type;
         Index        := 0;
      END
   ELSE
      BEGIN

         Operand_Type := Operands[Script_Buffer^[ICode]];

         CASE Operand_Type OF

            Operator_Type,
            Integer_Variable_Type,
            String_Variable_Type : BEGIN
                                      INC( ICode );
                                      Index := Script_Buffer^[ICode];
                                   END;

            Integer_Constant_Type: BEGIN
                                      INC( ICode );
                                      MOVE( Script_Buffer^[ICode], Index,
                                            SIZEOF( Index ) );
                                      INC( ICode , PRED( SIZEOF( Index ) ) );
                                   END;

            String_Constant_Type:  BEGIN
                                      INC( ICode );
                                      ICode := ICode + Script_Buffer^[ICode];
                                   END;

         END (* CASE *);

      END;

END   (* Get_Next_Operand_Type *);

(*----------------------------------------------------------------------*)

BEGIN (* Check_Types *)

   End_Of_Stack := FALSE;
   Stack_Index  := 0;
   Bad_Operands := FALSE;
   Result_Type  := Bad_Operand_Type;

   DEC( ICode );

   Operand_Type_Names[Bad_Operand_Type]      := 'BAD OPERAND';
   Operand_Type_Names[Integer_Variable_Type] := 'INTEGER';
   Operand_Type_Names[String_Variable_Type]  := 'STRING';

   WHILE ( NOT ( End_Of_Stack OR Bad_Operands ) ) DO
      BEGIN

         Get_Next_Operand_Type( Operand_Type , Index );

         CASE Operand_Type OF

            Integer_Variable_Type,
            Integer_Constant_Type:  Push_Type( Integer_Variable_Type );

            String_Variable_Type,
            String_Constant_Type :  Push_Type( String_Variable_Type );

            Operator_Type        :  Pseudo_Perform_Operator( OperSyms2[Index],
                                                             Bad_Operands );

            StackEnd_Type        :  End_Of_Stack := TRUE;

         END (* CASE *);

      END;

   Check_Types := NOT Bad_Operands;

{
   WRITELN('Before final POP, Stack_Index = ',Stack_Index);
}
   Pop_Type( Result_Type );
{
   IF Debug_Mode THEN
      BEGIN

         Write_Log( 'Check_Type:  Final result type is ', FALSE, FALSE );

         CASE Result_Type OF
            Integer_Variable_Type: Write_Log( ' Integer result variable.', FALSE, FALSE );
            String_Variable_Type : Write_Log( ' String result variable.',
                                              FALSE, FALSE );
            Bad_Operand_Type     : Write_Log( 'Bad operand type.',
                                              FALSE, FALSE );
         END (* CASE *);

      END;
}
END   (* Check_Types *);

