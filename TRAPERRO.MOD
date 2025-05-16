(*----------------------------------------------------------------------*)
(*     Trap_Error --- Trap errors and transfer to real error handler    *)
(*----------------------------------------------------------------------*)

PROCEDURE Trap_Error( ErrNo , ErrAddr : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Trap_Error                                           *)
(*                                                                      *)
(*     Purpose:    Handles PibTerm program aborts                       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Trap_Error( ErrNo , ErrAddr : INTEGER );                      *)
(*                                                                      *)
(*           ErrNo    --- error number/type                             *)
(*           ErrAddr  --- address where error occurred                  *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine simply calls the genuine error handler procedure *)
(*        ERROR_HANDLER.  Trap_Error exists to allow the non-main       *)
(*        modules in PibTerm access to the error handler in the main    *)
(*        module.                                                       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Trap_Error *)

   Error_Handler( ErrNo, ErrAddr );
   
END   (* Trap_Error *);
