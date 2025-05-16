(*----------------------------------------------------------------------*)
(*      View_Directory --- List files in current directory              *)
(*----------------------------------------------------------------------*)

PROCEDURE View_Directory;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  View_Directory                                       *)
(*                                                                      *)
(*     Purpose:    Lists files in current MSDOS directory               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        View_Directory;                                               *)
(*                                                                      *)
(*     Calls:   View_Prompt                                             *)
(*              Save_Screen                                             *)
(*              Restore_Screen_And_Colors                               *)
(*              Draw_Titled_Box                                         *)
(*              GetDir                                                  *)
(*              ChDir                                                   *)
(*              FindFirst                                               *)
(*              FindNext                                                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Drive_Ch            : CHAR;
   File_Entry          : SearchRec;
   S_File_Time         : STRING[8];
   S_File_Date         : STRING[8];
   S_File_Xmodem_Time  : STRING[8];
   S_File_Attributes   : STRING[6];
   I                   : INTEGER;
   L                   : INTEGER;
   Dir_Spec            : AnyStr;
   Save_Dir_Spec       : AnyStr;
   View_Ch             : CHAR;
   Total_File_Size     : LONGINT;
   Total_File_Count    : LONGINT;
   Free_Space          : LONGINT;
   Path_Name           : AnyStr;
   File_Ref_Name       : STRING[12];
   TTime               : LONGINT;

LABEL
   View_Exit;

BEGIN (* View_Directory *)
                                   (*  Draw view menu *)

   Draw_Titled_Box( Saved_Screen, 5, 4, 75, 24, 'View Directory' );

   Dir_Spec := '';
   TextColor( Menu_Text_Color_2 );
   WRITELN('Enter search specification (*.* for all): ');
   WRITE  ('>');
   TextColor( Menu_Text_Color );
   Read_Edited_String( Dir_Spec );

   FOR I := 1 TO 3 DO
      BEGIN
         GoToXY( 1 , I );
         ClrEol;
      END;

   IF ( Dir_Spec = CHR( ESC ) ) THEN
      GOTO View_Exit;
                                   (* Get current drive and path *)
   GetDir( 0 , Path_Name );
                                   (* If no spec entered, use current path *)
   IF ( Dir_Spec = '' ) THEN
      Dir_Spec := '*.*';

   Add_Path( Dir_Spec, Path_Name, Dir_Spec );

   IF ( Dir_Spec[LENGTH(Dir_Spec)] = ':' ) THEN
      Dir_Spec := Dir_Spec + '*.*';

   WHILE ( POS( '\\', Dir_Spec ) > 0 ) DO
      DELETE( Dir_Spec, POS( '\\', Dir_Spec ), 1 );

   IF ( POS( ':' , Dir_Spec ) > 0 ) THEN
      Drive_Ch := Dir_Spec[1]
   ELSE
      Drive_Ch := Path_Name[1];
                                   (* Display directory title *)

   RvsVideoOn( Menu_Text_Color , BLACK );

   GoToXY( 1 , 1 );

   WRITE('LISTING OF DIRECTORY: ',Dir_Spec);
   ClrEol;
   WRITELN;
   WRITE(' File Name         Size     Date     Time  Attributes  Xfer Time');
   ClrEol;
   WRITELN;

   RvsVideoOff( Menu_Text_Color , BLACK );

                                   (* Reset window so header doesn't vanish *)
   PibTerm_Window( 6, 7, 74, 23 );
   GoToXY( 1 , WhereY );
                                   (* List the directory contents   *)

   View_Count := 0;

   FindFirst( Dir_Spec, AnyFile, File_Entry );

   View_Done  := ( DosError <> 0 );

   Total_File_Size  := 0;
   Total_File_Count := 0;

   WHILE( NOT View_Done ) DO
      WITH File_Entry DO
         BEGIN
                                   (* == Display Next Directory Entry == *)

                                   (* Pick up creation date and time *)

            Dir_Convert_File_Date_And_Time( Time, S_File_Date, S_File_Time );

                                   (* Pick up file size *)

            Total_File_Size := Total_File_Size + Size;

                                   (* Pick up transfer time *)

            TTime := ROUND( ROUND( ( Size / 128.0 ) + 0.49 ) *
                                   ( Trans_Time_Val * 1.0 ) /
                                   ( Baud_Rate      * 1.0 ) );

            S_File_Xmodem_Time := TimeString( TTime , Military_Time );

                                   (* Determine attributes *)

            S_File_Attributes := '';

            IF ( Attr AND ReadOnly     ) <> 0 THEN
               S_File_Attributes := 'R';
            IF ( Attr AND Hidden       ) <> 0 THEN
               S_File_Attributes := S_File_Attributes + 'H';
            IF ( Attr AND SysFile      ) <> 0 THEN
               S_File_Attributes := S_File_Attributes + 'S';
            IF ( Attr AND VolumeID     ) <> 0 THEN
               S_File_Attributes := S_File_Attributes + 'V';
            IF ( Attr AND Directory    ) <> 0 THEN
               S_File_Attributes := S_File_Attributes + 'D';
            IF ( Attr AND Archive      ) <> 0 THEN
               S_File_Attributes := S_File_Attributes + 'A';

            IF ( S_File_Attributes = '' ) THEN
               S_File_Attributes := 'N';

                                   (* Display entry *)

            WRITELN( ' ', Name, DUPL( ' ' , 14 - LENGTH( Name ) ),
                     Size:8, ' ', S_File_Date, ' ',
                     S_File_Time,'  ',S_File_Attributes:10,'   ',
                     S_File_Xmodem_Time );

                                   (* Increment count of lines displayed *)

            INC( View_Count );

                                   (* Prompt if end of screen *)
            IF View_Count > 15 THEN
               View_Prompt( View_Done , View_Count );

                                   (* Increment file count *)

            INC( Total_File_Count );

            FindNext( File_Entry );
            View_Done := View_Done OR ( DosError <> 0 );

   END;
                                   (* Display total file size and free space *)
   WRITELN;

   INC( View_Count );
   IF View_Count > 15 THEN
      View_Prompt( View_Done , View_Count );

   Free_Space := DiskFree( SUCC( ORD( UpCase( Drive_Ch ) ) - ORD('A') ) );

   WRITE( Total_File_Size:8, ' bytes in ', Total_File_Count, ' files; ' );

   IF ( Free_Space >= 0 ) THEN
      WRITELN( Free_Space:8,' bytes free')
   ELSE
      WRITELN( ' drive cannot be accessed.');

   INC( View_Count );
   IF View_Count > 15 THEN
      View_Prompt( View_Done , View_Count );

                                   (* Issue final end-of-directory prompt *)

   RvsVideoOn( Menu_Text_Color , BLACK );

   WRITE('Viewing of directory complete. ',
         'Hit ESC to continue.');
   ClrEol;

   RvsVideoOff( Menu_Text_Color , BLACK );

                                   (* Swallow terminating character *)
   Read_Kbd( View_Ch );
   IF ( View_Ch = CHR( ESC ) ) AND PibTerm_KeyPressed THEN
      Read_Kbd( View_Ch );
                                   (* Restore previous screen *)
View_Exit:

   Restore_Screen_And_Colors( Saved_Screen );

END   (* View_Directory *);

(*----------------------------------------------------------------------*)
(*      Log_Drive_Change --- Change current logged drive                *)
(*----------------------------------------------------------------------*)

PROCEDURE Log_Drive_Change;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Log_Drive_Change                                     *)
(*                                                                      *)
(*     Purpose:    Change current logged drive                          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Log_Drive_Change                                              *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Drive_Path  : AnyStr;
   Drive_Ch    : CHAR;
   Drive_No    : INTEGER;
   Drive_Count : INTEGER;

BEGIN (* Log_Drive_Change *);
                                   (*  Draw logged drive change menu *)

   Draw_Titled_Box( Saved_Screen, 5, 10, 55, 15, 'Change Current Logged Drive' );

   GoToXY( 1 , 1 );

   GetDir( 0 , Drive_Path );

   Drive_Ch := Drive_Path[1];

   TextColor( Menu_Text_Color_2 );
   WRITE('Current logged drive is: ');
   TextColor( Menu_Text_Color );
   WRITE( Drive_Ch );

   GoToXY( 1 , 2 );

   TextColor( Menu_Text_Color_2 );
   WRITE('Enter letter for new logged drive: ');

   Read_Kbd( Drive_Ch );

   TextColor( Menu_Text_Color_2 );

   IF ( ( Drive_Ch = CHR( CR ) ) OR ( Drive_Ch = CHR( ESC ) ) ) THEN
      BEGIN
         WRITELN;
         WRITELN('*** Logged drive remains unchanged.')
      END
   ELSE
      BEGIN
                                (* Figure no. of drives in system *)

         TextColor( Menu_Text_Color );

         Drive_Ch := UpCase( Drive_Ch );

         WRITE( Drive_Ch );

         Drive_Count := Dir_Count_Drives;

                                (* Drive no. for entered letter   *)

         Drive_No := ORD( Drive_Ch ) - ORD( 'A' );

                                (* Check if drive legitimate      *)

         IF ( ( Drive_No < 0 ) OR ( Drive_No > Drive_Count ) ) THEN
            WRITELN('*** Invalid drive, logged drive unchanged.')
         ELSE
            BEGIN
                                (* Change default drive *)

               ChDir( Drive_Ch );

               IF ( Int24Result = 0 ) THEN
                  BEGIN

                     TextColor( Menu_Text_Color_2 );

                     WRITELN;
                     WRITE('*** Logged drive changed to ');

                     TextColor( Menu_Text_Color );
                     WRITE( Drive_Ch );

                  END
               ELSE
                  WRITELN('*** Invalid drive, logged drive unchanged.')

            END;

      END;

   Window_Delay;
                                   (* Restore previous screen *)

   Restore_Screen_And_Colors( Saved_Screen );

END   (* Log_Drive_Change *);

(*----------------------------------------------------------------------*)
(*       Change_Subdirectory --- Change current disk subdirectory       *)
(*----------------------------------------------------------------------*)

PROCEDURE Change_Subdirectory;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Change_Subdirectory                                  *)
(*                                                                      *)
(*     Purpose:    Change current subdirectory                          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Change_Subdirectory;                                          *)
(*                                                                      *)
(*     Calls:   GetDir                                                  *)
(*              ChDir                                                   *)
(*              Save_Screen                                             *)
(*              Restore_Screen                                          *)
(*              Draw_Titled_Box                                         *)
(*              Reset_Global_Colors                                     *)
(*                                                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Path_Name   : AnyStr;
   Save_Path   : AnyStr;
   Iok         : INTEGER;
   Drive_Ch    : CHAR;
   New_Drive   : CHAR;
   Drive_No    : INTEGER;
   Drive_Count : INTEGER;
   Y           : INTEGER;

BEGIN (* Change_Subdirectory *)
                                   (*  Draw directory change menu *)

   Draw_Titled_Box( Saved_Screen, 5, 10, 75, 15, 'Change Current Directory' );

   GoToXY( 1 , 1 );

   GetDir( 0 , Path_Name );
   Iok := Int24Result;

   TextColor( Menu_Text_Color_2 );
   WRITELN('Enter name of new directory path: ');
   WRITE  ('>');

   TextColor( Menu_Text_Color );

   Save_Path := Path_Name;
   Y         := WhereY;

   Read_Edited_String( Path_Name );

   WRITELN;

   TextColor( Menu_Text_Color_2 );

   IF ( ( LENGTH( Path_Name ) = 0 ) OR ( Path_Name = CHR( ESC ) ) ) THEN
      BEGIN
         GoToXY( 2 , Y );
         TextColor( Menu_Text_Color );
         WRITELN( Save_Path );
         TextColor( Menu_Text_Color_2 );
         WRITELN('*** Current directory remains unchanged.');
      END
   ELSE
      BEGIN

         Chdir( Path_Name );

         IF ( Int24Result = 0 ) THEN
            WRITELN('*** Current directory changed to ', Path_Name)
         ELSE
            WRITELN('*** Error found, directory not changed');

      END;

   Window_Delay;
                                   (* Restore previous screen *)

   Restore_Screen_And_Colors( Saved_Screen );

END   (* Change_Subdirectory *);

(*----------------------------------------------------------------------*)
(*               Delete_A_File --- Delete a file                        *)
(*----------------------------------------------------------------------*)

PROCEDURE Delete_A_File;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Delete_A_File                                        *)
(*                                                                      *)
(*     Purpose:    Delete file in current subdirectory                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Delete_A_File;                                                *)
(*                                                                      *)
(*     Calls:   Erase                                                   *)
(*              Save_Screen                                             *)
(*              Restore_Screen                                          *)
(*              Draw_Titled_Box                                         *)
(*              Reset_Global_Colors                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   File_Name : AnyStr;
   F         : FILE;

BEGIN (* Delete_A_File *)
                                   (*  Draw delete file menu *)

   Draw_Titled_Box( Saved_Screen, 5, 10, 75, 15, 'Delete A File -- Be Careful!' );

   TextColor( Menu_Text_Color_2 );

   GoToXY( 1 , 1 );

   WRITELN('Enter name of file to delete: ');
   WRITE('>');

   File_Name := '';

   TextColor( Menu_Text_Color );

   Read_Edited_String( File_Name );
   WRITELN;

   TextColor( Menu_Text_Color_2 );

   IF ( ( LENGTH( File_Name ) = 0 ) OR ( File_Name = CHR( ESC ) ) ) THEN
      WRITELN('*** No file to delete.')
   ELSE
      BEGIN
         ASSIGN( F , File_Name );
         ERASE ( F );
         IF ( Int24Result = 0 ) THEN
            WRITELN('*** File deleted.')
         ELSE
            WRITELN('*** File not found to delete or read-only');
      END;

   Window_Delay;
                                   (* Restore previous screen *)

   Restore_Screen_And_Colors( Saved_Screen );

END   (* Delete_A_File *);

(*----------------------------------------------------------------------*)
(*        Find_Free_Space_On_Drive --- Find free space on a drive       *)
(*----------------------------------------------------------------------*)

PROCEDURE Find_Free_Space_On_Drive;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Find_Free_Space_On_Drive                             *)
(*                                                                      *)
(*     Purpose:    Finds free space on a drive                          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Find_Free_Space_On_Drive;                                     *)
(*                                                                      *)
(*     Calls:   DiskFree                                                *)
(*              Save_Screen                                             *)
(*              Restore_Screen                                          *)
(*              Draw_Titled_Box                                         *)
(*              Reset_Global_Colors                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Drive_Ch: CHAR;
   FSpace:   LONGINT;

BEGIN (* Find_Free_Space_On_Drive *)

   Draw_Titled_Box( Saved_Screen, 10, 10, 61, 15, 'Free space on drive' );

   REPEAT
      GoToXY( 1 , 1 );
      ClrEol;
      Drive_CH := ' ';
      TextColor( Menu_Text_Color_2 );
      WRITE('Which drive? ');
      Read_Kbd( Drive_Ch );
      IF ( ( Drive_Ch = CHR( CR ) ) OR ( Drive_Ch = CHR( ESC ) ) ) THEN
         Drive_Ch := ' ';
      TextColor( Menu_Text_Color );
      WRITE( Drive_Ch );
      Drive_Ch := UpCase( Drive_Ch );
   UNTIL( Drive_Ch IN [' ','A'..'Z'] );

   TextColor( Menu_Text_Color_2 );

   IF Drive_Ch <> ' ' THEN
      BEGIN
         WRITELN;
         FSpace := DiskFree( SUCC( ORD( Drive_Ch ) - ORD('A') ) );
         IF ( FSpace >= 0 ) THEN
            WRITELN('Free space on drive ',Drive_Ch,' is ',FSpace:8,' bytes')
         ELSE
            WRITELN('Can''t find free space for drive ',Drive_Ch);

         WRITELN(' ');
         WRITE  ('Hit ESC to continue');

         Read_Kbd( Drive_Ch );

         IF ( Drive_Ch = CHR( ESC ) ) AND PibTerm_KeyPressed THEN
            Read_Kbd( Drive_Ch );

      END;

   Restore_Screen_And_Colors( Saved_Screen );

END   (* Find_Free_Space_On_Drive *);

(*----------------------------------------------------------------------*)
(*                    Copy_A_File  --- Copy a file                      *)
(*----------------------------------------------------------------------*)

PROCEDURE Copy_A_File;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Copy_A_File                                          *)
(*                                                                      *)
(*     Purpose:    Copies a file                                        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Copy_A_File;                                                  *)
(*                                                                      *)
(*     Calls:                                                           *)
(*              Save_Screen                                             *)
(*              Restore_Screen                                          *)
(*              Draw_Titled_Box                                         *)
(*              Reset_Global_Colors                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   BufSize =  4096                 (* Buffer size       *);

VAR
   F          : FILE               (* File to be copied *);
   F_Size     : LONGINT            (* Size of file      *);
   F_Name     : AnyStr             (* File to copy      *);
   F_Open     : BOOLEAN            (* If F opened OK    *);
   G          : FILE               (* File copied to    *);
   G_Open     : BOOLEAN            (* If G opened OK    *);
   G_Size     : LONGINT            (* Size of G         *);
   G_Name     : AnyStr             (* File copy         *);
   Abort_Copy : BOOLEAN            (* TRUE to stop copy *);

   BytesRead  : INTEGER            (* # of bytes read   *);
   BytesDone  : LONGINT            (* Total bytes read  *);

                                   (* Buffer area       *)
   Buffer     : PACKED ARRAY[ 1 .. BufSize ] OF CHAR;

   QErr       : BOOLEAN            (* If error occurs   *);

LABEL
   Abort_It;

BEGIN (* Copy_A_File *)
                                   (* Announce file copy *)

   Draw_Titled_Box( Saved_Screen, 5, 10, 75, 17, 'Copy a file' );

   Abort_Copy := FALSE;
   Qerr       := FALSE;
                                   (* Get name of file to copy *)
   REPEAT

      TextColor( Menu_Text_Color_2 );
      GoToXY( 1 , 1 );
      WRITE(' Enter file to be copied:    ');
      ClrEol;
      F_Name := '';

      TextColor( Menu_Text_Color );
      Read_Edited_String( F_Name );

      IF ( ( LENGTH( F_Name ) = 0 ) OR ( F_Name = CHR( ESC ) ) ) THEN
         Abort_Copy := TRUE
      ELSE
         F_Size := Get_File_Size( F_Name, F_Open )

   UNTIL ( F_Open OR Abort_Copy );

                                   (* Stop if no input file *)

   IF Abort_Copy THEN GOTO Abort_It;

                                   (* Get name of file to copy to *)
   REPEAT

      TextColor( Menu_Text_Color_2 );
      GoToXY( 1 , 2 );
      WRITE(' Enter file to receive copy: ');
      ClrEol;
      G_Name := '';
      TextColor( Menu_Text_Color );
      Read_Edited_String( G_Name );

      IF ( ( LENGTH( G_Name ) = 0 ) OR ( G_Name = CHR( ESC ) ) ) THEN
         Abort_Copy := TRUE
      ELSE
         G_Size := Get_File_Size( G_Name, G_Open );

      IF G_Open THEN
         BEGIN
            GoToXY( 1 , 3 );
            G_Open := NOT YesNo(' File already exists, overwrite (Y/N)? ');
         END;

   UNTIL ( ( NOT G_Open ) OR Abort_Copy );

                                   (* Open input file *)
   ASSIGN( F , F_Name );
   RESET ( F , 1 );
                                   (* Open output file *)
   ASSIGN ( G , G_Name );
   REWRITE( G , 1 );

                                   (* Report file size *)
   TextColor( Menu_Text_Color_2 );

   GoToXY( 1 , 4 );
   WRITE('Size of file ',F_Name,' in bytes is ',F_Size:8 );

   GoToXY( 1 , 5 );
   WRITE('Bytes copied: ');

   BytesDone := 0;
                                   (* Perform the copy *)
   REPEAT

      BlockRead( F, Buffer, BufSize, BytesRead );

      IF ( Int24Result <> 0 ) THEN
         BEGIN
            GoToXY( 1 , 6 );
            WRITE('Error reading input file, copy stops.');
            Qerr := TRUE;
         END;

      IF ( ( BytesRead > 0 ) AND ( NOT Qerr ) ) THEN
         BEGIN
            BlockWrite( G, Buffer, BytesRead );
            IF ( Int24Result <> 0 ) THEN
               BEGIN
                  GoToXY( 1 , 6 );
                  WRITE('Error writing output file, copy stops.');
                  Qerr := TRUE;
               END;
         END;

      BytesDone := BytesDone + BytesRead;

      GoToXY( 15 , 5 );
      WRITE( BytesDone:8 );

   UNTIL ( ( BytesRead < BufSize ) OR Qerr );

                                   (* Close files  *)
   CLOSE( F );
   Err := Int24Result;
   CLOSE( G );
   Err := Int24Result;

   GoToXY( 1 , 6 );

   IF ( NOT Qerr ) THEN
      WRITE('Copy complete.');

   Window_Delay;

Abort_It:
                                   (* Restore previous screen *)

   Restore_Screen_And_Colors( Saved_Screen );

END   (* Copy_A_File *);

(*----------------------------------------------------------------------*)
(*              Print_A_File  --- Initiate printing of a file           *)
(*----------------------------------------------------------------------*)

PROCEDURE Print_A_File( F_Name : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Print_A_File                                         *)
(*                                                                      *)
(*     Purpose:    Initiates printing of a file                         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Print_A_File;                                                 *)
(*                                                                      *)
(*     Calls:                                                           *)
(*              Save_Screen                                             *)
(*              Restore_Screen                                          *)
(*              Draw_Titled_Box                                         *)
(*              Reset_Global_Colors                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   F_Open      : BOOLEAN;
   Abort_Print : BOOLEAN;
   F_Size      : LONGINT;
   Err         : INTEGER;

BEGIN (* Print_A_File *)
                                   (* Announce file print *)

   Draw_Titled_Box( Saved_Screen, 5, 10, 75, 15, 'Print a file' );

                                   (* Print a file not allowed      *)
                                   (* if logging session to printer *)

   TextColor( Menu_Text_Color_2 );

   IF Printer_On THEN
      BEGIN
         WRITELN('Can''t print a file while session logging active.');
         Window_Delay;
         Restore_Screen_And_Colors( Saved_Screen );
         EXIT;
      END;
                                   (* Currently spooling -- see if *)
                                   (* we are to stop.              *)
   IF Print_Spooling THEN
      BEGIN
         F_Open := YesNo('File already being printed, stop it (Y/N)? ');
         IF F_Open THEN
            BEGIN
               Print_Spooling := FALSE;
               CLOSE( Spool_File );
               DISPOSE( Spool_Buffer );
            END
         ELSE
            BEGIN
               Restore_Screen_And_Colors( Saved_Screen );
               EXIT;
            END;
      END;

   Abort_Print := FALSE;
   F_Open      := FALSE;
                                   (* Get name of file to copy *)
   GoToXY( 1 , 1 );
   WRITE(' Enter file to be printed:    ');
   ClrEol;

   TextColor( Menu_Text_Color );
   IF ( LENGTH( F_Name ) = 0 ) THEN
      Read_Edited_String( F_Name )
   ELSE
      WRITE( F_Name );
   WRITELN;

   TextColor( Menu_Text_Color_2 );

   IF ( ( LENGTH( F_Name ) > 0 ) AND ( F_Name <> CHR( ESC ) ) ) THEN
      BEGIN
         F_Size := Get_File_Size( F_Name, F_Open );
         IF ( NOT F_Open ) THEN
            BEGIN
               WRITE(' Can''t open that file.');
               ClrEol;
               Window_Delay;
               GoToXY( 1 , WhereY );
               ClrEol;
               Abort_Print := TRUE;
            END;
      END
   ELSE
      Abort_Print := TRUE;
                                   (* Stop if no file to print *)
   IF ( NOT Abort_Print ) THEN
      BEGIN
                                   (* Open file to print and read in *)
                                   (* first buffer full of data      *)

         ASSIGN( Spool_File , F_Name );
         RESET ( Spool_File , 1 );
         
         NEW( Spool_Buffer );

         IF ( Spool_Buffer = NIL ) THEN
            BEGIN
               WRITELN;
               WRITELN(' Not enough memory to print file, print cancelled.');
               Press_Any;
            END
         ELSE
            BEGIN

               Spool_Buffer_Count := Max_Spool_Buffer_Count;

               BlockRead( Spool_File, Spool_Buffer^, Max_Spool_Buffer_Count,
                          Spool_Buffer_Count );

               Err := Int24Result;

               Spool_Buffer_Pos := 0;

               Print_Spooling := TRUE;

               WRITELN;
               WRITELN(' File ',F_Name,' starting to print.');
               Window_Delay;

            END;

      END;
                                   (* Restore previous screen *)

   Restore_Screen_And_Colors( Saved_Screen );

END   (* Print_A_File *);
