(*$R-,V-,K-*)
UNIT PibTimer;

INTERFACE

USES
   Dos, GlobType, StringMan;

   PROCEDURE Adjust_Hour( VAR Hour : INTEGER;
                          VAR AmPm : ShortStr );
   FUNCTION TimeOfDay : LONGINT;
   FUNCTION TimeDiff( Timer1, Timer2: LONGINT ) : LONGINT;
   FUNCTION TimeString( Timer_Value  : LONGINT;
                        Timer_Format : Time_Format_Type ) : ShortStr;
   FUNCTION DateString : ShortStr;
   FUNCTION DialDateString: ShortStr;

   FUNCTION TimeOfDayH : LONGINT;
   FUNCTION TimeDiffH( Timer1, Timer2: LONGINT ) : LONGINT;
   FUNCTION TimeStringH( Timer_Value  : LONGINT;
                         Timer_Format : Time_Format_Type ) : ShortStr;

IMPLEMENTATION

{$I ADJUSTHR.MOD }
{$I PIBTIMER.MOD }
{$I PIBTIMRH.MOD }

END (* PibTimer *).

