UNIT PT4DISPC;

INTERFACE

USES
   Dos, Crt, GlobType, StringMan, GlobRout, PibTimer, PibMTask, PibAsync;

(* EXPORTS *)
   PROCEDURE Capture_Char( Ch : CHAR );
   PROCEDURE Update_Review_Pointers;
   PROCEDURE Display_Character( Ch: CHAR );
   PROCEDURE Display_Character_Through_DOS( Ch: CHAR );
   PROCEDURE Learn_A_Character( Ch : CHAR );

IMPLEMENTATION
                                   (* Capture character         *)
{$I CAPTUREC.MOD }
                                   (* Update review buffer      *)
{$I UPDATERE.MOD }
                                   (* Display char via DSW/BIOS *)
{$I DISPLAYC.MOD }
                                   (* Display character via DOS *)
{$I DISPCDOS.MOD }
                                   (* Learn typed character     *)
{$I LEARNACH.MOD }

END   (* PT4DISPC *).
