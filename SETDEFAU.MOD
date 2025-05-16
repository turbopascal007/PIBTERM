(*----------------------------------------------------------------------*)
(*        Set_Defaults --- Set Default Communications Parameters        *)
(*----------------------------------------------------------------------*)

PROCEDURE Set_Defaults;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Set_Defaults                                         *)
(*                                                                      *)
(*     Purpose:    Set default communications parameters                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Set_Defaults;                                                 *)
(*                                                                      *)
(*      Calls:   None                                                   *)
(*                                                                      *)
(*      Remarks:  Note that defaults for color-related variables are    *)
(*                set in PibTerm so that error messages will appear     *)
(*                in a readable form.                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I: INTEGER;
   J: INTEGER;
   F: FILE;

(*----------------------------------------------------------------------*)

PROCEDURE Set_Parameter_Addresses;

BEGIN (* Set_Parameter_Addresses *)

   Parameters[  1].PDesc := @Desc_01;

   Parameters[  2].PDesc := @Desc_02;

   Parameters[  3].PDesc := @Desc_03;

   Parameters[  4].PDesc := @Desc_04;

   Parameters[  5].PDesc := @Desc_05;

   Parameters[  6].PAddr := @Command_Key_Name;
   Parameters[  6].PDesc := @Desc_06;

   Parameters[  7].PAddr := @Use_Military;
   Parameters[  7].PDesc := @Desc_07;
 
   Parameters[  8].PAddr := @Date_Format_String;
   Parameters[  8].PDesc := @Desc_08;
 
   Parameters[  9].PAddr := @Script_Order_String;
   Parameters[  9].PDesc := @Desc_09;
 
   Parameters[ 10].PAddr := @Ascii_CRLF;
   Parameters[ 10].PDesc := @Desc_10;
 
   Parameters[ 11].PDesc := @Desc_11;
 
   Parameters[ 12].PDesc := @Desc_12;
 
   Parameters[ 13].PAddr := @Host_Auto_Baud;
   Parameters[ 13].PDesc := @Desc_AB;
 
   Parameters[ 14].PAddr := @Ascii_Char_Delay;
   Parameters[ 14].PDesc := @Desc_AC;
 
   Parameters[ 15].PAddr := @Ascii_Show_Text;
   Parameters[ 15].PDesc := @Desc_AD;

   Parameters[ 16].PAddr := @Ascii_CR_LF_String;
   Parameters[ 16].PDesc := @Desc_AE;
 
   Parameters[ 17].PAddr := @Ascii_Send_Blank;
   Parameters[ 17].PDesc := @Desc_AF;
 
   Parameters[ 18].PAddr := @Auto_Load_FunKeys;
   Parameters[ 18].PDesc := @Desc_AK;
 
   Parameters[ 19].PAddr := @Ascii_Line_Delay;
   Parameters[ 19].PDesc := @Desc_AL;
 
   Parameters[ 20].PAddr := @Attended_Mode;
   Parameters[ 20].PDesc := @Desc_AM;
 
   Parameters[ 21].PAddr := @Ascii_Pacing_Char;
   Parameters[ 21].PDesc := @Desc_AP;
 
   Parameters[ 22].PAddr := @Ascii_Line_Size;
   Parameters[ 22].PDesc := @Desc_AS;
 
   Parameters[ 23].PAddr := @Ascii_Translate;
   Parameters[ 23].PDesc := @Desc_AT;
 
   Parameters[ 24].PAddr := @Host_CTTY_Device;
   Parameters[ 24].PDesc := @Desc_AU;
 
   Parameters[ 25].PAddr := @ATI_Ega_Wonder;
   Parameters[ 25].PDesc := @Desc_AW;
 
   Parameters[ 26].PAddr := @Ascii_Send_Asis;
   Parameters[ 26].PDesc := @Desc_AX;
 
   Parameters[ 27].PAddr := @Ascii_Use_CtrlZ;
   Parameters[ 27].PDesc := @Desc_AZ;
 
   Parameters[ 28].PAddr := @Baud_Rate;
   Parameters[ 28].PDesc := @Desc_BA;
 
   Parameters[ 29].PAddr := @Max_Review_Length;
   Parameters[ 29].PDesc := @Desc_BB;
 
   Parameters[ 30].PAddr := @Box_Chars;
   Parameters[ 30].PDesc := @Desc_BC;
 
   Parameters[ 31].PAddr := @Alter_Baud_Rate;
   Parameters[ 31].PDesc := @Desc_BD;
 
   Parameters[ 32].PAddr := @Break_Length;
   Parameters[ 32].PDesc := @Desc_BL;

   Parameters[ 33].PAddr := @CompuServe_B_On;
   Parameters[ 33].PDesc := @Desc_BP;
 
   Parameters[ 34].PAddr := @BS_String;
   Parameters[ 34].PDesc := @Desc_BS;
 
   Parameters[ 35].PAddr := @New_Menu_Text_Color_2;
   Parameters[ 35].PDesc := @Desc_CA;
 
   Parameters[ 36].PAddr := @New_BackGround_Color;
   Parameters[ 36].PDesc := @Desc_CB;
 
   Parameters[ 37].PAddr := @New_Menu_Title_Color;
   Parameters[ 37].PDesc := @Desc_CC;
 
   Parameters[ 38].PAddr := @New_ForeGround_Color;
   Parameters[ 38].PDesc := @Desc_CF;

   Parameters[ 39].PAddr := @Modem_Carrier_High;
   Parameters[ 39].PDesc := @Desc_CH;
 
   Parameters[ 40].PAddr := @Close_Comm_For_Dos;
   Parameters[ 40].PDesc := @Desc_CJ;
 
   Parameters[ 41].PAddr := @Command_Key;
   Parameters[ 41].PDesc := @Desc_CK;
 
   Parameters[ 42].PAddr := @New_Menu_Frame_Color;
   Parameters[ 42].PDesc := @Desc_CM;
 
   Parameters[ 43].PAddr := @New_Border_Color;
   Parameters[ 43].PDesc := @Desc_CS;
 
   Parameters[ 44].PAddr := @New_Menu_Text_Color;
   Parameters[ 44].PDesc := @Desc_CT;
 
   Parameters[ 45].PAddr := @Data_Bits;
   Parameters[ 45].PDesc := @Desc_DA;
 
   Parameters[ 46].PAddr := @New_Max_Screen_Col;
   Parameters[ 46].PDesc := @Desc_DC;
 
   Parameters[ 47].PAddr := @Download_Dir_Path;
   Parameters[ 47].PDesc := @Desc_DD;
 
   Parameters[ 48].PAddr := @Ctrl_BS_String;
   Parameters[ 48].PDesc := @Desc_DE;
 
   Parameters[ 49].PAddr := @Date_Format;
   Parameters[ 49].PDesc := @Desc_DF;
 
   Parameters[ 50].PAddr := @Use_Dos_Buffer_In;
   Parameters[ 50].PDesc := @Desc_DI;
 
   Parameters[ 51].PAddr := @New_Max_Screen_Line;
   Parameters[ 51].PDesc := @Desc_DL;
 
   Parameters[ 52].PAddr := @Use_Dos_Con_Output;
   Parameters[ 52].PDesc := @Desc_DO;
 
   Parameters[ 53].PAddr := @Default_Prefix;
   Parameters[ 53].PDesc := @Desc_DP;
 
   Parameters[ 54].PAddr := @Drop_Dtr_At_End;
   Parameters[ 54].PDesc := @Desc_DR;
 
   Parameters[ 55].PAddr := @Dialing_Dir_Size_Max;
   Parameters[ 55].PDesc := @Desc_DS;

   Parameters[ 56].PAddr := @Default_Postfix;
   Parameters[ 56].PDesc := @Desc_DT;
 
   Parameters[ 57].PAddr := @Downsize_Ymodem;
   Parameters[ 57].PDesc := @Desc_DY;
 
   Parameters[ 58].PAddr := @Mahoney_On;
   Parameters[ 58].PDesc := @Desc_EB;
 
   Parameters[ 59].PAddr := @Exact_Capture;
   Parameters[ 59].PDesc := @Desc_EC;
 
   Parameters[ 60].PAddr := @Allow_EGA_Graphics;
   Parameters[ 60].PDesc := @Desc_EG;
 
   Parameters[ 61].PAddr := @Extended_Keypad;
   Parameters[ 61].PDesc := @Desc_EK;

   Parameters[ 62].PAddr := @Editor_Name;
   Parameters[ 62].PDesc := @Desc_EN;
 
   Parameters[ 63].PAddr := @Evict_Partial_Trans;
   Parameters[ 63].PDesc := @Desc_EP;
 
   Parameters[ 64].PAddr := @Extended_Keyboard;
   Parameters[ 64].PDesc := @Desc_EU;
 
   Parameters[ 65].PAddr := @External_Trans_Def[1];
   Parameters[ 65].PDesc := @Desc_F0;
 
   Parameters[ 66].PAddr := @External_Trans_Def[2];
   Parameters[ 66].PDesc := @Desc_F1;
 
   Parameters[ 67].PAddr := @External_Trans_Def[3];
   Parameters[ 67].PDesc := @Desc_F2;
 
   Parameters[ 68].PAddr := @External_Trans_Def[4];
   Parameters[ 68].PDesc := @Desc_F3;
 
   Parameters[ 69].PAddr := @External_Trans_Def[5];
   Parameters[ 69].PDesc := @Desc_F4;
 
   Parameters[ 70].PAddr := @External_Trans_Def[6];
   Parameters[ 70].PDesc := @Desc_F5;
 
   Parameters[ 71].PAddr := @External_Trans_Def[7];
   Parameters[ 71].PDesc := @Desc_F6;
 
   Parameters[ 72].PAddr := @External_Trans_Def[8];
   Parameters[ 72].PDesc := @Desc_F7;
 
   Parameters[ 73].PAddr := @External_Trans_Def[9];
   Parameters[ 73].PDesc := @Desc_F8;
 
   Parameters[ 74].PAddr := @External_Trans_Def[10];
   Parameters[ 74].PDesc := @Desc_F9;
 
   Parameters[ 75].PAddr := @FK_CR;
   Parameters[ 75].PDesc := @Desc_FC;
 
   Parameters[ 76].PAddr := @FK_Delay;
   Parameters[ 76].PDesc := @Desc_FD;
 
   Parameters[ 77].PAddr := @Auto_Find_FileNames;
   Parameters[ 77].PDesc := @Desc_FF;
 
   Parameters[ 78].PAddr := @FK_Delay_Time;
   Parameters[ 78].PDesc := @Desc_FH;

   Parameters[ 79].PAddr := @FK_Ctrl_Mark;
   Parameters[ 79].PDesc := @Desc_FM;
 
   Parameters[ 80].PAddr := @FileName;
   Parameters[ 80].PDesc := @Desc_FN;
 
   Parameters[ 81].PAddr := @Function_Key_Path;
   Parameters[ 81].PDesc := @Desc_FP;
 
   Parameters[ 82].PAddr := @FK_Script_Ch;
   Parameters[ 82].PDesc := @Desc_FS;
 
   Parameters[ 83].PAddr := @FK_Wait_For;
   Parameters[ 83].PDesc := @Desc_FW;
 
   Parameters[ 84].PAddr := @GMT_Difference;
   Parameters[ 84].PDesc := @Desc_GD;

   Parameters[ 85].PAddr := @Gossip_Line_Mode;
   Parameters[ 85].PDesc := @Desc_GL;
 
   Parameters[ 86].PAddr := @Gossip_Window_Size;
   Parameters[ 86].PDesc := @Desc_GW;
 
   Parameters[ 87].PAddr := @Host_Mode_Blank_Time;
   Parameters[ 87].PDesc := @Desc_HB;
 
   Parameters[ 88].PAddr := @Host_Mode_Download;
   Parameters[ 88].PDesc := @Desc_HD;
 
   Parameters[ 89].PAddr := @Privilege;
   Parameters[ 89].PDesc := @Desc_HP;
 
   Parameters[ 90].PAddr := @Host_Mode_Upload;
   Parameters[ 90].PDesc := @Desc_HU;
 
   Parameters[ 91].PAddr := @Hard_Wired;
   Parameters[ 91].PDesc := @Desc_HW;
 
   Parameters[ 92].PAddr := @Default_Com_Irq[1];
   Parameters[ 92].PDesc := @Desc_I1;
 
   Parameters[ 93].PAddr := @Default_Com_Irq[2];
   Parameters[ 93].PDesc := @Desc_I2;
 
   Parameters[ 94].PAddr := @Default_Com_Irq[3];
   Parameters[ 94].PDesc := @Desc_I3;
 
   Parameters[ 95].PAddr := @Default_Com_Irq[4];
   Parameters[ 95].PDesc := @Desc_I4;
 
   Parameters[ 96].PAddr := @Async_Buffer_Length;
   Parameters[ 96].PDesc := @Desc_IB;
 
   Parameters[ 97].PAddr := @Edit_Insert_Mode;
   Parameters[ 97].PDesc := @Desc_IM;
 
   Parameters[ 98].PAddr := @Kermit_Quote_8_Char;
   Parameters[ 98].PDesc := @Desc_K8;
 
   Parameters[ 99].PAddr := @Kermit_Handshake_Char;
   Parameters[ 99].PDesc := @Desc_KA;
 
   Parameters[100].PAddr := @Kermit_Chk_Type;
   Parameters[100].PDesc := @Desc_KC;
 
   Parameters[101].PAddr := @Kermit_Debug;
   Parameters[101].PDesc := @Desc_KD;

   Parameters[102].PAddr := @Kermit_EOL;
   Parameters[102].PDesc := @Desc_KE;
 
   Parameters[103].PAddr := @Kermit_Header_Char;
   Parameters[103].PDesc := @Desc_KH;
 
   Parameters[104].PAddr := @Kermit_AutoDownload;
   Parameters[104].PDesc := @Desc_KK;
 
   Parameters[105].PAddr := @Kermit_Window_Size;
   Parameters[105].PDesc := @Desc_KL;
 
   Parameters[106].PAddr := @Kermit_Npad;
   Parameters[106].PDesc := @Desc_KN;
 
   Parameters[107].PAddr := @Kermit_Pad_Char;
   Parameters[107].PDesc := @Desc_KP;

   Parameters[108].PAddr := @Kermit_Quote_Char;
   Parameters[108].PDesc := @Desc_KQ;
 
   Parameters[109].PAddr := @Kermit_Repeat_Char;
   Parameters[109].PDesc := @Desc_KR;
 
   Parameters[110].PAddr := @Kermit_Init_Packet_Size;
   Parameters[110].PDesc := @Desc_KS;
 
   Parameters[111].PAddr := @Kermit_TimeOut;
   Parameters[111].PDesc := @Desc_KT;
 
   Parameters[112].PAddr := @Kermit_Delay_Time;
   Parameters[112].PDesc := @Desc_KW;
 
   Parameters[113].PAddr := @Kermit_Extended_Block;
   Parameters[113].PDesc := @Desc_KX;
 
   Parameters[114].PAddr := @Local_Echo;
   Parameters[114].PDesc := @Desc_LE;
 
   Parameters[115].PAddr := @Add_Lf;
   Parameters[115].PDesc := @Desc_LF;
 
   Parameters[116].PAddr := @Browser_Name;
   Parameters[116].PDesc := @Desc_LN;
 
   Parameters[117].PAddr := @Logging_On;
   Parameters[117].PDesc := @Desc_LO;
 
   Parameters[118].PAddr := @Modem_Answer;
   Parameters[118].PDesc := @Desc_MA;
 
   Parameters[119].PAddr := @Modem_Busy;
   Parameters[119].PDesc := @Desc_MB;
 
   Parameters[120].PAddr := @Modem_Connect;
   Parameters[120].PDesc := @Desc_MC;
 
   Parameters[121].PAddr := @Modem_Dial;
   Parameters[121].PDesc := @Desc_MD;
 
   Parameters[122].PAddr := @Modem_Escape;
   Parameters[122].PDesc := @Desc_ME;
 
   Parameters[123].PAddr := @Modem_Dial_End;
   Parameters[123].PDesc := @Desc_MF;
 
   Parameters[124].PAddr := @Modem_Ring;
   Parameters[124].PDesc := @Desc_MG;

   Parameters[125].PAddr := @Modem_Hang_Up;
   Parameters[125].PDesc := @Desc_MH;
 
   Parameters[126].PAddr := @Modem_Init;
   Parameters[126].PDesc := @Desc_MI;
 
   Parameters[127].PAddr := @Modem_Hold_Line;
   Parameters[127].PDesc := @Desc_ML;
 
   Parameters[128].PAddr := @Modem_No_Carrier;
   Parameters[128].PDesc := @Desc_MN;
 
   Parameters[129].PAddr := @Modem_Time_Out;
   Parameters[129].PDesc := @Desc_MO;
 
   Parameters[130].PAddr := @Modem_Redial_Delay;
   Parameters[130].PDesc := @Desc_MR;

   Parameters[131].PAddr := @Modem_Host_Set;
   Parameters[131].PDesc := @Desc_MS;
 
   Parameters[132].PAddr := @Modem_Escape_Time;
   Parameters[132].PDesc := @Desc_MT;
 
   Parameters[133].PAddr := @Modem_Command_Delay;
   Parameters[133].PDesc := @Desc_MW;
 
   Parameters[134].PAddr := @Modem_Host_UnSet;
   Parameters[134].PDesc := @Desc_MX;
 
   Parameters[135].PAddr := @New_Line_Param;
   Parameters[135].PDesc := @Desc_NL;
 
   Parameters[136].PAddr := @Async_OBuffer_Length;
   Parameters[136].PDesc := @Desc_OB;
 
   Parameters[137].PAddr := @Default_Com_Base[1];
   Parameters[137].PDesc := @Desc_P1;
 
   Parameters[138].PAddr := @Default_Com_Base[2];
   Parameters[138].PDesc := @Desc_P2;
 
   Parameters[139].PAddr := @Default_Com_Base[3];
   Parameters[139].PDesc := @Desc_P3;
 
   Parameters[140].PAddr := @Default_Com_Base[4];
   Parameters[140].PDesc := @Desc_P4;
 
   Parameters[141].PAddr := @Parity;
   Parameters[141].PDesc := @Desc_PA;
 
   Parameters[142].PAddr := @Play_Music_On;
   Parameters[142].PDesc := @Desc_PM;
 
   Parameters[143].PAddr := @Comm_Port;
   Parameters[143].PDesc := @Desc_PO;
 
   Parameters[144].PAddr := @Printer_Setup;
   Parameters[144].PDesc := @Desc_PS;
 
   Parameters[145].PAddr := @Status_ForeGround_Color;
   Parameters[145].PDesc := @Desc_SA;
 
   Parameters[146].PAddr := @Status_BackGround_Color;
   Parameters[146].PDesc := @Desc_SB;
 
   Parameters[147].PAddr := @Script_Learn_Buffer_Size;
   Parameters[147].PDesc := @Desc_SC;

   Parameters[148].PAddr := @Screen_Dump_Name;
   Parameters[148].PDesc := @Desc_SD;
 
   Parameters[149].PAddr := @Show_Status_Time;
   Parameters[149].PDesc := @Desc_SE;
 
   Parameters[150].PAddr := @Script_Path;
   Parameters[150].PDesc := @Desc_SF;
 
   Parameters[151].PAddr := @Graphics_Dump_Name;
   Parameters[151].PDesc := @Desc_SG;
 
   Parameters[152].PAddr := @Auto_Strip_High_Bit;
   Parameters[152].PDesc := @Desc_SH;
 
   Parameters[153].PAddr := @Script_Learn_Lines;
   Parameters[153].PDesc := @Desc_SL;

   Parameters[154].PAddr := @Silent_Mode;
   Parameters[154].PDesc := @Desc_SM;
 
   Parameters[155].PAddr := @Script_Search_Order;
   Parameters[155].PDesc := @Desc_SO;
 
   Parameters[156].PAddr := @Script_Parameter_Marker;
   Parameters[156].PDesc := @Desc_SP;
 
   Parameters[157].PAddr := @Reverse_Status_Colors;
   Parameters[157].PDesc := @Desc_SR;
 
   Parameters[158].PAddr := @Show_Status_Line;
   Parameters[158].PDesc := @Desc_SS;
 
   Parameters[159].PAddr := @Stop_Bits;
   Parameters[159].PDesc := @Desc_ST;
 
   Parameters[160].PAddr := @Auto_Unload_Scripts;
   Parameters[160].PDesc := @Desc_SU;
 
   Parameters[161].PAddr := @Software_Scroll_Par;
   Parameters[161].PDesc := @Desc_SZ;
 
   Parameters[162].PAddr := @User_Term_Name[1];
   Parameters[162].PDesc := @Desc_T1;
 
   Parameters[163].PAddr := @User_Term_Name[2];
   Parameters[163].PDesc := @Desc_T2;
 
   Parameters[164].PAddr := @User_Term_Name[3];
   Parameters[164].PDesc := @Desc_T3;
 
   Parameters[165].PAddr := @User_Term_Name[4];
   Parameters[165].PDesc := @Desc_T4;
 
   Parameters[166].PAddr := @User_Term_Name[5];
   Parameters[166].PDesc := @Desc_T5;
 
   Parameters[167].PAddr := @Transfer_Bells;
   Parameters[167].PDesc := @Desc_TB;
 
   Parameters[168].PAddr := @Terminal_To_Emulate;
   Parameters[168].PDesc := @Desc_TE;
 
   Parameters[169].PAddr := @Time_Format;
   Parameters[169].PDesc := @Desc_TF;
 
   Parameters[170].PAddr := @New_Text_Mode;
   Parameters[170].PDesc := @Desc_TM;

   Parameters[171].PAddr := @Default_Transfer_Type;
   Parameters[171].PDesc := @Desc_TT;
 
   Parameters[172].PAddr := @Send_Upper_Case_Only;
   Parameters[172].PDesc := @Desc_TU;
 
   Parameters[173].PAddr := @Use_Block_Zero;
   Parameters[173].PDesc := @Desc_U0;
 
   Parameters[174].PAddr := @Use_Prev_Key_Text;
   Parameters[174].PDesc := @Desc_UP;
 
   Parameters[175].PAddr := @Use_Short_Dial_Menu;
   Parameters[175].PDesc := @Desc_US;
 
   Parameters[176].PAddr := @Default_Com_Int[1];
   Parameters[176].PDesc := @Desc_V1;

   Parameters[177].PAddr := @Default_Com_Int[2];
   Parameters[177].PDesc := @Desc_V2;
 
   Parameters[178].PAddr := @Default_Com_Int[3];
   Parameters[178].PDesc := @Desc_V3;
 
   Parameters[179].PAddr := @Default_Com_Int[4];
   Parameters[179].PDesc := @Desc_V4;
 
   Parameters[180].PAddr := @VT100_Answerback_Message;
   Parameters[180].PDesc := @Desc_VA;
 
   Parameters[181].PAddr := @VT100_BackGround_Color;
   Parameters[181].PDesc := @Desc_VB;
 
   Parameters[182].PAddr := @Auto_Change_Arrows;
   Parameters[182].PDesc := @Desc_VC;
 
   Parameters[183].PAddr := @VT100_Bold_Color;
   Parameters[183].PDesc := @Desc_VE;
 
   Parameters[184].PAddr := @VT100_ForeGround_Color;
   Parameters[184].PDesc := @Desc_VF;
 
   Parameters[185].PAddr := @KeyPad_Appl_On_File;
   Parameters[185].PDesc := @Desc_VK;
 
   Parameters[186].PAddr := @KeyPad_Appl_Off_File;
   Parameters[186].PDesc := @Desc_VN;
 
   Parameters[187].PAddr := @VT100_Border_Color;
   Parameters[187].PDesc := @Desc_VS;
 
   Parameters[188].PAddr := @VT100_Underline_Color;
   Parameters[188].PDesc := @Desc_VU;
 
   Parameters[189].PAddr := @Window_Hold_Time;
   Parameters[189].PDesc := @Desc_WH;
 
   Parameters[190].PAddr := @Wait_For_Retrace_Par;
   Parameters[190].PDesc := @Desc_WR;
 
   Parameters[191].PAddr := @Write_Screen_Memory_Par;
   Parameters[191].PDesc := @Desc_WS;
 
   Parameters[192].PAddr := @Xmodem_Ack_Wait;
   Parameters[192].PDesc := @Desc_XA;
 
   Parameters[193].PAddr := @Max_Write_Buffer;
   Parameters[193].PDesc := @Desc_XB;

   Parameters[194].PAddr := @Xmodem_Char_Wait;
   Parameters[194].PDesc := @Desc_XC;
 
   Parameters[195].PAddr := @Check_DSR;
   Parameters[195].PDesc := @Desc_XD;
 
   Parameters[196].PAddr := @Xmodem_Block_Wait;
   Parameters[196].PDesc := @Desc_XH;
 
   Parameters[197].PAddr := @Exploding_Menus;
   Parameters[197].PDesc := @Desc_XM;
 
   Parameters[198].PAddr := @Do_Xon_Xoff_Checks;
   Parameters[198].PDesc := @Desc_XO;
 
   Parameters[199].PAddr := @Check_CTS;
   Parameters[199].PDesc := @Desc_XS;

   Parameters[200].PAddr := @Xmodem_Max_Errors;
   Parameters[200].PDesc := @Desc_XT;
 
   Parameters[201].PAddr := @Use_Ymodem_Header;
   Parameters[201].PDesc := @Desc_Y0;
 
   Parameters[202].PAddr := @Use_Full_Path_Name;
   Parameters[202].PDesc := @Desc_YF;
 
   Parameters[203].PAddr := @YTerm_On;
   Parameters[203].PDesc := @Desc_YT;
 
   Parameters[204].PAddr := @Honor_XOff_Ymodem;
   Parameters[204].PDesc := @Desc_YX;
 
   Parameters[205].PAddr := @Zmodem_AutoDownload;
   Parameters[205].PDesc := @Desc_ZA;
 
   Parameters[206].PAddr := @Zmodem_BlockSize;
   Parameters[206].PDesc := @Desc_ZB;
 
END   (* Set_Parameter_Addresses *);

(*----------------------------------------------------------------------*)

BEGIN (* Set_Defaults *)
                                   (* Version number and date *)

   PibTerm_Version := '4.1.3 Production.';
   PibTerm_Date    := 'Released March 23, 1988.';

                                   (* Assume text mode from    *)
                                   (* current system setting.  *)

   Start_Video_Mode := Current_Video_Mode;

   CASE Start_Video_Mode OF

      0, 2 : Text_Mode := BW80;
      7    : Text_Mode := Mono;
      ELSE   Text_Mode := C80;

   END (* CASE *);

   TextMode( Text_Mode );
   DirectVideo := FALSE;
                                   (* Set screen sizes         *)

   Get_Screen_Size( New_Max_Screen_Line , New_Max_Screen_Col );

   Max_Screen_Line     := New_Max_Screen_Line;
   Max_Screen_Col      := New_Max_Screen_Col;

   Wrap_Screen_Col     := Max_Screen_Col;

                                   (* Set window sizes         *)
   Upper_Left_Column   := 1;
   Upper_Left_Row      := 1;
   Lower_Right_Column  := Max_Screen_Col;
   Lower_Right_Row     := Max_Screen_Line;

   Ansi_Last_Line      := Max_Screen_Line;

                                   (* No terminal attributes *)

   FillChar( Line_Attributes, 100, 0 );

                                   (* Get session start time   *)

   Session_Start_Time := TimeOfDay;
   Dialing_Start_Time := Session_Start_Time;

                                   (* Select color/mono screen *)

   Get_Screen_Address( Actual_Screen );

                                   (* Set colors as black and white *)

   Set_Global_Colors( White, Black );
   Set_Border_Color ( Black );

   WITH Phone_Entry_Data DO
      BEGIN
         FOR I := 1 TO 25 Do
            Phone_Name[I] := ' ';
         FOR I := 1 TO 15 DO
            Phone_Number[I] := ' ';
      END;
                                   (* Set retrace based upon display type *)

   VGA_Present          := VGA_Installed;
   EGA_Present          := EGA_Installed OR VGA_Present;

   Wait_For_Retrace_Par := NOT ( EGA_Present OR ( Text_Mode = 7 ) );
   Wait_For_Retrace     := Wait_For_Retrace_Par;

                                   (* Initial translate maps each *)
                                   (* character into itself.      *)
   FOR I := 0 TO 255 DO
      TrTab[ CHR( I ) ] := CHR( I );

                                   (* No key strings yet defined. *)
   FOR I := 0 TO Max_Key_Def DO
      BEGIN
         Key_Definitions[I].Def  := NIL;
         Key_Definitions[I].Name := '';
         Key_Indices[ I ]        := I;
      END;
                                   (* Initialize command table *)
   FOR I := 0 TO 255 DO
      Pibterm_Command_Table[I] := Null_Command;

   PibTerm_Command_Table[Alt_A] := EditSy;
   PibTerm_Command_Table[Alt_B] := BreakSy;
   PibTerm_Command_Table[Alt_C] := ClearSy;
   PibTerm_Command_Table[Alt_D] := DialSy;
   PibTerm_Command_Table[Alt_E] := EchoSy;
   PibTerm_Command_Table[Alt_F] := FileSy;
   PibTerm_Command_Table[Alt_G] := ScriptSy;
   PibTerm_Command_Table[Alt_H] := HangUpSy;
   PibTerm_Command_Table[Alt_I] := InfoSy;
   PibTerm_Command_Table[Alt_J] := DosSy;
   PibTerm_Command_Table[Alt_K] := KeySy;
   PibTerm_Command_Table[Alt_L] := LogSy;
   PibTerm_Command_Table[Alt_M] := MuteSy;
   PibTerm_Command_Table[Alt_N] := FastCSy;
   PibTerm_Command_Table[Alt_O] := CaptureSy;
   PibTerm_Command_Table[Alt_P] := ParamSy;
   PibTerm_Command_Table[Alt_Q] := RedialSy;
   PibTerm_Command_Table[Alt_R] := ReceiveSy;
   PibTerm_Command_Table[Alt_S] := SendSy;
   PibTerm_Command_Table[Alt_T] := TranslateSy;
   PibTerm_Command_Table[Alt_U] := SDumpSy;
   PibTerm_Command_Table[Alt_V] := ViewSy;
   PibTerm_Command_Table[Alt_W] := HostSy;
   PibTerm_Command_Table[Alt_X] := QuitSy;
   PibTerm_Command_Table[Alt_Y] := TimersSy;
   PibTerm_Command_Table[Alt_Z] := AreaCodeSy;

   PibTerm_Command_Table[U_Arrow]      := KeySendSy;
   PibTerm_Command_Table[Alt_U_Arrow]  := KeySendSy;
   PibTerm_Command_Table[Ctrl_U_Arrow] := KeySendSy;

   PibTerm_Command_Table[L_Arrow]      := KeySendSy;
   PibTerm_Command_Table[Alt_L_Arrow]  := KeySendSy;
   PibTerm_Command_Table[Ctrl_L_Arrow] := KeySendSy;

   PibTerm_Command_Table[R_Arrow]      := KeySendSy;
   PibTerm_Command_Table[Alt_R_Arrow]  := KeySendSy;
   PibTerm_Command_Table[Ctrl_R_Arrow] := KeySendSy;

   PibTerm_Command_Table[D_Arrow]      := KeySendSy;
   PibTerm_Command_Table[Alt_D_Arrow]  := KeySendSy;
   PibTerm_Command_Table[Ctrl_D_Arrow] := KeySendSy;

   PibTerm_Command_Table[Home]         := KeySendSy;
   PibTerm_Command_Table[Alt_Home]     := KeySendSy;
   PibTerm_Command_Table[Ctrl_Home]    := KeySendSy;

   PibTerm_Command_Table[PgUp]         := KeySendSy;
   PibTerm_Command_Table[Alt_PgUp]     := KeySendSy;
   PibTerm_Command_Table[Ctrl_PgUp]    := KeySendSy;

   PibTerm_Command_Table[End_Key]      := KeySendSy;
   PibTerm_Command_Table[Alt_End_Key]  := KeySendSy;
   PibTerm_Command_Table[Ctrl_End_Key] := KeySendSy;

   PibTerm_Command_Table[PgDn]         := KeySendSy;
   PibTerm_Command_Table[Alt_PgDn]     := KeySendSy;
   PibTerm_Command_Table[Ctrl_PgDn]    := KeySendSy;

   PibTerm_Command_Table[Ins_Key]      := KeySendSy;
   PibTerm_Command_Table[Alt_Ins_Key]  := KeySendSy;
   PibTerm_Command_Table[Ctrl_Ins_Key] := KeySendSy;

   PibTerm_Command_Table[Del_Key]      := KeySendSy;
   PibTerm_Command_Table[Alt_Del_Key]  := KeySendSy;
   PibTerm_Command_Table[Ctrl_Del_Key] := KeySendSy;

   PibTerm_Command_Table[Kpd_Minus]      := KeySendSy;
   PibTerm_Command_Table[Alt_Kpd_Minus]  := KeySendSy;
   PibTerm_Command_Table[Ctrl_Kpd_Minus] := KeySendSy;

   PibTerm_Command_Table[Kpd_Plus]       := KeySendSy;
   PibTerm_Command_Table[Alt_Kpd_Plus]   := KeySendSy;
   PibTerm_Command_Table[Ctrl_Kpd_Plus]  := KeySendSy;

   PibTerm_Command_Table[Kpd_5]          := KeySendSy;
   PibTerm_Command_Table[Alt_Kpd_5]      := KeySendSy;
   PibTerm_Command_Table[Ctrl_Kpd_5]     := KeySendSy;

   PibTerm_Command_Table[Alt_Enter]      := KeySendSy;
   PibTerm_Command_Table[Alt_BS]         := KeySendSy;

   PibTerm_Command_Table[Kpd_Enter]      := KeySendSy;
   PibTerm_Command_Table[Alt_Kpd_Enter]  := KeySendSy;
   PibTerm_Command_Table[Ctrl_Kpd_Enter] := KeySendSy;

   PibTerm_Command_Table[Kpd_Star]       := KeySendSy;
   PibTerm_Command_Table[Alt_Kpd_Star]   := KeySendSy;
   PibTerm_Command_Table[Ctrl_Kpd_Star]  := KeySendSy;

   PibTerm_Command_Table[Kpd_Slash]      := KeySendSy;
   PibTerm_Command_Table[Alt_Kpd_Slash]  := KeySendSy;
   PibTerm_Command_Table[Ctrl_Kpd_Slash] := KeySendSy;

   PibTerm_Command_Table[PrtSc]          := KeySendSy;
   PibTerm_Command_Table[Alt_PrtSc]      := KeySendSy;
   PibTerm_Command_Table[Ctrl_PrtSc]     := KeySendSy;

   PibTerm_Command_Table[X_U_Arrow]      := KeySendSy;
   PibTerm_Command_Table[Alt_X_U_Arrow]  := KeySendSy;
   PibTerm_Command_Table[Ctrl_X_U_Arrow] := KeySendSy;

   PibTerm_Command_Table[X_L_Arrow]      := KeySendSy;
   PibTerm_Command_Table[Alt_X_L_Arrow]  := KeySendSy;
   PibTerm_Command_Table[Ctrl_X_L_Arrow] := KeySendSy;

   PibTerm_Command_Table[X_R_Arrow]      := KeySendSy;
   PibTerm_Command_Table[Alt_X_R_Arrow]  := KeySendSy;
   PibTerm_Command_Table[Ctrl_X_R_Arrow] := KeySendSy;

   PibTerm_Command_Table[X_D_Arrow]      := KeySendSy;
   PibTerm_Command_Table[Alt_X_D_Arrow]  := KeySendSy;
   PibTerm_Command_Table[Ctrl_X_D_Arrow] := KeySendSy;

   PibTerm_Command_Table[X_Home]         := KeySendSy;
   PibTerm_Command_Table[Alt_X_Home]     := KeySendSy;
   PibTerm_Command_Table[Ctrl_X_Home]    := KeySendSy;

   PibTerm_Command_Table[X_PgUp]         := KeySendSy;
   PibTerm_Command_Table[Alt_X_PgUp]     := KeySendSy;
   PibTerm_Command_Table[Ctrl_X_PgUp]    := KeySendSy;

   PibTerm_Command_Table[X_End_Key]      := KeySendSy;
   PibTerm_Command_Table[Alt_X_End_Key]  := KeySendSy;
   PibTerm_Command_Table[Ctrl_X_End_Key] := KeySendSy;

   PibTerm_Command_Table[X_PgDn]         := KeySendSy;
   PibTerm_Command_Table[Alt_X_PgDn]     := KeySendSy;
   PibTerm_Command_Table[Ctrl_X_PgDn]    := KeySendSy;

   PibTerm_Command_Table[X_Ins_Key]      := KeySendSy;
   PibTerm_Command_Table[Alt_X_Ins_Key]  := KeySendSy;
   PibTerm_Command_Table[Ctrl_X_Ins_Key] := KeySendSy;

   PibTerm_Command_Table[X_Del_Key]      := KeySendSy;
   PibTerm_Command_Table[Alt_X_Del_Key]  := KeySendSy;
   PibTerm_Command_Table[Ctrl_X_Del_Key] := KeySendSy;

                                   (* Initialize key names *)
   FOR I := F1 TO F10 DO
      BEGIN
         PibTerm_Command_Table[I] := KeySendSy;
         Key_Definitions[I].Name  := 'F' + IToS( I - F1 + 1 );
      END;

   FOR I := Alt_F1 TO Alt_F10 DO
      BEGIN
         PibTerm_Command_Table[I] := KeySendSy;
         Key_Definitions[I].Name  := 'A' + IToS( I - Alt_F1 + 1 );
      END;

   FOR I := Shift_F1 TO Shift_F10 DO
      BEGIN
         PibTerm_Command_Table[I] := KeySendSy;
         Key_Definitions[I].Name  := 'S' + IToS( I - Shift_F1 + 1 );
      END;

   FOR I := Ctrl_F1 TO Ctrl_F10 DO
      BEGIN
         PibTerm_Command_Table[I] := KeySendSy;
         Key_Definitions[I].Name  := 'C' + IToS( I - Ctrl_F1 + 1 );
      END;

   FOR I := Alt_1 TO Alt_Equal DO
      BEGIN
         PibTerm_Command_Table[I] := KeySendSy;
         Key_Definitions[I].Name  := 'N'+ COPY( '1234567890-+', I - Alt_1 + 1, 1 );
      END;

   FOR I := F11 TO Alt_F12 DO
      PibTerm_Command_Table[I] := KeySendSy;

   Key_Definitions[F11].Name          := 'F11';
   Key_Definitions[F12].Name          := 'F12';
   Key_Definitions[Shift_F11].Name    := 'S11';
   Key_Definitions[Shift_F12].Name    := 'S12';
   Key_Definitions[Ctrl_F11].Name     := 'C11';
   Key_Definitions[Ctrl_F12].Name     := 'C12';
   Key_Definitions[Alt_F11].Name      := 'A11';
   Key_Definitions[Alt_F12].Name      := 'A12';

   Key_Definitions[U_Arrow].Name      := 'K8';
   Key_Definitions[Alt_U_Arrow].Name  := 'AK8';
   Key_Definitions[Ctrl_U_Arrow].Name := 'CK8';

   Key_Definitions[L_Arrow].Name      := 'K4';
   Key_Definitions[Alt_L_Arrow].Name  := 'AK4';
   Key_Definitions[Ctrl_L_Arrow].Name := 'CK4';

   Key_Definitions[R_Arrow].Name      := 'K6';
   Key_Definitions[Alt_R_Arrow].Name  := 'AK6';
   Key_Definitions[Ctrl_R_Arrow].Name := 'CK6';

   Key_Definitions[D_Arrow].Name      := 'K2';
   Key_Definitions[Alt_D_Arrow].Name  := 'AK2';
   Key_Definitions[Ctrl_D_Arrow].Name := 'CK2';

   Key_Definitions[Home].Name         := 'K7';
   Key_Definitions[Alt_Home].Name     := 'AK7';
   Key_Definitions[Ctrl_Home].Name    := 'CK7';

   Key_Definitions[PgUp].Name         := 'K9';
   Key_Definitions[Alt_PgUp].Name     := 'AK9';
   Key_Definitions[Ctrl_PgUp].Name    := 'CK9';

   Key_Definitions[End_Key].Name      := 'K1';
   Key_Definitions[Alt_End_Key].Name  := 'AK1';
   Key_Definitions[Ctrl_End_Key].Name := 'CK1';

   Key_Definitions[PgDn].Name         := 'K3';
   Key_Definitions[Alt_PgDn].Name     := 'AK3';
   Key_Definitions[Ctrl_PgDn].Name    := 'CK3';

   Key_Definitions[Ins_Key].Name      := 'K0';
   Key_Definitions[Alt_Ins_Key].Name  := 'AK0';
   Key_Definitions[Ctrl_Ins_Key].Name := 'CK0';

   Key_Definitions[Del_Key].Name      := 'K.';
   Key_Definitions[Alt_Del_Key].Name  := 'AK.';
   Key_Definitions[Ctrl_Del_Key].Name := 'CK.';

   Key_Definitions[Kpd_Minus].Name      := 'K-';
   Key_Definitions[Alt_Kpd_Minus].Name  := 'AK-';
   Key_Definitions[Ctrl_Kpd_Minus].Name := 'CK-';

   Key_Definitions[Kpd_Plus].Name       := 'K+';
   Key_Definitions[Alt_Kpd_Plus].Name   := 'AK+';
   Key_Definitions[Ctrl_Kpd_Plus].Name  := 'CK+';

   Key_Definitions[Kpd_5].Name          := 'K5';
   Key_Definitions[Alt_Kpd_5].Name      := 'AK5';
   Key_Definitions[Ctrl_Kpd_5].Name     := 'CK5';

   Key_Definitions[Alt_Enter].Name      := 'AEN';

   Key_Definitions[Alt_BS].Name         := 'ABS';
   Key_Definitions[BS_Key].Name         := 'BS';
   Key_Definitions[Ctrl_BS_Key].Name    := 'CBS';

   Key_Definitions[PrtSc].Name          := 'PS';
   Key_Definitions[Alt_PrtSc].Name      := 'APS';
   Key_Definitions[Ctrl_PrtSc].Name     := 'CPS';

   Key_Definitions[Kpd_Enter].Name      := 'KE';
   Key_Definitions[Alt_Kpd_Enter].Name  := 'AKE';
   Key_Definitions[Ctrl_Kpd_Enter].Name := 'CKE';

   Key_Definitions[Kpd_Star].Name       := 'K*';
   Key_Definitions[Alt_Kpd_Star].Name   := 'AK*';
   Key_Definitions[Ctrl_Kpd_Star].Name  := 'CK*';

   Key_Definitions[Kpd_Slash].Name      := 'K/';
   Key_Definitions[Alt_Kpd_Slash].Name  := 'AK/';
   Key_Definitions[Ctrl_Kpd_Slash].Name := 'CK/';

   Key_Definitions[X_U_Arrow].Name      := 'XU';
   Key_Definitions[Alt_X_U_Arrow].Name  := 'AXU';
   Key_Definitions[Ctrl_X_U_Arrow].Name := 'CXU';

   Key_Definitions[X_L_Arrow].Name      := 'XL';
   Key_Definitions[Alt_X_L_Arrow].Name  := 'AXL';
   Key_Definitions[Ctrl_X_L_Arrow].Name := 'CXL';

   Key_Definitions[X_R_Arrow].Name      := 'XR';
   Key_Definitions[Alt_X_R_Arrow].Name  := 'AXR';
   Key_Definitions[Ctrl_X_R_Arrow].Name := 'CXR';

   Key_Definitions[X_D_Arrow].Name      := 'XD';
   Key_Definitions[Alt_X_D_Arrow].Name  := 'AXD';
   Key_Definitions[Ctrl_X_D_Arrow].Name := 'CXD';

   Key_Definitions[X_Home].Name         := 'XH';
   Key_Definitions[Alt_X_Home].Name     := 'AXH';
   Key_Definitions[Ctrl_X_Home].Name    := 'CXH';

   Key_Definitions[X_PgUp].Name         := 'XPU';
   Key_Definitions[Alt_X_PgUp].Name     := 'AXPU';
   Key_Definitions[Ctrl_X_PgUp].Name    := 'CXPU';

   Key_Definitions[X_End_Key].Name      := 'XE';
   Key_Definitions[Alt_X_End_Key].Name  := 'AXE';
   Key_Definitions[Ctrl_X_End_Key].Name := 'CXE';

   Key_Definitions[X_PgDn].Name         := 'XPD';
   Key_Definitions[Alt_X_PgDn].Name     := 'AXPD';
   Key_Definitions[Ctrl_X_PgDn].Name    := 'CXPD';

   Key_Definitions[X_Ins_Key].Name      := 'XI';
   Key_Definitions[Alt_X_Ins_Key].Name  := 'AXI';
   Key_Definitions[Ctrl_X_Ins_Key].Name := 'CXI';

   Key_Definitions[X_Del_Key].Name      := 'XDE';
   Key_Definitions[Alt_X_Del_Key].Name  := 'AXDE';
   Key_Definitions[Ctrl_X_Del_Key].Name := 'CXDE';

                                   (* Get sort index vector of key names *)


                                   (* Define BackSpace and Ctrl-BackSpace *)

   Key_Definitions[BS_Key].Def      := @BS_String;
   Key_Definitions[Ctrl_BS_Key].Def := @Ctrl_BS_String;

                                   (* Allow extended keyboard if there    *)

   Extended_KeyBoard    := ( ( Mem[$40:$96] AND $10 ) <> 0 );

                                   (* Debugging in Kermit *)

   Kermit_Debug          := Debug_Mode;

                                   (* Allocate keyboard/consol file       *)
   Script_File_Used[0]   := TRUE;

   NEW( Script_File_List[0] );

   IF( Script_File_List[0] = NIL ) THEN
      HALT( HeapTooSmall );

   WITH Script_File_List[0]^ DO
      BEGIN
         ReadOnly  := FALSE;
         EOF_Seen  := FALSE;
         Opened    := TRUE;
      END;
                                   (* Other files not used yet            *)

   FOR I := 1 TO MaxScriptOpenFiles DO
      Script_File_Used[I] := FALSE;

                                   (* Initialize display actions and *)
                                   (* character sets.                *)

   FOR I := 1 TO MaxDisplayStates DO
      Display_Action_Ptr[I] := NIL;

   FOR I := 1 TO MaxDisplayCharSets DO
      Display_Char_Set_Ptr[I] := NIL;

   NEW( Display_Action_Ptr[1]   );

   IF( Display_Action_Ptr[1] = NIL ) THEN
      HALT( HeapTooSmall );

   NEW( Display_Char_Set_Ptr[1] );

   IF( Display_Char_Set_Ptr[1] = NIL ) THEN
      HALT( HeapTooSmall );

   NEW( Display_Char_Set_Ptr[2] );

   IF( Display_Char_Set_Ptr[2] = NIL ) THEN
      HALT( HeapTooSmall );

                                   (* Set menu box characters *)
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
                                   (* Set parameter addresses  *)
   Set_Parameter_Addresses;
                                   (* Clear screen             *)

   Scroll( 1, Max_Screen_Line, 1, Max_Screen_Col, 0, White, Black );
   MoveToXY( 1 , 1 );

END   (* Set_Defaults *);
