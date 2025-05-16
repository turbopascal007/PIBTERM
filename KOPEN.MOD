(*----------------------------------------------------------------------*)
(*         Open_File --- Open file for use by Kermit protocol routines  *)
(*----------------------------------------------------------------------*)

PROCEDURE Open_File(     File_Mode : Kermit_File_Modes;
                         FileName  : AnyStr;
                     VAR FullName  : AnyStr             );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Open_File                                            *)
(*                                                                      *)
(*     Purpose:    Opens file for use by Kermit routines                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Open_File(     File_Mode : Kermit_File_Modes;                 *)
(*                       FileName  : AnyStr;                            *)
(*                   VAR FullName  : AnyStr  );                         *)
(*                                                                      *)
(*           File_Mode --- whether file is to be opened for read or     *)
(*                         write                                        *)
(*           FileName  --- name of file to open                         *)
(*           FullName  --- actual name used in open                     *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Adjust_Fn                                                     *)
(*        Open_For_Write                                                *)
(*        Int24Result                                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Count     : INTEGER;
   Space_Pos : INTEGER;
   New_Name  : AnyStr;
   Err       : INTEGER;
   Save_Name : AnyStr;
   IPos      : INTEGER;

(*----------------------------------------------------------------------*)
(*                Open_For_Write --- Open file for output               *)
(*----------------------------------------------------------------------*)

PROCEDURE Open_For_Write(     FileName : AnyStr;
                          VAR Open_OK  : BOOLEAN  );

VAR
   FSize : LONGINT;

BEGIN (* Open_For_Write *)
                                   (* Check if file exists *)

   Add_Path( FileName, Download_Dir_Path, FullName );

   FSize := Get_File_Size( FullName , Open_OK );

                                   (* Error if file exists *)
   IF Open_OK THEN
      Open_OK := FALSE
   ELSE                            (* Otherwise, new file -- open it *)
      BEGIN

         ASSIGN ( XFile , FullName );
         REWRITE( XFile , 1        );

         IF ( Int24Result <> 0 ) THEN
            Open_OK := FALSE
         ELSE
            BEGIN (* FileName is new file, open it *)

               File_Records := 0;
               Open_OK      := TRUE;
               File_Open    := TRUE;
               Buffer_Num   := 0;

            END;

      END;

END    (* Open_For_Write *);

(*----------------------------------------------------------------------*)
(*                  Open_For_Read --- Open file for input               *)
(*----------------------------------------------------------------------*)

PROCEDURE Open_For_Read(     FileName : AnyStr;
                         VAR Open_OK  : BOOLEAN  );

VAR
   DateTim  : LONGINT;
   KDateTim : ARRAY[1..2] OF WORD ABSOLUTE DateTim;
   Save_Date: Date_Format_Type;
   Save_Time: Time_Format_Type;

BEGIN (* Open_For_Read *)
                                   (* Append upload path if needed *)

   Add_Path( FileName, Upload_Dir_Path, FullName );

   File_Records := Get_File_Size( FullName , Open_OK );

                                   (* If there, close and open with file *)
                                   (* handle.                            *)
   IF Open_OK THEN
      BEGIN
                                   (* Indicate file opened OK *)
         File_Open    := TRUE;

         STR( File_Records , Kermit_CFile_Size );

                                   (* Display it if status display on *)

         IF Display_Status THEN
            BEGIN
               GoToXY( 25 , 4 );
               WRITE ( Kermit_CFile_Size );
               ClrEol;
            END;
                                   (* No characters sent yet *)
         Buffer_Num   := 0;
                                   (* Open as untyped file *)

         FileMode := 0;

         ASSIGN( XFile , FullName );
         RESET ( XFile , 1 );

         FileMode := 2;

         Err := Int24Result;
                                   (* Get file date and time for  *)
                                   (* attribute packet.           *)

                                   (* --- Get date/time from DOS  *)

         GetFTime( XFile , DateTim );

                                   (* --- Save current time/date formats *)

         Save_Date := Date_Format;
         Save_Time := Time_Format;
                                   (* --- Set time/date formats we want  *)
         Date_Format := YMD_Style;
         Time_Format := Military_Time;

                                   (* --- Get character form of date/time *)

         Dir_Convert_Date( KDateTim[1] , Kermit_CFile_Date );
         Dir_Convert_Time( KDateTim[2] , Kermit_CFile_Time );

                                   (* --- Restore proper date/time formats *)

         Date_Format := Save_Date;
         Time_Format := Save_Time;
                                   (* --- Strip slashes from date      *)

         WHILE ( POS( '/' , Kermit_CFile_Date ) > 0 ) DO
            DELETE( Kermit_CFile_Date , POS( '/' , Kermit_CFile_Date ), 1 );

         Kermit_CFile_Date := '19' + Kermit_CFile_Date;

                                   (* Indicate what file we're sending *)

         Write_Log('Sending file ' + FileName , TRUE , FALSE);
         Write_Log('Size of file to send is ' + Kermit_CFile_Size + ' bytes',
                   TRUE , FALSE);

      END
   ELSE
      BEGIN
         Open_OK := FALSE;
         Display_Kermit_Message( 'File ' + FileName + ' does not exist.');
      END;

END    (* Open_For_Read *);

(*----------------------------------------------------------------------*)

BEGIN (* Open_File *)
                                   (* Remember original file name    *)

   Save_Name := UpperCase( FileName );
   FullName  := '';
                                   (* Select open based upon whether *)
                                   (* file is to be read or written  *)
   CASE File_Mode OF

                                   (* Open file for reading *)

      Read_Open : Open_For_Read( FileName, Open_OK );

                                   (* Open file for writing *)
      Write_Open: BEGIN
                                   (* Ensure legal file name          *)

                     FileName := Fix_File_Name( FileName );

                                   (* Try opening under provided name *)

                     Open_For_Write( FileName, Open_OK );

                                   (* If file exists (Open_OK = FALSE), *)
                                   (* then try adjusting name until     *)
                                   (* non-existent name found.          *)

                     New_Name := FileName;

                     IF ( NOT Open_OK ) THEN
                        IF Kermit_Adjust_File_Name( FileName , New_Name ) THEN
                           Open_For_Write( New_Name , Open_OK );

                     IF Open_OK THEN
                        BEGIN
                           IF ( New_Name <> Save_Name ) THEN
                              Display_Kermit_Message_2('Filename ' +
                                                        Save_Name  +
                                                       ' changed to: ' +
                                                        New_Name );
                           Write_Log('Receiving file ' + FileName , TRUE , FALSE);

                        END
                     ELSE
                        Display_Kermit_Message_2('Filename ' +
                                                  Save_Name  +
                                                 ' could not be opened.');

                  END    (* Write_Open *);

   END (* CASE *);

END     (* Open_File *);
