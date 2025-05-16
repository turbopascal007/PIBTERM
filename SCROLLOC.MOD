(*----------------------------------------------------------------------*)
(*         Scroll_Lock_On --- Check if scroll lock key depressed        *)
(*----------------------------------------------------------------------*)

FUNCTION Scroll_Lock_On : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Scroll_Lock_On                                       *)
(*                                                                      *)
(*     Purpose:    Check if scroll lock key depressed                   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Lock_On := Scroll_Lock_On : BOOLEAN;                          *)
(*                                                                      *)
(*           Lock_On --- TRUE if scroll lock turned on                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Regs : Registers;
   
BEGIN (* Scroll_Lock_On *)

   Regs.Ah := 2;
   INTR( $16 , Regs );
   
   IF Do_Status_Time THEN
      Update_Status_Line;

   Scroll_Lock_On := ( ( Regs.AL AND $10 ) <> 0 );

END   (* Scroll_Lock_On *);
