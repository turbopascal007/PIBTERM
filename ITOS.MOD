(*----------------------------------------------------------------------*)
(*               IToS --- Convert integer number to string              *)
(*----------------------------------------------------------------------*)

FUNCTION IToS( Integr : INTEGER ) : ShortStr;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   IToS                                                 *)
(*                                                                      *)
(*     Purpose:    Convert integer to string                            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        IntString := IToS( Integr : INTEGER ) : ShortStr;             *)
(*                                                                      *)
(*           Integr     --- decimal integer to convert to string        *)
(*           IntString  --- resultant string                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   S: ShortStr;

BEGIN (* IToS *)

   STR( Integr , S );

   IToS := S;

END   (* IToS *);
