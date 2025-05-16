UNIT PibMTask;

INTERFACE

USES
   Dos,   Crt, GlobType;

(* EXPORTS *)

   FUNCTION IsTimeSharingActive : BOOLEAN;
   PROCEDURE TurnOnTimeSharing;
   PROCEDURE TurnOffTimeSharing;
   PROCEDURE GiveUpTime( NSlices : INTEGER );
   PROCEDURE Sync_Screen( S_Pos: INTEGER; NChars : INTEGER );
   PROCEDURE Sync_Entire_Screen;

IMPLEMENTATION
                                   (* Ensure multitasking defined       *)
{$DEFINE MTASK}
                                   (* Multitasker interface routines    *)
{$I PIBMDOS.MOD  }

END   (* PibMTask *).
