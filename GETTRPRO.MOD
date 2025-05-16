(*----------------------------------------------------------------------*)
(*          Get_Transfer_Protocol --- Get File Transfer Protocol        *)
(*----------------------------------------------------------------------*)

FUNCTION Get_Transfer_Protocol( Direction : CHAR ) : Transfer_Type ;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Get_Transfer_Protocol                                *)
(*                                                                      *)
(*     Purpose:    Gets file name and transfer protocol.                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Transtyp := Get_Transfer_Protocol( Direction : CHAR )         *)
(*                    : Transfer_Type;                                  *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Transfer_Kind : Transfer_Type;
   I             : INTEGER;
   Get_FileName  : BOOLEAN;
   AFile         : FILE;

BEGIN (* Get_Transfer_Protocol *)
                                   (* Copy keyboard data before we screw *)
                                   (* it up so we can get file name      *)

   Saved_Kbd_File_Name := Keyboard_Line;

                                   (* No file name yet *)
   FileName            := '';
                                   (* No protocol yet *)
   Get_Transfer_Protocol := None;

                                   (* Display menu of transfer types *)
                                   (* and get transfer kind.         *)

   Display_Transfer_Types( 'send', Transfer_Kind );

                                   (* Get file name to transfer *)

   Get_FileName := ( Transfer_Kind <> None );
   IF ( Transfer_Kind = Kermit ) THEN
      Get_FileName := FALSE;

   IF Get_FileName THEN
      BEGIN

         GoToXY( 2 , 18 );
         WRITE('Enter Filename.Ext: ');
         GoToXY( 2 , 19 );
         WRITE('>');
         ClrEol;
         IF Auto_Find_FileNames THEN
            Get_Auto_File_Name( Saved_Kbd_File_Name , FileName );
         Read_Edited_String(FileName);
         WRITELN;

         IF ( LENGTH( FileName ) = 0 ) THEN
            BEGIN
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

   Get_Transfer_Protocol := Transfer_Kind;

END   (* Get_Transfer_Protocol *);
