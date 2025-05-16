(*----------------------------------------------------------------------*)
(*                Set_Params --- Set Communications Parameters          *)
(*----------------------------------------------------------------------*)

FUNCTION Set_Params( First_Time : BOOLEAN;
                     Use_Script : BOOLEAN ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:  Set_Params                                            *)
(*                                                                      *)
(*     Purpose:    Set communications parameters                        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Flag := Set_Params( First_Time : BOOLEAN;                     *)
(*                            Use_Script : BOOLEAN ) : BOOLEAN;         *)
(*                                                                      *)
(*           First_Time:  TRUE for initial setup, else FALSE.           *)
(*           Use_Script:  TRUE to use commands from script buffer       *)
(*                                                                      *)
(*           Flag is TRUE if successful set-up, else FALSE.             *)
(*                                                                      *)
(*     Calls:    Async_Init                                             *)
(*               Async_Open                                             *)
(*               Get_Params                                             *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Reset_Attr    : BOOLEAN;
   S             : STRING[10];
   Vid_Mode      : INTEGER;
   Save_Maxl     : INTEGER;
   Save_MaxC     : INTEGER;
   Regs          : Registers;
   EGA_Rows      : INTEGER;
   Save_Rev_Len  : INTEGER;
   Save_Do_Status: BOOLEAN;
   I             : INTEGER;

(*--------------------------------------------------------------------------*)
(*      Read_Config_From_Script --- Read parameters from script buffer      *)
(*--------------------------------------------------------------------------*)

PROCEDURE Read_Config_From_Script;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Read_Config_From_Script                              *)
(*                                                                      *)
(*     Purpose:    Reads parameters from PibTerm script buffer          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Read_Config_From_Script;                                      *)
(*                                                                      *)
(*     Calls:   Get_Config_File_Line_From_Script                        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Ival       : INTEGER;
   OK_To_Read : BOOLEAN;
   I          : INTEGER;
   J          : INTEGER;
   Param_Num  : INTEGER;
   Param_Str  : AnyStr;
   Param_Ival : INTEGER;
   Param_Rval : LONGINT;
   Setting_Val: BOOLEAN;

(*----------------------------------------------------------------------*)
(*   Copy_Script_String --- Copy a string from the script buffer        *)
(*----------------------------------------------------------------------*)

PROCEDURE Copy_Script_String( VAR S: AnyStr; VAR V: INTEGER );

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
   L: INTEGER;

BEGIN (* Copy_Script_String *)
                                   (* Pick up string type *)

   Script_Buffer_Pos := SUCC( Script_Buffer_Pos );
   V                 := Script_Buffer^[Script_Buffer_Pos];

                                   (* Get string value based upon type *)
   CASE V OF

      0:  BEGIN (* Text string *)

             Script_Buffer_Pos := SUCC( Script_Buffer_Pos );

             L := Script_Buffer^[Script_Buffer_Pos];

             MOVE( Script_Buffer^[Script_Buffer_Pos + 1], S[1], L );

             S[0] := CHR( L );

             Script_Buffer_Pos := Script_Buffer_Pos + L;

          END;

      1:  BEGIN (* Local reply string *)
             S := Script_Reply;
          END;

      2:  BEGIN (* Remote reply string *)
             S := Script_Remote_Reply;
          END;

      3:  BEGIN (* Script variable *)
             Script_Buffer_Pos := SUCC( Script_Buffer_Pos );
             V                 := Script_Buffer^[Script_Buffer_Pos];
             S                 := Script_Variables^[V].Var_Value^;
          END   (* Script variable *);

      ELSE
          S := '';
          V := 4;

   END (* CASE *);

END   (* Copy_Script_String *);

(*--------------------------------------------------------------------------*)
(* Get_Config_File_Line_From_Script --- Get one param. line from script     *)
(*--------------------------------------------------------------------------*)

FUNCTION Get_Config_File_Line_From_Script(  VAR Param_Num   : INTEGER;
                                            VAR Param_Str   : AnyStr;
                                            VAR Param_Ival  : INTEGER;
                                            VAR Param_Rval  : LONGINT;
                                            VAR Setting_Val : BOOLEAN
                                          ) : BOOLEAN;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Function:  Get_Config_File_Line_From_Script                          *)
(*                                                                          *)
(*     Purpose:   Reads and interprets one line of script buffer            *)
(*                                                                          *)
(*     Calling Sequence:                                                    *)
(*                                                                          *)
(*        QGot := Get_Config_File_Line_From_Script( VAR Param_Num: INTEGER; *)
(*                                                  VAR Param_Str:  AnyStr; *)
(*                                                  VAR Param_Ival: INTEGER;*)
(*                                                  VAR Param_Rval: LONGINT;*)
(*                                                  VAR Setting_Val:BOOLEAN *)
(*                                                ) : BOOLEAN;              *)
(*                                                                          *)
(*           Param_Num   --- parameter number of this line                  *)
(*           Param_Str   --- string value of parameter                      *)
(*           Param_Ival  --- Integer value of parameter                     *)
(*           Param_Rval  --- Real value of parameter                        *)
(*           Setting_Val --- TRUE to set parameter value, FALSE if          *)
(*                           retrieving it here.                            *)
(*                                                                          *)
(*           Qgot        --- TRUE if configuration line returned;           *)
(*                           FALSE if end-of-buffer encountered on          *)
(*                           script buffer.                                 *)
(*                                                                          *)
(*     Calls:  None                                                         *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   I      : INTEGER;
   J      : INTEGER;
   L      : INTEGER;
   PName  : Char_2;
   NumDone: BOOLEAN;
   S1     : AnyStr;
   Command: Pibterm_Command_Type;

BEGIN (* Get_Config_File_Line_From_Script *)

                                   (* Initialize parameter values *)
   Param_Num   := 0;
   Param_Str   := '';
   Param_Ival  := 0;
   Param_Rval  := 0;
   Setting_Val := FALSE;
                                   (* Move to next slot in script *)

   Script_Buffer_Pos := SUCC( Script_Buffer_Pos );

                                   (* See if it's ParamSy or SetParamSy *)

   I       := Script_Buffer^[Script_Buffer_Pos];
   Command := PibTerm_Command_Table_2[ I ];

   IF ( ( Command = ParamSy    ) OR
        ( Command = GetParamSy ) OR
        ( Command = SetParamSy ) )   THEN
      BEGIN

         Get_Config_File_Line_From_Script := TRUE;

         CASE Command OF

            ParamSy :    BEGIN

                            Script_Buffer_Pos := SUCC( Script_Buffer_Pos );

                            J                 := Script_Buffer_Pos;
                            PName[1]          := UpCase( CHR( Script_Buffer^[J]   ) );
                            PName[2]          := UpCase( CHR( Script_Buffer^[J+1] ) );

                            L                 := Script_Buffer^[J+2];
                            Script_Buffer_Pos := J + 2;

                            FOR J := 1 TO L DO
                               BEGIN
                                  Script_Buffer_Pos := SUCC( Script_Buffer_Pos );
                                  Param_Str         := Param_Str +
                                                       CHR( Script_Buffer^[Script_Buffer_Pos] );
                               END;

                            S1 := 'Set parameter ' + PName +
                                  ' to ' + Param_Str;

                            Write_Log( S1 , TRUE , FALSE );

                         END;

            GetParamSy,
            SetParamSy : BEGIN
                            Copy_Script_String( S1 , J );
                            PName := '  ';
                            FOR J := 1 TO MIN( LENGTH( S1 ) , 2 ) DO
                               PName[J] := UpCase( S1[J] );
                            Copy_Script_String( Param_Str , J );
                         END;

         END (* CASE *);
                                   (* Search for parameter *)

         Param_Num := Look_Up_Parameter( PName );

                                   (* If found, convert to numeric if *)
                                   (* appropriate                     *)

         IF ( Param_Num > 0 ) THEN
            IF Command = GetParamSy THEN
               BEGIN

                  Get_Parameter( Param_Num , Param_Str );

                  Script_Variables^[J].Var_Value^ := Param_Str;
{
                  IF Debug_Mode THEN
                     WRITELN('Get_Params: PName = ' + S1 + ', # = ' +
                               IToS( Param_Num ) + ' = <' +
                               Param_Str + '>; Var = ' +
                               IToS( J ) );
}
               END
            ELSE
               BEGIN

                  Setting_Val := TRUE;

                  L       := LENGTH( Param_Str );
                  NumDone := ( L = 0 );
                  I       := 0;

                  WHILE ( NOT NumDone ) DO
                     BEGIN
                        I := SUCC( I );
                        IF Param_Str[I] IN ['0'..'9'] THEN
                           Param_Ival := Param_Ival * 10 +
                                         ORD( Param_Str[I] ) - ORD( '0' );
                        NumDone := NumDone OR ( I >= L ) OR
                                   ( Param_Str[I] = ' ');
                     END;

                  IF ( L > 0 ) THEN
                     IF ( UpCase( Param_Str[1] ) = 'Y' ) THEN
                        Param_Ival := 1;

                  Param_Rval := Param_Ival;

               END

         ELSE
            IF ( Command = GetParamSy ) THEN
               Script_Variables^[J].Var_Value^ := '';

      END

   ELSE
      BEGIN
         Get_Config_File_Line_From_Script := FALSE;
         Script_Buffer_Pos                := PRED( Script_Buffer_Pos );
      END;

END   (* Get_Config_File_Line_From_Script *);

(*--------------------------------------------------------------------------*)

BEGIN (* Read_Config_From_Script *)

                                   (* Point to 'Paramsy' entry *)

   Script_Buffer_Pos := PRED( Script_Buffer_Pos );

                                   (* Pick up all get/set parameter entries *)

   WHILE( Get_Config_File_Line_From_Script( Param_Num, Param_Str, Param_Ival,
                                            Param_Rval, Setting_Val ) ) DO
      IF Setting_Val THEN
         Set_Parameter( Param_Num, Param_Ival, Param_Rval, Param_Str );

END   (* Read_Config_From_Script *);

(*----------------------------------------------------------------------*)
(*                    Set_Params --- Main code body                     *)
(*----------------------------------------------------------------------*)

BEGIN (* Set_Params *)
                                   (* Don't reset port unless needed *)
   Reset_Comm_Port        := FALSE;

                                   (* If comm port changes *)
   Comm_Port_Changed      := FALSE;

                                   (* If keyboard interrupt changes *)
   Kbd_Interrupt_Change   := FALSE;

                                   (* If video interrupt changes    *)
   Video_Interrupt_Change := FALSE;

                                   (* Remember current colors *)

   New_ForeGround_Color  := ForeGround_Color;
   New_BackGround_Color  := BackGround_Color;
   New_Menu_Text_Color   := Menu_Text_Color;
   New_Menu_Title_Color  := Menu_Title_Color;
   New_Menu_Text_Color_2 := Menu_Text_Color_2;
   New_Menu_Frame_Color  := Menu_Frame_Color;
   New_Border_Color      := Border_Color;

                                   (* Remember current screen size *)

   New_Max_Screen_Line   := Max_Screen_Line;
   New_Max_Screen_Col    := Max_Screen_Col;
   Save_Maxl             := Max_Screen_Line;
   Save_MaxC             := Max_Screen_Col;

                                   (* Remember current text mode *)
   New_Text_Mode         := Text_Mode;

                                   (* Remember current terminal  *)

   IF ( Terminal_To_Emulate <> Gossip ) THEN
      Saved_Gossip_Term := Terminal_To_Emulate;

                                   (* Remember review buffer length *)

   Save_Rev_Len := Max_Review_Length;

                                   (* Get parameter values      *)
   IF( NOT First_Time ) THEN
      IF ( NOT Use_Script ) THEN
         Get_Default_Params( FALSE )
      ELSE
         Read_Config_From_Script;

                                   (* Initialize Comm Variables *)

   IF ( First_Time OR Comm_Port_Changed OR ( Cmd_Line_Port > 0 ) ) THEN
      BEGIN
                                   (* Set up com port hardware addresses *)

         FOR I := 1 TO MaxComPorts DO
            Async_Setup_Port( I,
                              Default_Com_Base[I],
                              Default_Com_Irq [I],
                              Default_Com_Int [I] );

                                   (* Set up buffers *)

         Async_Init( Async_Buffer_Length, Async_OBuffer_Length, 0, 0, 0 );

                                   (* If a command line port override *)
                                   (* exists, use it.                 *)

         IF ( Cmd_Line_Port > 0 ) THEN
            BEGIN
               Comm_Port     := Cmd_Line_Port;
               Cmd_Line_Port := 0;
            END;
                                   (* Check if space found for buffers *)

         IF ( ( Async_Buffer_Ptr = NIL ) OR ( Async_OBuffer_Ptr = NIL ) ) THEN
            Set_Params := FALSE

                                   (* Open Communications Port  *)
         ELSE
            Set_Params := Async_Open( Comm_Port, Baud_Rate, Parity, Data_Bits,
                                      Stop_Bits );

      END
   ELSE
      BEGIN
                                   (* Not 1st time, same port -- *)
                                   (* reset open port            *)
         Set_Params := TRUE;

         IF Reset_Comm_Port THEN
            Async_Reset_Port( Comm_Port, Baud_Rate, Parity, Data_Bits,
                              Stop_Bits );

      END;
                                   (* Change text mode, colors      *)

   IF Text_Mode <> New_Text_Mode THEN
      BEGIN
         Text_Mode := New_Text_Mode;
         TextMode( Text_Mode );
      END;
                                   (* Reset CTS check on/off        *)
   Async_Do_CTS := Check_CTS;
                                   (* Reset DSR check on/off        *)
   Async_Do_DSR := Check_DSR;
                                   (* Reset XON/XOFF check on/off   *)

   Async_Do_XonXoff := Do_Xon_Xoff_Checks;
   Async_OV_XonXoff := Do_Xon_XOff_Checks;

                                   (* Reset hard-wired status       *)

   Async_Hard_Wired_On := Hard_Wired;

                                   (* Reset break length            *)

   Async_Break_Length := Break_Length;

                                   (* Reset colors                  *)

   Reset_Attr        := ( ForeGround_Color <> New_ForeGround_Color ) OR
                        ( BackGround_Color <> New_BackGround_Color ) OR
                        ( Save_Maxl        <> Max_Screen_Line      ) OR
                        ( Save_MaxC        <> Max_Screen_Col       );

   ForeGround_Color  := New_ForeGround_Color;
   BackGround_Color  := New_BackGround_Color;
   Menu_Text_Color   := New_Menu_Text_Color;
   Menu_Title_Color  := New_Menu_Title_Color;
   Menu_Text_Color_2 := New_Menu_Text_Color_2;
   Menu_Frame_Color  := New_Menu_Frame_Color;
   Border_Color      := New_Border_Color;

   Set_Global_Colors( ForeGround_Color , BackGround_Color );

   Vid_Mode := Current_Video_Mode;
   IF ( Vid_Mode < MedRes_GraphMode ) OR ( Vid_Mode = Mono_TextMode ) THEN
      Set_Border_Color ( Border_Color );

                                   (* Update wait-for-retrace option *)

   Wait_For_Retrace := Wait_For_Retrace_Par AND
                       ( NOT ( EGA_Present OR ( Vid_Mode = 7 ) ) );

                                   (* Set write to screen mode *)

   Write_Screen_Memory := Write_Screen_Memory_Par (* OR TimeSharingActive *);

                                   (* Ensure proper screen length *)

   Max_Screen_Line   := New_Max_Screen_Line;
   Max_Screen_Col    := New_Max_Screen_Col;

   IF Do_Status_Line THEN
      Last_Line_To_Set := PRED( Max_Screen_Line )
   ELSE
      Last_Line_To_Set := Max_Screen_Line;

   Save_Do_Status := Do_Status_Line;
   Do_Status_Line := FALSE;
                                   (* Reset screen size *)

   IF ( ( Max_Screen_Line <> Save_MaxL ) OR
        ( Max_Screen_Col  <> Save_MaxC ) ) THEN
      BEGIN
         IF ( ATI_Ega_Wonder AND ( Max_Screen_Col <> Save_MaxC ) ) THEN
            BEGIN
               CASE Max_Screen_Col OF
                  132: BEGIN
                          Regs.AX := $23;
                          INTR( $10, Regs );
                       END;
                  ELSE BEGIN
                          Regs.AX := $03;
                          INTR( $10, Regs );
                       END;
               END (* CASE *);
            END (* BEGIN *);
         PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line );
      END;
                                   (* Reset if new # lines and EGA/VGA *)

   IF EGA_Present THEN
      BEGIN
                                   (* Get # of rows in current display *)
         Regs.AH := $11;
         Regs.AL := $30;
         Regs.BH := 0;

         INTR( $10 , Regs );

         IF ( Max_Screen_Line <> SUCC( Regs.DL ) ) THEN
            BEGIN
               Set_EGA_Text_Mode( Max_Screen_Line );
               Scroll( 1, Max_Screen_Line, 1, Max_Screen_Col, 0,
                       ForeGround_Color, BackGround_Color );
               PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line );
            END;

      END;
                                   (* Reset attributes *)
   IF Reset_Attr THEN
      Set_Text_Attributes( 1, 1, Max_Screen_Col, Last_Line_To_Set,
                           ForeGround_Color, BackGround_Color );

                                   (* Make sure gossip mode set properly *)

   Gossip_Mode_On := ( Terminal_To_Emulate = Gossip );

                                   (* Fixup keyboard handler if needed   *)
   IF Kbd_Interrupt_Change THEN
      IF Extended_Keypad THEN
         Install_Keyboard_Handler
      ELSE
         Remove_Keyboard_Handler;

                                   (* Update software_scrolling option *)

   Software_Scroll := Software_Scroll_Par AND {Wait_For_Retrace AND}
                      Write_Screen_Memory AND ( NOT TimeSharingActive );

                                   (* Fixup video handler if needed      *)
   IF Video_Interrupt_Change THEN
      IF ( NOT Video_Handler_Installed ) THEN
         Install_Video_Handler
      ELSE
         Remove_Video_Handler;

   Wrap_Screen_Col := Max_Screen_Col;

                                   (* Fix review buffer if needed *)

   IF ( Save_Rev_Len <> Max_Review_Length ) THEN
      BEGIN

         IF ( Save_Rev_Len > 0 ) AND ( Review_Buffer <> NIL ) THEN
            BEGIN
               MyFreeMem( Review_Buffer , Save_Rev_Len );
               Review_Buffer := NIL;
            END;

         IF ( Max_Review_Length > ( MaxAvail - 8000 ) ) THEN
            Max_Review_Length := MAX( 0 , ( MaxAvail - 8000 ) );

         Review_On := ( Max_Review_Length > 0 );

         IF Review_On THEN
            GetMem( Review_Buffer , Max_Review_Length );

         Review_On        := Review_On AND ( Review_Buffer <> NIL );

         Review_Head      := 0;
         Review_Tail      := 0;
         Review_Line      := '';

     END;
                                   (* Restore status line display *)

   Do_Status_Line := Save_Do_Status;

                                   (* Open/close logging file *)
   IF Logging_On THEN
      IF ( NOT Log_File_Open ) THEN
         Log_File_Open := Open_For_Append( Log_File,
                                           Log_File_Name, I );

END   (* Set_Params *);

