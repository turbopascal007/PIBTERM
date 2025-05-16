(*----------------------------------------------------------------------*)
(*   Handle_Function_Key --- Handle function key input during transfers *)
(*----------------------------------------------------------------------*)

PROCEDURE Handle_Function_Key( Ch : CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Handle_Function_Key                                  *)
(*                                                                      *)
(*     Purpose:    Handle function key input during transfers           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Handle_Function_Key( Ch : CHAR );                             *)
(*                                                                      *)
(*           Ch --- Probable function key (ESC just read before it)     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Key_No: INTEGER;
   I     : INTEGER;
   J     : INTEGER;

BEGIN (* Handle_Function_Key *)

   Key_No := ORD( Ch );

   IF ( Pibterm_Command_Table[ Key_No ] = KeySendSy ) THEN
      IF ( Key_Definitions[Key_No].Def <> NIL ) THEN
         Send_Function_Key( Key_Definitions[Key_No].Def^ );

END   (* Handle_Function_Key *);