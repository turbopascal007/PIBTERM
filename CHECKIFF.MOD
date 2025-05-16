(*----------------------------------------------------------------------*)
(*              Check_If_File_Exists --- Check if file exists           *)
(*----------------------------------------------------------------------*)

FUNCTION Check_If_File_Exists( File_Name : AnyStr; File_Path : AnyStr ): BOOLEAN;

VAR
   File_Entry: SearchRec;

BEGIN (* Check_If_File_Exists *)

   Add_Path( File_Name, File_Path, File_Name );

   FindFirst( File_Name, AnyFile, File_Entry );

   Check_If_File_Exists := ( DosError = 0 );

END   (* Check_If_File_Exists *);
