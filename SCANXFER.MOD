(*----------------------------------------------------------------------*)
(*          Scan_Xfer_List --- Search transfer list for file name       *)
(*----------------------------------------------------------------------*)

FUNCTION Scan_Xfer_List( File_Name : AnyStr ) : INTEGER;

VAR
   SDone          : BOOLEAN;
   XFer_Line      : STRING[14];
   Xfer_List_File : Text_File (* File transfer list file *);
   I              : INTEGER;

BEGIN (* Scan_Xfer_List *)
                                   (* Open xferlist file *)

   ASSIGN( Xfer_List_File , Home_Dir + 'PIBTERM.XFR' );
      (*!I-*)
   RESET( Xfer_List_File );
      (*!I+*)
                                   (* If not there, no files to check *)
   IF Int24Result = 0 THEN         (* If there, check the file        *)
      BEGIN

                                   (* Assume file not found *)
         Scan_Xfer_List := 0;

         SDone     := FALSE;
         File_Name := UpperCase( TRIM( File_Name ) );

         REPEAT

            READLN( Xfer_List_File , Xfer_Line );

            IF ( ORD( XFer_Line[0] ) > 0 ) THEN
               IF ( XFer_Line[1] <> '*' ) THEN
                  BEGIN
                     IF ( TRIM( Xfer_Line ) = File_Name ) THEN
                        BEGIN
                           SDone          := TRUE;
                           Scan_Xfer_List := 1;
                        END;
                  END;

         UNTIL ( EOF( Xfer_List_File ) OR SDone );

      END
   ELSE
                                   (* No xferlist -- indicate that *)
      Scan_Xfer_List := 2;

      (*!I-*)
   CLOSE( Xfer_List_File );
      (*!I+*)

   I := Int24Result;

END   (* Scan_Xfer_List *);
