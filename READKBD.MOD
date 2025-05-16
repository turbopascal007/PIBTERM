(*----------------------------------------------------------------------*)
(*            Read_Kbd --- Read one character from keyboard             *)
(*----------------------------------------------------------------------*)

PROCEDURE Read_Kbd( VAR Ch: CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Read_Kbd                                             *)
(*                                                                      *)
(*     Purpose:    Reads one character from the keyboard                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Read_Kbd( VAR Ch: CHAR );                                     *)
(*                                                                      *)
(*           Ch  --- Character read                                     *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine centralizes single character keyboard reads so   *)
(*        that time-slicing control for multitaskers is more easily     *)
(*        centralized.  In this particular implementation, the time     *)
(*        spent waiting for a keyboard entry is donated to the other    *)
(*        DoubleDos partition.                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Read_Kbd *)

   WHILE ( NOT PibTerm_KeyPressed ) DO
      GiveAwayTime( 2 );

   Ch := ReadKeyboard;

END   (* Read_Kbd *);

(*----------------------------------------------------------------------*)
(*  Read_Kbd_Old --- Read one character from keyboard ignoring extended *)
(*----------------------------------------------------------------------*)

PROCEDURE Read_Kbd_Old( VAR Ch: CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Read_Kbd_Old                                         *)
(*                                                                      *)
(*     Purpose:    Reads one character from the keyboard, but           *)
(*                 ignores presence of extended 101-key keyboard.       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Read_Kbd_Old( VAR Ch: CHAR );                                 *)
(*                                                                      *)
(*           Ch  --- Character read                                     *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine is useful when reading cursor input for menus    *)
(*        so that it isn't necessary to explicitly check for both       *)
(*        sets of cursor keys, both sets of position keys, etc.         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Use_Ext : BOOLEAN;

BEGIN (* Read_Kbd_Old *)

   WHILE ( NOT PibTerm_KeyPressed ) DO
      GiveAwayTime( 2 );

   Use_Ext           := Extended_Keyboard;
   Extended_Keyboard := FALSE;

   Ch := ReadKeyboard;

   Extended_Keyboard := Use_Ext;

END   (* Read_Kbd_Old *);
