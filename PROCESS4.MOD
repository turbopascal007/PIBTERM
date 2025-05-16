(*----------------------------------------------------------------------*)
(*             Get_Script_Name --- Get script name                      *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Script_Name;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_Script_Name                                      *)
(*                                                                      *)
(*     Purpose:    Gets script name if not already supplied             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_Script_Name;                                              *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   X : INTEGER;
   Y : INTEGER;
   Ch: CHAR;

BEGIN (* Get_Script_Name *)
                                   (* Pick up script file name *)
                                   (* if not already supplied  *)

   IF ( LENGTH( Script_File_Name ) = 0 ) THEN
      BEGIN
         TextColor( Menu_Text_Color_2 );
         WRITELN('Script name (hit ENTER for menu, ESC to quit)');
         WRITE('>');
         TextColor( Menu_Text_Color );
         X  := WhereX;
         Y  := WhereY;
         Ch := Edit_String( Script_File_Name, 255, X, X, Y, 64, FALSE, 0 );
         IF ( Ch = CHR( ESC ) ) THEN
            Script_File_Name := CHR( ESC );
         WRITELN;
      END;

END   (* Get_Script_Name *);

(*----------------------------------------------------------------------*)
(*       Get_Script_File_Name --- Get file name from script name        *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Script_File_Name( VAR Script_Name      : AnyStr;
                                VAR Script_File_Name : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_Script_File_Name                                 *)
(*                                                                      *)
(*     Purpose:    Gets file name from script name                      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_Script_File_Name( VAR Script_Name      : AnyStr;          *)
(*                              VAR Script_File_Name : AnyStr );        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I        : INTEGER;
   J        : INTEGER;

BEGIN (* Get_Script_File_Name *)
                                   (* If leading '*', then script is   *)
                                   (* member of PIBTERM.SCL library.   *)

   IF ( Script_Name[1] = '*' ) THEN
      BEGIN
         Use_Script_Library := TRUE;
         Script_Name        := COPY( Script_Name, 2,
                                       LENGTH( Script_Name ) - 1 );
      END
   ELSE
      Use_Script_Library := FALSE;
                                   (* Convert script name to file name *)

   Script_File_Name := Script_Name;

   IF ( POS( '.', Script_File_Name ) = 0 ) THEN
      Script_File_Name := Script_File_Name + '.SCR';

                                   (* Now strip off directory stuff *)
                                   (* from script name itself.      *)

   I := POS( '.', Script_Name );
                                   (* Remove trailing filetype      *)
   IF ( I > 0 ) THEN
      Script_Name := COPY( Script_Name, 1, I - 1 );

                                   (* Remove drive indicator        *)
   I := POS( ':', Script_Name );

   IF ( I > 0 ) THEN
      Script_Name := COPY( Script_Name, I + 1, LENGTH( Script_Name ) - I );

                                   (* Remove directory indicator *)

   IF ( POS( '\', Script_Name ) > 0 ) THEN
      BEGIN
         J := LENGTH( Script_Name );
         FOR I := J DOWNTO 1 DO
            IF ( Script_Name[I] = '\' ) THEN
               BEGIN
                  Script_Name := COPY( Script_Name, I + 1 , J - I );
                  EXIT;
               END;
      END
   ELSE
      Script_File_Name := Script_Path + Script_File_Name;

END   (* Get_Script_File_Name *);

(*----------------------------------------------------------------------*)
(*        Skip_To_Script --- Skips to script in script library          *)
(*----------------------------------------------------------------------*)

FUNCTION Skip_To_Script( Script_Short_Name : AnyStr ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:  Skip_To_Script                                        *)
(*                                                                      *)
(*     Purpose:   Skips to script in library file                       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Found := Skip_To_Script( Script_Short_Name ) : BOOLEAN;       *)
(*                                                                      *)
(*           Script_Short_Name --- Script name to look for              *)
(*           Found             --- TRUE if script found                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Found : BOOLEAN;

BEGIN (* Skip_To_Script *)

   Found := FALSE;

   Script_Short_Name := TRIM( Script_Short_Name );

   REPEAT

      READLN( Script_File , Script_Line );

      IF ( LENGTH( Script_Line ) > 2 ) THEN
         IF ( COPY( Script_Line, 1, 2 ) = '==' ) THEN
            Found := UpperCase( COPY( Script_Line, 3,
                                        LENGTH( Script_Line ) - 2 ) ) =
                     Script_Short_Name;

   UNTIL ( Found OR EOF( Script_File ) );

   Skip_To_Script := Found;

END   (* Skip_To_Script *);

(*----------------------------------------------------------------------*)
(*               Store_Script --- Store script in script list           *)
(*----------------------------------------------------------------------*)

PROCEDURE Store_Script( VAR Script_Slot : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Store_Script                                         *)
(*                                                                      *)
(*     Purpose:    Stores just-compiled script in script list           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Store_Script;                                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I           : INTEGER;
   Com_Line    : BOOLEAN;

BEGIN (* Store_Script *)
                                   (* See if command line being faked   *)
                                   (* as script.                        *)

   Com_Line := ( Script_Short_Name[1] = '!' );

                                   (* See if name already exists.       *)
   Script_Slot := 0;

   IF ( NOT Com_Line ) THEN
      FOR I := 1 TO Script_Count DO
         IF ( Script_Short_Name = Scripts[I].Script_Name ) THEN
            Script_Slot := I;
                                   (* If slot specified, release memory *)
                                   (* associated with it.               *)
   IF ( Script_Slot > 0 ) THEN
      BEGIN
         WRITELN;
         WRITELN( Script_Short_Name, ' replaced.' );
         MyFreeMem( Scripts[Script_Slot].Script_Ptr ,
                    Scripts[Script_Slot].Script_Len );
      END
   ELSE
                                   (* Check if room to add script.  *)
                                   (* If not, replace earliest one. *)

      IF ( Script_Count < MaxScripts ) THEN
         BEGIN
            INC( Script_Count );
            Script_Slot  := Script_Count;
         END
      ELSE
         BEGIN
            IF ( NOT Com_Line ) THEN
               BEGIN
                  WRITELN;
                  WRITELN('This script replaces script ',Scripts[1].Script_Name );
               END;
            Script_Slot := 1;
            MyFreeMem( Scripts[1].Script_Ptr , Scripts[1].Script_Len );
         END;

   WITH Scripts[Script_Slot] DO
      BEGIN
         Script_Name         := Script_Short_Name;
         Script_Ptr          := Script_Buffer;
         Script_Len          := Script_Buffer_Size;
         Script_Vars_Count   := Script_Variable_MaxKount;
         Script_Vars         := NIL;
         Script_Params_Count := Import_Count;
         Script_Params       := NIL;
      END;

END   (* Store_Script *);

(*----------------------------------------------------------------------*)
(*         Get_Library_Script --- Compile a script from library file    *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Library_Script;

VAR
   I: INTEGER;

BEGIN (* Get_Library_Script *)
                                   (* Assign script library name *)

   ASSIGN( Script_File , Home_Dir + 'PIBTERM.SCL' );
      (*!I-*)
   RESET ( Script_File );
      (*!I+*)
                                   (* Skip down to selected member. *)

   Script_File_OK := ( Int24Result = 0 );

   IF Script_File_OK THEN
      BEGIN
         Script_File_Ok := Skip_To_Script( Script_Short_Name );
         IF Script_File_OK THEN
            Use_Script_Library := TRUE;
      END
   ELSE
      BEGIN
            (*!I-*)
         CLOSE( Script_File );
            (*!I+*)
         I := INT24Result;
      END;

END   (* Get_Library_Script *);

(*----------------------------------------------------------------------*)
(*         Get_Dir_Script --- Compile a script from disk file           *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Dir_Script;

VAR
   I: INTEGER;

BEGIN (* Get_Dir_Script *)
                                   (* Assign script library name *)

   ASSIGN( Script_File , Script_File_Name );
      (*!I-*)
   RESET ( Script_File );
      (*!I+*)
                                   (* See if open went OK        *)

   Script_File_OK := ( Int24Result = 0 );

   IF ( NOT Script_File_OK ) THEN
         (*!I-*)
      CLOSE( Script_File );
         (*!I+*)

   I := INT24Result;

END   (* Get_Dir_Script *);

(*----------------------------------------------------------------------*)
(*           Locate_Script_File --- Locate script file                  *)
(*----------------------------------------------------------------------*)

PROCEDURE Locate_Script_File;

BEGIN (* Locate_Script_File *)
                                   (* Check if library search forced *)
   IF Use_Script_Library THEN
      Get_Library_Script
   ELSE                            (* Otherwise do search in proper order *)
      CASE Script_Search_Order OF

         Dir_Then_Lib : BEGIN
                           Get_Dir_Script;
                           IF ( NOT Script_File_OK ) THEN
                              Get_Library_Script;
                        END;

         Lib_Then_Dir : BEGIN
                           Get_Library_Script;
                           IF ( NOT Script_File_OK ) THEN
                              Get_Dir_Script;
                        END;

         Dir_Only     : Get_Dir_Script;

         Lib_Only     : Get_Library_Script;

      END (* CASE *);

END   (* Locate_Script_File *);

(*----------------------------------------------------------------------*)
(*              Compile_Script --- Compile a script to memory           *)
(*----------------------------------------------------------------------*)

PROCEDURE Compile_Script;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Compile_Script                                       *)
(*                                                                      *)
(*     Purpose:    Compiles a script to memory                          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Compile_Script;                                               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I          : INTEGER;
   Local_Save : Saved_Screen_Ptr;

LABEL 99;

(*----------------------------------------------------------------------*)

PROCEDURE Cant_Store( S : AnyStr );

BEGIN (* Cant_Store *)

   IF ( LENGTH( S ) > 0 ) THEN
      WRITELN( S );

   WRITELN('Script will not be stored.');

   Script_File_Mode   := FALSE;

   MyFreeMem( Script_Buffer , Script_Buffer_Size );

   Script_File_Mode := FALSE;

{--IMP
   IF Script_Debug_Mode THEN
      BEGIN
            (*!I-*)
         WRITELN( Script_Debug_File , '---> Fatal error: ' , S );
            (*!I+*)
         I := Int24Result;
      END;
}
END   (* Cant_Store *);

(*----------------------------------------------------------------------*)

PROCEDURE Read_Write_Spill_File;

VAR
   L: INTEGER;

BEGIN (* Read_Write_Spill_File *)

{--IMP
   IF Script_Debug_Mode THEN
      BEGIN
            (*!I-*)
         WRITELN( Script_Debug_File , '---> Copy uses spill file.' );
            (*!I+*)
         I := Int24Result;
      END;
}
   ASSIGN ( Spill_File , Script_Path + 'ZZSPILL.DAT' );
      (*!I-*)
   REWRITE( Spill_File , 1 );
      (*!I+*)

   IF ( INT24Result <> 0 ) THEN
      BEGIN
         Cant_Store('Can''t open spill file.');
         EXIT;
      END;

   L := Script_Buffer_Pos;

      (*!I-*)
   BlockWrite( Spill_File, Script_Buffer^[1], L );
      (*!I+*)

   IF ( INT24Result <> 0 ) THEN
      BEGIN
         Cant_Store('Error writing to spill file.');
         EXIT;
      END;

   MyFreeMem( Script_Buffer , Script_Buffer_Size );

   GETMEM ( Script_Buffer , Script_Buffer_Pos );

      (*!I-*)
   CLOSE  ( Spill_File );
      (*!I+*)

   IF ( INT24Result <> 0 ) THEN
      BEGIN
         Cant_Store('Error closing spill file.');
         EXIT;
      END;

   IF ( Script_Buffer = NIL ) THEN
      BEGIN
         Cant_Store('Not enough memory to store script.');
         EXIT;
      END;

      (*!I-*)
   RESET  ( Spill_File , Script_Buffer_Pos );
      (*!I+*)

   IF ( INT24Result <> 0 ) THEN
      BEGIN
         Cant_Store('Error re-opening spill file.');
         EXIT;
      END;

      (*!I-*)
   BlockRead( Spill_File, Script_Buffer^[1], 1 );
      (*!I+*)

   IF ( INT24Result <> 0 ) THEN
      BEGIN
         Cant_Store('Error reading spill file.');
         EXIT;
      END;

      (*!I-*)
   CLOSE( Spill_File );
      (*!I+*)

   IF ( INT24Result <> 0 ) THEN
      BEGIN
         Cant_Store('Error closing spill file.');
         EXIT;
      END;

      (*!I-*)
   ERASE( Spill_File );
      (*!I+*)

   IF ( INT24Result <> 0 ) THEN
      BEGIN
         Cant_Store('Error erasing spill file.');
         EXIT;
      END;

END   (* Read_Write_Spill_File *);

(*----------------------------------------------------------------------*)

BEGIN (* Compile_Script *)
                                   (* Save current screen *)

   Draw_Titled_Box( Local_Save, 10, 10, 78, 20, 'Compile script file' );

                                   (* Get script name to compile *)
   Get_Script_Name;
                                   (* Quit if null entry *)

   IF LENGTH( Script_File_Name ) <= 0 THEN
      BEGIN
         Restore_Screen_And_Colors( Local_Save );
         EXIT;
      END;
                                   (* Fix up script file name *)

   Script_Short_Name := UpperCase( TRIM( Script_File_Name ) );

   Get_Script_File_Name( Script_Short_Name , Script_File_Name );

                                   (* Get the script from a .SCR file *)
                                   (* or from library PIBTERM.SCL     *)
   Locate_Script_File;
                                   (* Quit now if we couldn't find *)
                                   (* the script.                  *)
   IF ( NOT Script_File_OK ) THEN
      BEGIN

         WRITELN(' ');
         WRITELN('Script ',Script_Short_Name,' not found');
         WRITELN(' ');

         Really_Wait_String  := FALSE;
         Script_Suspend_Time := 0;
         Script_File_Mode    := FALSE;

                                   (* Restore previous screen *)
         Window_Delay;

         Restore_Screen_And_Colors( Local_Save );

                                   (* Quit now *)
         EXIT;

      END;
                                   (* Tell where script found *)
   WRITELN(' ');
   IF ( NOT Use_Script_Library ) THEN
      WRITELN('Beginning scan of ',Script_File_Name)
   ELSE
      WRITELN('Beginning scan of ',Script_Short_Name,' in PIBTERM.SCL');
   WRITELN(' ');
                                   (* Allocate long buffer to hold  *)
                                   (* compiled script commands.  It *)
                                   (* will be truncated later as    *)
                                   (* necessary.                    *)

   Script_Memory_Avail := MaxAvail - 8000;

   IF ( Script_Memory_Avail > 32000 ) THEN
      Script_Memory_Avail := 32000
   ELSE IF ( Script_Memory_Avail <= 2048 ) THEN
      BEGIN
         Cant_Store('Not enough memory to compile script.');
         GOTO 99;
      END;

   Script_Buffer_Size := Script_Memory_Avail;

   GETMEM( Script_Buffer , Script_Buffer_Size );

                                   (* Open debugging file if needed *)
   Script_Debug_Mode := FALSE;

{--IMP
   IF ( POS( 'ZZBOGUS.SCR' , Script_File_Name ) > 0 ) THEN
      BEGIN
         ASSIGN ( Script_Debug_File , 'ZZBOGUS.DBG' );
         REWRITE( Script_Debug_File );
         Script_Debug_Mode := TRUE;
         WRITELN( Script_Debug_File ,
                  '=== Script buffer size = ',Script_Buffer_Size);
      END;
}
                                   (* Current offset in script buffer *)
   Script_Buffer_Pos     := 0;
                                   (* No procedures yet defined     *)
   Script_Proc_Count     := 0;
   Script_Proc_Start     := 0;
                                   (* All stacks empty              *)
   Script_Repeat_Level   := 0;
   Script_If_Level       := 0;
   Script_While_Level    := 0;
   Script_Case_Level     := 0;
   Script_For_Level      := 0;
   Script_Proc_Level     := 0;
                                   (* Script line number            *)
   Script_Line_Number    := 0;
                                   (* No variables yet              *)
   Script_Variable_Kount    := 2;
   Script_Variable_MaxKount := 2;
   Import_Count             := 0;

   WITH Script_Vars[1] DO
      BEGIN
         Var_Name   := ' ';
         Var_Type   := String_Variable_Type;
      END;

   WITH Script_Vars[2] DO
      BEGIN
         Var_Name   := ' ';
         Var_Type   := String_Variable_Type;
      END;
                                   (* Not special EOF marker        *)
   Script_EOF := FALSE;
                                   (* Read and compile lines from   *)
                                   (* script file                   *)
   REPEAT
                                   (* Read script line             *)

      READLN( Script_File , Script_Line );

                                   (* Increment count read         *)

      INC( Script_Line_Number );

                                   (* Length of line read          *)

      Length_Script_Line := LENGTH( Script_Line );

      Saved_Script_Line := Script_Line;
      OK_Script_Command := TRUE;

                                   (* Check for serious read error *)
      IF Int24Result <> 0 THEN
         OK_Script_Command := FALSE

                                   (* Skip comment lines           *)

      ELSE IF ( Length_Script_Line > 0 ) THEN
         IF ( Script_Line[1] = '=' ) THEN
            BEGIN
               IF ( Length_Script_Line > 1 ) THEN
                  IF ( Script_Line[2] = '=' ) THEN
                     IF ( Length_Script_Line > 2 ) THEN
                        IF ( Script_Line[3] <> ' ' ) THEN
                           Script_EOF := ( Script_Line_Number > 1 );
            END
         ELSE IF ( Script_Line[1] <> '*' ) THEN

                                   (* Parse and store compiled command *)
            BEGIN
{--IMP
               IF Script_Debug_Mode THEN
                  BEGIN
                     WRITELN( Script_Debug_File , '--- next statement --- ' );
                     WRITELN( Script_Debug_File , '<', Script_Line, '>' );
                     WRITELN( Script_Debug_File , '--- ');
                  END;
}
               Extract_Script_Command( OK_Script_Command );

               IF OK_Script_Command THEN
                  Parse_Script_Command  ( OK_Script_Command )
               ELSE
                  WRITELN('Unrecognized script command');

               IF ( NOT Ok_Script_Command ) THEN
                  BEGIN

                     WRITELN('>>> Error in line ',
                              Script_Line_Number, ' of script: ');
                     WRITELN( Saved_Script_Line );

                     Press_Any;

                  END;

         END;

   UNTIL ( EOF( Script_File ) OR ( NOT OK_Script_Command ) OR Script_EOF );

                                   (* Close script file.             *)
      (*!I-*)
   CLOSE( Script_File );
      (*!I+*)

   I := Int24Result;
                                   (* Drop "finish script" command   *)
                                   (* into script buffer.            *)
{--IMP
   IF Script_Debug_Mode THEN
      WRITELN( Script_Debug_File , '--- Exit statement follows ... ');
}
   Copy_Byte_To_Buffer( ORD( ExitSy ) );

                                   (* Check if stacks empty.  If not,  *)
                                   (* error from unclosed loop.        *)

   OK_Script_Command := OK_Script_Command           AND
                        ( Script_Repeat_Level = 0 ) AND
                        ( Script_If_Level     = 0 ) AND
                        ( Script_Case_Level   = 0 ) AND
                        ( Script_For_Level    = 0 ) AND
                        ( Script_While_Level  = 0 ) AND
                        ( Script_Proc_Level   = 0 );

                                   (* Release memory from proc ptrs     *)
                                   (* if error caused script scan abort *)

   Dispose_Proc_Stuff( 1 , Script_Proc_Count );

                                   (* If everything OK, allow script   *)
                                   (* to execute, else release buffer. *)
   Really_Wait_String  := FALSE;
   Script_Suspend_Time := 0;

   IF OK_Script_Command THEN
      BEGIN
                                   (* Truncate script memory to what  *)
                                   (* is actually needed.             *)
                                   (* First, see if compiled script   *)
                                   (* can be move via Sector_Data.    *)
                                   (* If so, do that.  If not, open   *)
                                   (* spill file, write out code,     *)
                                   (* release memory, reallocate, and *)
                                   (* read code back in into shorter  *)
                                   (* memory block.                   *)

         Script_File_Mode := TRUE;

         IF ( Script_Buffer_Pos <= MaxSectorLength ) THEN
            BEGIN

               MOVE     ( Script_Buffer^[1], Sector_Data, Script_Buffer_Pos );
               MyFreeMem( Script_Buffer , Script_Buffer_Size );
               GETMEM   ( Script_Buffer , Script_Buffer_Pos  );
               IF( Script_Buffer = NIL ) THEN
                  Cant_Store('');
               MOVE   ( Sector_Data, Script_Buffer^[1], Script_Buffer_Pos );
{--IMP
               IF Script_Debug_Mode THEN
                  BEGIN
                        (*!I-*)
                     WRITELN( Script_Debug_File ,
                              '---> Copy uses Sector_Data.' );
                        (*!I+*)
                     I := Int24Result;
                  END;
}
            END
         ELSE
            BEGIN
               Read_Write_Spill_File;
            END;

         IF Script_File_Mode THEN
            BEGIN

               Script_Buffer_Size := Script_Buffer_Pos;
               Script_Buffer_Pos  := 0;
               Script_File_Mode   := TRUE;

               WRITELN('Script file OK.');

               Store_Script( Current_Script_Num );

               Window_Delay;

            END
         ELSE
            MyFreeMem( Script_Buffer , Script_Buffer_Pos );

      END
   ELSE
      BEGIN
         Cant_Store('');
         MyFreeMem( Script_Buffer , Script_Buffer_Size );
      END;
                                   (* Close debugging file    *)
99:

{--IMP
   IF Script_Debug_Mode THEN
      BEGIN
            (*!I-*)
         CLOSE( Script_Debug_File );
            (*!I+*)
         I := Int24Result;
      END;
}
                                   (* Restore previous screen *)

   Restore_Screen_And_Colors( Local_Save );

END   (* Compile_Script *);

(*----------------------------------------------------------------------*)
(*         Push_Current_Script --- Push current script onto stack       *)
(*----------------------------------------------------------------------*)

PROCEDURE Push_Current_Script;

BEGIN (* Push_Current_Script *)

   IF Script_File_Mode THEN
      BEGIN

         INC( Script_Stack_Depth );

         WITH Script_Stack_Position[Script_Stack_Depth] DO
            BEGIN
               Buffer_Pos   := Script_Buffer_Pos;
               Buffer_Ptr   := Script_Buffer;
               Script_Num   := Current_Script_Num;
               Vars_Ptr     := Script_Variables;
               Vars_Count   := Script_Variable_Count;
               Params_Ptr   := Script_Parameters;
               Params_Count := Script_Parameter_Count;
               Params_Got   := Script_Parameter_Got;
               Prev_Ptr     := Prev_Script_Variables;
            END;

      END;

END   (* Push_Current_Script *);

(*----------------------------------------------------------------------*)
(*         Pop_Current_Script --- Pop current script off of stack       *)
(*----------------------------------------------------------------------*)

PROCEDURE Pop_Current_Script;

BEGIN (* Pop_Current_Script *)

   IF ( Script_Stack_Depth > 0 ) THEN
      BEGIN

         WITH Script_Stack_Position[Script_Stack_Depth] DO
            BEGIN
               Script_Buffer_Pos       := Buffer_Pos;
               Script_Buffer           := Buffer_Ptr;
               Current_Script_Num      := Script_Num;
               Script_Variables        := Vars_Ptr;
               Script_Variable_Count   := Vars_Count;
               Script_Parameters       := Params_Ptr;
               Script_Parameter_Count  := Params_Count;
               Script_Parameter_Got    := Params_Got;
               Prev_Script_Variables   := Prev_Ptr;
            END;

         DEC( Script_Stack_Depth );
         Script_File_Mode   := TRUE;

      END;

END   (* Pop_Current_Script *);

(*----------------------------------------------------------------------*)
(*   Allocate_Script_Variables --- allocate memory for script variables *)
(*----------------------------------------------------------------------*)

PROCEDURE Allocate_Script_Variables;

VAR
   Var_Mem : INTEGER;
   I       : INTEGER;

BEGIN (* Allocate_Script_Variables *)

                                   (* Make sure calling script's variables *)
                                   (* are accessible.                      *)

   Prev_Script_Variables := Script_Variables;

                                   (* Allocate and clear all script *)
                                   (* variables                     *)

   Var_Mem := ( Script_Variable_Count + 3 ) * SizeOf( Script_Variables^[1] );

   GETMEM( Script_Variables , Var_Mem );

   FOR I := 3 TO Script_Variable_Count DO
      WITH Script_Variables^[I] DO
         BEGIN
            Var_Name   := '';
            Var_Type   := Bad_Operand_Type;
            Var_Value  := NIL;
            Var_Passed := FALSE;
         END;
                                   (* Define special variables        *)

                                   (* Accumulator *)
   WITH Script_Variables^[0] DO
      BEGIN
         Var_Name  := '$ACCUM';
         Var_Type  := Integer_Variable_Type;
         GETMEM( Var_Value , 5 );
         Var_Value^ := CHR( 0 ) + CHR( 0 ) + CHR( 0 ) + CHR( 0 );
         Var_Passed := FALSE;
      END;
                                   (* Local input string *)
   WITH Script_Variables^[1] DO
      BEGIN
         Var_Name  := '$LOCAL';
         Var_Type  := String_Variable_Type;
         GETMEM( Var_Value , 256 );
         Var_Value^ := '';
         Var_Passed := FALSE;
      END;
                                   (* Remote input string *)
   WITH Script_Variables^[2] DO
      BEGIN
         Var_Name  := '$REMOTE';
         Var_Type  := String_Variable_Type;
         GETMEM( Var_Value , 256 );
         Var_Value^ := '';
         Var_Passed := FALSE;
      END;
                                   (* No script parameters yet retrieved *)
   Script_Parameter_Got := 0;
                                   (* No procedure parameters yet retrieved *)
   Proc_Parameter_Got   := 0;

END   (* Allocate_Script_Variables *);

(*----------------------------------------------------------------------*)
(*              Execute_Script --- Begin execution of a script          *)
(*----------------------------------------------------------------------*)

PROCEDURE Execute_Script(     Force_Recompilation : BOOLEAN;
                          VAR Got_Script          : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Execute_Script                                       *)
(*                                                                      *)
(*     Purpose:    Begins execution of a script                         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Execute_Script(     Force_Recompilation: BOOLEAN;             *)
(*                        VAR Got_Script         : BOOLEAN );           *)
(*                                                                      *)
(*           Force_Recompilation --- TRUE to force recompilation        *)
(*           Got_Script --- TRUE if script name entered                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Local_Save_2: Saved_Screen_Ptr;
   I           : INTEGER;
   L           : INTEGER;
   Found       : BOOLEAN;
   Save_Name   : AnyStr;
   Save_Pos    : INTEGER;
   Save_Ptr    : Script_Buffer_Ptr;

BEGIN (* Execute_Script *)
                                   (* Save current screen *)

   Save_Partial_Screen( Local_Save_2, 10, 10, 78, 20 );

                                   (* Get length of name, if any *)
   L := LENGTH( Script_File_Name );

                                   (* Avoid display if called from script *)

   IF ( ( NOT Script_File_Mode ) OR ( L <= 0 ) ) THEN
      Draw_Menu_Frame( 10, 10, 78, 20, Menu_Frame_Color, Menu_Title_Color,
                       Menu_Text_Color, 'Execute Script' );

                                   (* Get script name to execute *)
   IF ( L <= 0 ) THEN
      Get_Script_Name;
                                   (* Quit if null entry *)

   IF ( LENGTH( Script_File_Name ) <= 0 ) OR
      ( Script_File_Name           = CHR( ESC ) ) THEN
      BEGIN
         Got_Script := ( Script_File_Name = CHR( ESC ) );
         Restore_Screen_And_Colors( Local_Save_2 );
         EXIT;
      END
   ELSE
      Got_Script := TRUE;
                                   (* Save script name        *)
   Save_Name := Script_File_Name;
                                   (* Fix up script file name *)

   Script_Short_Name := UpperCase( TRIM( Script_File_Name ) );

   Get_Script_File_Name( Script_Short_Name , Script_File_Name );

                                   (* Save current script stuff *)
   Push_Current_Script;
                                   (* See if requested script is already  *)
                                   (* loaded into memory.  However, we    *)
                                   (* always recompile if any arguments   *)
                                   (* given.                              *)
   Found := FALSE;

   IF ( NOT Force_Recompilation ) THEN
      FOR I := 1 TO Script_Count DO
         IF ( Script_Short_Name = Scripts[I].Script_Name ) THEN
            BEGIN
               Found                  := TRUE;
               Script_Buffer          := Scripts[I].Script_Ptr;
               Script_Buffer_Pos      := 0;
               Really_Wait_String     := FALSE;
               Script_Suspend_Time    := 0;
               Script_File_Mode       := TRUE;
               Current_Script_Num     := I;
               Script_Variable_Count  := Scripts[I].Script_Vars_Count;
               Import_Count           := Scripts[I].Script_Params_Count;
               Got_Script             := TRUE;
            END;
                                   (* Not in memory -- compile it.  *)
   IF ( NOT Found ) THEN
      BEGIN

         Script_File_Name := Save_Name;

         Compile_Script;

         Script_Variable_Count := Script_Variable_MaxKount;

         IF ( NOT Script_File_Mode ) THEN
            BEGIN
               Pop_Current_Script;
               Got_Script := FALSE;
            END;

      END;
                                   (* Check that right number of    *)
                                   (* parameters passed.            *)

   IF Got_Script THEN
      IF Script_File_Mode THEN
         IF ( Import_Count <> Script_Parameter_Count ) THEN
            BEGIN
               Script_File_Mode := FALSE;
               Parse_Error( Script_Short_Name );
               Parse_Error('Wrong number of parameters passed to this script.');
               Press_Any;
               Pop_Current_Script;
               Got_Script := FALSE;
            END;
                                   (* Allocate memory for variables *)
   IF Got_Script THEN
      IF Script_File_Mode THEN
         Allocate_Script_Variables;

                                   (* Restore previous screen *)

   Restore_Screen_And_Colors( Local_Save_2 );

END   (* Execute_Script *);

(*----------------------------------------------------------------------*)
(*                Learn_Script --- Begin script learn mode              *)
(*----------------------------------------------------------------------*)

PROCEDURE Learn_Script;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Learn_Script                                         *)
(*                                                                      *)
(*     Purpose:    Begins script learn mode                             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Learn_Script;                                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Local_Save_2: Saved_Screen_Ptr;
   Ch          : CHAR;
   N           : LongInt;
   NN          : INTEGER;
   SSS         : STRING[10];

BEGIN (* Learn_Script *)
                                   (* Save current screen *)

   Draw_Titled_Box( Local_Save_2, 10, 10, 78, 20, 'Learn Script' );

                                   (* If already learning, just *)
                                   (* close up and return.      *)
   TextColor( Menu_Text_Color_2 );

   IF Script_Learn_Mode THEN
      BEGIN

         Learn_A_Character( CHR( CR ) );

         Script_Learn_Mode := FALSE;

         WRITELN;
         WRITELN('Finished learning ',Saved_Script_File_Name);

            (*!I-*)
         CLOSE( Script_File );
            (*!I+*)

         IF ( Int24Result <> 0 ) THEN
            BEGIN
               WRITELN('*** Error --- problem closing learned script file.');
               WRITELN('*** Check script file contents.');
               Press_Any;
            END;

         Window_Delay;

         Restore_Screen_And_Colors( Local_Save_2 );

         EXIT;

      END;
                                   (* Make sure script not in progress *)
   IF Script_File_Mode THEN
      BEGIN

         WRITELN('*** Error --- Cannot learn script while another');
         WRITELN('*** script is being executed.');
         WRITELN('*** Script learning will not be done.');

         Press_Any;

         Script_Learn_Mode := FALSE;

         Restore_Screen_And_Colors( Local_Save_2 );

         EXIT;

      END;
                                   (* Get script name to learn *)
   Get_Script_Name;
                                   (* Quit if null entry       *)

   IF ( LENGTH( Script_File_Name ) <= 0 ) OR
      ( Script_File_Name = CHR( ESC ) ) THEN
      BEGIN
         Restore_Screen_And_Colors( Local_Save_2 );
         EXIT;
      END;
                                   (* Fix up script file name *)

   Script_Short_Name := UpperCase( Script_File_Name );

   Get_Script_File_Name( Script_Short_Name , Script_File_Name );

   ASSIGN( Script_File , Script_File_Name );
      (*!I-*)
   REWRITE( Script_File );
      (*!I+*)

   Saved_Script_File_Name := '';

   IF ( Int24Result <> 0 ) THEN
      BEGIN
         WRITELN('*** Error --- Cannot open script file for output.');
         WRITELN('*** Script learning will not be done.');
         Press_Any;
      END
   ELSE
      BEGIN

         TextColor( Menu_Text_Color_2 );

         WRITE('Enter maximum length for each WAITSTRING: ');

         TextColor( Menu_Text_Color );

         N := Script_Learn_Buffer_Size;

         IF Read_Number( N , TRUE , N ) THEN
            IF ( N > 0 ) THEN
               BEGIN
                  NN := N;
                  Script_Learn_Buffer_Size := MIN( NN , 255 );
               END;

         WRITELN;

         TextColor( Menu_Text_Color_2 );

         WRITE('Enter maximum lines kept for WAITSTRING: ');

         TextColor( Menu_Text_Color );

         N := Script_Learn_Lines;

         IF Read_Number( N , TRUE , N ) THEN
            BEGIN
               NN := N;
               Script_Learn_Lines := MAX( 1 , NN );
            END;

         TextColor( Menu_Text_Color_2 );

         WRITELN;
         WRITELN;
         WRITELN('Beginning script learn mode.');
         WRITELN;

         Window_Delay;

         Script_Learn_Mode       := TRUE;
         Script_String           := '';
         Script_String_2         := '';
         Saved_Script_File_Name  := Script_File_Name;
         Script_Learn_Line_Count := 0;
         Script_Wait_Generated   := FALSE;
         Script_File_Name        := Script_Short_Name;

      END;

   Restore_Screen_And_Colors( Local_Save_2 );

END   (* Learn_Script *);

(*----------------------------------------------------------------------*)
(*              Unload_Script --- Unload memory-resident script         *)
(*----------------------------------------------------------------------*)

PROCEDURE Unload_Script;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Unload_Script                                        *)
(*                                                                      *)
(*     Purpose:    Unloads stored script                                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Unload_Script;                                                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Local_Save_2: Saved_Screen_Ptr;
   I           : INTEGER;
   IPos        : INTEGER;
   J           : INTEGER;

BEGIN (* Unload_Script *)
                                   (* Save current screen *)

   Draw_Titled_Box( Local_Save_2, 10, 10, 78, 20, 'Unload Script' );

                                   (* Get script name to unload *)
   Get_Script_Name;
                                   (* Quit if null entry *)

   IF LENGTH( Script_File_Name ) <= 0 THEN
      BEGIN
         Restore_Screen_And_Colors( Local_Save_2 );
         EXIT;
      END;
                                   (* Fix up script file name *)

   Script_File_Name := UpperCase( Script_File_Name );

   WRITELN;
                                   (* See if this script in memory. *)
   IPos := 0;

   FOR I := 1 TO Script_Count DO
      IF ( Script_File_Name = Scripts[I].Script_Name ) THEN
         IPos := I;
                                   (* If found, remove it. *)
   IF ( IPos = 0 ) THEN
      WRITELN('Script ', Script_File_Name, ' not found to unload.')
   ELSE
      BEGIN
         MyFreeMem( Scripts[IPos].Script_Ptr , Scripts[IPos].Script_Len );
         FOR J := SUCC( IPos ) TO Script_Count DO
            MOVE( Scripts[J], Scripts[J-1], SizeOf( Scripts[1] ) );
         DEC( Script_Count );
         WRITELN('Script unloaded.');
      END;

   Window_Delay;

   Restore_Screen_And_Colors( Local_Save_2 );

END   (* Unload_Script *);

(*----------------------------------------------------------------------*)
(*           Unload_All_Scripts --- Unload memory-resident script       *)
(*----------------------------------------------------------------------*)

PROCEDURE Unload_All_Scripts;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Unload_All_Scripts                                   *)
(*                                                                      *)
(*     Purpose:    Unloads all stored scripts                           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Unload_All_Scripts;                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Local_Save_2: Saved_Screen_Ptr;
   I           : INTEGER;
   J           : INTEGER;

BEGIN (* Unload_All_Scripts *)
                                   (* Save current screen *)

   Draw_Titled_Box( Local_Save_2, 10, 10, 78, 14, 'Unload All Scripts' );

                                   (* Run over all scripts and unload them *)
   FOR I := 1 TO Script_Count DO
      MyFreeMem( Scripts[I].Script_Ptr , Scripts[I].Script_Len );

   WRITELN( Script_Count, ' scripts unloaded.');

   Script_Count := 0;

   Window_Delay;

   Restore_Screen_And_Colors( Local_Save_2 );

END   (* Unload_All_Scripts *);

