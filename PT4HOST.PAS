UNIT PT4HOST;

INTERFACE

USES
   Dos, Crt, GlobType, StringMan, GlobRout, PibTimer, PibAsync,  
   PT4ASCI, PT4TERM, PT4UPDWN;

(* EXPORTS *)
   PROCEDURE Emulate_Host;

IMPLEMENTATION

{$I PIBHOSTA.MOD }
{$I PIBHOSTB.MOD }
{$I PIBHOSTC.MOD }
{$I PIBHOSTD.MOD }

END   (* PT4HOST *).
