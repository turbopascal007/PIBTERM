(*----------------------------------------------------------------------*)
(*               Do_Kermit --- Execute kermit protocol                  *)
(*----------------------------------------------------------------------*)

PROCEDURE Do_Kermit( Transfer_Direction : CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Do_Kermit                                            *)
(*                                                                      *)
(*     Purpose:    Executes Kermit protocol                             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Do_Kermit( Transfer_Direction : CHAR );                       *)
(*                                                                      *)
(*           Transfer_Direction --- 'S' for upload, 'R' for download    *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine loops over the send/receive portions of Kermit   *)
(*        as needed.  It is not used in host mode.                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Do_Kermit *)

   REPEAT

      CASE Transfer_Direction OF

         'S':   Send_Kermit_File;
         'R':   Receive_Kermit_File;
         ELSE
                Kermit_Really_Done := TRUE;

      END (* CASE *);

      IF ( NOT Kermit_Really_Done ) THEN
         IF ( Transfer_Direction = 'S' ) THEN
            Transfer_Direction := 'R'
         ELSE
            Transfer_Direction := 'S';

   UNTIL  Kermit_Really_Done;

END   (* Do_Kermit *);