UNIT PT4INIT;

INTERFACE

USES
   Dos, Crt, GlobType, GlobRout, StringMan, PibAsync, PibTimer,
   PT4SETP, PT4SCRI;

(* EXPORTS *)
   PROCEDURE Set_Defaults;
   FUNCTION  Read_Config_File : BOOLEAN;
   PROCEDURE Initialize_Communications;
   PROCEDURE Test_Version_Warning;
   PROCEDURE Get_Other_Files;
   PROCEDURE Allocate_Dial_And_Review;
   PROCEDURE Set_Other_Parameters;

IMPLEMENTATION
                                   (* Initialize modem                *)
{$I INITMODE.MOD }
                                   (* Initialize printer              *)
{$I INITPRIN.MOD }
                                   (* Set defaults for program        *)
{$I SETDEFAU.MOD }
                                   (* Initialize serial port          *)
{$I INITCOMM.MOD }
                                   (* Display version warning         *)
{$I TESTVERW.MOD }
                                   (* Read primary config. file       *)
{$I READCONF.MOD }
                                   (* Allocate dial, review buffer    *)
{$I ALOCDIRV.MOD }
                                   (* Read other config. files        *)
{$I GETOTHER.MOD }
                                   (* Set other parameters at init    *)
{$I SETOPAR.MOD  }

END   (* PT4INIT *).

