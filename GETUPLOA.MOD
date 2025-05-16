(*----------------------------------------------------------------------*)
(*       Get_Upload_Protocol --- Get Upload File Transfer Protocol      *)
(*----------------------------------------------------------------------*)

FUNCTION Get_Upload_Protocol : Transfer_Type ;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Get_Upload_Protocol                                  *)
(*                                                                      *)
(*     Purpose:    Gets file name and transfer protocol for upload.     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Transtyp := Get_Upload_Protocol: Transfer_Type;               *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Get_Auto_File_Name                                            *)
(*        Display_Transfer_Types                                        *)
(*        Restore_Screen_And_Colors                                     *)
(*        Read_Edited_String                                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Transfer_Kind : Transfer_Type;
   I             : INTEGER;
   AFile         : FILE;

BEGIN (* Get_Upload_Protocol *)
                                   (* Copy keyboard data before we screw *)
                                   (* it up so we can get file name      *)

   Saved_Kbd_File_Name := Keyboard_Line;

   IF Auto_Find_FileNames THEN
      Get_Auto_File_Name( Saved_Kbd_File_Name , FileName )
   ELSE
      FileName := '';

                                   (* No protocol yet *)
   Get_Upload_Protocol := None;
                                   (* Display menu of transfer types *)
                                   (* and get transfer kind.         *)

   Display_Transfer_Types( 'Choose protocol: ',
                           Default_Transfer_Type,
                           FALSE,
                           3, 10, 50, 21, 11,
                           FALSE,
                           Transfer_Kind );

                                   (* Get file name to transfer *)

   IF ( Transfer_Kind = None ) THEN
      BEGIN
         Restore_Screen_And_Colors( Saved_Screen );
         Get_Upload_Protocol := Transfer_Kind;
         EXIT;
      END;

   IF ( Transfer_Kind <> Kermit ) THEN
      BEGIN

         GoToXY( 2 , 18 );
         WRITE('Enter Filename.Ext: ');
         GoToXY( 2 , 19 );
         WRITE('>');
         ClrEol;
         Read_Edited_String(FileName);
         WRITELN;

         IF ( ( LENGTH( FileName ) = 0 ) OR ( FileName = CHR( ESC ) ) ) THEN
            BEGIN
               Transfer_Kind := None;
               Restore_Screen_And_Colors( Saved_Screen );
               EXIT;
            END;

      END;
                                   (* Check that file exists *)

   IF Single_File_Protocol[Transfer_Kind] THEN
      BEGIN

         ASSIGN(AFile,FileName);
            (*!I- *)
         RESET(AFile);
            (*!I+ *)

         IF ( Int24Result <> 0 ) THEN
            BEGIN
               Transfer_Kind := None;
               WRITE('*** File not found, send cancelled ***');
               Window_Delay;
            END;

            (*!I-*)
         CLOSE( AFile );
            (*!I+*)

         I := Int24Result;

      END;
                                   (* Remove this window            *)

   Restore_Screen_And_Colors( Saved_Screen );

                                   (* Return transfer protocol type *)

   Get_Upload_Protocol := Transfer_Kind;

END   (* Get_Upload_Protocol *);
