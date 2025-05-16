UNIT PT4XMOD;

INTERFACE

USES
   Dos, Crt, GlobType, GlobRout, StringMan, PibTimer, PibAsync;

   PROCEDURE Do_Xmodem_Upload  ( Trans_Protocol : Transfer_Type );
   PROCEDURE Do_Xmodem_Download( Trans_Protocol : Transfer_Type );

IMPLEMENTATION
                                   (* Common upload/download code *)
{$I XMODCOMO.MOD }
                                   (* Xmodem family uploads    *)
{$I DOXMODU1.MOD }
{$I SENDXMOD.MOD }
{$I MAKETELE.MOD }
{$I SENDMDM7.MOD }
{$I SENDYMOD.MOD }
{$I DOXMODU2.MOD }
                                   (* Xmodem family downloads *)
{$I DOXMODD1.MOD }
{$I RECEIVX1.MOD }
{$I RECEIVX2.MOD }
{$I RECEIVEM.MOD }
{$I RECEIVEY.MOD }
{$I DOXMODD2.MOD }

END   (* PT4XMOD *).
