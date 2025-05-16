(*----------------------------------------------------------------------*)
(*          Get_Capture_File -- Get session capture file name           *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Capture_File( Capture_FName : AnyStr;
                            Capture_Type  : AnyStr   );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_Capture_File                                     *)
(*                                                                      *)
(*     Purpose:    Opens capture file                                   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_Capture_File( Capture_FName : AnyStr;                     *)
(*                          Capture_Type  : AnyStr );                   *)
(*                                                                      *)
(*           Capture_FName --- name of capture file; prompted for       *)
(*                             if null.                                 *)
(*           Capture_Type  --- type of capture to perform.              *)
(*                             E = edited, U = unedited.                *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Open_For_Append                                               *)
(*        YesNo                                                         *)
(*        Save_Screen                                                   *)
(*        Draw_Menu_Frame                                               *)
(*        Restore_Screen                                                *)
(*        Reset_Global_Colors                                           *)
(*        Add_Path                                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   OK_File           : BOOLEAN;
   Open_OK           : BOOLEAN;
   File_Exists       : BOOLEAN;
   Name_Given        : BOOLEAN;
   Ierr              : INTEGER;
   CurDir            : AnyStr;

BEGIN (* Get_Capture_File *)

   Draw_Titled_Box( Saved_Screen, 10, 10, 75, 17, 'Capture session' );

                                   (* If capture mode ON, close current  *)
                                   (* capture file and turn capture mode *)
                                   (* OFF.                               *)
   IF Capture_On THEN
      BEGIN
            (*!I-*)
         CLOSE( Capture_File );
            (*!I+*)
         Capture_On := FALSE;
         TextColor( Menu_Text_Color_2 );
         WRITELN;
         WRITELN('*** Capturing of session to ', Capture_File_Name,
                 ' terminated.');
         TextColor( Menu_Text_Color );
         Window_Delay;
      END
   ELSE                            (* If capture mode OFF, then get name *)
                                   (* of file to capture to, and turn on *)
                                   (* capture mode.                      *)

      BEGIN  (* Capture mode was Off *)

         Capture_File_Name := Capture_FName;

         OK_File     := FALSE;
         Name_Given  := LENGTH( Capture_File_Name ) > 0;

         GetDir( 0 , CurDir );

         REPEAT

            Clear_Window;

            TextColor( Menu_Text_Color_2 );
            WRITE('File name to capture session to ? ');
            TextColor( Menu_Text_Color );

            IF ( NOT Name_Given ) THEN
               BEGIN
                  Capture_File_Name := '';
                  Read_Edited_String( Capture_File_Name );
                  WRITELN;
                  IF Capture_File_Name = CHR( ESC ) THEN
                     Capture_File_Name := '';
               END
            ELSE
               WRITELN( Capture_File_Name );

            Window_Delay;

            IF ( LENGTH( Capture_File_Name ) > 0 ) THEN
               BEGIN

                  ASSIGN( Capture_File , Capture_File_Name );
                     (*!I-*)
                  RESET( Capture_File );
                     (*!I+*)

                  IF Int24Result = 0 THEN
                     BEGIN

                        IF ( NOT Name_Given ) THEN
                           OK_File := YesNo('File ' + Capture_File_Name +
                                            ' already exists, append to it (Y/N) ? ')
                        ELSE
                           OK_File := TRUE;

                        File_Exists := TRUE;

                           (*!I-*)
                        CLOSE( Capture_File );
                           (*!I+*)

                     END
                  ELSE
                     BEGIN
                        OK_File     := TRUE;
                        File_Exists := FALSE;
                     END;

               END;

         UNTIL ( OK_File ) OR ( LENGTH( Capture_File_Name ) = 0 );

         IF LENGTH( Capture_File_Name ) > 0 THEN
            BEGIN

                  (*!I-*)
               IF File_Exists THEN
                  Open_OK := Open_For_Append( Capture_File,
                                              Capture_File_Name, Ierr )
               ELSE
                  BEGIN
                        (*!I-*)
                     ASSIGN ( Capture_File, Capture_File_Name );
                     REWRITE( Capture_File );
                        (*!I+*)
                     Open_OK := ( Int24Result = 0 );
                  END;

               IF ( NOT Open_OK ) THEN
                  BEGIN
                     TextColor( Menu_Text_Color_2 );
                     WRITELN('Can''t open ',Capture_File_Name,' for output.');
                     WRITELN('Capture will not be done.');
                     TextColor( Menu_Text_Color );
                  END
               ELSE
                  BEGIN

                     IF ( LENGTH( Capture_Type ) <= 0 ) THEN
                        Capture_Type := ' ';

                     CASE UpCase(Capture_Type[1]) OF
                        'U':  Exact_Capture := TRUE;
                        'E':  Exact_Capture := FALSE;
                        ELSE
                           WRITELN;
                           Exact_Capture := NOT YesNo('Perform edited capture? ');
                           WRITELN;
                     END (* CASE *);

                     TextColor( Menu_Text_Color_2 );

                     IF Exact_Capture THEN
                        WRITE('Unedited')
                     ELSE
                        WRITE('Edited');

                     WRITE(' capture to ');

                     TextColor( Menu_Text_Color );

                     WRITE( Capture_File_Name );

                     Capture_On := TRUE;

                     Add_Path( Capture_File_Name , CurDir , Capture_File_Name );

                  END;

               Window_Delay;

            END (* Length( Capture_File_Name ) > 0 *);

      END  (* Capture mode was OFF *);

   Restore_Screen_And_Colors( Saved_Screen );

END   (* Get_Capture_File *);
