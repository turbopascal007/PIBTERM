(*----------------------------------------------------------------------*)
(*        Rewrite_Dialing_Directory --- Rewrite dialing directory       *)
(*----------------------------------------------------------------------*)

PROCEDURE Rewrite_Dialing_Directory;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Rewrite_Dialing_Directory                            *)
(*                                                                      *)
(*     Purpose:    Rewrites the dialing directory                       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Rewrite_Dialing_Directory;                                    *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        Watch out -- some tricky stuff with string data and lengths   *)
(*        is used here.                                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I         : INTEGER;
   Ierr      : INTEGER;
   F         : TEXT;
   Phone_Str : AnyStr;
   Phone_Name: AnyStr;
   Full_Name : AnyStr;

BEGIN (* Rewrite_Dialing_Directory *)

                                   (* Don't update non-existent directory! *)

   IF ( Dialing_Directory = NIL ) THEN EXIT;

   Add_Path( Dialing_File_Name, Home_Dir, Full_Name );

   WRITELN;
   ClrEol;

   WRITE('Rewriting updated phone directory to ',Dialing_File_Name);
   ClrEol;
   WRITELN;

   ASSIGN    ( F , Full_Name );
   SetTextBuf( F , Sector_Data );
   REWRITE   ( F );

   IF ( INT24Result = 0 ) THEN
      BEGIN

         Phone_Str[0] := CHR( Dialing_Dir_Entry_Length );

         FOR I := 1 TO Dialing_Dir_Size DO
            BEGIN
               MOVE( Dialing_Directory^[I], Phone_Str[1],
                     Dialing_Dir_Entry_Length  );
               WRITELN( F, Phone_Str );
               Ierr := Int24Result;
            END;

         CLOSE( F );
         Ierr := Int24Result;

         Any_Dialing_Changes := FALSE;

         WRITELN;
         ClrEol;

         WRITE('Phone directory ',Dialing_File_Name,' updated.');
         ClrEol;
         WRITELN;

      END
   ELSE
      BEGIN
         WRITELN;
         ClrEol;
         WRITE('Can''t update phone directory ',Full_Name);
         ClrEol;
      END;

   Window_Delay;

END   (* Rewrite_Dialing_Directory *);
