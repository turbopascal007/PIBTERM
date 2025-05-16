(*----------------------------------------------------------------------*)
(*         Initialize_Communications --- Initialize communications      *)
(*----------------------------------------------------------------------*)

PROCEDURE Initialize_Communications;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Initialize_Communications                            *)
(*                                                                      *)
(*     Purpose:    Initializes serial port and modem                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Initialize_Communications                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   F      : FILE;
   Text_F : TEXT;
   Do_Scr : BOOLEAN;
   Line   : AnyStr;
   Ierr   : INTEGER;

BEGIN (* Initialize_Communications *)

                                   (* Get serial port initialized *)

   IF ( NOT Set_Params( TRUE , FALSE ) ) THEN
      Halt( BadPort );
                                   (* Give Program Notice *)

   Scroll( 1, Max_Screen_Line, 1, Max_Screen_Col, 0,
           Global_ForeGround_Color, Global_BackGround_Color );

   MoveToXY( 1 , 1 );

   WRITELN('PibTerm Version ', PibTerm_Version);
   WRITELN(PibTerm_Date);
   WRITELN(CopyRight_Notice);
   WRITELN('Hit <ALT>I for command list.');

                                   (* Indicate if debug mode on *)
   IF Debug_Mode THEN
      BEGIN
         WRITELN('*** Debug mode on ***');
      END;
                                   (* Initialize Modem        *)
   Initialize_Modem;
                                   (* Initialize Printer      *)
   Initialize_Printer;
                                   (* Pick up script file name if any, *)
                                   (* and convert to executable form.  *)

   IF ( Script_File_Name <> '' ) THEN
      BEGIN

         Do_Scr := FALSE;

         Add_Path( Script_File_Name, Script_Path, Script_File_Name );

         ASSIGN( F , Script_File_Name );
            (*!I-*)
         RESET( F );
            (*!I+*)

         IF ( Int24Result = 0 ) THEN
            BEGIN
                  (*!I-*)
               CLOSE( F );
                  (*!I+*)
               Do_Scr := TRUE;
            END
         ELSE
            BEGIN
                  (*!I-*)
               CLOSE( F );
               Ierr := Int24Result;
               ASSIGN( Text_F , Script_Path + 'PIBTERM.SCL' );
               RESET ( Text_F );
                  (*!I+*)
               IF ( Int24Result = 0 ) THEN
                  BEGIN
                     READLN( Text_F , Line );
                     Line := Line + ' ';
                     Do_Scr := ( UpperCase( COPY( Line, 1, 10 ) ) = '==PIBTERM ' );
                  END;
                  (*!I-*)
               CLOSE( Text_F );
               Ierr := Int24Result;
                  (*!I+*)
            END;

         IF Do_Scr THEN
            Process_Script( Script_File_Name , 'E' );

      END;
{
   IF Debug_Mode THEN
      IF TimeSharingActive THEN
         BEGIN
            WRITELN;
            WRITE('Multitasker: ');
            CASE MultiTasker OF
               DoubleDos: WRITELN('DoubleDos');
               DesqView:  WRITELN('DesqView');
               TopView:   WRITELN('TopView');
               TaskView:  WRITELN('TaskView');
               ELSE       WRITELN('Other');
            END (* CASE *);
         END;
}
END   (* Initialize_Communications *);