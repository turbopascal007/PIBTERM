(*----------------------------------------------------------------------*)
(*            Dispose_Proc_Stuff --- Dispose of proc stuff              *)
(*----------------------------------------------------------------------*)

PROCEDURE Dispose_Proc_Stuff( Start, Last : INTEGER );

VAR
   I: INTEGER;

BEGIN (* Dispose_Proc_Stuff *)

   FOR I := Start TO Last DO
      IF ( Script_Procs[I].NArgs > 0 ) THEN
         DISPOSE( Script_Procs[I].Type_Ptr );

END   (* Dispose_Proc_Stuff *);

(*----------------------------------------------------------------------*)
(*            Label_Fixup --- Debug code for label fixups               *)
(*----------------------------------------------------------------------*)

PROCEDURE Label_Fixup( IPos : INTEGER );

BEGIN (* Label_Fixup *)
{--IMP
   WRITELN( Script_Debug_File ,
            '      Fixup at ', IPos:4,
            ' to be ',NextP_Bytes[1]:4,
            NextP_Bytes[2]:4, ' = ',NextP:8 );
}
END   (* Label_Fixup *);

(*----------------------------------------------------------------------*)
(*           Emit_Proc --- Emit procedure call command                  *)
(*----------------------------------------------------------------------*)

PROCEDURE Emit_Proc;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Emit_Proc                                            *)
(*                                                                      *)
(*     Purpose:    Emits procedure header code                          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Emit_Proc;                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I          : INTEGER;
   J          : INTEGER;
   QGotS      : BOOLEAN;
   Token      : AnyStr;
   PToken     : AnyStr;
   Token_Type : OperandType;
   Oper_Type  : OperType;
   Index      : LONGINT;
   NPArgs     : INTEGER;
   PArgs      : Proc_Arg_Type_Vector;
   PName      : ARRAY[1..MaxScriptArgs] OF STRING[12];
   ProcName   : AnyStr;

BEGIN (* Emit_Proc *)
                                   (* Assume command is bad.   *)
   OK_Script_Command := FALSE;
                                   (* Back up over ProcedureSy *)

   DEC( Script_Buffer_Pos );

                                   (* Increment count of defined procs *)

   INC( Script_Proc_Count );

                                   (* Increment procedure nesting level *)

   INC( Script_Proc_Level );

                                   (* since it must be called to be *)
                                   (* executed.                     *)

   Copy_Byte_To_Buffer( ORD( GoToSy ) );

   Script_Proc_Start := SUCC( Script_Buffer_Pos );

   Copy_Integer_To_Buffer( 0 , IntegerConsOnly );

                                   (* Record information on this script level *)

   WITH Script_Proc_Stack[Script_Proc_Level] DO
      BEGIN
         Old_VCount := Script_Variable_Kount;
         Old_PCount := Script_Proc_Count;
         GOTO_Pos   := Script_Proc_Start;
      END;
                                   (* Pick up procedure name *)

   QGotS := Get_Next_Token( ProcName, Token_Type, Oper_Type, Index );

                                   (* Pick up procedure arguments *)
   NPArgs := 0;
   QGots  := TRUE;

   WHILE( QGots AND ( NPArgs <= MaxScriptArgs ) ) DO
      BEGIN
                                   (* Get next argument. *)

         QGots := Get_Next_Token( Token, Token_Type, Oper_Type, Index );

         IF QGots THEN
            BEGIN
                                   (* Increment argument count. *)

               INC( NPArgs );

                                   (* Must be a name type *)

               IF ( NOT ( Token_Type IN [String_Variable_Type,
                                        Integer_Variable_Type] ) ) THEN
                  BEGIN
                     Parse_Error( Token + ' <-- ' + S12 );
                     EXIT;
                  END;

               PName[NPArgs] := Token;

            END;
                                   (* Get argument type *)
         IF QGotS THEN
            BEGIN

               PToken := Token;

               QGots  := Get_Next_Token( Token, Token_Type, Oper_Type, Index );

               Token  := UpperCase( Token );

               IF ( Token = 'STRING' ) THEN
                  PArgs[NPArgs] := String_Variable_Type
               ELSE IF ( Token = 'INTEGER' ) THEN
                  PArgs[NPArgs] := Integer_Variable_Type
               ELSE
                  BEGIN
                     Parse_Error( S10 + 'type after ' + PToken );
                     EXIT;
                  END;

            END;

      END;
                                   (* Generate declares for arguments *)
   FOR I := 1 TO NPArgs DO
      BEGIN
         IF ( PArgs[I] = String_Variable_Type ) THEN
            Token := 'STRING '
         ELSE
            Token := 'INTEGER ';
         Copy_Byte_To_Buffer( ORD( PImportSy ) );
         Script_Line        := PName[I] + ' ' + Token;
         Length_Script_Line := LENGTH( Script_Line );
         IS                 := 0;
         OK_Script_Command  := Parse_Declare_Command;
      END;
                                   (* Record information on this script *)
   OK_Script_Command := TRUE;

   WITH Script_Procs[Script_Proc_Count] DO
     BEGIN
        Name       := UpperCase( ProcName );
        Buffer_Pos := Script_Proc_Start + SIZEOF( LONGINT );
        NArgs      := NPargs;
        IF ( NPArgs = 0 ) THEN
           Type_Ptr   := NIL
        ELSE
           BEGIN
              NEW( Type_Ptr );
              IF ( Type_Ptr <> NIL ) THEN
                 FOR I := 1 TO NPArgs DO
                    Type_Ptr^[I] := PArgs[I]
              ELSE
                 OK_Script_Command := FALSE;
           END;
     END;

END   (* Emit_Proc *);

(*----------------------------------------------------------------------*)
(*           Emit_Return --- Emit procedure return command              *)
(*----------------------------------------------------------------------*)

PROCEDURE Emit_Return( EndType : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Emit_Return                                          *)
(*                                                                      *)
(*     Purpose:    Emits return from procedure code                     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Emit_Return( EndType : AnyStr );                              *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Emit_Return *)
                                   (* Back up over command *)

   DEC( Script_Buffer_Pos );

                                   (* See if we have an open procedure    *)

   IF ( Script_Proc_Level <= 0 ) THEN
      BEGIN
         Parse_Error( S15 + EndType );
         OK_Script_Command := FALSE;
         EXIT;
      END;
                                   (* Issue ZapVars for local variables *)

   WITH Script_Proc_Stack[Script_Proc_Level] DO
      BEGIN
         IF ( Script_Variable_Kount > Old_VCount ) THEN
            BEGIN
               Copy_Byte_To_Buffer( ORD( ZapVarSy ) );
               Copy_Integer_To_Buffer( Old_VCount + 1        , IntegerConstant );
               Copy_Integer_To_Buffer( Script_Variable_Kount , IntegerConstant );
            END;
      END;
                                   (* Emit ReturnSy so run-time goes back *)

   Copy_Byte_To_Buffer( ORD( ReturnSy ) );

END   (* Emit_Return *);

(*----------------------------------------------------------------------*)
(*           Emit_EndProc --- Emit end of procedure code                *)
(*----------------------------------------------------------------------*)

PROCEDURE Emit_EndProc;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Emit_EndProc                                         *)
(*                                                                      *)
(*     Purpose:    Emits end of procedure code                          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Emit_EndProc;                                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I          : INTEGER;
   J          : INTEGER;
   QGotS      : BOOLEAN;
   Token      : AnyStr;
   Token_Type : OperandType;
   Oper_Type  : OperType;
   Index      : INTEGER;

BEGIN (* Emit_EndProc *)
                                   (* Issue ReturnSy *)
   Emit_Return( 'ENDPROC' );
                                   (* Issue ZapVars for any local variables *)
                                   (* declared in procedure.  Also, return  *)
                                   (* variable count to count prior to the  *)
                                   (* procedure declaration.                *)

   WITH Script_Proc_Stack[Script_Proc_Level] DO
      BEGIN
         IF ( Script_Variable_Kount > Old_VCount ) THEN
            Script_Variable_Kount := Old_VCount;
         IF ( Script_Proc_Count > Old_PCount ) THEN
            BEGIN
               Dispose_Proc_Stuff( Old_PCount + 1 , Script_Proc_Count );
               Script_Proc_Count := Old_PCount;
            END;
         Script_Proc_Start := GOTO_Pos;
      END;

   DEC( Script_Proc_Level );

                                   (* Now we know where procedure ends, *)
                                   (* do a fixup                        *)

   NextP := SUCC( Script_Buffer_Pos );

   MOVE( NextP, Script_Buffer^[ Script_Proc_Start ], SIZEOF( LONGINT ) );

{--IMP
   IF Script_Debug_Mode THEN
      Label_Fixup( Script_Proc_Start );
}
END   (* Emit_EndProc *);

(*----------------------------------------------------------------------*)
(*           Emit_Call --- Emit procedure call command                  *)
(*----------------------------------------------------------------------*)

PROCEDURE Emit_Call;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Emit_Call                                            *)
(*                                                                      *)
(*     Purpose:    Emits procedure call command                         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Emit_Call;                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I          : LONGINT;
   J          : INTEGER;
   QGotS      : BOOLEAN;
   Token      : AnyStr;
   Token_Type : OperandType;
   Oper_Type  : OperType;
   Index      : LONGINT;

BEGIN (* Emit_Call *)
                                   (* Back up over CallSy *)

   DEC( Script_Buffer_Pos );

                                   (* Get name of procedure to call *)

   QGotS := Get_Next_Token( Token, Token_Type, Oper_Type, Index );

                                   (* Look up procedure name *)
   J     := 0;

   Token := UpperCase( Token );

   FOR I := Script_Proc_Count DOWNTO 1 DO
      IF ( Token = Script_Procs[I].Name ) THEN
         J := I;
                                   (* Error if not found *)
   IF ( J = 0 ) THEN
      BEGIN
         OK_Script_Command := FALSE;
         Parse_Error( S21 + Token + S5 );
         EXIT;
      END
   ELSE
      I := Script_Procs[J].Buffer_Pos;

   Process_Call_List( '', Token_Type, I, J, OK_Script_Command );

END   (* Emit_Call *);

(*----------------------------------------------------------------------*)
(*   Parse_Script_Command --- Parse and convert script to internal code *)
(*----------------------------------------------------------------------*)

PROCEDURE Parse_Script_Command( VAR OK_Script_Command : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Parse_Script_Command                                 *)
(*                                                                      *)
(*     Purpose:    Parse and convert script line to internal code.      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Parse_Script_Command( VAR OK_Script_Command : BOOLEAN );      *)
(*                                                                      *)
(*           OK_Script_Command --- set TRUE if legitimate command       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Qnum       : BOOLEAN;
   QGotS      : BOOLEAN;
   IntVal     : LONGINT;
   ByteVal    : BYTE;
   L          : INTEGER;
   I          : LONGINT;
   J          : INTEGER;
   Index      : LONGINT;
   SvPos      : INTEGER;
   Token      : AnyStr;
   Token_Type : OperandType;
   Oper_Type  : OperType;
   IntType    : INTEGER;

(* STRUCTURED *) CONST
   Handle_Mess : STRING[21] = 'Handle not specified';

(*----------------------------------------------------------------------*)
(*     Get_File_Reference --- Get file reference in I/O statement       *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_File_Reference( Empty_Allowed : BOOLEAN );

VAR
   File_Ref : LONGINT;
   Ref_Type : INTEGER;

BEGIN (* Get_File_Reference *)

   SvPos    := IS;
   File_Ref := 0;
   Ref_Type := IntegerConstant;

   QGotS := Get_Next_Token( Token, Token_Type, Oper_Type, Index );

   IF ( NOT QGots ) THEN
      IF Empty_Allowed THEN
         IS := SvPos
      ELSE
         Parse_Error( Handle_Mess )
   ELSE
      CASE Token_Type OF

         Integer_Variable_Type : BEGIN
                                    File_Ref := Index;
                                    Ref_Type := IntegerVariable;
                                 END;

         Integer_Constant_Type: BEGIN
                                   File_Ref := Index;
                                   Ref_Type := IntegerConstant;
                                END;

         ELSE                   IS       := SvPos;

      END (* CASE *);

   Copy_Integer_To_Buffer( File_Ref , Ref_Type );

END   (* Get_File_Reference *);

(*----------------------------------------------------------------------*)
(*            Emit_EndIf --- Emit code for ENDIF statement              *)
(*----------------------------------------------------------------------*)

PROCEDURE Emit_EndIf;

VAR
   J : INTEGER;

BEGIN (* Emit_EndIf *)

   IF ( Script_If_Level > 0 ) THEN
      BEGIN

         J := Script_If_Stack[ Script_If_Level ];
         DEC( Script_If_Level );

                                   (* Fixup GoTo before ELSE or   *)
                                   (* FALSE branch in original IF *)
                                   (* if no else.                 *)

         NextP := Script_Buffer_Pos;

         IF ( J > 0 ) THEN
            BEGIN

               MOVE( NextP, Script_Buffer^[ J ], SIZEOF( LONGINT ) );
{--IMP
               IF Script_Debug_Mode THEN
                  Label_Fixup( J );
}
            END
         ELSE
            BEGIN

               J := -J;

               MOVE( NextP, Script_Buffer^[ J + False_Offset ], SIZEOF( LONGINT ) );
{--IMP
               IF Script_Debug_Mode THEN
                  Label_Fixup( J + False_Offset );
}
            END;

                                   (* Erase EndIf from buffer *)

         DEC( Script_Buffer_Pos );

      END
   ELSE
      OK_Script_Command := FALSE;

END   (* Emit_EndIf *);

(*----------------------------------------------------------------------*)
(*            Emit_Else --- Emit code for ELSE statement                *)
(*----------------------------------------------------------------------*)

PROCEDURE Emit_Else;

VAR
   J: INTEGER;

BEGIN (* Emit_Else *)

   IF ( Script_If_Level > 0 ) THEN
      BEGIN

                                   (* Get address of IF statement *)
                                   (* Remember offset is negative *)

         J := -Script_If_Stack[ Script_If_Level ];

                                   (* Back up over Else *)

         DEC( Script_Buffer_Pos );

                                   (* around FALSE code.          *)

         Copy_Byte_To_Buffer( ORD( GoToSy ) );

                                   (* Address of GoTo not defined   *)
                                   (* since we don't know it yet -- *)
                                   (* leave it zero, and stuff the  *)
                                   (* address of cell to receive    *)
                                   (* fixup address later on IF     *)
                                   (* stack.                        *)

         Script_If_Stack[ Script_If_Level ] := SUCC( Script_Buffer_Pos );

         Copy_Integer_To_Buffer( 0 , IntegerConsOnly );

                                   (* Fixup FALSE branch address in IF *)

         NextP := SUCC( Script_Buffer_Pos );

         MOVE( NextP, Script_Buffer^[ J + False_Offset ], SIZEOF( LONGINT ) );

{--IMP
         IF Script_Debug_Mode THEN
            Label_Fixup( J + False_Offset );
}
      END
   ELSE
      OK_Script_Command := FALSE;

END   (* Emit_Else *);

(*----------------------------------------------------------------------*)
(*            Emit_An_If --- Setup code for IF statement                *)
(*----------------------------------------------------------------------*)

PROCEDURE Emit_An_If;

BEGIN (* Emit_An_If *)
                                   (* Increment IF level *)

   INC( Script_If_Level );
   Script_If_Stack[Script_If_Level]     := -Script_Buffer_Pos;
   Script_ElseIf_Stack[Script_If_Level] := 0;

                                   (* Emit a conditional *)

   Emit_If_Command( 0 , OK_Script_Command );

END   (* Emit_An_If *);

(*----------------------------------------------------------------------*)
(*            Emit_A_While --- Emit code for WHILE statement            *)
(*----------------------------------------------------------------------*)

PROCEDURE Emit_A_While;

BEGIN (* Emit_A_While *)
{--IMP
   IF Script_Debug_Mode THEN
      WRITELN( Script_Debug_File , 'Entered Emit_A_While' );
}
                                   (* Increment While level *)

   INC( Script_While_Level );
   Script_While_Stack[Script_While_Level] := Script_Buffer_Pos;

                                   (* Emit conditional command *)

   Emit_If_Command( 0 , OK_Script_Command );

END   (* Emit_A_While *);

(*----------------------------------------------------------------------*)
(*       Emit_An_EndWhile --- Emit code for ENDWHILE statement          *)
(*----------------------------------------------------------------------*)

PROCEDURE Emit_An_EndWhile;

VAR
   J: INTEGER;

BEGIN (* Emit_An_EndWhile *)

   IF ( Script_While_Level > 0 ) THEN
      BEGIN

         J := Script_While_Stack[ Script_While_Level ];
         DEC( Script_While_Level );

         Script_Buffer^[Script_Buffer_Pos] := ORD( GoToSy );
         Copy_Integer_To_Buffer( J , IntegerConsOnly );

         NextP := SUCC( Script_Buffer_Pos );

         MOVE( NextP, Script_Buffer^[ J + False_Offset ], SIZEOF( LONGINT ) );

{--IMP
         IF Script_Debug_Mode THEN
            Label_Fixup( J + False_Offset );
}
      END
   ELSE
      Parse_Error( S15 + 'ENDWHILE');

END   (* Emit_An_EndWhile *);

(*----------------------------------------------------------------------*)
(*           Emit_A_For --- Emit code for FOR statement                 *)
(*----------------------------------------------------------------------*)

PROCEDURE Emit_A_For;

VAR
   Ascending : BOOLEAN;
   Dir_Chars : STRING[2];
   L         : INTEGER;

BEGIN (* Emit_A_For *)
                                   (* Generate initial SET *)
   DEC( Script_Buffer_Pos );

   Copy_Byte_To_Buffer( ORD( SetSy ) );

   IS := 0;

   Ascending := ( POS( 'DOWNTO' , UpperCase( Script_Line ) ) = 0 );

   CASE Ascending OF
      TRUE:  BEGIN
                OK_Script_Command := Parse_Set_Command( 'TO' );
                Dir_Chars         := '<=';
             END;
      FALSE: BEGIN
                OK_Script_Command := Parse_Set_Command( 'DOWNTO' );
                Dir_Chars         := '>=';
             END;
   END (* CASE *);
{
IF Script_Debug_Mode THEN
   BEGIN
      WRITELN( Script_Debug_File, 'IS = ',IS,' after generating SET for FOR');
      WRITELN( Script_Debug_File, 'Script_Line = <', Script_Line, '>');
   END;
}
                                   (* If OK, generate WHILE *)
   IF OK_Script_Command THEN
      BEGIN
                                   (* Get termination condition.       *)
                                   (* We need to strip the trailing DO *)
                                   (* if it appears.                   *)

         Script_Line := Trim( COPY( Script_Line, SUCC( IS ),
                                      Length_Script_Line - IS ) );
{
         IF Script_Debug_Mode THEN
            WRITELN( Script_Debug_File, 'Script_Line = <', Script_Line, '>');
}
         L           := LENGTH( Script_Line );

         IF ( UpperCase( COPY( Script_Line, L - 1, 2 ) ) = 'DO' ) THEN
            Script_Line := COPY( Script_Line, 1, L - 2 );
{
         IF Script_Debug_Mode THEN
               WRITELN( Script_Debug_File, 'Script_Line = <', Script_Line, '>');
}
         Script_Line := '( ' +
                        Script_Vars[Result_Index].Var_Name +
                        Dir_Chars +
                        Script_Line +
                        ' ) DO ';
{--IMP
         IF Script_Debug_Mode THEN
            BEGIN
               WRITELN( Script_Debug_File ,
                        '      For generates <',
                        Script_Line,'>' );
            END;
}
         Length_Script_Line := LENGTH( Script_Line );
         IS                 := 0;

         INC( Script_Buffer_Pos );

         Emit_A_While;

         IF OK_Script_Command THEN
            BEGIN
               INC( Script_For_Level );
               IF ( NOT Ascending ) THEN
                  Result_Index := (-Result_Index);
               Script_For_Stack[Script_For_Level] := Result_Index;
            END;

      END;

END   (* Emit_A_For *);

(*----------------------------------------------------------------------*)
(*           Emit_An_EndFor --- Emit code for ENDFOR statement          *)
(*----------------------------------------------------------------------*)

PROCEDURE Emit_An_EndFor;

VAR
   I         : INTEGER;
   Dir_Chars : STRING[4];

BEGIN (* Emit_An_EndFor *)
                                   (* Generate SET Statement *)

   IF ( Script_For_Level > 0 ) THEN
      BEGIN

         I := Script_For_Stack[Script_For_Level];

         IF ( I > 0 ) THEN
            Dir_Chars := '+ 1 '
         ELSE
            BEGIN
               Dir_Chars := '- 1 ';
               I         := -I;
            END;

         DEC( Script_For_Level );

         Script_Line         := Script_Vars[I].Var_Name +
                                '=' +
                                Script_Vars[I].Var_Name +
                                Dir_Chars;

         DEC( Script_Buffer_Pos );

         Copy_Byte_To_Buffer( ORD( SetSy ) );

         IS                  := 0;
         Length_Script_Line  := LENGTH( Script_Line );
         OK_Script_Command   := Parse_Set_Command( '' );
{
         IF Script_Debug_Mode THEN
            BEGIN
               WRITELN( Script_Debug_File ,
                        '      EndFor generates <',
                        Script_Line,'>' );
            END;
}
                                   (* Generate ENDWHILE command *)

         INC( Script_Buffer_Pos );

         Emit_An_EndWhile;

      END
   ELSE
      Parse_Error( S15 + 'ENDFOR' );

END   (* Emit_An_EndFor *);

(*----------------------------------------------------------------------*)
(*               Emit_Menu --- Emit code for MENU statement             *)
(*----------------------------------------------------------------------*)

PROCEDURE Emit_Menu;

VAR
   Qnum    : BOOLEAN;
   IntVal  : LONGINT;
   IntType : INTEGER;
   ICountP : INTEGER;
   SCount  : BYTE;
   QGotS   : BOOLEAN;
   MaxP    : INTEGER;
   I       : LONGINT;

BEGIN (* Emit_Menu *)
                                   (* Get variable index to receive *)
                                   (* menu index                    *)
   OK_Script_Command := FALSE;

   Get_Integer( QNum, I, IntType, TRUE );

   IF ( NOT Qnum ) THEN
      BEGIN
         IF ( IntType = IntegerMissing ) THEN
            Parse_Error( S8 + COPY( S9, 2, LENGTH( S9 ) - 1 ) );
         EXIT;
      END;
                                   (* Copy result index to buffer *)

   Copy_Integer_To_Buffer( I , IntType );

                                   (* Get column position *)

   Get_Integer( QNum, I, IntType, FALSE );
   Copy_Integer_To_Buffer( I , IntType );

                                   (* Get row position *)

   Get_Integer( QNum, I, IntType, FALSE );
   Copy_Integer_To_Buffer( I , IntType );

                                   (* Get default item *)

   Get_Integer( QNum, I, IntType, FALSE );
   Copy_Integer_To_Buffer( I , IntType );

                                   (* Get title        *)

   Get_And_Copy_String_To_Buffer( FALSE , FALSE, QGotS );

                                   (* Leave space for # menu items *)
   ICountP  := Script_Buffer_Pos;
   Copy_Byte_To_Buffer( 0 );
                                   (* Get menu item strings;   *)
                                   (* may be strings or string *)
                                   (* variables.               *)
   OK_Script_Command := TRUE;
   SCount            := 0;
   QGots             := TRUE;
                                   (* Get legitimate waitstrings *)

   WHILE( QGots AND OK_Script_Command AND ( SCount <= Max_Menu_Items ) ) DO
      BEGIN
         Get_And_Copy_String_To_Buffer( FALSE , FALSE, QGotS );
         IF QGots THEN
            INC( SCount );
      END;
                                   (* Enter count into buffer *)

   IntVal            := Script_Buffer_Pos;
   Script_Buffer_Pos := ICountP;

   Copy_Byte_To_Buffer( SCount );

   Script_Buffer_Pos := IntVal;

END   (* Emit_Menu *);

(*----------------------------------------------------------------------*)

BEGIN (* Parse_Script_Command *)
                                   (* Assume command is OK to start   *)
   OK_Script_Command := TRUE;
                                   (* Insert command type into buffer *)

   Copy_Byte_To_Buffer( ORD( Current_Script_Command ) );

                                   (* Pick up and insert command-dependent *)
                                   (* information into script buffer.      *)
   IS := 0;

   CASE Current_Script_Command OF

       AddCommandSy: IF Get_Next_Token( Token, Token_Type, Oper_Type, Index ) THEN
                        IF ( Script_New_Command_Count < MaxNewCommands ) THEN
                           BEGIN
                              INC( Script_New_Command_Count );
                              Script_New_Commands[Script_New_Command_Count] :=
                                 UpperCase( Trim( Token ) );
                              DEC( Script_Buffer_Pos );
                           END
                        ELSE
                              Parse_Error('No room to store new command definition.')
                     ELSE
                        Parse_Error( S10 + 'new command name to define.');

       ImportSy    : IF ( Script_Proc_Count > 0 ) THEN
                        IF ( Script_Proc_Level = 0 ) THEN
                           BEGIN
                              OK_Script_Command := FALSE;
                              Parse_Error( 'IMPORT' + S22 );
                           END
                        ELSE
                           BEGIN
                              OK_Script_Command := FALSE;
                              Parse_Error( S23 );
                           END
                     ELSE
                        BEGIN
                           OK_Script_Command := Parse_Declare_Command;
                           IF OK_Script_Command THEN
                              INC( Import_Count );
                        END;

       DeclareSy   : IF ( ( Script_Proc_Count > 0 ) AND
                          ( Script_Proc_Level = 0 ) ) THEN
                        BEGIN
                           OK_Script_Command := FALSE;
                           Parse_Error( 'DECLARE' + S22 );
                        END
                     ELSE
                        OK_Script_Command := Parse_Declare_Command;

       SuspendSy   ,
       DelaySy     ,
       WaitCountSy ,
       WaitQuietSy : BEGIN
                        Get_Integer( Qnum, IntVal, IntType, FALSE );
                        IF ( NOT Qnum ) THEN
                           BEGIN
                              IntVal  := 1;
                              IntType := IntegerConstant;
                           END;
                        Copy_Integer_To_Buffer( IntVal , IntType );
                     END;

       CaptureSy   ,
       CopyFileSy  ,
       FreeSpaceSy ,
       GetDirSy    ,
       GetParamSy  ,
       KeyDefSy    ,
       ReceiveSy   ,
       SendSy      ,
       SetParamSy  ,
       SetVarSy    ,
       WhenSy      : BEGIN
                        Get_And_Copy_String_To_Buffer( FALSE , TRUE, QGotS );
                        IF OK_Script_Command THEN
                           Get_And_Copy_String_To_Buffer( FALSE , TRUE, QGotS );
                     END;

       DialSy      : BEGIN

                        Get_And_Copy_String_To_Buffer( FALSE , TRUE, QGotS );

                        IF OK_Script_Command THEN

                                   (* See if NOSCRIPT appears *)

                           QGotS := Get_Next_Token( Token, Token_Type, Oper_Type, Index );

                        IF ( UpperCase( Token ) = 'NOSCRIPT' ) THEN
                           I := 1
                        ELSE
                           I := 0;
                                   (* Insert noscript flag in buffer *)

                        Copy_Integer_To_Buffer( I , IntegerConsOnly );


                     END;

       ChDirSy     ,
       DosSy       ,
       EditFileSy  ,
       EraseFileSy ,
       KeySy       ,
       KeySendSy   ,
       MessageSy   ,
       PrintFileSy ,
       ReDialSy    ,
       STextSy     ,
       TextSy      ,
       TranslateSy ,
       ViewFileSy  ,
       WaitSy      ,
       WhenDropSy  ,
       WriteLogSy  : Get_And_Copy_String_To_Buffer( FALSE , TRUE, QGotS );

       InputSy     : BEGIN
                                   (* Copy prompt string to script buffer *)

                        Get_And_Copy_String_To_Buffer( FALSE , TRUE, QGotS );

                                   (* See if variable name follows.  If so, *)
                                   (* that will be receiving variable.      *)
                                   (* If not, just leave in standard input  *)
                                   (* buffer.                               *)

                        IF ( OK_Script_Command ) THEN
                           Get_And_Copy_String_To_Buffer( TRUE , TRUE, QGotS );


                     END;

       RInputSy    : BEGIN
                                   (* Copy prompt string to script buffer *)

                        Get_And_Copy_String_To_Buffer( FALSE , TRUE, QGotS );

                                   (* Assume echo mode *)
                        I := 1;
                                   (* See if NOECHO appears *)

                        QGotS := Get_Next_Token( Token, Token_Type, Oper_Type, Index );

                        IF ( UpperCase( Token ) = 'NOECHO' ) THEN
                           I := 0;

                                   (* Insert echo/noecho flag in buffer *)

                        Copy_Integer_To_Buffer( I , IntegerConsOnly );

                                   (* See if var name follows.          *)

                        IF OK_Script_Command THEN
                           Get_And_Copy_String_To_Buffer( TRUE , TRUE, QGotS );


                     END;

       IfOpSy      : Emit_An_If;

       ElseSy      : Emit_Else;

       EndIfSy     : Emit_Endif;

       GoToXYSy    : BEGIN
                        Get_Integer( QNum, I, IntType, FALSE );
                        IF ( NOT Qnum ) THEN
                           BEGIN
                              IntVal  := 1;
                              IntType := IntegerConstant;
                           END;
                        Copy_Integer_To_Buffer( I , IntType );
                        Get_Integer( QNum, I, IntType, FALSE );
                        IF ( NOT Qnum ) THEN
                           BEGIN
                              IntVal  := 1;
                              IntType := IntegerConstant;
                           END;
                        Copy_Integer_To_Buffer( I , IntType );
                     END;

       WaitStrSy   : Emit_Wait_String_Command( OK_Script_Command );

       SetSy       : BEGIN
                        IS                := 0;
                        OK_Script_Command := Parse_Set_Command( '' );
                     END;

       RepeatSy    : BEGIN
                                   (* Increment repeat level *)

                        INC( Script_Repeat_Level );

                                   (* Remember where repeat starts. *)

                        Script_Repeat_Stack[Script_Repeat_Level] :=
                           Script_Buffer_Pos;

                                   (* Erase repeat command *)

                        DEC( Script_Buffer_Pos );


                     END;

       UntilSy     : BEGIN
                        IF ( Script_Repeat_Level > 0 ) THEN
                           BEGIN

                                   (* Pop REPEAT address off stack *)

                              J := Script_Repeat_Stack[ Script_Repeat_Level ];
                              DEC( Script_Repeat_Level );

                                   (* Emit end of loop test *)

                              Emit_If_Command( J , OK_Script_Command );

                          END
                        ELSE
                           OK_Script_Command := FALSE;


                     END;

       WhileSy     : Emit_A_While;

       EndWhileSy  : Emit_An_EndWhile;

       ParamSy     : BEGIN

                        QGotS := Get_Next_Token( Token, Token_Type, Oper_Type, Index );

                        Copy_Byte_To_Buffer( ORD( Token[1] ) );
                        Copy_Byte_To_Buffer( ORD( Token[2] ) );

                        QGotS := Get_Next_Token( Token, Token_Type, Oper_Type, Index );

                        IF ( Token <> '=' ) THEN
                           Parse_Error( S10 + '=' )
                        ELSE
                           BEGIN
                              Token := COPY( Script_Line, IS + 1,
                                               Length_Script_Line - IS );
                              L     := LENGTH( Token );
                              Copy_Byte_To_Buffer( L );
                              FOR I := 1 TO L DO
                                 Copy_Byte_To_Buffer( ORD( Token[I] ) );
                           END;


                     END;

       ProcedureSy : Emit_Proc;

       EndProcSy   : Emit_EndProc;

       CallSy      : Emit_Call;

       ScriptSy    : BEGIN

                        QGotS := Get_Next_Token( Token, Token_Type, Oper_Type, Index );

                        Copy_Byte_To_Buffer( ORD( Token[1] ) );

                        Get_And_Copy_String_To_Buffer( FALSE , TRUE, QGotS );

                     END;

       CloseSy     : BEGIN

                        Get_Integer( QNum, I, IntType, FALSE );

                        IF ( NOT Qnum ) THEN
                           Parse_Error( Handle_Mess );

                        Copy_Integer_To_Buffer( I , IntType );

                     END;

       ReadLnSy    : BEGIN

                        Get_File_Reference( FALSE );

                        Get_And_Copy_String_To_Buffer( TRUE , TRUE, QGotS );

                     END;

       ReadSy      : BEGIN

                        Get_File_Reference( FALSE );

                        Get_And_Copy_String_To_Buffer( TRUE , TRUE, QGotS );

                        Get_Integer( QNum, I, IntType, FALSE );

                        IF ( NOT Qnum ) THEN
                           I := 1;

                        Copy_Integer_To_Buffer( I , IntType );

                     END;

       WriteSy,
       WriteLnSy   : BEGIN

                        Get_File_Reference( TRUE );

                        Get_And_Copy_String_To_Buffer( FALSE , TRUE, QGotS );

                     END;

       OpenSy      : BEGIN

                        Get_Integer( QNum, I, IntType, FALSE );

                        IF ( NOT Qnum ) THEN
                           Parse_Error( Handle_Mess );

                        Copy_Integer_To_Buffer( I , IntType );

                        Get_And_Copy_String_To_Buffer( FALSE , TRUE, QGotS );

                        IF ( NOT Get_Next_Token( Token, Token_Type, Oper_Type, Index ) ) THEN
                           Parse_Error( S10 + '"input", "output", or "append"' )
                        ELSE
                           BEGIN
                              CASE UpCase(Token[1]) OF
                                 'I':  I := 0;
                                 'A':  I := 2;
                              ELSE
                                 I := 1;
                              END (* CASE *);
                              Copy_Integer_To_Buffer( I , IntType );
                           END;

                     END;

       DoCaseSy    : BEGIN
                                   (* Back up over DoCaseSy *)

                        DEC( Script_Buffer_Pos );

                                   (* Increment count of defined cases *)

                        INC( Script_Case_Level );

                                   (* Pick up case variable name *)

                        IF ( NOT Get_Next_Token( Token, Token_Type, Oper_Type, Index ) ) THEN
                           Parse_Error( S10 + 'case variable.' )
                        ELSE
                           BEGIN
                              IF ( Token_Type IN [String_Variable_Type,
                                                  Integer_Variable_Type] ) THEN
                                 BEGIN
                                    Script_Case_Var_Stack[Script_Case_Level] := Index;
                                    Script_Case_Cnt_Stack[Script_Case_Level] := 0;
                                 END
                              ELSE
                                 Parse_Error( S18 + Token + S3 );
                           END;


                     END;

       EndDoCaseSy : BEGIN

                        IF ( Script_Case_Level > 0 ) THEN
                           BEGIN
                              FOR J := 1 TO Script_Case_Cnt_Stack[Script_Case_Level] DO
                                 BEGIN
                                    Emit_EndIf;
                                    INC( Script_Buffer_Pos );
                                 END;
                              DEC( Script_Case_Level );
                              DEC( Script_Buffer_Pos );
                           END
                        ELSE
                           Parse_Error( S15 + 'ENDDOCASE' );

                     END;

       CaseSy      : BEGIN
                                   (* See if this is ELSE -- in which *)
                                   (* case, generate nothing.         *)

                        IF ( NOT Get_Next_Token( Token, Token_Type, Oper_Type, Index ) ) THEN
                           Parse_Error( S10 + 'case expression.' )

                        ELSE IF ( UpperCase( Token ) <> 'ELSE') THEN
                           BEGIN

                                   (* Increment count of cases found  *)

                              INC( Script_Case_Cnt_Stack[Script_Case_Level] );

                                   (* Increment IF level *)

                              INC( Script_If_Level );
                              Script_If_Stack[Script_If_Level] :=
                                 -Script_Buffer_Pos;

                                   (* Generate IF Statement *)

                              I := Script_Case_Var_Stack[Script_Case_Level];

                              Script_Line := '(' +
                                             Script_Vars[I].Var_Name +
                                             '=' + Script_Line + ') THEN ';

                              IS                 := 0;
                              Length_Script_Line := LENGTH( Script_Line );
{--IMP
                              IF Script_Debug_Mode THEN
                                 BEGIN
                                    WRITELN( Script_Debug_File ,
                                             '      Case generates <',
                                             Script_Line,'>' );
                                 END;
}
                                   (* Emit a conditional *)

                              Emit_If_Command( 0 , OK_Script_Command );

                           END
                        ELSE
                           Script_Case_Var_Stack[Script_Case_Level] := 0;

                     END;

       EndCaseSy   : IF ( Script_Case_Var_Stack[Script_Case_Level] <> 0 ) THEN
                        Emit_Else
                     ELSE
                        DEC( Script_Buffer_Pos );

       ForSy       : Emit_A_For;

       EndForSy    : Emit_An_EndFor;

       WhereXYSy   : BEGIN

                        Get_Integer( QNum, I, IntType, TRUE );

                        Copy_Integer_To_Buffer( I , IntType );

                        Get_Integer( QNum, I, IntType, TRUE );

                        Copy_Integer_To_Buffer( I , IntType );


                     END;

       ExecuteSy   : Emit_Execute_Command ( OK_Script_Command );

       WaitListSy  : Emit_WaitList_Command( OK_Script_Command );

       ExeNewSy    : BEGIN

                        Copy_String_To_Buffer( Script_Command_Token, String_Constant_Type, 0 );

                        Copy_String_To_Buffer( Script_Line, String_Constant_Type, 0 );

                     END;

       WaitTimeSy  : BEGIN

                        Get_Integer( QNum, I, IntType, FALSE );

                        IF ( NOT QNum ) THEN
                           BEGIN
                              I       := 30;
                              IntType := IntegerConstant;
                           END;

                        Copy_Integer_To_Buffer( I , IntType );

                     END;

       CommDrainSy : BEGIN

                        Get_Integer( QNum, I, IntType, FALSE );

                        IF ( NOT QNum ) THEN
                           BEGIN
                              I       := 5;
                              IntType := IntegerConstant;
                           END;

                        Copy_Integer_To_Buffer( I , IntType );

                     END;

       CommFlushSy : BEGIN

                        IF ( NOT Get_Next_Token( Token, Token_Type, Oper_Type, Index ) ) THEN
                           I := 3
                        ELSE
                           BEGIN
                              CASE UpCase(Token[1]) OF
                                 'I':  I := 1;
                                 'O':  I := 2;
                                 'B':  I := 3;
                                 ELSE  I := 1;
                              END (* CASE *);
                           END;

                        Copy_Integer_To_Buffer( I , IntType );

                     END;

       MenuSy      : Emit_Menu;

       ReturnSy    : Emit_Return( 'RETURN' );

       GetVarSy    : BEGIN
                        Get_And_Copy_String_To_Buffer( FALSE , TRUE, QGotS );
                        IF OK_Script_Command THEN
                           Get_And_Copy_String_To_Buffer( TRUE , TRUE, QGotS );
                        IF OK_Script_Command THEN
                           Get_And_Copy_String_To_Buffer( TRUE , TRUE, QGotS );
                     END;

       DirFirstSy,
       DirNextSy   : BEGIN
                        IF ( Current_Script_Command = DirFirstSy ) THEN
                           BEGIN
                              Get_And_Copy_String_To_Buffer( FALSE , TRUE, QGotS );
                              IF OK_Script_Command THEN
                                 Get_And_Copy_String_To_Buffer( FALSE , TRUE, QGotS );
                           END;
                        IF OK_Script_Command THEN
                           Get_And_Copy_String_To_Buffer( TRUE , TRUE, QGotS );
                        IF OK_Script_Command THEN
                           Get_And_Copy_String_To_Buffer( TRUE , TRUE, QGotS );
                        IF OK_Script_Command THEN
                           Get_And_Copy_String_To_Buffer( TRUE , TRUE, QGotS );
                        IF OK_Script_Command THEN
                           Get_And_Copy_String_To_Buffer( TRUE , TRUE, QGotS );
                        IF OK_Script_Command THEN
                           Get_And_Copy_String_To_Buffer( TRUE , TRUE, QGotS );
                     END;

       ELSE;

   END (* CASE *);

END   (* Parse_Script_Command *);

