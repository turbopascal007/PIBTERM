UNIT PT4UTIL;

INTERFACE

USES
   Dos, Crt, GlobType, GlobRout, StringMan, PibAsync, PibTimer;

(* EXPORTS *)
   PROCEDURE Set_Translate_Table( File_Name : AnyStr );
   PROCEDURE Display_Help( FirstTime : BOOLEAN );
   PROCEDURE PibFileManipulation( VAR File_Done : BOOLEAN;
                                  VAR Do_Editing: BOOLEAN;
                                  VAR Do_Viewing: BOOLEAN );
   PROCEDURE GetAreaCode;
   PROCEDURE Review_Captured_Text;
   PROCEDURE Display_Timers;
   PROCEDURE Do_Screen_Dump;
   PROCEDURE Get_Capture_File( Capture_FName : AnyStr;
                               Capture_Type  : AnyStr   );
   PROCEDURE Set_Input_Keys( File_Name : AnyStr; Tell : BOOLEAN );
   PROCEDURE Fast_Change_Params;
   PROCEDURE Edit_A_Line;
   PROCEDURE Print_A_File( F_Name : AnyStr );

IMPLEMENTATION
                                   (* Set translate entries -- Alt_T  *)
{$I SETTRTAB.MOD }
                                   (* Define function keys -- Alt_K subs *)
{$I SETINPKS.MOD }
                                   (* Display help screen -- Alt_I    *)
{$I DISPHELP.MOD }
                                   (* Issue end-of-screen prompts     *)
{$I VIEWPMPT.MOD }
                                   (* File manipulation -- Alt_F subs *)
{$I PIBFMANS.MOD }
                                   (* Area codes -- Alt_Z             *)
{$I GETAREAC.MOD }
                                   (* Review buffer -- Alt_V          *)
{$I REVIEWCA.MOD }
                                   (* Display time -- Alt_Y           *)
{$I DISPLAYT.MOD }
                                   (* Screen dumps -- Alt_U           *)
{$I DOSCDUMP.MOD }
                                   (* Capture to file -- Alt_O        *)
{$I GETCAPTU.MOD }
                                   (* File manipulation -- Alt_F main     *)
{$I PIBFMANI.MOD }
                                   (* Define function keys -- Alt_K main  *)
{$I SETINPTK.MOD }
                                   (* Change of comm. params -- Alt_N     *)
{$I FASTCHNG.MOD }
                                   (* Edit a line -- Alt_A                *)
{$I EDITALIN.MOD }

END   (* PT4UTIL *).
