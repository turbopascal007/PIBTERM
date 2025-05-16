(*----------------------------------------------------------------------*)
(*                Emulate_ANSI  -- Controls VT100 emulation             *)
(*----------------------------------------------------------------------*)

PROCEDURE Emulate_ANSI( VT100_Allowed : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*    Procedure: Emulate_ANSI                                           *)
(*                                                                      *)
(*    Purpose:   Controls ANSI terminal emulation                       *)
(*                                                                      *)
(*    Calling Sequence:                                                 *)
(*                                                                      *)
(*       Emulate_ANSI( VT100_allowed );                                 *)
(*                                                                      *)
(*          VT100_allowed --- TRUE to interpret private DEC sequences   *)
(*                                                                      *)
(*    Remarks:                                                          *)
(*                                                                      *)
(*       The ANSI and VT100 emulation are partly based upon TMODEM      *)
(*       by Paul Meiners and partly upon ISP100 by Tim Krauskopf.       *)
(*                                                                      *)
(*       VT100/ANSI commands are interpreted directly by these          *)
(*       routines -- the ANSI.SYS driver is not required and should     *)
(*       probably not be used, as it will result in an unnecessary      *)
(*       performance degradation.                                       *)
(*                                                                      *)
(*       This is by no means a complete VT100 or Ansi emulation.  It    *)
(*       works well enough so that the full-screen editors EDT under    *)
(*       VAX/VMS and FSE under CDC/NOS will perform properly.  That was *)
(*       my primary intention.  You may want to add code to emulate     *)
(*       other VT100/VT102/VT103/VT131 features not found here.  If you *)
(*       do, please send me back a copy so that I can add your upgrades *)
(*       to future releases of PibTerm.                                 *)
(*                                                                      *)
(*       ANSI/BBS mode assumes 25 lines on the screen.  VT100 mode      *)
(*       assumes only has 24.                                           *)
(*                                                                      *)
(*       The following variables are of central interest in the         *)
(*       emulation:                                                     *)
(*                                                                      *)
(*         Escape_Mode     --- TRUE if processing escape sequence       *)
(*         Escape_Type     --- Type of escape sequence being processed  *)
(*         Escape_Number   --- Number of numeric parameters in escape   *)
(*                             sequence                                 *)
(*         Escape_Register --- array of numeric parameters in escape    *)
(*                             sequence                                 *)
(*         Escape_Str      --- stores string of escape text; used to    *)
(*                             gather up a musical score for BBS Ansi.  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   Allow_Doubling      : BOOLEAN     (* TRUE to allow double width      *)
                         = TRUE;

VAR
   Comm_Ch             : CHAR        (* Character read from comm port   *);
   Double_Ch           : CHAR        (* Character for double-width mode *);
   Kbd_Ch              : CHAR        (* Character read from keyboard    *);
   Done                : BOOLEAN     (* TRUE to stop PIBTERM            *);
   B                   : BOOLEAN     (* General purpose flag            *);
   Graph_Ch            : BYTE        (* Graphics character              *);
   Itab                : BYTE        (* Tab stop                        *);
   Tabcol              : BYTE        (* Tab column                      *);
   Print_Line          : AnyStr      (* Line to print if print mode on  *);
   Local_Save          : Saved_Screen_Ptr;
   Reset_Attr          : BOOLEAN;
   SVal                : STRING[10];
   Do_Graphics_Mode    : BOOLEAN;
   ClrScr_Request      : BOOLEAN;
   VT100_G0_Set        : CHAR;
   VT100_G1_Set        : CHAR;
   VT100_G0_State      : BOOLEAN;
   Save_Dos_Con        : BOOLEAN;
   Save_Do_Status      : BOOLEAN;
   Save_Double         : BOOLEAN;

VAR                                  (* Special output characters *)

   Special_Comm  : ARRAY[0..255] OF BOOLEAN;

                                     (* VT100 tabs stops                *)
VAR
   Number_VT100_Tabs : INTEGER;

   VT100_Tabs:  Tab_Stop_Vector;

(*----------------------------------------------------------------------*)
(*      Ansi_Check_Line_Attributes --- Checks attributes for a line     *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Check_Line_Attributes( Y: INTEGER );

BEGIN (* Ansi_Check_Line_Attributes *)

   CASE Line_Attributes[ Y ] OF
      3,
      4,
      6: Double_Width_Mode := Allow_Doubling;
      ELSE
         Double_Width_Mode := OFF;
   END (* CASE *);

END   (* Ansi_Check_Line_Attributes *);

(*----------------------------------------------------------------------*)
(*       Ansi_Scroll_Attributes --- Scrolls attributes for lines        *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Scroll_Attributes( Y1, Y2, Lines : INTEGER );

VAR
   I : INTEGER;
   N : INTEGER;

BEGIN (* Ansi_Scroll_Attributes *)

   IF ( Lines = 0 ) THEN           (* Zero out line attributes *)
      FOR I := Y1 TO Y2 DO
         Line_Attributes[ I ] := 0

   ELSE IF ( Lines > 0 ) THEN      (* Scroll up the attr. array *)
      BEGIN

         N := MAX( 0 , MIN( Lines , SUCC( Y2 - Y1 ) ) );

         MOVE( Line_Attributes[ Y2 ], Line_Attributes[ Y1 ], N );

         FOR I := PRED( Y1 + N ) TO Bottom_Scroll DO
            Line_Attributes[ I ] := 0;

      END

   ELSE                            (* Scroll down the attr. array *)
      BEGIN

         N := MAX( 0 , MIN( ABS( Lines ) , SUCC( Y2 - Y1 ) ) );

         MOVE( Line_Attributes[ Y1 ], Line_Attributes[ Y2 ], N );

         FOR I := Y1 TO PRED( Y2 ) DO
            Line_Attributes[ I ] := 0;

      END;
                                   (* Ensure last column hit is set FALSE *)
   Last_Column_Hit := FALSE;

END   (* Ansi_Scroll_Attributes *);

(*----------------------------------------------------------------------*)
(*           Ansi_WhereX --- What LOGICAL column is cursor in           *)
(*----------------------------------------------------------------------*)

FUNCTION Ansi_WhereX : INTEGER;

VAR
   X : INTEGER;

BEGIN (* Ansi_WhereX *)

   X := WhereX;

   IF Double_Width_Mode THEN
      X := SUCC( X ) SHR 1;

   Ansi_WhereX := X;

END   (* Ansi_WhereX *);

(*----------------------------------------------------------------------*)
(*            Set_Cursor --- Set cursor to specified screen location    *)
(*----------------------------------------------------------------------*)

PROCEDURE Set_Cursor( X , Y : INTEGER );

VAR
   XX : INTEGER;

BEGIN (* Set_Cursor *)

   Ansi_Check_Line_Attributes( Y );

   IF Double_Width_Mode THEN
      BEGIN
         XX := PRED( X * 2 );
         IF ( XX > Wrap_Screen_Col ) THEN
            CASE ODD( Wrap_Screen_Col ) OF
               TRUE : XX := Wrap_Screen_Col;
               FALSE: XX := PRED( Wrap_Screen_Col );
            END (* CASE *);
         GoToXY( XX , Y );
      END
   ELSE
      GoToXY( X , Y );

END   (* Set_Cursor *);

(*----------------------------------------------------------------------*)
(*             Ansi_Set_Graphics --- Set graphics display               *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Set_Graphics;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Set_Graphics                                     *)
(*                                                                      *)
(*     Purpose:   Sets graphics rendition modes for ANSI/VT100          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Set_Graphics;                                            *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Set_Global_Colors                                             *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                 Ansi_Process_Escape                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I     : INTEGER;
   J     : INTEGER;

BEGIN (* Ansi_Set_Graphics *)

   IF ( Escape_Number = 0 ) THEN
      BEGIN
         Escape_Number      := 1;
         Escape_Register[1] := 0;
      END;

   FOR I := 1 TO Escape_Number DO
      BEGIN

         CASE Escape_Register[I] OF

            0 : BEGIN
                   IF VT100_Allowed THEN
                      BEGIN
                         FG    := VT100_ForeGround_Color;
                         BG    := VT100_BackGround_Color;
                      END
                   ELSE
                      BEGIN
                         FG    := LightGray;
                         BG    := Black;
                         Set_Border_Color( Black );
                      END;
                   Bolding_On  := FALSE;
                   Blinking_On := FALSE;
                END;

            1 : BEGIN
                   IF VT100_Allowed THEN
                      FG          := Ansi_Bold_Color
                   ELSE
                      FG          := Bold_Colors[ FG ];
                   Bolding_On  := TRUE;
                END;

            4 : BEGIN
                                   (* NOTE: In mono mode BLUE will    *)
                                   (* correctly produce an underline. *)

                   FG := Ansi_Underline_Color;

                   IF Bolding_On THEN
                      FG := Bold_Colors[ FG ];

                END;

            5 : Blinking_On := TRUE;

            7 : BEGIN
                   IF VT100_Allowed THEN
                      BEGIN
                         FG := Ansi_BackGround_Color;
                         IF Bolding_On THEN
                            BG := Ansi_Bold_Color
                         ELSE
                            BG := Ansi_ForeGround_Color;
                      END
                   ELSE
                      BEGIN
                         FG := Black;
                         BG := LightGray;
                      END;
                END;

            8 : FG := BG;

        30..37: IF ( Text_Mode = C80 ) THEN
                   BEGIN
                      IF Bolding_On THEN
                         FG := Bold_Colors_2[ Escape_Register[I] - 30 ]
                      ELSE
                         FG := Normal_Colors_2[ Escape_Register[I] - 30 ];
                   END;

        40..47: IF ( Text_Mode = C80 ) THEN
                   BEGIN
                      IF Bolding_On THEN
                         BG := Bold_Colors_2[ Escape_Register[I] - 40 ]
                      ELSE
                         BG := Normal_Colors_2[ Escape_Register[I] - 40 ];
                   END;

         END (* CASE *);

      END;
                                   (* Change the colors *)
   IF Blinking_On THEN
      FG := FG + Blink;

   Set_Global_Colors( FG , BG );

END   (* Ansi_Set_Graphics *);

(*----------------------------------------------------------------------*)
(*             Ansi_Set_Cursor --- Set cursor position                  *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Set_Cursor;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Set_Cursor                                       *)
(*                                                                      *)
(*     Purpose:   Sets cursor position                                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Set_Cursor;                                              *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Max                                                           *)
(*        Min                                                           *)
(*        UpperLeft                                                     *)
(*        Set_Cursor                                                    *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                 Ansi_Process_Escape                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Row    : INTEGER;
   Col    : INTEGER;
   RowNow : INTEGER;

BEGIN (* Ansi_Set_Cursor *)
                                   (* Get current row position *)
   RowNow := WhereY;
                                   (* Determine new row and column *)
   CASE Escape_Number OF
                                   (* Home cursor if no coords given *)
      0 : BEGIN
             Row := 1;
             Col := 1;
          END;
                                   (* Column 1 is default, row provided *)
      1 : BEGIN
             Col := 1;
             Row := Escape_Register[1];
          END;
                                   (* Both row and column provided *)
      ELSE
             Col := Escape_Register[2];
             Row := Escape_Register[1];

   END;
                                   (* Handle origin mode    *)
   IF Origin_Mode THEN
      Row := Row + PRED( Top_Scroll );

                                   (* Clip to screen size   *)

   Row := MAX( MIN( Row , Ansi_Last_Line  ) , 1 );
   Col := MAX( MIN( Col , Wrap_Screen_Col ) , 1 );

                                   (* If we moved down 1 line,  *)
                                   (* update the review buffer. *)
   IF ( Row <> RowNow ) THEN
      BEGIN
         Last_Column_Hit := FALSE;
         IF Review_On THEN
            IF ( ORD( Review_Line[0] ) > 0 ) THEN
               Update_Review_Pointers;
      END;
                                   (* Treat as if line written to *)
                                   (* capture file.               *)
   IF Capture_On THEN
      Capture_Char( CHR( LF ) );

                                   (* Move to new coordinates *)
   Set_Cursor( Col , Row );

END   (* Ansi_Set_Cursor *);

(*----------------------------------------------------------------------*)
(*             Ansi_Clear_Screen --- Clear segment of screen            *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Clear_Screen;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Clear_Screen                                     *)
(*                                                                      *)
(*     Purpose:   Clears portion of screen                              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Clear_Screen;                                            *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                 Ansi_Process_Escape                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I:        INTEGER;
   X:        INTEGER;
   Y:        INTEGER;
   C:        INTEGER;
   Blank_Line : AnyStr;
   ATT:      INTEGER;

BEGIN (* Ansi_Clear_Screen *)
                                   (* Update the review buffer. *)
   IF Review_On THEN
      IF ( ORD( Review_Line[0] ) > 0 ) THEN
         Update_Review_Pointers;
                                   (* Update capture file *)
   IF Capture_On THEN
      Capture_Char( CHR( LF ) );
                                   (* Get type of clear to perform *)
   IF ( Escape_Number = 1 )  THEN
      C := Escape_Register[1]
   ELSE
      C := 0;

   Save_FG1 := FG;
   Save_BG1 := BG;

   IF VT100_Allowed THEN
      Set_Global_Colors( Ansi_ForeGround_Color , Ansi_BackGround_Color );

   X     := WhereX;
   Y     := WhereY;

   CASE C OF
                                   (* Clear from cursor position to *)
                                   (* end of screen                 *)
      0:  BEGIN

             ClrEol;

             FOR I := ( Y + 1 ) TO Ansi_Last_Line DO
                BEGIN
                   GoToXY( 1 , I );
                   ClrEol;
                   Line_Attributes[I] := 0;
                END;

             GoToXY( X , Y );

          END;
                                   (* Clear start of screen to current *)
                                   (* cursor position                  *)
      1:  BEGIN

             IF ( Y > 1 ) THEN
                Scroll( 1, Y - 1, 1, Max_Screen_Col, 0, FG, BG );

             GoToXY( 1 , Y );

             FOR I := 1 TO X DO
                WRITE(' ');

             FOR I := 1 TO Y DO
                Line_Attributes[I] := 0;

          END;
                                   (* Clear entire screen *)
      2:  BEGIN

             Scroll( 1, Ansi_Last_Line, 1, Max_Screen_Col, 0, FG, BG );
{
             Blank_Line := DUPL( ' ' , Max_Screen_Col );
             ATT        := ( ( BG AND 7 ) SHL 4 ) OR FG;
             FOR I := 1 TO Ansi_Last_Line DO
                WriteSXY( Blank_Line, 1, I, ATT );
}
             FillChar( Line_Attributes, Max_Screen_Line, 0 );

             IF VT100_Allowed THEN
                GoToXY( X , Y )
             ELSE
                GoToXY( 1 , 1 );

          END;

   END (* CASE *);

   Set_Global_Colors( Save_FG1 , Save_BG1 );

END   (* Ansi_Clear_Screen *);

(*----------------------------------------------------------------------*)
(*             Ansi_Clear_Line --- Clear part of line in display        *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Clear_Line;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Clear_Line                                       *)
(*                                                                      *)
(*     Purpose:   Clears portion of current line                        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Clear_Line;                                              *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                 Ansi_Process_Escape                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I:        INTEGER;
   X:        INTEGER;
   Y:        INTEGER;
   C:        INTEGER;

BEGIN (* Ansi_Clear_Line *)

   IF ( Escape_Number = 1 )  THEN
      C := Escape_Register[1]
   ELSE
      C := 0;

   Save_FG1 := FG;
   Save_BG1 := BG;

   IF VT100_Allowed THEN
      Set_Global_Colors( Ansi_ForeGround_Color , Ansi_BackGround_Color );

                                   (* Remember current position *)
   X := WhereX;
   Y := WhereY;

   CASE C OF
                                   (* Clear cursor to end *)
      0:  ClrEol;
                                   (* Clear start to cursor *)
      1:  BEGIN
             GoToXY( 1 , Y );
             FOR I := 1 TO X DO
                WRITE(' ');
          END;
                                   (* Clear entire line *)
      2:  BEGIN
             GoToXY( 1 , Y );
             ClrEol;
             GoToXY( X , Y );
             Line_Attributes[Y] := 0;
          END;

   END  (* CASE *);

   Set_Global_Colors( Save_FG1 , Save_BG1 );

END   (* Ansi_Clear_Line *);

(*----------------------------------------------------------------------*)
(*          Ansi_Write_Escape --- Write out escape sequence to display  *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Write_Escape;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Write_Escape                                     *)
(*                                                                      *)
(*     Purpose:   Writes unused escape sequence chars to display        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Write_Escape;                                            *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                 Ansi_Process_Escape                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I: INTEGER;

BEGIN (* Ansi_Write_Escape *)

   FOR I := 1 TO LENGTH( Escape_Str ) DO
      Display_Character( Escape_Str[I] );

   Escape_Type    := ' ';

END   (* Ansi_Write_Escape *);

(*----------------------------------------------------------------------*)
(*            Ansi_Next_Char --- Get next character in escape sequence  *)
(*----------------------------------------------------------------------*)

FUNCTION Ansi_Next_Char : CHAR;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function: Ansi_Next_Char                                         *)
(*                                                                      *)
(*     Purpose:  Waits for next character in escape sequence            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Next_Char;                                               *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                 Ansi_Process_Escape                                  *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine actually shouldn't be used, but I got lazy.      *)
(*        Needs to be fixed next time around.                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Next_Ch: INTEGER;

BEGIN (* Ansi_Next_Char *)

   Async_Receive_With_Timeout( 5 , Next_Ch );

   IF Next_Ch > 0 THEN
      Ansi_Next_Char := CHR( Next_Ch )
   ELSE
      Ansi_Next_Char := CHR( 0 );

END   (* Ansi_Next_Char *);

(*----------------------------------------------------------------------*)
(*      Ansi_Set_Scrolling_Region --- Set scrolling region (window)     *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Set_Scrolling_Region;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Set_Scrolling_Region                             *)
(*                                                                      *)
(*     Purpose:   Sets scrolling region (window)                        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Set_Scrolling_Region;                                    *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                 Ansi_Process_Escape                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Top:    INTEGER;
   Bottom: INTEGER;

BEGIN (* Ansi_Set_Scrolling_Region *)

   CASE Escape_Number OF
                                   (* Window is entire screen *)
      0:  BEGIN
             Top    := 1;
             Bottom := Ansi_Last_Line;
          END;
                                   (* From specified line to end of screen *)
      1:  BEGIN
             Top    := MAX( Escape_Register[1] , 1 );
             Bottom := Ansi_Last_Line;
          END;
                                   (* Both top and bottom specified *)
      2:  BEGIN
             Top    := MAX( Escape_Register[1] , 1  );
             Bottom := MIN( Escape_Register[2] , Ansi_Last_Line );
          END;

      ELSE
             Top    := MAX( Escape_Register[1] , 1  );
             Bottom := MIN( Escape_Register[2] , Ansi_Last_Line );

   END (* CASE *);

   IF Bottom < Top THEN Bottom := Ansi_Last_Line;
   IF Bottom = 0   THEN Bottom := Ansi_Last_Line;

   IF Origin_Mode THEN
      PibTerm_Window( 1, Top, Max_Screen_Col, Bottom );

   GoToXY( 1 , 1 );

   Top_Scroll    := Top;
   Bottom_Scroll := Bottom;

   IF Origin_Mode THEN
      PibTerm_Window( 1, 1, Max_Screen_Col, Ansi_Last_Line );

END   (* Ansi_Set_Scrolling_Region *);

(*----------------------------------------------------------------------*)
(*                    Ansi_Cursor_Up --- Move cursor up                 *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Cursor_Up;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Cursor_Up;                                       *)
(*                                                                      *)
(*     Purpose:   Moves cursor up specified number of lines             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Cursor_Up;                                               *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Y    : INTEGER;
   X    : INTEGER;
   Regs : Registers;

BEGIN (* Ansi_Cursor_Up *)
                                   (* Get current position.  If not in *)
                                   (* scrolling region, we do nothing. *)
   Regs.Ah            := 3;
   Regs.Bh            := 0;
   INTR( $10 , Regs );

   X := SUCC( Regs.Dl );
   Y := SUCC( Regs.Dh );
{
   IF ( ( Y > Bottom_Scroll ) OR ( Y <= Top_Scroll ) ) THEN
      EXIT;
}
   IF ( Y < Top_Scroll ) THEN
      EXIT;
                                   (* Get # of lines to move up *)
   IF Escape_Number = 0 THEN
      Reg_Val := 1
   ELSE
      Reg_Val := MAX( 1 , Escape_Register[1] );

   Set_Cursor( X , MAX( Y - Reg_Val , Top_Scroll ) );

   IF ( WhereY <> Y ) THEN
      Last_Column_Hit := FALSE;

END   (* Ansi_Cursor_Up *);

(*----------------------------------------------------------------------*)
(*                 Ansi_Cursor_Down --- Move cursor down                *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Cursor_Down;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Cursor_Down;                                     *)
(*                                                                      *)
(*     Purpose:   Moves cursor down specified number of lines           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Cursor_Down;                                             *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Y    : INTEGER;
   X    : INTEGER;
   Regs : Registers;

BEGIN (* Ansi_Cursor_Down *)
                                   (* Get current position.  If not in *)
                                   (* scrolling region, we do nothing. *)
   Regs.Ah            := 3;
   Regs.Bh            := 0;
   INTR( $10 , Regs );

   X := SUCC( Regs.Dl );
   Y := SUCC( Regs.Dh );
{
   IF ( ( Y >= Bottom_Scroll ) OR ( Y < Top_Scroll ) ) THEN
}
   IF ( Y >= Bottom_Scroll ) THEN
      EXIT;
                                   (* Get # of lines to move down *)
   IF Escape_Number = 0 THEN
      Reg_Val := 1
   ELSE
      Reg_Val := MAX( 1 , Escape_Register[1] );

   Set_Cursor( X, MIN( Y + Reg_Val , Bottom_Scroll ) );

   IF ( WhereY <> Y ) THEN
      Last_Column_Hit := FALSE;

END   (* Ansi_Cursor_Down *);

(*----------------------------------------------------------------------*)
(*                  Ansi_Cursor_Left --- Move cursor left               *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Cursor_Left;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Cursor_Left;                                     *)
(*                                                                      *)
(*     Purpose:   Moves cursor left specified number of columns         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Cursor_Left;                                             *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Ansi_Cursor_Left *)

   IF Escape_Number = 0 THEN
      Reg_Val := 1
   ELSE
      Reg_Val := MAX( 1 , Escape_Register[1] );

   Set_Cursor( MAX( Ansi_WhereX - Reg_Val , 1 ), WhereY );

END   (* Ansi_Cursor_Left *);

(*----------------------------------------------------------------------*)
(*                 Ansi_Cursor_Right --- Move cursor right              *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Cursor_Right;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Cursor_Right;                                    *)
(*                                                                      *)
(*     Purpose:   Moves cursor right specified number of columns        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Cursor_Right;                                            *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Ansi_Cursor_Right *)

   IF Escape_Number = 0 THEN
      Reg_Val := 1
   ELSE
      Reg_Val := MAX( 1 , Escape_Register[1] );

   Set_Cursor( MIN( Ansi_WhereX + Reg_Val , Wrap_Screen_Col ), WhereY );

END   (* Ansi_Cursor_Right *);

(*----------------------------------------------------------------------*)
(*              Ansi_Status_Report --- Provide terminal status          *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Status_Report;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Status_Report;                                   *)
(*                                                                      *)
(*     Purpose:   Provides status reports to host enquiries             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Status_Report;                                           *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Istatus  : INTEGER;
   C_Column : STRING[10];
   C_Row    : STRING[10];

BEGIN (* Ansi_Status_Report *)

   IF Escape_Number = 0 THEN
      Istatus := 5
   ELSE
      Istatus := Escape_Register[ 1 ];

   CASE Istatus OF

      5:    Async_Send_String( CHR( 27 ) + '[0n' );

      6:    BEGIN
               STR( Ansi_WhereX, C_Column );
               STR( WhereY, C_Row    );
               Async_Send_String( CHR( 27 ) + '[' +
                                  C_Row + ';' + C_Column + 'R' );
            END;

      ELSE;

   END   (* CASE *);

END   (* Ansi_Status_Report *);

(*----------------------------------------------------------------------*)
(*              Ansi_Swap_Colors --- Swap foreground/background colors  *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Swap_Colors;

VAR
   K: INTEGER;

BEGIN (* Ansi_Swap_Colors *)

   K                     := Ansi_ForeGround_Color;
   Ansi_ForeGround_Color := Ansi_BackGround_Color;
   Ansi_BackGround_Color := K;

   K                := ForeGround_Color;
   ForeGround_Color := BackGround_Color;
   BackGround_Color := K;

   K  := FG;
   FG := BG;
   BG := K;

   Set_Global_Colors( ForeGround_Color , BackGround_Color );
   Set_Border_Color ( BackGround_Color );

   Status_Line_Attr := 16 * ( ForeGround_Color AND 7 ) +
                       BackGround_Color;

END   (* Ansi_Swap_Colors *);

(*----------------------------------------------------------------------*)
(*              Ansi_Set_Mode --- Set a terminal mode                   *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Set_Mode( Mode_Type : CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Set_Mode;                                        *)
(*                                                                      *)
(*     Purpose:   Set a terminal mode                                   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Set_Mode( Mode_Type : CHAR );                            *)
(*                                                                      *)
(*           Mode_Type --- ' ' or '?' depending upon type of            *)
(*                         parameter to set.                            *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I    : INTEGER;
   Regs : Registers;

BEGIN (* Ansi_Set_Mode *)

   IF ( Mode_Type = '?' ) THEN
      FOR I := 1 TO Escape_Number DO

         CASE Escape_Register[I] OF

            1:    IF Auto_Change_Arrows THEN
                     IF ( LENGTH( KeyPad_Appl_On_File ) > 0 ) THEN
                        Set_Input_Keys( KeyPad_Appl_On_File , FALSE );

            3:    BEGIN
                     IF ATI_Ega_Wonder THEN
                        BEGIN
                           IF Do_Xon_Xoff_Checks THEN
                              BEGIN
                                 Async_Send_Now( CHR( XOFF ) );
                                 IF Async_Wait_For_Quiet( 150 , 25 ) THEN;
                              END;
                           Regs.AX := $23;
                           INTR( $10, Regs );
                           Set_Border_Color( BG );
                           IF Do_Xon_Xoff_Checks THEN
                              Async_Send_Now( CHR( XON ) );
                           Max_Screen_Col  := 132;
                           Max_Screen_Line := 25;
                           PibTerm_Window( 1, 1, Max_Screen_Col, Ansi_Last_Line );
                           IF Do_Status_Line THEN
                              BEGIN
                                 Set_Status_Line_Name(Short_Terminal_Name);
                                 Write_To_Status_Line( Status_Line_Name, 1 );
                              END;
                           Last_Column_Hit := FALSE;
                        END;
                     Width_132          := TRUE;
                     Wrap_Screen_Col    := MIN( Max_Screen_Col , 132 );
                     Escape_Number      := 1;
                     Escape_Register[1] := 2;
                     Ansi_Clear_Screen;
                     GoToXY( 1 , 1 );
                     EXIT;
                  END;

            5:    IF ( NOT Reverse_On ) THEN
                     BEGIN
                        Ansi_Swap_Colors;
                        Set_Text_Attributes( 1, 1, Max_Screen_Col,
                                             Max_Screen_Line - 1,
                                             Ansi_Foreground_Color,
                                             Ansi_BackGround_Color );
                        Reverse_On := TRUE;
                        IF Do_Status_Line THEN
                           Write_To_Status_Line( Status_Line_Name, 1 );
                     END;

            6:    BEGIN
                     Origin_Mode := ON;
                     PibTerm_Window( 1, Top_Scroll, Max_Screen_Col, Bottom_Scroll );
                     GoToXY( 1 , 1 );
                     PibTerm_Window( 1, 1, Max_Screen_Col, Ansi_Last_Line );
                  END;

            7:    Auto_Wrap_Mode := ON;

            12:   Local_Echo     := ON;

            ELSE;

         END   (* CASE *)
   ELSE
      FOR I := 1 TO Escape_Number DO

         CASE Escape_Register[I] OF

             2:   (* Keyboard_Locked := ON *);
             4:   Insertion_Mode := ON;
            20:   New_Line       := ON;
            ELSE;

         END   (* CASE *);

END   (* Ansi_Set_Mode *);

(*----------------------------------------------------------------------*)
(*            Ansi_Reset_Mode --- Reset a terminal mode                 *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Reset_Mode( Mode_Type : CHAR; VAR Done: BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Reset_Mode;                                      *)
(*                                                                      *)
(*     Purpose:   Resets a terminal mode                                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Reset_Mode( Mode_Type : CHAR; VAR Done : BOOLEAN );      *)
(*                                                                      *)
(*           Mode_Type --- ' ' or '?' depending upon type of            *)
(*                         parameter to set.                            *)
(*           Done      --- TRUE if switch to VT52 done.                 *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I : INTEGER;
   B : BOOLEAN;
   Ch: CHAR;
   Regs : Registers;

BEGIN (* Ansi_Reset_Mode *)

   IF ( Mode_Type = '?' ) THEN
      FOR I := 1 TO Escape_Number DO

         CASE Escape_Register[I] OF

            1:    IF Auto_Change_Arrows THEN
                     IF ( LENGTH( KeyPad_Appl_Off_File ) > 0 ) THEN
                        Set_Input_Keys( KeyPad_Appl_Off_File , FALSE );

                                   (* We cheat here in order to avoid        *)
                                   (* an unnecessary switch in the case      *)
                                   (* of ESC [?2l being followed immediately *)
                                   (* by ESC < -- i.e., return to ANSI mode. *)
            2:    BEGIN
                     DELAY( Tenth_Of_A_Second_Delay );
                     IF ( Async_Peek( 0 ) = CHR( ESC ) ) AND
                        ( Async_Peek( 1 ) = '<'        ) THEN
                        BEGIN
                           Graphics_Mode := FALSE;
                           B             := Async_Receive( Ch );
                           B             := Async_Receive( Ch );
                        END
                     ELSE
                        BEGIN
                           Terminal_To_Emulate := VT52;
                           Done                := TRUE;
                        END;
                  END;

            3:    BEGIN
                     IF ( ATI_Ega_Wonder AND Width_132 ) THEN
                        BEGIN
                           IF Do_Xon_Xoff_Checks THEN
                              BEGIN
                                 Async_Send_Now( CHR( XOFF ) );
                                 IF Async_Wait_For_Quiet( 150 , 25 ) THEN;
                              END;
                           Max_Screen_Col  := 80;
                           Max_Screen_Line := 25;
                           Regs.AX         := $03;
                           INTR( $10, Regs );
                           Set_Border_Color( BG );
                           IF Do_Xon_Xoff_Checks THEN
                              Async_Send_Now( CHR( XON ) );
                           IF Do_Status_Line THEN
                              BEGIN
                                 Set_Status_Line_Name(Short_Terminal_Name);
                                 Write_To_Status_Line( Status_Line_Name, 1 );
                              END;
                           Last_Column_Hit := FALSE;
                           PibTerm_Window( 1, 1, Max_Screen_Col, Ansi_Last_Line );
                           GoToXY( 1 , 1 );
                        END;
                     Width_132          := FALSE;
                     Wrap_Screen_Col    := MIN( Max_Screen_Col , 80 );
                     Escape_Number      := 1;
                     Escape_Register[1] := 2;
                     Ansi_Clear_Screen;
                     GoToXY( 1 , 1 );
                     EXIT;
                  END;

            5:    IF Reverse_On THEN
                     BEGIN
                        Ansi_Swap_Colors;
                        Set_Text_Attributes( 1, 1, Max_Screen_Col,
                                             Max_Screen_Line - 1,
                                             Ansi_Foreground_Color,
                                             Ansi_BackGround_Color );
                        Reverse_On := FALSE;
                        IF Do_Status_Line THEN
                           Write_To_Status_Line( Status_Line_Name, 1 );
                     END;

            6:    BEGIN
                     Origin_Mode := OFF;
                     PibTerm_Window( 1, 1, Max_Screen_Col, Ansi_Last_Line );
                     GoToXY( 1 , 1 );
                  END;

            7:    Auto_Wrap_Mode := OFF;

            12:   Local_Echo     := OFF;

            ELSE;

         END   (* CASE *)
   ELSE
      FOR I := 1 TO Escape_Number DO

         CASE Escape_Register[I] OF

             2:   (* Keyboard_Locked := OFF *);
             4:   Insertion_Mode := OFF;
            20:   New_Line       := OFF;
            ELSE;

         END   (* CASE *);

END   (* Ansi_Reset_Mode *);

(*----------------------------------------------------------------------*)
(*         Ansi_Printer_Control --- Sets printer control modes          *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Printer_Control( Mode_Type : CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Printer_Control;                                 *)
(*                                                                      *)
(*     Purpose:   Sets printer control modes                            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Printer_Control;                                         *)
(*                                                                      *)
(*           Mode_Type --- ' ' or '?' depending upon type of            *)
(*                         parameter to set.                            *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   SaveM     : INTEGER;
   Text_Line : AnyStr;

BEGIN (* Ansi_Printer_Control *)

   IF ( Escape_Number = 0 ) THEN
      Escape_Register[1] := 0;

   CASE Mode_Type OF

      ' ': CASE Escape_Register[1] OF
              0: BEGIN (* Print screen *)
                    SaveM           := Max_Screen_Line;
                    Max_Screen_Line := Ansi_Last_Line;
                    Print_Screen;
                    Max_Screen_Line := SaveM;
                 END   (* Print screen *);
              4: Printer_Ctrl_Mode := OFF;
              5: Printer_Ctrl_Mode := ON;
           END (* CASE *);

      '?': CASE Escape_Register[1] OF
              1: BEGIN (* Print current line *)
                    Get_Screen_Text_Line( Text_Line,
                                          WhereY + Upper_Left_Row - 1, 1 );
                    Write_Prt_Str( Text_Line );
                    Write_Prt_Str( CRLF_String );
                 END   (* Print current line *);
              4: Auto_Print_Mode := OFF;
              5: Auto_Print_Mode := ON;
           END (* CASE *);

   END (* CASE *);

END   (* Ansi_Printer_Control *);

(*----------------------------------------------------------------------*)
(*            VT100_Set_Tab --- Sets a tab stop in VT100 mode           *)
(*----------------------------------------------------------------------*)

PROCEDURE VT100_Set_Tab;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: VT100_Set_Tab;                                        *)
(*                                                                      *)
(*     Purpose:   Sets tab stop in VT100 mode                           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        VT100_Set_Tab;                                                *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   ITab   : INTEGER;
   JTab   : INTEGER;
   TabCol : INTEGER;
   KTab   : INTEGER;

BEGIN (* VT100_Set_Tab *)

   TabCol := WhereX;
   ITab   := 0;

   IF ( Number_VT100_Tabs = 0 ) THEN
      BEGIN
         Number_VT100_Tabs  := 1;
         VT100_Tabs[1]      := TabCol;
         VT100_Tabs[2]      := Wrap_Screen_Col;
      END
   ELSE
      BEGIN

         REPEAT
            INC( ITab );
         UNTIL ( ITab >= Number_VT100_Tabs  ) OR
               ( VT100_Tabs[ITab] >= TabCol );

         IF ( VT100_Tabs[ITab] <> TabCol ) THEN
            BEGIN

               IF ( VT100_Tabs[ITab] < TabCol ) THEN
                  KTab := SUCC( ITab )
               ELSE
                  KTab := ITab;

               FOR JTab := Number_VT100_Tabs DOWNTO KTab DO
                  VT100_Tabs[JTab + 1] := VT100_Tabs[JTab];

               INC( Number_VT100_Tabs );

               VT100_Tabs[KTab]  := TabCol;

            END;

      END;

END   (* VT100_Set_Tab *);

(*----------------------------------------------------------------------*)
(*        VT100_Clear_Tabs --- Clears tab stops in VT100 mode           *)
(*----------------------------------------------------------------------*)

PROCEDURE VT100_Clear_Tabs;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: VT100_Clear_Tabs;                                     *)
(*                                                                      *)
(*     Purpose:   Clears one or all tab stops in VT100 mode             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        VT100_Clear_Tabs;                                             *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   ITab   : INTEGER;
   JTab   : INTEGER;
   TabCol : INTEGER;

BEGIN (* VT100_Clear_Tabs *)

   IF ( Number_VT100_Tabs > 0 ) THEN
      IF ( Escape_Register[1] = 3 ) THEN
         BEGIN
            Number_VT100_Tabs := 0;
            VT100_Tabs[1]     := Wrap_Screen_Col;
         END
      ELSE IF ( Escape_Register[1] = 0 ) THEN
         BEGIN

            TabCol := WhereX;
            ITab   := 0;

            REPEAT
               INC( ITab );
            UNTIL ( ITab >= Number_VT100_Tabs ) OR
                  ( VT100_Tabs[ITab] >= TabCol );

            IF ( VT100_Tabs[ITab] = TabCol ) THEN
               BEGIN
                  FOR JTab := ITab TO Number_VT100_Tabs DO
                     VT100_Tabs[JTab] := VT100_Tabs[SUCC( JTab )];
                  DEC( Number_VT100_Tabs );
               END;

         END;

END   (* VT100_Clear_Tabs *);

