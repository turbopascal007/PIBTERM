UNIT PT4DIAL;

INTERFACE

USES
   Dos, Crt, GlobType, StringMan, GlobRout, PibTimer, PibAsync,  
   PT4UpDwn;

   PROCEDURE PibDialer( ReDial         : BOOLEAN;
                        Dialing_String : AnyStr;
                        Allow_Script   : BOOLEAN );
   
IMPLEMENTATION

{$I PIBDIALA.MOD }
{$I PIBDIALB.MOD }
{$I PIBDIALC.MOD }

END   (* PT4DIAL *).
