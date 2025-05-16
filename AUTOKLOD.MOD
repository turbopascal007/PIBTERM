(*----------------------------------------------------------------------*)
(*       Load_Function_Keys --- Load function key definitions           *)
(*----------------------------------------------------------------------*)

PROCEDURE Load_Function_Keys( File_Name : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Load_Function_Keys                                   *)
(*                                                                      *)
(*     Purpose:    Load function keys for terminal emulations           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Load_Function_Keys( File_Name : AnyStr );                     *)
(*                                                                      *)
(*           File_Name --- file with function key definitions           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Load_Function_Keys *)

   Set_Input_Keys( File_Name , TRUE );

END   (* Load_Function_Keys *);