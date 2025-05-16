(*----------------------------------------------------------------------*)
(*        VT100_Fix_Line_Width -- Switch from single/double width       *)
(*----------------------------------------------------------------------*)

PROCEDURE VT100_Fix_Line_Width( Y : INTEGER; New_Attr : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: VT100_Fix_Line_Width;                                 *)
(*                                                                      *)
(*     Purpose:   Switches line contents from between single/double wid *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        VT100_Fix_Line_Width( Y : INTEGER; New_Attr : INTEGER );      *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Old_Attr    : BYTE;
   X           : INTEGER;
   I           : INTEGER;
   K           : INTEGER;
   MaxC        : INTEGER;
   C           : CHAR;
   Attr        : BYTE;
   Screen_Chars: ARRAY[1..132] OF CHAR;
   Screen_Attrs: ARRAY[1..132] OF BYTE;

                                   (* Flags if attribute is double *)
                                   (* width type.                  *)
(* STRUCTURED *) CONST
   Double_Type : ARRAY[0..6] OF BOOLEAN =
                 ( FALSE, FALSE, FALSE, TRUE, TRUE, FALSE, TRUE );

BEGIN (* VT100_Fix_Line_Width *)
                                   (* Get current column *)
   X        := Ansi_WhereX;
                                   (* Get current line attribute *)

   Old_Attr := Line_Attributes[ Y ];

                                   (* Store new attribute type *)

   Line_Attributes[ Y ] := New_Attr;

                                   (* See if width change needed and *)
                                   (* do it if so.                   *)

   IF ( Double_Type[ Old_Attr ] <> Double_Type[ New_Attr ] ) THEN
      BEGIN
                                   (* Figure out if we're compressing *)
                                   (* or expanding this line.         *)

         MaxC  := Wrap_Screen_Col SHR 1;

         IF ( New_Attr = 0 ) THEN
            BEGIN  (* Compression *)
               FOR I := 1 TO MaxC DO
                  BEGIN
                     ReadCXY ( C, PRED( I SHL 1 ) , Y, Attr );
                     WriteCXY( C, I,                Y, Attr );
                  END;
               FOR I := SUCC( MaxC ) TO Max_Screen_Col DO
                  WriteCXY( ' ', I, Y, Global_Text_Attribute );
               Double_Width_Mode := OFF;
            END
         ELSE
            BEGIN  (* Expansion *)

               FOR I := 1 TO MaxC DO
                  ReadCXY( Screen_Chars[ I ] , I, Y, Screen_Attrs[ I ] );

               K := 1;

               FOR I := 1 TO MaxC DO
                  BEGIN

                     C := Screen_Chars[ I ];

                     WriteCXY( C, K, Y, Screen_Attrs[ I ] );

                     IF ( C = CHR(196) ) OR
                        ( C = CHR(192) ) OR
                        ( C = CHR(218) ) THEN
                        C := CHR( 196 )
                     ELSE
                        C := ' ';

                     WriteCXY( C, SUCC( K ), Y, Screen_Attrs[ I ] );

                     INC( K , 2 );

                  END;

               Double_Width_Mode := ON;

            END;

         Set_Cursor( X , Y );

      END;

END   (* VT100_Fix_Line_Width *);

(*----------------------------------------------------------------------*)
(*        Ansi_Insert_Lines --- Insert empty lines in display           *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Insert_Lines;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Insert_Lines;                                    *)
(*                                                                      *)
(*     Purpose:   Inserts empty lines in display                        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Insert_Lines;                                            *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   L: INTEGER;
   Y: INTEGER;

BEGIN (* Ansi_Insert_Lines *)

   Y := WhereY;

   IF ( ( Y >= Top_Scroll ) AND ( Y <= Bottom_Scroll ) ) THEN
      BEGIN

         IF ( Escape_Number = 0 ) THEN
            L := 1
         ELSE
            L := MAX( 1 , Escape_Register[1] );

         IF ( ( Y + L - 1 ) > Bottom_Scroll ) THEN
            L := ( Bottom_Scroll - Y + 1 );

         IF ( L > 0 ) THEN
            BEGIN
               Scroll( Y, Bottom_Scroll, 1, Max_Screen_Col, -L, FG, BG );
               Ansi_Scroll_Attributes( Y , Bottom_Scroll, -L );
            END;

      END;

END   (* Ansi_Insert_Lines *);

(*----------------------------------------------------------------------*)
(*        Ansi_Delete_Lines --- Delete empty lines in display           *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Delete_Lines;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Delete_Lines;                                    *)
(*                                                                      *)
(*     Purpose:   Deletes lines in display                              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Delete_Lines;                                            *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   L: INTEGER;
   Y: INTEGER;

BEGIN (* Ansi_Delete_Lines *)
{==
   PibTerm_Window( 1, 1, Max_Screen_Col, Ansi_Last_Line );
==}
   Y := WhereY;

   IF ( ( Y >= Top_Scroll ) AND ( Y <= Bottom_Scroll ) ) THEN
      BEGIN

         IF ( Escape_Number = 0 ) THEN
            L := 1
         ELSE
            L := MAX( Escape_Register[1] , 1 );

         IF ( ( Y + L - 1 ) > Bottom_Scroll ) THEN
            L := ( Bottom_Scroll - Y + 1 );

         IF ( L > 0 ) THEN
            BEGIN
               Scroll( Y, Bottom_Scroll, 1, Max_Screen_Col, L, FG, BG );
               Ansi_Scroll_Attributes( Y , Bottom_Scroll , L );
            END;

      END;
{==
   IF Origin_Mode THEN
      PibTerm_Window( 1, Top_Scroll, Max_Screen_Col, Bottom_Scroll );
==}
END   (* Ansi_Delete_Lines *);

(*----------------------------------------------------------------------*)
(*        Ansi_Delete_Chars --- Delete characters in display            *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Delete_Chars;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Delete_Chars;                                    *)
(*                                                                      *)
(*     Purpose:   Deletes characters in display                         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Delete_Chars;                                            *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   L    : INTEGER;
   I    : INTEGER;
   C1   : INTEGER;
   C2   : INTEGER;
   Y    : INTEGER;
   Ch   : CHAR;
   Co   : BYTE;

BEGIN (* Ansi_Delete_Chars *)

   IF ( Escape_Number = 0 ) THEN
      L := 1
   ELSE
      L := MAX( Escape_Register[1] , 1 );

                                   (* Need to move twice as many in *)
                                   (* double width mode.            *)
   IF Double_Width_Mode THEN
      L := L * 2;
                                   (* Get current horizontal position *)
   C1 := WhereX;
                                   (* Get end of deletion area *)

   C2 := MIN( C1 + L , Wrap_Screen_Col );

                                   (* Get current line *)

   Y  := WhereY + PRED( Upper_Left_Row );

                                   (* Move characters to left *)

   FOR I := C2 TO Wrap_Screen_Col DO
      BEGIN
         ReadCXY ( Ch, I, Y, Co );
         WriteCXY( Ch, C1, Y, Co );
         INC( C1 );
      END;
                                   (* Blank out rest of line *)

   IF ( C1 <= Wrap_Screen_Col ) THEN
       BEGIN


          FOR I := C1 TO Wrap_Screen_Col DO
             WriteCXY( ' ', I, Y, Global_Text_Attribute );

       END;
                                   (* Move back to proper column position *)
   GoToXY( C1 , WhereY );

END   (* Ansi_Delete_Chars *);

(*----------------------------------------------------------------------*)
(*        Ansi_Insert_Chars --- Insert empty lines in display           *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Insert_Chars;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Insert_Chars;                                    *)
(*                                                                      *)
(*     Purpose:   Inserts characters in display                         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Insert_Chars;                                            *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I                   : INTEGER;
   L                   : INTEGER;
   Save_Insertion_Mode : BOOLEAN;
   XPos                : INTEGER;

BEGIN (* Ansi_Insert_Chars *)

   IF ( Escape_Number = 0 ) THEN
      L := 1
   ELSE
      L := Escape_Register[1];

   IF Double_Width_Mode THEN
      L := L * 2;

   Save_Insertion_Mode := Insertion_Mode;
   Insertion_Mode      := TRUE;
   XPos                := WhereX;

   FOR I := 1 TO L DO
      Display_Character( ' ' );

   Insertion_Mode      := Save_Insertion_Mode;

   GoToXY( XPos , WhereY );

END   (* Ansi_Insert_Chars *);

(*----------------------------------------------------------------------*)
(*     VT100_Send_Terminal_Parameters --- Send VT100 terminal params    *)
(*----------------------------------------------------------------------*)

PROCEDURE VT100_Send_Terminal_Parameters;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: VT100_Send_Terminal_Parameters                        *)
(*                                                                      *)
(*     Purpose:   Sends VT100 terminal parameters                       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        VT100_Send_Terminal_Parameters;                               *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   PString : AnyStr;
   BString : STRING[5];

BEGIN (* VT100_Send_Terminal_Parameters *)

   PString := CHR( ESC ) + '[';

   IF ( Escape_Register[1] = 1 ) THEN
      PString := PString + '3;'
   ELSE
      PString := PString + '2;';

   CASE Parity OF
      'E' : PString := PString + '5;';
      'O' : PString := PString + '4;';
      ELSE  PString := PString + '1;';
   END (* CASE *);

   CASE Data_Bits OF
      7    : PString := PString + '2;';
      ELSE   PString := PString + '1;';
   END (* CASE *);

   CASE Baud_Rate OF
      300  : BString := '48';
      600  : BString := '56';
      1200 : BString := '64';
      2400 : BString := '88';
      4800 : BString := '104';
      9600 : BString := '112';
      19200: BString := '120';
      ELSE   BString := '0';
   END (* CASE *);

   PString := PString + BString + ';' + BString + ';' + '1;0x';

   Async_Send_String( PString );

END   (* VT100_Send_Terminal_Parameters *);

(*----------------------------------------------------------------------*)
(*     VT100_Set_LEDs --- Set LED flags for VT100                       *)
(*----------------------------------------------------------------------*)

PROCEDURE VT100_Set_LEDs;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: VT100_Set_LEDs;                                       *)
(*                                                                      *)
(*     Purpose:   Sets VT100 LED flags                                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        VT100_Set_LEDs;                                               *)
(*                                                                      *)
(*     Called by:  VT100_Process_Escape                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Led_Number : INTEGER;
   I          : INTEGER;

BEGIN (* VT100_Set_LEDs *)

   IF ( Escape_Number = 0 ) THEN
      BEGIN
         Escape_Number      := 1;
         Escape_Register[1] := 0;
      END;

   FOR I := 1 TO Escape_Number DO
      CASE Escape_Register[I] OF

         0: BEGIN (* Turn off all LEDs *)
               VT100_Led_Vector[1] := FALSE;
               VT100_Led_Vector[2] := FALSE;
               VT100_Led_Vector[3] := FALSE;
               VT100_Led_Vector[4] := FALSE;
            END;

         1: VT100_Led_Vector[1] := TRUE;
         2: VT100_Led_Vector[2] := TRUE;
         3: VT100_Led_Vector[3] := TRUE;
         4: VT100_Led_Vector[4] := TRUE;

         ELSE;

      END (* CASE *);

END   (* VT100_Set_LEDs *);

(*----------------------------------------------------------------------*)
(*            Ansi_Reset_Terminal --- Reset terminal defaults           *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Reset_Terminal;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Reset_Terminal                                   *)
(*                                                                      *)
(*     Purpose:   Resets terminal defaults                              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Reset_Terminal;                                          *)
(*                                                                      *)
(*     Called by:  Emulate_Ansi                                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   ITab : INTEGER;

BEGIN (* Ansi_Reset_Terminal *)
                                   (* Turn on the cursor            *)
   CursorOn;
                                   (* Initialize terminal state     *)
   Done                  := FALSE;
   Alt_Keypad_Mode       := OFF;
   Graphics_Mode         := OFF;
   Auto_Print_Mode       := OFF;
   Origin_Mode           := OFF;
   Auto_Wrap_Mode        := ON;
   Printer_Ctrl_Mode     := OFF;
   Escape_Mode           := FALSE;
   Escape_Str            := '';
   NewX                  := WhereX;
   NewY                  := WhereY;
   Skip_All_Mode         := FALSE;
   Double_Width_Mode     := FALSE;
   New_Line              := New_Line_Param;
   Save_Done             := FALSE;
   Insertion_Mode        := FALSE;
   VT100_G0_Set          := 'A';
   VT100_G1_Set          := 'A';
   VT100_G0_State        := TRUE;
   Wrap_Screen_Col       := 80;
   Current_Status_Time   := -1;

                                   (* Set tabs *)
   Number_VT100_Tabs     := 17;

   FOR ITab := 1 TO 9 DO
      VT100_Tabs[ITab] := SUCC( ITab * 8 );

   FOR ITab := 10 TO 16 DO
      VT100_Tabs[ITab] := 64 + ITab;

   VT100_Tabs[17] := Wrap_Screen_Col;

                                   (* Set colors.                *)

   Ansi_ForeGround_Color := VT100_ForeGround_Color;
   Ansi_BackGround_Color := VT100_BackGround_Color;
   Ansi_Underline_Color  := VT100_Underline_Color;
   Ansi_Bold_Color       := VT100_Bold_Color;

   ForeGround_Color      := VT100_ForeGround_Color;
   BackGround_Color      := VT100_BackGround_Color;
   Border_Color          := VT100_Border_Color;

   FG                    := VT100_ForeGround_Color;
   BG                    := VT100_BackGround_Color;

   Bolding_On            := FALSE;
   Blinking_On           := FALSE;
   Reverse_On            := FALSE;

   Set_Global_Colors( Ansi_ForeGround_Color , Ansi_BackGround_Color );
   Set_Border_Color ( Border_Color );

                                   (* Initialize music playing   *)
   PibPlaySet;
   Getting_Music := FALSE;
                                   (* Set status line attribute *)

   IF Reverse_Status_Colors THEN
      Status_Line_Attr := 16 * ( ForeGround_Color AND 7 ) + BackGround_Color
   ELSE
      Status_Line_Attr := 16 * ( Status_BackGround_Color AND 7 ) + Status_ForeGround_Color;

   Do_Status_Line   := Show_Status_Line;
   Do_Status_Time   := Do_Status_Line AND Show_Status_Time;

   IF VT100_Allowed THEN
      Short_Terminal_Name := 'VT100'
   ELSE
      Short_Terminal_Name := 'ANSI/BBS';

   Ansi_Last_Line := Max_Screen_Line;

   Set_Status_Line_Name( Short_Terminal_Name );

                                   (* Status line to last line *)
   IF Do_Status_Line THEN
      BEGIN
         Ansi_Last_Line := PRED( Max_Screen_Line );
         Write_To_Status_Line( Status_Line_Name, 1 );
      END;
                                   (* Set screen size            *)

   PibTerm_Window( 1, 1, Max_Screen_Col, Ansi_Last_Line );

                                   (* Change text attributes     *)

   Set_Text_Attributes( 1, 1, Max_Screen_Col, Ansi_Last_Line,
                        Ansi_ForeGround_Color,
                        Ansi_BackGround_Color );

                                   (* Initial scrolling region is *)
                                   (* entire usable screen.       *)

   Top_Scroll            := 1;
   Bottom_Scroll         := Ansi_Last_Line;

                                   (* Set line attributes all normal  *)

   FillChar( Line_Attributes, Max_Screen_Line, 0 );

                                   (* Special keyboard and output chars *)
   FOR ITab := 0 TO 255 DO
      Special_Comm [ITab] := FALSE;

   Special_Comm[NUL]  := TRUE;
   Special_Comm[ESC]  := TRUE;
   Special_Comm[LF ]  := TRUE;
   Special_Comm[CR ]  := TRUE;
   Special_Comm[FF ]  := TRUE;
   Special_Comm[VT ]  := TRUE;
   Special_Comm[HT ]  := TRUE;
   Special_Comm[ENQ]  := TRUE;
   Special_Comm[SO ]  := TRUE;
   Special_Comm[SI ]  := TRUE;
   Special_Comm[DEL]  := TRUE;
   Special_Comm[BS ]  := TRUE;
   Special_Comm[CAN]  := TRUE;
   Special_Comm[SUB]  := TRUE;
   Special_Comm[DLE]  := TRUE;
   Special_Comm[ETX]  := TRUE;
   Special_Comm[SOH]  := TRUE;

                                   (* Set time for status line   *)
   Current_Status_Time := -1;
                                   (* Check if script tests req'd *)

   Do_Script_Tests := Waitstring_Mode OR When_Mode OR
                      WaitCount_Mode  OR WaitQuiet_Mode OR
                      Script_Learn_Mode;

                                   (* Set save guys *)

   Save_Col_Position  := PRED( NewX );
   Save_Row_Position  := PRED( NewY );
   Save_FG_Color      := FG;
   Save_BG_Color      := BG;
   Save_Graphics_Mode := Graphics_Mode;
   Save_Bolding       := Bolding_On;
   Save_Blinking      := Blinking_On;
   Save_Origin_Mode   := Origin_Mode;
   Save_Top_Scroll    := Top_Scroll;
   Save_Bottom_Scroll := Bottom_Scroll;

                                   (* No LEDs lit *)
   VT100_Led_Vector[1] := FALSE;
   VT100_Led_Vector[2] := FALSE;
   VT100_Led_Vector[3] := FALSE;
   VT100_Led_Vector[4] := FALSE;

END   (* Ansi_Reset_Terminal *);

(*----------------------------------------------------------------------*)
(*            Ansi_Process_Escape --- Process ANSI escape sequence      *)
(*----------------------------------------------------------------------*)

PROCEDURE Ansi_Process_Escape( Ch : CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Ansi_Process_Escape                                   *)
(*                                                                      *)
(*     Purpose:   Processes escape sequence for BBS/ANSI emulation      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ansi_Process_Escape( Ch: CHAR );                              *)
(*                                                                      *)
(*           Ch --- Next character in escape sequence                   *)
(*                                                                      *)
(*     Called by:  Emulate_Ansi                                         *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This version doesn't process private DEC escape sequences,    *)
(*        but DOES play music.                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Reg_Val     : INTEGER;
   Save_X      : INTEGER;
   Save_Y      : INTEGER;
   More_Escape : BOOLEAN;

BEGIN (* Ansi_Process_Escape *)

   IF Getting_Music THEN
      BEGIN
         IF ( ORD( Escape_Str[0] ) < 255 ) THEN
            Escape_Str := Escape_Str + Ch;
         EXIT;
      END;

   More_Escape := FALSE;

   CASE Ch OF

      ' ' : EXIT;
      ^M  : EXIT;
      ^J  : EXIT;

      '[' : BEGIN
               Escape_Type    := '[';
               EXIT;
            END;

      'A' : IF Escape_Type <> '[' THEN
               More_Escape := TRUE
            ELSE
               Ansi_Cursor_Up;

      'B' : IF Escape_Type <> '[' THEN
               More_Escape := TRUE
            ELSE
               Ansi_Cursor_Down;

      'C' : IF Escape_Type <> '[' THEN
               More_Escape := TRUE
            ELSE
               Ansi_Cursor_Right;

      'D' : IF Escape_Type <> '[' THEN
               More_Escape := TRUE
            ELSE
               Ansi_Cursor_Left;

      'f' : Ansi_Set_Cursor;

      'H' : Ansi_Set_Cursor;

      'I' : IF ( Escape_Type = ' ' ) THEN
               IF CompuServe_B_On THEN
                  CISB_Term_ESC_I;

      'J' : Ansi_Clear_Screen;

      'K' : Ansi_Clear_Line;

      'L' : BEGIN
               Scroll( WhereY, Bottom_Scroll, 1, Max_Screen_Col, -1, FG, BG );
               Ansi_Scroll_Attributes( WhereY, Bottom_Scroll, -1 );
               ClrEol;
            END;

      'M' : BEGIN
               Getting_Music := TRUE;
               More_Escape   := TRUE;
            END;

      'm' : Ansi_Set_Graphics;
                                   (* Indicate EXEC PC AutoDownload possible *)

      ^Q  : IF Mahoney_On THEN Async_Send_String( 'EXECPC2' );

      'O':  IF Mahoney_On THEN Exec_PC_Commands;

      's':  IF Escape_Type = '[' THEN
               BEGIN
                  Save_Row_Position  := WhereX;
                  Save_Col_Position  := WhereY;
                  Save_FG_Color      := FG;
                  Save_BG_Color      := BG;
                  Save_Graphics_Mode := Graphics_Mode;
                  Save_Bolding       := Bolding_On;
                  Save_Blinking      := Blinking_On;
                  Save_Double        := Double_Width_Mode;
               END
            ELSE
               More_Escape := TRUE;

      'u':  IF Escape_Type = '[' THEN
               BEGIN
                  MoveToXY( Save_Row_Position , Save_Col_Position );
                  FG                := Save_FG_Color;
                  BG                := Save_BG_Color;
                  Bolding_On        := Save_Bolding;
                  Blinking_On       := Save_Blinking;
                  Double_Width_Mode := Save_Double;
                  Graphics_Mode     := Save_Graphics_Mode;
                  IF Blinking_On THEN
                     TextColor( FG + Blink )
                  ELSE
                     TextColor( FG );
                  TextBackGround( BG );
               END
            ELSE
               More_Escape := TRUE;

      ELSE  More_Escape := TRUE;

   END  (* CASE *);

   IF ( NOT More_Escape ) THEN
      Escape_Mode := FALSE
   ELSE
      BEGIN

         Ch         := UpCase( Ch );
         Escape_Str := Escape_Str + Ch;

         IF Ch IN Lets THEN EXIT;

         IF Ch IN Digits THEN
            BEGIN
               Escape_Register[Escape_Number] :=
                  ( Escape_Register[Escape_Number] * 10 ) + ORD( Ch ) -
                                                            ORD( '0' );
               EXIT;
            END;

         CASE Ch OF

            ';', ',' : BEGIN
                          INC( Escape_Number );
                          Escape_Register[Escape_Number] := 0;
                       END;

            'T', 'S', '#', '+', '-', '>', '<', '.'
                        : ;
            ELSE
               Escape_Mode := FALSE;
               Ansi_Write_Escape;

         END  (* CASE *);

   END (* NOT More_Escape *);

END   (* Ansi_Process_Escape *);

(*----------------------------------------------------------------------*)
(*        Handle_VT100_Special --- Process special chars in VT100       *)
(*----------------------------------------------------------------------*)

PROCEDURE Handle_VT100_Special( Comm_Ch: CHAR );

VAR
   Save_Y: INTEGER;

(*----------------------------------------------------------------------*)

PROCEDURE Normal_Char;

BEGIN (* Normal_Char *)

   Display_Character( Comm_Ch );
   IF Do_Script_Tests THEN
      Do_Script_Checks( Comm_Ch );

END   (* Normal_Char *);

(*----------------------------------------------------------------------*)

BEGIN (* Handle_VT100_Special *)

   Do_Graphics_Mode := Graphics_Mode;
   Graphics_Mode    := OFF;

   CASE ORD( Comm_Ch ) OF

      ESC:  BEGIN (* ESC found *)

               IF Escape_Mode THEN Ansi_Write_Escape;

               Escape_Str         := '';
               Escape_Number      := 1;
               Escape_Register[1] := 0;
               Escape_Mode        := TRUE;
               Escape_Type        := ' ';
               Getting_Music      := FALSE;

            END;

      LF,
      FF,
      VT:   BEGIN (* go down one line *)

               Save_Y   := WhereY;

               IF Auto_Print_Mode THEN
                  BEGIN
                     Get_Screen_Text_Line( Print_Line, Save_Y, 1 );
                     Write_Prt_Str( Print_Line );
                     Write_Prt_Str( CRLF_String );
                  END;

               IF VT100_Allowed THEN
                  BEGIN
                     Save_FG1 := FG;
                     Save_BG1 := BG;
                     TextColor     ( Ansi_ForeGround_Color );
                     TextBackGround( Ansi_BackGround_Color );
                  END;

               IF ( Save_Y <= Bottom_Scroll  ) THEN
                  BEGIN

                     IF ( Save_Y = Bottom_Scroll ) THEN
                         BEGIN

                            PibTerm_Window( 1, Top_Scroll, Max_Screen_Col,
                                            Bottom_Scroll );

                            Display_Character( Comm_Ch );
{==
                            IF ( NOT Origin_Mode ) THEN
==}
                               PibTerm_Window( 1, 1, Max_Screen_Col, Ansi_Last_Line );

                            MOVE( Line_Attributes[ Top_Scroll + 1 ],
                                  Line_Attributes[ Top_Scroll     ],
                                  Bottom_Scroll - Top_Scroll );

                            Line_Attributes[ Bottom_Scroll ] := 0;
                            ClrEol;

                         END
                      ELSE
                         Display_Character( Comm_Ch );

                      IF Do_Script_Tests THEN
                         Do_Script_Checks( Comm_Ch );

                  END
               ELSE
                  BEGIN

                     IF ( Save_Y < Ansi_Last_Line ) THEN
                        Display_Character( Comm_Ch );

                     IF Capture_On THEN
                        Capture_Char( Comm_Ch );

                     IF Printer_On THEN
                         Write_Prt( Comm_Ch );

                     IF Review_On THEN
                         Update_Review_Pointers;

                     IF Do_Script_Tests THEN
                        Do_Script_Checks( Comm_Ch );

                  END;

               IF VT100_Allowed THEN
                  BEGIN
                     TextColor     ( Save_FG1 );
                     TextBackGround( Save_BG1 );
                  END;

            END   (* go down one line *);

                                   (* Move to specified tab column *)

      HT:   IF VT100_Allowed THEN
               Handle_Tab( VT100_Tabs , Number_VT100_Tabs )
            ELSE
               Normal_Char;

      BS:   BEGIN
               Display_Character( Comm_Ch );
               IF Double_Width_Mode THEN
                  Display_Character( Comm_Ch );
               IF Do_Script_Tests THEN
                  Do_Script_Checks( Comm_Ch );
            END;

      SO:   IF VT100_Allowed THEN
               BEGIN
                  VT100_G0_State   := FALSE;
                  Do_Graphics_Mode := ( VT100_G1_Set = '0' );
               END
            ELSE
               BEGIN
                  IF ( Play_Music_On ) AND ( NOT Silent_Mode ) THEN
                     PibPlay( Escape_Str );
                  Escape_Mode   := FALSE;
                  Escape_Str    := '';
               END;

      SI:   IF VT100_Allowed THEN
               BEGIN
                  VT100_G0_State   := TRUE;
                  Do_Graphics_Mode := ( VT100_G0_Set = '0' );
               END
            ELSE
               Normal_Char;
                                   (* Kermit autodownload request *)

      SOH:  IF Kermit_Autodownload THEN
               IF ( NOT Handle_Kermit_Autodownload ) THEN
                  Normal_Char
               ELSE
            ELSE
               Normal_Char;
                                   (* CompuServe B protocol request *)

      ENQ:  IF CompuServe_B_On THEN
               CISB_Term_ENQ
            ELSE
               IF VT100_Allowed THEN
                  Async_Send_String( VT100_Answerback_Message )
               ELSE
                  Normal_Char;

      ETX:  IF CompuServe_B_On THEN
               CISB_Term_ENQ
            ELSE
               Normal_Char;

      DLE:  IF CompuServe_B_On THEN
               CISB_DLE_Seen
            ELSE
               Normal_Char;
                                   (* Cancel escape sequence in progress *)
                                   (* or Zmodem download.                *)
      CAN:  IF Escape_Mode THEN
               Escape_Mode := FALSE
            ELSE
               IF Zmodem_Autodownload THEN
                  IF ( NOT Handle_Zmodem_Autodownload ) THEN
                     Normal_Char
                  ELSE
               ELSE
                  Normal_Char;

                                   (* Cancel escape sequence in progress *)
      SUB:  IF Escape_Mode THEN
               Escape_Mode := FALSE
            ELSE
               Normal_Char;

      ELSE
            Normal_Char;

   END  (* CASE *);

   Graphics_Mode := Do_Graphics_Mode;

   Ansi_Check_Line_Attributes( WhereY );

END   (* Handle_VT100_Special *);

(*----------------------------------------------------------------------*)
(*         VT100_Process_Escape --- Process VT100 escape sequence       *)
(*----------------------------------------------------------------------*)

PROCEDURE VT100_Process_Escape(     Ch   : CHAR;
                                VAR Done : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: VT100_Process_Escape                                  *)
(*                                                                      *)
(*     Purpose:   Processes escape sequence for DEC VT100 emulation     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        VT100_Process_Escape( Ch: CHAR; VAR Done: BOOLEAN );          *)
(*                                                                      *)
(*           Ch --- Next character in escape sequence                   *)
(*           Done --- Set TRUE to exit ANSI/VT100 mode                  *)
(*                                                                      *)
(*     Called by:  Emulate_Ansi                                         *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This version processes private DEC escape sequences.          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Reg_Val     : INTEGER;
   Save_X      : INTEGER;
   Save_Y      : INTEGER;
   I           : INTEGER;
   J           : INTEGER;
   More_Escape : BOOLEAN;
   S           : AnyStr;
   Regs        : Registers;

(* STRUCTURED *) CONST
   VT100_Char_Sets : SET OF CHAR = ['A','B','0','1','2'];

BEGIN (* VT100_Process_Escape *)

   More_Escape := FALSE;
                                   (* Ignore blanks *)
   IF ( Ch = ' ' ) THEN EXIT;
                                   (* Process char depending upon current *)
                                   (* escape type mode                    *)
   CASE Escape_Type OF

      ' ':  CASE Ch OF

               '#',
               '[',
               'O',
               '?':   BEGIN
                         Escape_Type := Ch;
                         EXIT;
                      END;

               'D':   BEGIN
                         IF ( WhereY < Bottom_Scroll ) THEN
                            BEGIN
                               MoveToXY( WhereX , WhereY + 1 );
                               Last_Column_Hit := FALSE;
                            END
                         ELSE
                            BEGIN
                               Save_X := WhereX;
                               Save_Y := WhereY;
                               Scroll( Top_Scroll, Bottom_Scroll, 1,
                                       Max_Screen_Col, 1, FG, BG );
                               MoveToXY( Save_X, Save_Y );
                               Ansi_Scroll_Attributes( Top_Scroll ,
                                                       Bottom_Scroll , 1 );
                            END;
                      END;

               'E':   BEGIN
                         IF ( WhereY < Bottom_Scroll ) THEN
                            BEGIN
                               MoveToXY( 1 , WhereY + 1 );
                               Last_Column_Hit := FALSE;
                            END
                         ELSE
                            BEGIN
                               Save_Y := WhereY;
                               Scroll( Top_Scroll, Bottom_Scroll, 1,
                                       Max_Screen_Col, 1, FG, BG );
                               MoveToXY( 1 , Save_Y );
                               Ansi_Scroll_Attributes( Top_Scroll ,
                                                       Bottom_Scroll ,
                                                       1 );
                            END;
                      END;

               'M':   BEGIN
{==
                         PibTerm_Window( 1, 1, Max_Screen_Col, Ansi_Last_Line );
==}
                         IF WhereY > Top_Scroll THEN
                            BEGIN
                               MoveToXY( WhereX ,  WhereY - 1 );
                               Last_Column_Hit := FALSE;
                            END
                         ELSE
                            BEGIN

                               Save_X  := WhereX;
                               Save_Y  := WhereY;
                               Save_FG := FG;
                               Save_BG := BG;
                               FG      := Ansi_ForeGround_Color;
                               BG      := Ansi_BackGround_Color;

                               Scroll( Top_Scroll, Bottom_Scroll, 1, Max_Screen_Col,
                                       -1, FG, BG );

                               FG      := Save_FG;
                               BG      := Save_BG;

                               Ansi_Scroll_Attributes( Top_Scroll ,
                                                       Bottom_Scroll ,
                                                       -1 );

                               MoveToXY( Save_X, Save_Y );

                            END;
{==
                         IF Origin_Mode THEN
                            PibTerm_Window( 1, Top_Scroll, Max_Screen_Col, Bottom_Scroll );
==}
                      END;

               '7':   BEGIN
                         Regs.Ah            := 3;
                         Regs.Bh            := 0;
                         INTR( $10 , Regs );
                         Save_Col_Position  := Regs.Dl;
                         Save_Row_Position  := Regs.Dh;
                         Save_FG_Color      := FG;
                         Save_BG_Color      := BG;
                         Save_Graphics_Mode := Graphics_Mode;
                         Save_Bolding       := Bolding_On;
                         Save_Blinking      := Blinking_On;
                         Save_Done          := TRUE;
                         Save_Top_Scroll    := Top_Scroll;
                         Save_Bottom_Scroll := Bottom_Scroll;
                         Save_Origin_Mode   := Origin_Mode;
                      END;

               '8':   BEGIN
                         Regs.Ah       := 2;
                         Regs.Bh       := 0;
                         Regs.Dh       := Save_Row_Position;
                         Regs.Dl       := Save_Col_Position;
                         INTR( $10 , Regs );
                         FG            := Save_FG_Color;
                         BG            := Save_BG_Color;
                         Bolding_On    := Save_Bolding;
                         Blinking_On   := Save_Blinking;
                         Graphics_Mode := Save_Graphics_Mode;
{
                         Top_Scroll    := Save_Top_Scroll;
                         Bottom_Scroll := Save_Bottom_Scroll;
                         Origin_Mode   := Save_Origin_Mode;
}
                         IF Blinking_On THEN
                           TextColor( FG + Blink )
                         ELSE
                           TextColor( FG );
                         TextBackGround( BG );
                         Set_Global_Colors( FG , BG );
                      END;

               'H':   VT100_Set_Tab;

               ')':   BEGIN
                         Escape_Type   := ')';
                         Ch            := Ansi_Next_Char;
                         IF ( Ch IN VT100_Char_Sets ) THEN
                            BEGIN
                               VT100_G1_Set := Ch;
                               IF ( NOT VT100_G0_State ) THEN
                                  Graphics_Mode := ( VT100_G1_Set = '0' );
                            END;
                      END;

               '(':   BEGIN
                         Escape_Type   := '(';
                         Ch            := Ansi_Next_Char;
                         IF ( Ch IN VT100_Char_Sets ) THEN
                            BEGIN
                               VT100_G0_Set := Ch;
                               IF VT100_G0_State THEN
                                  Graphics_Mode := ( VT100_G0_Set = '0' );
                            END;
                      END;

               '<':   BEGIN
                         Escape_Mode := FALSE;
                         EXIT;
                      END;

               'r':   BEGIN               (* Terminal Reset      *)
                         Top_Scroll    := 1;
                         Bottom_Scroll := Ansi_Last_Line;
                         Clear_Window;
                         FillChar( Line_Attributes, Max_Screen_Line, 0 );
                      END;

               'Z':   Async_Send_String( CHR( 27 ) + '[?1;0c' );

               '=':   Alt_Keypad_Mode := ON;

               '>':   Alt_Keypad_Mode := OFF;

               'c':   Ansi_Reset_Terminal;

               'I':   IF CompuServe_B_On THEN
                         CISB_Term_ESC_I;

               ELSE   More_Escape := TRUE;

            END (* CASE *);

      '[':  CASE Ch OF

               '?':   BEGIN
                         Escape_Type := Ch;
                         EXIT;
                      END;

               'A':   Ansi_Cursor_Up;

               'B':   Ansi_Cursor_Down;

               'C':   Ansi_Cursor_Right;

               'D':   Ansi_Cursor_Left;

               'H':   Ansi_Set_Cursor;

               'J':   Ansi_Clear_Screen;

               'K':   Ansi_Clear_Line;

               'L':   Ansi_Insert_Lines;

               'f':   Ansi_Set_Cursor;

               '}',
               'm':   Ansi_Set_Graphics;

               'r':   Ansi_Set_Scrolling_Region;

               'h':   Ansi_Set_Mode(' ');

               'i':   Ansi_Printer_Control(' ');

               'l':   Ansi_Reset_Mode( ' ' , Done );

               'g':   VT100_Clear_Tabs;

               'M':   Ansi_Delete_Lines;

               'c':   Async_Send_String( CHR( 27 ) + '[?1;0c' );

               'n':   Ansi_Status_Report;

               'P':   Ansi_Delete_Chars;

               'q':   VT100_Set_LEDs;

               's':   (* Protected fields not implemented *);

               'x':   VT100_Send_Terminal_Parameters;

               'y':   ;

               '@':   Ansi_Insert_Chars;

               ELSE   More_Escape := TRUE;

            END (* CASE *);

      '?':  CASE Ch OF

               'h':   Ansi_Set_Mode('?');

               'i':   Ansi_Printer_Control('?');

               'l':   Ansi_Reset_Mode( '?' , Done );

               ELSE   More_Escape := TRUE;

            END (* CASE *);

      '#':  CASE Ch OF

               '3',
               '4',
               '5',
               '6':  BEGIN
                        Reg_Val := ORD( Ch ) - ORD('0');
                        IF ( Reg_Val = 5 ) THEN
                           Reg_Val := 0;
                        VT100_Fix_Line_Width( WhereY , Reg_Val );
                     END;

               '8':  BEGIN
                        S := DUPL( 'E', Wrap_Screen_Col );
                        FOR I := 1 TO PRED( Max_Screen_Line ) DO
                            WriteSXY( S, 1, I,
                                      ( Global_BackGround_Color AND 7 ) SHL 4  +
                                      Global_ForeGround_Color );
                     END;

               ELSE   More_Escape := TRUE;

            END (* CASE *);

      'O':  CASE Ch OF

               'A':   Ansi_Cursor_Up;

               'B':   Ansi_Cursor_Down;

               'C':   Ansi_Cursor_Right;

               'D':   Ansi_Cursor_Left;

               ELSE   More_Escape := TRUE;

            END (* CASE *);

      ELSE  More_Escape := TRUE;

   END (* CASE Escape_Type *);

   IF ( NOT More_Escape ) THEN
      Escape_Mode := FALSE
   ELSE
      BEGIN

         Ch         := UpCase( Ch );
         Escape_Str := Escape_Str + Ch;

         IF Ch IN Lets THEN EXIT;

         IF Ch IN Digits THEN
            BEGIN
               Escape_Register[Escape_Number] :=
                  ( Escape_Register[Escape_Number] * 10 ) + ORD( Ch ) -
                                                            ORD( '0' );
               EXIT;
            END;

         CASE Ch OF

            ';', ',' : BEGIN
                          INC( Escape_Number );
                          Escape_Register[Escape_Number] := 0;
                       END;

            'T', 'S', '#', '+', '-', '>', '<', '.','?','='
                        : ;
            ELSE
               Escape_Mode := FALSE;
               Ansi_Write_Escape;

         END  (* Case *);

      END (* NOT More_Escape *);

END   (* VT100_Process_Escape *);

(*----------------------------------------------------------------------*)
(*        Process_Printer_Escapes --- Process printer escape sequence   *)
(*----------------------------------------------------------------------*)

PROCEDURE Process_Printer_Escapes( Ch : CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Process_Printer_Escapes                               *)
(*                                                                      *)
(*     Purpose:   Processes printer control escape sequences only       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Process_Printer_Escapes( Ch: CHAR );                          *)
(*                                                                      *)
(*           Ch --- Next character in escape sequence                   *)
(*                                                                      *)
(*     Called by:  Emulate_Ansi                                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   More_Escape : BOOLEAN;

BEGIN (* Process_Printer_Escapes *)

   More_Escape := TRUE;
                                   (* Ignore blanks *)
   IF ( Ch = ' ' ) THEN
      BEGIN
         Escape_Str := Escape_Str + Ch;
         EXIT;
      END;
                                   (* Process char depending upon current *)
                                   (* escape type mode                    *)
   CASE Escape_Type OF

      ' ':  CASE Ch OF

               '#',
               '[',
               'O',
               '?':   BEGIN
                         Escape_Str  := Escape_Str + Ch;
                         Escape_Type := Ch;
                         EXIT;
                      END;

               ELSE;

            END (* CASE *);

      '[':  IF ( Ch = 'i' ) THEN
               BEGIN
                  Ansi_Printer_Control(' ');
                  More_Escape := FALSE;
               END;

      ELSE;

   END (* CASE Escape_Type *);

   IF ( NOT More_Escape ) THEN
      Escape_Mode := FALSE
   ELSE
      BEGIN

         Escape_Str := Escape_Str + Ch;
         Ch         := UpCase( Ch );

         IF Ch IN Lets THEN EXIT;

         IF Ch IN Digits THEN
            BEGIN
               Escape_Register[Escape_Number] :=
                  ( Escape_Register[Escape_Number] * 10 ) + ORD( Ch ) -
                                                            ORD( '0' );
               EXIT;
            END;

         CASE Ch OF

            ';', ',' : BEGIN
                          INC( Escape_Number );
                          Escape_Register[Escape_Number] := 0;
                       END;

            'T', 'S', '#', '+', '-', '>', '<', '.','?','='
                        : ;
            ELSE
               Escape_Mode := FALSE;
               Write_Prt_Str( Escape_Str );

         END  (* Case *);

      END (* NOT More_Escape *);

END   (* Process_Printer_Escapes *);

(*----------------------------------------------------------------------*)

BEGIN (* Emulate_ANSI *)
                                   (* We don't go through DOS here *)

   Save_Dos_Con       := Use_Dos_Con_Output;
   Use_Dos_Con_Output := FALSE;

                                   (* Initialize text terminal mode *)
   Init_Text_Terminal;
                                   (* Background, foreground      *)

   Save_Global_FG        := Global_ForeGround_Color;
   Save_Global_BG        := Global_BackGround_Color;
   Save_FG               := ForeGround_Color;
   Save_BG               := BackGround_Color;
   Save_EG               := Border_Color;

                                   (* Set the terminal           *)
   Ansi_Reset_Terminal;
                                   (* Loop over input until done *)
   WHILE ( NOT Done ) DO
      BEGIN

         IF PibTerm_KeyPressed THEN
            BEGIN (* PibTerm_KeyPressed *)

               Save_Do_Status     := Do_Status_Line;
               Save_FG1           := FG;
               Save_BG1           := BG;
               Use_Dos_Con_Output := Save_Dos_Con;

               Set_Global_Colors( Save_Global_FG , Save_Global_BG );

               Handle_Keyboard_Input( Done , Reset_Requested , ClrScr_Request );

               Set_Global_Colors( Save_FG1 , Save_BG1 );

               Save_Dos_Con       := Use_Dos_Con_Output;
               Use_Dos_Con_Output := FALSE;

               IF Reset_Requested THEN
                  BEGIN
                     Clear_Window;
                     Ansi_Reset_Terminal;
                  END
               ELSE IF ClrScr_Request THEN
                  Clear_Window
               ELSE IF ( Save_Do_Status <> Do_Status_Line ) THEN
                  BEGIN

                     IF Do_Status_Line THEN
                        Ansi_Last_Line := PRED( Max_Screen_Line )
                     ELSE
                        Ansi_Last_Line := Max_Screen_Line;

                     PibTerm_Window( 1, 1, Max_Screen_Col, Ansi_Last_Line );

                  END;

            END   (* PibTerm_KeyPressed *);

                                   (* Process a script command if any *)

         IF ( Script_File_Mode AND ( NOT ( Done OR Really_Wait_String ) ) ) THEN
            BEGIN
               Get_Script_Command( PibTerm_Command );
               Execute_Command   ( PibTerm_Command , Done , TRUE );
            END;
                                   (* Hold everything while scroll lock on *)

         IF Scroll_Lock_On THEN
            Handle_Scroll_Lock;
                                   (* Handle carrier drop *)
         IF Carrier_Dropped THEN
            Handle_Carrier_Drop;

                                   (* Process char received from comm port *)

         IF ( Async_Buffer_Head <> Async_Buffer_Tail ) THEN
            BEGIN  (* Comm_Ch found *)

                                   (* Get the character *)

               B := Async_Receive( Comm_Ch );

                                   (* Strip high bit if requested *)

               IF Auto_Strip_High_Bit THEN
                  Comm_Ch := CHR( ORD( Comm_Ch ) AND $7F );

                                   (* Perform translation *)

               Comm_Ch := TrTab[Comm_Ch];

                                   (* Handle printer control mode *)

               IF Printer_Ctrl_Mode THEN
                  BEGIN
                     IF Escape_Mode THEN
                        Process_Printer_Escapes( Comm_Ch )
                     ELSE IF ( Comm_Ch = CHR( ESC ) ) THEN
                        BEGIN
                           IF Escape_Mode THEN
                              Write_Prt_Str( Escape_Str );
                           Escape_Str         := Comm_Ch;
                           Escape_Number      := 1;
                           Escape_Register[1] := 0;
                           Escape_Mode        := TRUE;
                           Escape_Type        := ' ';
                           Getting_Music      := FALSE;
                        END
                     ELSE
                        Write_Prt( Comm_Ch );
                  END
                                   (* Check for special control character *)

               ELSE IF Special_Comm[ ORD( Comm_Ch ) ] THEN
                  Handle_VT100_Special( Comm_Ch )

                                   (* Check for escape sequence to process *)

               ELSE IF Escape_Mode THEN

                  CASE VT100_Allowed OF
                     TRUE:   VT100_Process_Escape( Comm_Ch , Done );
                     FALSE:  Ansi_Process_Escape( Comm_Ch );
                  END (* CASE *)

               ELSE
                     BEGIN  (* Ordinary character *)

                        Double_Ch        := ' ';

                        IF Graphics_Mode THEN
                           BEGIN (* Graphics Mode *)

                              IF ORD( Comm_Ch ) IN [ 95 .. 126 ] THEN
                                 BEGIN
                                    Graph_Ch := VT100_Graphics_Chars[ ORD( Comm_Ch ) ];
                                    Comm_Ch  := CHR( Graph_Ch );
                                 END;

                              IF Double_Width_Mode THEN
                                 IF ( Comm_Ch = CHR(196) ) OR
                                    ( Comm_Ch = CHR(192) ) OR
                                    ( Comm_Ch = CHR(218) ) THEN
                                       Double_Ch := CHR( 196 );

                           END   (* Graphics Mode *);

                        Display_Character( Comm_Ch );

                        IF Double_Width_Mode THEN
                           Display_Character( Double_Ch );

                        IF Do_Script_Tests THEN
                           Do_Script_Checks( Comm_Ch );

                     END  (* Ordinary character *);

            END (* Comm_Ch found *)
                                   (* Check if waitstring time exhausted *)
         ELSE
            BEGIN
               Async_Line_Status := Async_Line_Status AND $FD;
               IF Really_Wait_String THEN
                  Check_Wait_String_Time;
               IF ( ( NOT PibTerm_KeyPressed ) AND ( NOT Script_File_Mode ) ) THEN
                  IF ( Async_Buffer_Head = Async_Buffer_Tail ) THEN
                     GiveAwayTime( 1 );
            END;

      END  (* NOT Done *);
                                   (* Reset whole screen as window *)

   PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line );

                                   (* Restore colors *)

   Reset_Attr              := ( ForeGround_Color <> Save_FG ) OR
                              ( BackGround_Color <> Save_BG );
   ForeGround_Color        := Save_FG;
   BackGround_Color        := Save_BG;
   Border_Color            := Save_EG;

   Set_Global_Colors( ForeGround_Color , BackGround_Color );
   Set_Border_Color ( Border_Color );

   IF Reset_Attr THEN
      Set_Text_Attributes( 1, 1, Max_Screen_Col, Max_Screen_Line,
                           ForeGround_Color, BackGround_Color );

   Use_Dos_Con_Output := Save_Dos_Con;

END   (* Emulate_ANSI *);

