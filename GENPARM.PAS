(*$R-,V-,S-*)
PROGRAM GenParm;

TYPE
   AnyStr = STRING[255];

VAR
   Max_Param_Names : INTEGER;
   Param_Text      : ARRAY[ 1 .. 220 ] OF AnyStr;
   Max_Descriptor  : INTEGER;
   Max_Desc_Short  : INTEGER;

VAR
   I, J, K         : INTEGER;
   L               : INTEGER;
   PLine           : AnyStr;
   F               : TEXT;
   G               : TEXT;
   PNameI          : STRING[2];
   PNameJ          : STRING[2];

BEGIN (* GenParm *)

   ASSIGN ( F, 'PARMDAT.DEF' );
   RESET  ( F );

   ASSIGN ( G, 'BBB.PAS' );
   REWRITE( G );

   Max_Param_Names := 0;

   REPEAT
      INC( Max_Param_Names );
      READLN( F , Param_Text[Max_Param_Names] );
   UNTIL ( EOF( F ) );

   CLOSE( F );

   FOR I := 1 TO PRED( Max_Param_Names ) DO
      BEGIN
         PNameI := Param_Text[I][1] + Param_Text[I][2];
         FOR J := SUCC( I ) TO Max_Param_Names DO
            BEGIN
               PNameJ := Param_Text[J][1] + Param_Text[J][2];
               IF ( PNameJ < PNameI ) THEN
                  BEGIN
                     PLine         := Param_Text[I];
                     Param_Text[I] := Param_Text[J];
                     Param_Text[J] := PLine;
                     PNameI        := Param_Text[I][1] + Param_Text[I][2];
                  END;
            END;
      END;

   WRITELN( G , 'CONST' );
   WRITELN( G , '   Max_Param_Names = ', Max_Param_Names, ';');
   WRITELN( G , ' ' );
   WRITELN( G , '(* STRUCTURED *) CONST');
   WRITELN( G , '   Parameters : ARRAY[ 1 .. Max_Param_Names ] OF Parameter_Record_Type =');
   WRITELN( G , '                (');

   FOR I := 1 TO Max_Param_Names DO
      BEGIN
         PLine := Param_Text[I];
         WRITE  ( G , '    (*', I:3, '*)      ( ');
         WRITE  ( G , 'PName : ''',PLine[1],PLine[2],'''; ');
         WRITE  ( G , 'PType : ',COPY( PLine, 4, 14 ),'; ');
         WRITE  ( G , 'PAddr : NIL; PDesc : NIL )');
         IF ( I <> Max_Param_Names ) THEN
            WRITE( G , ',' );
         WRITELN( G );
      END;

   WRITE  ( G , ' );');
   WRITELN( G );
   WRITELN( G );

   Max_Descriptor := 0;
   Max_Desc_Short := 0;

   WRITELN( G , ' ' );
   WRITELN( G , '(* STRUCTURED *) CONST');

   FOR I := 1 TO Max_Param_Names DO
      BEGIN
         PLine  := Param_Text[I];
         PNameI := Pline[1] + Pline[2];
         PLine  := COPY( PLine, 45, 255 );
         L      := LENGTH( PLine );
         IF ( L = 0 ) THEN
            BEGIN
               L     := 1;
               PLine := ' ';
            END;
         IF ( L > Max_Descriptor ) THEN
            Max_Descriptor := L;
         Max_Desc_Short := Max_Desc_Short + L;
         WRITELN( G , '   Desc_', PNameI, ': STRING[',L, '] = ''', PLine, ''';' );
      END;

   WRITELN( G );
   WRITELN( G );

   WRITELN( G , 'PROCEDURE Set_Parameter_Addresses;' );
   WRITELN( G , ' ' );
   WRITELN( G , 'BEGIN (* Set_Parameter_Addresses *)');
   WRITELN( G , ' ' );

   FOR I := 1 TO Max_Param_Names DO
      BEGIN
         PLine  := Param_Text[I];
         PNameI := PLine[1] + PLine[2];
         PLine  := COPY( PLine, 19, 26 );
         WHILE( POS( ' ' , PLine ) > 0 ) DO
            DELETE( PLine, POS( ' ' , PLine ), 1 );
         IF ( LENGTH( PLine ) > 0 ) THEN
            WRITELN( G , '   Parameters[',I:3,'].PAddr := @', PLine, ';' );
         WRITELN( G , '   Parameters[',I:3,'].PDesc := @Desc_', PNameI, ';' );
         WRITELN( G , ' ');
      END;

   WRITELN( G , 'END   (* Set_Parameter_Addresses *);');

   CLOSE( G );

   WRITELN;
   WRITELN('Number of parameters   : ',Max_Param_Names);
   WRITELN('Maximum descriptor     : ',Max_Descriptor );
   WRITELN('Total descriptor length: ',Max_Descriptor * Max_Param_Names);
   WRITELN('Total short desc. len. : ',Max_Desc_Short );

END   (* GenParm *).