(*----------------------------------------------------------------------*)
(*          Set_Translate_Table --- Set Character Translation Table     *)
(*----------------------------------------------------------------------*)

PROCEDURE Set_Translate_Table( File_Name : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Set_Translate_Table                                  *)
(*                                                                      *)
(*     Purpose:    Gets character translation table                     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Set_Translate_Table( File_Name : AnyStr );                    *)
(*                                                                      *)
(*           File_Name --- file to read translate table from, if        *)
(*                         specified.                                   *)
(*                                                                      *)
(*      Calls:   Clear_Window                                           *)
(*               Save_Screen                                            *)
(*               Draw_Menu_Frame                                        *)
(*               Restore_Screen                                         *)
(*               Reset_Global_Colors                                    *)
(*               Read_Kbd_Old                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   TrTab_File      : TEXT;
   I               : INTEGER;
   J               : INTEGER;
   K               : INTEGER;
   L_Char          : INTEGER;
   H_Pos           : INTEGER;
   TrTab_Menu      : Menu_Type;
   Done            : BOOLEAN;
   Ch              : CHAR;
   TrTab_Base      : INTEGER;
   Last_Char       : INTEGER;
   X               : INTEGER;
   Y               : INTEGER;
   S               : STRING[4];

(*----------------------------------------------------------------------*)
(*      Display_Translate_Table -- Display Translate_Table              *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Translate_Table;

VAR
   I: INTEGER;
   J: INTEGER;

BEGIN (* Display_Translate_Table *)

   GoToXY( 6 , 7 );

   L_Char     := 0;

   FOR I := 0 TO 15 DO
      BEGIN

         GoToXY( 2 , I + 7 );

         FOR J := 0 TO 7 DO
            BEGIN
               L_Char :=  ( J * 16 ) + I;
               WRITE( ( TrTab_Base + L_Char):3, '=',
                      ORD(TrTab[CHR(L_Char + TrTab_Base)]):3,'  ');
            END;

      END;

   GoToXY( 6 , 7 );

END   (* Display_Translate_Table *);


(*----------------------------------------------------------------------*)

BEGIN (* Set_Translate_Table *)

                                   (* Announce translate table definition *)

   Draw_Titled_Box( Saved_Screen, 10, 10, 65, 15,
                    'Read Translate Table Definitions' );

   WRITELN;
   WRITE('File with definitions? ');

   Translate_File_Name := File_Name;

   IF Length( Translate_File_Name ) > 0 THEN
      BEGIN
         WRITELN(Translate_File_Name);
         Window_Delay;
      END
   ELSE
      BEGIN
         Read_Edited_String( Translate_File_Name );
         WRITELN;
      END;

   IF ( Translate_File_Name = CHR( ESC ) ) THEN
      BEGIN
         Restore_Screen_And_Colors( Saved_Screen );
         EXIT;
      END;

   IF LENGTH( Translate_File_Name ) <= 0 THEN
      BEGIN (* Get translation definitions from keyboard *)

                                   (* Restore previous screen          *)

         Restore_Screen_And_Colors( Saved_Screen );

         Save_Screen( Saved_Screen );
         Draw_Menu_Frame( 2, 1, 79, 24, Menu_Frame_Color, Menu_Title_Color,
                          Menu_Text_Color, 'Translate Table Definitions' );

         Clear_Window;
         WRITELN(' Use arrows to move up/down/left/right.');
         WRITELN(' Hit ESC to quit editing and save definitions.');
         WRITELN(' To change character, just type new value, and hit CR.');
         WRITELN(' Hit S to toggle between first and second 128 characters ');

                                   (* Display current definitions    *)

         TrTab_Base := 0;

         Display_Translate_Table;

         Done      := FALSE;
         L_Char    := 0;
         I         := 1;
         J         := 1;
         H_Pos     := 6;
         Last_Char := 127;
                                   (* Get new definitions *)
         REPEAT

            Read_Kbd_Old( Ch );

            IF ( Ch = CHR( ESC ) ) THEN
               IF PibTerm_KeyPressed THEN
                  BEGIN  (* Escape sequence found *)

                     Read_Kbd_Old( Ch );

                     CASE ORD( Ch ) OF

                        U_Arrow:  IF J > 1  THEN
                                     J := J - 1
                                  ELSE
                                     IF I > 1 THEN
                                        BEGIN
                                           J := 16;
                                           I := I - 1;
                                        END;

                        D_Arrow:  IF J < 16 THEN
                                     J := J + 1
                                  ELSE
                                     IF I < 8 THEN
                                        BEGIN
                                           J := 1;
                                           I := I + 1;
                                        END;

                        R_Arrow:  IF I < 8  THEN
                                     I := I + 1
                                  ELSE
                                     IF J < 16 THEN
                                        BEGIN
                                           I := 1;
                                           J := J + 1;
                                        END;

                        L_Arrow:  IF I > 1  THEN
                                     I := I - 1
                                  ELSE
                                     IF J > 1 THEN
                                        BEGIN
                                           I := 8;
                                           J := J - 1;
                                        END;

                        ELSE ;

                     END (* CASE *);

                     L_Char := ( J - 1 ) * 8 + I - 1;
                     H_Pos  := 6 + ( ( I - 1 ) * 9 );

                     GoToXY( H_Pos , J + 6 );

                  END   (* Escape sequence found *)

               ELSE                (* Lone escape *)
                  Done := TRUE
                                   (* "S" means toggle display *)

            ELSE IF UpCase( Ch ) = 'S' THEN
               BEGIN
                  TrTab_Base := 128 - TrTab_Base;
                  Last_Char  := TrTab_Base + 127;
                  Display_Translate_Table;
                  I          := 1;
                  J          := 1;
                  H_Pos      := 6;
               END
                                   (* Should be digit *)
            ELSE
               BEGIN (* digit *)

                  X  := WhereX;
                  Y  := WhereY;
                  S  := Ch;

                  WRITE('   ');

                  Ch := Edit_String( S, 4, X, X + 1, Y, 4, FALSE, 0 );

                  K := 0;

                  IF ( Ch <> CHR( ESC ) ) THEN
                     FOR X := 1 TO LENGTH( S ) DO
                        IF ( S[X] IN ['0'..'9'] ) THEN
                           K := K * 10 + ORD( S[X] ) - ORD('0');

                  IF ( K >= 0 ) AND ( K <= 255 ) THEN
                     TrTab[CHR(L_Char + TrTab_Base)] := CHR(K);

                  GoToXY( H_Pos - 4  , J + 6 );
                  WRITE( ( TrTab_Base + L_Char):3, '=', K:3,'  ');
                  GoToXY( H_Pos , J + 6 );

               END  (* Digit *);

         UNTIL  Done;

         Clear_Window;
         GoToXY( 2 , 5 );
         WRITE('Enter file name to write definitions to (CR to exit): ');
         Read_Edited_String( Translate_File_Name );
         WRITELN;

         IF Translate_File_Name = CHR( ESC ) THEN
            Translate_File_Name := '';

         IF LENGTH( Translate_File_Name ) > 0 THEN
            BEGIN

               IF ( POS( '.', Translate_File_Name ) = 0 ) THEN
                  Translate_File_Name := Translate_File_Name + '.TRA';

               ASSIGN( TrTab_File , Translate_File_Name );
                  (*!I-*)
               REWRITE( TrTab_File );
                  (*!I+*)

               IF Int24Result <> 0 THEN
                  BEGIN (* File bad *)

                     GoToXY( 2 , 5 );
                     WRITE('*** File ',Translate_File_Name,' can''t be opened.');
                     ClrEol;

                     Window_Delay;

                  END   (* File bad *)
               ELSE
                  BEGIN (* File OK, definition written *)

                     FOR I := 0 TO 255 DO
                        WRITELN( TrTab_File, I:3, ' ', ORD(TrTab[CHR(I)]) );

                     CLOSE( TrTab_File );

                     GoToXY( 2 , 5 );

                     WRITE('Translation table definition written to ',
                            Translate_File_Name );

                     ClrEol;

                     Window_Delay;

                  END   (* File OK, definition written *);

            END;

      END   (* Get translation table definition from keyboard *)
   ELSE
      BEGIN (* Get definition from file *)

         IF ( POS( '.' , Translate_File_Name ) = 0 ) THEN
            Translate_File_Name := Translate_File_Name + '.TRA';

         ASSIGN( TrTab_File , Translate_File_Name );
             (*!I-*)
         RESET ( TrTab_File );
             (*!I+*)

         IF Int24Result <> 0 THEN
            BEGIN (* File bad *)
               WRITELN;
               WRITELN('*** File ',Translate_File_Name,' can''t be found.');
               Window_Delay;
            END   (* File bad *)
         ELSE
            BEGIN (* File OK, read definition *)

               REPEAT
                      (*!I-*)
                  READLN( TrTab_File , I, J );
                      (*!I+*)
                  IF Int24Result = 0 THEN
                     IF ( I >= 0 ) AND ( I <= 255 ) AND
                        ( J >= 0 ) AND ( J <= 255 ) THEN
                        TrTab[CHR(I)] := CHR( J );

               UNTIL( EOF( TrTab_File ) );

               WRITELN('Translation table definition loaded.');

               Window_Delay;

               CLOSE( TrTab_File );

            END   (* File OK, read definition *);

      END   (* Get definition from file *);

                                   (* Restore previous screen          *)

   Restore_Screen_And_Colors( Saved_Screen );

END   (* Set_Translate_Table *);
