(*----------------------------------------------------------------------*)
(*   Do_Script_Checks --- Check Script-related quantities for character *)
(*----------------------------------------------------------------------*)

PROCEDURE Do_Script_Checks( Ch: CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Do_Script_Checks                                     *)
(*                                                                      *)
(*     Purpose:    Do script-related checks on character received       *)
(*                 from comm port.                                      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Do_Script_Checks( Ch : CHAR );                                *)
(*                                                                      *)
(*           Ch --- Character received from Comm. port.                 *)
(*                                                                      *)
(*      Calls:   TimeOfDay                                              *)
(*               TimeDiff                                               *)
(*               Send_Function_Key                                      *)
(*               Check_Wait_String_Time                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   L  : INTEGER;
   L2 : INTEGER;
   I  : INTEGER;

LABEL 1;

(*----------------------------------------------------------------------*)

FUNCTION CmpS( S1, S2 : AnyStr; N : INTEGER ) : BOOLEAN;

BEGIN (* CmpS *)

   N := MIN( N , LENGTH( S1 ) );
   N := MIN( N , LENGTH( S2 ) );

   CmpS := ( COPY( S1, 1, N ) = COPY( S2, 1, N ) );

END   (* CmpS *);

(*----------------------------------------------------------------------*)

BEGIN (* Do_Script_Checks *)
                                   (* Skip checks for NUL, DEL    *)

   IF ( ( Ch = CHR( NUL ) ) OR ( Ch = CHR( DEL ) ) ) THEN
      EXIT;
                                   (* Check for WHEN string       *)
   IF When_Mode THEN
      BEGIN

         L := LENGTH( Script_When_Save );

         IF ( L < LENGTH( Script_When_Text ) ) THEN
            Script_When_Save := Script_When_Save + Ch
         ELSE
            BEGIN

               MOVE( Script_When_Save[2], Script_When_Save[1], PRED( L ) );
               Script_When_Save[L] := Ch;

               IF ( Script_When_Text[1] = Script_When_Save[1] ) THEN
                  IF ( CmpS( Script_When_Text , Script_When_Save , L ) ) THEN
                     BEGIN
                        Script_When_Save := '';
                        Send_Function_Key( Read_Ctrls( Script_When_Reply_Text ) );
                     END;

            END;

      END (* When_Mode *);

                                   (* Check for WAITCOUNT *)
   IF WaitCount_Mode THEN
      BEGIN
         INC( Script_Wait_Char_Count );
         IF ( Script_Wait_Char_Count >= Script_Wait_Check_Length ) THEN
            BEGIN
               WaitCount_Mode     := FALSE;
               Really_Wait_String := FALSE;
               Script_Wait_Found  := TRUE;
            END
         ELSE IF ( TimeDiff( Script_Wait_Start , TimeOfDay ) > Script_Wait_Time ) THEN
            BEGIN
               WaitCount_Mode      := FALSE;
               Really_Wait_String  := FALSE;
               Script_Wait_Found   := FALSE;
            END;
      END;
                                   (* Check for WAIT string       *)
   IF WaitString_Mode THEN
      BEGIN
                                   (* Add in new character and        *)
                                   (* check if wait string(s) present *)

         L := LENGTH( Script_Wait_Save );

         IF ( L < Script_Wait_Check_Length ) THEN
            Script_Wait_Save := Script_Wait_Save + Ch
         ELSE
            BEGIN
               MOVE( Script_Wait_Save[2], Script_Wait_Save[1], PRED( L ) );
               Script_Wait_Save[L] := Ch;
            END;

         FOR I := 1 TO Script_Wait_Count DO
            WITH Script_Wait_List[I] DO
               BEGIN
                  L2 := LENGTH( Wait_Text^ );
                  IF( L >= L2 ) THEN
                     IF ( Wait_Text^[1] = Script_Wait_Save[L - L2 + 1] ) THEN
                        IF ( CmpS( Wait_Text^ ,
                             COPY( Script_Wait_Save, L - L2 + 1, 255 ),
                             L2 ) ) THEN
                           BEGIN
                              Script_Wait_Save    := '';
                              Script_Wait_Found   := TRUE;
                              WaitString_Mode     := FALSE;
                              Really_Wait_String  := FALSE;
                              IF ( Script_Wait_Result_Index > 0 ) THEN
                                 Script_Variables^[Script_Wait_Result_Index].Var_Value^ :=
                                     CHR( I ) + CHR( 0 );
                              Send_Function_Key( Read_Ctrls( Wait_Reply^ ) );
                              GOTO 1;
                           END;
               END;
                                   (* Check if wait time exhausted *)
1:       IF WaitString_Mode THEN
            Check_Wait_String_Time
         ELSE                      (* Free up waitstring storage *)
            BEGIN
               FOR I := 1 TO Script_Wait_Count DO
                  WITH Script_Wait_List[I] DO
                     BEGIN
                        DISPOSE( Wait_Text );
                        DISPOSE( Wait_Reply );
                     END;
               Script_Wait_Count := 0;
            END;

      END  (* WaitString_Mode *);

                                   (* Check for Script LEARN mode *)
   IF Script_Learn_Mode THEN
      BEGIN

         L := LENGTH( Script_String_2 );

         IF ( L < Script_Learn_Buffer_Size ) THEN
            Script_String_2 := Script_String_2 + Ch
         ELSE
            BEGIN
               MOVE( Script_String_2[2], Script_String_2[1],
                     PRED( Script_Learn_Buffer_Size ) );
               Script_String_2[Script_Learn_Buffer_Size] := Ch;
            END;

      END (* Script_Learn_Mode *);

                                   (* Reset WAITQUIET *)
   IF WaitQuiet_Mode THEN
      Script_Wait_Start := TimeOfDayH;

END    (* Do_Script_Checks *);