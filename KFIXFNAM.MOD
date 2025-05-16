(*----------------------------------------------------------------------*)
(*    Fix_File_Name --- Fix file name from remote to be MS DOS style    *)
(*----------------------------------------------------------------------*)

FUNCTION Fix_File_Name( FileName : AnyStr ) : AnyStr;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Fix_File_Name                                        *)
(*                                                                      *)
(*     Purpose:    Fixes received file name to be MS DOS style          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Fixed_Name := Fix_File_Name( FileName : AnyStr ) : AnyStr;    *)
(*                                                                      *)
(*           FileName  --- name of file from remote system              *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Temp_Name : AnyStr;
   Suffix    : STRING[3];
   I         : INTEGER;
   L         : INTEGER;
   Dot_Found : BOOLEAN;
   Done      : BOOLEAN;

(* STRUCTURED *) CONST
   Legal_File_Name_Chars : SET OF CHAR = ['A'..'Z','0'..'9','$','&',
                                          '#','%','''','(',')','-',
                                          '@','^','{','}','~','`',
                                          '!','_'];

BEGIN (* Fix_File_Name *)

   Suffix    := '';
   Temp_Name := '';
   Dot_Found := FALSE;
   Done      := FALSE;
   L         := LENGTH( FileName );

                                   (* Throw away anything in front *)
                                   (* of a colon.                  *)
   I := POS( ':' , FileName );

   IF ( I > 0 ) THEN
      FileName := COPY( FileName, SUCC( I ), L - I );

                                   (* Look for trailing 'name.ext' *)
   L := LENGTH( FileName );

   REPEAT

      CASE Dot_Found OF

         TRUE:  BEGIN
                   IF FileName[L] <> '.' THEN
                      Temp_Name := UpCase( FileName[L] ) + Temp_Name;
                END;

         FALSE: IF FileName[L] = '.' THEN
                   BEGIN
                      Dot_Found := TRUE;
                      IF ( LENGTH( Temp_Name ) <= 3 ) THEN
                         Suffix := Temp_Name
                      ELSE
                         Suffix := COPY( Temp_Name, 1, 3 );
                      Temp_Name := '';
                   END
                ELSE
                   Temp_Name := UpCase( FileName[L] ) + Temp_Name;

      END (* CASE *);

      L    := PRED( L );
      Done := Done OR ( L < 1 );

   UNTIL Done;

                                   (* Evict illegal characters *)
   L := LENGTH( Temp_Name );

   FOR I := 1 TO L DO
      IF ( NOT ( Temp_Name[I] IN Legal_File_Name_Chars ) ) THEN
         DELETE( Temp_Name, I, 1 );

   L := LENGTH( Suffix );

   FOR I := 1 TO L DO
      IF ( NOT ( Suffix[I] IN Legal_File_Name_Chars ) ) THEN
         DELETE( Suffix, I, 1 );

                                   (* Truncate name to 8 characters *)

   IF ( LENGTH( Temp_Name ) > 8 ) THEN
      Temp_Name := COPY( Temp_Name, 1, 8 );

                                   (* Append suffix if '.' found *)
   IF Dot_Found THEN
      Temp_Name := Temp_Name + '.' + Suffix;

   Fix_File_Name := Temp_Name;

END   (* Fix_File_Name *);
