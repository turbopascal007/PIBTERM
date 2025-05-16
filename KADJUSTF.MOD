(*----------------------------------------------------------------------*)
(*    Kermit_Adjust_File_Name --- Adjust file name of incoming file     *)
(*----------------------------------------------------------------------*)

FUNCTION Kermit_Adjust_File_Name(     Old_Name : AnyStr;
                                  VAR New_Name : AnyStr  ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Kermit_Adjust_File_Name                              *)
(*                                                                      *)
(*     Purpose:    Adjust file name of incoming file for Kermit         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        OK := Kermit_Adjust_File_Name(     Old_Name : AnyStr;         *)
(*                                       VAR New_Name : AnyStr )        *)
(*                                       : BOOLEAN;                     *)
(*                                                                      *)
(*           Old_Name --- old file name                                 *)
(*           New_Name --- new file name                                 *)
(*           OK       --- TRUE if new file name could be found          *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Split_File_Name                                               *)
(*        Check_If_File_Exists                                          *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine prevents an existing file from being overwritten *)
(*        by changing the file name.                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Temp_Fn : AnyStr;
   Drive   : CHAR;
   Path    : AnyStr;
   FileName: AnyStr;
   FileType: AnyStr;
   Bad_Name: BOOLEAN;
   IPos    : INTEGER;
   OK      : BOOLEAN;

BEGIN (* Kermit_Adjust_File_Name *)

                                   (* Convert file name to upper case *)

   Temp_Fn := UpperCase( Old_Name );

                                   (* Extract file name parts         *)

   Split_File_Name( Temp_Fn, Drive, Path, FileName, FileType, Bad_Name );

                                   (* Fix up path            *)
   IF ( Path = '' ) THEN
      IF  ( Drive = ' ' ) THEN
         Path := Download_Dir_Path
      ELSE
         Path := Drive + ':'
   ELSE
      IF ( Drive <> ' ') THEN
         Path := Drive + ':' + Path;

                                   (* If file name bad, quit *)
   IF ( NOT Bad_Name ) THEN
      BEGIN                        (* Legitimate file name, proceed *)

         Temp_Fn  := FileName + DUPL(' ' , 8 - LENGTH( FileName ) ) + '.' +
                     FileType + DUPL(' ' , 3 - LENGTH( FileType ) );
         OK       := FALSE;

         REPEAT                    (* First try adding in &s to replace *)
                                   (* blanks in file name               *)

            New_Name := Temp_Fn;
            IPos     := POS( ' ', New_Name );

            IF ( IPos <> 0 ) THEN
               BEGIN
                  DELETE( New_Name, IPos, 1 );
                  INSERT( '&',     New_Name,   IPos);
                  Temp_Fn := New_Name;
                  WHILE ( POS(' ' , New_Name ) <> 0 ) DO
                     DELETE( New_Name, POS(' ',New_Name), 1 );
                  OK := ( NOT Check_If_File_Exists( New_Name , Path ) );
               END;

         UNTIL ( OK OR ( IPos = 0 ) );

                                   (* If that didn't work, try replacing     *)
                                   (* file name characters with &s, starting *)
                                   (* at end of file name.                   *)

         IF ( NOT OK ) THEN
            BEGIN
               IPos := LENGTH( New_Name );
               REPEAT
                  IF ( ( New_Name[IPos] <> '&' ) AND
                       ( New_Name[IPos] <> '.' ) ) THEN
                     BEGIN
                        New_Name[IPos] := '&';
                        OK := ( NOT Check_If_File_Exists( New_Name , Path ) );
                     END
                  ELSE
                     IPos := IPos - 1;
               UNTIL ( IPos <= 0 ) OR OK;
            END;

      END (* Legitimate file name *)
   ELSE
      OK := FALSE;

   Kermit_Adjust_File_Name := OK;

END    (* Kermit_Adjust_File_Name *);
