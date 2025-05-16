UNIT GlobRout;

INTERFACE

USES
   Dos,      Crt,      GlobType, StringMan, PibTimer, OverMgr, PibMTask,
   PibAsync, PT4Patch;

(* EXPORTS *)

   PROCEDURE GiveAwayTime( NSlices : INTEGER );
   PROCEDURE Print_Spooled_File;
   PROCEDURE FastTime( VAR HourMin: INTEGER );
   PROCEDURE Write_To_Status_Line( S: AnyStr; X: INTEGER );
   PROCEDURE Update_Status_Line;
   FUNCTION PibTerm_KeyPressed : BOOLEAN;
   FUNCTION ReadKeyboard : CHAR;
   PROCEDURE Error_Handler;
   FUNCTION Color_Screen_Active : BOOLEAN;
   PROCEDURE Set_Text_Mode( Text_Mode : INTEGER );
   PROCEDURE Read_Kbd( VAR Ch: CHAR );
   PROCEDURE Read_Kbd_Old( VAR Ch: CHAR );
   PROCEDURE Press_Any;
   PROCEDURE Sound_Bell;
   PROCEDURE Keyboard_Interrupt_Handler(
             Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP : WORD );
      Interrupt;
   PROCEDURE Ext_Keyboard_Interrupt_Handler(
             Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP : WORD );
      Interrupt;
   PROCEDURE Install_Keyboard_Handler;
   PROCEDURE Remove_Keyboard_Handler;
   FUNCTION Open_For_Append( VAR F      : Text_File;
                                 F_Name : AnyStr   ;
                             VAR Error  : INTEGER   ) : BOOLEAN;
   PROCEDURE Update_Review_Pointers;
   PROCEDURE Write_Log( T            : AnyStr;
                        Continuation : BOOLEAN;
                        On_Screen    : BOOLEAN  );
   PROCEDURE PibTerm_Window( X1, Y1, X2, Y2 : INTEGER );
   FUNCTION Current_Video_Mode: INTEGER;
   FUNCTION EGA_Installed : BOOLEAN;
   FUNCTION VGA_Installed : BOOLEAN;
   PROCEDURE Get_Screen_Address( VAR Actual_Screen : Screen_Ptr );
   FUNCTION Get_Rows_For_EGA : INTEGER;
   PROCEDURE RvsVideoOn( Foreground_Color, Background_Color : INTEGER );
   PROCEDURE RvsVideoOff( Foreground_Color, Background_Color : INTEGER );
   PROCEDURE CursorOn;
   PROCEDURE CursorOff;
   PROCEDURE CursorGet( VAR Current_Cursor : INTEGER );
   PROCEDURE CursorSet( New_Cursor_Type : INTEGER );
   PROCEDURE Upper_Left( VAR X1, Y1 : INTEGER );
   PROCEDURE Set_Global_Colors( ForeGround, BackGround : INTEGER );
   PROCEDURE Reset_Global_Colors;
   PROCEDURE Set_Border_Color( The_Border_Color : INTEGER );
   PROCEDURE Change_Attributes( NAttr: INTEGER;
                                X    : INTEGER;
                                Y    : INTEGER;
                                Color: INTEGER );
   PROCEDURE Set_Text_Attributes( X1, Y1, X2, Y2, FG, BG : INTEGER );
   PROCEDURE ReadCXY( VAR C     ;
                          X         : INTEGER;
                          Y         : INTEGER;
                      VAR Color );
   PROCEDURE MoveToScreen( VAR Source, Dest; SLen: INTEGER );
   PROCEDURE MoveFromScreen( VAR Source, Dest; SLen: INTEGER );
   PROCEDURE Get_Screen_Text_Line( VAR Text_Line     : AnyStr;
                                       Screen_Line   : INTEGER;
                                       Screen_Column : INTEGER );
   PROCEDURE Print_Screen;
   PROCEDURE Write_Screen( Fname : AnyStr );
   PROCEDURE Write_Graphics_Screen( Fname : AnyStr );
   PROCEDURE Get_Screen_Size( VAR Rows: INTEGER; VAR Columns: INTEGER );
   PROCEDURE Set_EGA_Text_Mode( EGA_Rows : INTEGER );
   PROCEDURE Set_Graphics_Colors( EGA_On : BOOLEAN;
                                  GMode  : INTEGER;
                                  FG     : INTEGER;
                                  BG     : INTEGER );
   PROCEDURE WriteCXY( C: CHAR; X: INTEGER; Y: INTEGER; Color: INTEGER );
   PROCEDURE WriteSXY( S: AnyStr; X: INTEGER; Y: INTEGER; Color: INTEGER );
   PROCEDURE WriteLXY( VAR S; X: INTEGER; Y: INTEGER; Len: INTEGER );
   PROCEDURE MoveToXY( X: INTEGER; Y: INTEGER );
   PROCEDURE Save_Partial_Screen( VAR Saved_Screen_Pointer : Saved_Screen_Ptr;
                                      X1                   : INTEGER;
                                      Y1                   : INTEGER;
                                      X2                   : INTEGER;
                                      Y2                   : INTEGER  );
   PROCEDURE Restore_Screen( VAR Saved_Screen_Pointer : Saved_Screen_Ptr );
   PROCEDURE Restore_Screen_And_Colors( VAR Saved_Screen_Pointer : Saved_Screen_Ptr );
   PROCEDURE Save_Screen( VAR Saved_Screen_Pointer : Saved_Screen_Ptr );
   PROCEDURE Draw_Titled_Box( VAR Saved_Screen_Pointer : Saved_Screen_Ptr;
                                  UpperLeftX           : INTEGER;
                                  UpperLeftY           : INTEGER;
                                  LowerRightX          : INTEGER;
                                  LowerRightY          : INTEGER;
                                  Box_Title            : AnyStr );
   PROCEDURE Video_Interrupt_Handler(
          Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP : WORD );
      Interrupt;
   PROCEDURE Install_Video_Handler;
   PROCEDURE Remove_Video_Handler;
   PROCEDURE Scroll( Y1, Y2, X1, X2, Nlines, FG, BG : INTEGER );
   PROCEDURE Clear_Window;
   PROCEDURE Menu_Set_Explode( Explode_ON : BOOLEAN );
   PROCEDURE Menu_Set_Beep( Beep_ON : BOOLEAN );
   PROCEDURE Menu_Set_Box_Chars( Top_Left_Corner     : CHAR;
                                 Top_Line            : CHAR;
                                 Top_Right_Corner    : CHAR;
                                 Right_Line          : CHAR;
                                 Bottom_Right_Corner : CHAR;
                                 Bottom_Line         : CHAR;
                                 Bottom_Left_Corner  : CHAR;
                                 Left_Line           : CHAR  );
   PROCEDURE Draw_Box( X1, Y1, X2, Y2 : INTEGER;
                       Frame_Color    : INTEGER;
                       Title_Color    : INTEGER;
                       Title          : AnyStr   );
   PROCEDURE Draw_Menu_Frame( UpperLeftX,  UpperLeftY,
                              LowerRightX, LowerRightY : INTEGER;
                              Frame_Color, Title_Color,
                              Text_Color               : INTEGER;
                              Menu_Title: AnyStr );
   PROCEDURE Menu_Click;
   PROCEDURE Menu_Beep;
   PROCEDURE Menu_Turn_On( Menu: Menu_Type; Menu_Item : INTEGER );
   PROCEDURE Menu_Turn_Off( Menu: Menu_Type; Menu_Item : INTEGER );
   PROCEDURE Menu_IBMCh( VAR C : CHAR );
   PROCEDURE Menu_Display_Choices( Menu : Menu_Type );
   FUNCTION Menu_Get_Choice( Menu: Menu_Type; Erase_After: BOOLEAN ) : INTEGER;
   PROCEDURE Convert_AsciiZ_To_String( VAR S: AnyStr );
   PROCEDURE Convert_String_To_AsciiZ( VAR S: AnyStr );
   FUNCTION Dir_Get_Current_Path( Drive         : CHAR;
                                  VAR Path_Name : AnyStr ) : INTEGER;
   FUNCTION Dir_Set_Current_Path( Path_Name : AnyStr ) : INTEGER;
   PROCEDURE Dir_Set_Disk_Transfer_Address( VAR DMA_Buffer );
   PROCEDURE Dir_Set_Default_Drive( Drive: CHAR );
   FUNCTION Dir_Get_Default_Drive: CHAR;
   FUNCTION Dir_Count_Drives : INTEGER;
   PROCEDURE Dir_Convert_Time ( Time : WORD; VAR S_Time : AnyStr );
   PROCEDURE Dir_Convert_Date ( Date : WORD; VAR S_Date : AnyStr );
   FUNCTION Dir_Set_File_Date_And_Time( File_Handle: INTEGER;
                                        File_Date  : INTEGER;
                                        File_Time  : INTEGER  ) : INTEGER;
   FUNCTION Dir_Get_File_Date_And_Time(     File_Handle: INTEGER;
                                        VAR File_Date  : INTEGER;
                                        VAR File_Time  : INTEGER  ) : INTEGER;
   PROCEDURE Send_Modem_Command( Modem_Text : AnyStr );
   FUNCTION YesNo( YesNo_Question : AnyStr ) : BOOLEAN;
   PROCEDURE HangUpPhone;
   PROCEDURE Make_A_Menu( VAR Menu     : Menu_Type;
                              Size     : INTEGER;
                              Row      : INTEGER;
                              Column   : INTEGER;
                              Width    : INTEGER;
                              Height   : INTEGER;
                              Default  : INTEGER;
                              Title    : AnyStr;
                              Texts    : AnyStr;
                              GenLet   : BOOLEAN     );
   PROCEDURE Make_And_Display_Menu( VAR Menu     : Menu_Type;
                                        Size     : INTEGER;
                                        Row      : INTEGER;
                                        Column   : INTEGER;
                                        Width    : INTEGER;
                                        Height   : INTEGER;
                                        Default  : INTEGER;
                                        Title    : AnyStr;
                                        Texts    : AnyStr;
                                        GenLet   : BOOLEAN;
                                        Erase_It : BOOLEAN;
                                    VAR Choice   : INTEGER );
   PROCEDURE Clr_Kbd_Buf;
   PROCEDURE Stuff_Kbd_Buf( In_Chr: INTEGER; Clr_Kbd : BOOLEAN );
   FUNCTION Edit_String( VAR In_Str      : AnyStr;
                             Buffer_Len  : INTEGER;
                             Start_X     : INTEGER;
                             X           : INTEGER;
                             Y           : INTEGER;
                             MaxWidth    : INTEGER;
                             Force_Case  : BOOLEAN;
                             Status_Line : INTEGER  ) : CHAR;
   PROCEDURE Read_Edited_String( VAR S: AnyStr );
   FUNCTION Read_Number(      Old_Number: LongInt;
                              Use_Old   : BOOLEAN;
                          VAR Number    : LongInt ) : BOOLEAN;
   PROCEDURE FiniTerm;
   PROCEDURE Split_File_Name(     FileRef    : AnyStr;
                              VAR Drive      : CHAR;
                              VAR Path       : AnyStr;
                              VAR FileName   : AnyStr;
                              VAR FileType   : AnyStr;
                              VAR Bogus_Name : BOOLEAN  );
   PROCEDURE Set_Status_Line_Name( Name : AnyStr );
   FUNCTION Scroll_Lock_On : BOOLEAN;
   FUNCTION Check_If_File_Exists( File_Name : AnyStr; File_Path : AnyStr ): BOOLEAN;
   PROCEDURE Handle_Function_Key( Ch : CHAR );
   PROCEDURE Send_Function_Key( Key_Text : AnyStr ) ;
   PROCEDURE Define_Key( Key_Name : AnyStr;
                         Key_Text : AnyStr  );
   FUNCTION Get_File_Size( Fname: AnyStr; VAR OpenOK : BOOLEAN ): LONGINT;
   PROCEDURE DosJump( Dos_String : AnyStr );
   PROCEDURE Add_Path( VAR File_Name      : AnyStr;
                       VAR Path           : AnyStr;
                       VAR Full_File_Name : AnyStr  );
   PROCEDURE Dir_Convert_File_Date_And_Time(      Date_Time  : LONGINT;
                                              VAR SFile_Date : AnyStr;
                                              VAR SDate_Time : AnyStr  );
   PROCEDURE Int24;
   PROCEDURE Int24On;
   PROCEDURE Int24Off( Flag : BOOLEAN );
   FUNCTION Int24Result : INTEGER;

   FUNCTION Heap_Error_Handler( Size : WORD ) : INTEGER;

   PROCEDURE Window_Delay;

   FUNCTION Scan_Xfer_List( File_Name : AnyStr ) : INTEGER;
   PROCEDURE Get_Auto_File_Name( VAR Keybrd_Line : AnyStr;
                                 VAR FileName    : AnyStr );

   PROCEDURE Write_Prt( Ch : CHAR );
   PROCEDURE Write_Prt_Str( S : AnyStr );

   PROCEDURE MyFreeMem( VAR P ; Size : WORD );
   PROCEDURE Rewrite_Dialing_Directory;
   PROCEDURE Clear_XOFF_Received;
   PROCEDURE Get_Long_Key_Name(     Short_Name : AnyStr;
                                VAR Long_Name  : AnyStr );
   FUNCTION Get_Key_Index( Short_Name : AnyStr ) : INTEGER;

IMPLEMENTATION

CONST                              (* TRUE to return actual keypressed *)
                                   (* status -- see rdkeybrd.mod.      *)
   Return_KeyPressed : BOOLEAN = TRUE;

                                   (* Ensure multitasking defined       *)
{$DEFINE MTASK}
                                   (* Interrupt 24 handler              *)
{$I INT24.MOD    }
                                   (* Time of day for status line       *)
{$I FASTTIME.MOD }
                                   (* Write to status line              *)
{$I WRITESTA.MOD }
                                   (* Updates status line               *)
{$I UPDATEST.MOD }
                                   (* Read keyboard driver              *)
{$I RDKEYBRD.MOD }
                                   (* Read character from keyboard      *)
{$I READKBD.MOD  }
                                   (* Do a "press any" question         *)
{$I PRESSANY.MOD }
                                   (* Sound terminal bell               *)
{$I SOUNDBEL.MOD }
                                   (* Redefine Int 9 keyboard handler   *)
{$I KBDINTP.MOD  }
                                   (* Open file for append              *)
{$I OPENFORA.MOD }
                                   (* Update review pointers            *)
{$I UPDATERE.MOD }
                                   (* Write time stamped string to log  *)
{$I WRITELOG.MOD }
                                   (* Print character from spool file   *)
{$I PRINTSPO.MOD }
                                   (* Screen management routines        *)
{$I MYGRAPH.MOD  }
{$I PIBSCRN1.MOD }
{$I PIBSCRN2.MOD }
{$I WRITECXY.MOD }
{$I MOVETOXY.MOD }
{$I PIBSCRN3.MOD }
                                   (* Redefine Int 10 video handler     *)
{$I VIDINTP.MOD  }
                                   (* Scroll portion of screen          *)
{$I SCROLL.MOD   }
                                   (* Clear out current window          *)
{$I CLEARWIN.MOD }
                                   (* Pop-up menu routines              *)
{$I PIBMENUS.MOD }
                                   (* MS DOS directory routines         *)
{$I PIBDIR.MOD   }
                                   (* Send string to modem              *)
{$I SENDMODE.MOD }
                                   (* Get yes/no answer                 *)
{$I YESNO.MOD    }
                                   (* Hangup the phone -- Alt_H         *)
{$I HANGUP.MOD   }
                                   (* Generate a menu                   *)
{$I MAKEMENU.MOD }
{$I MAKEMEND.MOD }
                                   (* Stuff keyboard buffer             *)
{$I STUFFKBD.MOD }
                                   (* Edit a string                     *)
{$I EDITSTRI.MOD }
                                   (* Read and edit a string            *)
{$I READEDIS.MOD }
                                   (* Read a number                     *)
{$I READNUMB.MOD }
                                   (* General error handler             *)
{$I ERRORHAN.MOD }
                                   (* Finish terminal emulation         *)
{$I FINITERM.MOD }                                   (* Split file name                   *)
{$I SPLITFNA.MOD }
                                   (* Set status line name              *)
{$I SETSTATU.MOD }
                                   (* Handle scroll lock                *)
{$I SCROLLOC.MOD }
                                   (* Check if file exists              *)
{$I CHECKIFF.MOD }
                                   (* Send function key                 *)
{$I SENDFUNK.MOD }
                                   (* Handle function key               *)
{$I HANDLEFK.MOD }
                                   (* Define a key                      *)
{$I DEFINEKY.MOD }
                                   (* Get file size                     *)
{$I GETFSIZE.MOD }
                                   (* DOS jump interface                *)
{$I DOSJUMP.MOD  }
                                   (* Add path to file name             *)
{$I ADDPATH.MOD  }
                                   (* Window delay                      *)
{$I WINDELAY.MOD }
                                   (* Scan transfer list                *)
{$I SCANXFER.MOD }
                                   (* Auto find file name               *)
{$I GETAUTOF.MOD }
                                   (* Write character/string to printer *)
{$I WRITEPRT.MOD }
                                   (* Substitute freemem routine        *)
{$I MYFREEM.MOD  }
                                   (* Rewrite phone directory           *)
{$I REWRITED.MOD }
                                   (* Clear any XOFFs received          *)
{$I CLEARXOF.MOD }
                                   (* Look up function key name         *)
{$I GETLKNAM.MOD }
                                   (* Look up function key index        *)
{$I GETKIND.MOD  }
                                   (* Give away time to other tasks     *)
{$I GIVEAWAY.MOD }

END   (* GlobRout *).
