(*--------------------------------------------------------------------------*)
(*       Read_Edited_String  -- Read in string and allow keypad editing     *)
(*--------------------------------------------------------------------------*)

PROCEDURE Read_Edited_String( VAR S: AnyStr );

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Procedure: Read_Edited_String                                        *)
(*                                                                          *)
(*     Purpose:   Provides for editing a string using keypad keys.          *)
(*                                                                          *)
(*     Calling Sequence:                                                    *)
(*                                                                          *)
(*        Read_Edited_String( VAR S : AnyStr );                             *)
(*                                                                          *)
(*           S --- Where input string should be placed                      *)
(*                                                                          *)
(*     Calls:    Edit_String                                                *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   Ch : CHAR;
   X  : INTEGER;
   Y  : INTEGER;
   W  : INTEGER;

BEGIN (* Read_Edited_String *)

   X  := WhereX;
   Y  := WhereY;

   W  := MAX( 1 , PRED( Lower_Right_Column - ( PRED( X ) + Upper_Left_Column ) ) );

   Ch := Edit_String( S, 255, X, X, Y, W, FALSE, 0 );

   IF ( ( LENGTH( S ) = 0 ) AND ( Ch = CHR( ESC ) ) ) THEN
      S := CHR( ESC );

END   (* Read_Edited_String *);
