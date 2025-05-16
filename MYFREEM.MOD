(*----------------------------------------------------------------------*)
(*         MyFreeMem --- Free block of memory with error checking       *)
(*----------------------------------------------------------------------*)

PROCEDURE MyFreeMem( VAR P ; Size : WORD );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  MyFreeMem                                            *)
(*                                                                      *)
(*     Purpose:    Free block of memory with error checks.              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        MyFreeMem( VAR P : POINTER; Size : WORD );                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   PP : POINTER ABSOLUTE P;

BEGIN (* MyFreeMem *)

   IF ( ( PP <> NIL ) AND ( Size > 0 ) ) THEN
      FREEMEM( PP , Size );

   PP := NIL;

END   (* MyFreeMem *);
