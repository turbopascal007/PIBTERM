UNIT PT4ASCI;

INTERFACE

USES
   Dos, Crt, GlobType, StringMan, GlobRout, PibTimer, PibAsync;

(* EXPORTS *)
   PROCEDURE Receive_Ascii_File;
   PROCEDURE Send_Ascii_File;

IMPLEMENTATION
                                   (* Ascii downloads                 *)
{$I RECEIVEA.MOD }
                                   (* Ascii uploads                   *)
{$I SENDASCI.MOD }

END   (* PT4ASCI *).
