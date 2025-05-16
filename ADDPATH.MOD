(*----------------------------------------------------------------------*)
(*             Add_Path --- Add path to file spec if necessary          *)
(*----------------------------------------------------------------------*)

PROCEDURE Add_Path( VAR File_Name      : AnyStr;
                    VAR Path           : AnyStr;
                    VAR Full_File_Name : AnyStr  );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Add_Path                                              *)
(*                                                                      *)
(*     Purpose:   Adds path to file name if not already present.        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Add_Path( VAR File_Name      : AnyStr;                        *)
(*                  VAR Path           : AnyStr;                        *)
(*                  VAR Full_File_Name : AnyStr  );                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   MyPath : AnyStr;
   L      : INTEGER;

BEGIN (* Add_Path *)

   MyPath := Path;

   L := LENGTH( Mypath );

   IF ( L > 0 ) THEN
      IF ( MyPath[L] <> ':' ) THEN
         IF ( MyPath[L] <> '\' ) THEN
            MyPath := MyPath + '\';

   IF ( POS( '\' , File_Name ) = 0 ) AND
      ( POS( ':' , File_Name ) = 0 ) THEN
      Full_File_Name := MyPath + File_Name
   ELSE
      Full_File_Name := File_Name;

END   (* Add_Path *);
