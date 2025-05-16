UNIT PT4TERM;

INTERFACE

USES
   Dos, Crt, GlobType, StringMan, GlobRout, PibTimer, PibMTask, PibAsync,
   PT4ASCI, PT4CISB,  PT4UTIL, PT4VIEW, PT4DIAL, PT4SCRI, PT4EDIT,
   PT4SETP, PT4UPDWN, PT4DISPC;
                                   (* General terminal definitions      *)
{$I TERMDEF.LOC  }

(* EXPORTS *)
   PROCEDURE Do_VT52_LineFeeds( Ch : CHAR );
   PROCEDURE Handle_Carrier_Drop;
   PROCEDURE Check_Wait_String_Time;
   PROCEDURE Process_Command( VAR Ch       : CHAR;
                                  Use_Ch   : BOOLEAN;
                              VAR Command  : PibTerm_Command_Type );
   PROCEDURE Execute_Command( VAR Command    : Pibterm_Command_Type;
                              VAR Done       : BOOLEAN;
                                  Use_Script : BOOLEAN );
   PROCEDURE Get_Script_Command( VAR Command : PibTerm_Command_Type );
   PROCEDURE Handle_Scroll_Lock;
   PROCEDURE Handle_Keyboard_Input( VAR Done                  : BOOLEAN;
                                    VAR Reset_Requested       : BOOLEAN;
                                    VAR ClearScreen_Requested : BOOLEAN );
   PROCEDURE Init_Text_Terminal;
   PROCEDURE Do_Script_Checks( Ch: CHAR );
   PROCEDURE Load_Function_Keys( File_Name : AnyStr );
   PROCEDURE Handle_Tab( VAR Tabs : Tab_Stop_Vector; NTabs : INTEGER );
   PROCEDURE Exec_PC_Commands;
   PROCEDURE Get_Async_Integer( VAR Integr: INTEGER );
   FUNCTION  Handle_Zmodem_Autodownload : BOOLEAN;
   FUNCTION  Handle_Kermit_Autodownload : BOOLEAN;

IMPLEMENTATION
                                   (* Compare character strings *)
{$I CMPSTR.MOD   }
                                   (* Toggle option on/off      *)
{$I TOGGLEOP.MOD }
                                   (* Check if WaitString found *)
{$I CHECKWAI.MOD }
                                   (* Do Script-related checks  *)
{$I DOSCRIPC.MOD }
                                   (* Process PibTerm command   *)
{$I PROCESSC.MOD }
                                   (* Execute a PibTerm command *)
{$I EXECUTC1.MOD }
{$I EXECUTC2.MOD }
                                   (* Get command from script   *)
{$I GETSCRIP.MOD }
                                   (* Handle scroll lock key    *)
{$I HANDLESC.MOD }
                                   (* Handle keyboard input     *)
{$I HANDLEKB.MOD }
                                   (* Handle carrier drop       *)
{$I HANDLECD.MOD }
                                   (* Handle auto key load      *)
{$I AUTOKLOD.MOD }
                                   (* EXEC PC BBS commands      *)
{$I EXECPC.MOD   }
                                   (* Get VT52 style position   *)
{$I GETASYNC.MOD }
                                   (* Do VT52 linefeed processing*)
{$I DOVT52LF.MOD }
                                   (* Do tab processing          *)
{$I HANDLEHT.MOD }
                                   (* Initialize text terminals  *)
{$I INITTEXT.MOD }
                                   (* Handle autodownloads       *)
{$I AUTODOWN.MOD }

END   (* PT4TERM *).
