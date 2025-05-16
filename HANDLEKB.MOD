(*----------------------------------------------------------------------*)
(*     Handle_Keyboard_Input ---  Read keyboard input in terminal mode  *)
(*----------------------------------------------------------------------*)

PROCEDURE Handle_Keyboard_Input( VAR Done                  : BOOLEAN;
                                 VAR Reset_Requested       : BOOLEAN;
                                 VAR ClearScreen_Requested : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Handle_Keyboard_Input                                *)
(*                                                                      *)
(*     Purpose:    Reads keyboard input in terminal modes               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Handle_Keyboard_Input                                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Ch               : CHAR;
   Save_Screen_Line : INTEGER;
   Save_Screen_Col  : INTEGER;
   I                : INTEGER;

BEGIN (* Handle_Keyboard_Input *)

                                   (* Read input character *)
   Read_Kbd( Ch );
                                   (* Assume not reset     *)
   Reset_Requested := FALSE;
                                   (* Assume not clear screen *)
   ClearScreen_Requested := FALSE;
                                   (* Process it           *)
   IF ( Ch = CHR( ESC ) ) THEN
      IF PibTerm_KeyPressed THEN
         BEGIN  (* Escape AND PibTerm_KeyPressed *)

                                   (* Get character following escape *)
            Read_Kbd( Ch );

            IF ( Ch = CHR( SI ) ) THEN
               Reset_Requested := TRUE
            ELSE
               BEGIN  (* Not terminal reset *)

                  Save_Screen_Line := Max_Screen_Line;
                  Save_Screen_Col  := Max_Screen_Col;

                  Process_Command( Ch, TRUE, PibTerm_Command );

                  CASE PibTerm_Command OF
                     Null_Command: ;
                     ClearSy     : ClearScreen_Requested := TRUE;
                     ELSE
                                   Execute_Command( PibTerm_Command, Done, FALSE );
                  END (* CASE *);

                  Reset_Requested := ( Max_Screen_Line <> Save_Screen_Line ) OR
                                     ( Max_Screen_Col  <> Save_Screen_Col  );

               END   (* Not terminal reset *);

            EXIT;

         END  (* Escape AND PibTerm_KeyPressed *)
      ELSE  (* Escape only *)
         IF Async_XOff_Received THEN
            BEGIN
               Clear_XOFF_Received;
               EXIT;
            END;
                                   (* Convert characters to upper case *)
   IF Send_Upper_Case_Only THEN
      Ch := UpCase( Ch );
                                   (* Learn this character if doing a *)
                                   (* learn script.                   *)
   IF Script_Learn_Mode THEN
      Learn_A_Character( Ch );
                                   (* We must handle the BS and Ctrl_BS  *)
                                   (* requests specially, since they can *)
                                   (* be strings.                        *)
   CASE ORD( Ch ) OF

      DEL  : BEGIN
                                   (* Send ctrl-backspace.  If local    *)
                                   (* echo, store characters in receive *)
                                   (* buffer.                           *)

                FOR I := 1 TO LENGTH( Ctrl_BS_String ) DO
                   BEGIN
                      Async_Send ( Ctrl_BS_String[ I ] );
                      IF Gossip_Mode_On THEN
                         Display_Character( Ctrl_BS_String[I] )
                      ELSE IF Local_Echo THEN
                         Async_Stuff( Ctrl_BS_String[ I ] );
                   END;
                                   (* Move back in saved input line *)

                IF ( Keyboard_Line_Pos > 0 ) THEN
                   DEC( Keyboard_Line_Pos );

             END;

      BS   : BEGIN
                                   (* Send backspace.  Also, if local   *)
                                   (* echo, store characters in receive *)
                                   (* buffer.                           *)

                FOR I := 1 TO LENGTH( BS_String ) DO
                   BEGIN
                      Async_Send ( BS_String[ I ] );
                      IF Gossip_Mode_On THEN
                         Display_Character( BS_String[I] )
                      ELSE IF Local_Echo THEN
                         Async_Stuff( BS_String[ I ] );
                   END;
                                   (* Move back in saved input line *)

                IF ( Keyboard_Line_Pos > 0 ) THEN
                   DEC( Keyboard_Line_Pos );

             END;

      ELSE   BEGIN (* Other characters *)

                                   (* Put char in received buffer if *)
                                   (* local echo on so we display it *)
                                   (* later on, except XOFF.         *)

                IF ( Ch <> CHR( XOFF ) ) THEN
                   IF Gossip_Mode_On THEN
                      Display_Character( Ch )
                   ELSE IF Local_Echo THEN
                      Async_Stuff( Ch );

                                   (* Send this character to remote.  *)
                Async_Send( Ch );
                                   (* If Ch = CR and New_Line mode, send  *)
                                   (* a LF as well.                       *)

                IF ( Ch = CHR( CR ) ) THEN
                   BEGIN
                      IF New_Line THEN
                         Async_Send( CHR( LF ) );
                      IF Gossip_Mode_On THEN
                         Display_Character( CHR( LF ) );
                   END;

                                   (* Stuff character into keyboard line  *)

                IF ( Keyboard_Line_Pos = 255 ) THEN
                   BEGIN
                      MOVE( Keyboard_Line[2], Keyboard_Line[1], 254 );
                      Keyboard_Line[255] := Ch;
                   END
                ELSE
                   BEGIN
                      INC( Keyboard_Line_Pos );
                      Keyboard_Line[Keyboard_Line_Pos] := Ch;
                   END;

                Keyboard_Line[0] := CHR( Keyboard_Line_Pos );

                IF ( Ch = CHR( CR ) ) THEN
                   Keyboard_Line_Pos := 0;

             END   (* Other characters *);

   END (* CASE *);

END   (* Handle_Keyboard_Input *);
