(*----------------------------------------------------------------------*)
(*     Handle_Carrier_Drop --- Handle carrier drop in terminal mode     *)
(*----------------------------------------------------------------------*)

PROCEDURE Handle_Carrier_Drop;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Handle_Carrier_Drop                                  *)
(*                                                                      *)
(*     Purpose:    Handle carrier drop in terminal mode                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Handle_Carrier_Drop;                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Handle_Carrier_Drop *)

   Write_Log( 'Carrier dropped, session ended.', FALSE, FALSE );

   Write_Log( 'Elapsed session time: ' +
              TimeString( TimeDiff( Dialing_Start_Time , TimeOfDay ),
                          Military_Time ), TRUE, FALSE );

   Carrier_Dropped := FALSE;

   Dialing_Start_Time := TimeOfDay;

                                   (* Check for WHENDROP string *)
   IF When_Drop_Mode THEN
      BEGIN
         Send_Function_Key( Read_Ctrls( Script_When_Drop_Text ) );
      END (* When_Mode *);

END   (* Handle_Carrier_Drop *);
