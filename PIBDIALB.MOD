(*----------------------------------------------------------------------*)
(*            Revise_Dialing_Prefix --- Revise dialing prefix           *)
(*----------------------------------------------------------------------*)

PROCEDURE Revise_Dialing_Prefix;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Revise_Dialing_Prefix                                *)
(*                                                                      *)
(*     Purpose:    Handles revision of dialing prefix or setting of     *)
(*                 default prefix.                                      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Revise_Dialing_Prefix;                                        *)
(*                                                                      *)
(*     Calls:   Save_Screen                                             *)
(*              Draw_Menu_Frame                                         *)
(*              Restore_Screen                                          *)
(*              Get_New_Dialing_Prefix                                  *)
(*              Get_New_Default_Prefix                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Prefix_Menu       : Menu_Type;
   Default           : INTEGER;
   Choice            : INTEGER;
   Full_Name         : AnyStr;
   Phone_Prefix_File : Text_File;

(*----------------------------------------------------------------------*)

PROCEDURE Get_New_Dialing_Prefix;

VAR
   I:       INTEGER;
   Done:    BOOLEAN;
   Pchar:   CHAR;
   Changed: BOOLEAN;

BEGIN (* Get_New_Dialing_Prefix *)

                                   (* Bring up revision window *)

   Draw_Titled_Box( Local_Save_2, 10, 2, 75, 10, 'Revise Dialing Prefix');

   PibTerm_Window( 11, 3, 74, 9 );

   Done    := FALSE;
   Changed := FALSE;

   REPEAT

      TextColor( Menu_Text_Color_2 );

      GoToXY( 1 , 2 );

      FOR I := 1 TO Max_Phone_Prefixes DO
         BEGIN
            ClrEol;
            TextColor( Menu_Text_Color_2 );
            WRITE  ( ' ', Phone_Prefix_Chars[I], ' = ');
            TextColor( Menu_Text_Color );
            WRITELN( Phone_Prefix_Nos[I] );
         END;

      WRITELN(' ');

      TextColor( Menu_Text_Color_2 );

      REPEAT
         GoToXY( 2 , WhereY );
         WRITE('Enter character to revise: ');
         ClrEol;
         Read_Kbd( Pchar );
         IF NOT ( Pchar IN ['+','-','!','@','#',CHR(CR),^[] ) THEN
            Menu_Beep;
      UNTIL( Pchar IN ['+','-','!','@','#',CHR(CR),^[] );

      IF ( ( Pchar <> CHR(CR) ) AND ( Pchar <> CHR( ESC ) ) ) THEN
         BEGIN
            GoToXY( 2 , WhereY );
            WRITE('Enter new definition for ');
            TextColor( Menu_Text_Color );
            WRITE(Pchar);
            TextColor( Menu_Text_Color_2 );
            WRITE(':');
            ClrEol;

            I       := POS( Pchar , '+-!@#' );
            SNumber := Phone_Prefix_Nos[I];

            TextColor( Menu_Text_Color );
            Read_Edited_String( SNumber );
            WRITELN;

            Phone_Prefix_Nos[ I ] := Trim( Read_Ctrls( SNumber ) );

            Changed := TRUE;

         END
      ELSE
         Done := TRUE;

   UNTIL( Done );
                                   (* Rewrite prefix file if changed *)
   TextColor( Menu_Text_Color );

   IF Changed THEN
      BEGIN

         Add_Path( Prefix_File_Name, Home_Dir, Full_Name );

         ASSIGN( Phone_Prefix_File , Full_Name );
                   (*!I-*)
         REWRITE( Phone_Prefix_File );
                   (*!I+*)

         Clear_Window;

         IF Int24Result <> 0 THEN
            WRITELN(' Can''t create revised ',Full_Name)
         ELSE
            BEGIN

               WRITELN(' Writing revised dialing prefix file ',Full_Name,'.');

               FOR I := 1 TO Max_Phone_Prefixes DO
                  WRITELN( Phone_Prefix_File ,
                           Write_Ctrls( Phone_Prefix_Nos[ I ] ) );

               CLOSE( Phone_Prefix_File );

            END;

         Window_Delay;

      END;

   Restore_Screen( Local_Save_2 );

END   (* Get_New_Dialing_Prefix *);

(*----------------------------------------------------------------------*)

PROCEDURE Get_New_Default_Prefix;

VAR
   Done:  BOOLEAN;
   Pchar: CHAR;

BEGIN (* Get_New_Default_Prefix *)
                                   (* Bring up revision window *)

   Draw_Titled_Box( Local_Save_2, 10, 10, 75, 15, 'Set Default Dialing Prefix');

   PibTerm_Window( 11, 11, 74, 14 );

   Done := FALSE;

   REPEAT
      TextColor( Menu_Text_Color_2 );
      GoToXY( 1 , WhereY );
      WRITE('Enter default prefix character: ');
      ClrEol;
      Read_Kbd( Pchar );
      TextColor( Menu_Text_Color );
      WRITE( Pchar );
      IF NOT ( Pchar IN ['+','-','!','@','#',CHR(CR),^[] ) THEN
         Menu_Beep;
   UNTIL( Pchar IN ['+','-','!','@','#',CHR(CR),^[] );

   IF ( ( Pchar <> CHR(CR) ) AND ( Pchar <> CHR( ESC ) ) ) THEN
      BEGIN
         Default_Prefix := Pchar;
         WRITELN;
         WRITELN('New default prefix is ',Default_Prefix);
      END
   ELSE
      BEGIN
         Default_Prefix := ' ';
         WRITELN;
         WRITELN('No default prefix');
      END;

   Window_Delay;

   Restore_Screen( Local_Save_2 );

END   (* Get_New_Default_Prefix *);

(*----------------------------------------------------------------------*)

PROCEDURE Get_New_Default_Postfix;

VAR
   Done:  BOOLEAN;
   Pchar: CHAR;

BEGIN (* Get_New_Default_Postfix *)
                                   (* Bring up revision window *)

   Draw_Titled_Box( Local_Save_2, 10, 10, 75, 15, 'Set Default Dialing Postfix');

   PibTerm_Window( 11, 11, 74, 14 );

   Done := FALSE;

   REPEAT
      TextColor( Menu_Text_Color_2 );
      GoToXY( 1 , WhereY );
      WRITE('Enter default postfix character: ');
      ClrEol;
      Read_Kbd( Pchar );
      TextColor( Menu_Text_Color );
      WRITE( Pchar );
      IF NOT ( Pchar IN ['+','-','!','@','#',CHR(CR),^[] ) THEN
         Menu_Beep;
   UNTIL( Pchar IN ['+','-','!','@','#',CHR(CR),^[] );

   IF ( ( Pchar <> CHR(CR) ) AND ( Pchar <> CHR( ESC ) ) ) THEN
      BEGIN
         Default_PostFix := Pchar;
         WRITELN;
         WRITELN('New default postfix is ',Default_PostFix);
      END
   ELSE
      BEGIN
         Default_PostFix := ' ';
         WRITELN;
         WRITELN('No default postfix');
      END;

   Window_Delay;

   Restore_Screen( Local_Save_2 );

END   (* Get_New_Default_Postfix *);

(*----------------------------------------------------------------------*)

BEGIN (* Revise_Dialing_Prefix *)

   Default := 1;
                                   (* Display menu and get choice *)

   Make_And_Display_Menu( Prefix_Menu, 3, 11, 30, 0, 0, Default,
                          'Choose revision function: ',
                          'Revise definition string;Set default prefix;' +
                          'Set default postfix;',
                          TRUE, TRUE, Choice );

   CASE Choice OF
      1: Get_New_Dialing_Prefix;
      2: Get_New_Default_Prefix;
      3: Get_New_Default_Postfix;
      ELSE ;
   END (* Case *);

END   (* Revise_Dialing_Prefix *);

(*----------------------------------------------------------------------*)
(*            Clear_Dialing_Entry --- Clear dialing entry               *)
(*----------------------------------------------------------------------*)

PROCEDURE Clear_Dialing_Entry;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Clear_Dialing_Entry                                  *)
(*                                                                      *)
(*     Purpose:    Clear out entry in dialing directory                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Clear_Dialing_Entry;                                          *)
(*                                                                      *)
(*     Calls:   CopySToA                                                *)
(*              Menu_Beep                                               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I       : INTEGER;
   J       : INTEGER;
   SNumber : STRING[10];
   Qerr    : BOOLEAN;

BEGIN (* Clear_Dialing_Entry *)

                                   (* Bring up clear entry window *)

   Draw_Titled_Box( Local_Save_2, 10, 2, 65, 5, 'Clear Entry');

   PibTerm_Window( 11, 3, 64, 4 );

   GoToXY( 1 , 1 );
                                   (* Get entry to clear out *)

   TextColor( Menu_Text_Color_2 );
   WRITE('Enter # of entry to clear: ');

   TextColor( Menu_Text_Color );
   SNumber := '';
   Read_Edited_String( SNumber );

   I    := 0;
   Qerr := FALSE;

   FOR J := 1 TO LENGTH( SNumber ) DO
      IF SNumber[J] IN ['0'..'9'] THEN
         I := I * 10 + ORD(SNumber[J]) - ORD('0')
      ELSE
         Qerr := TRUE;

                                   (* Check if legitimate *)
   IF ( NOT Qerr ) AND
      ( I > 0 ) AND ( I <= Dialing_Dir_Size ) THEN
      BEGIN
                                   (* If so, clear it     *)
         WITH Phone_Entry_Data DO
            BEGIN

               CopyStoA( Dupl( '-' , 25 ) , Phone_Name ,   25 );
               CopyStoA( ' # ### ###-####' , Phone_Number , 15 );

               Phone_Parity     := ' ';
               Phone_Baud       := '     ';
               Phone_DataBits   := ' ';
               Phone_StopBits   := ' ';
               Phone_Echo       := ' ';
               Phone_BackSpace  := ' ';
               Phone_LineFeed   := ' ';
               Phone_Term_Type  := ' ';
               Phone_Trans_Type := '  ';
               Phone_Script     := '         ';
               Phone_Last_Date  := '        ';
               Phone_Last_Time  := '        ';

            END;

         Update_Phone_File( Phone_Entry_Data , I );

      END
   ELSE
      Menu_Beep;

   Restore_Screen( Local_Save_2 );

END   (* Clear_Dialing_Entry *);

(*----------------------------------------------------------------------*)
(*            Extract_Dialing_Entry --- Get number to dial              *)
(*----------------------------------------------------------------------*)

PROCEDURE Extract_Dialing_Entry(     I            : INTEGER;
                                 VAR Entry_String : AnyStr   );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Extract_Dialing_Entry                                *)
(*                                                                      *)
(*     Purpose:    Read entry from dialing directory file               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Extract_Dialing_Entry(     I            : INTEGER;            *)
(*                               VAR Entry_String : AnyStr   );         *)
(*                                                                      *)
(*           I --- If  > 0, then entry to dial;                         *)
(*                 If <= 0, then get entry from input.                  *)
(*           Entry_String --- Full text of dialing entry                *)
(*                                                                      *)
(*     Calls:   Reset_Comm_Params                                       *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The current communications parameters are reset to match      *)
(*        present in the selected dialing directory entry.              *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   OK_Number: BOOLEAN;
   Ch       : CHAR;
   IX       : INTEGER;
   IY       : INTEGER;
   Quit     : BOOLEAN;
   Use_DP   : BOOLEAN;
   J        : INTEGER;
   Ext_Num  : BOOLEAN;

BEGIN (* Extract_Dialing_Entry *)
                                   (* Initialize dialing entry *)
   SNumber      := '';
   Prefix_Str   := '';
   Postfix_Str  := '';
   Entry_String := '';

   Quit       := FALSE;
   Use_DP     := FALSE;
   Ext_Num    := ( I <= 0 );
                                   (* We entered with first character *)
                                   (* in Dial_Func if I <= 0.         *)

   IF Ext_Num THEN
      Read_Number_Or_ESC( Dial_Func, Xpos, 5, SNumber, Prefix_Str, Postfix_Str,
                          Quit, I, Entry_String )
   ELSE
      BEGIN
         Use_DP := Default_Prefix <> ' ';
         STR( I , Entry_String );
      END;
                                   (* No number entered -- quit *)

   IF ( Quit OR ( I <= 0 ) OR ( I > Dialing_Dir_Size ) ) THEN
      BEGIN
         Entry_String := '';
         EXIT;
      END;
                                   (* Also quit if empty dialing entry    *)

   IF ( Dialing_Directory^[I].Phone_Name = Empty_Name ) THEN
      BEGIN
         Entry_String := '';
         EXIT;
      END;
                                   (* Extract phone number from directory *)

   Phone_Entry_Data   := Dialing_Directory^[I];
   Phone_Number       := Phone_Entry_Data.Phone_Number;
   Phone_Entry_Number := I;

                                   (* Use default dialing prefix if       *)
                                   (* number is > 7 digits.               *)
   IF Use_DP THEN
      BEGIN

         IX := 0;

         FOR J := 1 TO LENGTH( Phone_Number ) DO
            IF ( Phone_Number[J] IN ['0'..'9'] ) THEN
               IX := IX + 1;

         IF ( IX > 7 ) THEN
            BEGIN

               IF ( Default_Prefix <> ' ' ) THEN
                  BEGIN
                     Prefix_Str   := Phone_Prefix_Nos[ POS( Default_Prefix,
                                                       '+-!@#' ) ];
                     Entry_String := Default_Prefix + Entry_String;
                  END;
                                   (* Add in default postfix if any *)

               IF ( Default_Postfix <> ' ' ) THEN
                  BEGIN
                     Postfix_Str  := Phone_Prefix_Nos[ POS( Default_Postfix,
                                                       '+-!@#' ) ];
                     Entry_String := Entry_String + Default_Postfix;
                  END;

            END;

      END;

   Done := TRUE;
                                   (* If session not already in progress, *)
                                   (* change comm parms to match dialing  *)
                                   (* directory entry.                    *)

   IF ( NOT Dialer_Carrier_Detect ) THEN
      Reset_Comm_Params( Phone_Entry_Data , I );

END   (* Extract_Dialing_Entry *);

(*----------------------------------------------------------------------*)
(*     Do_Manual_Dial --- Get number to dial from keyboard entry        *)
(*----------------------------------------------------------------------*)

FUNCTION Do_Manual_Dial : BOOLEAN;

VAR
   Local_Save_5 : Saved_Screen_Ptr;
   Ch           : CHAR;
   Quit         : BOOLEAN;
   J            : INTEGER;
   Entry_Str    : AnyStr;
   I            : INTEGER;

BEGIN (* Do_Manual_Dial *)

   Draw_Titled_Box( Local_Save_5, 10, 10, 65, 13, 'Manual Dial');

   PibTerm_Window( 11, 11, 64, 12 );

   GoToXY( 1 , 1 );

   Prefix_Str  := '';
   Postfix_Str := '';
   SNumber     := '';

   TextColor( Menu_Text_Color_2 );
   WRITE('Number to dial? ');
   Read_Kbd( Ch );

   IF ( ( Ch = CHR( CR ) ) OR ( Ch = CHR( ESC ) ) ) THEN
      BEGIN
         SNumber := '';
         Quit    := TRUE;
      END
   ELSE
      Read_Number_Or_ESC( Ch , WhereX - 1, 40, SNumber, Prefix_Str, PostFix_Str,
                          Quit, J, Entry_Str );

   Restore_Screen( Local_Save_5 );

   IF ( NOT Quit ) AND ( LENGTH( SNumber ) > 0 ) THEN
      BEGIN
         Phone_Number       := SNumber;
         Phone_Entry_Number := -1;
         FOR I := 1 TO 25 DO
            Phone_Entry_Data.Phone_Name[I] := ' ';
         FOR I := 1 TO 15 DO
            Phone_Entry_Data.Phone_Number[I] := ' ';
         FOR I := 1 TO 9 DO
            Phone_Entry_Data.Phone_Script[I] := ' ';
         J := 0;
         FOR I := ( 16 - LENGTH( SNumber ) ) TO 15 DO
            BEGIN
               J := J + 1;
               Phone_Entry_Data.Phone_Number[I] := SNumber[J];
            END;
         Do_Manual_Dial := TRUE;
         Manual_Dial    := TRUE;
      END
   ELSE
      Do_Manual_Dial := FALSE;

END   (* Do_Manual_Dial *);

(*----------------------------------------------------------------------*)
(*     Get_List_Of_Phone_Numbers --- Get list of entries to dial        *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_List_Of_Phone_Numbers;

VAR
   No_Num  : BOOLEAN;
   SS_Num  : AnyStr;

BEGIN (* Get_List_Of_Phone_Numbers *)

   N_Dial_Nos := 0;
   I_Dial_Nos := 0;
   No_Num     := FALSE;

   WHILE ( ( N_Dial_Nos < Max_Dial_Nos ) AND ( NOT No_Num ) ) DO
      BEGIN
                                   (* Increment dialing number count *)

         INC( N_Dial_Nos );

                                   (* Read in number *)

         TextColor( Menu_Text_Color_2 );
         WRITE('Select entry number ');
         TextColor( Menu_Text_Color   );
         WRITE(N_Dial_Nos:2);
         TextColor( Menu_Text_Color_2 );
         WRITE(': ');

         TextColor( Menu_Text_Color );
         SS_Num := '';
         Read_Edited_String( SS_Num );
         WRITELN;
                                   (* Empty line terminates list entry *)

         IF ( LENGTH( SS_Num ) <= 0 ) THEN
            BEGIN
               No_Num     := TRUE;
               DEC( N_Dial_Nos );
            END
                                   (* ESC evicts current list          *)

         ELSE IF ( SS_Num = CHR( ESC ) ) THEN
            BEGIN
               No_Num     := TRUE;
               N_Dial_Nos := 0;
            END

         ELSE
                                   (* Store number *)

            Dial_Nos[N_Dial_Nos].Number := SS_Num;
            Dial_Nos[N_Dial_Nos].Tries  := 0;

      END;

END   (* Get_List_Of_Phone_Numbers *);

(*----------------------------------------------------------------------*)
(*            Sort_Dialing_Directory --- Sort dialing entries           *)
(*----------------------------------------------------------------------*)

PROCEDURE Sort_Dialing_Directory;

TYPE
   Saved_Chars_Type = ARRAY[1..1] OF CHAR;
   Saved_Chars_Ptr  = ^Saved_Chars_Type;

VAR
   I            : INTEGER;
   J            : INTEGER;
   D            : INTEGER;
   Key          : INTEGER;
   Ascending    : BOOLEAN;
   Hold_Entry   : Phone_Number_Record;
   Sort_Menu    : Menu_Type;
   Local_Save_5 : Saved_Screen_Ptr;
   Empty_Char   : CHAR;
   Saved_Chars  : Saved_Chars_Ptr;
   Hold_Char    : CHAR;

CONST
   Quit_Item    = 7;

(*----------------------------------------------------------------------*)

FUNCTION Comp : BOOLEAN;

VAR
   Komp : BOOLEAN;

BEGIN (* Comp *)

   CASE Key OF
      1:   Komp := Hold_Entry.Phone_Name      < Dialing_Directory^[J].Phone_Name;
      2:   Komp := Hold_Entry.Phone_Number    < Dialing_Directory^[J].Phone_Number;
      3:   Komp := Hold_Entry.Phone_Baud      < Dialing_Directory^[J].Phone_Baud;
      4:   Komp := Hold_Entry.Phone_Term_Type < Dialing_Directory^[J].Phone_Term_Type;
      5:   Komp := Hold_Entry.Phone_Script    < Dialing_Directory^[J].Phone_Script;
      6:   IF Hold_Entry.Phone_Last_Date <> Dialing_Directory^[J].Phone_Last_Date THEN
              Komp := Hold_Entry.Phone_Last_Date < Dialing_Directory^[J].Phone_Last_Date
           ELSE
              Komp := Hold_Entry.Phone_Last_Time < Dialing_Directory^[J].Phone_Last_Time;
   END (* CASE *);

   IF ( NOT Ascending ) THEN
      Comp := Komp
   ELSE
      Comp := ( NOT Komp );

END   (* Comp *);

(*----------------------------------------------------------------------*)

BEGIN (* Sort_Dialing_Directory *)
                                   (* Display items to revise *)

   Make_And_Display_Menu( Sort_Menu, Quit_Item, 10, 30, 30, 0, Quit_Item,
                          'Choose field to sort on: ',
                          'Name;Number;Baud Rate;Terminal Type;Script Name;' +
                          'Date/Time;Quit;',
                          TRUE, TRUE, Key );

   IF ( Key > 0 ) AND ( Key <> Quit_Item ) THEN
      BEGIN

         Make_And_Display_Menu( Sort_Menu, 2, 10, 30, 30, 0, 1,
                          'Sort order: ',
                          'A)scending;D)escending;',
                          FALSE, TRUE, I );

         Ascending := ( I = 1 );

         Draw_Titled_Box( Local_Save_5, 10, 10, 65, 13, '' );

         IF Ascending THEN
            Empty_Char := CHR( 255 )
         ELSE
            Empty_Char := CHR( 0 );

         GETMEM( Saved_Chars , Dialing_Dir_Size );

         IF ( Saved_Chars = NIL ) THEN
            BEGIN
               WRITE('Not enough room to perform sort.');
               Press_Any;
               Restore_Screen( Local_Save_5 );
               EXIT;
            END
         ELSE
            WRITE( 'Sorting ... ');

         FOR I := 1 TO Dialing_Dir_Size DO
            CASE Key OF
               1:  BEGIN
                      Saved_Chars^[I] := Dialing_Directory^[I].Phone_Name[1];
                      IF ( Dialing_Directory^[I].Phone_Name = Empty_Name ) THEN
                         Dialing_Directory^[I].Phone_Name[1] := Empty_Char;
                   END;
               2:  BEGIN
                      Saved_Chars^[I] := Dialing_Directory^[I].Phone_Number[1];
                      IF ( Dialing_Directory^[I].Phone_Name = Empty_Name ) THEN
                         Dialing_Directory^[I].Phone_Number[1] := Empty_Char;
                   END;
               3:  BEGIN
                      Saved_Chars^[I] := Dialing_Directory^[I].Phone_Baud[1];
                      IF ( Dialing_Directory^[I].Phone_Name = Empty_Name ) THEN
                         Dialing_Directory^[I].Phone_Baud[1] := Empty_Char;
                   END;
               4:  BEGIN
                      Saved_Chars^[I] := Dialing_Directory^[I].Phone_Term_Type;
                      IF ( Dialing_Directory^[I].Phone_Name = Empty_Name ) THEN
                         Dialing_Directory^[I].Phone_Term_Type := Empty_Char;
                   END;
               5:  BEGIN
                      Saved_Chars^[I] := Dialing_Directory^[I].Phone_Script[1];
                      IF ( Dialing_Directory^[I].Phone_Name = Empty_Name ) THEN
                         Dialing_Directory^[I].Phone_Script[1] := Empty_Char;
                   END;
               6:  BEGIN
                      Saved_Chars^[I] := Dialing_Directory^[I].Phone_Last_Date[1];
                      IF ( Dialing_Directory^[I].Phone_Name = Empty_Name ) THEN
                         Dialing_Directory^[I].Phone_Last_Date[1] := Empty_Char;
                   END;
            END (* CASE *);

                                   (* This is a shell sort *)
         D := Dialing_Dir_Size;

         WHILE( D > 1 ) DO
            BEGIN

               IF ( D < 5 ) THEN
                  D := 1
               ELSE
                  D := TRUNC( 0.45454 * D );

               FOR I := ( Dialing_Dir_Size - D ) DOWNTO 1 DO
                  BEGIN

                     Hold_Entry := Dialing_Directory^[I];
                     Hold_Char  := Saved_Chars^[I];
                     J          := I + D;

                     WHILE( Comp AND ( J <= Dialing_Dir_Size ) ) DO
                        BEGIN
                           Dialing_Directory^[J-D] := Dialing_Directory^[J];
                           Saved_Chars^[J-D]       := Saved_Chars^[J];
                           J                       := J + D;
                        END;

                     Dialing_Directory^[J-D] := Hold_Entry;
                     Saved_Chars^[J-D]       := Hold_Char;

                  END;

            END;

         FOR I := 1 TO Dialing_Dir_Size DO
            CASE Key OF
               1:  Dialing_Directory^[I].Phone_Name[1]      := Saved_Chars^[I];
               2:  Dialing_Directory^[I].Phone_Number[1]    := Saved_Chars^[I];
               3:  Dialing_Directory^[I].Phone_Baud[1]      := Saved_Chars^[I];
               4:  Dialing_Directory^[I].Phone_Term_Type    := Saved_Chars^[I];
               5:  Dialing_Directory^[I].Phone_Script[1]    := Saved_Chars^[I];
               6:  Dialing_Directory^[I].Phone_Last_Date[1] := Saved_Chars^[I];
            END (* CASE *);

         MyFreeMem( Saved_Chars , Dialing_Dir_Size );

         WRITE('Done');

         Window_Delay;

         Restore_Screen( Local_Save_5 );

         Any_Dialing_Changes := TRUE;

      END;

END   (* Sort_Dialing_Directory *);

(*----------------------------------------------------------------------*)
(*        Dialing_Page_Title --- Display dialing window title           *)
(*----------------------------------------------------------------------*)

PROCEDURE Dialing_Page_Title;

BEGIN (* Dialing_Page_Title *)

   IF First_Display_Time THEN
      Draw_Menu_Frame( 1, 1, 79, 24, Menu_Frame_Color, Menu_Title_Color,
                       Menu_Text_Color, 'Dialing Directory' );

   First_Display_Time := FALSE;

   PibTerm_Window( 2, 2, 78, 23 );
                                   (* Display title                *)
   GoToXY( 1 , 1 );
   ClrEol;

   TextColor( Menu_Text_Color_2 );
   TextBackGround( BLACK );

   CASE Dialing_Page OF
      1:  BEGIN
             WRITELN('No.  --------- Name ----------',
                     '   --- Number ---   -Baud- -Bits- -Par- -Stp- ');
          END;
      2:  BEGIN
             WRITELN('No.  --------- Name ----------',
                     ' -Echo-  -BS-  -Add LF-  -Terminal-    -Xfer- ');
          END;
      3:  BEGIN
             WRITELN('No.  --------- Name ----------',
                     '  -Script-  -Last Date-  -Last Time-');
          END;

   END (* CASE *);

   PibTerm_Window( 2, 3, 78, 23 );

   TextColor( Menu_Text_Color );

END   (* Dialing_Page_Title *);

(*----------------------------------------------------------------------*)
(*        Display_Dialing_Window --- Display dialing window stuff       *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Dialing_Window;

BEGIN (* Display_Dialing_Window *)

   Dialing_Page_Title;

   GoToXY( 1 , N_Nos + 2 );
   TextColor( Menu_Text_Color_2 );
   WRITE  (' -->');
   TextColor( Menu_Text_Color );
   WRITE  ('     R');
   TextColor( Menu_Text_Color_2 );
   WRITE  (' Revise entry   ');
   TextColor( Menu_Text_Color );
   WRITE  (' P');
   TextColor( Menu_Text_Color_2 );
   WRITE  (' Revise prefix   ');
   TextColor( Menu_Text_Color );
   WRITE  (' C');
   TextColor( Menu_Text_Color_2 );
   WRITE  (' Clear entry');
   TextColor( Menu_Text_Color );
   WRITE  ('    Q');
   TextColor( Menu_Text_Color_2 );
   WRITELN(' Redial');

   TextColor( Menu_Text_Color );
   WRITE  ('         PgUp/PgDn');
   TextColor( Menu_Text_Color_2 );
   WRITE  (' Page');
   TextColor( Menu_Text_Color );
   WRITE  ('    Esc');
   TextColor( Menu_Text_Color_2 );
   WRITE  (' Exit        ');
   TextColor( Menu_Text_Color );
   WRITE  ('   //', ^[, '/', ^Z );
   TextColor( Menu_Text_Color_2 );
   WRITE  (' Scroll');
   TextColor( Menu_Text_Color );
   WRITE  ('   H');
   TextColor( Menu_Text_Color_2 );
   WRITELN(' Hang up');

   TextColor( Menu_Text_Color );
   WRITE  ('         M ');
   TextColor( Menu_Text_Color_2 );
   WRITE  ('Manual dial');
   TextColor( Menu_Text_Color );
   WRITE  ('     Home ');
   TextColor( Menu_Text_Color_2 );
   WRITE  ('First page ');
   TextColor( Menu_Text_Color );
   WRITE  ('   End');
   TextColor( Menu_Text_Color_2 );
   WRITE  (' Last page');
   TextColor( Menu_Text_Color );
   WRITE  ('    G');
   TextColor( Menu_Text_Color_2 );
   WRITELN(' Goto page');

   WRITE  ('         Entry');
   WRITE  (' to dial     ');
   TextColor( Menu_Text_Color );
   WRITE  ('ENTER ');
   TextColor( Menu_Text_Color_2 );
   WRITE('dials highlighted entry');
   TextColor( Menu_Text_Color );
   WRITE  ('       L ');
   TextColor( Menu_Text_Color_2 );
   WRITELN('Dial list');

   TextColor( Menu_Text_Color );
   WRITE  ('         S ');
   TextColor( Menu_Text_Color_2 );
   WRITE  ('Search');
   TextColor( Menu_Text_Color );
   WRITE('          O ');
   TextColor( Menu_Text_Color_2 );
   WRITE('Order entries');
   TextColor( Menu_Text_Color );
   WRITE('    W ');
   TextColor( Menu_Text_Color_2 );
   WRITE('Write directory');

   TextColor( Menu_Text_Color );

END   (* Display_Dialing_Window *);

(*----------------------------------------------------------------------*)
(*        Switch_To_Full_Display --- Switch to full dialing display     *)
(*----------------------------------------------------------------------*)

PROCEDURE Switch_To_Full_Display;

BEGIN (* Switch_To_Full_Display *)

   IF Use_Short_Prompt THEN
      BEGIN
         Use_Short_Prompt := FALSE;
         Display_Dialing_Window;
      END;

END   (* Switch_To_Full_Display *);

(*----------------------------------------------------------------------*)
(*        Update_Dialing_Directory --- Rewrite dialing directory        *)
(*----------------------------------------------------------------------*)

PROCEDURE Update_Dialing_Directory;

VAR
   Local_Save_5 : Saved_Screen_Ptr;
   I            : INTEGER;

BEGIN (* Update_Dialing_Directory *)

   Draw_Titled_Box( Local_Save_5, 10, 10, 65, 15,
                    'Write Updated Dialing Directory');

   Rewrite_Dialing_Directory;

   Restore_Screen( Local_Save_5 );

END   (* Update_Dialing_Directory *);

(*----------------------------------------------------------------------*)
(*            Search_For_Entry --- Search for a dialing entry           *)
(*----------------------------------------------------------------------*)

PROCEDURE Search_For_Entry;

VAR
   Local_Save_5 : Saved_Screen_Ptr;
   I            : INTEGER;
   Found        : BOOLEAN;
   K            : INTEGER;
   T_Phone_Name : AnyStr;

BEGIN (* Search_For_Entry *)

   Draw_Titled_Box( Local_Save_5, 10, 10, 65, 14, 'Search for entry');

   TextColor( Menu_Text_Color_2 );

   GoToXY( 1 , 1 );
   WRITE('String to search for? ');

   TextColor( Menu_Text_Color );

   T_Phone_Name := '';
   Read_Edited_String( T_Phone_Name );

   IF LENGTH( T_Phone_Name ) > 0 THEN
      Dial_Search_String := UpperCase( T_Phone_Name );

   IF LENGTH( Dial_Search_String ) <= 0 THEN
      BEGIN
         Restore_Screen( Local_Save_5 );
         EXIT;
      END;

   Found := FALSE;
   I     := Low_Num + 1;
   K     := 0;

   REPEAT

      MOVE( Dialing_Directory^[I].Phone_Name,   T_Phone_Name[1],  25 );
      MOVE( Dialing_Directory^[I].Phone_Number, T_Phone_Name[26], 15 );
      T_Phone_Name[0] := CHR( 40 );

      IF ( POS( Dial_Search_String , UpperCase( T_Phone_Name ) ) > 0 ) THEN
         BEGIN
            Found   := TRUE;
            Low_Num := I;
            Hi_Num  := MIN( Low_Num + N_Nos - 1 , Dialing_Dir_Size );
            ReDraw  := TRUE;
            Switch_To_Full_Display;
         END;

      I := I + 1;

      IF ( I > Dialing_Dir_Size ) THEN
         I := 1;

      K := K + 1;

   UNTIL ( FOUND OR ( K > Dialing_Dir_Size ) );

   IF ( NOT Found ) THEN
      BEGIN
         TextColor( Menu_Text_Color_2 );
         WRITELN;
         WRITE('String not found.');
         Window_Delay;
      END;

   TextColor( Menu_Text_Color );
   Restore_Screen( Local_Save_5 );

END   (* Search_For_Entry *);

(*----------------------------------------------------------------------*)

BEGIN (* Display_Phone_Numbers *)
                                   (* Save dialing box screen *)

   Save_Partial_Screen( Local_Save, 1, 1, Max_Screen_Col, 24 );

                                   (* Display dialing prompt          *)
   IF Use_Short_Prompt THEN
      BEGIN
         TextColor( Menu_Text_Color_2 );
         WRITELN;
         WRITE('Dialing Command --> ');
         TextColor( Menu_Text_Color  );
         XPos      := WhereX;
         YPos      := WhereY;
         Dial_Func := ' ';
      END
   ELSE
      Display_Dialing_Window;
                                   (* Figure numbers to display       *)

   Low_Num      := MIN( MAX( Phone_Entry_Page , 1 ) ,
                             Dialing_Dir_Size );
   Hi_Num       := MIN( Low_Num + N_Nos - 1 , Dialing_Dir_Size );
   Done         := FALSE;

   N_Dial_Nos   := 0;

   Esc_Hit      := FALSE;
   ReDraw       := ( NOT Use_Short_Prompt );
   Entry_String := '';
                                   (* If full menu display requested,    *)
                                   (* display dialing directory until    *)
                                   (* explicit exit requested or a       *)
                                   (* phone number selected for dialing  *)
   REPEAT

      IF ReDraw AND ( NOT Use_Short_Prompt ) THEN
         BEGIN
            Display_Directory_Page;
            GoToXY( 5 , N_Nos + 2 );
            XPos      := WhereX;
            YPos      := WhereY;
            Dial_Func := ' ';
         END;

      ReDraw    := TRUE;
                                   (* Read in dialing command *)
      GoToXY( Xpos, Ypos );

      FOR I := 1 TO 5 DO
         WRITE(' ');

      GoToXY( Xpos, Ypos );
                                   (* Get function to perform *)
      Read_Kbd_Old( Dial_Func );
      Dial_Func := UpCase( Dial_Func );

                                   (* Check for keypad key *)

      IF ( ORD( Dial_Func ) = ESC ) AND PibTerm_KeyPressed THEN
         BEGIN

            Read_Kbd_Old( Dial_Func );

            CASE ORD( Dial_Func ) OF

               PgUp:    Dial_Func := 'B';
               PgDn:    Dial_Func := 'F';
               U_Arrow: Dial_Func := 'U';
               D_Arrow: Dial_Func := 'D';
               L_Arrow: Dial_Func := '<';
               R_Arrow: Dial_Func := '>';
               End_Key: Dial_Func := 'E';
               Home:    Dial_Func := 'T';
               Alt_D:   Dial_Func := ^M;
               ELSE     Dial_Func := 'Z';

            END (* CASE *)

         END
                                   (* Flag invalid letters *)

      ELSE IF( NOT ( Dial_Func IN ['C','R','O','P','S',^[,^H,'0'..'9','+','-',
                                   '!','@',
                                   '#',' ',^M, 'M','L','H','Q','G', 'W' ] ) ) THEN
         Dial_Func := 'Z';

                                   (* Perform requested dialing command *)

      CASE Dial_Func OF

                                   (* Clear dialing entry        *)
         'C':     Clear_Dialing_Entry;

                                   (* Exit without dialing anything *)
         ^[ :     BEGIN
                     Done    := TRUE;
                     Esc_Hit := TRUE;
                  END;

                                   (* Display next page in directory *)

         'F':     IF Hi_Num < Dialing_Dir_Size THEN
                     BEGIN
                        Low_Num := Hi_Num + 1;
                        Hi_Num  := MIN( Low_Num + N_Nos - 1 ,
                                        Dialing_Dir_Size );
                        Switch_To_Full_Display;
                     END;
                                   (* Display previous page in directory *)

         'B':     IF Low_Num > 1 THEN
                     BEGIN
                        Low_Num := MAX( Low_Num - N_Nos , 1 );
                        Hi_Num  := MIN( Low_Num + N_Nos - 1 ,
                                        Dialing_Dir_Size );
                        Switch_To_Full_Display;
                     END;
                                   (* Display first page in directory *)
         'T':     BEGIN
                     Low_Num := 1;
                     Hi_Num  := N_Nos;
                     Switch_To_Full_Display;
                  END;

                                   (* Display last page in directory *)

         'E':     BEGIN
                     Hi_Num  := Dialing_Dir_Size;
                     Low_Num := MAX( Hi_Num - N_Nos + 1 , 1 );
                     Switch_To_Full_Display;
                  END;

                                   (* Go to specific page in directory *)
         'G':     BEGIN
                     Ch := 'G';
                     Read_Number_Or_ESC( Ch , WhereX , 5, SS, SS, SS, Q, J, SS );
                     IF ( NOT Q ) THEN
                        BEGIN
                           I       := ( Dialing_Dir_Size + N_Nos - 1 ) DIV
                                      N_Nos;
                           Low_Num := MAX( 1 , MIN( J , I ) );
                           Low_Num := ( Low_Num - 1 ) * N_Nos + 1;
                           Hi_Num  := MIN( Low_Num + N_Nos - 1 ,
                                           Dialing_Dir_Size );
                        END;
                     IF Use_Short_Prompt THEN
                        BEGIN
                           Use_Short_Prompt := FALSE;
                           Display_Dialing_Window;
                        END;
                  END;

         'U':     BEGIN (* Move up one line *)

                     Redraw           := Use_Short_Prompt;

                     Switch_To_Full_Display;

                     IF Low_Num > 1 THEN
                        IF ( NOT Redraw ) THEN
                           BEGIN

                              PibTerm_Window( 2, 3, 78, N_Nos + 2 );

                                   (* Remove highlight from top line *)

                              Display_One_Entry( Low_Num, 1, FALSE );

                                   (* Make room for new line *)

                              GoToXY( 1 , 1 );
                              InsLine;

                              Low_Num  := Low_Num  - 1;
                              Hi_Num   := Hi_Num   - 1;

                                   (* Get data for new line *)

                              Display_One_Entry( Low_Num, 1, TRUE );

                              PibTerm_Window( 2, 3, 78, 23 );

                           END
                        ELSE
                           BEGIN
                              Low_Num  := Low_Num  - 1;
                              Hi_Num   := Hi_Num   - 1;
                           END;

                  END   (* Move up one line *);

         'D':     BEGIN (* Move down one line *)

                     Redraw           := Use_Short_Prompt;

                     Switch_To_Full_Display;

                     IF Low_Num < Dialing_Dir_Size THEN
                        IF ( NOT Redraw ) THEN
                           BEGIN
                                   (* Make room for new line *)

                              PibTerm_Window( 2, 3, 78, N_Nos + 3 );

                              GoToXY( 1 , 1 );
                              DelLine;

                              Low_Num := Low_Num + 1;
                              Hi_Num  := MIN( Low_Num + N_Nos - 1 ,
                                           Dialing_Dir_Size );
                              J        := Hi_Num - Low_Num + 1;

                              Display_One_Entry( Hi_Num  , J , FALSE );
                              Display_One_Entry( Low_Num , 1 , TRUE  );

                              PibTerm_Window( 2, 3, 78, 23 );

                           END
                        ELSE
                           BEGIN
                              Low_Num := Low_Num + 1;
                              Hi_Num  := MIN( Low_Num + N_Nos - 1 ,
                                           Dialing_Dir_Size );
                           END;

                  END   (* Move down one line *);

                                   (* Entry to dial *)

         '0'..'9', '+','-','!','@','#':
                  Extract_Dialing_Entry( -1 , Entry_String );
{
                  IF ( NOT Dialer_Carrier_Detect ) THEN
                     Extract_Dialing_Entry( -1 , Entry_String )
                  ELSE
                     BEGIN
                        Draw_Titled_Box( Local_Save_3, 10, 10, 60, 14, '' );
                        WRITELN('Session already in progress.');
                        WRITE  ('Dialing request ignored.');
                        Window_Delay;
                        Restore_Screen( Local_Save_3 );
                        TextColor( Menu_Text_Color );
                        ReDraw    := FALSE;
                     END;
}
                                   (* Revise/add a dialing entry *)

         'R':     Revise_Phone_Entry;

                                   (* Revise dialing prefix/postfix *)

         'P':     BEGIN
                     Revise_Dialing_Prefix;
                     Redraw := FALSE;
                  END;
                                   (* Start a redial             *)

         'Q':     BEGIN
                     IF Phone_Number = '' THEN
                        Extract_Dialing_Entry( Low_Num , Entry_String );
                     Done   := TRUE;
                     ReDial := TRUE;
                  END;

                                   (* Ignore extraneous backspace *)
         ^H:      BEGIN
                     Redraw := FALSE;
                  END;

                                   (* Hang up the phone *)
         'H':     BEGIN

                     Redraw := FALSE;

                     Draw_Titled_Box( Local_Save_2, 10, 10, 60, 15, '' );

                     WRITELN;
                     WRITELN('*** Hanging up the phone ***');

                                   (* Hang up the phone *)

                     HangUpPhone;

                     IF Async_Carrier_Detect THEN
                        WRITELN('*** Phone not hung up, try again ***')
                     ELSE
                        BEGIN
                           WRITELN('*** Phone hung up ***');
                           Qerr := Async_Open( Comm_Port, Baud_Rate,
                                               Parity, Data_Bits,
                                               Stop_Bits );
                        END;

                     Window_Delay;

                     Restore_Screen( Local_Save_2 );
                     TextColor( Menu_Text_Color );

                  END;

                                   (* Dial top number on screen *)
         ^M,
         ' ':     IF ( Use_Short_Prompt ) THEN
                     BEGIN
                        Display_Dialing_Window;
                        Use_Short_Prompt := FALSE;
                        Redraw           := TRUE;
                     END
                  ELSE
                     Extract_Dialing_Entry( Low_Num , Entry_String );
 {
                     IF ( NOT Dialer_Carrier_Detect ) THEN
                        Extract_Dialing_Entry( Low_Num , Entry_String )
                     ELSE
                        BEGIN
                           Save_Partial_Screen( Local_Save_3, 10, 10, 60, 14 );
                           Draw_Menu_Frame( 10, 10, 60, 14, Menu_Frame_Color, Menu_Title_Color,
                                            Menu_Text_Color + Blink, '' );
                           WRITELN('Session already in progress.');
                           WRITE  ('Dialing request ignored.');
                           Window_Delay;
                           Restore_Screen( Local_Save_3 );
                           TextColor( Menu_Text_Color );
                           ReDraw    := FALSE;
                        END;
}
                                   (* Manual dial *)
         'M':     BEGIN
                     Done   := Do_Manual_Dial;
                     ReDraw := FALSE;
                  END;

                                   (* 'L' -- list of numbers given *)
         'L':     BEGIN
                     Draw_Titled_Box( Local_Save_3, 10, 10, 60, 22,
                                      'Numbers to Dial' );
                     Get_List_Of_Phone_Numbers;
                     Restore_Screen( Local_Save_3 );
                     TextColor( Menu_Text_Color );
                     ReDraw := FALSE;
                     Done   := ( N_Dial_Nos > 0 );
                  END;
                                   (* Back up parameters *)

         '<':     IF ( Dialing_Page > 1 ) THEN
                     BEGIN
                        DEC( Dialing_Page );
                        ReDraw       := TRUE;
                        Dialing_Page_Title;
                     END;
                                   (* Forward parameters *)

         '>':     IF ( Dialing_Page < 3 ) THEN
                     BEGIN
                        INC( Dialing_Page );
                        ReDraw       := TRUE;
                        Dialing_Page_Title;
                     END;

         'O':     BEGIN
                     Sort_Dialing_Directory;
                     Low_Num := 1;
                     Hi_Num  := MIN( N_Nos, Dialing_Dir_Size );
                     Switch_To_Full_Display;
                     ReDraw := TRUE;
                  END;

         'S':     BEGIN
                     Switch_To_Full_Display;
                     Search_For_Entry;
                     ReDraw := TRUE;
                  END;

         'W':     BEGIN
                     Switch_To_Full_Display;
                     Update_Dialing_Directory;
                     ReDraw := TRUE;
                  END;

                                   (* Beep on anything else -- bad *)
         ELSE
            Menu_Beep;
            ReDraw := FALSE;

      END (* CASE *);

   UNTIL Done;
                                   (* Remember current dialing page *)
   Phone_Entry_Page := Low_Num;
                                   (* Restore dialing box *)

   Restore_Screen_And_Colors( Local_Save );

END   (* Display_Phone_Numbers *);
