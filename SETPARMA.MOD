(*----------------------------------------------------------------------*)
(*        Get_Default_Params --- Set Communications Parameters          *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Default_Params( First_Time : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_Default_Params                                   *)
(*                                                                      *)
(*     Purpose:    Set communications parameters                        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_Default_Params( First_Time : BOOLEAN );                   *)
(*                                                                      *)
(*           First_Time:  TRUE for initial setup, else FALSE.           *)
(*                                                                      *)
(*     Calls:    Async_Init                                             *)
(*               Async_Open                                             *)
(*               Menu_Get_Choice                                        *)
(*               Menu_Display_Choices                                   *)
(*                                                                      *)
(*      Remarks:                                                        *)
(*                                                                      *)
(*         This routine is called if PIBTERM.CNF doesn't exist,         *)
(*         or to update communications parameters.                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   Quit_Item       = 13;

VAR
   Config_File     : Text_File;

VAR
   Settings_Menu   : Menu_Type;
   Settings_Choice : INTEGER;
   I               : INTEGER;
   J               : INTEGER;

(* STRUCTURED *) CONST
   Colon_Str     : STRING[ 2] = ': ';
   Enter_Str     : STRING[ 6] = 'Enter ';
   Currently_Str : STRING[11] = 'Currently: ';
   Arrow_Str     : STRING[ 5] = ' --> ';

TYPE
   PNums_Vector  = ARRAY[1..25] OF INTEGER;

VAR
                                   (* Parameter types                    *)

   Param_Types : ARRAY[1..25] OF Param_Type;

                                   (* Pointers to parameter addresses    *)

   Param_IPtrs : ARRAY[1..25] OF Param_IPtr_Type;
   Param_XPtrs : ARRAY[1..25] OF Param_XPtr_Type ABSOLUTE Param_IPtrs;
   Param_SPtrs : ARRAY[1..25] OF Param_SPtr_Type ABSOLUTE Param_IPtrs;
   Param_CPtrs : ARRAY[1..25] OF Param_CPtr_Type ABSOLUTE Param_IPtrs;
   Param_LPtrs : ARRAY[1..25] OF Param_LPtr_Type ABSOLUTE Param_IPtrs;
   Param_BPtrs : ARRAY[1..25] OF Param_BPtr_Type ABSOLUTE Param_IPtrs;
   Param_TPtrs : ARRAY[1..25] OF Param_TPtr_Type ABSOLUTE Param_IPtrs;
   Param_FPtrs : ARRAY[1..25] OF Param_FPtr_Type ABSOLUTE Param_IPtrs;
   Param_DPtrs : ARRAY[1..25] OF Param_DPtr_Type ABSOLUTE Param_IPtrs;
   Param_OPtrs : ARRAY[1..25] OF Param_OPtr_Type ABSOLUTE Param_IPtrs;
   Param_WPtrs : ARRAY[1..25] OF Param_WPtr_Type ABSOLUTE Param_IPtrs;

                                   (* Pointers to parameter descriptions *)

   Param_Desc  : ARRAY[1..25] OF StringPtr;

                                   (* Parameter numbers *)

   Param_Nums  : PNums_Vector;

   Param_Count : INTEGER           (* Parameter count                    *);
   Param_ValCol: INTEGER           (* Column at which value is displayed *);
   Null_Guy    : INTEGER           (* For null parameter definitions     *);

(* STRUCTURED *) CONST
   Int_Param  : Param_Type = Integer_Param;
   PInt_Param : Param_Type = PosInt_Param;
   Wor_Param  : Param_Type = Word_Param;
   Str_Param  : Param_Type = String_Param;
   Chr_Param  : Param_Type = Char_Param;
   Lin_Param  : Param_Type = LongInt_Param;
   Bol_Param  : Param_Type = Boolean_Param;
   Byt_Param  : Param_Type = Byte_Param;
   Pat_Param  : Param_Type = Path_Param;
   Tra_Param  : Param_Type = Transfer_Param;
   Dat_Param  : Param_Type = Date_Param;
   Scr_Param  : Param_Type = ScrOrder_Param;
   Col_Param  : Param_Type = Color_Param;
   BCol_Param : Param_Type = BColor_Param;
   Vid_Param  : Param_Type = VidMode_Param;
   Ter_Param  : Param_Type = Terminal_Param;
   Hex_Param  : Param_Type = Hexi_Param;
   Nul_Param  : Param_Type = Null_Param;

(* STRUCTURED *) CONST
   Date_Formats : ARRAY[1..3] OF STRING[8] =
                  ( 'MM/DD/YY', 'YY/MM/DD', 'DD/MM/YY' );

   Date_Modes   : ARRAY[1..3] OF Date_Format_Type =
                  (  MDY_Style,  YMD_Style,  DMY_Style );

(* STRUCTURED *) CONST
   Lib_Search      : ARRAY[1..4] OF STRING[22] =
                     ( 'Directory then library', 'Library then directory',
                       'Directory only', 'Library only' );

   Lib_Search_Mode : ARRAY[1..4] OF Script_Search_Order_Type =
                     ( Dir_Then_Lib, Lib_Then_Dir, Dir_Only, Lib_Only );

(* STRUCTURED *) CONST
   Colors : ARRAY[0..15] OF STRING[12] =
            ( 'Black       ', 'Blue        ', 'Green       ',
              'Cyan        ', 'Red         ', 'Magenta     ',
              'Brown       ', 'LightGray   ', 'DarkGray    ',
              'LightBlue   ', 'LightGreen  ', 'LightCyan   ',
              'LightRed    ', 'LightMagenta', 'Yellow      ',
              'White       ' );

PROCEDURE Get_General_Setup( Menu_String : AnyStr;
                             Menu_Title  : AnyStr;
                             Post_Proc   : CHAR    );
   FORWARD;

FUNCTION Get_Item_Choice : INTEGER;
   FORWARD;

PROCEDURE Define_Param_For_Display( PName : Char_2 );
   FORWARD;

PROCEDURE File_Post_Processor( Menu_Item : INTEGER );
   FORWARD;

PROCEDURE Input_Post_Processor( Menu_Item : INTEGER );
   FORWARD;

PROCEDURE Kermit_Post_Processor( Menu_Item : INTEGER );
   FORWARD;

PROCEDURE Modem_Post_Processor( Menu_Item : INTEGER );
   FORWARD;

(*----------------------------------------------------------------------*)
(*                 Get_A_Color --- Get a color variable                 *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_A_Color(      Color_Title   : AnyStr;
                            Default_Color : INTEGER;
                            Short_Menu    : BOOLEAN;
                        VAR The_Color     : INTEGER );

VAR
   Color_Menu  : Menu_Type;
   I           : INTEGER;
   J           : INTEGER;
   Block_Chars : STRING[5];
   Menu_Size   : INTEGER;

BEGIN (* Get_A_Color *)
                                   (* Set up color menu *)
   IF Short_Menu THEN
      Menu_Size := 8
   ELSE
      Menu_Size := 16;

   INC( Default_Color );
   IF ( Default_Color > Menu_Size ) THEN
      Default_Color := 1;

   Make_A_Menu( Color_Menu, Menu_Size, 6, 50, 29, 0,
                Default_Color,
                Color_Title,
                'Black;Blue;Green;Cyan;Red;Magenta;Brown;LightGray;' +
                'DarkGray;LightBlue;LightGreen;LightCyan;LightRed;'  +
                'LightMagenta;Yellow;White;',
                TRUE );

   Menu_Display_Choices( Color_Menu );

   Block_Chars := DUPL( CHR( 219 ) , 5 );

   FOR J := 0 TO PRED( Menu_Size ) DO
      WriteSXY( Block_Chars, 72, ( J + 6 ), J );

   I := Menu_Get_Choice( Color_Menu, TRUE );

                                   (* If selected color legitimate, *)
                                   (* return it.                    *)
   IF ( I > 0 ) THEN
      The_Color := PRED( I );

END   (* Get_A_Color *);

(*----------------------------------------------------------------------*)
(*                Get_Video_Mode --- Get video mode                     *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Video_Mode;

VAR
   Video_Menu   : Menu_Type;
   I            : INTEGER;
   J            : INTEGER;
   Default      : INTEGER;

BEGIN (* Get_Video_Mode *)
                                   (* Get video mode *)
   CASE Text_Mode OF
      Mono : Default := 1;
      BW80 : Default := 2;
      ELSE   Default := 3;
   END (* CASE *);
                                   (* Display menu and get choice *)

   Make_And_Display_Menu( Video_Menu, 3, 10, 54, 0, 0, Default,
                          'Choose Text Mode: ',
                          'Monochrome;Black and White;Color;',
                          FALSE, TRUE, I );

   CASE I OF
      1:   New_Text_Mode := Mono;
      2:   New_Text_Mode := BW80;
      3:   New_Text_Mode := C80;
      ELSE New_Text_Mode := Text_Mode;
   END (* CASE *);
                                   (* Monochrome -- all colors *)
                                   (* become black and white   *)
   IF ( ( New_Text_Mode = BW80 ) OR
        ( New_Text_Mode = Mono ) ) THEN
      BEGIN

         New_ForeGround_Color   := White;
         New_BackGround_Color   := Black;
         New_Menu_Text_Color    := White;
         New_Menu_Text_Color_2  := White;
         New_Menu_Frame_Color   := White;
         New_Border_Color       := Black;

         VT100_ForeGround_Color := LightGray;
         VT100_BackGround_Color := Black;
         VT100_Border_Color     := Black;
         VT100_Underline_Color  := Blue;
         VT100_Bold_Color       := White;

      END;

END   (* Get_Video_Mode *);

(*----------------------------------------------------------------------*)
(*        Get_Terminal_Type --- Get Type of Terminal to Emulate         *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Terminal_Type;

VAR
   Emul_Menu   : Menu_Type;
   I           : INTEGER;
   J           : INTEGER;
   Default     : INTEGER;
   Gossip_Str  : STRING[20];

BEGIN (* Get_Terminal_Type *)
                                   (* Get current terminal type *)

   Default := SUCC( ORD( Terminal_To_Emulate ) );

   IF Gossip_Mode_On THEN
      Gossip_Str := 'Turn OFF Gossip mode'
   ELSE
      Gossip_Str := 'Turn ON Gossip mode';

                                   (* Construct menu *)

   Make_And_Display_Menu( Emul_Menu, NumberTerminalTypes + 1, 8, 54, 0, 0,
                          Default,
                          'Terminal to Emulate: ',
                          'Dumb;VT52;ANSI;VT100;' + Gossip_Str + ';Host Mode;' +
                          'Tektronix 4010;ADM3a;ADM5;TV925;User1;User2;User3;' +
                          'User4;User5;',
                          TRUE, TRUE, I );

   IF ( I > 0 ) THEN
      BEGIN

         IF ( I = 5 ) THEN
            IF ( NOT Gossip_Mode_On ) THEN
               BEGIN
                  Saved_Gossip_Term   := Terminal_To_Emulate;
                  Terminal_To_Emulate := Gossip;
                  Gossip_Mode_On      := TRUE;
               END
            ELSE
               BEGIN
                  Terminal_To_Emulate := Saved_Gossip_Term;
                  Gossip_Mode_On      := FALSE;
               END
         ELSE
            Terminal_To_Emulate := Terminal_Type_List[ PRED( I ) ];

      END;

END   (* Get_Terminal_Type *);

(*----------------------------------------------------------------------*)
(*     Get_Kermit_Checksum_Type --- Get Type of Checksum for Kermit     *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Kermit_Checksum_Type;

VAR
   Kermit_Chk_Menu : Menu_Type;
   I               : INTEGER;

BEGIN (* Get_Kermit_Checksum_Type *)

   Make_And_Display_Menu( Kermit_Chk_Menu, 3, 10, 54, 0, 0,
                          ( ORD( Kermit_Chk_Type ) - ORD( '0' ) ),
                          'Block check type: ',
                          '1 character checksum;2 character checksum;' +
                          '3 character CRC',
                          FALSE, TRUE, I );

   IF ( I > 0 ) THEN
      Kermit_Chk_Type := CHR( I + ORD('0') );

END   (* Get_Kermit_Checksum_Type *);

(*----------------------------------------------------------------------*)
(*          Get_Date_Type --- Get Type of Date Format for Display       *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Date_Type;

VAR
   L2        : INTEGER;
   L         : INTEGER;
   Date_Menu : Menu_Type;

BEGIN (* Get_Date_Type *)

   L2 := SUCC( ORD( Date_Format ) );

   Make_And_Display_Menu( Date_Menu, 4, 10, 54, 0, 0, L2,
                          'Date Format: ',
                          Date_Formats[1] + ';' +
                          Date_Formats[2] + ';' +
                          Date_Formats[3] + ';QUIT',
                          TRUE, TRUE, L );

   IF ( L > 0 ) AND ( L < 4 ) THEN
      BEGIN
         Date_Format        := Date_Modes[ L ];
         Date_Format_String := Date_Formats[ L ];
      END;

END   (* Get_Date_Type *);

(*----------------------------------------------------------------------*)
(*          Get_Script_Order --- Get order to search for scripts        *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Script_Order;

VAR
   L2         : INTEGER;
   L          : INTEGER;
   Order_Menu : Menu_Type;

BEGIN (* Get_Script_Order *)

   L2 := SUCC( ORD( Script_Search_Order ) );

   Make_And_Display_Menu( Order_Menu, 5, 10, 54, 0, 0,
                          L2,
                          'Script search order: ',
                          Lib_Search[1] + ';' +
                          Lib_Search[2] + ';' +
                          Lib_Search[3] + ';' +
                          Lib_Search[4] + ';QUIT;',
                          FALSE, TRUE, L );

   IF ( L > 0 ) AND ( L < 5 ) THEN
      BEGIN
         Script_Search_Order := Lib_Search_Mode[ L ];
         Script_Order_String := Lib_Search     [ L ];
      END;

END   (* Get_Script_Order *);

(*----------------------------------------------------------------------*)
(*         Get_VT100_Setup   ---  Get VT100 setup                       *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_VT100_Setup;

BEGIN (* Get_VT100_Setup *)

   (* VF = VT100_Foreground_Color   *)
   (* VB = VT100_Background_Color   *)
   (* VS = VT100_Border_Color       *)
   (* VE = VT100_Bold_Color         *)
   (* VU = VT100_Underline_Color    *)
   (* VA = VT100_Answerback_Message *)
   (* VC = Auto_Change_Arrows       *)
   (* VK = KeyPad_Appl_On_File      *)
   (* VN = KeyPad_Appl_Off_File     *)

   Get_General_Setup( 'VF VB VS VE VU VA VC VK VN ',
                      'VT100 settings', ' ' );

END   (* Get_VT100_Setup *);

(*----------------------------------------------------------------------*)
(*                 Get_A_Key --- Get a function key and name            *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_A_Key( VAR Key_No     : INTEGER;
                     VAR Key_Name   : AnyStr   );

VAR
   Ch        : CHAR;
   OK_KeyHit : BOOLEAN;
   Defs_Done : BOOLEAN;
   AKey_No   : INTEGER;
   Key_Type  : INTEGER;
   AKey_Name : STRING[20];
   S_Val     : STRING[10];
   SKey_Name : STRING[4];
   I         : INTEGER;

BEGIN (* Get_Command_Key *)

   OK_KeyHit := FALSE;
   Defs_Done := FALSE;

   REPEAT

      GoToXY( 2 , Param_Count + 3 );

      IF ( Command_Key_Name = '' ) THEN
         AKey_Name := 'None'
      ELSE
         AKey_Name := Command_Key_Name;

      WRITE(' Hit key for invoking command mode (currently ',
            AKey_Name, ') >>');
      ClrEol;
                                   (* Pick up blank, ESC, or function key sequence *)
      Read_Kbd( Ch );

      IF ( Ch = ' ' ) THEN
         BEGIN
            Key_No   := 0;
            Key_Name := '';
            EXIT;
         END
      ELSE IF ( Ch <> CHR( ESC ) ) THEN
         OK_KeyHit := FALSE
      ELSE
         IF ( NOT PibTerm_KeyPressed ) THEN
            BEGIN
               Defs_Done := TRUE;
               OK_KeyHit := TRUE;
            END
         ELSE
            BEGIN
               Read_Kbd( Ch );
               AKey_No   := ORD( Ch );
               OK_KeyHit := ( PibTerm_Command_Table[ AKey_No ] = KeySendSy );
            END;
                                   (* Not just plain escape -- must be *)
                                   (* function key.                    *)
      IF ( NOT OK_KeyHit ) THEN
         BEGIN
            WRITE(' *** Not a valid key');
            ClrEol;
            Window_Delay;
         END
      ELSE                         (* Get key name *)

         IF ( NOT Defs_Done ) THEN
            BEGIN

               Key_No   := AKey_No;
               Get_Long_Key_Name( Key_Definitions[Key_No].Name , Key_Name );

               WRITE( Key_Name );
               ClrEol;

               Window_Delay;

            END;

   UNTIL ( OK_KeyHit OR Defs_Done );

END   (* Get_A_Key *);

(*----------------------------------------------------------------------*)
(*         Get_Ascii_Parameters --- Get parameters for ascii transfers  *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Ascii_Parameters;

BEGIN (* Get_Ascii_Parameters *)
                                   (* Fake this parameter as boolean *)

   Ascii_CRLF := ( Ascii_CR_LF_String <> CHR( CR ) );

   (* AC = Ascii_Char_Delay  *)
   (* AL = Ascii_Line_Delay  *)
   (* AP = Ascii_Pacing_Char *)
   (* AX = Ascii_Send_Asis   *)
   (* AS = Ascii_Line_Size   *)
   (* AE = Ascii_CRLF        *)
   (* AF = Ascii_Send_Blank  *)
   (* AZ = Ascii_Use_CtrlZ   *)
   (* AD = Ascii_Show_Text   *)
   (* AT = Ascii_Translate   *)

   Get_General_Setup( 'AC AL AP AX AS 10 AF AZ AD AT ',
                      'Ascii transfer settings', ' ' );

   Ascii_Line_Size := MAX( MIN( Ascii_Line_Size , 255 ) , 1 );

   IF ( NOT Ascii_CRLF ) THEN
      Ascii_CR_LF_String := CHR( CR )
   ELSE
      Ascii_CR_LF_String := CHR( CR ) + CHR( LF );

END   (* Get_Ascii_Parameters *);

(*----------------------------------------------------------------------*)
(*      Get_Xmodem_Parameters --- Get parameters for xmodem transfers   *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Xmodem_Parameters;

BEGIN (* Get_Xmodem_Parameters *)

   (*  XC = Xmodem_Char_Wait   *)
   (*  XH = Xmodem_Block_Wait  *)
   (*  XA = Xmodem_Ack_Wait    *)
   (*  XT = Xmodem_Max_Errors  *)
   (*  GD = GMT_Difference     *)
   (*  DY = Downsize_Ymodem    *)
   (*  Y0 = Use_Ymodem_Header  *)
   (*  U0 = Use_Block_Zero     *)
   (*  YX = Honor_Xoff_Ymodem  *)
   (*  YF = Use_Full_Path_Name *)

   Get_General_Setup( 'XC XH XA XT GD DY Y0 U0 YX YF ',
                      'Xmodem/Ymodem transfer settings', ' ' );

END   (* Get_Xmodem_Parameters *);

(*----------------------------------------------------------------------*)
(*      Save_Params --- Save current parameter vector definitions       *)
(*----------------------------------------------------------------------*)

PROCEDURE Save_Params( VAR Save_P_Count : INTEGER;
                       VAR Save_PNums   : PNums_Vector );

VAR
   I : INTEGER;

BEGIN (* Save_Params *)

   Save_P_Count  := Param_Count;

   IF ( Save_P_Count > 0 ) THEN
      FOR I := 1 TO Save_P_Count DO
         Save_PNums[ I ] := Param_Nums[ I ];

END   (* Save_Params *);

(*----------------------------------------------------------------------*)
(*      Restore_Params --- Restore saved parameter vector definitions   *)
(*----------------------------------------------------------------------*)

PROCEDURE Restore_Params( VAR Save_P_Count : INTEGER;
                          VAR Save_PNums   : PNums_Vector );

VAR
   I    : INTEGER;
   PNum : INTEGER;

BEGIN (* Restore_Params *)

   IF ( Save_P_Count > 0 ) THEN
      BEGIN
         Param_Count  := 0;
         Param_ValCol := 0;
         FOR I := 1 TO Save_P_Count DO
            BEGIN
               PNum := Save_PNums[ I ];
               Define_Param_For_Display( Parameters[PNum].PName );
               Param_Nums[ I ] := PNum;
            END;
         Param_ValCol := Param_ValCol + 6;
      END;

END   (* Restore_Params *);

(*----------------------------------------------------------------------*)
(*      Get_External_Protocols --- Get parms for external protocols     *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_External_Protocols;

VAR
   Local_Save : Saved_Screen_Ptr;
   I          : INTEGER;
   T          : Transfer_Type;
   BatchF     : STRING[3];
   SName      : String12;
   RName      : String12;
   Prot_Menu  : Menu_Type;
   Prot_Item  : INTEGER;
   IProt      : INTEGER;
   First_Prot : INTEGER;
   Default    : INTEGER;
   Save_PCount: INTEGER;
   Save_PNums : PNums_Vector;

(*----------------------------------------------------------------------*)

PROCEDURE Display_One_Protocol( I : INTEGER );

VAR
   T          : Transfer_Type;
   SName      : String12;
   RName      : String12;
   HostOK     : STRING[3];
   ProtI      : INTEGER;
   TName      : String12;
   BatchL     : CHAR;
   HostL      : CHAR;

BEGIN (* Display_One_Protocol *)

   GoToXY( 1 , ( I - First_Prot ) + 4 );

   T     := Transfers[SUCC(I)];
   ProtI := SUCC( I - First_Prot );

   SName := Send_Script_Names[T];
   RName := Receive_Script_Names[T];

   IF Single_File_Protocol[T] THEN
      BEGIN
         BatchF := 'NO ';
         BatchL := 'S';
      END
   ELSE
      BEGIN
         BatchF := 'YES';
         BatchL := 'B';
      END;

   IF Trans_OK_In_Host[T] THEN
      BEGIN
         HostOK := 'YES';
         HostL  := 'H';
      END
   ELSE
      BEGIN
         HostOK := 'NO ';
         HostL  := 'T';
      END;

   WRITE( ' ', CHR( ORD('a') + ( I - First_Prot ) ) );

   TextColor( Menu_Text_Color_2);

   WRITE( ')');

   TextColor( Menu_Text_Color );

   IF ( TRIM( Transfer_Name_List[SUCC(I)] ) <> '' ) THEN
      BEGIN
         TName := LTrim( Transfer_Name_List[SUCC(I)] );
         External_Trans_Def[ProtI] := Trans_Type_Name[T]  +
                                      ' '                 +
                                      TName               +
                                      ' '                 +
                                      BatchL              +
                                      ' '                 +
                                      HostL               +
                                      ' '                 +
                                      RName               +
                                      ' '                 +
                                      SName;
         WRITE( Transfer_Name_List[SUCC(I)]:13,
                '    ',
                Trans_Type_Name[T] ,
                '        ' );
         IF ( Trans_Type_Name[T] <> '  ' ) THEN
            WRITE( BatchF, '         ',
                   HostOK, '     ',
                   RName:12, '   ',
                   SName:12 )
       END
   ELSE
      BEGIN
         WRITE( '** Unused **':13 );
         External_Trans_Def[ProtI] := '';
      END;

   ClrEol;

END   (* Display_One_Protocol *);

(*----------------------------------------------------------------------*)

PROCEDURE Revise_Protocol_String(     Desc    : AnyStr;
                                  VAR NewSVal : String12 );

VAR
   SVal : AnyStr;
   I    : INTEGER;

BEGIN (* Revise_Protocol_String *)

   GoToXY( 2 , Param_Count + 3 );
   ClrEol;

   TextColor( Menu_Text_Color_2 );

   WRITELN( Desc );
   WRITE  ( Arrow_Str );

   TextColor( Menu_Text_Color );

   SVal := NewSVal;

   Read_Edited_String( SVal );

   IF ( SVal <> CHR( ESC ) ) THEN
      NewSVal := SVal;

   FOR I := ( Param_Count + 3 ) TO ( Param_Count + 7 ) DO
      BEGIN
         GoToXY( 1 , I );
         ClrEol;
      END;

END   (* Revise_Protocol_String *);

(*----------------------------------------------------------------------*)

BEGIN (* Get_External_Protocols *)
                                   (* Save current definitions *)

   Save_Params( Save_PCount , Save_PNums );

                                   (* Draw frame around screen *)

   Draw_Titled_Box( Local_Save, 1, 1, 80, 24,
                    'External transfer protocol definitions' );

   TextColor( Menu_Text_Color_2 );

   WRITELN;
   WRITELN('   Protocol Name  Abbrev.  Batch Mode  Host Mode  Receive Script  Send Script');
   WRITELN;

   TextColor( Menu_Text_Color );

   Param_Count := 2;
   First_Prot  := ORD( PUser1 );

   FOR I := First_Prot TO ORD( PUser10 ) DO
      BEGIN
         Display_One_Protocol( I );
         INC( Param_Count );
      END;

   WRITELN;
                                   (* Get entries to change *)
   IProt := Get_Item_Choice;

   WHILE( IProt > 0 ) DO
      BEGIN

         IProt   := IProt + First_Prot;
         Default := 1;

         REPEAT

            Make_And_Display_Menu( Prot_Menu, 7, 17, 30, 0, 0, Default,
                                   'Revise Protocol: ',
                                   'P)rotocol name;A)bbreviation;B)atch mode;' +
                                   'H)ost mode allowed;R)eceive script;S)end script;Q)uit;',
                                   FALSE, TRUE, Prot_Item );

            TextColor     ( Menu_Text_Color );
            TextBackGround( Black );

            T := Transfers[IProt];

            CASE Prot_Item OF

               1: BEGIN
                     SName := Transfer_Name_List[IProt];
                     IF ( TRIM( SName ) <> '' ) THEN
                        SName := LTRIM( SName );
                     Revise_Protocol_String( 'Protocol name:' , SName );
                     SName := LTRIM( TRIM( SName ) );
                     CopyS2AR( SName, RName[1], 12 );
                     RName[0] := CHR( 12 );
                     Transfer_Name_List[IProt] := RName;
                  END;

               2: BEGIN
                     SName := Trans_Type_Name[T];
                     Revise_Protocol_String( 'Abbreviation:' , SName );
                     SName := UpperCase( SName + '  ' );
                     Trans_Type_Name[T][1] := SName[1];
                     Trans_Type_Name[T][2] := SName[2];
                     IF ( Trans_Type_Name[T] <> '  ' ) THEN
                        IF ( ( Trans_Type_Name[T][1] = ' ' ) OR
                             ( Trans_Type_Name[T][2] = ' ' ) ) THEN
                           BEGIN
                              Trans_Type_Name[T] := '  ';
                              Menu_Beep;
                           END;
                  END;

               3: BEGIN
                     GoToXY( 3 , Param_Count + 2 );
                     Single_File_Protocol[ T ] := NOT YesNo(' Batch mode protocol (Y/N)? ');
                     GoToXY( 1 , Param_Count + 3 );
                     ClrEol;
                     GoToXY( 1 , Param_Count + 4 );
                     ClrEol;
                  END;

               4: BEGIN
                     GoToXY( 3 , Param_Count + 2 );
                     Trans_OK_In_Host[ T ] := YesNo(' Allow this protocol in host mode (Y/N)? ');
                     GoToXY( 1 , Param_Count + 3 );
                     ClrEol;
                     GoToXY( 1 , Param_Count + 4 );
                     ClrEol;
                  END;

               5: BEGIN
                     SName := Receive_Script_Names[T];
                     IF ( TRIM( SName ) <> '' ) THEN
                        SName := LTrim( SName );
                     Revise_Protocol_String( 'Script name for receiving files:' , SName );
                     SName := UpperCase( LTrim( Trim( SName ) ) );
                     I := POS( '.BAT' , SName );
                     IF ( I = 0 ) THEN
                        IF ( LENGTH( SName ) > 8 ) THEN
                           SName := COPY( SName, 1, 8 )
                        ELSE
                     ELSE
                        SName := COPY( SName, 1, MIN( 8 , PRED( I ) ) ) + '.BAT';
                     Receive_Script_Names[T] := SName;
                  END;

               6: BEGIN
                     SName := Send_Script_Names[T];
                     IF ( TRIM( SName ) <> '' ) THEN
                        SName := LTrim( SName );
                     Revise_Protocol_String( 'Script name for sending files:' , SName );
                     SName := UpperCase( LTrim( Trim( SName ) ) );
                     I := POS( '.BAT' , SName );
                     IF ( I = 0 ) THEN
                        IF ( LENGTH( SName ) > 8 ) THEN
                           SName := COPY( SName, 1, 8 )
                        ELSE
                     ELSE
                        SName := COPY( SName, 1, MIN( 8 , PRED( I ) ) ) + '.BAT';
                     Send_Script_Names[T] := SName;
                  END;

               ELSE
                  Prot_Item := -3;

            END (* CASE *);

            Default := SUCC( Prot_Item );
            IF ( ( Default > 7 ) OR ( Default < 1 ) ) THEN
               Default := 1;

            IF ( Prot_Item > 0 ) THEN
               Display_One_Protocol( PRED( IProt ) );

         UNTIL ( Prot_Item <= 0 );

         IProt := Get_Item_Choice;

      END;
                                   (* Restore previous screen *)
   Restore_Screen( Local_Save );
                                   (* Restore previous definitions *)

   Restore_Params( Save_PCount , Save_PNums );

END   (* Get_External_Protocols *);

(*----------------------------------------------------------------------*)
(*        Define_Param_For_Display --- Define parameter for display     *)
(*----------------------------------------------------------------------*)

PROCEDURE Define_Param_For_Display( PName : Char_2 );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Define_Param_For_Display                             *)
(*                                                                      *)
(*     Purpose:    Define parameter for display/update                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Define_Param_For_Display( PName : Char_2 );                   *)
(*                                                                      *)
(*           PName --- Name of parameter to be defined                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   P_Num : INTEGER;

BEGIN (* Define_Param_For_Display *)

                                   (* Increment parameter count *)
   INC( Param_Count );
                                   (* Insert information on this parameter *)

   P_Num := Look_Up_Parameter( PName );

   WITH Parameters[P_Num] DO
      BEGIN
         Param_Types[Param_Count] := PType;
         Param_IPtrs[Param_Count] := PAddr;
         Param_Desc [Param_Count] := PDesc;
         Param_Nums [Param_Count] := P_Num;
      END;
                                   (* Remember longest description length *)

   Param_ValCol := MAX( Param_ValCol ,
                        LENGTH( Param_Desc[Param_Count]^ ) );

END   (* Define_Param_For_Display *);

(*----------------------------------------------------------------------*)
(*  Display_Parameter --- Display description and value of a parameter  *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Parameter( IParam: INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Display_Parameter                                    *)
(*                                                                      *)
(*     Purpose:    Display description/value of a parameter             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Display_Parameter( IParam : INTEGER );                        *)
(*                                                                      *)
(*           IParam --- which parameter to display                      *)
(*                      (corresponds to offset previously set by        *)
(*                      calling Define_Parameter_For_Display)           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   SVal      : STRING[10];
   Disp_Line : INTEGER;
   MaxDLen   : INTEGER;
   SDisply   : AnyStr;

BEGIN (* Display_Parameter *)
                                   (* Clear line of current stuff *)
   Disp_Line := SUCC( IParam );

   TextColor     ( Menu_Text_Color_2 );
   TextBackGround( Black );

   GoToXY( 2 , Disp_Line );
   ClrEol;
                                   (* Display description *)

   WRITE( CHR( ORD('a') + PRED( IParam ) ) );

   TextColor( Menu_Text_Color  );

   WRITE( ') ');

   TextColor( Menu_Text_Color_2 );

   WRITE( Param_Desc[IParam]^ );
                                   (* If null parameter, quit      *)

   IF ( ( Param_Types[IParam] = Menu_Param ) OR
        ( Param_Types[IParam] = Null_Param ) ) THEN EXIT;

                                   (* Move to value display column *)

   GoToXY( Param_ValCol , Disp_Line );

                                   (* Figure maximum display length *)
                                   (* for parameters.               *)

   MaxDLen := MAX( 1 , PRED( Lower_Right_Column -
                       ( PRED( Param_ValCol ) + Upper_Left_Column ) ) );

   WRITE ( ': ');
   TextColor( Menu_Text_Color );

                                   (* Display parameter value      *)
   CASE Param_Types[IParam] OF

      PosInt_Param,
      Integer_Param : WRITE( Param_IPtrs[IParam]^ );

      Word_Param    : WRITE( Param_WPtrs[IParam]^ );

      Byte_Param    : WRITE( Param_BPtrs[IParam]^ );

      LongInt_Param : WRITE( Param_XPtrs[IParam]^ );

      String_Param,
      Path_Param,
      FileN_Param,
      Key_Param     : BEGIN
                         SDisPly := Write_Ctrls( Param_SPtrs[IParam]^ );
                         IF ( LENGTH( SDisPly ) > MaxDLen ) THEN
                            BEGIN

                               TextColor( Menu_Text_Color_2 );
                               GoToXY( Param_ValCol , Disp_Line );
                               WRITE ( '+ ');
                               TextColor( Menu_Text_Color );

                               SDisPly := COPY( SDisPly, 1, MaxDLen );

                            END;
                         WRITE( SDisPly );
                      END;

      SpecChar_Param: BEGIN
                         SVal := Param_CPtrs[IParam]^;
                         WRITE( Write_Ctrls( SVal ), ' (Ascii ',ORD( SVal[1] ),
                                ')');
                      END;

      KCheck_Param,
      Char_Param    : WRITE( Param_CPtrs[IParam]^, ' (Ascii ',
                         ORD( Param_CPtrs[IParam]^ ),')');

      Boolean_Param : IF Param_LPtrs[IParam]^ THEN
                        WRITE( 'Yes' )
                      ELSE
                        WRITE( 'No' );

      Transfer_Param: WRITE( LTrim( Transfer_Name_List[ ORD( Param_FPtrs[IParam]^ ) + 1 ] ) );

      Terminal_Param: WRITE( Terminal_Name_List[ ORD( Param_TPtrs[IParam]^ ) ] );

      Date_Param    : WRITE( Date_Formats[ ORD( Param_DPtrs[IParam]^ ) + 1 ] );

      ScrOrder_Param: WRITE( Lib_Search[ ORD( Param_OPtrs[IParam]^ ) + 1 ] );

      BColor_Param,
      Color_Param   : WRITE( Colors[ Param_IPtrs[IParam]^ ] );

      VidMode_Param : CASE Param_IPtrs[IParam]^ OF
                         BW80: WRITE( 'Black and white' );
                         Mono: WRITE( 'Monochrome' );
                         ELSE
                               WRITE( 'Color' );
                      END (* CASE *);

      Hexi_Param    : WRITE( Dec_To_Hex( Param_IPtrs[IParam]^ ) );

      ELSE;

   END (* CASE *);

   TextColor( Menu_Text_Color );

END   (* Display_Parameter *);

(*----------------------------------------------------------------------*)
(*            Update_Parameter --- Update value of a parameter          *)
(*----------------------------------------------------------------------*)

PROCEDURE Update_Parameter( IParam: INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Update_Parameter                                     *)
(*                                                                      *)
(*     Purpose:    Update value of a parameter                          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Update_Parameter( IParam : INTEGER );                         *)
(*                                                                      *)
(*           IParam --- which parameter to update                       *)
(*                      (corresponds to offset previously set by        *)
(*                      calling Define_Parameter_For_Display)           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I     : LongInt;
   II    : INTEGER;
   PType : Param_Type;
   PStr  : AnyStr;
   PDesc : AnyStr;
   Y     : INTEGER;

BEGIN (* Update_Parameter *)

   PType := Param_Types[IParam];
   Y     := WhereY;

   CASE PType OF

      Boolean_Param : Param_LPtrs[IParam]^ := NOT Param_LPtrs[IParam]^;

      Color_Param   : Get_A_Color( Param_Desc[IParam]^, Param_IPtrs[IParam]^, FALSE,
                                   Param_IPtrs[IParam]^ );

      BColor_Param  : Get_A_Color( Param_Desc[IParam]^, Param_IPtrs[IParam]^, TRUE,
                                   Param_IPtrs[IParam]^ );

      VidMode_Param : Get_Video_Mode;

      Terminal_Param: Get_Terminal_Type;

      KCheck_Param  : Get_Kermit_Checksum_Type;

      VT100_Param   : Get_VT100_Setup;

      Date_Param    : Get_Date_Type;

      ScrOrder_Param: Get_Script_Order;

      Key_Param     : Get_A_Key( Command_Key , Command_Key_Name );

      Ascii_Param   : Get_Ascii_Parameters;

      Xmodem_Param  : Get_Xmodem_Parameters;

      ExtTrans_Param: Get_External_Protocols;

      Transfer_Param: Display_Transfer_Types( 'Transfer protocol: ',
                                               Default_Transfer_Type,
                                               FALSE,
                                               2, 54, 0, 0, 24,
                                               TRUE,
                                               Default_Transfer_Type );
      ELSE
         BEGIN

            GoToXY( 2 , MIN( Param_Count + 3 , 21 ) );
            ClrEol;

            PDesc    := Param_Desc[IParam]^;

            IF ( ( PDesc[1] IN ['A'..'Z'] ) AND
                 ( COPY( PDesc, 1, 5 ) <> 'VT100' ) AND
                 ( COPY( PDesc, 1, 4 ) <> 'CTTY'  )     ) THEN
               PDesc[1] := CHR( ORD( PDesc[1] ) + ORD('a') - ORD('A') );

            TextColor( Menu_Text_Color_2 );

            WRITE( Enter_Str, PDesc, Colon_Str );

            TextColor( Menu_Text_Color );

            CASE PType OF

               PosInt_Param :  BEGIN
                                  I := Param_IPtrs[IParam]^;
                                  IF Read_Number( I, TRUE, I ) THEN
                                     BEGIN
                                        IF ( I <= 0 ) THEN
                                           II := 0
                                        ELSE IF ( I > 32767 ) THEN
                                           II := 32767
                                        ELSE
                                           II := I;
                                        Param_IPtrs[IParam]^ := II;
                                     END;
                               END;

               Byte_Param   :  BEGIN
                                  I := Param_BPtrs[IParam]^;
                                  IF Read_Number( I, TRUE, I ) THEN
                                     Param_BPtrs[IParam]^ := I;
                               END;

               LongInt_Param:  IF Read_Number( Param_XPtrs[IParam]^,
                                               TRUE, I ) THEN
                                  Param_XPtrs[IParam]^ := I;

               String_Param :  BEGIN
                                  PStr := Write_Ctrls( Param_SPtrs[IParam]^ );
                                  WRITELN;
                                  WRITE( Arrow_Str );
                                  ClrEol;
                                  Read_Edited_String( PStr );
                                  IF ( PStr <> CHR( ESC ) ) THEN
                                     Param_SPtrs[IParam]^ := Read_Ctrls( PStr );
                               END;

               SpecChar_Param: BEGIN
                                  PStr := Write_Ctrls( Param_CPtrs[IParam]^ );
                                  WRITELN;
                                  WRITE( Arrow_Str );
                                  ClrEol;
                                  Read_Edited_String( PStr );
                                  IF ( PStr <> CHR( ESC ) ) THEN
                                     BEGIN
                                        PStr := Read_Ctrls( PStr );
                                        IF( LENGTH( PStr ) > 0 ) THEN
                                           Param_CPtrs[IParam]^ := PStr[1];
                                     END;
                               END;

               Char_Param    : BEGIN
                                  PStr := Param_CPtrs[IParam]^;
                                  WRITELN;
                                  WRITE( Arrow_Str );
                                  ClrEol;
                                  Read_Edited_String( PStr );
                                  IF ( PStr <> CHR( ESC ) ) THEN
                                     IF( LENGTH( PStr ) > 0 ) THEN
                                        Param_CPtrs[IParam]^ := PStr[1];
                               END;

               Path_Param   :  BEGIN
                                  PStr := Param_SPtrs[IParam]^;
                                  WRITELN;
                                  WRITE( Arrow_Str );
                                  ClrEol;
                                  Read_Edited_String( PStr );
                                  PStr := TRIM( PStr );
                                  IF ( PStr <> CHR( ESC ) ) THEN
                                     BEGIN
                                        IF ( LENGTH( PStr ) > 0 ) THEN
                                           IF PStr[ LENGTH( PStr ) ] <> '\' THEN
                                              PStr := PStr + '\';
                                        Param_SPtrs[IParam]^ := PStr;
                                     END;
                               END;

               Hexi_Param   :  BEGIN
                                  II   := Param_IPtrs[IParam]^;
                                  PStr := Dec_To_Hex( II );
                                  WRITELN;
                                  WRITE( Arrow_Str );
                                  ClrEol;
                                  Read_Edited_String( PStr );
                                  IF ( PStr <> CHR( ESC ) ) THEN
                                     Param_IPtrs[IParam]^ := Hex_To_Dec( PStr , II );
                               END;

               Integer_Param:  BEGIN
                                  I := Param_IPtrs[IParam]^;
                                  IF Read_Number( I, TRUE, I ) THEN
                                     BEGIN
                                        IF ( I <= -32768 ) THEN
                                           II := -32768
                                        ELSE IF ( I > 32767 ) THEN
                                           II := 32767
                                        ELSE
                                           II := I;
                                        Param_IPtrs[IParam]^ := II;
                                     END;
                               END;

               ELSE;

            END (* CASE *);

         END (* BEGIN *);

   END (* CASE *);

   TextBackGround( BLACK );

   GoToXY( 1 , 21 );
   ClrEol;

END   (* Update_Parameter *);

(*----------------------------------------------------------------------*)
(*            Do_Display --- Display all currently defined parameters   *)
(*----------------------------------------------------------------------*)

PROCEDURE Do_Display;

VAR
   I: INTEGER;

BEGIN (* Do_Display *)

   FOR I := 1 TO Param_Count DO
      Display_Parameter( I );

END   (* Do_Display *);

(*----------------------------------------------------------------------*)
(*            Get_Item_Choice  ---   Get parameter item choice          *)
(*----------------------------------------------------------------------*)

FUNCTION Get_Item_Choice : INTEGER;

VAR
   OK_Choice : BOOLEAN;
   Hi_Let_Ord: INTEGER;
   Ch        : CHAR;
   I         : INTEGER;
   Cur_Choice: INTEGER;
   Cur_Let   : CHAR;
   OK_Move   : BOOLEAN;

BEGIN (* Get_Item_Choice *)
                                   (* Clear input area lines       *)

   FOR I := ( Param_Count + 3 ) TO ( Param_Count + 7 ) DO
      BEGIN
         GoToXY( 2 , I );
         ClrEol;
      END;
                                   (* Assume ESC as default choice *)
   Get_Item_Choice := 0;
   OK_Choice       := FALSE;
   Hi_Let_Ord      := ORD( 'A' ) + Param_Count - 1;
   Cur_Choice      := Param_Count;
   Cur_Let         := ' ';
                                   (* Get choice *)
   REPEAT

      GoToXY( 2 , Param_Count + 3 );

      TextColor( Menu_Text_Color_2 );
      WRITE( 'Enter letter of item to revise or hit ESC to quit: ');
      ClrEol;

      TextColor( Menu_Text_Color );
      WRITE( Cur_Let );

      Read_Kbd_Old( Ch );

      Ch := UpCase( Ch );

      OK_Choice := ( Ch = CHR( ESC ) ) OR
                   ( Ch = CHR( CR  ) ) OR
                   ( ( ORD( Ch ) >= ORD( 'A' ) ) AND
                     ( ORD( Ch ) <= Hi_Let_Ord ) );

      IF ( NOT OK_Choice ) THEN
         Menu_Beep
      ELSE
                                   (* Check for arrows *)

         IF ( ( Ch = CHR( ESC ) ) ) THEN
            IF ( NOT PibTerm_KeyPressed ) THEN
               Cur_Let := ' '
            ELSE
               BEGIN

                  Read_Kbd_Old( Ch );

                  OK_Move := TRUE;

                  CASE ORD( Ch ) OF

                     U_Arrow,
                     5        : BEGIN
                                   DEC( Cur_Choice );
                                   IF ( Cur_Choice < 1 ) THEN
                                      Cur_Choice := Param_Count;
                                END;

                     D_Arrow,
                     24       : BEGIN
                                   INC( Cur_Choice );
                                   IF ( Cur_Choice > Param_Count ) THEN
                                      Cur_Choice := 1;
                                END;

                     ELSE       BEGIN
                                   Menu_Beep;
                                   OK_Move := FALSE;
                                END;

                  END (* CASE *);

                  IF OK_Move THEN
                     BEGIN
                        Ch        := CHR( PRED( Cur_Choice ) + ORD('a') );
                        Cur_Let   := Ch;
                        OK_Choice := FALSE;
                     END;

               END;

   UNTIL ( OK_Choice );
                                   (* Get index of choice *)
   IF ( Ch <> CHR( ESC ) ) THEN
      IF ( Cur_Let = ' ' ) THEN
         BEGIN
            IF ( Ch <> CHR( CR ) ) THEN
               Get_Item_Choice := SUCC( ORD( Ch ) - ORD( 'A' ) );
         END
      ELSE
         Get_Item_Choice := Cur_Choice;

END   (* Get_Item_Choice *);

(*----------------------------------------------------------------------*)
(*         Get_General_Setup --- Get "non-special" setup                *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_General_Setup( Menu_String : AnyStr;
                             Menu_Title  : AnyStr;
                             Post_Proc   : CHAR    );

VAR
   Local_Save   : Saved_Screen_Ptr;
   Item_Name    : Char_2;
   Menu_Item    : INTEGER;

   Save_P_Count : INTEGER;
   PNum         : INTEGER;
   Save_PNums   : PNums_Vector;

BEGIN (* Get_General_Setup *)
                                   (* Save previous parameters info *)

   Save_Params( Save_P_Count , Save_PNums );

                                   (* Draw frame around screen *)

   Draw_Titled_Box( Local_Save, 1, 1, 80, 24, Menu_Title );

                                   (* Set up parameter addresses  *)
   Param_Count  := 0;
   Param_ValCol := 0;

   WHILE ( LENGTH ( Menu_String ) > 0 ) DO
      BEGIN
         Item_Name[1] := Menu_String[1];
         Item_Name[2] := Menu_String[2];
         Define_Param_For_Display( Item_Name );
         DELETE( Menu_String, 1, 3 );
      END;

   Param_ValCol := Param_ValCol + 6;

                                   (* Display parameter values *)
   Do_Display;
                                   (* Get 1st item to modify, if any.   *)
                                   (* ESC takes us out.                 *)

   Menu_Item := Get_Item_Choice;

   WHILE( Menu_Item > 0 ) DO
      BEGIN
                                   (* Update the selected item *)

         Update_Parameter( Menu_Item );

                                   (* Call post-processor if any *)

         CASE Post_Proc OF
            'I'   : Input_Post_Processor ( Menu_Item );
            'F'   : File_Post_Processor  ( Menu_Item );
            'K'   : Kermit_Post_Processor( Menu_Item );
            'M'   : Modem_Post_Processor ( Menu_Item );
            ELSE;
         END (* Post_Proc *);
                                   (* Display revised item    *)

         Display_Parameter( Menu_Item );

                                   (* Get next item to revise *)

         Menu_Item := Get_Item_Choice;

      END;
                                   (* Restore previous screen *)
   Restore_Screen( Local_Save );
                                   (* Restore previous parameter info *)

   Restore_Params( Save_P_Count , Save_PNums );

END   (* Get_General_Setup *);

