(*----------------------------------------------------------------------*)
(*   Directory_Of_Scripts --- Display directory of available scripts    *)
(*----------------------------------------------------------------------*)

PROCEDURE Directory_Of_Scripts;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Directory_Of_Scripts                                 *)
(*                                                                      *)
(*     Purpose:    Displays directory of scripts                        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Directory_Of_Scripts;                                         *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Save_Screen                                                   *)
(*        Draw_Menu_Frame                                               *)
(*        Restore_Screen                                                *)
(*        Reset_Global_Colors                                           *)
(*        Display_Library_Options                                       *)
(*        Display_Script_Options                                        *)
(*        Get_Library_Names                                             *)
(*        Get_Directory_Names                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   Scripts_Per_Line        = 7;
   Scripts_Per_Page        = 105;
   Scripts_Per_Line_1      = 6;
   Scripts_Per_Page_1      = 104;
   Script_Lines_Per_Page   = 15;
   Script_Lines_Per_Page_1 = 14;

TYPE
   Script_Origin_Type     = ( From_Disk, From_Library, From_Memory );

   Script_Names_Type      = ARRAY[1..1] OF STRING[8];
   Script_Lib_Origin_Type = ARRAY[1..1] OF Script_Origin_Type;

   Script_Names_Type_Ptr  = ^Script_Names_Type;
   Script_Lib_Origin_Ptr  = ^Script_Lib_Origin_Type;

VAR
   Local_Save_2      : Saved_Screen_Ptr;
   I                 : INTEGER;
   J                 : INTEGER;
   L                 : INTEGER;
   Ch                : CHAR;
   Script_Title      : AnyStr;
   Quit              : BOOLEAN;
   Script_File_Local : Text_File;
   Top_Script        : INTEGER;
   Bottom_Script     : INTEGER;
   Current_Script    : INTEGER;
   Row               : INTEGER;
   Column            : INTEGER;
   NScripts          : INTEGER;
   Script_Names      : Script_Names_Type_Ptr;
   Script_Lib_Origin : Script_Lib_Origin_Ptr;
   ReDraw            : BOOLEAN;
   Search_String     : STRING[8];
   Recomp            : BOOLEAN;
   Max_Scripts       : INTEGER;
   RMaxScripts       : LONGINT;

(*----------------------------------------------------------------------*)
(*   Display_Directory_Options --- Display script processing options    *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Directory_Options;

BEGIN (* Display_Directory_Options *)

   TextColor( Menu_Text_Color );

   GoToXY( 1 , 16 );
   WRITE(' * before script name means script resides in PIBTERM.SCL');
   ClrEol;
   GoToXY( 1 , 17 );
   WRITE(' & before script name means script already compiled to memory');
   ClrEol;

   GoToXY( 1 , 19 );
   TextColor( Menu_Frame_Color );
   WRITE('ESC');
   TextColor( Menu_Text_Color  );
   WRITE('    Quit    ');
   TextColor( Menu_Frame_Color );
   WRITE('/');
   TextColor( Menu_Text_Color  );
   WRITE('   Scroll     ');
   TextColor( Menu_Frame_Color );
   WRITE('PgUp/PdDn');
   TextColor( Menu_Text_Color  );
   WRITE('  Page       ');
   TextColor( Menu_Frame_Color );
   WRITE('Home/End  ');
   TextColor( Menu_Text_Color  );
   WRITE('Top/bottom');
   ClrEol;

   GoToXY( 1 , 20 );
   TextColor( Menu_Frame_Color );
   WRITE('S      ');
   TextColor( Menu_Text_Color  );
   WRITE('Search  ');
   TextColor( Menu_Frame_Color );
   WRITE('C     ');
   TextColor( Menu_Text_Color  );
   WRITE('Compile    ');
   TextColor( Menu_Frame_Color );
   WRITE('U          ');
   TextColor( Menu_Text_Color  );
   WRITE('Unload     ');
   TextColor( Menu_Frame_Color );
   WRITE('L         ');
   TextColor( Menu_Text_Color  );
   IF ( NOT Script_Learn_Mode ) THEN
      WRITE('Learn')
   ELSE
      WRITE( 'Finish learn' );
   ClrEol;
{
   GoToXY( 1 , 21 );
   TextColor( Menu_Frame_Color );
   WRITE('ENTER  ');
   TextColor( Menu_Text_Color  );
   WRITE('execute script           ');
}
   GoToXY( 1 , 21 );
   TextColor( Menu_Frame_Color );
   WRITE('ENTER  ');
   TextColor( Menu_Text_Color  );
   WRITE('execute ');
   TextColor( Menu_Frame_Color );
   WRITE('A');
   TextColor( Menu_Text_Color  );
   WRITE('     Unload all ');
   TextColor( Menu_Frame_Color );
   WRITE('O          ');
   TextColor( Menu_Text_Color  );
   WRITE('Change search order (now ');
   CASE Script_Search_Order OF
      Dir_Then_Lib:  WRITE('DL');
      Lib_Then_Dir:  WRITE('LD');
      Dir_Only    :  WRITE('D ');
      Lib_Only    :  WRITE('L ');
   END (* CASE *);
   WRITE(')');
   ClrEol;

END   (* Display_Directory_Options *);

(*----------------------------------------------------------------------*)
(*          Get_Library_Names --- Get script names in PIBTERM.SCL       *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Library_Names;

VAR
   Quit  : BOOLEAN;
   SName : STRING[8];

BEGIN (* Get_Library_Names *)
                                   (* Open script library file *)
      (*!I-*)
   ASSIGN( Script_File_Local , Home_Dir + 'PIBTERM.SCL' );
   RESET ( Script_File_Local );
      (*!I+*)
                                   (* Error if it can't be opened *)
   IF ( Int24Result <> 0 ) THEN
      BEGIN
            (*!I-*)
         CLOSE( Script_File_Local );
            (*!I+*)
         I := Int24Result;
         EXIT;
      END;
                                   (* Loop over script library lines *)
                                   (* and extract script names.      *)
   Quit := FALSE;

   REPEAT

      READLN( Script_File_Local , Script_Line );

      IF ( LENGTH( Script_Line ) > 1 ) THEN
         IF ( COPY( Script_Line, 1, 2 ) = '==' ) THEN
            BEGIN

               SName    := COPY( Script_Line, 3, LENGTH( Script_Line ) - 2 );
               SName    := SName + Dupl( ' ' , 8 - LENGTH( SName ) );

               IF ( NScripts >= Max_Scripts ) THEN
                  Quit := TRUE
               ELSE
                  BEGIN
                     INC( NScripts );
                     Script_Names^[NScripts]      := SName;
                     Script_Lib_Origin^[NScripts] := From_Library;
                  END;

            END;

   UNTIL ( EOF( Script_File_Local ) OR Quit );

                                   (* Close script library file *)
      (*!I-*)
   CLOSE( Script_File_Local );
      (*!I+*)
   I := Int24Result;

END   (* Get_Library_Names *);

(*----------------------------------------------------------------------*)
(*   Get_Directory_Names --- Get script names in script directory       *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Directory_Names;

VAR
   Quit         : BOOLEAN;
   File_Entry   : SearchRec;
   SName        : STRING[8];
   Script_P     : AnyStr;
   I            : INTEGER;

BEGIN (* Get_Directory_Names *)
                                   (* Script path *)

   Script_P := Script_Path + '*.SCR';

                                   (* See if any scripts at all *)

   FindFirst( Script_P, AnyFile, File_Entry );

   Quit     := ( DosError <> 0 );

   IF ( Quit AND ( NScripts = 0 ) ) THEN
      BEGIN
         GoToXY( 1 , 1 );
         WRITE('No scripts at all!');
         ClrEol;
      END;
                                   (* Get all scripts in directory *)
   WHILE( NOT Quit ) DO
      BEGIN
                                   (* Get file name *)

         IF ( Nscripts > Max_Scripts ) THEN
            Quit := TRUE
         ELSE
            WITH File_Entry DO
               BEGIN
                  INC( NScripts );
                  SName     := COPY( Name, 1, PRED( POS( '.' , Name ) ) );
                  SName     := SName + Dupl( ' ' , 8 - LENGTH( SName ) );
                  Script_Names^[NScripts]      := SName;
                  Script_Lib_Origin^[NScripts] := From_Disk;
               END;
                                   (* See if more scripts *)

         FindNext( File_Entry );

         Quit := Quit OR ( DosError <> 0 );

      END (* WHILE *);

END   (* Get_Directory_Names *);

(*----------------------------------------------------------------------*)
(*   Get_Compiled_Names --- Get script names already compiled to memory *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Compiled_Names;

VAR
   SName        : STRING[8];
   I            : INTEGER;
   Quit         : BOOLEAN;

BEGIN (* Get_Compiled_Names *)

   Quit := FALSE;
   I    := 0;

   WHILE ( NOT Quit ) DO
      BEGIN

         INC( I );

         IF ( I > Script_Count ) THEN
            Quit:= TRUE
         ELSE
            BEGIN

               INC( NScripts );

               IF ( NScripts > Max_Scripts ) THEN
                  Quit := TRUE
               ELSE
                  BEGIN
                     SName := Scripts[I].Script_Name;
                     Script_Names^[NScripts] := Sname +
                        Dupl( ' ' , 8 - LENGTH( SName ) );
                     Script_Lib_Origin^[NScripts] := From_Memory;
                  END;

            END;

      END;

END   (* Get_Compiled_Names *);

(*----------------------------------------------------------------------*)
(*             Sort_Script_Names --- Sort the script names              *)
(*----------------------------------------------------------------------*)

PROCEDURE Sort_Script_Names;

VAR
   I     : INTEGER;
   J     : INTEGER;
   SName : STRING[8];
   B     : Script_Origin_Type;
   D     : INTEGER;

BEGIN (* Sort_Script_Names *)
                                   (* This is a shell sort *)
   D := NScripts;

   WHILE( D > 1 ) DO
      BEGIN

         IF ( D < 5 ) THEN
            D := 1
         ELSE
            D := TRUNC( 0.45454 * D );

         FOR I := ( NScripts - D ) DOWNTO 1 DO
            BEGIN

               SName := Script_Names^[I];
               B     := Script_Lib_Origin^[I];
               J     := I + D;

               WHILE( ( SName > Script_Names^[J] ) AND ( J <= NScripts ) ) DO
                  BEGIN
                     Script_Names^[J-D]      := Script_Names^[J];
                     Script_Lib_Origin^[J-D] := Script_Lib_Origin^[J];
                     J                       := J + D;
                  END;

               Script_Names^[J-D]      := SName;
               Script_Lib_Origin^[J-D] := B;

            END;

      END;

END   (* Sort_Script_Names *);

(*----------------------------------------------------------------------*)
(*             Emphasize --- Emphasize current script name              *)
(*----------------------------------------------------------------------*)

PROCEDURE Emphasize;

BEGIN (* Emphasize *)

   IF ( NScripts > 0 ) THEN
      BEGIN

         RvsVideoOn( Menu_Text_Color, BLACK );

         GoToXY( ( Column - 1 ) * 10 + 1 , Row );

         CASE Script_Lib_Origin^[Current_Script] OF
            From_Library: WRITE( ' *');
            From_Disk   : WRITE( '  ');
            From_Memory : WRITE( ' &');
         END (* CASE *);

         WRITE( Script_Names^[Current_Script] );

         RvsVideoOff( Menu_Text_Color, BLACK );

      END;

END   (* Emphasize *);

(*----------------------------------------------------------------------*)
(*             UnEmphasize --- Unemphasize current script name          *)
(*----------------------------------------------------------------------*)

PROCEDURE Unemphasize;

BEGIN (* Unemphasize *)

   IF ( NScripts > 0 ) THEN
      BEGIN

         GoToXY( ( Column - 1 ) * 10 + 1 , Row );

         CASE Script_Lib_Origin^[Current_Script] OF
            From_Library: WRITE( ' *');
            From_Disk   : WRITE( '  ');
            From_Memory : WRITE( ' &');
         END (* CASE *);

         WRITE( Script_Names^[Current_Script] );

      END;

END   (* Unemphasize *);

(*----------------------------------------------------------------------*)
(*             Display_A_Line --- Display one line in script list       *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_A_Line( LineNo : INTEGER; Top: INTEGER );

VAR
   I: INTEGER;
   N: INTEGER;

BEGIN (* Display_A_Line *)

   GoToXY( 1 , LineNo );

   N := MIN( NScripts , Top + Scripts_Per_Line_1 );

   FOR I := Top TO N DO
      BEGIN

         CASE Script_Lib_Origin^[I] OF
            From_Library: WRITE( ' *');
            From_Disk   : WRITE( '  ');
            From_Memory : WRITE( ' &');
         END (* CASE *);

         WRITE( Script_Names^[I] );

      END;

   ClrEol;

END   (* Display_A_Line *);

(*----------------------------------------------------------------------*)
(*               Scroll_Up --- Scroll up a line in display              *)
(*----------------------------------------------------------------------*)

PROCEDURE Scroll_Up;

VAR
   L: INTEGER;

BEGIN (* Scroll_Up *)

   IF ( Bottom_Script < NScripts ) THEN
      BEGIN

         Emphasize;
                                   (* Make room for new line *)
         GoToXY( 1 , 1 );
         DelLine;

         Top_Script     := MIN( NScripts , Top_Script     + Scripts_Per_Line_1 );
         Bottom_Script  := MIN( NScripts , Bottom_Script  + Scripts_Per_Line_1 );
         Current_Script := MIN( NScripts , Current_Script + Scripts_Per_Line_1 );

         L             := ( ( Bottom_Script - Top_Script ) +
                            Scripts_Per_Line_1 ) DIV Scripts_Per_Line;

         Display_A_Line(  L , ( L - 1 ) * Scripts_Per_Line + 1 );

         UnEmphasize;

      END;

END   (* Scroll_Up *);

(*----------------------------------------------------------------------*)
(*               Scroll_Down --- Scroll down a line in display          *)
(*----------------------------------------------------------------------*)

PROCEDURE Scroll_Down;

BEGIN (* Scroll_Down *)

   IF ( Top_Script > 1 ) THEN
      BEGIN

         UnEmphasize;
                                   (* Make room for new line *)
         GoToXY( 1 , 1 );
         InsLine;

         Top_Script     := MAX( 1 , Top_Script     - Scripts_Per_Line_1 );
         Bottom_Script  := MAX( 1 , Bottom_Script  - Scripts_Per_Line_1 );
         Current_Script := MAX( 1 , Current_Script - Scripts_Per_Line_1 );

         Display_A_Line( 1 , Top_Script );

         Emphasize;

      END;

END   (* Scroll_Down *);

(*----------------------------------------------------------------------*)
(*                 Move_Up --- Move up a line in display                *)
(*----------------------------------------------------------------------*)

PROCEDURE Move_Up;

BEGIN (* Move_Up *)
                                   (* Scroll down if at top line *)
   IF ( Row = 1 ) THEN
      Scroll_Down
   ELSE
      IF ( ( Current_Script - Scripts_Per_Line ) >= 1 ) THEN
         BEGIN
            Unemphasize;
            DEC( Row );
            Current_Script := MAX( 1 , Current_Script - Scripts_Per_Line );
            Emphasize;
         END;

END   (* Move_Up *);

(*----------------------------------------------------------------------*)
(*                 Move_Down --- Move down a line in display            *)
(*----------------------------------------------------------------------*)

PROCEDURE Move_Down;

BEGIN (* Move_Down *)
                                   (* Scroll up if at bottom line *)

   IF ( Row = Script_Lines_Per_Page ) THEN
      Scroll_Up
   ELSE
      IF ( ( Current_Script + Scripts_Per_Line ) <= NScripts ) THEN
         BEGIN
            Unemphasize;
            INC( Row );
            Current_Script := MIN( NScripts ,
                                   Current_Script + Scripts_Per_Line );
            Emphasize;
         END;

END   (* Move_Down *);

(*----------------------------------------------------------------------*)
(*                  Move_Left --- Move left in script list              *)
(*----------------------------------------------------------------------*)

PROCEDURE Move_Left;

BEGIN (* Move_Left *)

   IF ( Current_Script > 1 ) THEN
      IF ( Column = 1 ) THEN
         IF ( Row = 1 ) THEN
            Move_Up
         ELSE
            BEGIN
               UnEmphasize;
               DEC( Row );
               Column         := Scripts_Per_Line;
               DEC( Current_Script );
               Emphasize;
            END
      ELSE
         BEGIN
            UnEmphasize;
            DEC( Column );
            DEC( Current_Script );
            Emphasize;
         END;

END   (* Move_Left *);

(*----------------------------------------------------------------------*)
(*                  Move_Right --- Move right in script list            *)
(*----------------------------------------------------------------------*)

PROCEDURE Move_Right;

BEGIN (* Move_Right *)

   IF ( Current_Script < NScripts ) THEN
      IF ( Column = Scripts_Per_Line  ) THEN
         IF ( Row = Script_Lines_Per_Page ) THEN
            Move_Down
         ELSE
            BEGIN
               UnEmphasize;
               INC( Row );
               Column         := 1;
               INC( Current_Script );
               Emphasize;
            END
      ELSE
         BEGIN
            UnEmphasize;
            INC( Column );
            INC( Current_Script );
            Emphasize;
         END;

END   (* Move_Right *);

(*----------------------------------------------------------------------*)
(* Sync_Current_Script --- Synchronize positioning for current script   *)
(*----------------------------------------------------------------------*)

PROCEDURE Sync_Current_Script;

BEGIN (* Sync_Current_Script *)

   Row            := ( Current_Script - Top_Script ) DIV
                     Scripts_Per_Line + 1;
   Column         := ( Current_Script - Top_Script ) MOD Scripts_Per_Line + 1;

END   (* Sync_Current_Script *);

(*----------------------------------------------------------------------*)
(*            Search_For_Script --- Search for string in script name    *)
(*----------------------------------------------------------------------*)

PROCEDURE Search_For_Script;

VAR
   Local_Save_5 : Saved_Screen_Ptr;
   I            : INTEGER;
   Found        : BOOLEAN;
   J            : INTEGER;
   K            : INTEGER;
   SName        : STRING[8];

BEGIN (* Search_For_Script *)

   Save_Partial_Screen( Local_Save_5, 10, 10, 65, 14 );

   PibTerm_Window( 1, 1, 80, 25 );

   Draw_Menu_Frame( 10, 10, 65, 14, Menu_Frame_Color, Menu_Title_Color,
                    Menu_Text_Color, 'Search for script');

   GoToXY( 1 , 1 );

   WRITE('String to search for? ');

   SName := '';
   Read_Edited_String( SName );

   IF LENGTH( SName ) > 0 THEN
      Search_String := UpperCase( SName );

   IF LENGTH( Search_String ) <= 0 THEN
      BEGIN
         Restore_Screen( Local_Save_5 );
         EXIT;
      END;

   Found := FALSE;
   I     := SUCC( Current_Script );
   K     := 0;

   REPEAT

      IF ( POS( Search_String , Script_Names^[I] ) > 0 ) THEN
         BEGIN

            Found   := TRUE;

            Restore_Screen( Local_Save_5 );

            UnEmphasize;

            Current_Script := I;

            IF ( ( I < Top_Script ) OR ( I > Bottom_Script ) ) THEN
               BEGIN
                  ReDraw         := TRUE;
                  J              := ( I - 1 ) DIV Scripts_Per_Line + 1;
                  Top_Script     := MAX( 1 , ( J - 1 ) * Scripts_Per_Line );
               END;

            Sync_Current_Script;

         END;

      INC( I );

      IF ( I > NScripts ) THEN
         I := 1;

      INC( K );

   UNTIL ( FOUND OR ( K > NScripts ) );

   IF ( NOT Found ) THEN
      BEGIN
         WRITELN;
         WRITE('String not found.');
         Window_Delay;
         Restore_Screen( Local_Save_5 );
      END;

END   (* Search_For_Script *);

(*----------------------------------------------------------------------*)
(*    Change_Script_Search_Order --- Change order for script search     *)
(*----------------------------------------------------------------------*)

PROCEDURE Change_Script_Search_Order;

VAR
   Search_Menu  : Menu_Type;
   Default      : INTEGER;

CONST
   Quit_Item = 5;

BEGIN (* Change_Script_Search_Order *)

   Default := SUCC( ORD( Script_Search_Order ) );

   Make_And_Display_Menu( Search_Menu, Quit_Item, 10, 30, 0, 0, Default,
                          'Order to search for script: ',
                          'Directory then library;Library then directory;' +
                          'Directory only;Library only;Quit;',
                          TRUE, TRUE, I );

   IF ( I > 0 ) THEN
      BEGIN

         CASE I OF
            1: Script_Search_Order := Dir_Then_Lib;
            2: Script_Search_Order := Lib_Then_Dir;
            3: Script_Search_Order := Dir_Only;
            4: Script_Search_Order := Lib_Only;
         END (* CASE *);

         IF ( I <> Default ) THEN
            Display_Directory_Options;

      END;

END   (* Change_Script_Search_Order *);

(*----------------------------------------------------------------------*)
(*            Compile_The_Script --- Compile a script                   *)
(*----------------------------------------------------------------------*)

PROCEDURE Compile_The_Script;

VAR
   I                 : INTEGER;
   Skip_It           : BOOLEAN;
   Skip_Low          : INTEGER;
   Skip_High         : INTEGER;

BEGIN (* Compile_The_Script *)

   IF ( Script_Lib_Origin^[Current_Script] <> From_Memory ) THEN
      BEGIN (* Compile a script *)

         Script_File_Name := Script_Names^[Current_Script];

         Skip_It   := FALSE;

         Skip_Low  := MAX( Current_Script - 2 , 1 );
         Skip_High := MIN( Current_Script + 2 , NScripts );

         FOR I := Skip_Low TO Skip_High DO
            IF ( Script_Names^[I]      = Script_File_Name ) AND
               ( Script_Lib_Origin^[I] = From_Memory      ) THEN
               Skip_It := TRUE;

         IF ( Script_Lib_Origin^[Current_Script] = From_Library ) THEN
            Script_File_Name := '*' + Script_File_Name;

         Script_File_Name := TRIM( Script_File_Name );

         Compile_Script;

         IF ( ( NOT Skip_It ) AND Script_File_Mode ) THEN
            BEGIN
               INC( NScripts );
               Script_Names^[NScripts]      := Script_Names^[Current_Script];
               Script_Lib_Origin^[NScripts] := From_Memory;
               Sort_Script_Names;
               ReDraw := TRUE;
            END;

         Script_File_Mode := FALSE;

         TextColor     ( Menu_Text_Color );
         TextBackGround( BLACK );

      END   (* Compile a script *)
   ELSE
      Menu_Beep;

END   (* Compile_The_Script *);

(*----------------------------------------------------------------------*)
(*            Get_Script_Names --- Get names of scripts                 *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Script_Names;

BEGIN (* Get_Script_Names *)
                                   (* No scripts yet *)
   NScripts := 0;
                                   (* Get names from library *)

   IF ( Script_Search_Order <> Dir_Only ) THEN
      Get_Library_Names;
                                   (* Get names from disk *)
   Get_Directory_Names;
                                   (* Get names from memory *)
   Get_Compiled_Names;
                                   (* Sort names *)
   Sort_Script_Names;

   Top_Script     := 1;
   Current_Script := 1;
   Column         := 1;
   Row            := 1;
   ReDraw         := TRUE;

END   (* Get_Script_Names *);

(*----------------------------------------------------------------------*)

BEGIN (* Directory_Of_Scripts *)
                                   (* Save current screen *)
   Save_Screen( Local_Save_2 );
                                   (* Get title *)

   Script_Title := 'Script Directory';

                                   (* Script menu display *)

   Draw_Menu_Frame( 1, 1, 80, 24, Menu_Frame_Color, Menu_Title_Color,
                    Menu_Text_Color, Script_Title );

   PibTerm_Window( 2, 2, 78, 23 );

   TextBackGround( BLACK );
                                   (* Options for script menu *)
   Display_Directory_Options;
                                   (* Figure out how many names can *)
                                   (* be stored.                    *)

   RMaxScripts := ( MaxAvail - 4096 ) DIV 10;

   IF ( RmaxScripts >= 512 ) THEN
      Max_Scripts := 512
   ELSE
      Max_Scripts := RMaxScripts;

   IF ( Max_Scripts <= 0 ) THEN
      BEGIN
         GoToXY( 1 , 1 );
         WRITELN('Not enough memory to display scripts.');
         Press_Any;
         Restore_Screen_And_Colors( Local_Save_2 );
         EXIT;
      END
   ELSE
      BEGIN
         GETMEM( Script_Names      , 9 * Max_Scripts );
         GETMEM( Script_Lib_Origin , Max_Scripts     );
      END;
                                   (* == Get script names == *)
   Get_Script_Names;
                                   (* Begin script name display loop *)

   Quit           := FALSE;
   Search_String  := '';

   REPEAT
                                   (* Display current page          *)

      Top_Script     := MAX( MIN( Top_Script , NScripts ) , 1 );
      Bottom_Script  := MIN( Top_Script + Scripts_Per_Page_1 , NScripts );
      Current_Script := MIN( Current_Script , NScripts );

      Sync_Current_Script;

      IF Redraw THEN
         FOR L := 0 TO Script_Lines_Per_Page_1 DO
             Display_A_Line( SUCC( L ) , L * Scripts_Per_Line + 1 );

      Emphasize;
                                   (* Assume no need to redraw screen *)
      Redraw := FALSE;
                                   (* Read command                  *)
      Read_Kbd_Old( Ch );

      IF ( ORD( Ch ) = ESC ) AND ( NOT PibTerm_KeyPressed ) THEN
         Quit := TRUE
      ELSE
         BEGIN

            IF ( ORD( Ch ) = ESC ) THEN
               BEGIN

                  Read_Kbd_Old( Ch );

                  CASE ORD( Ch ) OF

                     L_Arrow:  BEGIN (* Left arrow -- move to left *)
                                  Move_Left;
                               END;

                     R_Arrow:  BEGIN (* Right arrow -- move to right *)
                                  Move_Right;
                               END;

                     U_Arrow:  BEGIN (* Up Arrow -- scroll up one line *)
                                  Move_Up;
                               END   (* Up Arrow *);

                     D_Arrow:  BEGIN (* Down Arrow -- scroll down one line *)
                                  Move_Down;
                               END   (* Down Arrow *);

                     PgUp:     BEGIN (* PgUp -- move up one page *)

                                  IF ( Top_Script > 1 ) THEN
                                     BEGIN
                                        Redraw     := TRUE;
                                        Top_Script := MAX( Top_Script -
                                                           Scripts_Per_Page + 1 , 1 );
                                        Current_Script := MAX( Current_Script -
                                                               Scripts_Per_Page + 1 , 1 );
                                     END;

                               END   (* PgUp *);

                     PgDn:     BEGIN (* PgDn -- move down one page *)

                                  IF ( SUCC( Bottom_Script ) < NScripts ) THEN
                                     BEGIN
                                        Redraw         := TRUE;
                                        Top_Script     := SUCC( Bottom_Script );
                                        Current_Script := MAX( Current_Script +
                                                               Scripts_Per_Page - 1 , 1 );
                                     END;

                               END   (* PgDn *);

                     Home:     BEGIN (* Home -- move to top of buffer *)

                                  Top_Script     := 1;
                                  Current_Script := 1;
                                  Redraw         := TRUE;

                               END   (* Home *);

                     End_Key:  BEGIN (* End -- move to end of buffer *)
                                  Bottom_Script  := NScripts;
                                  Current_Script := NScripts;
                                  Top_Script     := MAX( Bottom_Script -
                                                         Scripts_Per_Page + 1 , 1 );
                                  Redraw         := TRUE;
                               END   (* End *);

                     ELSE                (* Sound bell for bad input *)

                               Menu_Beep;

                  END (* CASE *);

               END (* Ch = ESC *)
            ELSE
               CASE UpCase( Ch ) OF

                  ^M:       BEGIN (* Execute chosen script *)
                               Script_File_Name := Script_Names^[Current_Script];
                               IF ( Script_Lib_Origin^[Current_Script] = From_Library ) THEN
                                  Script_File_Name := '*' + Script_File_Name;
                               Recomp := ( Script_Lib_Origin^[Current_Script] <>
                                           From_Memory );
                               Execute_Script( Recomp, Quit );
                               TextColor( Menu_Text_Color );
                               TextBackGround( BLACK );
                            END   (* Execute chosen script *);

                  'A':      BEGIN
                               Unload_All_Scripts;
                               Get_Script_Names;
                               TextColor( Menu_Text_Color );
                               TextBackGround( BLACK );
                            END;

                  'C':      Compile_The_Script;

                  'L':      BEGIN (* Learn a script *)
                               Learn_Script;
                               TextColor( Menu_Text_Color );
                               TextBackGround( BLACK );
                               Display_Directory_Options;
                               Quit := ( Script_Learn_Mode );
                            END   (* Learn a script *);

                  'O':      BEGIN (* Change script search order *)
                               Change_Script_Search_Order;
                            END   (* Change script search order *);

                  'S':      BEGIN (* Search for script *)
                               Search_For_Script;
                            END   (* Search for script *);

                  'U':      BEGIN (* Unload a script *)

                               Script_File_Name := TRIM( Script_Names^[Current_Script] );

                               IF ( Script_Lib_Origin^[Current_Script] = From_Memory) THEN
                                  BEGIN
                                     Unload_Script;
                                     FOR I := SUCC( Current_Script ) TO NScripts DO
                                         BEGIN
                                            Script_Names^[I-1]      :=
                                               Script_Names^[I];
                                            Script_Lib_Origin^[I-1] :=
                                               Script_Lib_Origin^[I];
                                         END;
                                     TextColor( Menu_Text_Color );
                                     TextBackGround( BLACK );
                                     IF ( Current_Script = NScripts ) THEN
                                        Move_Left;
                                     NScripts := MAX( PRED( NScripts ) , 0 );
                                     ReDraw   := TRUE;
                                  END
                               ELSE
                                  Menu_Beep;

                            END   (* Unload a script *);

                  ELSE             (* Sound bell for bad input *)

                            Menu_Beep;

               END (* CASE *);

         END;

   UNTIL Quit;

   MyFreeMem( Script_Names      , 9 * Max_Scripts );
   MyFreeMem( Script_Lib_Origin , Max_Scripts     );

   Restore_Screen_And_Colors( Local_Save_2 );

END   (* Directory_Of_Scripts *);

(*----------------------------------------------------------------------*)
(*             Execute_Keyboard_Command --- Execute keyboard command    *)
(*----------------------------------------------------------------------*)

PROCEDURE Execute_Keyboard_Command;

VAR
   Save_C25 : ARRAY[1..132] OF CHAR;
   Save_A25 : ARRAY[1..132] OF BYTE;
   J        : INTEGER;
   I        : INTEGER;
   Ch       : CHAR;
   Save_WX1 : INTEGER;
   Save_WX2 : INTEGER;
   Save_WY1 : INTEGER;
   Save_WY2 : INTEGER;
   Save_X   : INTEGER;
   Save_Y   : INTEGER;

LABEL 1;

BEGIN (* Execute_Keyboard_Command *)

   Save_Do_Status_Time := Do_Status_Time;
   Do_Status_Time      := FALSE;

                                   (* Save window positions *)

   Upper_Left( Save_WX1 , Save_WY1 );

   Save_WX2 := Lower_Right_Column;
   Save_WY2 := Lower_Right_Row;
   Save_X   := WhereX;
   Save_Y   := WhereY;

   PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line );

   FOR I := 1 TO Max_Screen_Col DO
      ReadCXY( Save_C25[I], I, Max_Screen_Line, Save_A25[I] );

                                   (* Prompt for command *)

   WriteSXY( 'Command: ' + DUPL( ' ' , Max_Screen_Col - 9 ), 1, Max_Screen_Line,
             Status_Line_Attr );

   TextColor     ( Status_Line_Attr AND $0F );
   TextBackGround( Status_Line_Attr SHR 4   );

   GoToXY( 10 , Max_Screen_Line );

                                   (* Clear previous text if requested *)

   IF ( NOT Use_Prev_Key_Text ) THEN
      Command_Key_Text := '';

   Ch := Edit_String( Command_Key_Text, 255, 10, 10, Max_Screen_Line,
                      Max_Screen_Col - 11, FALSE, 0 );

                                   (* If not quit, then parse command *)
   IF ( Ch <> CHR( ESC ) ) THEN
      BEGIN
                                   (* Push down script stack      *)
         Push_Current_Script;
                                   (* Copy command to script line *)

         Script_Line := Command_Key_Text;

                                   (* Allocate script buffer *)

         Script_Buffer_Size := 256;
         GetMem( Script_Buffer , Script_Buffer_Size );

                                   (* Make sure we got it *)

         IF ( Script_Buffer = NIL ) THEN
            BEGIN
               WriteSXY( '>>> Not enough memory to process command <<<'
                         + Dupl( ' ' , Max_Screen_Col - 44 ), 1, Max_Screen_Line,
                         Status_Line_Attr );
               Press_Any;
               Pop_Current_Script;
               GOTO 1;
            END;
                                   (* Current offset in script buffer *)

         Script_Buffer_Pos     := 0;

                                   (* No procedures yet defined     *)

         Script_Proc_Count     := 0;
         Script_Proc_Start     := 0;

                                   (* All stacks empty              *)

         Script_Repeat_Level   := 0;
         Script_If_Level       := 0;
         Script_While_Level    := 0;
         Script_Case_Level     := 0;
         Script_For_Level      := 0;
         Script_Proc_Level     := 0;

                                   (* Script line number            *)

         Script_Line_Number    := 0;

                                   (* No variables yet              *)

         Script_Variable_Kount    := 2;
         Script_Variable_MaxKount := 2;
         Script_Variable_Count    := 2;
         Import_Count             := 0;
         Script_Debug_Mode        := FALSE;

                                   (* Check if legitimate command   *)

         Extract_Script_Command( OK_Script_Command );

                                   (* If so, generate code for it   *)
         IF OK_Script_Command THEN
            Parse_Script_Command  ( OK_Script_Command );

                                   (* Check if stacks empty.  If not,  *)
                                   (* error from unclosed loop.        *)

         OK_Script_Command := OK_Script_Command           AND
                              ( Script_Repeat_Level = 0 ) AND
                              ( Script_If_Level     = 0 ) AND
                              ( Script_Case_Level   = 0 ) AND
                              ( Script_For_Level    = 0 ) AND
                              ( Script_While_Level  = 0 ) AND
                              ( Script_Proc_Level   = 0 );

         IF ( NOT Ok_Script_Command ) THEN
            BEGIN

               WriteSXY( '>>> Bad Command <<<' + Dupl( ' ' , Max_Screen_Col - 19 ),
                         1, Max_Screen_Line, Status_Line_Attr );

               Press_Any;

               Pop_Current_Script;

            END
         ELSE
            BEGIN
                                   (* Drop exit into table *)

               Copy_Byte_To_Buffer( ORD( ExitSy ) );

                                   (* Store command as script *)

               Script_Short_Name := '!' + Script_Command_Token;

               Store_Script( Current_Script_Num );

                                   (* Allocate variables *)

               Allocate_Script_Variables;

                                   (* Now point to start of buffer     *)

               Script_Buffer_Pos       := 0;
               Script_File_Mode        := TRUE;
               Script_Command_Key_Mode := TRUE;

            END;

      END;

                                   (* Restore status line *)
1:
   FOR I := 1 TO Max_Screen_Col DO
      WriteCXY( Save_C25[I], I, Max_Screen_Line, Save_A25[I] );

                                   (* Restore colors     *)
   Reset_Global_Colors;
                                   (* Restore old window *)

   PibTerm_Window( Save_WX1, Save_WY1, Save_WX2, Save_WY2 );
   GoToXY( Save_X, Save_Y );

                                   (* Ensure status line updated *)

   Do_Status_Time := Save_Do_Status_Time;

   IF Do_Status_Time THEN
      BEGIN
         Current_Status_Time := -1;
         Update_Status_Line;
      END;

END   (* Execute_Keyboard_Command *);

(*----------------------------------------------------------------------*)

BEGIN (* Process_Script *)
                                   (* If script file name defined,   *)
                                   (* then we're doing it from the   *)
                                   (* command line or another script *)

   Use_Script_Library       := FALSE;
   Script_File_Name         := Script_FName;
   Script_ComLet            := UpCase( Script_ComLet );
   Script_File_Name_Given   := ( LENGTH( Script_File_Name ) > 0 );

                                   (* Choose function *)
   IF Script_Learn_Mode THEN
      Learn_Script
   ELSE
      CASE Script_ComLet OF

         'C':  BEGIN
                  Save_Script_File_Mode := Script_File_Mode;
                  Push_Current_Script;
                  Compile_Script;
                  Pop_Current_Script;
                  Script_File_Mode := Save_Script_File_Mode;
               END;
         'K':  Execute_Keyboard_Command;
         'L':  Learn_Script;
         'U':  Unload_Script;
         ELSE  BEGIN
                  IF ( NOT Script_Learn_Mode ) THEN
                     Execute_Script( FALSE , Got_Script )
                  ELSE
                     Got_Script := FALSE;
                  IF ( ( NOT Got_Script ) AND
                       Attended_Mode      AND
                       ( NOT Script_File_Name_Given ) ) THEN
                     Directory_Of_Scripts;
               END;

      END (* CASE *);

END   (* Process_Script *);
