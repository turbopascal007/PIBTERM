(*----------------------------------------------------------------------*)
(*        Review_Captured_Text --- display internal capture buffer      *)
(*----------------------------------------------------------------------*)

PROCEDURE Review_Captured_Text;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Review_Captured_Text                                 *)
(*                                                                      *)
(*     Purpose:    Displays contents of internal capture buffer of      *)
(*                 last Max_Review_Length lines received from           *)
(*                 communications port                                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Review_Captured_Text;                                         *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Save_Screen                                                   *)
(*        Restore_Screen                                                *)
(*        Update_Lines_Displayed                                        *)
(*        Reset_Global_Colors                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   MaxLines = 1500                 (* Maximum lines in capture buffer *);

TYPE
   IntStr   = STRING[6];

VAR
   I           : INTEGER;
   J           : INTEGER;
   L           : INTEGER;
   Ch          : CHAR;
   Quit        : BOOLEAN;
   Bot_Line    : INTEGER;
   Top_Line    : INTEGER;
   Review_Len  : INTEGER;
   Redraw      : BOOLEAN;
   Left_Col    : INTEGER;
   Right_Col   : INTEGER;
   F_Name      : AnyStr;
   F           : Text_File;
   Attrib      : INTEGER;
   Search_Str  : AnyStr;
   Search_Text : AnyStr;
   Line_Ptrs   : ARRAY[1..MaxLines] OF INTEGER;
   Line_Lens   : ARRAY[1..MaxLines] OF INTEGER;
   NLines      : INTEGER;
   Page_Len    : INTEGER;

(*----------------------------------------------------------------------*)
(*    Update_Lines_Displayed -- tell which lines currently displayed    *)
(*----------------------------------------------------------------------*)

PROCEDURE Update_Lines_Displayed;

VAR
   S: AnyStr;

BEGIN (* Update_Lines_Displayed *)

   S := ITOS( Top_Line ) + ' --> ' + ITOS( Bot_Line );
   S := S + DUPL( ' ' , 11 - LENGTH( S ) );

   WriteSXY( S, 69, Page_Len + 3, Attrib );

   S := ITOS( Left_Col ) + ' --> ' + ITOS( Right_Col );
   S := S + DUPL( ' ' , 11 - LENGTH( S ) );

   WriteSXY( S, 69, Page_Len + 4, Attrib );

END   (* Update_Lines_Displayed *);

(*----------------------------------------------------------------------*)
(*       Display_A_Line --- Display selected line in review buffer      *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_A_Line( LineNo: INTEGER );

VAR
   L:  INTEGER;
   I:  INTEGER;
   Y:  INTEGER;
   S:  AnyStr;
   J:  INTEGER;
   K:  INTEGER;
   Ch: CHAR;

BEGIN (* Display_A_Line *)

   I := Line_Ptrs[LineNo];
   L := MIN( Max_Screen_Col , SUCC( Line_Lens[LineNo] - Left_Col ) );
   Y := WhereY;

   FillChar( S[1], Max_Screen_Col, ' ' );

   IF ( L > 0 ) THEN
      BEGIN

         I := PRED( I + Left_Col );
         K := 0;
         J := 0;

         REPEAT

            Ch   := Review_Buffer^[I];

            INC( K );

            IF ( I = Max_Review_Length ) THEN
               I := 1
            ELSE
               INC( I );

            CASE ORD( Ch ) OF
               BS   : J := MAX( 0 , PRED( J ) );
               CR   : J := 0;
               HT   : J := J + ( 8 - WhereX MOD 8 );
               ELSE
                      INC( J );
                      S[J] := Ch;
            END (* CASE *);

         UNTIL ( J >= Max_Screen_Col ) OR ( K >= L );

      END;

   S[0] := CHR( Max_Screen_Col );

   WriteSXY( S, 1, Y, Attrib );

END   (* Display_A_Line *);

(*----------------------------------------------------------------------*)
(*          Search_Lines --- Search for text in review buffer           *)
(*----------------------------------------------------------------------*)

PROCEDURE Search_Lines;

VAR
   Local_Save_5 : Saved_Screen_Ptr;
   I            : INTEGER;
   J            : INTEGER;
   K            : INTEGER;
   L            : INTEGER;
   Found        : BOOLEAN;
   S            : AnyStr;

BEGIN (* Search_Lines *)

   CursorOn;

   Draw_Titled_Box( Local_Save_5, 10, 10, 65, 14, 'Search for text' );

   GoToXY( 1 , 1 );

   WRITE('String to search for? ');

   Read_Edited_String( Search_Text );
   WRITELN;

   IF LENGTH( Search_Text ) > 0 THEN
      Search_Str := UpperCase( Search_Text );

   IF LENGTH( Search_Str ) <= 0 THEN
      BEGIN
         Restore_Screen( Local_Save_5 );
         EXIT;
      END;

   Found := FALSE;
   I     := SUCC( Top_Line );
   K     := 0;

   REPEAT

      L := Line_Ptrs[I];

      FOR J := 1 TO Line_Lens[I] DO
         BEGIN
            S[J] := Review_Buffer^[L];
            IF ( L = Max_Review_Length ) THEN
               L := 1
            ELSE
               INC( L );
         END;

      S[0] := CHR( Line_Lens[I] );

      IF ( POS( Search_Str , UpperCase( S ) ) > 0 ) THEN
         BEGIN
            Found    := TRUE;
            Top_Line := I;
            Bot_Line := MIN( Top_Line + 19 , Review_Len );
            ReDraw   := TRUE;
         END;

      INC( I );
      IF( I > Review_Len ) THEN
         I := 1;

      INC( K );

   UNTIL ( FOUND OR ( K > Review_Len ) );

   IF ( NOT Found ) THEN
      BEGIN
         WRITE('String not found.');
         Window_Delay;
      END;

   Restore_Screen_And_Colors( Local_Save_5 );

   TextColor( Menu_Text_Color );

   CursorOff;

END   (* Search_Lines *);

(*----------------------------------------------------------------------*)
(*          Write_Out_Lines --- Write review buffer to text file        *)
(*----------------------------------------------------------------------*)

PROCEDURE Write_Out_Lines;

VAR
   I           : INTEGER;
   J           : INTEGER;
   K           : INTEGER;
   Local_Save  : Saved_Screen_Ptr;
   OK_File     : BOOLEAN;
   Open_OK     : BOOLEAN;
   File_Exists : BOOLEAN;
   S           : AnyStr;

BEGIN (* Write_Out_Lines *)

   CursorOn;

   Draw_Titled_Box( Local_Save, 10, 10, 70, 16,
                    'Write review buffer to file' );

   OK_File     := FALSE;
   F_Name       := '';

   REPEAT

      Clear_Window;

      WRITELN('File name to write review buffer to: ');
      WRITE('>');

      Read_Edited_String( F_Name );
      WRITELN;

      ASSIGN( F , F_Name );
         (*!I-*)
      RESET( F );
         (*!I+*)

      IF Int24Result = 0 THEN
         BEGIN

            OK_File := YesNo('File ' + F_Name +
                            ' already exists, append to it (Y/N) ? ');

            File_Exists := TRUE;

               (*!I-*)
            CLOSE( F );
               (*!I+*)

         END
      ELSE
         OK_File := TRUE;

   UNTIL ( OK_File ) OR ( LENGTH( F_Name ) = 0 );

   IF LENGTH( F_Name ) > 0 THEN
      BEGIN
            (*!I-*)
         IF File_Exists THEN
            Open_OK := Open_For_Append( F , F_Name , I )
         ELSE
            BEGIN
                  (*!I-*)
                ASSIGN ( F , F_Name );
                REWRITE( F );
                  (*!I+*)
                Open_OK := ( Int24Result = 0 );
            END;

         IF ( NOT Open_OK ) THEN
            BEGIN
               WRITELN('Can''t open ',F_Name,' for output.');
               WRITELN('Review buffer will not be written.');
            END
         ELSE
            BEGIN

               WRITELN('Writing review buffer to ', F_Name );

               FOR I := 1 TO Review_Len DO
                  BEGIN
                     K := Line_Ptrs[I];
                     FOR J := 1 TO Line_Lens[I] DO
                        BEGIN
                           S[J] := Review_Buffer^[K];
                           IF ( K = Max_Review_Length ) THEN
                              K := 1
                           ELSE
                              INC( K );
                        END;
                     S[0] := CHR( Line_Lens[I] );
                     WRITELN( F , S );
                  END;

                  (*!I-*)
               CLOSE( F );
                  (*!I+*)

            END;

      END (* Length( F_Name ) > 0 *);

   Restore_Screen_And_Colors( Local_Save );

   TextColor( Menu_Text_Color );

   CursorOff;

END   (* Write_Out_Lines *);

(*----------------------------------------------------------------------*)

PROCEDURE Get_Line_Offsets( VAR Review_Len : INTEGER );

VAR
   I     : LONGINT;
   IStart: LONGINT;
   L     : LONGINT;
   Done  : BOOLEAN;
   Head_1: LONGINT;

BEGIN (* Get_Line_Offsets *)

   Review_Len   := 1;
   Line_Ptrs[1] := Review_Tail;
   I            := Review_Tail;

   IF ( Head_1 = Max_Review_Length ) THEN
      Head_1 := 1
   ELSE
      Head_1 := SUCC( Review_Head );

   Done := FALSE;

   REPEAT

      IStart := PRED( I );
      IF ( IStart < 1 ) THEN
         IStart := IStart + PRED( Max_Review_Length );

      WHILE ( ( Review_Buffer^[I] <> CHR( CR )  ) AND
              ( I <> IStart                     )     ) DO
         BEGIN
            IF ( I = Max_Review_Length ) THEN
               I := 1
            ELSE
               INC( I );
         END;

      L  := I - Line_Ptrs[Review_Len];
      IF ( L < 0 ) THEN
         L := L + PRED( Max_Review_Length );

      Line_Lens[Review_Len] := L;

      INC( Review_Len );

      INC( I , 2 );

      IF ( I > Max_Review_Length ) THEN
         I := I - Max_Review_Length;

      Line_Ptrs[Review_Len] := I;
      Done                  := Done OR ( I = Head_1 );

   UNTIL Done;

   DEC( Review_Len );

END   (* Get_Line_Offsets *);

(*----------------------------------------------------------------------*)

BEGIN (* Review_Captured_Text *)
                                   (*  No status line time check    *)

   Save_Do_Status_Time := Do_Status_Time;
   Do_Status_Time      := FALSE;
                                   (* Turn off cursor               *)
   CursorOff;

                                   (*  Save current screen contents *)
   Save_Screen( Saved_Screen );

   PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line );

                                   (*  Clear screen                 *)

   Scroll( 1, Max_Screen_Line, 1, Max_Screen_Col, 0,
           Global_ForeGround_Color, Global_BackGround_Color );

                                   (*  Draw split-screen bar        *)
   TextColor( Menu_Text_Color_2 );

   Page_Len := Max_Screen_Line - 5;

   GoToXY( 1 , Page_Len + 2 );

   FOR I := 1 TO 29 DO
      WRITE('=');

   TextColor( Menu_Text_Color );

   WRITE(' Review Captured Text ');

   TextColor( Menu_Text_Color_2 );

   FOR I := 1 TO 29 DO
      WRITE('=');
                                   (* Display instructions *)
   GoToXY( 1 , Page_Len + 3 );

   WRITE('Esc');
   TextColor( Menu_Text_Color );
   WRITE('  to quit                ');
   TextColor( Menu_Text_Color_2 );
   WRITE( ^Z, '/', ^[, '  ');
   TextColor( Menu_Text_Color );
   WRITE('to go left/right ');
   GoToXY( 53 , Page_Len + 3 );
   TextColor( Menu_Text_Color_2 );
   WRITELN('Current lines:   ');

   WRITE('PgUp/PgDn');
   TextColor( Menu_Text_Color );
   WRITE('  to page          ');
   TextColor( Menu_Text_Color_2 );
   WRITE('/  ');
   TextColor( Menu_Text_Color );
   WRITE('to scroll');
   GoToXY( 53 , Page_Len + 4 );
   TextColor( Menu_Text_Color_2 );
   WRITELN('Current columns: ');

   TextColor( Menu_Text_Color_2 );
   WRITE('Home/End');
   TextColor( Menu_Text_Color );
   WRITE('  first/last screen ');
   TextColor( Menu_Text_Color_2 );
   WRITE('S');
   TextColor( Menu_Text_Color );
   WRITE('  search for text');
   GoToXY( 53 , Page_Len + 5 );
   TextColor( Menu_Text_Color_2  );
   WRITE('W  ');
   TextColor( Menu_Text_Color );
   WRITE('Write lines to file');

   TextColor( Menu_Text_Color );

   PibTerm_Window( 1, 1, Max_Screen_Col, SUCC( Page_Len ) );

                                   (* Not done yet                  *)
   Quit     := FALSE;
                                   (* Text color for display        *)
   TextColor( Menu_Text_Color );
   Attrib   := BackGround_Color SHL 4 + Menu_Text_Color;

                                   (* Start columns 1 through 80    *)
   Left_Col  := 1;
   Right_Col := Max_Screen_Col;
                                   (* No current search string      *)
   Search_Text := '';
                                   (* Get line offsets in buffer    *)
   Get_Line_Offsets( Review_Len );
                                   (* Last line                     *)
   Bot_Line := Review_Len;
   Top_Line := MAX( SUCC( Bot_Line - Page_Len ) , 1 );
   Redraw   := TRUE;
                                   (* List buffer contents          *)
   REPEAT
                                   (* Display current page          *)

      Bot_Line := MIN( PRED( Top_Line + Page_Len ) , Review_Len );
      L        := 0;

      IF Redraw THEN
         BEGIN

            FOR I := Top_Line TO Bot_Line DO
               BEGIN
                  INC( L );
                  GoToXY( 1 , L );
                  Display_A_Line( I );
               END;

            FOR I := SUCC( L ) TO Page_Len DO
               BEGIN
                  GoToXY( 1 , I );
                  ClrEol;
               END;

         END;
                                   (* Assume no need to redraw screen *)
      Redraw := FALSE;
                                   (* Indicate which lines displayed  *)
      Update_Lines_Displayed;
                                   (* Read command                  *)
      Read_Kbd_Old( Ch );

      IF ( ORD( Ch ) = ESC ) AND ( NOT PibTerm_KeyPressed ) THEN
         Quit := TRUE
      ELSE
         BEGIN

            IF ( ORD( Ch ) = ESC ) THEN
               Read_Kbd_Old( Ch );

            CASE ORD( Ch ) OF

               L_Arrow:  BEGIN (* Left arrow -- move 10 cols to left *)
                            Left_Col  := MAX( Left_Col - 10 , 1 );
                            Right_Col := MIN( Left_Col + PRED( Max_Screen_Col ) ,
                                              Max_Review_Line_Length );
                            ReDraw    := TRUE;
                         END;

               R_Arrow:  BEGIN (* Right arrow -- move 10 cols to right *)
                            Left_Col  := MIN( Left_Col + 10 ,
                                              Max_Review_Line_Length );
                            Right_Col := MIN( Left_Col + PRED( Max_Screen_Col ) ,
                                              Max_Review_Line_Length );
                            ReDraw    := TRUE;
                         END;

               U_Arrow:  BEGIN (* Up Arrow -- scroll up one line *)

                            IF Top_Line > 1 THEN
                               BEGIN

                                   (* Make room for new line *)

                                  GoToXY( 1 , 1 );
                                  Scroll( 1, Page_Len,
                                          1, Max_Screen_Col, -1,
                                          Menu_Text_Color,
                                          BackGround_Color );

                                  DEC( Top_Line );
                                  DEC( Bot_Line );

                                  Display_A_Line( Top_Line );

                               END;

                         END   (* Up Arrow *);

               D_Arrow:  BEGIN (* Down Arrow -- scroll down one line *)

                            IF Bot_Line < Review_Len THEN
                               BEGIN

                                   (* Make room for new line *)

                                  GoToXY( 1 , 1 );
                                  Scroll( 1, Page_Len,
                                          1, Max_Screen_Col, 1,
                                          Menu_Text_Color,
                                          BackGround_Color );

                                  INC( Top_Line );
                                  INC( Bot_Line );

                                  GoToXY( 1 , SUCC( Bot_Line - Top_Line ) );
                                  Display_A_Line( Bot_Line );

                               END;

                         END   (* Down Arrow *);

               PgUp:     BEGIN (* PgUp -- move up one page *)

                            IF ( Top_Line > 1 ) THEN
                               BEGIN
                                  Redraw := TRUE;
                                  Top_Line := MAX( Top_Line - Page_Len , 1 );
                               END;

                         END   (* PgUp *);

               PgDn:     BEGIN (* PgDn -- move down one page *)

                            IF ( SUCC( Bot_Line ) < Review_Len ) THEN
                               BEGIN
                                  Redraw := TRUE;
                                  Top_Line := SUCC( Bot_Line );
                               END;

                         END   (* PgDn *);

               Home:     BEGIN (* Home -- move to top of buffer *)

                            Top_Line := 1;
                            Redraw   := TRUE;

                         END   (* Home *);

               End_Key:  BEGIN (* End -- move to end of buffer *)
                            Bot_Line := Review_Len;
                            Top_Line := MAX( SUCC( Bot_Line - Page_Len ) , 1 );
                            Redraw   := TRUE;
                         END   (* End *);

               (* W, w *)
               87, 119 : Write_Out_Lines;

               (* S, s *)
               83, 115 : Search_Lines;

               ELSE                (* Sound bell for bad input *)

                         Menu_Beep;

            END (* CASE *);

         END;

   UNTIL Quit;

   CursorOn;

   Restore_Screen_And_Colors( Saved_Screen );

   Do_Status_Time := Save_Do_Status_Time;

END   (* Review_Captured_Text *);
