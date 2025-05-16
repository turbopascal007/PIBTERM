(*----------------------------------------------------------------------*)
(*     Do_Display_Action  ---  interpret display escape sequence        *)
(*----------------------------------------------------------------------*)

FUNCTION Do_Display_Action( Ch : CHAR; VAR Done : BOOLEAN ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Function: Do_Display_Action                                        *)
(*                                                                      *)
(*   Purpose:  Interprets and executes display escape sequence          *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      B := Do_Display_Action( Ch : CHAR ) : BOOLEAN;                  *)
(*                                                                      *)
(*         Ch   --- Character to act upon                               *)
(*         B    --- TRUE if display action completed                    *)
(*                                                                      *)
(*   Calls:  Scroll                                                     *)
(*           Get_Async_Integer                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   X    : INTEGER;
   Y    : INTEGER;
   B    : BOOLEAN;
   I    : INTEGER;
   C    : INTEGER;
   D_Ch : CHAR;
   TT   : Transfer_Type;

BEGIN (* Do_Display_Action *)

   X := WhereX;
   Y := WhereY;
   B := TRUE;

   IF ( Ch = CHR( 0 ) ) THEN

   ELSE IF ( Ch = ^[ ) THEN
      BEGIN
         Escape_Mode := TRUE;
         B           := FALSE;
      END

   ELSE IF ( ( ORD( Ch ) < 32 ) OR Escape_Mode ) THEN
      BEGIN

         CASE Display_Action_Ptr[Display_Action_State]^[ Ch ] OF

                                   (* Display character as is *)

          DisplayChar:   BEGIN
                            D_Ch := Character_Set_Ptr^[Ch];
                            IF Use_Dos_Con_Output THEN
                               Display_Character_Through_DOS( D_Ch )
                            ELSE
                               Display_Character( D_Ch );
                         END;
                                   (* Move cursor up one line *)

          CursorUp:      IF ( Y > 1 ) THEN
                            GoToXY( X , PRED( Y ) );

                                   (* Move cursor down one line *)

          CursorDown:    IF ( Y < Ansi_Last_Line ) THEN
                            GoToXY( X , SUCC( Y ) );

                                   (* Move cursor left one column *)

          CursorLeft:    IF ( X > 1 ) THEN
                            GoToXY( PRED( X ) , Y );

                                   (* Move cursor right one column *)

          CursorRight:   IF ( X < Max_Screen_Col ) THEN
                            GoToXY( SUCC( X ) , Y );

                                   (* Clear screen *)
          ClearScr:     BEGIN
                           Scroll( 1, Ansi_Last_Line, 1, Max_Screen_Col, 0,
                                   ForeGround_Color, BackGround_Color );
                           FillChar( Line_Attributes, 100, 0 );
                           GoToXY( X , Y );
                        END;

                                   (* VT52 tabs *)

          VT52HT:       Handle_Tab( Tab_Stops , Number_Tab_Stops );

                                   (* VT52 line feeds *)

          VT52LF:       Do_VT52_LineFeeds( Ch );

          DoCISBESCI:   CISB_Term_ESC_I;

          DoCISBDLE:    CISB_DLE_Seen;

          DoCISBENQ:    CISB_Term_ENQ;

          DoKermitReceive : IF ( NOT Handle_Kermit_Autodownload ) THEN
                               BEGIN
                                  D_Ch := Character_Set_Ptr^[Ch];
                                  IF Use_Dos_Con_Output THEN
                                     Display_Character_Through_DOS( D_Ch )
                                  ELSE
                                     Display_Character( D_Ch );
                               END;

          DoZmodemReceive : IF ( NOT Handle_Zmodem_Autodownload ) THEN
                               BEGIN
                                  D_Ch := Character_Set_Ptr^[Ch];
                                  IF Use_Dos_Con_Output THEN
                                     Display_Character_Through_DOS( D_Ch )
                                  ELSE
                                     Display_Character( D_Ch );
                               END;

          EnterState1:  Display_Action_State := 1;

          EnterState2:  Display_Action_State := 2;

          EnterState3:  Display_Action_State := 3;

          EnterState4:  Display_Action_State := 4;

          EnterState5:  Display_Action_State := 5;

                                   (* Clear screen and home cursor *)
          ClearScrH:     BEGIN
                            Scroll( 1, Ansi_Last_Line, 1, Max_Screen_Col, 0,
                                    ForeGround_Color, BackGround_Color );
                            FillChar( Line_Attributes, 100, 0 );
                            GoToXY( 1 , 1 );
                         END;

                                   (* Clear cursor to end of screen *)
          ClearEOS:      BEGIN

                            ClrEol;

                            FOR I := SUCC( Y ) TO Ansi_Last_Line DO
                               BEGIN
                                  GoToXY( 1 , I );
                                  ClrEol;
                                  Line_Attributes[I] := 0;
                               END;

                            GoToXY( X , Y );

                         END;

                                   (* Clear start of screen to current *)
                                   (* cursor position                  *)
          ClearSCur:     BEGIN

                            IF ( Y > 1 ) THEN
                               Scroll( 1, PRED( Y ), 1, Max_Screen_Col, 0,
                                       ForeGround_Color, BackGround_Color );

                            GoToXY( 1 , Y );

                            FOR I := 1 TO X DO
                               WRITE(' ');

                            FOR I := 1 TO Y DO
                               Line_Attributes[I] := 0;

                         END;

                                   (* Clear entire line *)
          ClearLine:     BEGIN
                            GoToXY( 1 , Y );
                            ClrEol;
                            GoToXY( X , Y );
                            Line_Attributes[Y] := 0;
                         END;

                                   (* Clear cursor to end of line *)
          ClearEOL:      ClrEol;

                                   (* Clear start of line to cursor *)
          ClearLCur:     BEGIN
                            GoToXY( 1 , Y );
                            FOR I := 1 TO X DO
                               WRITE(' ');
                         END;

                                   (* Move cursor to top left hand corner *)

          CursorHome:    GoToXY( 1 , 1 );

                                   (* Reverse index *)
          ReverseIndex:  BEGIN
                            IF ( Y > 1 ) THEN
                               GoToXY( X , PRED( Y ) )
                            ELSE
                               Scroll( 1, PRED( Max_Screen_Line ), 1,
                                       Max_Screen_Col,
                                       -1,
                                       ForeGround_Color, BackGround_Color );
                         END;

                                   (* Index *)

          Index:         Display_Character( ^J );

          TV950Video:    BEGIN
                            Async_Receive_With_TimeOut( 5 , C );
                            IF ( C <> TimeOut ) THEN
                               CASE CHR( C ) OF
                                  '0': ;
                                  '2': ;
                                  '4': ;
                                  '8': ;
                               END (* CASE *);
                         END;

          StartGraphicsMode : BEGIN
                                 Graphics_Mode     := TRUE;
                                 Character_Set_Ptr := Display_Char_Set_Ptr[2];
                              END;

          EndGraphicsMode   : BEGIN
                                 Graphics_Mode     := FALSE;
                                 Character_Set_Ptr := Display_Char_Set_Ptr[1];
                              END;

          IdentifyVT52   : Async_Send_String( ^[ + '/Z' );


          PrintPage:       Print_Screen;

                                   (* Toggle reverse video *)
          ReverseVideo:    BEGIN
                              I                := ForeGround_Color;
                              ForeGround_Color := BackGround_Color;
                              BackGround_Color := I;
                              Global_Text_Attribute := 16 * ( BackGround_Color AND 7 ) + ForeGround_Color;
                              TextColor( ForeGround_Color );
                              TextBackGround( BackGround_Color );
                           END;

          StartDim     :   LowVideo;

          EndDim       :   HighVideo;

                                   (* Move to screen position in VT52 format *)
          CursorPosVT52:   BEGIN

                              OldX   := NewX;
                              OldY   := NewY;

                              Get_Async_Integer( NewY );
                              Get_Async_Integer( NewX );

                              NewY := MAX( 1 , MIN( NewY , PRED( Max_Screen_Line ) ) );
                              NewX := MAX( 1 , MIN( NewX , Max_Screen_Col ) );

                              GoToXY( NewX, NewY );

                           END;

          StartAltKey:     Alt_Keypad_Mode := ON;

          EndAltKey  :     Alt_Keypad_Mode := OFF;

          StartAutoPrint:  Auto_Print_Mode := ON;

          EndAutoPrint:    Auto_Print_Mode := OFF;


          StartPrintControl: Printer_Ctrl_Mode := ON;

          EndPrintControl  : Printer_Ctrl_Mode := OFF;

          StartVT52HoldScreen: Hold_Screen_Mode := ON;

          EndVT52HoldScreen  : Hold_Screen_Mode := OFF;

          EnterVT100:      BEGIN                (* Enter VT100 mode  *)

                              Terminal_To_Emulate := VT100;
                              Done                := TRUE;

                           END;

                                        (* Indicate AutoDownload possible *)

          SendMahoneyOn : IF Mahoney_On THEN Async_Send_String( 'EXECPC2' );

          ExecPCCommands: IF Mahoney_On THEN Exec_PC_Commands;
{
          InsertCharA:
          InsertCharB:
          InsertLineA:
          InsertLineB:
          DeleteChar:
          DeleteLine:
          StartInsert:
          EndInsert:
          NormalVideo:
          StartBlink:
          EndBlink:
          StartUnderline:
          EndUnderline:
          StartBold:
          EndBold:
          PrintLine:
          SetTab:
          ClearTab:
          Swallow:
          CursorPosH:
          CursorPosV:
          EnterVT52:
          NotDone       : B := FALSE;

          EndCase       : ;
}
          ELSE            B := FALSE;

         END (* CASE *)

      END
   ELSE
      BEGIN
         D_Ch := Character_Set_Ptr^[Ch];
         IF Use_Dos_Con_Output THEN
            Display_Character_Through_DOS( D_Ch )
         ELSE
            Display_Character( D_Ch );
      END;

   IF B THEN
      BEGIN
         Do_Display_Action := TRUE;
         Escape_Mode       := FALSE;
      END
   ELSE
      Do_Display_Action := FALSE;

END   (* Do_Display_Action *);

