UNIT PT4UPDWN;

INTERFACE

USES
   Dos, Crt, GlobType, GlobRout, StringMan, PibTimer, PibAsync,
   PT4SCRI, PT4KERM, PT4ASCI, PT4XMOD;

(* EXPORTS *)

   PROCEDURE Display_Transfer_Types(     Menu_Title    : AnyStr;
                                         Menu_Default  : Transfer_Type;
                                         Allow_None    : BOOLEAN;
                                         Row           : INTEGER;
                                         Column        : INTEGER;
                                         Width         : INTEGER;
                                         Height        : INTEGER;
                                         Menu_Depth    : INTEGER;
                                         Menu_Erase    : BOOLEAN;
                                     VAR Transfer_Kind : Transfer_Type );

   PROCEDURE PibUpLoad  ( Transfer_Protocol : Transfer_Type );
   PROCEDURE PibDownLoad( Transfer_Protocol : Transfer_Type );
   FUNCTION  Get_Zmodem_Type : Transfer_Type;

IMPLEMENTATION
                                   (* Display transfer types menu       *)
{$I DISPLYTT.MOD }
                                   (* Get upload protocol -- Alt_S      *)
{$I GETUPLOA.MOD }
                                   (* Get download protocol -- Alt_R    *)
{$I GETDOWNL.MOD }
                                   (* Signal end of transfer            *)
{$I SIGENDTR.MOD }
                                   (* Transfer file through batch file  *)
{$I TRANSBAT.MOD }
                                   (* Finds which ext. prot. is Zmodem  *)
{$I GETZMODE.MOD }
                                   (* General file transfer handler     *)
{$I PIBUPDOW.MOD }
                                   (* General upload handler -- Alt_S   *)
{$I PIBUPLOD.MOD }
                                   (* General download handler -- Alt_R *)
{$I PIBDWLOD.MOD }

END   (* PT4UPDWN *).