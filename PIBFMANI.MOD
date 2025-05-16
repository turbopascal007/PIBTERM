(*----------------------------------------------------------------------*)
(*        PibFileManipulation --- File Manipulation for Turbo           *)
(*----------------------------------------------------------------------*)

PROCEDURE PibFileManipulation( VAR File_Done : BOOLEAN;
                               VAR Do_Editing: BOOLEAN;
                               VAR Do_Viewing: BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  PibFileManipulation                                  *)
(*                                                                      *)
(*     Purpose:    Central control routine for file manipulation        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        PibFileManipulation( VAR File_Done : BOOLEAN;                 *)
(*                             VAR Do_Editing: BOOLEAN;                 *)
(*                             VAR Do_Viewing: BOOLEAN );               *)
(*                                                                      *)
(*           File_Done  --- TRUE if through with file manipulation      *)
(*           Do_Editing --- TRUE to do editing                          *)
(*           Do_Viewing --- TRUE to do viewing                          *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine exists to centralize file manipulation so that   *)
(*        the Turbo Pascal overlay scheme will work.                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   File_Menu     : Menu_Type;
   I             : INTEGER;
   Done_Files    : BOOLEAN;

BEGIN (* PibFileManipulation *)
                                   (* Get file manipulation menu *)

   Make_A_Menu( File_Menu, 10, 10, 30, 0, 0, 10,
                'Choose file function: ',
                'A)ctive directory change;C)opy file;D)irectory display;' +
                'E)dit file;F)ree space on drive;L)ogged drive change;'   +
                'P)rint a file;V)iew a file;Z)ap (delete) file;Q)uit;',
                FALSE );

   Done_Files := FALSE;
   Do_Editing := FALSE;
   Do_Viewing := FALSE;

   REPEAT

      Menu_Display_Choices( File_Menu );
      I := Menu_Get_Choice( File_Menu , Erase_Menu );

      IF ( I < 0 ) THEN
         I := 10;

      CASE I OF
         1:  Change_Subdirectory;
         2:  Copy_A_File;
         3:  View_Directory;
         4:  BEGIN
                Do_Editing := TRUE;
                Done_Files := TRUE;
             END;
         5:  Find_Free_Space_On_Drive;
         6:  Log_Drive_Change;
         7:  Print_A_File( '' );
         8:  BEGIN
                Do_Viewing := TRUE;
                Done_Files := TRUE;
             END;
         9:  Delete_A_File;
        10:  Done_Files := TRUE;
        ELSE;
      END (* Case *);

   UNTIL Done_Files;

   File_Done := NOT ( Do_Editing OR Do_Viewing );

END   (* PibFileManipulation *);

