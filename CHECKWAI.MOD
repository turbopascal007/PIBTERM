(*----------------------------------------------------------------------*)
(*     Check_Wait_String_Time --- Check if wait string time exhausted   *)
(*----------------------------------------------------------------------*)

PROCEDURE Check_Wait_String_Time;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Check_Wait_String_Time                               *)
(*                                                                      *)
(*     Purpose:    Checks if wait string time is exhausted              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Check_Wait_String_Time;                                       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Check_Wait_String_Time *)

                                   (* Check for WAITQUIET *)
   IF WaitQuiet_Mode THEN
      BEGIN
         IF ( TimeDiffH( Script_Wait_Start , TimeOfDayH ) >= Script_WaitQuiet_Time ) THEN
            BEGIN
               WaitQuiet_Mode      := FALSE;
               Really_Wait_String  := FALSE;
            END;
      END
   ELSE
                                   (* Check wait string time *)

      IF ( TimeDiff( Script_Wait_Start , TimeOfDay ) > Script_Wait_Time ) THEN
         BEGIN
            Script_Wait_Save    := '';
            Script_Wait_Found   := FALSE;
            WaitString_Mode     := FALSE;
            Really_Wait_String  := FALSE;
            IF ( Script_Wait_Failure > 0 ) THEN
               Script_Buffer_Pos  := PRED( Script_Wait_Failure );
         END;

END   (* Check_Wait_String_Time *);
