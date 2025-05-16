(*----------------------------------------------------------------------*)
(*             PibDownLoad --- Control routine for downloads            *)
(*----------------------------------------------------------------------*)

PROCEDURE PibDownLoad( Transfer_Protocol : Transfer_Type );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  PibDownload                                          *)
(*                                                                      *)
(*     Purpose:    Controls downloading of files from remote hosts.     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        PibDownLoad( Transfer_Protocol : Transfer_Type );             *)
(*                                                                      *)
(*           Transfer_Protocol --- the type of transfer protocol        *)
(*                                 be used; if None is given, then      *)
(*                                 a prompt is issued for the transfer  *)
(*                                 protocol.                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* PibDownLoad *)

   PibUpDown( Transfer_Protocol , 'R' );

END   (* PibDownLoad *);
