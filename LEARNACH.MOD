(*----------------------------------------------------------------------*)
(*        Learn_A_Character --- Learn character for script              *)
(*----------------------------------------------------------------------*)

PROCEDURE Learn_A_Character( Ch : CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*       Procedure:   Learn_A_Character                                 *)
(*                                                                      *)
(*       Purpose:     Learn character for script in learn mode          *)
(*                                                                      *)
(*       Calling Sequence:                                              *)
(*                                                                      *)
(*          Learn_A_Character( Ch: CHAR );                              *)
(*                                                                      *)
(*             Ch --- Character to be learned                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   L: INTEGER;
   I: INTEGER;
   J: INTEGER;
   K: INTEGER;

BEGIN (* Learn_A_Character *)
                                   (* Output stuff from remote system *)

   IF ( LENGTH( Script_String_2 ) <> 0 ) THEN

                                   (* Any waitstring after first in sequence *)
                                   (* is spurious so don't generate it.      *)

      IF ( NOT Script_Wait_Generated ) THEN
         BEGIN

            L := LENGTH( Script_String_2 );
            J := L;
            K := 0;
                                   (* If last chars are CR+LF, back up    *)
                                   (* in front of them.                   *)
            IF ( L > 1 ) THEN
               IF ( ( Script_String_2[L]       = CHR( LF ) ) AND
                    ( Script_String_2[PRED(L)] = CHR( CR ) ) ) THEN
                  BEGIN
                     DEC( L , 2 );
                     J := L;
                  END;
                                   (* Loop until required number of lines *)
                                   (* picked up.                          *)
            REPEAT

               I := J;
               L := J;
                                   (* Scan for CR and LFs *)

               WHILE ( ( I > 1 ) AND ( NOT ( Script_String_2[I] IN [^M,^J] ) ) ) DO
                  DEC( I );
                                   (* Adjust text pointer for next line *)

               IF ( Script_String_2[I] = CHR( LF ) ) THEN
                  IF ( Script_String_2[PRED(I)] = CHR( CR ) ) THEN
                     J := I - 2
                  ELSE
                     J := PRED( I )
               ELSE
                  J := PRED( I );
                                   (* Point after CR or LF *)

               IF ( Script_String_2[I] IN [^M,^J] ) THEN
                  INC( I );
                                   (* Generate waitstring if we got something *)

               IF ( I > 0 ) THEN
                  IF ( ( L - I + 1 ) > 0 ) THEN
                     BEGIN
                        WRITELN( Script_File , 'WaitString "',
                                 Write_Ctrls( COPY( Script_String_2, I, L - I + 1 ) ), '"' );
                        INC( K );
                     END;

            UNTIL ( ( K >= Script_Learn_Lines ) OR ( I <= 1 ) );

                                   (* Indicate a waitstring has been generated *)

            Script_Wait_Generated := TRUE;

         END;

   Script_String_2 := '';
                                   (* If CR, end of user input, generate SText *)
   IF( ORD( Ch ) = CR ) THEN
      BEGIN
         WRITELN( Script_File , 'SText "', Script_String, '|"' );
         Script_String         := '';
         Script_Wait_Generated := FALSE;
      END
   ELSE
      IF ( LENGTH( Script_String ) = 240 ) THEN
         BEGIN
            MOVE( Script_String[2], Script_String[1], 239 );
            Script_String[240] := Ch;
         END
      ELSE
         Script_String := Script_String + Ch;

END   (* Learn_A_Character *);