(*--------------------------------------------------------------------------*)
(*            GetAreaCode --- Get area code for city/state/country          *)
(*--------------------------------------------------------------------------*)

PROCEDURE GetAreaCode;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Procedure:  GetAreaCode                                              *)
(*                                                                          *)
(*     Purpose:    Searches area code directory                             *)
(*                                                                          *)
(*     Calling sequence:                                                    *)
(*                                                                          *)
(*        GetAreaCode;                                                      *)
(*                                                                          *)
(*     Calls:                                                               *)
(*                                                                          *)
(*        UpperCase                                                         *)
(*        Save_Screen                                                       *)
(*        Draw_Menu_Frame                                                   *)
(*        Restore_Screen                                                    *)
(*        Reset_Global_Colors                                               *)
(*                                                                          *)
(*     Called by:  Execute_Command                                          *)
(*                                                                          *)
(*     Credit:  This area code search is based upon one by Tom Hanlin III   *)
(*              in his ETERM and PASCTERM programs, and one by Martin Smith *)
(*              in his AREA2.EXE program.                                   *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

CONST
   MaxAreaCodes = 300;

TYPE
   AreaCodeVectorType = ARRAY[0..MaxAreaCodes] OF STRING[60];
   AreaCodePtr        = ^AreaCodeVectorType;

VAR
   LF             : BYTE;
   RT             : BYTE;
   Ptr            : BYTE;
   I              : BYTE;
   Code           : STRING[20];
   Any_Ch         : CHAR;
   AreaCode       : AreaCodePtr;
   AreaCodeFile   : TEXT;
   N_Area_Codes   : INTEGER;
   Searching_Done : BOOLEAN;
   AreaCodeBuf    : ARRAY[1..1024] OF CHAR;
   
(*--------------------------------------------------------------------------*)

PROCEDURE Do_Area_Code_Search;

VAR
   I: INTEGER;
   
BEGIN (* Searching_Done *)
                                   (* Convert to upper case *)
    Code := UpperCase( Code );

                                   (* Determine type of request *)
    IF ( RT = 2 ) AND
       ( Code[1] IN ['A'..'Z']) AND ( Code[2] IN ['A'..'Z'] ) THEN
          LF := 4
    ELSE IF ( RT = 3 ) AND
       ( Code[1] IN ['0'..'9'] ) AND
       ( Code[2] IN ['0'..'9'] ) AND
       ( Code[3] IN ['0'..'9'] ) THEN
          LF := 1
    ELSE IF RT <> 0 THEN
          LF := 6;
                                   (* Display search message *)

    Draw_Menu_Frame( 5, 4, 75, 23, Menu_Frame_Color, Menu_Title_Color,
                     Menu_Text_Color, 'Searching for: ' + Code );

                                   (* Perform search *)
    View_Count := 0;
    View_Done  := FALSE;

    FOR I := 0 TO N_Area_Codes DO
       IF ( NOT View_Done ) THEN
          IF UpperCase( Copy( AreaCode^[I], LF, RT ) ) = Code THEN
             BEGIN

                WRITE  ( '     ' );
                WRITE  ( Copy( AreaCode^[I], 1, 3 ), '   ' );
                WRITE  ( Copy( AreaCode^[I], 4, 2 ) ,'   ' );
                WRITELN( Copy( AreaCode^[I], 6, LENGTH( AreaCode^[I] ) - 5 ) );

                INC( View_Count );

                IF View_Count > 16 THEN
                   View_Prompt( View_Done, View_Count );

             END;

    RvsVideoOn ( Menu_Text_Color , BLACK );
    WRITE('Search complete. Hit any key to continue.');
    RvsVideoOff( Menu_Text_Color , BLACK );

    Read_Kbd( Any_Ch );
    IF ( Any_Ch = CHR( ESC ) ) AND PibTerm_KeyPressed THEN
       Read_Kbd( Any_Ch );

END   (* Searching_Done *);

(*--------------------------------------------------------------------------*)

BEGIN (* GetAreaCode *)
                                   (* Save current screen *)
    Save_Screen( Saved_Screen );
                                   (* Display area code prompt box *)

    Draw_Menu_Frame( 5, 4, 75, 23, Menu_Frame_Color, Menu_Title_Color,
                     Menu_Text_Color, 'Area code search' );

                                   (* Open area code directory file *)

    ASSIGN    ( AreaCodeFile , Home_Dir + 'PIBTERM.ACO' );
    SetTextBuf( AreaCodeFile , AreaCodeBuf );
       (*!I-*)
    RESET ( AreaCodeFile );
       (*!I+*)
                                   (* Check if open went OK *)
    IF ( Int24Result <> 0 ) THEN
       BEGIN
          WRITELN('Area code file ', Home_Dir, ' PIBTERM.ACO cannot be opened.');
          WRITELN;
          Window_Delay;
          Restore_Screen_And_Colors( Saved_Screen );
          EXIT;
       END;
                                   (* Get space for area code entries *)

    GetMem( AreaCode , SIZEOF( AreaCodeVectorType ) );

    IF ( AreaCode = NIL ) THEN
       BEGIN
          WRITELN('Not enough memory to store area codes for searching.');
          WRITELN;
          Window_Delay;
          Restore_Screen_And_Colors( Saved_Screen );
          EXIT;
       END;
                                   (* Read in area code data *)

    WRITELN('Reading area code information ... ');

    N_Area_Codes := -1;

    REPEAT
       INC( N_Area_Codes );
       READLN( AreaCodeFile , AreaCode^[N_Area_Codes] );
    UNTIL ( EOF( AreaCodeFile ) );

       (*!I-*)
    CLOSE( AreaCodeFile );
       (*!I+*)
                                   (* Prompt for and read area code req. *)
    Searching_Done := FALSE;

    REPEAT

       Clear_Window;

       WRITE('Enter area code, state/country, or state initials: ');
       Code := '';
       Read_Edited_String( Code );

       RT := LENGTH( Code );

       IF ( ( RT > 0 ) AND ( Code <> CHR( ESC ) ) ) THEN
          Do_Area_Code_Search
       ELSE
          Searching_Done := TRUE;

    UNTIL( Searching_Done );
                                   (* Free memory for area codes *)

    FreeMem( AreaCode , SIZEOF( AreaCodeVectorType ) );

                                   (* Restore previous screen *)

    Restore_Screen_And_Colors( Saved_Screen );

END   (* GetAreaCode *);
