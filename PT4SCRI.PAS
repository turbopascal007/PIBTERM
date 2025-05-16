UNIT PT4SCRI;

INTERFACE

USES
   Dos, Crt, GlobType, StringMan, GlobRout, PibTimer, PibAsync,  
   PT4DispC;

(* EXPORTS *)
   PROCEDURE Process_Script( Script_FName  : AnyStr;
                             Script_ComLet : CHAR     );

                                   (* Script operation definitions *)
{$I SCRIPTOP.GLO }

IMPLEMENTATION

{$I PROCESSS.MOD }
{$I PROCESS2.MOD }
{$I PROCESS3.MOD }
{$I PROCESS4.MOD }
{$I PROCESS5.MOD }

END   (* PT4SCRI *).
