(*----------------------------------------------------------------------*)
(*      Read_Key_Defs_From_File --- get key definitions from file       *)
(*----------------------------------------------------------------------*)

PROCEDURE Read_Key_Defs_From_File( File_Name : AnyStr; Tell : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Read_Key_Defs_From_File                              *)
(*                                                                      *)
(*     Purpose:    Reads function key and keypad key values from file   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Read_Key_Defs_From_File;                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Input_Key_File      : TEXT;
   Input_Key_File_Name : AnyStr;
   Key_Name            : STRING[5];
   Key_Text            : AnyStr;
   Section_No          : INTEGER;
   Key_Def_Text        : AnyStr;
   Key_Number          : INTEGER;
   L_Text              : INTEGER;
   I                   : INTEGER;
   J                   : INTEGER;
   Save_Name           : AnyStr;
   Ch                  : CHAR;
   X                   : INTEGER;
   Y                   : INTEGER;
   W                   : INTEGER;

(*----------------------------------------------------------------------*)
(*       Process_Key_Definition --- Process Function Key Definition     *)
(*----------------------------------------------------------------------*)

PROCEDURE Process_Key_Definition;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Process_Key_Definition                               *)
(*                                                                      *)
(*     Purpose:    Process and store key definition string              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Process_Key_Definition;                                       *)
(*                                                                      *)
(*           On entry, Key_Text should have the key definition text     *)
(*           as read from a file.                                       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Process_Key_Definition *)

                                   (* Ignore comment line *)
   IF ( Key_Text[1] <> '*' ) THEN
      BEGIN
                                   (* Get key name   *)

         I        := POS( '=' , Key_Text );
         L_Text   := LENGTH( Key_Text );

         IF ( I > 0 ) THEN
            Define_Key( COPY( Key_Text, 1, PRED( I ) ) ,
                        COPY( Key_Text, SUCC( I ) , L_Text - I ) );

      END;

END   (* Process_Key_Definition *);

(*----------------------------------------------------------------------*)

BEGIN (* Read_Key_Defs_From_File *)

                                   (* Announce input key definition *)

   Tell                := Tell OR ( File_Name = '' );
   Input_Key_File_Name := File_Name;

   IF Tell THEN
      BEGIN

         Draw_Titled_Box( Saved_Screen, 10, 10, 75, 16, 'Read Input Key Definitions' );

                                   (* Prompt for file with definitions *)
                                   (* if not already specified         *)

         TextColor( Menu_Text_Color_2 );

         GoToXY( 2 , 1 );
         WRITE('Enter file name from which to read definitions (ESC to exit): ');
         ClrEol;
         GoToXY( 2 , 2 );
         WRITE('>');
         ClrEol;

         TextColor( Menu_Text_Color );

         IF ( LENGTH( Input_Key_File_Name ) <= 0 ) THEN
            BEGIN
               Input_Key_File_Name := Function_Key_Name;
               Read_Edited_String( Input_Key_File_Name );
               WRITELN;
            END
         ELSE
            BEGIN
               WRITELN( Input_Key_File_Name );
               Window_Delay;
            END;

         IF ( ( LENGTH( Input_Key_File_Name ) <= 0 ) OR
              ( Input_Key_File_Name = CHR( ESC ) ) ) THEN
            BEGIN
               Restore_Screen_And_Colors( Saved_Screen );
               EXIT;
            END;

      END;

   Input_Key_File_Name := UpperCase( Input_Key_File_Name );

                                   (* Assume .FNC if type not given *)

   IF ( POS( '.', Input_Key_File_Name ) = 0 ) THEN
      Input_Key_File_Name := Input_Key_File_Name + '.FNC';

   Save_Name := Input_Key_File_Name;

                                   (* Append function key path if needed *)

   Add_Path( Input_Key_File_Name, Function_Key_Path, Input_Key_File_Name );

   IF Tell THEN
      TextColor( Menu_Text_Color_2 );

                                   (* Attach file with definitions *)

   ASSIGN( Input_Key_File , Input_Key_File_Name );
       (*!I-*)
   RESET ( Input_Key_File );
       (*!I+*)
                                   (* See if openable *)

   IF ( ( Int24Result <> 0 ) AND Tell ) THEN
      BEGIN (* File bad *)
         WRITELN;
         WRITELN(' *** File ',Input_Key_File_Name,' can''t be found.');
         Window_Delay;
      END   (* File bad *)
   ELSE
      BEGIN (* File OK, read definitions *)

         REPEAT

            Key_Text       := ' ';
                                   (* Read key definition *)

            READLN( Input_Key_File , Key_Text );

                                   (* Process it *)

            Process_Key_Definition;

         UNTIL( EOF( Input_Key_File ) );

                                   (* Indicate definitions finished *)


         IF Tell THEN
            BEGIN

               WRITELN(' Function key definitions loaded.');

               Window_Delay;

               Function_Key_Name := Save_Name;

            END;

         CLOSE( Input_Key_File );

      END   (* File OK, read definitions *);

                                   (* Restore previous screen          *)

   IF Tell THEN
      Restore_Screen_And_Colors( Saved_Screen );

END   (* Read_Key_Defs_From_File *);

(*----------------------------------------------------------------------*)
(*       Get_Key_Defs_From_Keyboard --- get key defs. from keyboard     *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Key_Defs_From_Keyboard;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_Key_Defs_From_Keyboard                           *)
(*                                                                      *)
(*     Purpose:    Read function and keypad key values from keyboard    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_Key_Defs_From_Keyboard;                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Local_Save : Saved_Screen_Ptr;
   Page_No    : INTEGER;
   Key_Type   : INTEGER;
   Defs_Done  : BOOLEAN;
   Key_Text   : AnyStr;

(*----------------------------------------------------------------------*)
(*              Update_Key_Defs --- Update key definitions              *)
(*----------------------------------------------------------------------*)

PROCEDURE Update_Key_Defs( VAR Defs_Done : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Update_Key_Defs                                      *)
(*                                                                      *)
(*     Purpose:    Update key definitions                               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Update_Key_Defs( VAR Defs_Done : BOOLEAN );                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Key_No     : INTEGER;
   OK_KeyHit  : BOOLEAN;
   I          : INTEGER;
   J          : INTEGER;
   Ch         : CHAR;
   Key_Name   : ShortStr;
   X          : INTEGER;
   Y          : INTEGER;
   W          : INTEGER;
   LKey_Text  : INTEGER;
   LDef       : INTEGER;

BEGIN (* Update_Key_Defs *)
                                   (* Not through with definitions yet *)
   Defs_Done := FALSE;
                                   (* Get number of key to change *)
   REPEAT
                                   (* Clear any previous error         *)
      GoToXY( 1 , 2 );
      ClrEol;

      TextColor( Menu_Text_Color_2 );
      GoToXY( 1 , 1 );
      WRITE(' Hit key to define or <ESC> to quit: ');
      ClrEol;
      TextColor( Menu_Text_Color );

                                   (* Pick ESC or function key sequence *)
      Read_Kbd( Ch );

      IF ( Ch <> CHR( ESC ) ) THEN
         OK_KeyHit := FALSE
      ELSE
         IF ( NOT PibTerm_KeyPressed ) THEN
            BEGIN
               Defs_Done := TRUE;
               OK_KeyHit := TRUE;
            END
         ELSE
            BEGIN
               Read_Kbd( Ch );
               Key_No      := ORD( Ch );
               OK_KeyHit   := ( PibTerm_Command_Table[ Key_No ] = KeySendSy );
            END;
                                   (* Not just plain escape -- must be *)
                                   (* function key.                    *)
      IF ( NOT OK_KeyHit ) THEN
         BEGIN
            GoToXY( 1 , 2 );
            WRITE(' *** Not a valid key');
            ClrEol;
            Window_Delay;
         END;

   UNTIL ( OK_KeyHit OR Defs_Done );

                                   (* If CR entered, quit;        *)
                                   (* else, pick up definition.   *)
   IF ( NOT Defs_Done ) THEN
      BEGIN
                                   (* Display key name *)

         Get_Long_Key_Name( Key_Definitions[Key_No].Name , Key_Name );
         WRITE( Key_Name );
         ClrEol;

         TextColor( Menu_Text_Color_2 );
         GoToXY( 1 , 2 );
         WRITE(' -->');
         ClrEol;
         TextColor( Menu_Text_Color );

                                    (* Prompt for and read new definition *)

         WITH Key_Definitions[Key_No] DO
            BEGIN

               IF ( Def = NIL ) THEN
                  Key_Text := ''
               ELSE
                  Key_Text := Write_Ctrls( Def^ );

               X  := WhereX;
               Y  := WhereY;

               W  := MAX( 1 , PRED( Lower_Right_Column - ( PRED( X ) + Upper_Left_Column ) ) );

               Ch := Edit_String( Key_Text, 255, X, X, Y, W, FALSE, 0 );

               Key_Text  := Read_Ctrls( Key_Text );
               LKey_Text := LENGTH( Key_Text );

               IF ( Def = NIL ) THEN
                  GETMEM( Def , SUCC( LKey_Text ) );

               IF ( Def <> NIL ) THEN
                  BEGIN
                     LDef := LENGTH( Def^ );
                     IF ( LKey_Text > LDef ) THEN
                        IF ( ( Key_No <> BS_Key ) AND
                             ( Key_No <> Ctrl_BS_Key ) ) THEN
                           BEGIN
                              MyFreeMem( Def , SUCC( LDef ) );
                              GETMEM   ( Def , SUCC( LKey_Text ) );
                           END;
                     IF( Def <> NIL ) THEN
                        Def^ := Key_Text;
                  END;

            END (* With *);

      END (* NOT Defs_Done *);

END   (* Update_Key_Defs *);

(*----------------------------------------------------------------------*)

BEGIN (* Get_Key_Defs_From_Keyboard *)

                                   (* Save screen *)
   Save_Screen( Local_Save );
                                   (* Get back whole screen as window *)
                                   (* for key display                 *)
   PibTerm_Window( 1, 1, 80, 25 );

   Draw_Menu_Frame( 5, 11, 75, 16, Menu_Frame_Color, Menu_Title_Color,
                    Menu_Text_Color, 'Input key definition' );

   PibTerm_Window( 6, 12, 74, 15 );

                                   (* Update key definitions           *)
   REPEAT
      Update_Key_Defs( Defs_Done );
   UNTIL ( Defs_Done );
                                   (* Restore previous screen          *)

   Restore_Screen_And_Colors( Local_Save );

END   (* Get_Key_Defs_From_Keyboard *);

(*----------------------------------------------------------------------*)
(*     Display_Current_Key_Defs --- Display current key definitions     *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Current_Key_Defs;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Display_Current_Key_Defs                             *)
(*                                                                      *)
(*     Purpose:    Displays current key definitions                     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Display_Current_Key_Defs;                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   Quit_Item  = 12;

VAR
   Local_Save : Saved_Screen_Ptr;
   Page_No    : INTEGER;
   Key_Menu   : Menu_Type;
   Key_Type   : INTEGER;
   Defs_Done  : BOOLEAN;
   Ch         : CHAR;
   Done       : BOOLEAN;

(*----------------------------------------------------------------------*)
(*       Display_Key_Defs --- Display current key definitions           *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Key_Defs( Key_Type : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Display_Key_Defs                                     *)
(*                                                                      *)
(*     Purpose:    Display portion of current key definitions           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Display_Key_Defs( Key_Type: INTEGER );                        *)
(*                                                                      *)
(*           Key_Type --- Key type to display.                          *)
(*                        = 1:  F1 through F12                          *)
(*                        = 2:  Shift F1 through Shift F12              *)
(*                        = 3:  Ctrl F1 through Ctrl F12                *)
(*                        = 4:  Alt F1 through Alt F12                  *)
(*                        = 5:  Keypad keys                             *)
(*                        = 6:  Alt keypad keys                         *)
(*                        = 7:  Ctrl keypad keys                        *)
(*                        = 8:  Alt-Number keys                         *)
(*                        = 9:  Extended cursor keys                    *)
(*                        = 10: Extended keypad keys                    *)
(*                        = 11: Miscellaneous keys                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I          : INTEGER;
   Last_Key   : INTEGER;
   Key_Name   : ShortStr;
   Key_Num    : INTEGER;
   Local_Save : Saved_Screen_Ptr;
   Key_Nos    : ARRAY[1..18] OF BYTE;

(* STRUCTURED *) CONST

   Keypad_Keys     :  ARRAY[1..16] OF BYTE
                      = (  71,  72,  73,  74,  75,  76,  77,
                           78,  79,  80,  81,  82,  83, 1, 4, 7 );

   Alt_Keypad_Keys :  ARRAY[1..16] OF BYTE
                      = ( 173, 174, 175, 176, 177, 178, 179,
                          180, 181, 182, 183, 184, 185, 2, 5, 8 );

   Ctrl_Keypad_Keys :  ARRAY[1..16] OF BYTE
                       = ( 119, 160, 132, 161, 115, 162, 116,
                           163, 117, 164, 118, 165, 166, 3, 6, 9 );

BEGIN (* Display_Key_Defs *)

   GoToXY( 1 , 1 );
                                   (* Display title                *)
   TextColor( Menu_Text_Color_2 );

   WRITELN(' --Key Name-- ',
           '   ------------------------Definition-------------------------- ');
   WRITELN(' ');

   CASE Key_Type OF

      1,
      2,
      3,
      4:  BEGIN
             Last_Key   := 12;
             FOR I := 1 TO 10 DO
                Key_Nos[ I ] := Funk_Bases[ Key_Type ] + I;
             Key_Nos[ 11 ] := Funk_Bases_2[ Key_Type ] + 11;
             Key_Nos[ 12 ] := Funk_Bases_2[ Key_Type ] + 12;
          END;
      5:  BEGIN
             Last_Key   := 16;
             MOVE( Keypad_Keys[1], Key_Nos[1], 16 );
          END;
      6:  BEGIN
             Last_Key   := 16;
             MOVE( Alt_Keypad_Keys[1], Key_Nos[1], 16 );
          END;
      7:  BEGIN
             Last_Key   := 16;
             MOVE( Ctrl_Keypad_Keys[1], Key_Nos[1], 16 );
          END;
      8:  BEGIN
             Last_Key   := 12;
             FOR I := 1 TO 12 DO
                Key_Nos[ I ] := PRED( Alt_1 ) + I;
          END;
      9:  BEGIN
             Last_Key := 12;
             FOR I := 1 TO 12 DO
                Key_Nos[ I ] := PRED( X_U_Arrow ) + I;
          END;
     10:  BEGIN
             Last_Key := 18;
             FOR I := 1 TO 18 DO
                Key_Nos[ I ] := PRED( X_Home ) + I;
          END;
     11:  BEGIN
             Last_Key := No_Misc_Keys;
             MOVE( Misc_Keys[ 1 ], Key_Nos[ 1 ], No_Misc_Keys );
          END;

      ELSE;

   END (* CASE *);
                                   (* Display current definitions *)
   FOR I := 1 TO Last_Key DO
      BEGIN

         GoToXY( 1 , I + 2 );
         ClrEol;

         TextColor( Menu_Text_Color_2 );

         Key_Num := Key_Nos[ I ];

         Get_Long_Key_Name( Key_Definitions[Key_Num].Name , Key_Name );
         WRITE( ' ', Key_Name );

         TextColor( Menu_Text_Color );

         GoToXY( 18 , I + 2 );
         IF ( Key_Definitions[Key_Num].Def <> NIL ) THEN
            WRITE( Write_Ctrls( Key_Definitions[ Key_Num ].Def^ ) );

      END (* FOR *);
                                   (* Blank out remaining lines *)

   FOR I := SUCC( WhereY ) TO 20 DO
      BEGIN
         GoToXY( 1 , I );
         ClrEol;
      END;

END   (* Display_Key_Defs *);

(*----------------------------------------------------------------------*)

BEGIN (* Display_Current_Key_Defs *)

                                   (* Save screen *)

   Draw_Titled_Box( Local_Save, 1, 2, 80, 24, 'Display input key definitions' );

   PibTerm_Window( 2, 3, 78, 23 );
                                   (* Set up menu *)

   Make_A_Menu( Key_Menu, Quit_Item, 11, 15, 0, 0, 1,
                'Select keys to display',
                'a) Function keys 1 to 12;b) Shifted function keys;c) Ctrl + function keys;' +
                'd) Alt + function keys;e) Keypad keys;f) Alt + keypad keys;' +
                'g) Ctrl + keypad keys;h) Alt + number keys;' +
                'i) Extended cursor keys;j) Extended keypad keys;' +
                'k) Miscellaneous keys;q) Quit;',
                FALSE );

                                   (* Loop until quit chosen *)
   Done := FALSE;

   REPEAT
                                   (* Display menu of choices *)

      Menu_Display_Choices( Key_Menu );
      Key_Type := Menu_Get_Choice( Key_Menu , Erase_Menu );

                                   (* Do requested operation *)

      IF ( ( Key_Type > 0 ) AND ( Key_Type <> Quit_Item ) ) THEN
         BEGIN
            TextColor( Menu_Text_Color );
            TextBackGround( BLACK );
            Display_Key_Defs( Key_Type );
            GoToXY( 1 , 21 );
            TextColor( Menu_Text_Color_2 );
            Press_Any;
         END
      ELSE
         Done := TRUE;

      Key_Menu.Menu_Default := Quit_Item;

   UNTIL Done;
                                   (* Restore previous screen          *)

   Restore_Screen_And_Colors( Local_Save );

END   (* Display_Current_Key_Defs *);

(*----------------------------------------------------------------------*)
(*  Write_Key_Defs_To_File --- write revised key definitions to file    *)
(*----------------------------------------------------------------------*)

PROCEDURE Write_Key_Defs_To_File;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Write_Key_Defs_To_File                               *)
(*                                                                      *)
(*     Purpose:    Write updated function key and keypad key values     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Write_Key_Defs_To_File;                                       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Local_Save          : Saved_Screen_Ptr;
   Input_Key_File      : TEXT;
   Input_Key_File_Name : AnyStr;
   Key_Name            : STRING[5];
   Key_Text            : AnyStr;
   Section_No          : INTEGER;
   Key_Def_Text        : AnyStr;
   Key_Number          : INTEGER;
   L_Text              : INTEGER;
   I                   : INTEGER;
   J                   : INTEGER;
   Save_Name           : AnyStr;

BEGIN (* Write_Key_Defs_To_File *)

                                   (* Indicate write to file *)

   Draw_Titled_Box( Local_Save, 10, 10, 75, 14,
                    'Write Function Key Definitions' );

                                   (* Get name of file to write to *)

   TextColor( Menu_Text_Color_2 );

   GoToXY( 2 , 1 );
   WRITE('Enter file name to write definitions to (ESC to exit): ');
   ClrEol;
   GoToXY( 2 , 2 );
   WRITE('>');
   ClrEol;

   Input_Key_File_Name := Function_Key_Name;

   TextColor( Menu_Text_Color );
   Read_Edited_String( Input_Key_File_Name );

   IF ( ( LENGTH( Input_Key_File_Name ) = 0 ) OR
        ( Input_Key_File_Name = CHR( ESC ) ) ) THEN
      BEGIN
         Restore_Screen( Local_Save );
         EXIT;
      END;
                                   (* Assume .FNC if type not given *)

   Input_Key_File_Name := UpperCase( Input_Key_File_Name );

   IF ( POS( '.', Input_Key_File_Name ) = 0 ) THEN
      Input_Key_File_Name := Input_Key_File_Name + '.FNC';

   Save_Name := Input_Key_File_Name;

   TextColor( Menu_Text_Color_2 );

                                   (* Append function key path if none *)
                                   (* specified                        *)

   Add_Path( Input_Key_File_Name, Function_Key_Path, Input_Key_File_Name );

                                   (* Ensure file can be opened *)

   IF LENGTH( Input_Key_File_Name ) > 0 THEN
      BEGIN

         ASSIGN( Input_Key_File , Input_Key_File_Name );
            (*!I-*)
         REWRITE( Input_Key_File );
            (*!I+*)

         IF Int24Result <> 0 THEN
            BEGIN (* File bad *)

               GoToXY( 2 , 3 );
               WRITE('*** File ',Input_Key_File_Name,' can''t be opened.');
               ClrEol;

               Window_Delay;

            END   (* File bad *)
         ELSE
            BEGIN (* File OK, definitions written *)

               FOR I := 0 TO Max_Key_Def DO
                  WITH Key_Definitions[I] DO
                     IF ( Def <> NIL ) THEN
                        IF LENGTH( Def^ ) > 0 THEN
                           WRITELN( Input_Key_File, Name, '=', Write_Ctrls( Def^ ) );

               CLOSE( Input_Key_File );

               GoToXY( 2 , 3 );

               WRITE('Function key definitions written to ',
                      Input_Key_File_Name );

               ClrEol;

               Window_Delay;

               Function_Key_Name := Save_Name;

            END   (* File OK, definitions written *);

      END;
                                   (* Restore previous screen          *)
   Restore_Screen( Local_Save );

END   (* Write_Key_Defs_To_File *);
