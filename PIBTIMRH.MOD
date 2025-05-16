(*--------------------------------------------------------------------------*)
(*      TimeOfDayH  --- Get time of day in 1/100 seconds from midnight      *)
(*--------------------------------------------------------------------------*)

FUNCTION TimeOfDayH : LONGINT;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Function:  TimeOfDayH                                                *)
(*                                                                          *)
(*     Purpose:   Gets time of day from internal clock in 1/100 seconds     *)
(*                                                                          *)
(*     Calling sequence:                                                    *)
(*                                                                          *)
(*        Tod := TimeOfDayH : LONGINT;                                      *)
(*                                                                          *)
(*           Tod --- Real number which is timer value expressed in          *)
(*                   hundredths of seconds as:                              *)
(*                   ( 360000 x hour + 6000 x minutes + 100 x seconds +     *)
(*                     hundredths of seconds ).                             *)
(*                                                                          *)
(*     Calls:  GetTime                                                      *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   Hours   : WORD;
   Minutes : WORD;
   Seconds : WORD;
   SecHun  : WORD;

   TimerVal: LONGINT;

BEGIN (* TimeOfDayH *)

   GetTime( Hours, Minutes, Seconds, SecHun );

   TimerVal    := Hours;
   TimeOfDayH  := TimerVal * 360000 + Minutes * 6000 + Seconds * 100 + SecHun;

END   (* TimeOfDayH *);

(*--------------------------------------------------------------------------*)
(*       TimeDiffH  --- Get difference in time between two timer values     *)
(*--------------------------------------------------------------------------*)

FUNCTION TimeDiffH( Timer1, Timer2: LONGINT ) : LONGINT;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Function:  TimeDiffH                                                 *)
(*                                                                          *)
(*     Purpose:   Get difference in time between two timer values           *)
(*                in hundredths of seconds.                                 *)
(*                                                                          *)
(*     Calling sequence:                                                    *)
(*                                                                          *)
(*        Tdiff := TimeDiffH( Timer1, Timer2: LONGINT ) : REAL;             *)
(*                                                                          *)
(*           Timer1  --- first timer value (earlier)                        *)
(*           Timer2  --- second timer value (later)                         *)
(*                                                                          *)
(*           Tdiff   --- difference between timer values                    *)
(*                                                                          *)
(*     Calls:  None                                                         *)
(*                                                                          *)
(*     Remarks:                                                             *)
(*                                                                          *)
(*        This routine will handle time wrap around midnight.  However, it  *)
(*        only handles timer values <= 24 hours in duration.                *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

CONST
   Hundredths_Secs_Per_Day = 8640000    (* 1/100 Seconds in one day *);

VAR
   TDiff : LONGINT;

BEGIN (* TimeDiffH *)

   TDiff := Timer2 - Timer1;

   IF Tdiff < 0 THEN Tdiff := Tdiff + Hundredths_Secs_Per_Day;

   TimeDiffH := Tdiff;

END   (* TimeDiffH *);

(*--------------------------------------------------------------------------*)
(*      TimeStringH  --- convert timer value in 1/100 secs to string        *)
(*--------------------------------------------------------------------------*)

FUNCTION TimeStringH( Timer_Value  : LONGINT;
                      Timer_Format : Time_Format_Type ) : ShortStr;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Function:  TimeStringH                                               *)
(*                                                                          *)
(*     Purpose:   Convert elapsed timer value to HH:MM:SS string            *)
(*                                                                          *)
(*     Calling sequence:                                                    *)
(*                                                                          *)
(*        Tstring := TimeStringH( Timer_Value  : LONGINT;                   *)
(*                                Timer_Format : Time_Format_Type ) :       *)
(*                                AnyStr;                                   *)
(*                                                                          *)
(*           Timer_Value ---  Real number which is timer value expressed as *)
(*                            1/100th seconds from 12 am.                   *)
(*           Timer_Format --- Format type for time                          *)
(*           Tstring      --- Resultant 'HH:MM:SS' form of time             *)
(*                                                                          *)
(*     Calls:  None                                                         *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

BEGIN (* TimeStringH *)

   TimeStringH := TimeString( Timer_Value DIV 100 , Timer_Format );

END   (* TimeStringH *);

