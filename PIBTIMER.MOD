(*--------------------------------------------------------------------------*)
(*                TimeOfDay  --- Get time of day                            *)
(*--------------------------------------------------------------------------*)

FUNCTION TimeOfDay : LONGINT;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Function:  TimeOfDay                                                 *)
(*                                                                          *)
(*     Purpose:   Gets time of day from internal clock                      *)
(*                                                                          *)
(*     Calling sequence:                                                    *)
(*                                                                          *)
(*        Tod := TimeOfDay : LONGINT;                                       *)
(*                                                                          *)
(*           Tod --- Long integer number which is timer value expressed in  *)
(*                   seconds as:                                            *)
(*                   ( 3600 x hour + 60 x minutes + seconds )               *)
(*                                                                          *)
(*     Calls:  GetTime                                                      *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   Hours   : WORD;
   Minutes : WORD;
   Seconds : WORD;
   SecHun  : WORD;

   TimeVal : LONGINT;

BEGIN (* TimeOfDay *)

   GetTime( Hours, Minutes, Seconds, SecHun );

   TimeVal    := Hours;
   TimeOfDay  := TimeVal * 3600 + Minutes * 60 + Seconds;

END   (* TimeOfDay *);

(*--------------------------------------------------------------------------*)
(*        TimeDiff  --- Get difference in time between two timer values     *)
(*--------------------------------------------------------------------------*)

FUNCTION TimeDiff( Timer1, Timer2: LONGINT ) : LONGINT;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Function:  TimeDiff                                                  *)
(*                                                                          *)
(*     Purpose:   Get difference in time between two timer values in        *)
(*                seconds.                                                  *)
(*                                                                          *)
(*     Calling sequence:                                                    *)
(*                                                                          *)
(*        TDiff := TimeDiff( Timer1, Timer2: LONGINT ) : LONGINT;           *)
(*                                                                          *)
(*           Timer1  --- first timer value (earlier)                        *)
(*           Timer2  --- second timer value (later)                         *)
(*                                                                          *)
(*           TDiff   --- difference between timer values                    *)
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
   Secs_Per_Day = 86400    (* Seconds in one day *);

VAR
   TDiff : LONGINT;

BEGIN (* TimeDiff *)

   TDiff := Timer2 - Timer1;

   IF ( TDiff < 0 ) THEN 
      TDiff := TDiff + Secs_Per_Day;

   TimeDiff := TDiff;

END   (* TimeDiff *);

(*--------------------------------------------------------------------------*)
(*          TimeString  --- convert timer value to string                   *)
(*--------------------------------------------------------------------------*)

FUNCTION TimeString( Timer_Value  : LONGINT;
                     Timer_Format : Time_Format_Type ) : ShortStr;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Function:  TimeString                                                *)
(*                                                                          *)
(*     Purpose:   Convert elapsed timer value to HH:MM:SS string            *)
(*                                                                          *)
(*     Calling sequence:                                                    *)
(*                                                                          *)
(*        Tstring := TimeString( Timer_Value  : LONGINT;                    *)
(*                               Timer_Format : Time_Format_Type ) :        *)
(*                               AnyStr;                                    *)
(*                                                                          *)
(*           Timer_Value ---  Number which is timer value expressed as      *)
(*                            seconds from 12 am.                           *)
(*           Timer_Format --- Format type for time                          *)
(*           Tstring      --- Resultant 'HH:MM:SS' form of time             *)
(*                                                                          *)
(*     Calls:  None                                                         *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   Hours   : INTEGER;
   SaveHrs : LONGINT;
   Minutes : INTEGER;
   Seconds : INTEGER;
   Save_H  : LONGINT;
   SH      : STRING[2];
   SM      : STRING[2];
   SS      : STRING[2];
   AmPm    : STRING[3];

BEGIN (* TimeString *)

   Hours   := Timer_Value DIV 3600;
   SaveHrs := Hours;
   AmPm    := '';

   IF ( Timer_Format = AMPM_Time ) THEN
      BEGIN
         Adjust_Hour( Hours , AmPm );
         AmPm := ' ' + AmPm;
      END;

   Save_H  := Timer_Value - SaveHrs * 3600;
   Minutes := Save_H DIV 60;
   Seconds := Save_H - Minutes * 60;

   STR( Hours:2,   SH );
   STR( Minutes:2, SM );
   STR( Seconds:2, SS );

   IF ( Timer_Format <> AMPM_Time ) THEN
      IF SH[1] = ' ' THEN SH[1] := '0';
   IF SM[1] = ' ' THEN SM[1] := '0';
   IF SS[1] = ' ' THEN SS[1] := '0';

   TimeString := SH + ':' + SM + ':' + SS + AmPm;

END   (* TimeString *);

(*--------------------------------------------------------------------------*)
(*             DateString  --- Return current date in string form           *)
(*--------------------------------------------------------------------------*)

FUNCTION DateString : ShortStr;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Function:  DateString                                                *)
(*                                                                          *)
(*     Purpose:   Returns current date in string form                       *)
(*                                                                          *)
(*     Calling sequence:                                                    *)
(*                                                                          *)
(*        Dstring := DateString: AnyStr;                                    *)
(*                                                                          *)
(*           Dstring     --- Resultant string form of date                  *)
(*                                                                          *)
(*     Calls:  GetDate                                                      *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   SMonth:         STRING[2];
   SDay:           STRING[2];
   SYear:          STRING[4];
   Month:          WORD;
   Day:            WORD;
   Year:           WORD;
   DayOfWeek:      WORD;

BEGIN (* DateString *)
                                   (* Date function *)

   GetDate( Year, Month, Day, DayOfWeek );

                                   (* Convert date to string *)
   STR( Year  , SYear  );
   STR( Day   , SDay   );
   STR( Month , SMonth );

   CASE Date_Format OF
      YMD_Style: DateString := SYear  + '/' + SMonth + '/' + SDay;
      DMY_Style: DateString := SDay   + '/' + SMonth + '/' + SYear;
      ELSE
         DateString := SMonth + '/' + SDay + '/' + SYear;
   END (* CASE *);

END   (* DateString *);

(*--------------------------------------------------------------------------*)
(*              DialDateString  --- Return current date                     *)
(*--------------------------------------------------------------------------*)

FUNCTION DialDateString : ShortStr;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Function:  DialDateString                                            *)
(*                                                                          *)
(*     Purpose:   Returns current date in string form                       *)
(*                                                                          *)
(*     Calling sequence:                                                    *)
(*                                                                          *)
(*        Dstring := DialDateString: AnyStr;                                *)
(*                                                                          *)
(*           Dstring     --- Resultant string form of date                  *)
(*                                                                          *)
(*     Calls:  GetDate                                                      *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   SMonth:         STRING[2];
   SDay:           STRING[2];
   SYear:          STRING[4];
   Month:          WORD;
   Day:            WORD;
   Year:           WORD;
   DayOfWeek:      WORD;

BEGIN (* DialDateString *)
                                   (* Date function *)

   GetDate( Year, Month, Day, DayOfWeek );

                                   (* Convert date to string *)
   STR( Year  : 4  , SYear  );
   STR( Day   : 2  , SDay   );
   STR( Month : 2  , SMonth );

   IF ( SDay[1]   = ' ' ) THEN SDay[1]   := '0';
   IF ( SMonth[1] = ' ' ) THEN SMonth[1] := '0';

   DialDateString := SYear[3] + SYear[4] + '/' + SMonth + '/' + SDay;

END   (* DialDateString *);
