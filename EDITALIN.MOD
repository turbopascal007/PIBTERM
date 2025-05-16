(*--------------------------------------------------------------------------*)
(*       Edit_A_Line --- Edit line on screen and resend to host             *)
(*--------------------------------------------------------------------------*)

PROCEDURE Edit_A_Line;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*    Function: Edit_A_Line                                                 *)
(*                                                                          *)
(*    Purpose:  Edit line on screen and resend to host                      *)
(*                                                                          *)
(*    Calling Sequence:                                                     *)
(*                                                                          *)
(*       Edit_A_Line;                                                       *)
(*                                                                          *)
(*    Calls:  EditString                                                    *)
(*            Async_Send                                                    *)
(*            Get_Screen_Text_Line                                          *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   I           : INTEGER;
   L1          : INTEGER;
   L2          : INTEGER;
   S           : AnyStr;
   S2          : AnyStr;
   S3          : AnyStr;
   Ch          : CHAR;
   X           : INTEGER;
   Y           : INTEGER;
   Saved_Line  : AnyStr;
   Status_Line : INTEGER;
   Old_Status  : INTEGER;
   Saved_X     : BYTE;
   Saved_Y     : BYTE;
   Saved_X_2   : BYTE;
   Saved_Y_2   : BYTE;
   Max_Line    : INTEGER;
   KTop        : INTEGER;
   KBottom     : INTEGER;

(*--------------------------------------------------------------------------*)

PROCEDURE Set_Up_Status_Line;

BEGIN (* Set_Up_Status_Line *)

   IF Y <> 1 THEN
      Status_Line := 1
   ELSE
      Status_Line := Max_Line;

   IF ( Status_Line <> Old_Status ) THEN
      BEGIN

         Saved_X_2 := WhereX;
         Saved_Y_2 := WhereY;

         GoToXY( 1 , Old_Status );
         WRITE( TRIM( Saved_Line ) );
         ClrEol;

         Old_Status := Status_Line;

         Get_Screen_Text_Line( Saved_Line, Status_Line, 1 );

         GoToXY( Saved_X_2, Saved_Y_2 );

      END;

END   (* Set_Up_Status_Line *);

(*--------------------------------------------------------------------------*)

BEGIN (* Edit_A_Line *)
                                   (* Not available in graphics mode *)

   IF ( ( Current_Video_Mode = HiRes_GraphMode ) OR
        ( Current_Video_Mode = EGA_GraphMode   ) ) THEN EXIT;

                                   (* Figure out and remember current *)
                                   (* position                        *)
   X       := 1;
   Y       := WhereY;

   Saved_X := WhereX;
   Saved_Y := Y;
                                   (* Figure max line to edit *)
   IF Do_Status_Line THEN
      Max_Line := PRED( Max_Screen_Line )
   ELSE
      Max_Line := Max_Screen_Line;

                                   (* Figure out where status line goes *)
   IF Y <> 1 THEN
      Old_Status := 1
   ELSE
      Old_Status := Max_Line;
                                   (* Get text line to be edited *)

   Get_Screen_Text_Line( Saved_Line, Old_Status, 1 );

                                   (* No range of lines yet selected. *)
   KTop    := 0;
   KBottom := 0;
                                   (* Begin edit loop. *)
   REPEAT
                                   (* Display status line *)
      Set_Up_Status_Line;
                                   (* Get text of line to be edited *)

      Get_Screen_Text_Line( S, Y, 1 );

      S  := Trim( S );
      S3 := S;
                                   (* Edit the line *)

      X  := MAX( 1 , MIN( X , LENGTH( S ) ) );
      Ch := Edit_String( S, 255, 1, X, Y, Max_Screen_Col, FALSE, Status_Line );
      X  := WhereX;
                                   (* If line changed, send revised text *)

      IF ( ( Ch <> CHR( ESC ) ) AND ( Ch <> ^K ) ) THEN
         IF ( S <> S3 ) THEN
            Async_Send_String( Trim( S ) + CHR( CR ) );

                                   (* Move to new line if needed *)
      CASE Ch OF
         ^E:  IF ( Y > 1        ) THEN DEC( Y );
         ^X:  IF ( Y < Max_Line ) THEN INC( Y );
         ^K:  IF ( KTop = 0 ) THEN
                 KTop := Y
              ELSE
                 BEGIN

                    KBottom := Y;

                    IF ( KBottom < KTop ) THEN
                       BEGIN
                          I       := KTop;
                          KTop    := KBottom;
                          KBottom := I;
                       END;

                    S  := '';
                    Y  := KTop;

                    Set_Up_Status_Line;

                    FOR I := KTop TO KBottom DO
                       BEGIN
                          Get_Screen_Text_Line( S2, I, 1 );
                          IF ( I = KBottom ) THEN
                             S2 := TRIM( S2 );
                          L1 := LENGTH( S ) + LENGTH( S2 );
                          IF ( L1 <= 255 ) THEN
                             S := S + S2
                          ELSE
                             S := S + COPY( S2, 1, 255 - LENGTH( S ) );
                       END;

                    S3 := S;

                    X  := MAX( 1 , MIN( X , LENGTH( S ) ) );
                    Ch := Edit_String( S, 255, 1, X, Y, Max_Screen_Col,
                                       FALSE, Status_Line );
                    X  := WhereX;

                                   (* If line changed, send revised text *)

                    IF ( Ch <> CHR( ESC ) ) THEN
                       IF ( S <> S3 ) THEN
                          Async_Send_String( Trim( S ) + CHR( CR ) );

                                   (* Reset to no line range selected *)
                    KTop    := 0;
                    KBottom := 0;

                 END;
         ELSE ;
      END (* CASE *);

   UNTIL ( Ch = CHR( CR ) );
                                   (* Restore previous line *)
   GoToXY( 1 , Status_Line );
   WRITE( TRIM( Saved_Line ) );
   ClrEol;
                                   (* Restore previous position *)
   GoToXY( Saved_X , Saved_Y );

END   (* Edit_A_Line *);
