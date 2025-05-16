(*----------------------------------------------------------------------*)
(*           Execute_Command --- Execute PibTerm  command               *)
(*----------------------------------------------------------------------*)

PROCEDURE Execute_Command( VAR Command    : Pibterm_Command_Type;
                           VAR Done       : BOOLEAN;
                               Use_Script : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Execute_Command                                      *)
(*                                                                      *)
(*     Purpose:    Execute PibTerm Commands                             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Execute_Command( VAR Command    : Pibterm_Command_Type;       *)
(*                         VAR Done       : BOOLEAN;                    *)
(*                             Use_Script : BOOLEAN );                  *)
(*                                                                      *)
(*           Command    --- Command to execute                          *)
(*           Done       --- set TRUE if termination command found       *)
(*           Use_Script --- TRUE if this is a script command execution  *)
(*                                                                      *)
(*      Calls:   Async_Send_String                                      *)
(*               PibDialer                                              *)
(*               Async_Send_Break                                       *)
(*               Async_Carrier_Detect                                   *)
(*               Display_Commands                                       *)
(*               Delay                                                  *)
(*               GetAreaCode                                            *)
(*               PibUpLoad                                              *)
(*               PibDownLoad                                            *)
(*               Save_Screen                                            *)
(*               Restore_Screen                                         *)
(*               Draw_Menu_Frame                                        *)
(*               Fast_Change_Params                                     *)
(*               PibFileManipulation                                    *)
(*               Get_Capture_File                                       *)
(*               Toggle_Option                                          *)
(*               HangUpPhone                                            *)
(*               Send_Function_Key                                      *)
(*               Set_Input_Keys                                         *)
(*               Set_Translate_Table                                    *)
(*               Do_Screen_Dump                                         *)
(*               DosJump                                                *)
(*               Handle_Function_Key                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Flag       : BOOLEAN;
   I          : INTEGER;
   J          : INTEGER;
   LongI      : LONGINT;
   LongJ      : LONGINT;
   T_Type     : Terminal_Type;
   TimeW      : STRING[8];
   TimeN      : STRING[8];
   TimeO      : STRING[8];
   Local_Save : Saved_Screen_Ptr;
   ESC_Found  : BOOLEAN;
   Trans_Type : Transfer_Type;
   Ch         : CHAR;
   Rem_Ch     : CHAR;
   XPos       : INTEGER;
   GotChar    : BOOLEAN;
   S          : AnyStr;
   Echo       : BOOLEAN;
   Test_Cond  : BOOLEAN;
   File_Done  : BOOLEAN;
   Do_Editing : BOOLEAN;
   Do_Viewing : BOOLEAN;
   F          : FILE;
   Alter_Status : BOOLEAN;
   Drive_Word   : WORD;
   Free_Size    : LONGINT;
   Search_Attr  : BYTE;
   Ansi_Term    : BOOLEAN;
   Com_Line_Scr : BOOLEAN;

VAR
   Save_Do_Status_Line : BOOLEAN;

(* STRUCTURED *) CONST
   Oper_Type_Vector : ARRAY[0..MaxOperandTypes] OF OperandType =
                      ( Bad_Operand_Type, Operator_Type, Integer_Variable_Type,
                        Real_Variable_Type, String_Variable_Type,
                        Char_Variable_Type,
                        Integer_Constant_Type, Real_Constant_Type,
                        String_Constant_Type,
                        Char_Constant_Type,
                        StackEnd_Type, Left_Paren_Type, Right_Paren_Type,
                        Comma_Type );

(*----------------------------------------------------------------------*)
(*           Remote_Input --- get remote input in response to prompt    *)
(*----------------------------------------------------------------------*)

PROCEDURE Remote_Input;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Remote_Input                                         *)
(*                                                                      *)
(*     Purpose:    Gets remote input (from host system) in response to  *)
(*                 prompt.                                              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Remote_Input;                                                 *)
(*                                                                      *)
(*           Global string  -Script_Remote_Reply- get the resultant     *)
(*           input.                                                     *)
(*                                                                      *)
(*      Calls:   Async_Send                                             *)
(*               Send_Function_Key                                      *)
(*               Async_Receive                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Rem_Ch     : CHAR;
   XPos       : INTEGER;
   GotChar    : BOOLEAN;
   S          : AnyStr;
   Echo       : BOOLEAN;
   Ch         : CHAR;

BEGIN (* Remote_Input *)
                                   (* Send prompt to remote system *)

   IF LENGTH( Script_String ) > 0 THEN
      Send_Function_Key( Read_Ctrls( Script_String ) );

   Ch                     := CHR( 0 );
   Script_Remote_Reply[0] := CHR( 0 );
   XPos                   := WhereX;
   Echo                   := ( Script_Integer_1 > 0 );

                                   (* Get response string        *)
   REPEAT

      GotChar := FALSE;
                                   (* Check for keyboard input   *)
      IF PibTerm_KeyPressed THEN
         BEGIN
            Read_Kbd( Ch );
            GotChar := TRUE;
         END;
                                   (* Check for remote input *)

      IF Async_Receive( Rem_Ch ) THEN
         BEGIN
            Ch      := Rem_Ch;
            GotChar := TRUE;
         END;
                                   (* Process received character *)
      IF GotChar THEN
         IF Ch <> CHR( CR ) THEN
            IF Ch = ^H THEN
               BEGIN  (* Backspace *)
                  IF WhereX > Xpos THEN
                     BEGIN
                        Async_Send( Ch  );
                        WRITE( Ch );
                        Async_Send( ' ' );
                        WRITE( ' ' );
                        Async_Send( Ch  );
                        WRITE( Ch );
                        IF ( LENGTH( Script_Remote_Reply ) > 1 ) THEN
                           Script_Remote_Reply := COPY( Script_Remote_Reply,
                                                  1,
                                                  LENGTH( Script_Remote_Reply ) - 1 )
                        ELSE
                           Script_Remote_Reply[0] := CHR( 0 );
                     END;
               END   (* Backspace *)
            ELSE
               BEGIN
                  Script_Remote_Reply := Script_Remote_Reply + Ch;
                  IF Echo THEN
                     BEGIN
                        Async_Send( Ch );
                        WRITE( Ch );
                     END
                  ELSE
                     BEGIN
                        Async_Send( '.' );
                        WRITE( '.' );
                     END
               END;

   UNTIL ( Ch = CHR( CR ) ) OR ( NOT Async_Carrier_Detect );

   Script_Remote_Reply_Ok := FALSE;

                                   (* Copy to variable if necessary *)

   IF ( Script_Integer_2 > 2 ) THEN
      Script_Variables^[Script_Integer_2].Var_Value^ :=
         Script_Remote_Reply;

END   (* Remote_Input *);

(*----------------------------------------------------------------------*)
(*           Execute_Stack --- Execute postfix command stack            *)
(*----------------------------------------------------------------------*)

PROCEDURE Execute_Stack( Result_Index : INTEGER );

VAR
   Stack         : ARRAY[1..MaxExecStack] OF Stack_Entry_Ptr;
   End_Of_Stack  : BOOLEAN;
   Stack_Index   : INTEGER;
   Operand_Type  : INTEGER;
   Index         : INTEGER;
   LIndex        : LONGINT;
   Var_Ptr       : Stack_Entry_Ptr;
   IVal          : LONGINT;
   Int1          : LONGINT;
   Str1          : AnyStr;
   Int1_Bytes    : ARRAY[1..4] OF BYTE ABSOLUTE Int1;

(*----------------------------------------------------------------------*)
(*     Move_Variable_To_Stack --- Place variable on evaluation stack    *)
(*----------------------------------------------------------------------*)

PROCEDURE Move_Variable_To_Stack( Index : INTEGER );

VAR
   IType : OperandType;

BEGIN (* Move_Variable_To_Stack *)

   INC( Stack_Index );

   NEW( Stack[Stack_Index] );
                                   (* Defines a script record *)

   IType                      := Script_Variables^[Index].Var_Type;
   Stack[Stack_Index]^.TypVal := IType;

   CASE IType OF
      Integer_Variable_Type: MOVE( Script_Variables^[Index].Var_Value^[1],
                                   Stack[Stack_Index]^.IntVal,
                                   SIZEOF( LongInt ) );
      String_Variable_Type : Stack[Stack_Index]^.StrVal := Script_Variables^[Index].Var_Value^;
   END (* CASE *);

END   (* Move_Variable_To_Stack *);

(*----------------------------------------------------------------------*)
(* Move_Integer_Constant_To_Stack --- Place integer on evaluation stack *)
(*----------------------------------------------------------------------*)

PROCEDURE Move_Integer_Constant_To_Stack( IntVal : LONGINT );

BEGIN (* Move_Integer_Constant_To_Stack *)

   INC( Stack_Index );

   NEW( Stack[Stack_Index] );

   Stack[Stack_Index]^.TypVal := Integer_Variable_Type;
   Stack[Stack_Index]^.IntVal := IntVal;

END   (* Move_Integer_Constant_To_Stack *);

(*----------------------------------------------------------------------*)
(* Move_String_Constant_To_Stack --- Place string on evaluation stack   *)
(*----------------------------------------------------------------------*)

PROCEDURE Move_String_Constant_To_Stack( VAR Index : INTEGER );

VAR
   L : INTEGER;

BEGIN (* Move_String_Constant_To_Stack *)

   INC( Stack_Index );

   NEW( Stack[Stack_Index] );

   L := Script_Buffer^[Index];

   MOVE( Script_Buffer^[Index+1], Stack[Stack_Index]^.StrVal[1], L );

   Stack[Stack_Index]^.StrVal[0] := CHR( L );
   Stack[Stack_Index]^.TypVal    := String_Variable_Type;

   Index := Index + L;
{
IF Debug_Mode THEN
   Debug_Write('===> Moving <' + Stack[Stack_Index]^.StrVal + '> onto stack.');
}
END   (* Move_String_Constant_To_Stack *);

(*----------------------------------------------------------------------*)
(*       Pop_Stack_Integer --- Remove integer from evaluation stack     *)
(*----------------------------------------------------------------------*)

PROCEDURE Pop_Stack_Integer( VAR IntVal : LONGINT );

BEGIN (* Pop_Stack_Integer *)

   IntVal := Stack[Stack_Index]^.IntVal;

   DISPOSE( Stack[Stack_Index] );

   DEC( Stack_Index );

END   (* Pop_Stack_Integer *);

(*----------------------------------------------------------------------*)
(*       Pop_Stack_String --- Remove string from evaluation stack       *)
(*----------------------------------------------------------------------*)

PROCEDURE Pop_Stack_String( VAR StrVal : AnyStr );

BEGIN (* Pop_Stack_String *)

   StrVal := Stack[Stack_Index]^.StrVal;

   DISPOSE( Stack[Stack_Index] );

   DEC( Stack_Index );

END   (* Pop_Stack_String *);

(*----------------------------------------------------------------------*)
(*       Perform_Operator --- Execute operator using evaluation stack   *)
(*----------------------------------------------------------------------*)

PROCEDURE Perform_Operator( Operator : OperType );

VAR
   Int1: LONGINT;
   Int2: LONGINT;
   Str1: AnyStr;
   Str2: AnyStr;
   Str3: AnyStr;
   IRes: LONGINT;
   SRes: AnyStr;
   I   : INTEGER;
   I1  : INTEGER;

   Int1_Bytes : ARRAY[1..4] OF BYTE ABSOLUTE Int1;

TYPE
   ArgType = ( One_String, One_Integer, Two_Integers, Two_Strings,
               String_And_One_Integer, String_And_Two_Integers,
               Special_Args, No_Args );

(* STRUCTURED *) CONST
   ArgTypeVector : ARRAY[OperType] OF ArgType =
                   ( Special_Args, Two_Integers, Two_Integers, Two_Integers,
                     Two_Integers, Two_Integers, Two_Integers, Two_Integers,
                     Two_Integers, Two_Integers, Two_Integers,
                     Two_Strings,  Two_Strings,  Two_Strings,
                     Two_Strings,  Two_Strings,  Two_Strings,
                     Two_Integers,
                     One_Integer,  Two_Integers, Two_Integers,
                     String_And_Two_Integers, Two_Strings, One_String,
                     Two_Strings, No_Args, No_Args, One_Integer,
                     One_String, No_Args, One_String , One_Integer ,
                     No_Args, String_And_One_Integer, One_String, One_String,
                     No_Args, One_Integer, No_Args, No_Args, One_String,
                     No_Args, No_Args, One_Integer, String_And_One_Integer,
                     One_Integer, One_String, One_String, No_Args,
                     One_String );

   ResTypeVector : ARRAY[OperType] OF OperandType =
                   ( Bad_Operand_Type,
                     Integer_Variable_Type, Integer_Variable_Type,
                     Integer_Variable_Type, Integer_Variable_Type,
                     Integer_Variable_Type, Integer_Variable_Type,
                     Integer_Variable_Type, Integer_Variable_Type,
                     Integer_Variable_Type, Integer_Variable_Type,
                     Integer_Variable_Type, Integer_Variable_Type,
                     Integer_Variable_Type, Integer_Variable_Type,
                     Integer_Variable_Type, Integer_Variable_Type,
                     Integer_Variable_Type, Integer_Variable_Type,
                     Integer_Variable_Type, Integer_Variable_Type,
                     String_Variable_Type,  Integer_Variable_Type,
                     Integer_Variable_Type, String_Variable_Type,
                     Integer_Variable_Type, Integer_Variable_Type,
                     String_Variable_Type,  Integer_Variable_Type,
                     Integer_Variable_Type, Integer_Variable_Type,
                     Integer_Variable_Type, Integer_Variable_Type,
                     String_Variable_Type,  String_Variable_Type,
                     String_Variable_Type,  Integer_Variable_Type,
                     String_Variable_Type,  String_Variable_Type,
                     Integer_Variable_Type, String_Variable_Type,
                     String_Variable_Type,  String_Variable_Type,
                     String_Variable_Type,  Integer_Variable_Type,
                     String_Variable_Type,  String_Variable_Type,
                     String_Variable_Type,  Integer_Variable_Type,
                     String_Variable_Type );

(*----------------------------------------------------------------------*)
(*    Push_Stack_Integer --- Push integer value onto evaluation stack   *)
(*----------------------------------------------------------------------*)

PROCEDURE Push_Stack_Integer( IntVal : LONGINT );

BEGIN (* Push_Stack_Integer *)

   INC( Stack_Index );

   NEW( Stack[Stack_Index] );

   Stack[Stack_Index]^.TypVal := Integer_Variable_Type;

   Stack[Stack_Index]^.IntVal := IntVal;

END   (* Push_Stack_Integer *);

(*----------------------------------------------------------------------*)
(*    Push_Stack_String --- Push string value onto evaluation stack     *)
(*----------------------------------------------------------------------*)

PROCEDURE Push_Stack_String( StrVal : AnyStr );

BEGIN (* Push_Stack_String *)

   INC( Stack_Index );

   NEW( Stack[Stack_Index] );

   Stack[Stack_Index]^.TypVal := String_Variable_Type;

   Stack[Stack_Index]^.StrVal := StrVal;
{
IF Debug_Mode THEN
   Debug_Write('===> Pushing <' + StrVal + '> onto stack.');
}
END   (* Push_Stack_String *);

(*----------------------------------------------------------------------*)

BEGIN (* Perform_Operator *)

   CASE ArgTypeVector[Operator] OF
      One_String              :  Pop_Stack_String ( Str1 );
      One_Integer             :  Pop_Stack_Integer( Int1 );
      Two_Integers            :  BEGIN
                                    Pop_Stack_Integer( Int2 );
                                    Pop_Stack_Integer( Int1 );
                                 END;
      Two_Strings             :  BEGIN
                                    Pop_Stack_String ( Str2 );
                                    Pop_Stack_String ( Str1 );
                                 END;
      String_And_One_Integer  :  BEGIN
                                    Pop_Stack_Integer( Int1 );
                                    Pop_Stack_String ( Str1 );
                                 END;
      String_And_Two_Integers :  BEGIN
                                    Pop_Stack_Integer( Int2 );
                                    Pop_Stack_Integer( Int1 );
                                    Pop_Stack_String ( Str1 );
                                 END;
      ELSE;
   END;

   CASE Operator OF

       NoOpSy  : ;
       AddSy:           IRes := Int1 + Int2;
       SubtractSy:      IRes := Int1 - Int2;
       MultSy:          IRes := Int1 * Int2;
       DivideSy:        IF ( Int2 <> 0 ) THEN
                           IRes := Int1 DIV Int2
                        ELSE
                           IRes := 0;
       ConcatSy:        BEGIN
                           IRes := ORD( Str1[0] ) + ORD( Str2[0] );
                           IF ( IRes <= 255 ) THEN
                              SRes := Str1 + Str2
                           ELSE
                              SRes := Str1 + COPY( Str2, 1, 255 - ORD( Str1[0] ) );
                        END;
       SubStrSy:        SRes := COPY( Str1, Int1, Int2 );
       IndexSy:         IRes := POS( Str1, Str2 );
       LengthSy:        IRes := LENGTH( Str1 );
       EqualISy:        IRes := ORD( Int1 = Int2 );
       LessEqualISy:    IRes := ORD( Int1 <= Int2 );
       LessISy:         IRes := ORD( Int1 < Int2 );
       GreaterISy:      IRes := ORD( Int1 > Int2 );
       GreaterEqualISy: IRes := ORD( Int1 >= Int2 );
       NotEqualISy    : IRes := ORD( Int1 <> Int2 );
       EqualSSy:        IRes := ORD( CompareStr( Str1 , Str2 ) =  Equal    );
       LessEqualSSy:    IRes := ORD( CompareStr( Str1 , Str2 ) <> Greater  );
       LessSSy:         IRes := ORD( CompareStr( Str1 , Str2 ) =  Less     );
       GreaterSSy:      IRes := ORD( CompareStr( Str1 , Str2 ) =  Greater  );
       GreaterEqualSSy: IRes := ORD( CompareStr( Str1 , Str2 ) <> Less     );
       NotEqualSSy    : IRes := ORD( CompareStr( Str1 , Str2 ) <> Equal    );
       AndSy          : IRes := Int1 AND Int2;
       NotSy          : IRes := NOT Int1;
       OrSy           : IRes := Int1 OR Int2;
       XorSy          : IRes := Int1 XOR Int2;
       OrdSy          : IF ( ( Int1 > 0 ) AND ( Int1 <= LENGTH( Str1 ) ) ) THEN
                           IRes := ORD( Str1[ Int1 ] )
                        ELSE
                           IRes := 0;
       ChrSy          : IF ( ( Int1 >= 0 ) AND ( Int1 <= 255 ) ) THEN
                           SRes := CHR( Int1 )
                        ELSE
                           SRes := '';
       WaitFoundSy    : IRes := ORD( Script_Wait_Found    );
       ConnectedSy    : IRes := ORD( Async_Carrier_Detect );
       AttendedSy     : IRes := ORD( Attended_Mode );
       DialedSy       : IF Script_Dialed THEN
                           IRes := Phone_Entry_Number
                        ELSE
                           IRes := 0;
       FileExistsSy   : BEGIN
                              (*!I-*)
                           ASSIGN( F , Str1 );
                           RESET ( F );
                              (*!I+*)
                           IRes := ORD( Int24Result = 0 );
                              (*!I-*)
                           CLOSE ( F );
                              (*!I+*)
                           Int1 := Int24Result;
                        END;
       EofSy          : BEGIN
                           IF Script_File_Used[Int1] THEN
                              IRes := ORD( Script_File_List[Int1]^.EOF_Seen )
                           ELSE
                              IRes := 1;
                        END;
       StringSy       : STR( Int1 , SRes );
       NumberSy       : BEGIN
                           VAL( TRIM( LTRIM( Str1 ) ), IRes, I1 );
                           IF ( I1 <> 0 ) THEN
                              IRes := 0;
                        END;
       IOResultSy     : IRes := Script_IO_Error;
       DuplSy         : SRes := Dupl( Str1[1], Int1 );
       UpperCaseSy    : SRes := UpperCase( Str1 );
       TrimSy         : SRes := Trim( Str1 );
       LTrimSy        : SRes := LTrim( Str1 );
       ParamCountSy   : IRes := ParamCount;
       ParamStrSy     : SRes := ParamStr( Int1 );
       ParamLineSy    : MOVE( MEM[PrefixSeg:$80], SRes, MEM[PrefixSeg:$80] );
       DateSy         : SRes := DialDateString;
       TimeSy         : SRes := TimeString( TimeOfDay , Military_Time );
       DialEntrySy    : IF ( ( Int1 > 0 ) AND ( Int1 <= Dialing_Dir_Size ) ) THEN
                           BEGIN
                              SRes[0] := CHR( Dialing_Dir_Entry_Length );
                              MOVE( Dialing_Directory^[Int1], SRes[1],
                                    Dialing_Dir_Entry_Length );
                           END
                        ELSE
                           SRes := '';
       ReadCtrlSy     : SRes := Read_Ctrls ( Str1 );
       WriteCtrlSy    : SRes := Write_Ctrls( Str1 );
       EnhKeybdSy     : IF ( ( Mem[$40:$96] AND $10 ) <> 0 ) THEN
                           IRes := 1
                        ELSE
                           IRes := 0;
       KeyStringSy    : BEGIN
                           I    := Get_Key_Index( Str1 );
                           SRes := '';
                           IF ( I > 0 ) THEN
                              IF ( Key_Definitions[I].Def <> NIL ) THEN
                                 SRes := Key_Definitions[I].Def^;
                        END;
       ELSE ;

   END (* CASE *);

   CASE ResTypeVector[Operator] OF
      Integer_Variable_Type:  Push_Stack_Integer( IRes );
      String_Variable_Type :  Push_Stack_String ( SRes );
      ELSE;
   END (* CASE *);

END   (* Perform_Operator *);

(*----------------------------------------------------------------------*)
(*       Get_Next_Operand --- Get next operand from postfix string      *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Next_Operand( VAR Operand_Type : INTEGER;
                            VAR LIndex       : LONGINT  );

BEGIN (* Get_Next_Operand *)

   INC( Script_Buffer_Pos );

   Operand_Type := Script_Buffer^[Script_Buffer_Pos];

   CASE Operands[Operand_Type] OF

      Operator_Type,
      Integer_Variable_Type,
      String_Variable_Type:  BEGIN
                                INC( Script_Buffer_Pos );
                                LIndex := Script_Buffer^[Script_Buffer_Pos];
                             END;

      Integer_Constant_Type: BEGIN
                                INC( Script_Buffer_Pos );
                                MOVE( Script_Buffer^[Script_Buffer_Pos],
                                      LIndex, SIZEOF( LongInt ) );
                                INC( Script_Buffer_Pos );
                             END;

      String_Constant_Type:  INC( Script_Buffer_Pos );

   END (* CASE *);

END   (* Get_Next_Operand *);

(*----------------------------------------------------------------------*)

BEGIN (* Execute_Stack *)
{
   IF Debug_Mode THEN
      Debug_Write('+++ Entering Execute_Stack +++');
}
   End_Of_Stack := FALSE;
   Stack_Index  := 0;

   WHILE ( NOT End_Of_Stack ) DO
      BEGIN

         Get_Next_Operand( Operand_Type , LIndex );

         CASE Operands[Operand_Type] OF

            Integer_Variable_Type,
            String_Variable_Type :  BEGIN
                                       Index := LIndex;
                                       Move_Variable_To_Stack( Index );
                                    END;

            Integer_Constant_Type:  Move_Integer_Constant_To_Stack( LIndex );

            String_Constant_Type :  Move_String_Constant_To_Stack ( Script_Buffer_Pos );

            Operator_Type        :  BEGIN
                                       Index := LIndex;
                                       Perform_Operator( OperSyms2[Index] );
                                    END;

            StackEnd_Type        :  End_Of_Stack := TRUE;

         END (* CASE *);

      END;

   WITH Script_Variables^[Result_Index] DO
      BEGIN
         CASE Var_Type OF
            Integer_Variable_Type : BEGIN
                                       Pop_Stack_Integer( Int1 );
                                       MOVE( Int1,
                                             Var_Value^[1],
                                             SIZEOF( LongInt ) );
                                    END;
            String_Variable_Type  : BEGIN
                                       Pop_Stack_String( Str1 );
                                       Var_Value^ := Str1;
                                    END;
            ELSE
{
               IF Debug_Mode THEN
                  Debug_Write('*** BOGUS RESULT MODE IN EXECUTE_STACK = ' +
                              ITOS( ORD( Var_Type ) ) );
}
               ;
         END (* CASE *);
      END;
{
   IF Debug_Mode THEN
      Debug_Write('+++ Leaving Execute_Stack +++');
}
END   (* Execute_Stack *);

(*----------------------------------------------------------------------*)

PROCEDURE Do_Simple_If( Condit : BOOLEAN );

BEGIN (* Do_Simple_If *)

   IF ( Script_Integer_1 = 1 ) THEN
      IF Condit THEN
         Script_Buffer_Pos := PRED( Script_Integer_2 )
      ELSE
         Script_Buffer_Pos := PRED( Script_Integer_3 )
   ELSE
      IF ( NOT Condit ) THEN
         Script_Buffer_Pos := PRED( Script_Integer_2 )
      ELSE
         Script_Buffer_Pos := PRED( Script_Integer_3 );

END   (* Do_Simple_If *);

(*--------------------------------------------------------------------------*)
(*      Fix_Up_File_Name --- Get file name for edit/view operation          *)
(*--------------------------------------------------------------------------*)

PROCEDURE Fix_Up_File_Name(      File_Function: AnyStr;
                                 Path         : AnyStr;
                                 FName        : AnyStr;
                            VAR  Jump_Text    : AnyStr  );
VAR
   IPos  : INTEGER;

BEGIN (* Fix_Up_File_Name *)
                                   (* Save screen *)

   Draw_Titled_Box( Saved_Screen, 5, 10, 75, 14, File_Function + ' File');

                                   (* Get name of file to edit *)

   WRITELN('Enter name of file to ', File_Function, ':');
   WRITE('>');
   IF ( LENGTH( FName ) = 0 ) THEN
      Read_Edited_String( FName )
   ELSE
      WRITE( FName );
   WRITELN;
                                   (* Restore screen *)

   Restore_Screen_And_Colors( Saved_Screen );

                                   (* Replace file name marker in path *)
                                   (* with file name just obtained     *)

   IF ( FName <> CHR( ESC ) ) THEN
      BEGIN

         Jump_Text := Path;

         IPos := POS( '%F' , Jump_Text );

         WHILE( IPos > 0 ) DO
            BEGIN
               DELETE( Jump_Text, IPos, 2 );
               INSERT( FName, Jump_Text, IPos );
               IPos := POS( '%F' , Jump_Text );
            END;

      END
   ELSE
      Jump_Text[0] := CHR( 0 );

END    (* Fix_Up_File_Name *);

(*--------------------------------------------------------------------------*)
(*           Allocate_Variable --- Allocate variable if necessary           *)
(*--------------------------------------------------------------------------*)

PROCEDURE Allocate_Variable;

VAR
   NBytes : INTEGER;
   P      : Script_Save_Variable_Record_Ptr;

BEGIN (* Allocate_Variable *)

{
   IF Debug_Mode THEN
      Debug_Write('--- Allocating variable # ' + ITOS( Script_Integer_1 ) +
              ' = ' + Script_String + ' of type = ' + ITOS( Script_Integer_2 ) );
}
                                   (* Save previous var at this offset *)
                                   (* if in CALLed procedure           *)

   IF ( Script_Call_Depth > 0 ) THEN
      WITH Script_Call_Stack[Script_Call_Depth] DO
         BEGIN
            P := Save_Vars;
            NEW( Save_Vars );
            Save_Vars^.Prev_Var  := P;
            NEW( Save_Vars^.Save_Data );
            Save_Vars^.Save_Data^ := Script_Variables^[Script_Integer_1];

{
            IF Debug_Mode THEN
               BEGIN
                  Debug_Write('--- Saving old variable ' + IToS( Script_Integer_1 ) );
                  Debug_Write('                   Name = ' +
                              Script_Variables^[Script_Integer_1].Var_Name );
                  Debug_Write('             Call depth = ' +
                              IToS( Script_Call_Depth ) );
               END;
}

         END;
                                   (* Allocate the variable *)

   IF ( Command = DeclareSy ) THEN
      WITH Script_Variables^[Script_Integer_1] DO
         BEGIN

            CASE Oper_Type_Vector[Script_Integer_2] OF
               Integer_Variable_Type: NBytes := 5;
               String_Variable_Type : NBytes := 256;
               ELSE
{
                  IF Debug_Mode THEN
                     Debug_Write('===> WARNING, Bogus type in allocate = ' +
                                 ITOS( Script_Integer_2 ) );
}
                                      ;
            END (* CASE *);

         GETMEM( Var_Value , NBytes );

         Var_Value^ := Script_String_2;
         Var_Name   := Script_String;
         Var_Type   := Oper_Type_Vector[Script_Integer_2];
         Var_Passed := FALSE;

      END
   ELSE IF ( Command = ImportSy ) THEN
      BEGIN
         INC( Script_Parameter_Got );
         Script_Variables^[Script_Integer_1] :=
            Prev_Script_Variables^[Script_Parameters^[Script_Parameter_Got]];
         Script_Variables^[Script_Integer_1].Var_Passed := TRUE;
      END
   ELSE (* PImportSy *)
      BEGIN
         INC( Proc_Parameter_Got );
         Script_Variables^[Script_Integer_1] :=
            Script_Variables^[Proc_Parameters^[Proc_Parameter_Got]];
         Script_Variables^[Script_Integer_1].Var_Passed := TRUE;
      END;

   Script_Variable_Count := MAX( Script_Variable_Count , Script_Integer_1 );

END   (* Allocate_Variable *);

(*--------------------------------------------------------------------------*)
(*                Zap_Variables --- Zap script variables                    *)
(*--------------------------------------------------------------------------*)

PROCEDURE Zap_Script_Variables( First : INTEGER;  Last : INTEGER );

VAR
   I: INTEGER;
   P: Script_Save_Variable_Record_Ptr;
   V: INTEGER;

BEGIN (* Zap_Script_Variables *)
                                   (* Free up variable memory *)
   FOR I := Last DOWNTO First DO
      WITH Script_Variables^[I] DO
         IF ( NOT Var_Passed ) THEN
            CASE Var_Type OF
               Integer_Variable_Type: MyFreeMem( Var_Value , 5   );
               String_Variable_Type : MyFreeMem( Var_Value , 256 );
               ELSE;
            END;
                                   (* Restore old variable pointers *)
                                   (* if necessary.                 *)

   IF ( Script_Call_Depth > 0 ) THEN
      WITH Script_Call_Stack[Script_Call_Depth] DO
         FOR I := Last DOWNTO First DO
            BEGIN
               P := Save_Vars;
               IF ( P <> NIL ) THEN
                  BEGIN
                     Script_Variables^[I] := P^.Save_Data^;
                     Save_Vars            := P^.Prev_Var;
                     DISPOSE( P^.Save_Data );
                     DISPOSE( P );
{
                     IF Debug_Mode THEN
                        BEGIN
                           Debug_Write('Restoring variable ' + IToS( I ));
                           Debug_Write('            Name = ' + Script_Variables^[I].Var_Name );
                           CASE Script_Variables^[I].Var_Type OF
                              Integer_Variable_Type : BEGIN
                                                         Debug_Write('            Type = INTEGER' );
                                                         MOVE( Script_Variables^[I].Var_Value^[1], V,
                                                               SIZEOF( LONGINT ) );
                                                         Debug_Write('           Value = ' + IToS( V ) );
                                                      END;
                              String_Variable_Type  : BEGIN
                                                         Debug_Write('            Type = STRING');
                                                         Debug_Write('           Value = ' +
                                                                     Script_Variables^[I].Var_Value^ );
                                                      END;
                           END (* CASE *);
                           Debug_Write('             Call depth = ' +
                                       IToS( Script_Call_Depth ) );
                        END;
}
                  END;
            END;
                                   (* Restore old variable count *)

   Script_Variable_Count := MAX( PRED( First ) , 2 );
{
   IF Debug_Mode THEN
      Debug_Write( 'Zap:  First = ' + IToS( First ) + ', Last = ' +
                   IToS( Last ) + ', Count = ' + IToS( Script_Variable_Count ) );
}
END   (* Zap_Script_Variables *);

(*--------------------------------------------------------------------------*)
(*           Clear_Script_Variables --- Deallocate script variables         *)
(*--------------------------------------------------------------------------*)

PROCEDURE Clear_Script_Variables;

VAR
   I: INTEGER;
   L: INTEGER;
   S: AnyStr;

BEGIN (* Clear_Script_Variables *)

                                   (* Free space for variable values *)

   Zap_Script_Variables( 0 , Script_Variable_Count );

                                   (* Free space for variable pointers *)

   MyFreeMem( Script_Variables ,
            ( Script_Variable_Count + 3 ) * SizeOf( Script_Variables^[1] ) );

                                   (* No script variables active *)
   Script_Variable_Count  := 2;
   Script_Parameter_Count := 0;
   Script_Parameter_Got   := 0;
                                   (* Close all script files           *)

   FOR I := 1 TO MaxScriptOpenFiles DO
      IF Script_File_Used[I] THEN
         BEGIN
            IF Script_File_List[I]^.Opened THEN
               BEGIN
                     (*!I-*)
                  CLOSE( Script_File_List[I]^.F );
                     (*!I+*)
                  L := INT24Result;
               END;
            DISPOSE( Script_File_List[I] );
            Script_File_Used[I] := FALSE;
         END;
                                   (* Turn off other script activities *)

   FOR I := 1 TO Script_Wait_Count DO
      WITH Script_Wait_List[I] DO
         BEGIN
            DISPOSE( Wait_Text  );
            DISPOSE( Wait_Reply );
         END;

   Script_File_Name[0]   := CHR( 0 );
   Script_Buffer         := NIL;
   Script_Dialed         := FALSE;
   Really_Wait_String    := FALSE;
   WaitString_Mode       := FALSE;
   Script_File_Count     := 0;
   Script_Wait_Count     := 0;
   Script_IO_Error       := 0;
                                   (* Clear out command line area. *)
   S := CHR( CR );
   MOVE( S[0], Mem[PrefixSeg:$80], 2 );

END   (* Clear_Script_Variables *);

(*--------------------------------------------------------------------------*)
(*           Read_Chars --- Read characters from script-defined file        *)
(*--------------------------------------------------------------------------*)

PROCEDURE Read_Chars( VAR F        : Text_File;
                      VAR S        : AnyStr;
                          N        : INTEGER;
                      VAR EOF_Seen : BOOLEAN;
                          Use_KBD  : BOOLEAN );

VAR
   I : INTEGER;
   J : INTEGER;
   Ch: CHAR;

BEGIN (* Read_Chars *)
{
   IF Debug_Mode THEN
      BEGIN
         Write_Log( 'N=' + CHR( ORD('0') + N ), FALSE, FALSE );
         Write_Log( 'UK=' + CHR( ORD('0') + ORD(Use_KBD) ), FALSE, FALSE );
      END;
}
   IF EOF_Seen THEN
      S[0] := CHR( 0 )
   ELSE
      BEGIN

         I := 0;

         WHILE ( ( I < N ) AND ( NOT EOF_Seen ) ) DO
            BEGIN

                  (*!I-*)
               CASE Use_KBD OF
                  FALSE:  BEGIN
                             READ( F , Ch );
                             Script_IO_Error := INT24Result;
                             EOF_Seen        := EOF( F ) OR ( Ch = ^Z );
                          END;
                  TRUE:   BEGIN
                             Read_Kbd( Ch );
                             WRITE( Ch );
                             Script_IO_Error := INT24Result;
                          END;
               END (* CASE *);
                  (*!I+*)

               IF ( NOT EOF_Seen ) THEN
                  BEGIN
                     INC( I );
                     S[I] := Ch;
                  END;

            END;

         S[0] := CHR( I );

      END;

END   (* Read_Chars *);

(*--------------------------------------------------------------------------*)
(*           Unload_This_Script --- Unload just-executed script             *)
(*--------------------------------------------------------------------------*)

PROCEDURE Unload_This_Script;

VAR
   I: INTEGER;
   J: INTEGER;

BEGIN (* Unload_This_Script *)

   I := Current_Script_Num;

   MyFreeMem( Scripts[I].Script_Ptr , Scripts[I].Script_Len );

   FOR J := ( I + 1 ) TO Script_Count DO
      MOVE( Scripts[J], Scripts[J-1], SizeOf( Scripts[1] ) );

   DEC( Script_Count );

END   (* Unload_This_Script *);

(*--------------------------------------------------------------------------*)
(*           Exit_All_Scripts --- Exit all scripts regardless of nesting    *)
(*--------------------------------------------------------------------------*)

PROCEDURE Exit_All_Scripts;

VAR
   I: INTEGER;

BEGIN (* Exit_All_Scripts *)

   IF ( Script_Stack_Depth > 0 ) THEN
      REPEAT
                                   (* Free space for script buffer *)

         IF ( Auto_Unload_Scripts OR
              ( Scripts[Current_Script_Num].Script_Name[1] = '!' ) ) THEN
            Unload_This_Script;

                                   (* Free space for variable values *)

         Zap_Script_Variables( 0 , Script_Variable_Count );

                                   (* Free space for variable pointers *)
         MyFreeMem( Script_Variables ,
                  ( Script_Variable_Count + 3 ) * SizeOf( Script_Variables^[1] ) );

                                   (* Free space for any parameters *)

         IF ( Script_Parameter_Count > 0 ) THEN
            IF ( Script_Parameters <> NIL ) THEN
               DISPOSE( Script_Parameters );

         WITH Script_Stack_Position[Script_Stack_Depth] DO
            BEGIN
               Script_Buffer          := Buffer_Ptr;
               Script_Buffer_Pos      := Buffer_Pos;
               Current_Script_Num     := Script_Num;
               Script_Variables       := Vars_Ptr;
               Script_Variable_Count  := Vars_Count;
               Script_Parameters      := Params_Ptr;
               Script_Parameter_Count := Params_Count;
               Script_Parameter_Got   := Params_Got;
               Prev_Script_Variables  := Prev_Ptr;
            END;

         DEC( Script_Stack_Depth );

      UNTIL ( Script_Stack_Depth = 0 );

                                   (* Clear top-level scripts stuff *)
   Clear_Script_Variables;
                                   (* Clear command-line mode         *)

   Script_Command_Key_Mode := FALSE;

                                   (* Indicate script mode turned off *)

   Toggle_Option( 'Script Mode', Script_File_Mode );

END   (* Exit_All_Scripts *);

(*--------------------------------------------------------------------------*)
(*           Store_Find_Info --- Store file info for DirFind, DirNext       *)
(*--------------------------------------------------------------------------*)

PROCEDURE Store_Find_Info;

VAR
   SAttr : ShortStr;

BEGIN (* Store_Find_Info *)

   Script_IO_Error := DosError;

   IF ( DosError <> 0 ) THEN
      BEGIN
         Script_Variables^[Script_Integer_1].Var_Value^ := '';
         Script_Variables^[Script_Integer_2].Var_Value^ := '';
         Script_Variables^[Script_Integer_3].Var_Value^ := '';
         Script_Variables^[Script_Integer_4].Var_Value^ := '';
         Script_Variables^[Script_Integer_5].Var_Value^ := '';
      END
   ELSE
      WITH Script_Search_Rec DO
         BEGIN

            Script_Variables^[Script_Integer_1].Var_Value^ := Name;
            Script_Variables^[Script_Integer_2].Var_Value^ := '';

            SAttr := '';

            IF ( Attr AND ReadOnly     ) <> 0 THEN
               SAttr := 'R';
            IF ( Attr AND Hidden       ) <> 0 THEN
               SAttr := SAttr + 'H';
            IF ( Attr AND SysFile      ) <> 0 THEN
               SAttr := SAttr + 'S';
            IF ( Attr AND VolumeID     ) <> 0 THEN
               SAttr := SAttr + 'V';
            IF ( Attr AND Directory    ) <> 0 THEN
               SAttr := SAttr + 'D';
            IF ( Attr AND Archive      ) <> 0 THEN
               SAttr := SAttr + 'A';

            IF ( SAttr = '' ) THEN
               SAttr := 'N';

            Script_Variables^[Script_Integer_2].Var_Value^ := SAttr;

            Dir_Convert_File_Date_And_Time( Time,
                                            Script_Variables^[Script_Integer_3].Var_Value^,
                                            Script_Variables^[Script_Integer_4].Var_Value^ );
            STR( Size , Script_Variables^[Script_Integer_5].Var_Value^ );

         END;

END   (* Store_Find_Info *);

(*--------------------------------------------------------------------------*)
(*           Do_File_Editing --- Call file editor                           *)
(*--------------------------------------------------------------------------*)

PROCEDURE Do_File_Editing;

VAR
   S: AnyStr;

BEGIN (* Do_File_Editing *)

   IF ( LENGTH( Editor_Name ) > 0 ) THEN
      BEGIN
         IF ( POS( '%F' , Editor_Name ) > 0 ) THEN
            Fix_Up_File_Name( 'Edit', Editor_Name, Script_String, S )
         ELSE
            S := Editor_Name;
         DosJump( S );
      END
   ELSE
      PibEditor( Script_String );

END   (* Do_File_Editing *);

(*--------------------------------------------------------------------------*)
(*           Do_File_Viewing --- Call file viewer                           *)
(*--------------------------------------------------------------------------*)

PROCEDURE Do_File_Viewing;

VAR
   S: AnyStr;

BEGIN (* Do_File_Viewing *)

   IF ( LENGTH( Browser_Name ) > 0 ) THEN
      BEGIN
         IF ( POS( '%F' , Browser_Name ) > 0 ) THEN
            Fix_Up_File_Name( 'View', Browser_Name,  Script_String, S )
         ELSE
            S := Browser_Name;
         DosJump( S );
      END
   ELSE
      View_A_File( Script_String );

END   (* Do_File_Viewing *);

(*--------------------------------------------------------------------------*)
(*           CopyFile --- Copy one file to another                          *)
(*--------------------------------------------------------------------------*)

PROCEDURE CopyFile( F_Name : AnyStr; G_Name : AnyStr; VAR BytesDone : LONGINT );

VAR
   F         : FILE;
   G         : FILE;
   BytesRead : INTEGER;

BEGIN (* CopyFile *)
                                   (* Bytes copied    *)
   BytesDone := 0;
                                   (* Open input file *)
   ASSIGN( F , F_Name );
   RESET ( F , 1 );

   Script_IO_Error := Int24Result;
   IF ( Script_IO_Error <> 0 ) THEN
      EXIT;
                                   (* Open output file *)
   ASSIGN ( G , G_Name );
   REWRITE( G , 1 );

   Script_IO_Error := Int24Result;
   IF ( Script_IO_Error <> 0 ) THEN
      BEGIN
         CLOSE( F );
         Err := Int24Result;
         EXIT;
      END;
                                   (* Perform the copy *)
   REPEAT

      BlockRead( F, Sector_Data, MaxSectorLength, BytesRead );

      Script_IO_Error := Int24Result;

      IF ( ( BytesRead > 0 ) AND ( Script_IO_Error = 0 ) ) THEN
         BEGIN
            BlockWrite( G, Sector_Data, BytesRead );
            Script_IO_Error := Int24Result;
         END;

      BytesDone := BytesDone + BytesRead;

   UNTIL ( ( BytesRead < MaxSectorLength ) OR ( Script_IO_Error <> 0 ) );

                                   (* Close files  *)
   CLOSE( F );
   Err := Int24Result;

   IF ( Script_IO_Error = 0 ) THEN
      Script_IO_Error := Err;

   CLOSE( G );
   Err := Int24Result;

   IF ( Script_IO_Error = 0 ) THEN
      Script_IO_Error := Err;

END   (* CopyFile *);