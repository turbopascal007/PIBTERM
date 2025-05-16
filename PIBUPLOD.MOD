(*----------------------------------------------------------------------*)
(*           PibUpLoad --- Control routine for uploads/downloads        *)
(*----------------------------------------------------------------------*)

PROCEDURE PibUpLoad( Transfer_Protocol : Transfer_Type );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  PibUpload                                            *)
(*                                                                      *)
(*     Purpose:    Controls uploading of files to remote hosts.         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        PibUpLoad( Transfer_Protocol : Transfer_Type );               *)
(*                                                                      *)
(*           Transfer_Protocol --- type of transfer to do               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* PibUpLoad *)

   PibUpDown( Transfer_Protocol , 'S' );

END   (* PibUpLoad *);
