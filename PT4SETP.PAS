UNIT PT4SETP;

INTERFACE

USES
   Dos, Crt, GlobType, StringMan, GlobRout, PibAsync,   PT4UpDwn;

(* EXPORTS *)
   FUNCTION Set_Params( First_Time : BOOLEAN;
                        Use_Script : BOOLEAN ) : BOOLEAN;
   PROCEDURE Get_Default_Params( First_Time : BOOLEAN );
   FUNCTION Look_Up_Parameter( PName : Char_2 ) : INTEGER;
   PROCEDURE Write_Config_File( Config_File_Name : AnyStr );
   PROCEDURE Set_Parameter( Param_Num  : INTEGER;
                            Param_Ival : INTEGER;
                            Param_Rval : LONGINT;
                            Param_Str  : AnyStr   );
   FUNCTION Get_Config_File_Line(  VAR Config_File : Text_File;
                                   VAR Param_Num   : INTEGER;
                                   VAR Param_Str   : AnyStr;
                                   VAR Param_Ival  : INTEGER;
                                   VAR Param_Rval  : LONGINT ) : BOOLEAN;

                                   (* Parameter definitions           *)
(*$I PARMDAT.GLO *)

IMPLEMENTATION
                                   (* Get value of parameter *)
{$I GETPARAM.MOD }
                                   (* Set value of parameter *)
{$I SETPARAM.MOD }
                                   (* Get one line of configuration file *)
{$I GETCONFI.MOD }
                                   (* Main parameter setting routines *)
{$I SETPARMA.MOD }
{$I SETPARMB.MOD }
{$I SETPARMC.MOD }

END   (* PT4SETP *).
