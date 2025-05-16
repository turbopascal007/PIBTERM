(*----------------------------------------------------------------------*)
(*     Handle_Scroll_Lock --- Handle scroll lock in terminal mode       *)
(*----------------------------------------------------------------------*)

PROCEDURE Handle_Scroll_Lock;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Handle_Scroll_Lock                                   *)
(*                                                                      *)
(*     Purpose:    Handle scroll lock in terminal mode                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Handle_Scroll_Lock                                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Handle_Scroll_Lock *)
                                   (* Hold everything while scroll lock on *)

   IF Do_Status_Line THEN
      Write_To_Status_Line( 'Scroll Lock ON', 65 );

   WHILE Scroll_Lock_On DO
      GiveAwayTime( 1 );

   IF Do_Status_Line THEN
      Write_To_Status_Line( DUPL( ' ' , 14 ), 65 );

END   (* Handle_Scroll_Lock *);
