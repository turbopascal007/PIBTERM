(*----------------------------------------------------------------------*)
(*  MaxBlockAvail --- returns size in bytes of largest free heap block  *)
(*----------------------------------------------------------------------*)

FUNCTION MaxBlockAvail : REAL;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   MaxBlockAvail                                        *)
(*                                                                      *)
(*     Purpose:    Returns size in bytes of largest free heap block     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Size := MaxBlockAvail : REAL;                                 *)
(*                                                                      *)
(*           Size --- returned size in bytes of largest available       *)
(*                    free block on heap.                               *)
(*                                                                      *)
(*     Calls:  MaxAvail                                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   NParagraphs : INTEGER;

BEGIN (* MaxBlockAvail *)

   NParagraphs := MaxAvail;

   IF Nparagraphs >= 0 THEN
      MaxBlockAvail := 16.0 * Nparagraphs
   ELSE
      MaxBlockAvail := 16.0 * ( 65536.0 + NParagraphs );

END   (* MaxBlockAvail *);
