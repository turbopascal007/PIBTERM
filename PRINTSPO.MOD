(*----------------------------------------------------------------------*)
(* Print_Spooled_File -- Write a character to printer from spooled file *)
(*----------------------------------------------------------------------*)

PROCEDURE Print_Spooled_File;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Print_Spooled_File                                   *)
(*                                                                      *)
(*     Purpose:    Writes character to printer from spooled file        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Print_Spooled_File;                                           *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Close                                                         *)
(*        BlockRead                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Err : INTEGER;

BEGIN (* Print_Spooled_File *)

   IF ( Spool_Buffer_Pos > Spool_Buffer_Count ) THEN
      BEGIN
         BlockRead( Spool_File, Spool_Buffer^,
                    Max_Spool_Buffer_Count,
                    Spool_Buffer_Count );
         Err              := Int24Result;
         Spool_Buffer_Pos := 0;
      END;

   Spool_Buffer_Pos := SUCC( Spool_Buffer_Pos );

   IF ( Spool_Buffer_Count > 0 ) THEN
      Write_Prt( Spool_Buffer^[ Spool_Buffer_Pos ] )
   ELSE
      BEGIN
         CLOSE( Spool_File );
         Err            := Int24Result;
         Print_Spooling := FALSE;
         DISPOSE( Spool_Buffer );
      END;

END   (* Print_Spooled_File *);
