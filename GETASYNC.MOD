(*----------------------------------------------------------------------*)
(*     Get_Async_Integer   --- get integer in biased VT52 form          *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Async_Integer( VAR Integr: INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Procedure: Get_Async_Integer                                       *)
(*                                                                      *)
(*   Purpose:  Gets integer in biased VT52 form from COM port           *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      Get_Async_Integer( Var Integr: INTEGER );                       *)
(*                                                                      *)
(*         Integr: Returned integer value                               *)
(*                                                                      *)
(*   Calls:  None                                                       *)
(*                                                                      *)
(*   Remarks:                                                           *)
(*                                                                      *)
(*      The screen positions on the VT52 are expressed in excess 31     *)
(*      notation.  That is, the value 31 is added to each row and       *)
(*      column value.                                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   C  : INTEGER;

BEGIN (* Get_Async_Integer *)

   Async_Receive_With_TimeOut( 5 , C );

   IF C = TimeOut THEN
      Integr := 0
   ELSE
      Integr := C - 31;

END   (* Get_Async_Integer *);
