(*----------------------------------------------------------------------*)
(*        Get_Download_Protocol --- Get File Transfer Protocol          *)
(*----------------------------------------------------------------------*)

FUNCTION Get_Download_Protocol : Transfer_Type ;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Get_Download_Protocol                                *)
(*                                                                      *)
(*     Purpose:    Gets file name and transfer protocol for download.   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Transtyp := Get_Download_Protocol: Transfer_Type;             *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Transfer_Kind : Transfer_Type;
   I             : INTEGER;
   OK_File_Name  : BOOLEAN;
   AFile         : FILE;
   Quit          : BOOLEAN;

BEGIN (* Get_Download_Protocol *)
                                   (* Copy keyboard data before we screw *)
                                   (* it up so we can get file name      *)

   Saved_Kbd_File_Name := Keyboard_Line;

   IF Auto_Find_FileNames THEN
      Get_Auto_File_Name( Saved_Kbd_File_Name , FileName )
   ELSE
      FileName := '';

                                   (* Display menu of transfer types *)
                                   (* and get transfer kind.         *)

   Display_Transfer_Types( 'Choose protocol: ',
                           Default_Transfer_Type,
                           FALSE,
                           3, 10, 50, 21, 11,
                           FALSE,
                           Transfer_Kind );

                                   (* Get file name to use if not *)
                                   (* batch transfer              *)
   Ok_File_Name := FALSE;
   Quit         := ( Transfer_Kind = None );

   IF Quit THEN
      BEGIN
         Restore_Screen_And_Colors( Saved_Screen );
         Get_Download_Protocol := Transfer_Kind;
         EXIT;
      END;

   IF Single_File_Protocol[Transfer_Kind] THEN
      BEGIN

         REPEAT

            FOR I := 18 TO 21 DO
               BEGIN
                  GoToXY( 1 , I );
                  ClrEol;
               END;

            GoToXY( 2 , 18 );
            WRITE('Enter Filename.Ext: ');

            GoToXY( 2 , 19 );
            WRITE('>');
            Read_Edited_String(FileName);
            WRITELN;

            IF ( ( LENGTH( FileName ) = 0 ) OR ( FileName = CHR( ESC ) ) ) THEN
               BEGIN
                  Quit          := TRUE;
                  Transfer_Kind := None;
               END
            ELSE
               BEGIN

                  Add_Path( FileName, Download_Dir_Path, Saved_Kbd_File_Name );

                  ASSIGN(AFile,Saved_Kbd_File_Name);
                     (*!I- *)
                  RESET( AFile );
                     (*!I+ *)

                  IF ( Int24Result <> 0 ) THEN
                     OK_File_Name := TRUE
                  ELSE
                     BEGIN
                        OK_File_Name := YesNo( Saved_Kbd_File_Name + ' exists, overwrite (Y/N) ? ');
                           (*!I-*)
                        CLOSE( AFile );
                           (*!I+*)
                        I := Int24Result;
                     END;

               END;

         UNTIL( OK_File_Name OR Quit );

         IF ( NOT Quit ) THEN
            BEGIN

               ASSIGN( AFile, Saved_Kbd_File_Name );
                     (*!I- *)
               REWRITE( AFile );
                     (*!I+ *)

               IF ( Int24Result <> 0 ) THEN
                  BEGIN
                     Transfer_Kind := None;
                     WRITE('*** Can''t open file, receive cancelled ***');
                     Window_Delay;
                  END;

                  (*!I-*)
               CLOSE( AFile );
                  (*!I+*)

               I := INT24Result;

            END;

      END  (* Get file name *);
                                   (* Remove this window            *)

   Restore_Screen_And_Colors( Saved_Screen );

   Use_Time_Sent := Use_Block_Zero;

                                   (* Return transfer protocol type *)

   Get_Download_Protocol := Transfer_Kind;

END   (* Get_Download_Protocol *);
