(*----------------------------------------------------------------------*)
(*         Press_Any  --- Issue a "press any key to continue" message   *)
(*----------------------------------------------------------------------*)

PROCEDURE Press_Any;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Press_Any                                            *)
(*                                                                      *)
(*     Purpose:    Issue 'press any key to continue' message            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Press_Any;                                                    *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        If machine not in Attended_Mode, then no message is issued,   *)
(*        and a two-second delay is executed.                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Ch: CHAR;

BEGIN (* Press_Any *)

   IF Attended_Mode THEN
      BEGIN
         WRITE('*** Hit ESC key to continue ... ');
         Read_Kbd( Ch );
         IF ( ORD( Ch ) = ESC ) AND PibTerm_KeyPressed THEN
            Read_Kbd( Ch );
      END
   ELSE
      Window_Delay;

END   (* Press_Any *);
