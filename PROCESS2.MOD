(*----------------------------------------------------------------------*)
(*    Parse_Declare_Command --- Parse DECLARE var type script command   *)
(*----------------------------------------------------------------------*)

FUNCTION Parse_Declare_Command : BOOLEAN;

VAR
   Token          : AnyStr;
   Token_Type     : OperandType;
   B              : BOOLEAN;
   Name           : AnyStr;
   Type_It        : OperandType;
   Oper_Type      : OperType;
   I              : LONGINT;

BEGIN (* Parse_Declare_Command *)

   B := Get_Next_Token( Name , Token_Type , Oper_Type , I );

   IF ( NOT B ) THEN
      BEGIN
         Parse_Declare_Command := FALSE;
         Parse_Error( S11 );
         EXIT;
      END;

   B := Get_Next_Token( Token , Token_Type , Oper_Type , I );

   IF ( NOT B ) THEN
      BEGIN
         Parse_Declare_Command := FALSE;
         Parse_Error( S12 );
         EXIT;
      END;

   Token := UpperCase( Token );

   IF Token = 'STRING' THEN
      Type_It := String_Variable_Type
   ELSE IF Token = 'INTEGER' THEN
      Type_It := Integer_Variable_Type
   ELSE
      BEGIN
         Parse_Error( S12 );
         Parse_Declare_Command := FALSE;
         EXIT;
      END;

   INC( Script_Variable_Kount );
   Script_Variable_MaxKount := MAX ( Script_Variable_MaxKount ,
                                     Script_Variable_Kount );
{--IMP
   IF Script_Debug_Mode THEN
      WRITELN( Script_Debug_File , '--- Declare:  Name = ',Name,
                                   ', Type = ', Token, ', Index = ',
                                   Script_Variable_Kount );
}
   WITH Script_Vars[Script_Variable_Kount] DO
      BEGIN
         Var_Name   := UpperCase( Name );
         Var_Type   := Type_It;
      END;

   Parse_Declare_Command := TRUE;
                                   (* Store variable name *)
   Copy_Byte_To_Buffer( 0 );
   Copy_Byte_To_Buffer( LENGTH( Name ) );

   FOR I := 1 TO LENGTH( Name ) DO
      Copy_Byte_To_Buffer( ORD( Name[I] ) );

                                   (* Store variable index *)

   Copy_Integer_To_Buffer( Script_Variable_Kount  , IntegerConsOnly );

                                   (* Store variable type  *)

   Copy_Integer_To_Buffer( ORD( Type_It ) , IntegerConsOnly );

                                   (* Pick up initial value if any *)

   B := Get_Next_Token( Token , Token_Type , Oper_Type , I );

                                   (* Store initial value  *)
   IF ( NOT B ) THEN
      CASE Type_It OF
         String_Variable_Type : Token := '';
         Integer_Variable_Type: Token := ^@^@^@^@;
      END (* CASE *)
   ELSE
      IF ( Type_It = Integer_Variable_Type ) THEN
         IF ( Token_Type <> Integer_Constant_Type ) THEN
            BEGIN
               Parse_Error( S25 );
               Parse_Declare_Command := FALSE;
               EXIT;
            END
         ELSE
            BEGIN
               MOVE( I, Token[1], SIZEOF( LONGINT ) );
               TOKEN[0] := CHR( SIZEOF( LONGINT ) );
            END;

   Copy_String_To_Buffer( Token, String_Constant_Type, LongZero );

END   (* Parse_Declare_Command *);

(*----------------------------------------------------------------------*)
(*    Parse_Set_Command --- Parse SET var=expression script command     *)
(*----------------------------------------------------------------------*)

FUNCTION Parse_Set_Command ( Stop_Token : AnyStr ): BOOLEAN;

VAR
   Token          : AnyStr;
   Token_Type     : OperandType;
   Result_Type    : OperandType;
   SResult_Type   : OperandType;
   B              : BOOLEAN;
   Oper_Type      : OperType;
   I              : LONGINT;

BEGIN (* Parse_Set_Command *)

   Result_Index      := 0;
   Parse_Set_Command := FALSE;

   IF ( Get_Next_Token( Token, Token_Type, Oper_Type, Result_Index ) ) THEN
      IF ( Result_Index > 0 ) THEN
         BEGIN
            Copy_Integer_To_Buffer( Result_Index , IntegerConsOnly );
            Result_Type := Script_Vars[Result_Index].Var_Type;
            B           := Get_Next_Token( Token, Token_Type, Oper_Type , I );
            IF B THEN
               BEGIN
                  B := Parse_Expression( Stop_Token );
                  IF B THEN
                     BEGIN
                        B := Check_Types( SResult_Type );
                        IF B THEN
                           BEGIN
                              B := ( Result_Type = SResult_Type );
                              IF ( NOT B ) THEN
                                 Parse_Error( S8 + COPY( S13, 2, LENGTH( S13 ) - 1 ) );
                           END;
                     END;
               END;
            Parse_Set_Command := B;
         END
      ELSE
         Parse_Error( S8 + COPY( S5, 2, LENGTH( S5 ) - 1 ) )
   ELSE
      Parse_Error( S8 + COPY( S9, 2, LENGTH( S9 ) - 1 ) );

END   (* Parse_Set_Command *);

(*----------------------------------------------------------------------*)
(*    Extract_Script_Command --- Extract command type from script line  *)
(*----------------------------------------------------------------------*)

PROCEDURE Extract_Script_Command( VAR OK_Script_Command : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Extract_Script_Command                               *)
(*                                                                      *)
(*     Purpose:    Extracts command name from script line               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Extract_Script_Command( VAR OK_Script_Command : BOOLEAN );    *)
(*                                                                      *)
(*           OK_Script_Command --- set TRUE if legitimate command       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Found   : BOOLEAN;
   L       : INTEGER;
   I       : INTEGER;
   J       : INTEGER;
   OldOnly : BOOLEAN;

LABEL 1;

BEGIN (* Extract_Script_Command *)

                                   (* Remove initial, trailing blanks *)

   Script_Line := LTRIM( TRIM( Script_Line ) );
   L           := LENGTH( Script_Line );

                                   (* If nothing left, ignore this line *)

   IF ( L < 1 ) THEN
      Current_Script_Command := Null_Command
   ELSE
      BEGIN
                                   (* Append blank to script line *)

         Script_Line := Script_Line + ' ';

                                   (* Pick up command name        *)

         Script_Command_Token := '';
         I                    := 1;

         WHILE ( ( Script_Line[I] <> ' ' ) AND ( Script_Line[I] <> '(' ) ) DO
            BEGIN
               IF ( I <= 8 ) THEN
                  Script_Command_Token := Script_Command_Token +
                                          UpCase( Script_Line[I] );
               INC( I );
            END;
                                   (* Check for missing 'Set' in      *)
                                   (* assignment statement by looking *)
                                   (* for '='.                        *)

         IF ( I < LENGTH( Script_Line ) ) THEN
            BEGIN
               J := I;
               WHILE ( ( J <= LENGTH( Script_Line ) ) AND
                       ( Script_Line[J] = ' ' ) ) DO
                  INC( J );
               IF ( J <= LENGTH( Script_Line ) ) THEN
                  IF ( Script_Line[J] = '=' ) THEN
                     BEGIN
                        Current_Script_Command := SetSy;
                        GOTO 1;
                     END;
            END;
                                   (* Strip command text from front *)
                                   (* of script text line           *)

         DELETE( Script_Line, 1, PRED( I ) );

                                   (* See if first character of command *)
                                   (* is $.  If so, scan only built-in  *)
                                   (* script commands list.             *)

         IF ( Script_Command_Token[1] = '$' ) THEN
            BEGIN
               OldOnly := TRUE;
               DELETE( Script_Command_Token, 1, 1 );
            END
         ELSE
            OldOnly := FALSE;
                                   (* Look up command in user-defined *)
                                   (* commands list first.            *)
         Found := FALSE;

         IF ( NOT OldOnly ) THEN
            BEGIN

               I := 1;

               WHILE( ( I <= Script_New_Command_Count ) AND ( NOT Found ) ) DO
                  BEGIN
                     Found := ( Script_Command_Token = Script_New_Commands[I] );
                     INC( I );
                  END;

               IF Found THEN
                  Current_Script_Command := ExeNewSy;

            END;
                                   (* Look up command in built-in command *)
                                   (* list if not in user-defined list    *)
         IF ( NOT Found ) THEN
            BEGIN

               I := 0;

               REPEAT
                  INC( I );
                  Found := ( Script_Command_Token = Script_File_Command_Names[I] );
               UNTIL  ( Found OR ( I >= Max_Script_File_Commands ) );

               IF ( NOT Found ) THEN
                  Current_Script_Command := Bad_Command
               ELSE
                  Current_Script_Command := Script_File_Commands[I];

            END;

      END;

1:
   Length_Script_Line := LENGTH( Script_Line );
   OK_Script_Command  := ( Current_Script_Command <> Bad_Command );

END   (* Extract_Script_Command *);

(*----------------------------------------------------------------------*)
(*      Emit_Wait_String_Command --- Emit wait for string command       *)
(*----------------------------------------------------------------------*)

PROCEDURE Emit_Wait_String_Command( VAR OK_Script_Command: BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Emit_Wait_String_Command                             *)
(*                                                                      *)
(*     Purpose:    Emit command to wait for specified string            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Emit_Wait_String_Command( VAR OK_Script_Command : BOOLEAN );  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Qnum    : BOOLEAN;
   IntVal  : LONGINT;
   IntType : INTEGER;
   QGotS   : BOOLEAN;

BEGIN (* Emit_Wait_String_Command *)

                                   (* String to wait for *)

   Get_And_Copy_String_To_Buffer( FALSE, TRUE, QGotS );

                                   (* Null reply string  *)
   Copy_Byte_To_Buffer( 0 );
   Copy_Byte_To_Buffer( 0 );
                                   (* Number of seconds to wait *)

   Get_Integer( Qnum, IntVal, IntType, FALSE );

   IF ( NOT Qnum ) THEN
      BEGIN
         IntVal  := 0;
         IntType := IntegerConstant;
      END;

   Copy_Integer_To_Buffer( IntVal , IntType );

                                   (* Failure label *)

   Copy_Integer_To_Buffer( Script_Buffer_Pos + SUCC( SIZEOF( IntVal ) ) ,
                           IntegerConsOnly );

   OK_Script_Command := TRUE;

END   (* Emit_Wait_String_Command *);

(*----------------------------------------------------------------------*)
(*         Emit_WaitList_Command --- Emit WaitList command              *)
(*----------------------------------------------------------------------*)

PROCEDURE Emit_WaitList_Command( VAR OK_Script_Command: BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Emit_WaitList_Command                                *)
(*                                                                      *)
(*     Purpose:    Emit command to wait for specified strings           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Emit_WaitList_Command( VAR OK_Script_Command : BOOLEAN );     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Qnum    : BOOLEAN;
   IntVal  : LONGINT;
   IntType : INTEGER;
   ICountP : INTEGER;
   SCount  : BYTE;
   QGotS   : BOOLEAN;
   MaxP    : INTEGER;
   I       : LONGINT;

BEGIN (* Emit_WaitList_Command *)

                                   (* Get variable index to receive *)
                                   (* waitlist index                *)
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

                                   (* Leave space for # strings *)
   ICountP  := Script_Buffer_Pos;
   Copy_Byte_To_Buffer( 0 );
                                   (* Get strings to wait for; *)
                                   (* may be strings or string *)
                                   (* variables.               *)

   OK_Script_Command := TRUE;
   SCount            := 0;
   QGots             := TRUE;
                                   (* Get legitimate waitstrings *)

   WHILE( QGots AND OK_Script_Command AND ( SCount <= MaxWaitStrings ) ) DO
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
                                   (* Failure label *)

   Copy_Integer_To_Buffer( Script_Buffer_Pos + SUCC( SIZEOF( IntVal ) ) ,
                           IntegerConsOnly );

END   (* Emit_WaitList_Command *);

(*----------------------------------------------------------------------*)
(*         Process_Call_List  ---  Process call/execute argument list   *)
(*----------------------------------------------------------------------*)

PROCEDURE Process_Call_List(     ScrName          : AnyStr;
                                 ScrType          : OperandType;
                                 ScrIndex         : LONGINT;
                                 ProcIndex        : INTEGER;
                             VAR OK_Script_Command: BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Process_Call_List                                    *)
(*                                                                      *)
(*     Purpose:    Processes call/execute argument list                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Process_Call_List( VAR OK_Script_Command : BOOLEAN );         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   NArgs       : BYTE;
   QGotS       : BOOLEAN;
   Index       : LONGINT;
   Save_VCount : INTEGER;
   V_Type      : OperandType;
   V_Init      : AnyStr;
   Oper_Type   : OperType;
   Token       : AnyStr;
   Token_Type  : OperandType;
   Arg_Type    : Proc_Arg_Type_Vector;
   I           : LONGINT;

(*----------------------------------------------------------------------*)

PROCEDURE Create_Dummy_Variable;

BEGIN (* Create_Dummy_Variable *)

   Copy_Byte_To_Buffer( ORD( DeclareSy ) );

   INC( Script_Variable_Kount );
   Script_Variable_MaxKount := MAX( Script_Variable_MaxKount ,
                                    Script_Variable_Kount );

   Copy_String_To_Buffer ( '$TEMP', String_Constant_Type, LongZero );
   Copy_Integer_To_Buffer( Script_Variable_Kount , IntegerConsOnly );
   Copy_Integer_To_Buffer( ORD( V_Type ), IntegerConsOnly );
   Copy_String_To_Buffer ( V_Init, String_Constant_Type, LongZero );

END   (* Create_Dummy_Variable *);

(*----------------------------------------------------------------------*)

BEGIN (* Process_Call_List *)
                                   (* Remember current variable count *)

   Save_VCount := Script_Variable_Kount;

                                   (* Get arguments.  If variable,    *)
                                   (* just record index; else         *)
                                   (* generate DeclareSy for constant *)
                                   (* so dummy variable index used.   *)

   NArgs     := 0;
   QGots     := TRUE;

   WHILE( QGots AND ( NArgs <= MaxScriptArgs ) ) DO
      BEGIN
                                   (* Get next argument. *)

         QGots := Get_Next_Token( Token, Token_Type, Oper_Type, Index );

         IF QGots THEN
            BEGIN
                                   (* Increment argument count. *)

               INC( NArgs );

                                   (* If variable type, just record index.   *)
                                   (* If constant, generate a dummy variable *)
                                   (* initialized to that constant and       *)
                                   (* record its type.                       *)

               CASE Token_Type OF
                  String_Variable_Type,
                  Integer_Variable_Type : BEGIN
                                             Arg_Index[NArgs] := Index;
                                             Arg_Type[NArgs]  := Token_Type;
                                          END;
                  String_Constant_Type  : BEGIN
                                             V_Type := String_Variable_Type;
                                             V_Init := Token;
                                             Create_Dummy_Variable;
                                             Arg_Index[NArgs] := Script_Variable_Kount;
                                             Arg_Type[NArgs]  := V_Type;
                                          END;
                  Integer_Constant_Type : BEGIN
                                             V_Type := Integer_Variable_Type;
                                             V_Init[0] := CHR( SIZEOF( LONGINT ) );
                                             MOVE( Index, V_Init[1], SIZEOF( LONGINT ) );
                                             Create_Dummy_Variable;
                                             Arg_Index[NArgs] := Script_Variable_Kount;
                                             Arg_Type[NArgs]  := V_Type;
                                          END;
                  ELSE
                     Parse_Error( S20 );
                     EXIT;
               END (* CASE *);

            END;

      END;
                                   (* Put command type back into buffer *)

   Copy_Byte_To_Buffer( ORD( Current_Script_Command ) );

                                   (* Put script name or call address  *)
                                   (* into buffer.  Also, for CallSy,  *)
                                   (* check that correct # args given, *)
                                   (* and that types are correct.      *)

   CASE Current_Script_Command OF

      ExecuteSy: Copy_String_To_Buffer ( ScrName, ScrType, ScrIndex );

      CallSy   : BEGIN

                    Copy_Integer_To_Buffer( ScrIndex, IntegerConsOnly );

                    IF ( NArgs <> Script_Procs[ProcIndex].NArgs ) THEN
                       BEGIN
                          Parse_Error( S24 );
                          EXIT;
                       END;

                    FOR I := 1 TO NArgs DO
                       WITH Script_Procs[ProcIndex] DO
                          IF ( Type_Ptr^[I] <> Arg_Type[I] ) THEN
                             BEGIN
                                STR( I , Token );
                                Parse_Error( 'Argument ' + Token + S13 );
                                EXIT;
                             END;

                 END;

   END (* CASE *);

                                   (* Enter count into buffer *)
   Copy_Byte_To_Buffer( NArgs );
                                   (* Copy in variable indices *)
   FOR I := 1 TO NArgs DO
      Copy_Byte_To_Buffer( Arg_Index[I] );

                                   (* Issue ZapVar command *)
   IF ( NArgs > 0 ) THEN
      IF ( Script_Variable_Kount > Save_VCount ) THEN
         BEGIN
            Copy_Byte_To_Buffer( ORD( ZapVarSy ) );
            Copy_Integer_To_Buffer( Save_VCount + 1       , IntegerConstant );
            Copy_Integer_To_Buffer( Script_Variable_Kount , IntegerConstant );
         END;
                                   (* Restore "real" variable count *)

   Script_Variable_Kount := Save_VCount;

   OK_Script_Command     := TRUE;

END   (* Process_Call_List *);

(*----------------------------------------------------------------------*)
(*         Emit_Execute_Command --- Emit Execute command                *)
(*----------------------------------------------------------------------*)

PROCEDURE Emit_Execute_Command( VAR OK_Script_Command: BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Emit_Execute_Command                                 *)
(*                                                                      *)
(*     Purpose:    Emit command to execute another script               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Emit_Execute_Command( VAR OK_Script_Command : BOOLEAN );      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   NArgs       : BYTE;
   QGotS       : BOOLEAN;
   ScrName     : AnyStr;
   ScrType     : OperandType;
   ScrIndex    : LONGINT;
   Index       : INTEGER;
   Save_VCount : INTEGER;
   V_Type      : OperandType;
   V_Init      : AnyStr;
   Oper_Type   : OperType;
   Token       : AnyStr;
   Token_Type  : OperandType;

BEGIN (* Emit_Execute_Command *)

                                   (* Back up over ExecuteSy   *)

   DEC( Script_Buffer_Pos );
   OK_Script_Command := FALSE;

                                   (* Get script name          *)

   IF ( NOT Get_Next_Token( ScrName, ScrType, Oper_Type, ScrIndex ) ) THEN
      BEGIN
         Parse_Error( S10 + 'script name.' );
         EXIT;
      END;
                                   (* Make sure script name is *)
                                   (* legit.                   *)

   IF ( NOT ( ScrType IN [String_Variable_Type, String_Constant_Type] ) ) THEN
      BEGIN
         Parse_Error( S19 );
         EXIT;
      END;

   Process_Call_List( ScrName, ScrType, ScrIndex, 0, OK_Script_Command );

END   (* Emit_Execute_Command *);

(*----------------------------------------------------------------------*)
(*           Emit_If_Command --- Emit IF conditional command            *)
(*----------------------------------------------------------------------*)

PROCEDURE Emit_If_Command(     False_Label       : LONGINT;
                           VAR OK_Script_Command : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Emit_If_Command                                      *)
(*                                                                      *)
(*     Purpose:    Emit IF conditional command                          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Emit_If_Command(     False_Label       : INTEGER;             *)
(*                         VAR OK_Script_Command : BOOLEAN );           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Qnum         : BOOLEAN;
   IntVal       : LONGINT;
   Token        : AnyStr;
   Token_Type   : OperandType;
   Oper_Type    : OperType;
   Index        : LONGINT;
   I            : LONGINT;
   L            : INTEGER;
   Save_IS      : INTEGER;
   Save_BPos1   : INTEGER;
   Save_BPos2   : INTEGER;
   NextP        : LONGINT;
   NextP_Bytes  : ARRAY[1..4] OF BYTE ABSOLUTE NextP;
   SResult_Type : OperandType;
   Stop_Token   : STRING[8];
   QGotS        : BOOLEAN;

(*----------------------------------------------------------------------*)

PROCEDURE Short_If( IfType : PibTerm_Command_Type );

BEGIN (* Short_If *)

   Copy_Byte_To_Buffer   ( ORD( IfType ) );
   Copy_Integer_To_Buffer( I           , IntegerConsOnly );
   Copy_Integer_To_Buffer( NextP       , IntegerConsOnly );
   Copy_Integer_To_Buffer( False_Label , IntegerConsOnly );

END   (* Short_If *);

(*----------------------------------------------------------------------*)

PROCEDURE Long_If( IfType : PibTerm_Command_Type );

BEGIN (* Long_If *)

   Save_IS := IS;

   IF ( NOT Get_Next_Token( Token, Token_Type, Oper_Type, Index ) ) THEN
      BEGIN
         Parse_Error( S10 + 'boolean condition.' );
         EXIT;
      END;

   IF ( Token_Type = String_Constant_Type ) THEN
      L := SUCC( LENGTH( Token ) )
   ELSE
      L := 0;

   Copy_Byte_To_Buffer   ( ORD( IfType ) );
   Copy_Integer_To_Buffer( I             , IntegerConsOnly );
   Copy_Integer_To_Buffer( NextP + L + 1 , IntegerConsOnly );
   Copy_Integer_To_Buffer( False_Label   , IntegerConsOnly );

   IS := Save_IS;
   Get_And_Copy_String_To_Buffer( FALSE , TRUE, QGotS );

END   (* Long_If *);

(*----------------------------------------------------------------------*)

BEGIN (* Emit_If_Command *)
                                   (* Back up 1 byte in script buffer   *)
                                   (* We overwrite existing instruction *)
                                   (* with the proper IF guy here.      *)

   DEC( Script_Buffer_Pos );

                                   (* Pick up type of condition *)

   IF ( NOT Get_Next_Token( Token, Token_Type, Oper_Type, Index ) ) THEN
      BEGIN
         Parse_Error( S10 + 'boolean condition.' );
         EXIT;
      END;

   L    := LENGTH( Token );
   Token := UpperCase( Token );
                                   (* '(' -- complex condition *)

   IF ( Token_Type = Left_Paren_Type ) THEN
         BEGIN

            Save_BPos1        := Script_Buffer_Pos;

            Copy_Byte_To_Buffer   ( 0 );
            Copy_Integer_To_Buffer( 0 , IntegerConsOnly );
            Copy_Integer_To_Buffer( 0 , IntegerConsOnly );
            Copy_Integer_To_Buffer( 0 , IntegerConsOnly );

            DEC( IS );

            CASE Current_Script_Command OF

               ForSy,
               WhileSy  : Stop_Token := 'DO';
               ElseIfSy,
               CaseSy,
               IfOpSy   : Stop_Token := 'THEN';
               ELSE       Stop_Token := '';

            END (* CASE *);

            OK_Script_Command := Parse_Expression( Stop_Token );

            IF OK_Script_Command THEN
               BEGIN
                  OK_Script_Command := Check_Types( SResult_Type );
                  IF OK_Script_Command THEN
                     OK_Script_Command := ( SResult_Type = Integer_Variable_Type );
                  IF ( NOT OK_Script_Command ) THEN
                     Parse_Error( S14 );
               END;

            IF OK_Script_Command THEN
               BEGIN

                  Save_BPos2        := Script_Buffer_Pos;
                  NextP             := SUCC( Script_Buffer_Pos );
                  Script_Buffer_Pos := Save_BPos1;
                  Copy_Byte_To_Buffer( ORD( IfOpSy ) );
                  Copy_Integer_To_Buffer( 0 , IntegerConsOnly );
                  Copy_Integer_To_Buffer( NextP , IntegerConsOnly );
                  Copy_Integer_To_Buffer( False_Label , IntegerConsOnly );
                  Script_Buffer_Pos := Save_BPos2;

               END;

            EXIT;

         END
      ELSE IF ( Token_Type = Bad_Operand_Type ) THEN
         BEGIN  (* No condition -- bad      *)
            Token := 'BAD';
            L    := 3;
         END;
                                   (* Look for NOT *)
   IF ( Token = 'NOT' ) THEN
      BEGIN

         I := 0;

         IF ( NOT Get_Next_Token( Token, Token_Type, Oper_Type, Index ) ) THEN
            BEGIN
               Parse_Error( S10 + 'boolean condition.' );
               EXIT;
            END;

         L    := LENGTH( Token );
         Token := UpperCase( Token );

      END
   ELSE
      I := 1;
                                   (* True branch -- next statement *)

   NextP := Script_Buffer_Pos + ( 3 * SIZEOF( LONGINT ) ) + 2;

                                   (* Analyze condition type *)
   IF ( L >= 3 ) THEN
      IF      COPY( Token, 1, 3 ) = 'CON' THEN
         Short_If( IfConSy )
      ELSE IF COPY( Token, 1, 3 ) = 'WAI' THEN
         Short_If( IfFoundSy )
      ELSE IF COPY( Token, 1, 3 ) = 'LOC' THEN
         Long_If ( IfLocStrSy )
      ELSE IF COPY( Token, 1, 3 ) = 'REM' THEN
         Long_If ( IfRemStrSy )
      ELSE IF COPY( Token, 1, 3 ) = 'DIA' THEN
         Short_If( IfDialSy )
      ELSE IF COPY( Token, 1, 3 ) = 'IOE' THEN
         Short_If( IfOKSy )
      ELSE IF COPY( Token, 1, 3 ) = 'EXI' THEN
         Long_If ( IfExistsSy )
      ELSE
         OK_Script_Command := FALSE
   ELSE
      OK_Script_Command := FALSE;

END   (* Emit_If_Command *);
