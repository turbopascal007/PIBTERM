(*----------------------------------------------------------------------*)
(*       Split_File_Name --- Return components of a file name           *)
(*----------------------------------------------------------------------*)

PROCEDURE Split_File_Name(     FileRef    : AnyStr;
                           VAR Drive      : CHAR;
                           VAR Path       : AnyStr;
                           VAR FileName   : AnyStr;
                           VAR FileType   : AnyStr;
                           VAR Bogus_Name : BOOLEAN  );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Split_File_Name                                      *)
(*                                                                      *)
(*     Purpose:    Splits file name into component parts                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Split_File_Name(     FileRef    : AnyStr;                     *)
(*                         VAR Drive      : AnyStr;                     *)
(*                         VAR Path       : AnyStr;                     *)
(*                         VAR FileName   : AnyStr;                     *)
(*                         VAR FileType   : AnyStr;                     *)
(*                         VAR Bogus_Name : BOOLEAN );                  *)
(*                                                                      *)
(*           FileRef    --- original file specification                 *)
(*           Drive      --- drive spec if any                           *)
(*           Path       --- path spec if any                            *)
(*           FileName   --- main file name                              *)
(*           FileType   --- file type if any                            *)
(*           Bogus_Name --- TRUE if name is bad, FALSE otherwise        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Count      : INTEGER;
   IPos       : INTEGER;
   L          : INTEGER;

BEGIN (* Split_File_Name *)
                                   (* Assume file name bad.       *)
   Bogus_Name := TRUE;
                                   (* Defaults                    *)
   Drive      := ' ';
   Path       := '';
   FileName   := '';
   FileType   := '';
                                   (* Trim the file name          *)

   FileRef    := LTrim( Trim( FileRef ) );

                                   (* Remove any drive identifier *)

   IPos := POS(':', FileRef);

   IF ( IPos <> 0 ) THEN
      IF ( IPos = 2 ) THEN
         BEGIN
            Drive   := FileRef[1];
            FileRef := COPY( FileRef, 3, LENGTH( FileRef ) - 2 );
         END
      ELSE
         EXIT;
                                   (* Extract the path if any          *)

   IF ( POS( '\' , FileRef ) <> 0 ) THEN
      BEGIN

         L    := LENGTH( FileRef );
         IPos := L + 1;

         REPEAT
            DEC( IPos );
         UNTIL ( IPos <= 1 ) OR ( FileRef[IPos] = '\' );

         Path    := COPY( FileRef, 1, IPos );
         FileRef := COPY( FileRef, IPos + 1, L - IPos );

      END;
                                   (* No file reference after path --  *)
                                   (* exit.                            *)
   IF ( FileRef = '' ) THEN
      BEGIN
         Bogus_Name := FALSE;
         EXIT;
      END;
                                   (* Extract file type if any         *)
   IPos := POS( '.' , FileRef );

   IF ( IPos = 0 ) THEN
      BEGIN
         FileName   := FileRef;
         Bogus_Name := FALSE;
      END
   ELSE
      BEGIN
         FileName := COPY( FileRef, 1, PRED( IPos ) );
         FileType := COPY( FileRef, SUCC( IPos ), LENGTH( FileRef ) - IPos );
         Bogus_Name := ( LENGTH( FileName ) <= 0 );
      END;

END    (* Split_File_Name *);
