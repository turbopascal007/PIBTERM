(*----------------------------------------------------------------------*)
(*       Send_Function_Key  --- Send function key definition            *)
(*----------------------------------------------------------------------*)

PROCEDURE Send_Function_Key( Key_Text : AnyStr ) ;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*       Procedure:  Send_Function_Key                                  *)
(*                                                                      *)
(*       Purpose:    Send function key definition                       *)
(*                                                                      *)
(*       Calling Sequence:                                              *)
(*                                                                      *)
(*           Send_Function_Key( Key_Text : AnyStr );                    *)
(*                                                                      *)
(*              Input_Key_Text   --- text to be sent                    *)
(*                                                                      *)
(*       Remarks:                                                       *)
(*                                                                      *)
(*          If the string to be sent has not "Wait For" markers, then   *)
(*          it is sent in its entirety in one call here.  If there ARE  *)
(*          "Wait For" characters, then the flag WaitString_Mode is set *)
(*          TRUE, Script_Wait_Text is set to the character to be found, *)
(*          and  Script_Wait_Reply_Text is set to the remainder of the  *)
(*          function key string.  This allows the terminal emulation to *)
(*          properly process any received characters while PibTerm is   *)
(*          waiting for the selected string to appear.                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I       : INTEGER;
   L       : INTEGER;
   Ch      : CHAR;
   FK_Char : CHAR;
   Done    : BOOLEAN;
   Kbd_On  : BOOLEAN;
   Delim_Ch: CHAR;

CONST
   Alt_Vals: ARRAY['A'..'Z'] OF BYTE =
             ( Alt_A, Alt_B, Alt_C, Alt_D, Alt_E, Alt_F, Alt_G,
               Alt_H, Alt_I, Alt_J, Alt_K, Alt_L, Alt_M, Alt_N,
               Alt_O, Alt_P, Alt_Q, Alt_R, Alt_S, Alt_T, Alt_U,
               Alt_V, Alt_W, Alt_X, Alt_Y, Alt_Z );

(*----------------------------------------------------------------------*)

PROCEDURE FK_Send_Char( Ch : CHAR );

BEGIN (* FK_Send_Char *)

   Async_Send_Now( Ch );

   IF Local_Echo THEN
      Async_Stuff( Ch );

   IF ( FK_Delay_Time > 0 ) THEN
      DELAY( FK_Delay_Time );

END   (* FK_Send_Char *);

(*----------------------------------------------------------------------*)

BEGIN (* Send_Function_Key *)

   L        := LENGTH( Key_Text );
   I        := 1;
   Done     := FALSE;
   Kbd_On   := FALSE;

   WHILE( I <= L ) AND ( NOT Done ) DO
      BEGIN

         FK_Char := Key_Text[I];

         IF Kbd_On THEN
            BEGIN
               IF ( Key_Text[I] <> Delim_Ch ) THEN
                  Keyboard_Buffer := Keyboard_Buffer + Key_Text[I]
               ELSE
                  Kbd_On := FALSE;
            END
         ELSE IF FK_Char = FK_CR THEN
            FK_Send_Char( CHR( CR ) )

         ELSE IF FK_Char = FK_Delay THEN
            DELAY( One_Second_Delay )

         ELSE IF FK_Char = FK_Script_Ch THEN
            BEGIN
               INC( I );
               IF ( I <= L ) THEN
                  BEGIN
                     Ch := UpCase( Key_Text[I] );
                     IF ( Ch IN ['A'..'Z'] ) THEN
                        BEGIN
                           Keyboard_Buffer := Keyboard_Buffer +
                                              #$E0 + #$E0     +
                                              CHR( Alt_Vals[ Ch ] );
                           Kbd_On := FALSE;
                        END
                     ELSE
                        BEGIN
                           Delim_Ch := Key_Text[I];
                           Kbd_On   := TRUE;
                        END;
                  END;
            END

         ELSE IF FK_Char = FK_Ctrl_Mark THEN
            BEGIN
               IF ( ( I + 2 ) <= L ) THEN
                  IF ( Key_Text[ SUCC( I ) ] = '''' ) THEN
                     INC( I , 2 );
               Async_Send_Now( Key_Text[I] );
            END

         ELSE IF FK_Char = FK_Wait_For THEN
            BEGIN   (* Wait For *)

               INC( I );

               IF ( I <= L ) THEN
                  BEGIN

                     WITH Script_Wait_List[1] DO
                        BEGIN
                           NEW( Wait_Text );
                           IF( Wait_Text <> NIL ) THEN
                              Wait_Text^ := Key_Text[I];
                           NEW( Wait_Reply );
                           INC( I );
                           IF ( Wait_Reply <> NIL ) THEN
                              BEGIN
                                 IF ( I <= L ) THEN
                                    Wait_Reply^ := COPY( Key_Text, I, L - I + 1 )
                                 ELSE
                                    Wait_Reply^:= '';
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
         ELSE
            FK_Send_Char( Key_Text[I] );

         INC( I );

      END;

END   (* Send_Function_Key *);
