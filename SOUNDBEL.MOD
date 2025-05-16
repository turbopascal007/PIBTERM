(*----------------------------------------------------------------------*)
(*         Sound_Bell --- Sound terminal bell                           *)
(*----------------------------------------------------------------------*)

PROCEDURE Sound_Bell;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Sound_Bell                                           *)
(*                                                                      *)
(*     Purpose:    Sounds terminal bell                                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Sound_Bell;                                                   *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine replaces the usual WRITE( ^G ) sequence which    *)
(*        causes too many dropped characters.                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Sound_Bell *)

   Sound( 900 );
   Delay( 40 );
   NoSound;

END   (* Sound_Bell *);
