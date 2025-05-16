UNIT PT4T4010;

INTERFACE

USES
   Dos,      Crt,     GlobType, StringMan, GlobRout, PibTimer,
   PibMTask, PibAsync, PT4ASCI, PT4UPDWN, PT4TERM;

(* EXPORTS *)
   PROCEDURE Emulate_TEK4010;

IMPLEMENTATION

{$I PIB4010.GLO  }
{$I PIB4010A.MOD }
{$I PIB4010B.MOD }

END   (* PT4T4010 *).
