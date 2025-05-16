(*----------------------------------------------------------------------*)
(*           Get_File_Size --- Get size in bytes for a file             *)
(*----------------------------------------------------------------------*)

FUNCTION Get_File_Size( Fname: AnyStr; VAR OpenOK : BOOLEAN ): LONGINT;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_File_Size                                        *)
(*                                                                      *)
(*     Purpose:    Get size in bytes for a file                         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Fsize := Get_File_Size( Fname      : AnyStr;                  *)
(*                                VAR OpenOK : BOOLEAN ) : REAL;        *)
(*                                                                      *)
(*           Fname  --- name of file to find size of                    *)
(*           OpenOK --- set TRUE if file opened successfully            *)
(*           Fsize  --- file size in bytes                              *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        RESET                                                         *)
(*        Int24Result                                                   *)
(*        ASSIGN                                                        *)
(*        LongFileSize                                                  *)
(*        Close                                                         *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The file must not already be opened before calling this       *)
(*        routine.                                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   F : FILE OF BYTE;
   I : INTEGER;

BEGIN (* Get_File_Size *)

   Get_File_Size := 0;
   FileMode      := 0;

   ASSIGN( F , Fname );
   RESET ( F );

   FileMode      := 2;

   IF ( Int24Result = 0 ) THEN
      BEGIN
         Get_File_Size := FileSize( F );
         OpenOK := TRUE;
      END
   ELSE
      OpenOK := FALSE;

   CLOSE( F );

   I := INT24Result;

END   (* Get_File_Size *);
