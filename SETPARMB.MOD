(*----------------------------------------------------------------------*)
(*          Get_Baud_Rate --- Get Baud Rate for Communications          *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Baud_Rate;

VAR
   Baud_Menu   : Menu_Type;
   I           : INTEGER;
   Default     : INTEGER;
   Baud_String : AnyStr;
   Baud_SVal   : STRING[5];

BEGIN (* Get_Baud_Rate *)
                                   (* Get current baud rate *)
   Default     := 5;
   Baud_String := '';

   FOR I := 1 TO N_Baud_Rates DO
      BEGIN
         IF Baud_Rate = Baud_Rates[I] THEN
            Default := I;
         STR( Baud_Rates[I] , Baud_SVal );
         Baud_String := Baud_String + Baud_SVal + ';';
      END;
                                   (* Display menu and get choice *)

   Make_And_Display_Menu( Baud_Menu, N_Baud_Rates, 10, 54, 0, 0, Default,
                         'Baud Rate: ',
                         Baud_String,
                         TRUE, TRUE, I );

   IF ( I > 0 ) THEN
      BEGIN
         Comm_Port_Changed := ( Baud_Rate <> Baud_Rates[ I ] ) OR Comm_Port_Changed;
         Baud_Rate         := Baud_Rates[ I ];
      END;

END   (* Get_Baud_Rate *);

(*----------------------------------------------------------------------*)
(*        Get_Comm_Port --- Get Port Number for Communications          *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Comm_Port;

VAR
   Port_Menu   : Menu_Type;
   I           : INTEGER;
   J           : INTEGER;

(* STRUCTURED *) CONST
   Serial_Str : STRING[12] = 'Serial Port ';

BEGIN (* Get_Comm_Port *)
                                   (* Display menu and get choice *)

   Make_And_Display_Menu( Port_Menu, 4, 10, 54, 0, 0, Comm_Port,
                          'Serial Port: ',
                          Serial_Str + '1 (COM1:);' +
                          Serial_Str + '2 (COM2:);' +
                          Serial_Str + '3 (COM3:);' +
                          Serial_Str + '4 (COM4:);',
                          TRUE, TRUE, J );

                                   (* Get choice *)
   I := Comm_Port;

   IF ( J > 0 ) THEN
      BEGIN
         Comm_Port_Changed := ( Comm_Port <> J ) OR Comm_Port_Changed;
         Comm_Port         := J;
      END;

END   (* Get_Comm_Port *);

(*----------------------------------------------------------------------*)
(*            Get_Parity --- Get Parity for Communications              *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Parity;

CONST
   Parities:   ARRAY[ 1 .. 5 ] OF Char
               = ( 'E', 'O', 'N', 'M', 'S' );

VAR
   Parity_Menu   : Menu_Type;
   Default       : INTEGER;
   I             : INTEGER;

BEGIN (* Get_Parity *)
                                   (* Get Current Parity *)
   Default := 3;

   FOR I := 1 TO 5 DO
      IF Parity = Parities[I] THEN
         Default := I;
                                   (* Display menu and get choice *)

   Make_And_Display_Menu( Parity_Menu, 5, 10, 54, 0, 0, Default,
                          'Parity: ',
                          'Even;Odd;None;Mark;Space;',
                          FALSE, TRUE, I );

   IF ( I > 0 ) THEN
      BEGIN
         Comm_Port_Changed := ( Parity <> Parities[ I ] ) OR Comm_Port_Changed;
         Parity            := Parities[ I ];
      END;

END   (* Get_Parity *);

(*----------------------------------------------------------------------*)
(*          Get_Stop_Bits --- Get Stop Bits for Communications          *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Stop_Bits;

VAR
   Stop_Menu   : Menu_Type;
   I           : INTEGER;

BEGIN (* Get_Stop_Bits *)
                                   (* Display menu and get choice *)

   Make_And_Display_Menu( Stop_Menu, 2, 10, 54, 0, 0, Stop_Bits,
                          'Stop Bits: ',
                          '1;2;',
                          FALSE, TRUE, I );

   IF ( I > 0 ) THEN
      BEGIN
         Comm_Port_Changed := ( Stop_Bits <> I ) OR Comm_Port_Changed;
         Stop_Bits         := I;
      END;

END   (* Get_Stop_Bits *);

(*----------------------------------------------------------------------*)
(*          Get_Data_Bits --- Get Data Bits for Communications          *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Data_Bits;

VAR
   Bits_Menu   : Menu_Type;
   I           : INTEGER;

BEGIN (* Get_Data_Bits *)
                                   (* Display menu and get choice *)

   Make_And_Display_Menu( Bits_Menu, 2, 10, 54, 0, 0, Data_Bits - 6,
                          'Data Bits: ',
                          '7;8;',
                          FALSE, TRUE, I );

   IF ( I > 0 ) THEN
      Data_Bits := I + 6;

END   (* Get_Data_Bits *);

(*----------------------------------------------------------------------*)
(*      Get_Comm_Port_Hardware --- Get hardware addresses for com ports *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Comm_Port_Hardware;

VAR
   Port_Item : INTEGER;

BEGIN (* Get_Comm_Port_Hardware *)

   Get_General_Setup( 'P1 I1 V1 P2 I2 V2 P3 I3 V3 P4 I4 V4 ',
                      'Serial port hardware settings', ' ' );

                                   (* Set new port addresses *)
   Comm_Port_Changed := TRUE;

   FOR Port_Item := 1 TO MaxComPorts DO
      Async_Setup_Port( Port_Item,
                        Default_Com_Base[Port_Item],
                        Default_Com_Irq [Port_Item],
                        Default_Com_Int [Port_Item] );

END   (* Get_Comm_Port_Hardware *);

(*----------------------------------------------------------------------*)
(*            Get_Comm_Settings --- Get communications settings         *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Comm_Settings;

VAR
   Comm_Item    : INTEGER;
   Local_Save   : Saved_Screen_Ptr;

(*----------------------------------------------------------------------*)

PROCEDURE Do_Comm_Defines;

BEGIN (* Do_Comm_Defines *)
                                   (* Set up parameter addresses  *)
   Param_Count  := 0;
   Param_ValCol := 0;

   Define_Param_For_Display( 'PO' );   (* Comm_Port *)
   Define_Param_For_Display( 'BA' );   (* Baud_Rate *)
   Define_Param_For_Display( 'PA' );   (* Parity *)
   Define_Param_For_Display( 'DA' );   (* Data_Bits *)
   Define_Param_For_Display( 'ST' );   (* Stop_Bits *)
   Define_Param_For_Display( 'LF' );   (* Add_LF *)
   Define_Param_For_Display( 'NL' );   (* New_Line *)
   Define_Param_For_Display( 'XS' );   (* Check_CTS *)
   Define_Param_For_Display( 'XD' );   (* Check_DSR *)
   Define_Param_For_Display( 'HW' );   (* Hard_Wired *)
   Define_Param_For_Display( 'BL' );   (* Break_Length *)
   Define_Param_For_Display( 'DR' );   (* Drop_Dtr_At_End *)
   Define_Param_For_Display( 'CJ' );   (* Close_Comm_For_Dos *)
   Define_Param_For_Display( 'XO' );   (* Do_Xon_Xoff_Checks *)
   Define_Param_For_Display( 'SH' );   (* Auto_Strip_High_Bit *)
   Define_Param_For_Display( 'IB' );   (* Async_Buffer_Length *)
   Define_Param_For_Display( 'OB' );   (* Async_OBuffer_Length *)
   Define_Param_For_Display( 'LE' );   (* Local_Echo *)
   Define_Param_For_Display( '01' );   (* Comm port hardware menu *)

   Param_ValCol := Param_ValCol + 6;

END   (* Do_Comm_Defines *);

(*----------------------------------------------------------------------*)

BEGIN (* Get_Comm_Settings *)
                                   (* Save current screen *)
   Save_Screen( Local_Save );
                                   (* Define com port stuff    *)
   Do_Comm_Defines;
                                   (* Draw frame around screen *)

   Draw_Menu_Frame( 1, 1, 80, 24, Menu_Frame_Color, Menu_Title_Color,
                    Menu_Text_Color, 'Communications parameters' );

                                   (* Display parameter values *)
   Do_Display;
                                   (* Get 1st item to modify, if any.   *)
                                   (* ESC takes us out.                 *)

   Comm_Item := Get_Item_Choice;

   WHILE( Comm_Item > 0 ) DO
      BEGIN

         CASE Comm_Item OF
                                   (* Handle items with menus *)

            1:      Get_Comm_Port;
            2:      Get_Baud_Rate;
            3:      Get_Parity;
            4:      Get_Data_Bits;
            5:      Get_Stop_Bits;
            19:     Get_Comm_Port_Hardware;

                                   (* Otherwise, prompt-style update *)

            ELSE    Update_Parameter( Comm_Item );

         END (* CASE *);
                                   (* Make sure input buffer length is OK *)

         IF ( Comm_Item = 16 ) THEN
            Async_Buffer_Length := MAX( 128 , Async_Buffer_Length )
         ELSE IF ( Comm_Item = 17 ) THEN
            Async_OBuffer_Length := MAX( 16  , Async_OBuffer_Length );

                                   (* Display revised item    *)

         Display_Parameter( Comm_Item );

                                   (* Get next item to revise *)

         Comm_Item := Get_Item_Choice;

      END;
                                   (* Restore previous screen *)
   Restore_Screen( Local_Save );

   New_Line := New_Line_Param;

END   (* Get_Comm_Settings *);

(*----------------------------------------------------------------------*)
(*  File_Post_Processor --- Handle special file parameter updates       *)
(*----------------------------------------------------------------------*)

PROCEDURE File_Post_Processor( Menu_Item : INTEGER );

BEGIN (* File_Post_Processor *)

   Max_Write_Buffer := MAX( Max_Write_Buffer , 512 );
   Zmodem_BlockSize := MAX( Zmodem_BlockSize , 32  );

END   (* File_Post_Processor *);

(*----------------------------------------------------------------------*)
(*            Get_File_Transfer --- Get file transfer settings          *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_File_Transfer;

BEGIN (* Get_File_Transfer *)

   (* TT = Default_Transfer_Type *)
   (* EB = Mahoney_On            *)
   (* BP = Compuserve_B_On       *)
   (* XB = Max_Write_Buffer      *)
   (* TB = Transfer_Bells        *)
   (* EP = Evict_Partial_Trans   *)
   (* FF = Auto_Find_FileNames   *)
   (* ZA = Zmodem_Autodownload   *)
   (* ZB = Zmodem_BlockSize      *)
   (* 02 = Ascii transfer params *)
   (* 03 = Xmodem transfer parms *)
   (* 04 = External trans params *)

   Get_General_Setup( 'TT EB BP XB TB EP FF ZA ZB 02 03 04 ',
                      'File transfer settings', 'F' );

END   (* Get_File_Transfer *);

(*----------------------------------------------------------------------*)
(*            Get_Host_Mode_Setup --- Get setup for host mode           *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Host_Mode_Setup;

BEGIN (* Get_Host_Mode_Setup *)

   (*  MS = Modem_Host_Set       *)
   (*  MX = Modem_Host_UnSet     *)
   (*  AB = Host_Auto_Baud       *)
   (*  HB = Host_Mode_Blank_Time *)
   (*  HU = Host_Mode_Upload     *)
   (*  HD = Host_Mode_Download   *)
   (*  AU = Host_CTTY_Device     *)

   Get_General_Setup( 'MS MX AB HB HU HD AU ',
                      'Host mode settings', ' ' );

END   (* Get_Host_Mode_Setup *);

(*----------------------------------------------------------------------*)
(* Input_Post_Processor --- Handle special input parameter updates      *)
(*----------------------------------------------------------------------*)

PROCEDURE Input_Post_Processor( Menu_Item : INTEGER );

BEGIN (* Input_Post_Processor *)

   CASE Menu_Item OF

      3:  BEGIN
             BS_String      := CHR( BS );
             Ctrl_BS_String := CHR( DEL );
             Display_Parameter( 1 );
             Display_Parameter( 2 );
          END;

      4:  BEGIN
             BS_String      := CHR( DEL );
             Ctrl_BS_String := CHR( BS  );
             Display_Parameter( 1 );
             Display_Parameter( 2 );
          END;

      ELSE;

   END (* CASE *);

END   (* Input_Post_Processor *);

(*----------------------------------------------------------------------*)
(*          Get_Input_Setup -- Get keyboard input parameters            *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Input_Setup;

VAR
   Save_Ext_Kpd : BOOLEAN;

BEGIN (* Get_Input_Setup *)
                                   (* Remember which keypad mode we're in *)

   Save_Ext_Kpd := Extended_Keypad;

   (*  BS = Backspace string      *)
   (*  DE = Ctrl-BackSpace string *)
   (*  11 = BS to BS, DEL to DEL  *)
   (*  12 = DEL to BS, BS to DEL  *)
   (*  EK = Extended_Keypad       *)
   (*  06 = Command_Key_Name      *)
   (*  IM = Edit_Insert_Mode      *)
   (*  DI = Use_Dos_Buffer_In     *)
   (*  FH = FK_Delay_Time         *)
   (*  UP = Use_Prev_Key_Text     *)
   (*  TU = Send_Upper_Case_Only  *)
   (*  EU = Extended_KeyBoard     *)

   Get_General_Setup( 'BS DE 11 12 EK 06 IM DI FH UP TU EU ',
                      'Keyboard Input Parameters',
                      'I' );

                                   (* Check if 101-key kbd allowed *)

   Extended_KeyBoard      := Extended_KeyBoard AND
                             ( ( Mem[$40:$96] AND $10 ) <> 0 );

                                   (* See if extended keypad change *)

   Kbd_Interrupt_Change   := ( Extended_Keypad <> Save_Ext_Kpd );

END   (* Get_Input_Setup *);

(*----------------------------------------------------------------------*)
(* Kermit_Post_Processor --- Handle special Kermit parameter updates    *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Post_Processor( Menu_Item : INTEGER );

BEGIN (* Kermit_Post_Processor *)

   CASE Menu_Item OF

      10: Kermit_Init_Packet_Size := MIN( MAX( Kermit_Init_Packet_Size , 20 ) , 94 );
      13: Kermit_Window_Size      := MIN( Kermit_Window_Size ,
                                          MaxKermitWindowSize );
      14: Kermit_Extended_Block   := MIN( Kermit_Extended_Block,
                                          MaxLongPacketLength );
      ELSE;

   END (* CASE *);

END   (* Kermit_Post_Processor *);

(*----------------------------------------------------------------------*)
(*            Get_Kermit_Setup --- Get Kermit protocol parameters       *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Kermit_Setup;

BEGIN (* Get_Kermit_Setup *)

   (* KC = Kermit_Chk_Type         *)
   (* KD = Kermit_Debug            *)
   (* KE = Kermit_EOL              *)
   (* KH = Kermit_Header_Char      *)
   (* KN = Kermit_NPad             *)
   (* KP = Kermit_Pad_Char         *)
   (* KQ = Kermit_Quote_Char       *)
   (* K8 = Kermit_Quote_8_Char     *)
   (* KR = Kermit_Repeat_Char      *)
   (* KS = Kermit_Init_Packet_Size *)
   (* KT = Kermit_TimeOut          *)
   (* KW = Kermit_Delay_Time       *)
   (* KL = Kermit_Window_Size      *)
   (* KX = Kermit_Extended_Block   *)
   (* KA = Kermit_Handshake_Char   *)
   (* KK = Kermit_Autodownload     *)

   Get_General_Setup( 'KC KD KE KH KN KP KQ K8 KR KS KT KW KL KX KA KK ',
                      'Kermit settings', 'K' );

END   (* Get_Kermit_Setup *);

(*----------------------------------------------------------------------*)
(*  Modem_Post_Processor --- Handle special Modem parameter updates     *)
(*----------------------------------------------------------------------*)

PROCEDURE Modem_Post_Processor( Menu_Item : INTEGER );

BEGIN (* Modem_Post_Processor *)

   Dialing_Dir_Size_Max := MIN( 900 , MAX( Dialing_Dir_Size_Max, 1 ) );

END   (* Modem_Post_Processor *);

(*----------------------------------------------------------------------*)
(*            Get_Modem_Setup --- Get setup values for modem            *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Modem_Setup;

BEGIN (* Get_Modem_Setup *)

   (*  MI = Modem_Init           *)
   (*  MD = Modem_Dial           *)
   (*  MC = Modem_Connect        *)
   (*  MN = Modem_No_Carrier     *)
   (*  MB = Modem_Busy           *)
   (*  ME = Modem_Escape         *)
   (*  MT = Modem_Escape_Time    *)
   (*  MH = Modem_Hang_Up        *)
   (*  MO = Modem_Time_Out       *)
   (*  MR = Modem_Redial_Delay   *)
   (*  MA = Modem_Answer         *)
   (*  MW = Modem_Command_Delay  *)
   (*  CH = Modem_Carrier_High   *)
   (*  BD = Alter_Baud_Rate      *)
   (*  MF = Modem_Dial_End       *)
   (*  US = Use_Short_Dial_Menu  *)
   (*  DS = Dialing_Dir_Size_Max *)
   (*  MG = Modem_Ring           *)
   (*  MG = Modem_Hold_Line      *)

   Get_General_Setup( 'MI MD MC MN MB ME MT MH MO MR MA MW CH BD MF US DS MG ML ',
                      'Modem settings', 'M' );

END   (* Get_Modem_Setup *);

(*----------------------------------------------------------------------*)
(*          Get_Miscellaneous --- Get miscellaneous parameters          *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Miscellaneous;

BEGIN (* Get_Miscellaneous *)

   (* PS = Printer_Setup       *)
   (* PM = Play_Music_On       *)
   (* SM = Silent_Mode         *)
   (* 08 = Date_Format         *)
   (* 07 = Use_Military        *)
   (* 09 = Script_Search_Order *)
   (* SU = Auto_Unload_Scripts *)
   (* AM = Attended_Mode       *)
   (* LO = Logging_On          *)

   Get_General_Setup( 'PS PM SM DF 07 SO SU AM LO ',
                      'Miscellaneous parameters', ' ' );

                                   (* Make sure everything updated *)

   Menu_Set_Beep( NOT Silent_Mode );

   IF Use_Military THEN
      Time_Format := Military_Time
   ELSE
      Time_Format := AMPM_Time;

END   (* Get_Miscellaneous *);

(*----------------------------------------------------------------------*)
(*             Get_File_Paths --- Get various file paths                *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_File_Paths;

BEGIN (* Get_File_Paths *)

   (* EN = Editor_Name        *)
   (* LN = Browser_Name       *)
   (* SD = Screen_Dump_Name   *)
   (* SG = Graphics_Dump_Name *)
   (* DD = Download_Dir_Path  *)
   (* SF = Script_Path        *)
   (* FP = Function_Key_Path  *)
   (* HU = Host_Mode_Upload   *)
   (* HD = Host_Mode_Download *)

   Get_General_Setup( 'EN LN SD SG DD SF FP HU HD ',
                      'File paths', ' ' );

END   (* Get_File_Paths *);

(*----------------------------------------------------------------------*)
(*         Read_A_Config_File --- read configuration parameters         *)
(*----------------------------------------------------------------------*)

PROCEDURE Read_A_Config_File;

VAR
   Local_Save       : Saved_Screen_Ptr;
   Ival             : INTEGER;
   OK_To_Read       : BOOLEAN;
   I                : INTEGER;
   J                : INTEGER;
   Param_Num        : INTEGER;
   Param_Str        : AnyStr;
   Param_Ival       : INTEGER;
   Param_Rval       : LONGINT;
   Config_File_NameL: AnyStr;
   Save_Name        : AnyStr;

BEGIN (* Read_A_Config_File *)

   Save_Screen( Local_Save );

   Draw_Menu_Frame( 10, 19, 70, 24, Menu_Frame_Color, Menu_Title_Color,
                    Menu_Text_Color, 'Read configuration file' );

   PibTerm_Window( 11, 20, 69, 23 );

   GoToXY( 1 , 1 );
                                   (* Get config file name *)

   TextColor( Menu_Text_Color_2 );
   WRITELN('Enter configuration file name:');
   WRITE('>');

   TextColor( Menu_Text_Color );
   Config_File_NameL := Config_File_Name;

   Read_Edited_String( Config_File_NameL );
   WRITELN;

   TextColor( Menu_Text_Color_2 );

                                   (* Stop if no name given     *)

   Config_File_NameL := Trim( LTrim( Config_File_NameL ) );

   IF ( POS( '.' , Config_File_NameL ) = 0 ) THEN
      Config_File_NameL := UpperCase( Config_File_NameL + '.CNF' );

   IF ( Config_File_NameL = '' ) OR
      ( Config_File_NameL = CHR( ESC ) ) THEN
      BEGIN
         Restore_Screen( Local_Save );
         Reset_Global_Colors;
         EXIT;
      END;
                                   (* Add path if needed        *)

   Save_Name := Config_File_NameL;

   Add_Path( Config_File_NameL, Home_Dir, Config_File_NameL );

                                   (* Assign configuration file *)

   ASSIGN( Config_File , Config_File_NameL );
        (*!I-*)
   RESET( Config_File );
        (*!I+*)

   OK_To_Read := ( Int24Result = 0 );

   IF NOT OK_To_Read THEN
      BEGIN (* No configuration file *)

         WRITELN('Can''t find configuration file ',Config_File_NameL);

      END   (* No configuration file *)

   ELSE                           (* file exists -- read it *)
      BEGIN  (* Config file exists *)

         WRITELN('Reading configuration file');

         WHILE( Get_Config_File_Line( Config_File, Param_Num, Param_Str,
                                      Param_Ival, Param_Rval ) ) DO
            IF ( Param_Num > 0 ) THEN
               Set_Parameter( Param_Num, Param_Ival, Param_Rval, Param_Str );

         Config_File_Name := Save_Name;

      END    (* Config file exists *);

        (*!I-*)
   CLOSE( Config_File );
        (*!I+*)

   OK_To_Read := ( Int24Result = 0 );

   Restore_Screen( Local_Save );
   Reset_Global_Colors;
                                   (* Ensure comm port variables reset *)
   Comm_Port_Changed := TRUE;

END   (* Read_A_Config_File *);

(*----------------------------------------------------------------------*)
(*         Get_Terminal_Setup --- Get emulation-related stuff           *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Terminal_Setup;

BEGIN (* Get_Terminal_Setup *)

   (*  TE = Terminal_To_Emulate      *)
   (*  05 = VT100 colors             *)
   (*  GW = Gossip_Window_Size       *)
   (*  GL = Gossip_Line_Mode         *)
   (*  SS = Show_Status_Line         *)
   (*  SE = Show_Status_Time         *)
   (*  SR = Reverse_Status_Colors    *)
   (*  SA = Status_ForeGround_Color  *)
   (*  SB = Status_BackGround_Color  *)
   (*  AK = Auto_Load_FunKeys        *)
   (*  DO = Use_Dos_Con_Output       *)
   (*  T1 = User_Term_Name[1]        *)
   (*  T2 = User_Term_Name[2]        *)
   (*  T3 = User_Term_Name[3]        *)
   (*  T4 = User_Term_Name[4]        *)
   (*  T5 = User_Term_Name[5]        *)

   Get_General_Setup( 'TE 05 GW GL SS SE SR SA SB AK DO T1 T2 T3 T4 T5 ',
                      'Terminal settings', ' ' );

END   (* Get_Terminal_Setup *);

(*----------------------------------------------------------------------*)
(*          Get_Video_Setup --- Get video mode and colors               *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Video_Setup;

VAR
   Save_Scroll : BOOLEAN;

BEGIN (* Get_Video_Setup *)
                                   (* Remember which scroll mode we're in *)

   Save_Scroll  := Software_Scroll_Par;

   (*  TM = New_Text_Mode           *)
   (*  CF = New_Foreground_Color    *)
   (*  CB = New_Background_Color    *)
   (*  CS = New_Border_Color        *)
   (*  CM = New_Menu_Frame_Color    *)
   (*  CC = New_Menu_Title_Color    *)
   (*  CT = New_Menu_Text_Color     *)
   (*  CA = New_Menu_Text_Color_2   *)
   (*  05 = VT100 colors            *)
   (*  WS = Write_Screen_Memory_Par *)
   (*  WR = Wait_For_Retrace_Par    *)
   (*  BB = Max_Review_Length       *)
   (*  XM = Exploding_Menus         *)
   (*  WH = Window hold time        *)
   (*  DL = Max_Screen_Line         *)
   (*  DC = Max_Screen_Col          *)
   (*  SZ = Software_Scroll_Par     *)
   (*  AW = ATI_Ega_Wonder          *)
   (*  EG = Allow_EGA_Graphics      *)

   Get_General_Setup( 'TM CF CB CS CM CC CT CA 05 WS WR BB XM WH DL DC SZ AW EG ',
                      'Video mode and colors', ' ' );

                                   (* Note any change in menu style now *)

   Menu_Set_Explode( Exploding_Menus );

                                   (* Make sure video interrupt  *)
                                   (* changes occur if requested *)

   Video_Interrupt_Change := ( Software_Scroll_Par <> Save_Scroll );

END   (* Get_Video_Setup *);

(*----------------------------------------------------------------------*)
(*     Write_New_Config_File --- write configuration parameters         *)
(*----------------------------------------------------------------------*)

PROCEDURE Write_New_Config_File;

VAR
   Local_Save       : Saved_Screen_Ptr;
   Config_File_NameL: FileStr;

BEGIN (* Write_New_Config_File *)

   Draw_Titled_Box( Local_Save, 10, 19, 70, 24,
                    'Write configuration file' );

   PibTerm_Window( 11, 20, 69, 23 );

   GoToXY( 1 , 1 );

   TextColor( Menu_Text_Color_2 );
   WRITELN('Enter configuration file name:');
   WRITE('>');

   Config_File_NameL := Config_File_Name;

   TextColor( Menu_Text_Color );
   Read_Edited_String( Config_File_NameL );
   WRITELN;

   Config_File_NameL := Trim( LTrim( Config_File_NameL ) );

   IF ( POS( '.' , Config_File_NameL ) = 0 ) THEN
      Config_File_NameL := UpperCase( Config_File_NameL + '.CNF' );

   IF ( Config_File_NameL <> '' ) AND
      ( Config_File_NameL <> CHR( ESC ) ) THEN
      BEGIN
         Write_Config_File( Config_File_NameL );
         Config_File_Name := Config_File_NameL;
         TextColor( Menu_Text_Color_2 );
         WRITE('Configuration file written.');
         Window_Delay;
      END;

   Restore_Screen( Local_Save );
   Reset_Global_Colors;

END   (* Write_New_Config_File *);

(*----------------------------------------------------------------------*)

BEGIN (* Get_Default_Params *)
                                   (* If first time, get important params *)
   IF First_Time THEN
      BEGIN
         Get_Video_Mode;
         Get_Comm_Settings;
         Get_Terminal_Type;
         IF ( NOT Hard_Wired ) THEN
            Get_Modem_Setup;
         Download_Dir_Path := Home_Dir;
         Script_Path       := Home_Dir;
         Function_Key_Path := Home_Dir;
      END
                                   (* Not first time -- prompt for *)
                                   (* params to be changed         *)
   ELSE
      BEGIN
                                   (* Top-level menu count *)
         Menu_Depth  := 1;
         Param_Count := 0;
                                   (* Construct global settings menu *)

         Make_A_Menu( Settings_Menu, Quit_Item, 10, 30, 0, 0, Quit_Item,
                      'Set Parameters: ',
                      'C)ommunications;F)ile transfer;H)ost mode;I)nput;K)ermit;' +
                      'M)odem and dialing;O)dds and ends;'      +
                      'P)aths for special files;' +
                      'R)ead config file;' +
                      'T)erminal emulation;V)ideo mode and colors;' +
                      'W)rite config file;Q)uit setup;',
                      FALSE );

                                   (* Request setup parameters until *)
                                   (* stop setup selected            *)
         REPEAT

            Menu_Display_Choices( Settings_Menu );
            Settings_Choice := Menu_Get_Choice( Settings_Menu , Erase_Menu );

            IF ( Settings_Choice > 0 ) THEN
               Menu_Depth := 2;

            CASE Settings_Choice OF

                1:   Get_Comm_Settings;
                2:   Get_File_Transfer;
                3:   Get_Host_Mode_Setup;
                4:   Get_Input_Setup;
                5:   Get_Kermit_Setup;
                6:   Get_Modem_Setup;
                7:   Get_Miscellaneous;
                8:   Get_File_Paths;
                9:   Read_A_Config_File;
               10:   Get_Terminal_Setup;
               11:   Get_Video_Setup;
               12:   Write_New_Config_File;
               ELSE;

            END (* CASE *);
                                   (* Remember if comm parms changed *)

            Reset_Comm_Port := Reset_Comm_Port OR ( Settings_Choice = 1 );

                                   (* Reset menu depth *)
            Menu_Depth      := 1;
            Param_Count     := 0;

         UNTIL ( Settings_Choice = Quit_Item ) OR
               ( Settings_Choice < 1         );

      END;
                                   (* Reset menu depth *)
   Menu_Depth := 0;

END   (* Get_Default_Params *);
