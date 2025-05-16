(*--------------------------------------------------------------------------*)
(*           Look_Up_Parameter --- See if parameter name found              *)
(*--------------------------------------------------------------------------*)

FUNCTION Look_Up_Parameter( PName : Char_2 ) : INTEGER;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Function:  Look_Up_Parameter                                         *)
(*                                                                          *)
(*     Purpose:   Looks up parameter name in parameter name list            *)
(*                                                                          *)
(*     Calling Sequence:                                                    *)
(*                                                                          *)
(*        Param_Num := Look_Up_Parameter( PName: Char_2 ) : INTEGER;        *)
(*                                                                          *)
(*           PName      --- parameter name to look up                       *)
(*           Param_Num  --- parameter number of this line                   *)
(*                                                                          *)
(*     Calls:  None                                                         *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   Hi        : INTEGER;
   Lo        : INTEGER;
   Mid       : INTEGER;
   Param_Num : INTEGER;

BEGIN (* Look_Up_Parameter *)

   Hi        := Max_Param_Names;
   Lo        := 1;
   Param_Num := 0;

   REPEAT

      Mid := ( Lo + Hi ) DIV 2;

      IF ( PName = Parameters[Mid].PName ) THEN
         BEGIN
            Param_Num := Mid;
            Lo        := SUCC( Hi );
         END

      ELSE IF ( PName < Parameters[Mid].PName ) THEN
         Hi := PRED( Mid )
      ELSE
         Lo := SUCC( Mid );

   UNTIL( Lo > Hi );

   Look_Up_Parameter := Param_Num;

END   (* Look_Up_Parameter *);

(*----------------------------------------------------------------------*)
(*         Set_Parameter --- Set value of PibTerm parameter             *)
(*----------------------------------------------------------------------*)

PROCEDURE Set_Parameter( Param_Num  : INTEGER;
                         Param_Ival : INTEGER;
                         Param_Rval : LONGINT;
                         Param_Str  : AnyStr   );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  SetÿParameter                                        *)
(*                                                                      *)
(*     Purpose:    Set value of PibTerm parameter                       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Set_Parameter( Param_Num  : INTEGER;                          *)
(*                       Param_Ival : INTEGER;                          *)
(*                       Param_Rval : LONGINT;                          *)
(*                       Param_Str  : AnyStr   );                       *)
(*                                                                      *)
(*           Param_Num  --- Parameter to set                            *)
(*           Param_Ival --- integer parameter value                     *)
(*           Param_Rval --- real parameter value                        *)
(*           Param_Str  --- string parameter value                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I      : INTEGER;
   IWord  : WORD;
   Ch2    : STRING[2];
   P_Ptr  : POINTER;
   P_IPtr : Param_IPtr_Type ABSOLUTE P_Ptr;
   P_XPtr : Param_XPtr_Type ABSOLUTE P_Ptr;
   P_SPtr : Param_SPtr_Type ABSOLUTE P_Ptr;
   P_CPtr : Param_CPtr_Type ABSOLUTE P_Ptr;
   P_LPtr : Param_LPtr_Type ABSOLUTE P_Ptr;
   P_BPtr : Param_BPtr_Type ABSOLUTE P_Ptr;
   P_TPtr : Param_TPtr_Type ABSOLUTE P_Ptr;
   P_FPtr : Param_FPtr_Type ABSOLUTE P_Ptr;
   P_DPtr : Param_DPtr_Type ABSOLUTE P_Ptr;
   P_OPtr : Param_OPtr_Type ABSOLUTE P_Ptr;
   P_WPtr : Param_WPtr_Type ABSOLUTE P_Ptr;

(*----------------------------------------------------------------------*)
(*         Copy_First_Char --- Set value to first char of string        *)
(*----------------------------------------------------------------------*)

FUNCTION Copy_First_Char : CHAR;

VAR
   T: AnyStr;

BEGIN (* Copy_First_Char *)

   T := Read_Ctrls( Param_Str );

   IF ( LENGTH( T ) > 0 ) THEN
      Copy_First_Char := T[1]
   ELSE
      Copy_First_Char := ' ';

END   (* Copy_First_Char *);

(*----------------------------------------------------------------------*)
(*              Set_To_Color  --- Set value to legitimate color         *)
(*----------------------------------------------------------------------*)

FUNCTION Set_To_Color : INTEGER;

BEGIN (* Set_To_Color *)

   Set_To_Color := MAX( MIN( Param_Ival , 15 ) , 0 );

END   (* Set_To_Color *);

(*----------------------------------------------------------------------*)
(*              Set_Path --- Set value to fixed-up pathname             *)
(*----------------------------------------------------------------------*)

FUNCTION Set_Path : AnyStr;

BEGIN (* Set_Path *)

   IF ( LENGTH( Param_Str ) > 0 ) THEN
      IF ( Param_Str[ LENGTH( Param_Str ) ] <> '\' ) THEN
         Param_Str := Param_Str + '\';

   Set_Path := Param_Str;

END   (* Set_Path *);

(*----------------------------------------------------------------------*)
(*              Get_Hex --- Get hexadecimal value from string           *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Hex( VAR Integr : WORD );

VAR
   I: INTEGER;

BEGIN (* Get_Hex *)

   I := Hex_To_Dec( Param_Str , -1 );

   IF ( I <> -1 ) THEN
      Integr := I;

END   (* Get_Hex *);

(*----------------------------------------------------------------------*)
(*    Parse_Protocol_Definition --- Parse protocol definition           *)
(*----------------------------------------------------------------------*)

PROCEDURE Parse_Protocol_Definition;

VAR
   PName  : String12;
   PAbbr  : String12;
   Batch  : String12;
   HostOK : String12;
   RName  : String12;
   SName  : String12;
   I      : INTEGER;
   L      : INTEGER;
   T      : Transfer_Type;
   IProt  : INTEGER;
   Ch     : CHAR;

(*----------------------------------------------------------------------*)

PROCEDURE SkipBl;

BEGIN (* SkipBl *)

   WHILE( ( I < L ) AND ( Param_Str[I] = ' ' ) ) DO
      INC( I );

END   (* SkipBl *);

(*----------------------------------------------------------------------*)

PROCEDURE SkipToBl;

BEGIN (* SkipToBl *)

   WHILE( ( I < L ) AND ( Param_Str[I] <> ' ' ) ) DO
      INC( I );

END   (* SkipToBl *);

(*----------------------------------------------------------------------*)

PROCEDURE CopyStr( VAR S : String12; MaxLen : INTEGER );

VAR
   K: INTEGER;

BEGIN (* CopyStr *)

   SkipBl;

   K := 0;

   WHILE( ( K <= MaxLen ) AND ( Param_Str[I] <> ' ' ) ) DO
      BEGIN
         S := S + Param_Str[I];
         INC( I );
         INC( K );
      END;

   SkipToBl;

END   (* CopyStr *);

(*----------------------------------------------------------------------*)

BEGIN (* Parse_Protocol_Definition *)

                                   (* Set defaults *)

   Param_Str := LTrim( Param_Str );
   P_SPtr^   := Param_Str;

   PName     := '';
   PAbbr     := '  ';
   Batch     := '';
   RName     := '';
   SName     := '';
   HostOK    := '';
                                   (* Quit if null definition *)

   IF ( LENGTH( Param_Str ) = 0 ) THEN EXIT;

   Param_Str := Param_Str + '  ';
                                   (* Get abbreviation *)

   PAbbr[1]  := UpCase( Param_Str[1] );
   PAbbr[2]  := UpCase( Param_Str[2] );

   I         := 3;
   L         := LENGTH( Param_Str );

                                   (* Get long name    *)
   CopyStr( PName , 12 );
                                   (* Get batch type   *)
   CopyStr( Batch , 1  );

   IF ( Batch <> '' ) THEN
      Batch[1] := UpCase( Batch[1] )
   ELSE
      Batch[1] := ' ';
                                   (* Get host/terminal mode *)
   CopyStr( HostOK , 1  );

   IF ( HostOK <> '' ) THEN
      HostOK[1] := UpCase( HostOK[1] )
   ELSE
      HostOK[1] := 'T';
                                   (* Get receive script name *)
   CopyStr( RName , 12 );

   IF ( RName = '*' ) THEN
      RName := '';
                                   (* Get send script name *)
   CopyStr( SName , 12 );

   IF ( SName = '*' ) THEN
      SName := '';
                                   (* Find slot *)

   IProt := Param_Num - Look_Up_Parameter( 'F0' ) + ORD( PUser1 );

                                   (* Found slot -- insert protocol    *)
                                   (* information.                     *)
   T := Transfers[SUCC(IProt)];

   CopyS2AR( PName, Transfer_Name_List[SUCC(IProt)][1], 12 );

   Transfer_Name_List[SUCC(IProt)][0] := CHR( 12 );

   Trans_Type_Name[T][1]     := PAbbr[1];
   Trans_Type_Name[T][2]     := PAbbr[2];
   Single_File_Protocol[T]   := ( Batch[1]  = 'S' );
   Trans_OK_In_Host[T]       := ( HostOK[1] = 'H' );
   Receive_Script_Names[T]   := RName;
   Send_Script_Names[T]      := SName;

END   (* Parse_Protocol_Definition *);

(*----------------------------------------------------------------------*)

BEGIN (* Set_Parameter *)
                                   (* If not legal parameter number, quit *)

   IF ( ( Param_Num < 1 ) OR ( Param_Num > Max_Param_Names ) ) THEN EXIT;

                                   (* Get parameter address *)

   P_Ptr := Parameters[Param_Num].PAddr;

                                   (* Convert parameter value to string *)

   CASE Parameters[Param_Num].PType OF

      PosInt_Param  : IF ( Param_Rval <= 0 ) THEN
                         P_IPtr^ := 0
                      ELSE IF ( Param_Rval >= 32767 ) THEN
                         P_IPtr^ := 32767
                      ELSE
                         P_IPtr^ := Param_Rval;

      BColor_Param,
      Color_Param   : P_IPtr^ := Set_To_Color;

      String_Param  : P_SPtr^ := Read_Ctrls( Param_Str );

      Path_Param    : P_SPtr^ := Set_Path;

      Box_Param     : IF LENGTH( Param_Str ) > 0 THEN
                         BEGIN
                            Box_Chars := Param_Str + DUPL(' ' , 8 - LENGTH( Param_Str ) );
                            WITH Menu_Box_Chars DO
                               BEGIN
                                  Top_Left_Corner     := Box_Chars[1];
                                  Top_Line            := Box_Chars[2];
                                  Top_Right_Corner    := Box_Chars[3];
                                  Right_Line          := Box_Chars[4];
                                  Bottom_Right_Corner := Box_Chars[5];
                                  Bottom_Line         := Box_Chars[6];
                                  Bottom_Left_Corner  := Box_Chars[7];
                                  Left_Line           := Box_Chars[8];
                              END;
                         END;

      VidMode_Param : CASE Param_Str[1] OF
                         'C': New_Text_Mode   := C80;
                         'M': New_Text_Mode   := Mono;
                         ELSE New_Text_Mode   := BW80;
                      END;

      KCheck_Param,
      Char_Param    : IF ( LENGTH( Param_Str ) > 0 ) THEN
                         P_CPtr^ := Param_Str[1]
                      ELSE
                         P_CPtr^ := ' ';

      SpecChar_Param: P_CPtr^ := Copy_First_Char;

      LongInt_Param : P_XPtr^ := Param_RVal;

      Boolean_Param : P_LPtr^ := ( Param_IVal = 1 );

      Byte_Param    : P_BPtr^ := Param_IVal;

      Transfer_Param: BEGIN
                         CH2 := UpCase( Param_Str[1] ) +
                                UpCase( Param_Str[2] );
                         IF ( CH2 = '  ' ) THEN
                            Default_Transfer_Type := Xmodem_CRC
                         ELSE
                            BEGIN
                               FOR I := 1 TO Max_Transfer_Types DO
                                  IF ( CH2 = Trans_Type_Name[Transfers[I]] ) THEN
                                     Default_Transfer_Type := Transfers[I];
                               IF ( CH2 = 'YM' ) THEN
                                  Default_Transfer_Type := Xmodem_1K;
                            END;
                      END;

      Terminal_Param: IF ( ( Param_Ival >= 0 ) AND ( Param_Ival <= NumberTerminalTypes ) ) THEN
                         Terminal_To_Emulate := Terminal_Type_List[ Param_Ival ]
                      ELSE
                         Terminal_To_Emulate := DUMB;

      Date_Param    : BEGIN
                         Param_Str := UpperCase( Param_Str );
                         IF ( Param_Str = 'YMD' ) THEN
                            Date_Format := YMD_Style
                         ELSE IF ( Param_Str = 'MDY' ) THEN
                            Date_Format := MDY_Style
                         ELSE IF ( Param_Str = 'DMY' ) THEN
                            Date_Format := DMY_Style;
                      END;

      Time_Param   :  BEGIN
                         Param_Str := UpperCase( Param_Str );
                         IF Param_Str = 'AMPM' THEN
                            Time_Format := AMPM_Time
                         ELSE IF Param_Str = 'MILITARY' THEN
                            Time_Format := Military_Time;
                         Use_Military := ( Time_Format = Military_Time );
                      END;

      ScrOrder_Param: CASE Param_Ival OF
                         0: Script_Search_Order := Dir_Then_Lib;
                         1: Script_Search_Order := Lib_Then_Dir;
                         2: Script_Search_Order := Dir_Only;
                         3: Script_Search_Order := Lib_Only;
                         ELSE
                            Script_Search_Order := Dir_Then_Lib;
                      END (* CASE *);

      Hexi_Param    : BEGIN
                         Get_Hex( IWord );
                         P_WPtr^ := IWord;
                      END;

      Word_Param    : P_WPtr^ := Param_RVal;

      ExtTrans_Param: Parse_Protocol_Definition;

      Integer_Param : IF ( Param_Rval < -32768 ) THEN
                         P_IPtr^ := -32768
                      ELSE IF ( Param_Rval >= 32767 ) THEN
                         P_IPtr^ := 32767
                      ELSE
                         P_IPtr^ := Param_Rval;

      ELSE          ;

   END (* CASE *);

   IF Silent_Mode THEN Play_Music_On := FALSE;
   Menu_Set_Beep( NOT Silent_Mode );

   Reset_Comm_Port := TRUE;

END   (* Set_Parameter *);
