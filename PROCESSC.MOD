(*----------------------------------------------------------------------*)
(*           Process_Command --- Process PibTerm  command               *)
(*----------------------------------------------------------------------*)

PROCEDURE Process_Command( VAR Ch       : CHAR;
                               Use_Ch   : BOOLEAN;
                           VAR Command  : PibTerm_Command_Type );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Process_Command                                      *)
(*                                                                      *)
(*     Purpose:    Process PibTerm Command escape sequence              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Process_Command(     VAR Ch  : CHAR;                          *)
(*                             Use_Ch  : BOOLEAN;                       *)
(*                         VAR Command : PibTerm_Command_Type );        *)
(*                                                                      *)
(*           Done    --- set TRUE if termination command (Alt-X) found  *)
(*           Ch      --- character following ESC                        *)
(*           Use_Ch  --- TRUE if Ch on entry is char following ESC,     *)
(*                       FALSE if Ch to be read here.                   *)
(*           Command --- Command to be executed                         *)
(*                                                                      *)
(*      Remarks:                                                        *)
(*                                                                      *)
(*         All PibTerm commands are implemented as escape sequences,    *)
(*         very much like PC-TALK or QMODEM.  The available commands    *)
(*         are:                                                         *)
(*                                                                      *)
(*            Alt-A:  Alter (block) mode                                *)
(*            Alt-B:  Send Break                                        *)
(*            Alt-C:  Clear Screen                                      *)
(*            Alt-D:  Dial a number                                     *)
(*            Alt-E:  Turn local echo ON/OFF                            *)
(*            Alt-F:  File manipulation                                 *)
(*            Alt-G:  Gossip (chat) mode                                *)
(*            Alt-H:  Hang up the phone                                 *)
(*            Alt-I:  Display program information (help)                *)
(*            Alt-J:  Jump to DOS                                       *)
(*            Alt-K:  Set function keys                                 *)
(*            Alt-L:  Log session to printer                            *)
(*            Alt-M:  Toggle Mute/Sound Mode                            *)
(*            Alt-N:  New communications params                         *)
(*            Alt-O:  Output session to disk                            *)
(*            Alt-P:  Set communications parameters                     *)
(*            Alt-Q:  Redial last number dialed                         *)
(*            Alt-R:  Receive a file from remote                        *)
(*            Alt-S:  Send file to remote                               *)
(*            Alt-T:  Set up translate table                            *)
(*            Alt-U:  Screen dump                                       *)
(*            Alt-V:  Review captured text                              *)
(*            Alt-W:  Set host mode (wait for call)                     *)
(*            Alt-X:  Leave Program                                     *)
(*            Alt-Y:  Examine timers                                    *)
(*            Alt-Z:  Area code search                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Process_Command *)
                                   (* Pick up character following escape *)
   IF ( NOT Use_Ch ) THEN
      Read_Kbd( Ch );
                                   (* Remember it                        *)
   Key_No  := ORD( Ch );
                                   (* Get corresponding command type     *)

   Command := PibTerm_Command_Table[ Key_No ];

                                   (* Ensure script strings are null     *)
   IF ( NOT Script_Learn_Mode ) THEN
      BEGIN
         Script_String       := '';
         Script_String_2     := '';
         Script_Integer_1    := 0;
      END;

END   (* Process_Command *);
