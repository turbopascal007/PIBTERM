(*----------------------------------------------------------------------*)
(* Display_Character_Through_DOS --- show character received from port  *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Character_Through_DOS( Ch: CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Display_Character_Through_Dos                        *)
(*                                                                      *)
(*     Purpose:    Displays character received from comm. port on       *)
(*                 screen/printer/capture file.                         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Display_Character_Through_Dos( Ch : CHAR );                   *)
(*                                                                      *)
(*           Ch         --- Character received from Comm. port.         *)
(*                                                                      *)
(*      Calls:   Capture_Char                                           *)
(*               Update_Review_Pointers                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I    : INTEGER;

BEGIN (* Display_Character_Through_DOS *)

                                   (* Select display depending on *)
                                   (* character.                  *)
   CASE ORD( Ch ) OF

      CR   :       IF Add_LF THEN
                      BEGIN

                         IF Capture_On THEN
                            Capture_Char( CHR( LF ) );

                         IF Printer_On THEN
                            BEGIN
                               Write_Prt( CHR( CR ) );
                               Write_Prt( CHR( LF ) );
                            END;

                         INLINE(
                                 $B4/$02 {  MOV    AH,2    ;DOS display character function}
                                /$B2/<CR {  MOV    DL,<CR  ;Character to display}
                                /$CD/$21 {  INT    $21     ;Call DOS}
                               );

                         INLINE(
                                 $B4/$02 {  MOV    AH,2    ;DOS display character function}
                                /$B2/<LF {  MOV    DL,<LF  ;Character to display}
                                /$CD/$21 {  INT    $21     ;Call DOS}
                               );

                         IF Review_On THEN
                            Update_Review_Pointers;

                      END
                   ELSE
                      BEGIN

                         INLINE(
                                 $B4/$02 {  MOV    AH,2    ;DOS display character function}
                                /$B2/<CR {  MOV    DL,<CR  ;Character to display}
                                /$CD/$21 {  INT    $21     ;Call DOS}
                               );

                         IF Printer_On THEN
                            Write_Prt( CHR( CR ) );

                      END;

      LF   :       IF NOT Add_LF THEN
                      BEGIN
                         IF Capture_On THEN
                            Capture_Char( CHR( LF ) );
                         INLINE(
                                 $B4/$02 {  MOV    AH,2    ;DOS display character function}
                                /$B2/<LF {  MOV    DL,<LF  ;Character to display}
                                /$CD/$21 {  INT    $21     ;Call DOS}
                               );
                         IF Printer_On THEN
                            Write_Prt( CHR( LF ) );
                         IF Review_On THEN
                            Update_Review_Pointers;
                      END;

      VT, FF:      BEGIN
                      IF Capture_On THEN
                         Capture_Char( Ch );
                      IF Printer_On THEN
                         Write_Prt( Ch );
                      INLINE(
                              $B4/$02     {  MOV    AH,2        ;DOS display character function}
                             /$8A/$56/<CH {  MOV    DL,[BP+<Ch] ;Character to display}
                             /$CD/$21     {  INT    $21         ;Call DOS}
                            );
                      IF Review_On THEN
                         Update_Review_Pointers;
                   END;

      ELSE         BEGIN

                      INLINE(
                              $B4/$02     {  MOV    AH,2        ;DOS display character function}
                             /$8A/$56/<CH {  MOV    DL,[BP+<Ch] ;Character to display}
                             /$CD/$21     {  INT    $21         ;Call DOS}
                            );

                      IF Capture_On THEN
                         Capture_Char( Ch );

                      IF Printer_On THEN
                         Write_Prt( Ch );

                      IF Review_On THEN
                         IF ( LENGTH( Review_Line ) < Max_Review_Line_Length ) THEN
                            Review_Line := Review_Line + Ch;

                   END;

      END;

END   (* Display_Character_Through_Dos *);
