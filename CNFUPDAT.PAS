(*$R-,V-,S-,I-,F+*)
PROGRAM CnfUpDate;

USES
   Dos;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Program:    CnfUpDate;                                           *)
(*                                                                      *)
(*     Purpose:    Updates pre-v4.1 PIBTERM.CNF files to v4.1 specs.    *)
(*                                                                      *)
(*     Author:     Philip R. Burns                                      *)
(*                                                                      *)
(*     Version:    1.0.  January 5, 1988.                               *)
(*                 1.1.  February 21, 1988.  For initial PTv4.1 release.*)
(*                                                                      *)
(*     Use:                                                             *)
(*                                                                      *)
(*        At the DOS prompt enter:                                      *)
(*                                                                      *)
(*           CNFUPDAT cnfname                                           *)
(*                                                                      *)
(*        where "cnfname" is the name of the .CNF file to be            *)
(*        converted WITHOUT the terminating ".CNF" specified.           *)
(*        If "cnfname" is not specified, then "PIBTERM"                 *)
(*        is used as a default name.  If a '?' is entered for           *)
(*        "cnfname", then a brief help note is displayed.               *)
(*                                                                      *)
(*        The old file is renamed to "cnfname.CNO" and the new file is  *)
(*        written to "cnfname.CNF".                                     *)
(*                                                                      *)
(*        For example, if                                               *)
(*                                                                      *)
(*           CNFUPDAT  PIBTERM                                          *)
(*                                                                      *)
(*        is entered, then  PIBTERM.CNF is renamed to PIBTERM.CNO,      *)
(*        and the new file is PIBTERM.CNF.                              *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

TYPE
   AnyStr  = STRING[255];
   TextBuf = ARRAY[1..4096] OF CHAR;

VAR
   New_Config_File : TEXT;
   Old_Config_File : TEXT;

   New_Config_File_Buffer : TextBuf;
   Old_Config_File_Buffer : TextBuf;

   New_Config_File_Name   : AnyStr;
   Old_Config_File_Name   : AnyStr;

   File_Path              : AnyStr;

   New_Open               : BOOLEAN;
   Old_Open               : BOOLEAN;

   Config_Line            : AnyStr;
   Param_Name             : String[2];

(*----------------------------------------------------------------------*)

PROCEDURE Close_Files;

VAR
   Ierr : INTEGER;

BEGIN (* Close_Files *)

   IF Old_Open THEN
      BEGIN
         CLOSE( Old_Config_File );
         Ierr := IOResult;
      END;

   IF New_Open THEN
      BEGIN
          CLOSE( New_Config_File );
          Ierr := IOResult;
      END;

END   (* Close_Files *);

(*----------------------------------------------------------------------*)

PROCEDURE Check_Error( S : AnyStr );

BEGIN (* Check_Error *)

   IF ( IOResult <> 0 ) THEN
      BEGIN

         WRITELN;
         WRITELN( S , ', conversion abandoned.' );

         Close_Files;

         Halt( 1 );

      END;

END   (* Check_Error *);

(*----------------------------------------------------------------------*)

PROCEDURE Display_Help;

BEGIN (* Display_Help *)

   WRITELN( ' ' );
   WRITELN( 'Program:    CnfUpDate' );
   WRITELN( 'Purpose:    Updates pre-v4.1 PIBTERM.CNF files to v4.1 specs.' );
   WRITELN( 'Author:     Philip R. Burns' );
   WRITELN( 'Version:    1.1.  February 21, 1988.');
   WRITELN( 'Use:');
   WRITELN( '      CNFUPDAT cnfname' );
   WRITELN( 'where "cnfname" is the name of the .CNF file to be');
   WRITELN( 'converted WITHOUT the terminating ".CNF" specified.');
   WRITELN( 'If "cnfname" is not specified, then "PIBTERM"');
   WRITELN( 'is used as a default name.  If a "?" is entered for');
   WRITELN( '"cnfname", then a brief help note is displayed.');
   WRITELN( ' ');
   WRITELN( 'The old file is renamed to "cnfname.CNO" and the new file is');
   WRITELN( 'written to "cnfname.CNF".');
   WRITELN( ' ' );
   WRITELN( 'Example:');
   WRITELN( '      CNFUPDAT  PIBTERM');
   WRITELN( 'causes PIBTERM.CNF to be renamed to PIBTERM.CNO, and the');
   WRITELN( 'updated configuration file is written to PIBTERM.CNF.');

END    (* Display_Help *);

(*----------------------------------------------------------------------*)

PROCEDURE Get_File_Names;

VAR
   I        : INTEGER;
   L        : INTEGER;

BEGIN (* Get_File_Names *)
                                      (* No files open yet *)
   Old_Open  := FALSE;
   New_Open  := FALSE;
   File_Path := '';
                                      (* Get old config file name *)
   IF ( ParamCount > 0 ) THEN
      Old_Config_File_Name := ParamStr( 1 )
   ELSE
      Old_Config_File_Name := 'PIBTERM.CNF';

                                      (* See if help request *)

   IF ( Old_Config_File_Name = '?' ) THEN
      BEGIN
         Display_Help;
         Halt( 0 );
      END;
                                      (* Convert name to upper case *)

   L := LENGTH( Old_Config_File_Name );

   FOR I := 1 TO L DO
      Old_Config_File_Name[I] := UpCase( Old_Config_File_Name[I] );

                                      (* Remove file extension  *)

   I := POS( '.' , Old_Config_File_Name );

   IF ( I > 0 ) THEN
      Old_Config_File_Name := COPY( Old_Config_File_Name, 1, PRED( I ) );

                                      (* Extract path if any    *)

   IF ( ( POS( ':' , Old_Config_File_Name ) <> 0 ) OR
        ( POS( '\' , Old_Config_File_Name ) <> 0 ) ) THEN
      BEGIN
         I := L;
         WHILE( ( Old_Config_File_Name[I] <> ':' ) AND
                ( Old_Config_File_Name[I] <> '\' ) ) DO
            DEC( I );
         File_Path            := COPY( Old_Config_File_Name, 1, I );
         Old_Config_File_Name := COPY( Old_Config_File_Name, SUCC( I ), 255 );
      END;
                                      (* Form old and new names *)

   New_Config_File_Name := File_Path + Old_Config_File_Name + '.CNF';
   Old_Config_File_Name := File_Path + Old_Config_File_Name + '.CNO';

END    (* Get_File_Names *);

(*----------------------------------------------------------------------*)

PROCEDURE Open_Files;

BEGIN (* Open_Files *)
                                   (* Assign old config file and *)
                                   (* rename to PIBTERM.CNO      *)

   ASSIGN( Old_Config_File , New_Config_File_Name );
   RENAME( Old_Config_File , Old_Config_File_Name );

   Check_Error('Can not rename ' + New_Config_File_Name + ' to ' +
               Old_Config_File_Name );

   WRITELN('The old configuration file ',New_Config_File_Name,
           ' has been renamed ',Old_Config_File_Name);

                                   (* Rename worked -- open old config file *)

   SetTextBuf( Old_Config_File , Old_Config_File_Buffer );
   RESET( Old_Config_File );

   Check_Error('Can not open old ' + Old_Config_File_Name + ' file');

   Old_Open := TRUE;
                                   (* Assign new configuration file *)

   ASSIGN( New_Config_File , New_Config_File_Name );
   SetTextBuf( New_Config_File , New_Config_File_Buffer );
   REWRITE( New_Config_File );

   Check_Error('Can not open new ' + New_Config_File_Name + ' file');

   New_Open := TRUE;

END   (* Open_Files *);

(*----------------------------------------------------------------------*)
(*             Write_Ctrls --- Convert ctrl key defs in string          *)
(*----------------------------------------------------------------------*)

FUNCTION Write_Ctrls( S : AnyStr ) : AnyStr;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Write_Ctrls                                          *)
(*                                                                      *)
(*     Purpose:    Convert ctrl key defs to ascii sequences             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Fixed_S := Write_Ctrls( S: AnyStr ) : AnyStr;                 *)
(*                                                                      *)
(*           S       --- the string with potential ctrl seqs to convert *)
(*           Fixed_S --- fixed up string                                *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine replaces control sequences like ^G (ascii 07)    *)
(*        with a two-character sequence like '^G' -- ascii 94 +         *)
(*        ascii 71. The actual '^' character                            *)
(*        is the global parameter FK_Ctrl_Mark and can be set with      *)
(*        a configuration file.                                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   T: AnyStr;
   I: INTEGER;
   J: INTEGER;

BEGIN (* Write_Ctrls *)
                                   (* Scan for ctrl characters *)
   T    := '';
   J    := 0;

   FOR I := 1 TO LENGTH( S ) DO
      BEGIN                        (* Ctrl char --- convert to marker  *)
                                   (* plus ascii character             *)

         IF ( S[I] IN [^@..^_] ) THEN
            BEGIN
               INC( J );
               T[J] := '^';
               INC( J );
               T[J] := CHR( ORD( S[I] ) + 64 );
            END

                                   (* Regular character -- just copy *)
         ELSE
            BEGIN
               INC( J );
               T[J] := S[I];
            END;
      END;

   T[0]        := CHR( J );
   Write_Ctrls := T;

END   (* Write_Ctrls *);

(*--------------------------------------------------------------------------*)
(*               Trim --- Trim trailing blanks from a string                *)
(*--------------------------------------------------------------------------*)

FUNCTION Trim( S : AnyStr ) : AnyStr;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Function:   Trim                                                     *)
(*                                                                          *)
(*     Purpose:    Trims trailing blanks from a string                      *)
(*                                                                          *)
(*     Calling sequence:                                                    *)
(*                                                                          *)
(*         Trimmed_S := TRIM( S );                                          *)
(*                                                                          *)
(*            S          --- the string to be trimmed                       *)
(*            Trimmed_S  --- the trimmed version of S                       *)
(*                                                                          *)
(*     Calls:  None                                                         *)
(*                                                                          *)
(*     Remarks:                                                             *)
(*                                                                          *)
(*        Note that the original string itself is left untrimmed.           *)
(*                                                                          *)
(*     Pascal version might be written as:                                  *)
(*                                                                          *)
(*        VAR                                                               *)
(*           I:       INTEGER;                                              *)
(*                                                                          *)
(*        BEGIN                                                             *)
(*                                                                          *)
(*           I := ORD( S[0] );                                              *)
(*                                                                          *)
(*           WHILE ( I > 0 ) AND ( S[I] = ' ' ) DO                          *)
(*              I := PRED( I );                                             *)
(*                                                                          *)
(*           S[0] := CHR( I );                                              *)
(*           Trim := S;                                                     *)
(*                                                                          *)
(*        END;                                                              *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

BEGIN (* Trim *)

INLINE(
  $1E/                   {         PUSH    DS                ; Save DS}
                         {;}
  $C5/$76/$06/           {         LDS     SI,[BP+6]         ; Get address of S}
  $FC/                   {         CLD                       ; Forward search}
  $AC/                   {         LODSB                     ; Get length of S}
  $3C/$00/               {         CMP     AL,0              ; See if length 0}
  $74/$21/               {         JE      Trim2             ; If so, no trimming required}
                         {;}
  $30/$ED/               {         XOR     CH,CH}
  $88/$C1/               {         MOV     CL,AL             ; Remember length for search loop}
                         {;}
  $B0/$20/               {         MOV     AL,' '            ; Blank to AL}
                         {;}
  $C4/$7E/$06/           {         LES     DI,[BP+6]         ; Get address of S}
  $01/$CF/               {         ADD     DI,CX             ; Point to end of source string}
                         {;}
  $FD/                   {         STD                       ; Backwards search}
  $F3/$AE/               {         REPE    SCASB             ; Scan over blanks}
  $74/$01/               {         JE      Trim1             ; If CX=0, entire string is blank.}
  $41/                   {         INC     CX}
                         {;}
  $88/$C8/               {Trim1:   MOV     AL,CL             ; Length to copy}
  $C5/$76/$06/           {         LDS     SI,[BP+6]         ; Source string address}
  $46/                   {         INC     SI                ; Skip length}
  $C4/$7E/$0A/           {         LES     DI,[BP+10]        ; Result string address}
  $FC/                   {         CLD                       ; Forward move}
  $AA/                   {         STOSB                     ; Set length in result}
  $F2/$A4/               {         REP     MOVSB             ; Move trimmed result}
  $E9/$04/$00/           {         JMP     Exit}
                         {;}
  $C4/$7E/$0A/           {Trim2:   LES     DI,[BP+10]        ; Result string address}
  $AA/                   {         STOSB                     ; Set length=0 in result}
                         {;}
  $1F);                  {Exit:    POP     DS                ; Restore DS}

END   (* Trim *);

(*----------------------------------------------------------------------*)

PROCEDURE Convert_Config_File;

VAR
   Config_Line : AnyStr;
   Param_Name  : String[2];
   PD_Count    : INTEGER;
   Int_Val     : LONGINT;
   L           : INTEGER;
   I           : INTEGER;
   YM_Seen     : BOOLEAN;
   ZM_Seen     : BOOLEAN;

BEGIN (* Convert_Config_File *)
                                   (* No external transfer guys found yet *)
   PD_Count := 0;
   YM_Seen  := FALSE;
   ZM_Seen  := FALSE;
                                   (* Read old config file and     *)
                                   (* convert parameters as needed *)
   REPEAT
                                   (* Read line from old config file *)

      READLN( Old_Config_File , Config_Line );

      Check_Error('Can not read line from old configuration file' );

                                   (* Make sure it's legal format *)

      IF ( LENGTH( Config_Line ) > 2 ) THEN
         IF ( Config_Line[3] = '=' ) THEN
            BEGIN
                                   (* Get param name. If one we are *)
                                   (* checking, process it.         *)

               Param_Name  := Config_Line[1] + Config_Line[2];
               Config_Line := TRIM( COPY( Config_Line, 4, LENGTH( Config_Line ) - 3 ) );
               L           := LENGTH( Config_Line );

               IF      ( Param_Name = 'PD' ) THEN
                  BEGIN
                     Param_Name := 'Z' + CHR( ORD( '0' ) + PD_Count );
                     PD_Count   := SUCC( PD_Count );
                     YM_Seen    := YM_Seen OR ( COPY( Config_Line, 1, 2 ) = 'YM' );
                     ZM_Seen    := ZM_Seen OR ( COPY( Config_Line, 1, 2 ) = 'ZM' );
                  END
               ELSE IF ( ( Param_Name = 'BS' ) OR
                         ( Param_Name = 'DE' )  ) THEN
                  BEGIN
                     IF ( L > 0 ) THEN
                        BEGIN
                           I       := 1;
                           Int_Val := 0;
                           WHILE ( ( I <= L ) AND
                                   ( Config_Line[I] IN ['0'..'9'] ) ) DO
                              BEGIN
                                 Int_Val := Int_Val * 10 + ORD( Config_Line[I] ) - ORD( '0' );
                                 INC( I );
                              END;
                           Config_Line := Write_Ctrls( CHR( Int_Val ) );
                        END;
                  END
               ELSE IF ( ( Param_Name[1] = 'B' ) AND
                         ( Param_Name[2] IN ['1'..'4'] ) ) THEN
                  Param_Name := ''
               ELSE IF ( Param_Name = 'TT' ) THEN
                  BEGIN
                     IF ( ( Config_Line = 'YM' ) AND ( NOT YM_Seen ) ) THEN
                        Config_Line := 'X1';
                  END
               ELSE IF ( Param_Name = 'TM' ) THEN
                  BEGIN
                     IF ( Config_Line[1] = 'M' ) THEN
                        Config_Line[1] := 'B';
                  END;

               IF ( Param_Name <> '' ) THEN
                  BEGIN
                     WRITELN( New_Config_File , Param_Name , '=', Config_Line );
                     Check_Error('Can not write line to new configuration file' );
                  END;

            END;

   UNTIL ( EOF( Old_Config_File ) );

                                   (* Write defaults for new parameters *)

   WRITELN( New_Config_File , 'NL=0'   );
   WRITELN( New_Config_File , 'YX=1'   );
   WRITELN( New_Config_File , 'WH=2'   );
   WRITELN( New_Config_File , 'EU=1'   );
   WRITELN( New_Config_File , 'AS=255' );
   WRITELN( New_Config_File , 'EG=1'   );
   WRITELN( New_Config_File , 'ML=0'   );
   WRITELN( New_Config_File , 'V1=0C'  );
   WRITELN( New_Config_File , 'V2=0B'  );
   WRITELN( New_Config_File , 'V3=0C'  );
   WRITELN( New_Config_File , 'V4=0B'  );
   WRITELN( New_Config_File , 'VK='    );
   WRITELN( New_Config_File , 'VN='    );
   WRITELN( New_Config_File , 'KK=0'   );
   WRITELN( New_Config_File , 'ZA=0'   );

                                   (* Add Zmodem protocol definition if *)
                                   (* already seen.                     *)

   IF ( ( NOT ZM_Seen ) AND ( PD_Count <= 9 ) ) THEN
      WRITELN( New_Config_File , 'Z' , CHR( ORD( '0' ) + PD_Count ),
               '=ZM Zmodem B H RECZMOD.BAT SENDZMOD.BAT' );

   WRITELN('Updated configuration file written to ',New_Config_File_Name);

END   (* Convert_Config_File *);

(*----------------------------------------------------------------------*)

BEGIN (* CnfUpDate *)
                                   (* Get file names *)
   Get_File_Names;
                                   (* Open the files *)
   Open_Files;
                                   (* Convert the old file to the new *)
   Convert_Config_File;
                                   (* Close config files *)
   Close_Files;

END   (* CnfUpDate *).