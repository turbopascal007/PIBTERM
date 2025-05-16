UNIT PT4GOSSI;

INTERFACE

USES
   Dos, Crt, GlobType, StringMan, GlobRout, PibTimer, PibAsync,
   PT4ASCI, PT4DISPC, PT4UPDWN, PT4TERM;

(* EXPORTS *)
   PROCEDURE Emulate_Gossip;

IMPLEMENTATION

{$I PIBGOSSI.MOD }

END   (* PT4GOSSI *).
