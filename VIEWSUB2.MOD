(*---------------------------------------------------------------------------*)
(*                 Format_Line -- Format text for screen display             *)
(*---------------------------------------------------------------------------*)

PROCEDURE Format_Line( Txt: AnyStr; ScrLin : INTEGER );

(*---------------------------------------------------------------------------*)
(*                                                                           *)
(*     Routine:  Format_Line                                                 *)
(*                                                                           *)
(*     Purpose:  Format text for screen display                              *)
(*                                                                           *)
(*     Calling Sequence:                                                     *)
(*                                                                           *)
(*        Format_Line( Txt: AnyStr; ScrLin: INTEGER );                       *)
(*                                                                           *)
(*           Txt    --- The text to be displayed                             *)
(*           ScrLin --- Screen row  of 'Txt'                                 *)
(*                                                                           *)
(*     Calls:       TextColor                                                *)
(*                                                                           *)
(*     Called By:   Display_Screen                                           *)
(*                                                                           *)
(*     Remarks:                                                              *)
(*                                                                           *)
(*        Up to a maximum of 'width' characters will be displayed            *)
(*        starting at 'First_Col'.  Column one is always displayed           *)
(*        if line-printer controls are requested.  Unprintable               *)
(*        characters are printed as their ASCII mnemonics enclosed           *)
(*        in angular brackets.                                               *)
(*                                                                           *)
(*---------------------------------------------------------------------------*)

TYPE
   My_Line_Type = ARRAY[1..264] OF CHAR;

VAR
   I       : INTEGER;
   J       : INTEGER;
   N       : INTEGER;
   Len     : INTEGER;
   C       : CHAR;
   IPos    : INTEGER;
   LColor  : CHAR;
   My_Line : My_Line_Type;
   Spec_C  : CHAR;

BEGIN  (* Format_Line *)

   Len  := LENGTH( Txt );

   IPos := 1;
                                   (* If this line is string-search *)
                                   (* result, high-light it.        *)

   IF ( ScrLin = Search_Lpos ) THEN
      BEGIN
         LColor      := CHR( Search_Color );
         Spec_C      := CHR( Spec_Chars_Color_2 );
         Search_Lpos := 0;
      END
   ELSE
      BEGIN
         LColor := CHR( Normal_Color     );
         Spec_C := CHR( Spec_Chars_Color );
      END;

   FillChar( My_Line, 2 * Max_Screen_Col, LColor );

   N := 0;
   I := First_Col;
                                   (* Insert each character into work line *)

   WHILE ( ( I <= Len ) AND ( N < Width ) ) DO
      BEGIN

         C := Txt[I];

         INC( I );

         IF ( Spec_Chars[C] ) THEN
            BEGIN
               My_Line[ IPos + 1 ] := Spec_C;
               My_Line[ IPos     ] := C;
               INC( IPos , 2 );
               INC( N );
            END
         ELSE
            BEGIN
               My_Line[ IPos ] := C;
               INC( IPos , 2 );
               INC( N );
            END;

      END;

   WriteLXY( My_Line, 1, SUCC( ScrLin ), N );

END   (* Format_Line *);

(*---------------------------------------------------------------------------*)
(*                Display_Screen -- Display formatted screen                 *)
(*---------------------------------------------------------------------------*)

PROCEDURE Display_Screen;

(*---------------------------------------------------------------------------*)
(*                                                                           *)
(*     Routine:  Display_Screen                                              *)
(*                                                                           *)
(*     Purpose:  Displays formatted screen                                   *)
(*                                                                           *)
(*     Calling Sequence:                                                     *)
(*                                                                           *)
(*        Display_Screen;                                                    *)
(*                                                                           *)
(*     Calls:                                                                *)
(*                                                                           *)
(*        Read_Line                                                          *)
(*        Format_Line                                                        *)
(*        Move                                                               *)
(*        PibTerm_Window                                                     *)
(*        InsLine                                                            *)
(*        DelLine                                                            *)
(*        GoToXY                                                             *)
(*                                                                           *)
(*     Remarks:                                                              *)
(*                                                                           *)
(*        On entry Eod=FALSE if the viewing window contains at least one     *)
(*        line.  In this case top points to the first line in the window.    *)
(*        On exit Bot points to the Last Line in the window, and top_Line    *)
(*        is equal to the Line number of the top Line in the window.  If     *)
(*        the viewing window extends beyond the end of the file then the     *)
(*        extra Line <End of file> is displayed.                             *)
(*                                                                           *)
(*        On entry Eod=TRUE if the viewing window is beyond the end of the   *)
(*        file. In this case top points to the Last line in the buffer,      *)
(*        which is the Last line in the file.  Only the message              *)
(*        <End of file> is displayed.  On exit Bot=top and top_Line is       *)
(*        the line number of the Last line in the file plus 1.               *)
(*        The <END of file> message is considered in this case               *)
(*        to be an "extra" line on the file with line number Max_Line+1.     *)
(*        This gives proper behavior on subsequent backwards line and screen *)
(*        skipping commands.                                                 *)
(*                                                                           *)
(*        Note:  Requests for 1 line up or down scrolls are handled          *)
(*               as special cases.                                           *)
(*                                                                           *)
(*---------------------------------------------------------------------------*)

VAR
   N       : INTEGER;
   LineNo  : INTEGER;
   Nothing : BOOLEAN;
   Save_Bot: Line_Ptr;

(*---------------------------------------------------------------------------*)

PROCEDURE Display_Remaining_Lines( Do_Each : BOOLEAN );

BEGIN (* Display_Remaining_Lines *);

   WHILE ( N > 0 ) AND ( NOT Eod ) DO
      BEGIN
         INC( LineNo );
         IF Do_Each THEN
            Format_Line( Bot^.Txt, LineNo );
         DEC( N );
         Save_Bot := Bot;
         IF ( N > 0 ) THEN
            IF Bot = Last THEN
               BEGIN
                  Read_Line;
                  Bot := Last;
               END
            ELSE
               Bot := Bot^.Next;
         Eod := ( Save_Bot = Bot );
      END;

END   (* Display_Remaining_Lines *);

(*---------------------------------------------------------------------------*)

BEGIN  (* Display_Screen *)

   PibTerm_Window( 1 , 2 , Max_Screen_Col , PRED( PS_Size ) );

   Bot    := Top;
   N      := Height;
   LineNo := 0;

   IF ( One_Up AND ( Top^.Lnum = 1 ) ) THEN
      One_Up := FALSE;

   IF Eod THEN
      Top_Line := SUCC( Top^.Lnum )
   ELSE
      Top_Line := Top^.Lnum;

                                   (* Case one: scroll screen down 1 line *)
   IF One_Up THEN
      BEGIN

         Scroll( 2 , PRED( PS_Size ), 1, Max_Screen_Col, -1,
                 ForeGround_Color, BackGround_Color );

         Format_Line( Bot^.Txt, 1 );

         Display_Remaining_Lines( FALSE );

      END
                                   (* Case 2: Scroll screen up 1 line *)
   ELSE IF One_Down THEN
      BEGIN

         Scroll( 2 , PRED( PS_Size ), 1, Max_Screen_Col, 1,
                 ForeGround_Color, BackGround_Color );

         Display_Remaining_Lines( FALSE );

         IF ( N <= 0 ) THEN
            Format_Line( Bot^.Txt, LineNo )
        ELSE
           BEGIN
              INC( LineNo );
              Format_Line( '<End of File>', LineNo );
              DEC( N );
           END;

      END
                                   (* Case 3:  Everything else *)
   ELSE
      BEGIN

         Scroll( 2 , PRED( PS_Size ), 1, Max_Screen_Col, 0,
                 ForeGround_Color, BackGround_Color );

         Display_Remaining_Lines( TRUE );

         IF ( N > 0 ) THEN
            BEGIN
               INC( LineNo );
               Format_Line( '<End of File>', LineNo );
               DEC( N );
            END;

      END;

END   (* Display_Screen  *);

(*----------------------------------------------------------------------*)
(*          Get_View_Command --- Get viewing command key                *)
(*----------------------------------------------------------------------*)

FUNCTION Get_View_Command : CHAR;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Function:    Get_View_Command                                      *)
(*                                                                      *)
(*   Purpose:     Gets viewing command key                              *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      Ch := Get_View_Command : CHAR;                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   C : CHAR;

BEGIN (* Prompt *)
                                   (* Toss stuff in keyboard to try *)
                                   (* to avoid keyboard overflow    *)
   WHILE( PibTerm_KeyPressed ) DO
      Read_Kbd_Old( C );
                                   (* Get command character *)
   Read_Kbd_Old( C );
                                   (* Convert to upper case *)
   C := UpCase( C );
                                   (* Convert keypad keys and WordStar *)
                                   (* commands to letters              *)
   CASE C OF

      ^[   : IF PibTerm_KeyPressed THEN
                BEGIN

                   Read_Kbd_Old( C );

                   CASE ORD( C ) OF

                     PgUp:    C := 'B';
                     PgDn:    C := 'F';
                     U_Arrow: C := 'U';
                     D_Arrow: C := 'D';
                     L_Arrow: C := '<';
                     R_Arrow: C := '>';
                     End_Key: C := 'E';
                     Home:    C := 'T';
                     ELSE     C := 'Z';

                  END (* CASE *)

                END;

      ' '  : C := ^M;

      ^M   ,
      'S'  ,
      'N'  ,
      'L'  : ;

      ^E   : C := 'U';
      ^X   : C := 'D';
      ^S   : C := '<';
      ^D   : C := '>';
      ^T   : C := 'B';
      ^Z   : C := 'F';
      ^Q   : C := 'T';
      ^L   : C := 'E';

      ELSE   C := 'Z';

   END (* CASE *);
                                   (* Return command character *)
   Get_View_Command := C;

END   (* Get_View_Command *);

(*----------------------------------------------------------------------*)
(*                   Prompt --- Prompt for Command Entry                *)
(*----------------------------------------------------------------------*)

PROCEDURE Prompt;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Procedure:   Prompt                                                *)
(*                                                                      *)
(*   Purpose:     Prompts for, reads, parses, and executes command.     *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      Prompt;                                                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Legal   : BOOLEAN;
   Question: BOOLEAN;
   C       : CHAR;
   SNum    : STRING[6];
   SCol    : STRING[6];
   N       : LONGINT;

BEGIN (* Prompt *)

   REPEAT

      Legal    := TRUE;
      Question := FALSE;
                                   (* Update line/column display *)
      STR( Bot^.LNum : 6 , SNum );
      STR( First_Col : 5 , SCol );

      WriteSXY( ' Line' + SNum + '   Column' + SCol, 1, PS_Size,
                Status_Line_Color );

                                   (* Not single line move yet *)
      One_Up   := FALSE;
      One_Down := FALSE;
                                   (* Get and execute next command request *)
      CASE Get_View_Command OF

         'U'  : BEGIN
                   Find_Line( RMax( PRED( Top_Line ) , 1 ) );
                   One_Up := TRUE;
                END;
         'D'  : BEGIN
                   Find_Line( SUCC( Top_Line ) );
                   One_Down := TRUE;
                END;
         'F'  : Find_Line( Top_Line + Height );
         'B'  : Find_Line( RMAX( Top_Line - Height , 1 ) );
         'T'  : Find_Line( 1 );
         'E'  : Find_Line( 99999999 );
         '<'  : BEGIN
                   First_Col := RMax( PRED( First_Col ) , 1 );
                   Find_Line( Top_Line );
                END;
         '>'  : BEGIN
                   INC( First_Col );
                   Find_Line( Top_Line );
                END;
         ^M   : Find_Line( SUCC( Bot^.LNum ) );
         'S'  : BEGIN
                   Get_Search_String;
                   Find_Line( RMAX( SUCC( Search_Line ) , Top^.LNum ) );
                   Find_String( Search_Str );
                END;
         'N'  : BEGIN
                   Find_Line( RMAX( SUCC( Search_Line ) , Top^.LNum ) );
                   Find_String( Search_Str );
                END;
         'L'  : BEGIN
                   Get_Line_Number( N );
                   IF ( N > 0 ) THEN
                      Find_Line( N )
                   ELSE
                      Find_Line( Top_Line );
                END;
         ^[   : BEGIN
                   All_Done := TRUE;
                   Done     := TRUE;
                END;
         ELSE   Legal := FALSE;

      END (* CASE *);

      IF ( NOT Legal ) THEN
         Menu_Beep;

   UNTIL ( Legal AND ( NOT Question ) );

END   (* Prompt *);

(*----------------------------------------------------------------------*)
(*               Init_File --- Initialize File to be listed             *)
(*----------------------------------------------------------------------*)

FUNCTION Init_File( VAR File_Spec: AnyStr ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Function:    Init_File                                             *)
(*                                                                      *)
(*   Purpose:     Initializes File to be listed                         *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      OK := Init_File( VAR File_Spec: AnyStr ) : BOOLEAN;             *)
(*                                                                      *)
(*         File_Spec: Name of file to be listed.                        *)
(*                                                                      *)
(*         OK = TRUE if file opened OK.                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   SFSize     : STRING[8];
   SFDate     : STRING[8];
   SFTime     : STRING[8];
   SFName     : STRING[12];
   File_Entry : SearchRec;

BEGIN (* Init_File *)
                                   (* Attach file to be listed *)
   FileMode     := 0;

   ASSIGN( F, File_Spec );
   SetTextBuf( F , Sector_Data );
   RESET( F );

   FileMode     := 2;
                                    (* Reset file for I/O *)
   Reset_F;
                                    (* File OK *)
   Init_File := TRUE;
                                    (* Turn off cursor   *)
   CursorOff;
                                    (* Clear screen      *)

   Scroll( 1, PS_Size, 1, Max_Screen_Col, 0,
           ForeGround_Color, BackGround_Color );

                                   (* Set color in status line *)

   WriteSXY( DUPL( ' ', Max_Screen_Col ), 1,  PS_Size,
             Status_Line_Color );

                                   (* Write options in status line *)

   WriteSXY( CHR( 24 ) + '/' + CHR( 25 ) + '/' +
             CHR( 26 ) + '/' + CHR( 27 ) + '/' +
             'PgUp/PgDn/Home/End/S/N/L/<ESC>', 40, PS_Size, Status_Line_Color );

                                   (* Set color in file name line *)

   WriteSXY( DUPL( ' ', Max_Screen_Col ), 1,  1,
             Status_Line_Color );
                                    (* Display file spec *)

   FindFirst( File_Spec, AnyFile, File_Entry );

   WITH File_Entry DO
      BEGIN
         SFName := Name;
         STR( Size , SFSize );
         SFSize := SFSize + DUPL( ' ' , 8 - LENGTH( SFSize ) );
         Dir_Convert_File_Date_And_Time( Time, SFDate, SFTime );
      END;

   WriteSXY( 'File: '    + SFName +
             '     Size: ' + SFSize +
             '   Date: ' + SFDate +
             '   Time: ' + SFTime,
             1, 1, Status_Line_Color );

END   (* Init_File *);

(*----------------------------------------------------------------------*)
(*      Initialize_Viewing --- Initialize file viewing                  *)
(*----------------------------------------------------------------------*)

FUNCTION Initialize_Viewing : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Function:    Initialize_Viewing                                    *)
(*                                                                      *)
(*   Purpose:     Initializes file viewing                              *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      OK := Initialize_Viewing : BOOLEAN;                             *)
(*                                                                      *)
(*         OK --- FALSE if not enough memory to hold buffered lines     *)
(*                for file viewing.                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I:         INTEGER;
   J:         INTEGER;
   K:         INTEGER;
   Len:       INTEGER;
   Last_Col:  INTEGER;
   P:         Line_Ptr;
   Param_Str: AnyStr;
   Ch       : CHAR;

BEGIN  (* Initialize_Viewing *)

   Max_Line     := 0;
   Done         := FALSE;
   Eod          := FALSE;
   Width        := Max_Screen_Col;
   Expand_Tabs  := FALSE;
   Strip_High   := FALSE;
   File_Pattern := '';

   PS_Size      := Max_Screen_Line;

   FOR Ch := CHR(0) TO CHR(31) DO
      Spec_Chars[Ch] := TRUE;

   FOR Ch := CHR(32) TO CHR(255) DO
      Spec_Chars[Ch] := FALSE;

   Spec_Chars[#127] := TRUE;
                                   (* Figure # of lines that will fit   *)
                                   (* in memory.                        *)

   Max_Buf_Lines := MIN( 200 ,
                         MAX( 0 ,
                              TRUNC( ( MemAvail - 4000 ) DIV Max_String ) ) );

                                   (* If space for less than two screen- *)
                                   (* fulls of lines, skip viewing.      *)

   IF ( Max_Buf_Lines < ( 2 * Max_Screen_Line ) ) THEN
      BEGIN
          WRITELN('Not enough memory to view file, viewing cancelled.');
          Press_Any;
          Initialize_Viewing := FALSE;
          EXIT;
      END;
                                   (* Get the circular text line buffer *)
   NEW( First );

   Last := First;

   FOR I := 1 TO PRED( Max_Buf_Lines ) DO
      BEGIN
         NEW( P );
         Last^.Next := P;
         Last       := P
      END;

   Last^.Next := First;
   Last       := NIL;
                                   (* No current search string *)
   Search_Str  := '';
   Search_Line := 0;
   Search_Lpos := 0;
   Search_Col  := 0;

   One_Up      := FALSE;
   One_Down    := FALSE;
                                   (* Get height of display area *)
   Height      := PS_Size - 2;
                                   (* Set colors *)

   Normal_Color       := 16 * ( Background_Color AND 7 ) +
                         ForeGround_Color;
   Search_Color       := 16 * ( ForeGround_Color AND 7 ) +
                         BackGround_Color;
   Status_Line_Color  := 16 * ( Menu_Text_Color AND 7 ) +
                         BackGround_Color;
   Spec_Chars_Color   := Normal_Color;
   Spec_Chars_Color_2 := Search_Color;
   Help_Text_Color    := 16 * ( BackGround_Color AND 7 ) +
                         Menu_Text_Color;

   Initialize_Viewing := TRUE;

END   (* Initialize_Viewing *);

(*----------------------------------------------------------------------*)
(*          Init_This_File --- Initialize current file to be listed     *)
(*----------------------------------------------------------------------*)

FUNCTION Init_This_File( File_Spec : AnyStr ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   Function:    Init_This_File                                        *)
(*                                                                      *)
(*   Purpose:     Initializes current file to be listed                 *)
(*                                                                      *)
(*   Calling sequence:                                                  *)
(*                                                                      *)
(*      OK := Init_This_File( Dir_Entry : SearchRec );                  *)
(*                                                                      *)
(*         Dir_Entry: Directory record for file to be listed.           *)
(*                                                                      *)
(*         OK = TRUE if file OK to be listed.                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I:         INTEGER;
   J:         INTEGER;
   K:         INTEGER;
   Len:       INTEGER;
   Last_Col:  INTEGER;
   P:         Line_Ptr;
   Ch       : CHAR;

BEGIN (* Init_This_File *)
                                   (* Get the file name to list and open it *)

   IF ( NOT Init_File( File_Spec ) ) THEN
      BEGIN
         Init_This_File := FALSE;
         EXIT;
      END
   ELSE
      Init_This_File := TRUE;

   I        := 1;
   Last_Col := 1;
   Last     := NIL;
                                   (* Read in the First Max_Buf_Lines lines *)
   REPEAT

      Read_Line;

      INC( I );

      Last_Col := MAX( Last_Col , LENGTH( Last^.Txt ) );

   UNTIL ( ( I = Max_Buf_Lines ) OR EOF( F ) );

   Top := First;

   J   := 1;

   IF ( Last_Col <= Width ) THEN
      First_Col := J
   ELSE
      BEGIN

         P := First;
         K := Max_String + 1;

         REPEAT

            I := J;

            WITH P^ DO
               BEGIN

                  Len := LENGTH( P^.Txt );

                  WHILE ( ( I < Len ) AND ( Txt[I] IN [' ',FF] ) ) DO INC( I );

                  IF I < Len THEN K := MIN( K , I )

               END;

            P := P^.Next

         UNTIL ( P = Last^.Next );

         First_Col := MIN( K , Last_Col + J - Width );

     END;

   One_Up      := FALSE;
   One_Down    := FALSE;

END   (* Init_This_File *);

(*----------------------------------------------------------------------*)
(*          Release_Line_Buffer --- Release linked list of lines        *)
(*----------------------------------------------------------------------*)

PROCEDURE Release_Line_Buffer;

VAR
   P1: Line_Ptr;
   P2: Line_Ptr;
   I : INTEGER;

BEGIN (* Release_Line_Buffer *)

   P1 := First;

   FOR I := 1 TO PRED( Max_Buf_Lines ) DO
      BEGIN
         P2 := P1;
         P1 := P1^.Next;
         DISPOSE( P2 );
      END;

   DISPOSE( P1 );

END   (* Release_Line_Buffer *);

(*----------------------------------------------------------------------*)
(*             List_One_File --- P R O C E D U R E   B O D Y            *)
(*----------------------------------------------------------------------*)

BEGIN (* List_One_File *)
                                   (* General initialization *)

   IF ( NOT Initialize_Viewing ) THEN
      EXIT;
                                   (* Initialize file *)

   IF ( NOT Init_This_File( View_File_Name ) ) THEN
      EXIT;
                                   (* Not done with this file yet *)
   Done := FALSE;
                                   (* Loop until no more commands *)
   WHILE ( NOT Done ) DO
      BEGIN
                                   (* Display screenful of lines  *)
         Display_Screen;
                                   (* Get input command *)
         Prompt;

      END;
                                   (* Close current file *)
   CLOSE( F );

   IF ( Int24Result <> 0 ) THEN;
                                   (* Release view buffer memory *)
   Release_Line_Buffer;
                                   (* Re-enable cursor           *)
   CursorOn;

END   (* List_One_File *);
