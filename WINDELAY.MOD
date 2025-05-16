(*--------------------------------------------------------------------------*)
(*      Window_Delay  --- Delay for specified window delay period           *)
(*--------------------------------------------------------------------------*)

PROCEDURE Window_Delay;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Procedure: Window_Delay                                              *)
(*                                                                          *)
(*     Purpose:   Delays for specified window delay period                  *)
(*                                                                          *)
(*     Calling sequence:                                                    *)
(*                                                                          *)
(*        Window_Delay;                                                     *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

BEGIN (* Window_Delay *)

   IF ( Window_Hold_Time > 0 ) THEN
      DELAY( Window_Hold_Time * 100 );

END   (* Window_Delay *);
