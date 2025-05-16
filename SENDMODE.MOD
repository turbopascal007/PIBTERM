(*----------------------------------------------------------------------*)
(*             Send_Modem_Command --- Send command to modem             *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Modem_Command( Modem_Text : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Send_Modem_Command                                   *)
(*                                                                      *)
(*     Purpose:    Sends command to modem                               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*         Send_Modem_Command( Modem_Text : AnyStr );                   *)
(*                                                                      *)
(*           Modem_Text --- text of command to send to modem            *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Async_Send_Now                                                *)
(*        Async_Receive                                                 *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*          If the string to be sent has not "Wait For" markers, then   *)
(*          it is sent in its entirety in one call here.  If there ARE  *)
(*          "Wait For" characters, then the flag WaitString_Mode is set *)
(*          TRUE, Script_When_Text is set to the character to be found, *)
(*          and  Script_When_Reply_Text is set to the remainder of the  *)
(*          function key string.  This allows the terminal emulation to *)
(*          properly process any received characters while PibTerm is   *)
(*          waiting for the selected string to appear.                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)


VAR
   I:       INTEGER;
   L:       INTEGER;
   Ch:      CHAR;
   MO_Char: CHAR;
   Done:    BOOLEAN;

BEGIN (* Send_Modem_Command *)

   L      := LENGTH( Modem_Text );
   I      := 1;
   Done   := FALSE;

   WHILE( I <= L ) AND ( NOT Done ) DO
      BEGIN

         MO_Char := Modem_Text[I];

         IF MO_Char = FK_CR THEN
            Async_Send_Now( CHR( CR ) )

         ELSE IF MO_Char = FK_Delay THEN
            DELAY( One_Second_Delay )

         ELSE IF MO_Char = FK_Wait_For THEN
            BEGIN   (* Wait For *)

               INC( I );

               IF ( I <= L ) THEN
                  BEGIN

                     WITH Script_Wait_List[1] DO
                        BEGIN
                           NEW( Wait_Text );
                           IF ( Wait_Text <> NIL ) THEN
                              Wait_Text^ := Modem_Text[I];
                           NEW( Wait_Reply );
                           INC( I );
                           IF ( Wait_Reply <> NIL ) THEN
                              BEGIN
                                 IF ( I <= L ) THEN
                                    Wait_Reply^ := COPY( Modem_Text, I, SUCC( L - I ) )
                                 ELSE
                                    Wait_Reply^ := '';
                                 Script_Wait_Check_Length := 1;
                              END;
                        END;

                     Script_Wait_Count      := 1;
                     WaitString_Mode        := TRUE;
                     Really_Wait_String     := TRUE;
                     Script_Wait_Time       := Script_Default_Wait_Time;
                     IF ( Script_Wait_Time <= 0 ) THEN
                        Script_Wait_Time := 60;
                     Script_Wait_Failure    := 0;
                     Done                   := TRUE;
                     Script_Wait_Start      := TimeOfDay;

                  END;

            END
         ELSE IF MO_Char = FK_Ctrl_Mark THEN
            BEGIN
               IF ( ( I + 2 ) <= L ) THEN
                  IF ( Modem_Text[ SUCC( I ) ] = '''' ) THEN
                     INC( I , 2 );
               Async_Send_Now( Modem_Text[I] );
            END
         ELSE
            BEGIN
               Async_Send_Now( Modem_Text[I] );
               IF ( Modem_Command_Delay > 0 )
                  THEN DELAY( Modem_Command_Delay );
            END;

         INC( I );

      END;

END   (* Send_Modem_Command *);
