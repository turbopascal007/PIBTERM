UNIT PT4ANSI;

INTERFACE

USES
   Dos, Crt, GlobType, StringMan, GlobRout, PibTimer, PibAsync,  
   PT4ASCI, PT4CISB, PT4UTIL,  PT4VIEW, PT4DIAL, PT4SCRI,
   PT4EDIT, PT4SETP, PT4UPDWN, PT4DISPC, PT4TERM;

(* EXPORTS *)
   PROCEDURE Emulate_ANSI( VT100_Allowed : BOOLEAN );

IMPLEMENTATION
                                   (* Play music for ANSI mode  *)
{$I PIBMUSIC.MOD }
                                   (* ANSI/VT100 emulation      *)
{$I PIBANSIA.MOD }
{$I PIBANSIB.MOD }

END   (* PT4ANSI *).
