(*----------------------------------------------------------------------*)
(*               Min --- Find minimum of two integers                   *)
(*----------------------------------------------------------------------*)

FUNCTION Min( A, B: INTEGER ) : INTEGER;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Function: Min                                                      *)
(*                                                                      *)
(*   Purpose:  Returns smaller of two numbers                           *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      Smaller := MIN( A , B ) : INTEGER;                              *)
(*                                                                      *)
(*         A       --- 1st input integer number                         *)
(*         B       --- 2nd input integer number                         *)
(*         Smaller --- smaller of A, B returned                         *)
(*                                                                      *)
(*                                                                      *)
(*   Calls:  None                                                       *)
(*                                                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Min *)

   IF ( A < B ) THEN
      Min := A
   ELSE
      Min := B;

END   (* Min *);

(*----------------------------------------------------------------------*)
(*               Max --- Find maximum of two integers                   *)
(*----------------------------------------------------------------------*)

FUNCTION Max( A, B: INTEGER ) : INTEGER;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Function:  Max                                                     *)
(*                                                                      *)
(*   Purpose:  Returns larger of two numbers                            *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      Larger := MAX( A , B ) : INTEGER;                               *)
(*                                                                      *)
(*         A       --- 1st input integer number                         *)
(*         B       --- 2nd input integer number                         *)
(*         Larger  --- Larger of A, B returned                          *)
(*                                                                      *)
(*                                                                      *)
(*   Calls:  None                                                       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Max *)

   IF ( A > B ) THEN
      Max := A
   ELSE
      Max := B;

END   (* Max *);
