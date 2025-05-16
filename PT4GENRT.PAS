UNIT PT4GENRT;

INTERFACE

USES
   Dos, Crt, GlobType, StringMan, GlobRout, PibTimer, PibAsync,  
   PT4ASCI, PT4CISB,  PT4UTIL,  PT4DIAL, PT4SCRI, PT4EDIT, PT4VIEW,
   PT4SETP, PT4UPDWN, PT4DISPC, PT4TERM;

(* EXPORTS *)
   PROCEDURE Emulate_General_Terminal;
   PROCEDURE Emulate_User_Terminal;

IMPLEMENTATION
                                   (* Set display action vector    *)
{$I SETDISPL.MOD }
                                   (* Reset general terminal       *)
{$I RESGENRT.MOD }
                                   (* Display actions for genterm  *)
{$I DODISPLA.MOD }
                                   (* General terminal emulation   *)
{$I PIBGENRT.MOD }
                                   (* User terminal                *)
{$I EMULTUSR.MOD }

END   (* PT4GENRT *).
